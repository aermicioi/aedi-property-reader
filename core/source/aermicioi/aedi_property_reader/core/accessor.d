module aermicioi.aedi_property_reader.core.accessor;

import std.traits : fullyQualifiedName, isImplicitlyConvertible, EnumMembers;
import taggedalgebraic;
import std.array;
import std.conv;
import aermicioi.aedi.exception.not_found_exception;
import std.algorithm;
import std.range;
import std.exception : enforce;

interface PropertyAccessor(ComponentType, FieldType = ComponentType, KeyType = string) {

    FieldType access(ComponentType component, in KeyType property) const;

    bool has(in ComponentType component, in KeyType property) const;
}

class AggregatePropertyAccessor(ComponentType, FieldType = ComponentType, KeyType = string) : PropertyAccessor!(ComponentType, FieldType, KeyType) {

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
        typeof(this) accessors(PropertyAccessor!(ComponentType, FieldType, KeyType)[] accessors) @safe nothrow pure {
            this.accessors_ = accessors;

            return this;
        }

        /**
        ditto
        **/
        typeof(this) accessors(PropertyAccessor!(ComponentType, FieldType, KeyType)[] accessors...) @safe nothrow pure {
            this.accessors_ = accessors;

            return this;
        }

        /**
        Get accessors

        Returns:
            PropertyAccessor!(ComponentType, FieldType, KeyType)
        **/
        inout(PropertyAccessor!(ComponentType, FieldType, KeyType)[]) accessors() @safe nothrow pure inout {
            return this.accessors_;
        }

        FieldType access(ComponentType component, in KeyType property) const {

            foreach (accessor; this.accessors) {

                if (accessor.has(component, property)) {

                    return accessor.access(component, property);
                }
            }

            import aermicioi.aedi.exception.not_found_exception : NotFoundException;
            throw new NotFoundException("Could not find element");
        }

        bool has(in ComponentType component, in KeyType property) const {

            foreach (accessor; this.accessors) {

                if (accessor.has(component, property)) {
                    return true;
                }
            }

            return false;
        }
    }
}

