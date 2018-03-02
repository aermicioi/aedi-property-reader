module aermicioi.aedi_property_reader.core.accessor;

import std.traits;
import taggedalgebraic;

interface PropertyAccessor(ComponentType, FieldType = ComponentType) {

    FieldType access(ComponentType component, string property) const;

    bool has(in ComponentType component, string property) const;
}

class AggregatePropertyAccessor(ComponentType, FieldType = ComponentType) : PropertyAccessor!(ComponentType, FieldType) {

    private {

        PropertyAccessor!(ComponentType, FieldType)[] accessors_;
    }

    public {

        this(PropertyAccessor!(ComponentType, FieldType)[] accessors...) {
            this.accessors = accessors.dup;
        }

        /**
        Set accessors

        Params:
            accessors = accessors that implement various logic of accessing a property out of component

        Returns:
            typeof(this)
        **/
        typeof(this) accessors(PropertyAccessor!(ComponentType, FieldType)[] accessors) @safe nothrow pure {
            this.accessors_ = accessors;

            return this;
        }

        /**
        Get accessors

        Returns:
            PropertyAccessor!(ComponentType, FieldType)
        **/
        inout(PropertyAccessor!(ComponentType, FieldType)[]) accessors() @safe nothrow pure inout {
            return this.accessors_;
        }

        FieldType access(ComponentType component, string property) const {

            foreach (accessor; this.accessors) {

                if (accessor.has(component, property)) {

                    return accessor.access(component, property);
                }
            }

            import aermicioi.aedi.exception.not_found_exception : NotFoundException;
            throw new NotFoundException("Could not find element");
        }

        bool has(in ComponentType component, string property) const {

            foreach (accessor; this.accessors) {

                if (accessor.has(component, property)) {
                    return true;
                }
            }

            return false;
        }
    }
}

class PropertyPathAccessor(ComponentType, FieldType = ComponentType) : PropertyAccessor!(ComponentType, FieldType)
    if (isImplicitlyConvertible!(FieldType, ComponentType)) {

    private {
        PropertyAccessor!(ComponentType, FieldType) accessor_;
        PropertyAccessor!(ComponentType, FieldType) indexer_;
    }

    public {

        this(
            PropertyAccessor!(ComponentType, FieldType) accessor,
            PropertyAccessor!(ComponentType, FieldType) indexer
        ) {
            this.accessor = accessor;
            this.indexer = indexer;
        }

        /**
        Set accessor

        Params:
            accessor = accessor instance responsible for getting a property out of component

        Returns:
            typeof(this)
        **/
        typeof(this) accessor(PropertyAccessor!(ComponentType, FieldType) accessor) @safe nothrow pure {
            this.accessor_ = accessor;

            return this;
        }

        /**
        Get accessor

        Returns:
            PropertyAccessor!(ComponentType, FieldType)
        **/
        inout(PropertyAccessor!(ComponentType, FieldType)) accessor() @safe nothrow pure inout {
            return this.accessor_;
        }

        /**
        Set indexer

        Params:
            indexer = indexer instance responsible to access a property by index
        Throws:

        Returns:
            typeof(this)
        **/
        typeof(this) indexer(PropertyAccessor!(ComponentType, FieldType) indexer) @safe nothrow pure {
            this.indexer_ = indexer;

            return this;
        }

        /**
        Get indexer

        Returns:
            PropertyAccessor!(ComponentType, FieldType)
        **/
        inout(PropertyAccessor!(ComponentType, FieldType)) indexer() @safe nothrow pure inout {
            return this.indexer_;
        }

        FieldType access(ComponentType component, string path) const {
            import std.algorithm;
            import std.range;

            auto identities = path.splitter(".").map!(s => s.splitter("[")).joiner;

            ComponentType current = component;

            foreach (identity; identities) {

                if (identity.endsWith("]")) {
                    identity = identity[0 .. $ - 1];

                    if (identity.startsWith("\"") && identity.endsWith("\"")) {
                        identity = identity[1 .. $ - 1];
                    }

                    if (indexer.has(current, identity)) {

                        current = this.indexer.access(current, identity);
                    } else {

                        throw new Exception("Property " ~ identity ~ " not found in path " ~ path);
                    }
                } else if (this.accessor.has(current, identity)) {

                    current = this.accessor.access(current, identity);
                } else {

                    throw new Exception("Property " ~ identity ~ " not found in path " ~ path);
                }
            }

            return current;
        }

        bool has(in ComponentType component, string path) const {

            import std.algorithm;
            import std.range;

            auto identities = path.splitter(".").map!(s => s.splitter("[")).joiner;

            ComponentType current = component;

            foreach (identity; identities) {

                if (identity.endsWith("]")) {
                    identity = identity[0 .. $ - 1];

                    if (identity.startsWith("\"") && identity.endsWith("\"")) {
                        identity = identity[1 .. $ - 1];
                    }

                    if (indexer.has(current, identity)) {

                        current = this.indexer.access(current, identity);
                    } else {

                        return false;
                    }
                } else if (this.accessor.has(current, identity)) {

                    current = this.accessor.access(current, identity);
                } else {

                    return false;
                }
            }

            return true;
        }
    }
}

class TaggedElementPropertyAccessorWrapper(Tagged : TaggedAlgebraic!Y, PropertyAccessorType : PropertyAccessor!(X, Z), X, Z, Y) : PropertyAccessor!(Tagged, Tagged) {

    private {
        PropertyAccessorType accessor_;
    }

    public {
        this(PropertyAccessorType accessor) {
            this.accessor = accessor;
        }

        @property {
            /**
            Set accessor

            Params:
                accessor = the property accessor that is wrapped

            Returns:
                typeof(this)
            **/
            typeof(this) accessor(PropertyAccessorType accessor) @safe nothrow pure {
                this.accessor_ = accessor;

                return this;
            }

            /**
            Get accessor

            Returns:
                PropertyAccessorType
            **/
            inout(PropertyAccessorType) accessor() @safe nothrow pure inout {
                return this.accessor_;
            }
        }

        Tagged access(Tagged component, string property) const
        {
            if (this.has(component, property)) {
                return Tagged(this.accessor.access(cast(X) component, property));
            }

            import aermicioi.aedi.exception.not_found_exception : NotFoundException;
            import std.conv : text;
            throw new NotFoundException(text(component, " does not have ", property));
        }

        bool has(in Tagged component, string property) const {
            import std.meta;
            import aermicioi.util.traits;

            static foreach (e; staticMap!(identifier, EnumMembers!(Tagged.Kind))) {
                static if (mixin("is(typeof(Y." ~ e ~ ") : X)")) {
                    if (mixin("component.Kind." ~ e ~ " == component.kind")) {

                        import std.stdio;
                        return this.accessor.has(cast(X) (cast() component), property);
                    }

                    return false;
                }
            }

            assert(false, "TaggedAlgebraic does not have " ~ fullyQualifiedName!X ~ " as member");
        }
    }
}