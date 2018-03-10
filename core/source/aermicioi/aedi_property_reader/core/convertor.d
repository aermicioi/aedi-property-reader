module aermicioi.aedi_property_reader.core.convertor;

import aermicioi.aedi;
import aermicioi.aedi_property_reader.core.exception : ConvertorException;
import aermicioi.aedi.storage.wrapper;
import std.meta;
import std.conv;
import std.experimental.allocator;
import std.exception : enforce;
import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi_property_reader.core.type_guesser;
import std.algorithm;
import std.array;
import std.experimental.logger;

alias FunctionalConvertor(To, From) = void function(in From, ref To, IAllocator allocator = theAllocator);
alias DelegateConvertor(To, From) = void delegate(in From, ref To, IAllocator allocator = theAllocator);

template isConvertor(alias T) {
    static if (is(typeof(&T) : void function(in Y, ref X, IAllocator allocator = theAllocator), Y, X) || is(typeof(&T) : void delegate(in Y, ref X, IAllocator allocator = theAllocator), Y, X)) {
        enum bool Yes = true;

        alias To = X;
        alias From = Y;
    } else {

        enum bool Yes = false;
    }
}

template isConvertor(alias T, To, From) {
    static if (isConvertor!T.Yes && is(isConvertor!T.To == To) && is(isConvertor!T.From == From)) {
        alias isConvertor = isConvertor!T;
    } else {
        enum Yes = false;
    }
}

template maybeConvertor(alias T, To, From) {
    static if (isConvertor!(T!(To, From)).Yes) {
        enum Yes = true;
        alias Convertor = T!(To, From);
        alias Info = isConvertor!Convertor;
    } else {
        enum Yes = false;
    }
}

alias FunctionalDestructor(To) = void function (ref To, IAllocator = theAllocator);
alias DelegateDestructor(To) = void delegate (ref To, IAllocator = theAllocator);

template isDestructor(alias T) {
    static if (is(typeof(&T) : void function (ref X, IAllocator = theAllocator), X) || is(typeof(&T) : void delegate (ref X, IAllocator = theAllocator), X)) {
        enum bool Yes = true;

        alias To = X;
    } else {

        enum bool Yes = false;
    }
}

template isDestructor(T, To) {
    static if (isDestructor!T.Yes && is(isDestructor!T.To == To)) {
        alias isDestructor = isDestructor!T;
    } else {
        enum Yes = false;
    }
}

template maybeDestructor(alias T, To) {
    static if (isDestructor!(T!To).Yes) {
        enum Yes = true;
        alias Destructor = T!(To);
        alias Info = isDestructor!Destructor;
    } else {
        enum Yes = false;
    }
}

interface Convertor {
    @property {
        TypeInfo from() const;
        TypeInfo to() const;
    }

    bool convertsFrom(TypeInfo from) const;
    bool convertsFrom(in Object from) const;
    bool convertsTo(TypeInfo to) const;
    bool convertsTo(in Object to) const;

    Object convert(in Object from, TypeInfo to, IAllocator allocator = theAllocator);
    void destruct(ref Object converted, IAllocator allocator = theAllocator);
}