class PropertyPathAccessor(ComponentType, FieldType = ComponentType, KeyType = string) : PropertyAccessor!(ComponentType, FieldType, KeyType)
    if (isImplicitlyConvertible!(FieldType, ComponentType) && isInputRange!KeyType) {

    private {
        PropertyAccessor!(ComponentType, FieldType) accessor_;
        PropertyAccessor!(ComponentType, FieldType) indexer_;

        ElementType!KeyType propertyAccessor_;
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
        typeof(this) accessor(PropertyAccessor!(ComponentType, FieldType, KeyType) accessor) @safe nothrow pure {
            this.accessor_ = accessor;

            return this;
        }

        /**
        Get accessor

        Returns:
            PropertyAccessor!(ComponentType, FieldType, KeyType)
        **/
        inout(PropertyAccessor!(ComponentType, FieldType, KeyType)) accessor() @safe nothrow pure inout {
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
        typeof(this) indexer(PropertyAccessor!(ComponentType, FieldType, KeyType) indexer) @safe nothrow pure {
            this.indexer_ = indexer;

            return this;
        }

        /**
        Get indexer

        Returns:
            PropertyAccessor!(ComponentType, FieldType)
        **/
        inout(PropertyAccessor!(ComponentType, FieldType, KeyType)) indexer() @safe nothrow pure inout {
            return this.indexer_;
        }

        /**
        Set propertyAccessor

        Params:
            propertyAccessor = property splitter used to cut up the property path into multiple points

        Returns:
            typeof(this)
        **/
        typeof(this) propertyAccessor(ElementType!KeyType propertyAccessor) @safe nothrow pure {
            this.propertyAccessor_ = propertyAccessor;

            return this;
        }

        /**
        Get propertyAccessor

        Returns:
            ElementType!KeyType
        **/
        inout(ElementType!KeyType) propertyAccessor() @safe nothrow pure inout {
            return this.propertyAccessor_;
        }

        FieldType access(ComponentType component, in KeyType path) const {
            import std.algorithm;
            import std.range;

            auto identities = path.splitter(this.propertyAccessor);

            ComponentType current = component;

            foreach (identity; identities) {

                if (this.accessor.has(component, identity)) {

                    current = this.accessor.access(component, identity);
                } else if (this.indexer.has(component, identity)) {

                    current = this.indexer.access(component, identity);
                } else {

                    throw new NotFoundException(text("Could not find ", identity, " in ", current, " for property path of ", path));
                }
            }

            return current;
        }

        bool has(in ComponentType component, in KeyType path) const {

            auto identities = path.splitter(this.propertyAccessor);

            ComponentType current = cast(ComponentType) component;

            foreach (identity; identities) {
                if (!this.accessor.has(current, identity) || !this.indexer.has(current, identity)) {
                    return false;
                }

                if (this.accessor.has(current, identity)) {
                    current = this.accessor.access(current, identity);
                } else {
                    current = this.indexer.access(current, identity);
                }
            }

            return true;
        }
    }
}

class ArrayIndexedPropertyAccessor(ComponentType, FieldType = ComponentType, KeyType = string) : PropertyAccessor!(ComponentType, FieldType, KeyType)
    if (isBidirectionalRange!KeyType) {

    private {
        alias EType = ElementType!KeyType;
        EType beggining_;
        EType ending_;

        PropertyAccessor!(ComponentType, FieldType, KeyType) accessor_;
        PropertyAccessor!(ComponentType, FieldType, KeyType) indexer_;
    }

    public {

        this(EType beggining, EType ending, PropertyAccessor!(ComponentType, FieldType, KeyType) accessor, PropertyAccessor!(ComponentType, FieldType, KeyType) indexer) {
            this.beggining_ = beggining;
            this.ending_ = ending;
            this.accessor = accessor;
            this.indexer = indexer;
        }

        /**
        Set beggining

        Params:
            beggining = element denoting beggining of array syntax in identity, ex. [

        Returns:
            typeof(this)
        **/
        typeof(this) beggining(EType beggining) @safe nothrow pure {
            this.beggining_ = beggining;

            return this;
        }

        /**
        Get beggining

        Returns:
            EType
        **/
        inout(EType) beggining() @safe nothrow pure inout {
            return this.beggining_;
        }

        /**
        Set ending

        Params:
            ending = element denoting the end of array indexing, ex. ]

        Returns:
            typeof(this)
        **/
        typeof(this) ending(EType ending) @safe nothrow pure {
            this.ending_ = ending;

            return this;
        }

        /**
        Get ending

        Returns:
            EType
        **/
        inout(EType) ending() @safe nothrow pure inout {
            return this.ending_;
        }

        /**
        Set accessor

        Params:
            accessor = accessor used to access property part from indexed property

        Returns:
            typeof(this)
        **/
        typeof(this) accessor(PropertyAccessor!(ComponentType, FieldType, KeyType) accessor) @safe nothrow pure {
            this.accessor_ = accessor;

            return this;
        }

        /**
        Get accessor

        Returns:
            PropertyAccessor!(ComponentType, FieldType, KeyType)
        **/
        inout(PropertyAccessor!(ComponentType, FieldType, KeyType)) accessor() @safe nothrow pure inout {
            return this.accessor_;
        }

        /**
        Set indexer

        Params:
            indexer = property accessor used to access element based on contents in index part of property

        Returns:
            typeof(this)
        **/
        typeof(this) indexer(PropertyAccessor!(ComponentType, FieldType, KeyType) indexer) @safe nothrow pure {
            this.indexer_ = indexer;

            return this;
        }

        /**
        Get indexer

        Returns:
            PropertyAccessor!(ComponentType, FieldType, KeyType)
        **/
        inout(PropertyAccessor!(ComponentType, FieldType, KeyType)) indexer() @safe nothrow pure inout {
            return this.indexer_;
        }

        FieldType access(ComponentType component, in KeyType path) const {

            auto splitted = path.splitter(this.beggining);

            enforce!NotFoundException(!splitted.empty, text("Malformed indexed property ", path));

            FieldType property = this.accessor.access(component, splitted.front);
            splitted.popFront;

            enforce!NotFoundException(!splitted.empty, text("Malformed indexed property ", path, ", no index part found"));
            enforce!NotFoundException(!splitted.front.endsWith(this.ending), text("Malformed indexed property ", path, ", no closing ] found"));

            return this.indexer.access(component, splitted.front.drop(1).dropBack(1));
        }

        bool has(in ComponentType component, in KeyType path) const {

            auto splitted = path.splitter(this.beggining);

            if (splitted.empty) {
                return false;
            }

            FieldType property = this.accessor.access(cast(ComponentType) component, splitted.front);
            splitted.popFront;

            if (splitted.empty || !splitted.front.endsWith(this.ending)) {
                return false;
            }

            return this.indexer.has(property, splitted.front.drop(1).dropBack(1));
        }
    }
}

class TickedPropertyAccessor(ComponentType, FieldType = ComponentType, KeyType = string) : PropertyAccessor!(ComponentType, FieldType, KeyType)
    if (isBidirectionalRange!KeyType) {

    private {
        alias EType = ElementType!KeyType;
        EType tick_;

        PropertyAccessor!(ComponentType, FieldType, KeyType) accessor_;
    }

    public {

        this(EType tick, PropertyAccessor!(ComponentType, FieldType, KeyType) accessor) {
            this.tick = tick;
            this.accessor = accessor;
        }

        /**
        Set tick

        Params:
            tick = ticking element used to encapsulate property

        Returns:
            typeof(this)
        **/
        typeof(this) tick(EType tick) @safe nothrow pure {
            this.tick_ = tick;

            return this;
        }

        /**
        Get tick

        Returns:
            EType
        **/
        inout(EType) tick() @safe nothrow pure inout {
            return this.tick_;
        }

        /**
        Set accessor

        Params:
            accessor = accessor used to access property enclosed in ticks

        Returns:
            typeof(this)
        **/
        typeof(this) accessor(PropertyAccessor!(ComponentType, FieldType, KeyType) accessor) @safe nothrow pure {
            this.accessor_ = accessor;

            return this;
        }

        /**
        Get accessor

        Returns:
            PropertyAccessor!(ComponentType, FieldType, KeyType)
        **/
        inout(PropertyAccessor!(ComponentType, FieldType, KeyType)) accessor() @safe nothrow pure inout {
            return this.accessor_;
        }

        FieldType access(ComponentType component, in KeyType path) const {

            enforce!NotFoundException(!(path.front == this.tick) || !(path.back == this.tick), text("Malformed ticked property ", path, ", missing a tick"));

            return this.accessor.access(component, path.drop(1).dropBack(1));
        }

        bool has(in ComponentType component, in KeyType path) const {

            return (!(path.front == this.tick) || !(path.back == this.tick)) && this.accessor.has(component, path.drop(1).dropBack(2));
        }
    }
}

class TaggedElementPropertyAccessorWrapper(Tagged : TaggedAlgebraic!Y, PropertyAccessorType : PropertyAccessor!(X, Z, KeyType), X, Z, KeyType = string, Y) : PropertyAccessor!(Tagged, Tagged, KeyType) {

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

        Tagged access(Tagged component, in KeyType property) const
        {
            if (this.has(component, property)) {
                return Tagged(this.accessor.access(cast(X) component, property));
            }

            import aermicioi.aedi.exception.not_found_exception : NotFoundException;
            import std.conv : text;
            throw new NotFoundException(text(component, " does not have ", property));
        }

        bool has(in Tagged component, in KeyType property) const {
            import std.meta;
            import aermicioi.util.traits;

            static foreach (e; staticMap!(identifier, EnumMembers!(Tagged.Kind))) {
                static if (mixin("is(typeof(Y." ~ e ~ ") : X)")) {
                    if (mixin("component.Kind." ~ e ~ " == component.kind")) {

                        return this.accessor.has(cast(const(X)) component, property);
                    }

                    return false;
                }
            }

            assert(false, "TaggedAlgebraic does not have " ~ fullyQualifiedName!X ~ " as member");
        }
    }
}