class CallbackConvertor(alias convertor, alias destructor) : Convertor
    if (isConvertor!convertor.Yes && isDestructor!destructor.Yes) {

    private {
        alias Info = isConvertor!convertor;
    }

    public {

        @property {
            /**
            Get from

            Returns:
                TypeInfo
            **/
            TypeInfo from() @safe nothrow pure const {
                return typeid(Info.From);
            }

            /**
            Get to

            Returns:
                TypeInfo
            **/
            TypeInfo to() @safe nothrow pure const {
                return typeid(Info.To);
            }
        }

        bool convertsFrom(TypeInfo from) const {
            return typeid(Info.From) is from;
        }

        bool convertsFrom(in Object from) const {
            static if (is(From : Object)) {

                return this.convertsFrom(from.classinfo);
            } else {

                return this.convertsFrom((cast(Placeholder) from).type);
            }
        }

        bool convertsTo(TypeInfo to) const {
            return typeid(Info.To) is to;
        }

        bool convertsTo(in Object To) const {
            static if (is(To : Object)) {

                return this.convertsTo(to.classinfo);
            } else {

                return this.convertsTo((cast(Placeholder) to).type);
            }
        }

        Object convert(in Object from, TypeInfo to, IAllocator allocator = theAllocator)
        {
            enforce!ConvertorException(this.convertsTo(to), text(to, " is not supported by convertor expected ", typeid(Info.To)));
            enforce!ConvertorException(this.convertsFrom(from), text(this.unwrap(from), " is not supported by convertor expected ", typeid(Info.From)));

            Info.From naked;

            static if (is(From : Object)) {
                naked = cast(From) from;

                if (naked is null) {
                    throw new ConvertorException(text("Cannot convert ", from.classinfo, " only supported ", this.from));
                }
            } else {

                auto wrapper = (cast(Wrapper!(Info.From)) from);

                if (wrapper is null) {
                    throw new ConvertorException(text("Cannot convert ", this.unwrap(from), " only supported ", this.from));
                }

                naked = wrapper.value;
            }


            static if (is(Info.To : Object)) {
                Info.To placeholder = make!(Info.To);

                convertor(naked, placeholder, allocator);
            } else {
                PlaceholderImpl!(Info.To) placeholder = allocator.make!(PlaceholderImpl!(Info.To))(Info.To.init);

                convertor(naked, placeholder.value, allocator);
            }

            return placeholder;
        }

        void destruct(ref Object converted, IAllocator allocator = theAllocator) {
            static if (is(Info.To : Object)) {

                destructor(converted, allocator);
            } else {
                auto container = cast(Wrapper!(Info.To)) converted;

                destructor(container.value);
                allocator.dispose(converted);
            }
        }
    }

    private TypeInfo unwrap(in Object obj) const {
        static if (is(From : obj)) {
            return obj;
        } else {
            return (cast(Placeholder) obj).type;
        }
    }
}

class AggregateConvertor : Convertor {
    import std.algorithm;

    private {
        Convertor[] convertors_;
    }

    public {

        /**
        Default constructor for AggregateConvertor
        **/
        this(Convertor[] convertors...) {
            this.convertors = convertors.dup;
        }

        /**
        Set convertors

        Params:
            convertors = convertors used to convert from one type to another

        Returns:
            typeof(this)
        **/
        typeof(this) convertors(Convertor[] convertors) @safe nothrow pure {
            this.convertors_ = convertors;

            return this;
        }

        /**
        Get convertors

        Returns:
            Convertor[]
        **/
        inout(Convertor[]) convertors() @safe nothrow pure inout {
            return this.convertors_;
        }

        @property {
            /**
            Get from

            Returns:
                TypeInfo
            **/
            TypeInfo from() @safe nothrow pure const {
                return typeid(void);
            }

            /**
            Get to

            Returns:
                TypeInfo
            **/
            TypeInfo to() @safe nothrow pure const {
                return typeid(void);
            }
        }

        bool convertsFrom(TypeInfo from) const {
            return this.convertors.canFind!(c => c.convertsFrom(from));
        }

        bool convertsFrom(in Object from) const {
            return this.convertors.canFind!(c => c.convertsFrom(from));
        }

        bool convertsTo(TypeInfo to) const {
            return this.convertors.canFind!(c => c.convertsTo(to));
        }

        bool convertsTo(in Object to) const {
            return this.convertors.canFind!(c => c.convertsTo(to));
        }

        Object convert(in Object from, TypeInfo to, IAllocator allocator = theAllocator)
        {
            auto convertors = this.convertors.find!(c => c.convertsFrom(from) && c.convertsTo(to));

            if (!convertors.empty) {
                return convertors[0].convert(from, to, allocator);
            }

            throw new ConvertorException(text("Could not convert ", typeid(from), " to type ", to));
        }

        void destruct(ref Object converted, IAllocator allocator = theAllocator) {
            auto convertors = this.convertors.find!(c => c.convertsFrom(from) && c.convertsTo(to));

            if (convertors.empty) {
                throw new ConvertorException(text("Could not destroy ", converted));
            }

            convertors[0].destruct(converted, allocator);
        }
    }
}