class AssociativeArrayAccessor(Key, Type) : PropertyAccessor!(Type[const(Key)], Type, Key) {

    public {

        Type access(Type[const(Key)] component, in Key property) const {
            auto peek = property in component;
            enforce!NotFoundException(peek, text("Could not find ", property, " in associative array ", component));

            return *peek;
        }

        bool has(in Type[const(Key)] component, in Key property) const {
            return (property in component) !is null;
        }
    }
}

class ArrayAccessor(Type) : PropertyAccessor!(Type[], Type, size_t) {

    public {

        FieldType access(Type[] component, in size_t property) const {
            enforce!NotFoundException(property >= component.length, "Could not find property ", property, " in array ", component);

            return component[property];
        }

        bool has(in Type[] component, in size_t property) const {
            return property >= component.length;
        }
    }
}

auto dsl(ComponentType, FieldType, KeyType)(PropertyAccessor!(ComponentType, FieldType, KeyType) accessor, PropertyAccessor!(ComponentType, FieldType, KeyType) indexer) {
    return new PropertyPathAccessor!(ComponentType, FieldType, KeyType)(
        accessor,
        new AggregatePropertyAccessor!(ComponentType, FieldType, KeyType)(
            accessor,
            new ArrayIndexedPropertyAccessor!(ComponentType, FieldType, KeyType)(
                '[', ']',
                accessor,
                new AggregatePropertyAccessor!(ComponentType, FieldType, KeyType)(
                    new TickedPropertyAccessor!(ComponentType, FieldType, KeyType)(
                        '\'',
                        accessor,
                    ),
                    new TickedPropertyAccessor!(ComponentType, FieldType, KeyType)(
                        '"',
                        accessor,
                    ),
                    indexer
                )
            )
        )
    );
}