To convert(To, From)(Convertor convertor, From from, IAllocator allocator = theAllocator) {
    import std.typecons : scoped;
    static if (is(From : Object)) {

        Object converted = convertor.convert(from, typeid(To), allocator);
    } else {

        Object converted = convertor.convert(scoped!(WrapperImpl!From)(from), typeid(To), allocator);
    }

    static if (is(To : Object)) {

        return cast(To) converted;
    } else {

        scope(exit) allocator.dispose(converted);
        return (cast(Wrapper!To) converted).value;
    }
}

interface Placeholder {
    TypeInfo type() const;
}

class PlaceholderImpl(T) : WrapperImpl!T, Placeholder {

    this() @disable;

    this(ref T value) {
        super(value);
    }

    this(T value) {
        super(value);
    }

    TypeInfo type() const {
        return typeid(T);
    }
}

class DocumentContainer(DocumentType, FieldType = DocumentType) : Container, Storage!(Convertor, string) {

    private {
        Convertor[string] convertors;
        IAllocator allocator_;
        PropertyAccessor!(DocumentType, FieldType) accessor_;
        TypeGuesser!FieldType guesser_;

        DocumentType document_;
        Object[string] components;
    }

    public {
        this(DocumentType document) {
            this.document = document;
        }

        @property {
            /**
            Set allocator

            Params:
                allocator = allocator used to allocate memory for converted components.

            Returns:
                typeof(this)
            **/
            typeof(this) allocator(IAllocator allocator) @safe nothrow pure {
                this.allocator_ = allocator;

                return this;
            }

            /**
            Get allocator

            Returns:
                IAllocator
            **/
            inout(IAllocator) allocator() @safe nothrow pure inout {
                return this.allocator_;
            }

            /**
            Set guesser

            Params:
                guesser = guesser uset to guess the D type of document.

            Returns:
                typeof(this)
            **/
            typeof(this) guesser(TypeGuesser!FieldType guesser) @safe nothrow pure {
                this.guesser_ = guesser;

                return this;
            }

            /**
            Get guesser

            Returns:
                TypeGuesser!FieldType
            **/
            inout(TypeGuesser!FieldType) guesser() @safe nothrow pure inout {
                return this.guesser_;
            }
            /**
            Set document

            Params:
                document = document containing valuable components

            Returns:
                typeof(this)
            **/
            typeof(this) document(DocumentType document) @safe nothrow {
                this.document_ = document;

                return this;
            }

            /**
            Get document

            Returns:
                DocumentType
            **/
            inout(DocumentType) document() @safe nothrow pure inout {
                return this.document_;
            }

            /**
            Set accessor

            Params:
                accessor = accessor used to navigate through document
            Returns:
                typeof(this)
            **/
            typeof(this) accessor(PropertyAccessor!(DocumentType, FieldType) accessor) @safe nothrow pure {
                this.accessor_ = accessor;

                return this;
            }

            /**
            Get accessor

            Returns:
                PropertyAccessor!(DocumentType, FieldType)
            **/
            inout(PropertyAccessor!(DocumentType, FieldType)) accessor() @safe nothrow pure inout {
                return this.accessor_;
            }
        }

        /**
		Save an element in Storage by key identity.

		Params:
			identity = identity of element in Storage.
			element = element which is to be saved in Storage.

		Return:
			Storage
		**/
        typeof(this) set(Convertor element, string identity) {
            this.convertors[identity] = element;

            return this;
        }

        /**
        Remove an element from Storage with identity.

        Remove an element from Storage with identity. If there is no element by provided identity, then no action is performed.

        Params:
        	identity = the identity of element to be removed.

    	Return:
    		Storage
        **/
        typeof(this) remove(string identity) {
            this.convertors.remove(identity);

            return this;
        }

        /**
        Sets up the internal state of container.

        Sets up the internal state of container (Ex, for singleton container it will spawn all objects that locator contains).
        **/
        Container instantiate() {
            foreach (identity, convertor; this.convertors) {
                this.get(identity);
            }

            return this;
        }

        /**
        Destruct all managed components.

        Destruct all managed components. The method denotes the end of container lifetime, and therefore destruction of all managed components
        by it.
        **/
        Container terminate() {
            foreach (identity, convertor; this.convertors) {
                if (auto component = identity in this.components) {
                    convertor.destruct(*component, this.allocator);
                }
            }

            return this;
        }

        /**
		Get a component that is associated with key.

		Params:
			identity = the element id.

		Throws:
			NotFoundException in case if the element wasn't found.

		Returns:
			Object element if it is available.
		**/
        Object get(string identity) {
            trace("Searching for ", identity);

            Object converted;

            if (auto peeked = identity in this.components) {
                trace("Found already converted ", identity);

                return *peeked;
            }

            static if (is(FieldType : Object)) {

                FieldType document = this.accessor.access(this.document, identity);
            } else {
                import std.typecons : scoped;
                auto document = scoped!(PlaceholderImpl!FieldType)(this.accessor.access(this.document, identity));
            }

            trace("Searching for suitable convertor for ", typeid(FieldType));

            if (auto convertor = identity in this.convertors) {
                if (convertor.to !is typeid(void)) {
                    trace("Found convertor for ", identity, " commencing conversion to ", convertor.to);

                    converted = (*convertor).convert(document, convertor.to, this.allocator);
                    this.components[identity] = converted;
                    return converted;
                }
            }

            trace("No suitable convertor found, attempting to guess the desired type.");
            static if (is(FieldType : Object)) {

                TypeInfo guess = this.guesser.guess(document);
            } else {

                TypeInfo guess = this.guesser.guess(document.value);
            }

            auto convertors = this.convertors.byValue.filter!(c => c.convertsTo(guess));

            if (!convertors.empty) {
                trace("Guessed convertable type of ", guess, " commencing conversion");

                converted = convertors.front.convert(document, guess, this.allocator);
                this.components[identity] = converted;
                return converted;
            }

            trace("No suitable convertor found for ", typeid(FieldType));
            throw new ConvertorException(text("Could not convert ", identity, " of ", typeid(FieldType), " type"));
        }

        /**
        Check if an element is present in Locator by key id.

        Note:
        	This check should be done for elements that locator actually contains, and
        	not in chained locator.
        Params:
        	identity = identity of element.

    	Returns:
    		bool true if an element by key is present in Locator.
        **/
        bool has(string identity) inout {
            if (identity in this.components) {

                return true;
            }

            return this.accessor.has(this.document, identity);
        }
    }
}

template AdvisedConvertor(alias convertor, alias destructor) {

    template AdvisedConvertor(To, From) {
        alias ConvertorInfo = maybeConvertor!(convertor, To, From);
        alias DestructorInfo = maybeDestructor!(destructor, To);

        static if (ConvertorInfo.Yes && DestructorInfo.Yes) {

            alias AdvisedConvertor = CallbackConvertor!(ConvertorInfo.Convertor, DestructorInfo.Destructor);
        } else {

            import std.traits : fullyQualifiedName;
            static assert(false, text(
                "Cannot convert type ",
                fullyQualifiedName!From,
                " to ",
                fullyQualifiedName!To,
                " ",
                fullyQualifiedName!convertor,
                " implements convertor ",
                ConvertorInfo.Yes,
                " ",
                fullyQualifiedName!destructor,
                " implements destructor ",
                DestructorInfo.Yes
                ));
        }
    }
}

class AdvisedDocumentContainer(DocumentType, FieldType, alias AdvisedConvertor) : DocumentContainer!(DocumentType, FieldType) {

    public {

        this(DocumentType document) {
            super(document);
        }
    }
}