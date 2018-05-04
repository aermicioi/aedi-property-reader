/**
License:
    Boost Software License - Version 1.0 - August 17th, 2003

    Permission is hereby granted, free of charge, to any person or organization
    obtaining a copy of the software and accompanying documentation covered by
    this license (the "Software") to use, reproduce, display, distribute,
    execute, and transmit the Software, and to prepare derivative works of the
    Software, and to permit third-parties to whom the Software is furnished to
    do so, all subject to the following:

    The copyright notices in the Software and this entire statement, including
    the above license grant, this restriction and the following disclaimer,
    must be included in all copies of the Software, in whole or in part, and
    all derivative works of the Software, unless such copies or derivative
    works are solely in the form of machine-executable object code generated by
    a source language processor.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
    SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
    FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
    ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.

Authors:
    Alexandru Ermicioi
**/
module aermicioi.aedi_property_reader.core.document;

import aermicioi.aedi;
import aermicioi.aedi_property_reader.core.exception : ConvertorException;
import aermicioi.aedi_property_reader.core.convertor;
import aermicioi.aedi_property_reader.core.placeholder;
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

/**
An implementation of Container interface from aedi IoC providing access to
components that are stored into a document.

An implementation of Container interface from aedi IoC providing access to
components that are stored into a document where a document could be anything
that is accessable by a PropertyAccessor implementation. Components stored in
document will be converted according to convertor associated to property
path from document.
**/
class DocumentContainer(DocumentType, FieldType = DocumentType) :
    Container, Storage!(Convertor, string),
    AllocatorAware!(),
    Convertor
{

    mixin AllocatorAwareMixin!(typeof(this));

    private {
        Convertor[string] convertors;
        PropertyAccessor!(DocumentType, FieldType) accessor_;
        TypeGuesser!FieldType guesser_;

        DocumentType document_;
        Object[string] components;
    }

    public {

        /**
        Constructor for a container for document.

        Params:
            document = document stored in container.
        **/
        this(DocumentType document) {
            this.document = document;
        }

        @property {

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
                if (this.accessor.has(this.document, identity)) {
                    this.get(identity);
                }
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
            debug(trace) trace("Searching for \"", identity, '"');

            Object converted;

            if (auto peeked = identity in this.components) {
                debug(trace) trace("Found already converted \"", identity, '"');

                return *peeked;
            }

            if (!this.accessor.has(this.document, identity)) {
                throw new NotFoundException(text("Could not find \"", identity, "\" in document of type ", typeid(DocumentType)));
            }

            static if (is(FieldType : Object)) {

                FieldType document = this.accessor.access(this.document, identity);
            } else {
                import std.typecons : scoped;
                auto document = scoped!(PlaceholderImpl!FieldType)(this.accessor.access(this.document, identity));
            }

            debug(trace) trace("Searching for suitable convertor for \"", identity, "\" of ", typeid(FieldType));

            if (auto convertor = identity in this.convertors) {
                if (convertor.to !is typeid(void)) {
                    debug(trace) trace("Found convertor for \"", identity, "\" commencing conversion to ", convertor.to);

                    converted = (*convertor).convert(document, convertor.to, this.allocator);
                    this.components[identity] = converted;
                    return converted;
                }
            }

            debug(trace) trace("No suitable convertor found, attempting to guess the desired type.");
            static if (is(FieldType : Object)) {

                TypeInfo guess = this.guesser.guess(document);
            } else {

                TypeInfo guess = this.guesser.guess(document.value);
            }
            debug(trace) trace("Guessed ", guess, " type, commencing conversion");
            return this.convert(document, guess, this.allocator);
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

        @property {

            /**
            Get the type info of component that convertor can convert from.

            Get the type info of component that convertor can convert from.
            The method is returning the default type that it is able to convert,
            though it is not necessarily limited to this type only. More generalistic
            checks should be done by convertsFrom method.

            Returns:
                type info of component that convertor is able to convert.
            **/
            TypeInfo from() const nothrow {
                return typeid(FieldType);
            }

            /**
            Get the type info of component that convertor is able to convert to.

            Get the type info of component that convertor is able to convert to.
            The method is returning the default type that is able to convert,
            though it is not necessarily limited to this type only. More generalistic
            checks should be done by convertsTo method.

            Returns:
                type info of component that can be converted to.
            **/
            TypeInfo to() const nothrow {
                return typeid(void);
            }
        }

        /**
        Check whether convertor is able to convert from.

        Check whether convertor is able to convert from.
        The intent of method is to implement customized type checking
        is not limited immediatly to supported default from component.

        Params:
            from = the type info of component that could potentially be converted by convertor.
        Returns:
            true if it is able to convert from, or false otherwise.
        **/
        bool convertsFrom(TypeInfo from) const nothrow {
            return this.convertors.byValue.canFind!(convertor => convertor.convertsFrom(from));
        }

        /**
        Check whether convertor is able to convert from.

        Check whether convertor is able to convert from.
        The method will try to extract type info out of from
        object and use for subsequent type checking.
        The intent of method is to implement customized type checking
        is not limited immediatly to supported default from component.

        Params:
            from = the type info of component that could potentially be converted by convertor.
        Returns:
            true if it is able to convert from, or false otherwise.
        **/
        bool convertsFrom(in Object from) const nothrow {
            return this.convertors.byValue.canFind!(convertor => convertor.convertsFrom(from));
        }

        /**
        Check whether convertor is able to convert to.

        Check whether convertor is able to convert to.
        The intent of the method is to implement customized type checking
        that is not limited immediatly to supported default to component.

        Params:
            to = type info of component that convertor could potentially convert to.

        Returns:
            true if it is able to convert to, false otherwise.
        **/
        bool convertsTo(TypeInfo to) const nothrow {
            return this.convertors.byValue.canFind!(convertor => convertor.convertsTo(to));
        }

        /**
        Check whether convertor is able to convert to.

        Check whether convertor is able to convert to.
        The method will try to extract type info out of to object and use
        for subsequent type checking.
        The intent of the method is to implement customized type checking
        that is not limited immediatly to supported default to component.

        Params:
            to = type info of component that convertor could potentially convert to.

        Returns:
            true if it is able to convert to, false otherwise.
        **/
        bool convertsTo(in Object to) const nothrow {
            return this.convertors.byValue.canFind!(convertor => convertor.convertsTo(to));
        }

        /**
        Convert from component to component.

        Params:
            from = original component that is to be converted.
            to = destination object that will be constructed out for original one.
            allocator = optional allocator that could be used to construct to component.
        Throws:
            ConvertorException when there is a converting error
            InvalidArgumentException when arguments passed are not of right type or state
        Returns:
            Resulting converted component.
        **/
        Object convert(in Object from, TypeInfo to, RCIAllocator allocator = theAllocator) {
            debug(trace) trace("Searching for convertor for ", from.identify, " to ", to);
            auto convertors = this.convertors.byValue.filter!(
                c => c.convertsTo(to) && c.convertsFrom(from)
            );

            if (!convertors.empty) {
                debug(trace) trace("Found convertor ", convertors.front.classinfo, " for ", from.identify, " to ", to);

                return convertors.front.convert(from, to, allocator);
            }

            debug(trace) trace("No suitable convertor found for ", from.identify, " to ", to);
            throw new ConvertorException(text("Could not convert ", from.identify));
        }

        /**
        Destroy component created using this convertor.

        Destroy component created using this convertor.
        Since convertor could potentially allocate memory for
        converted component, only itself is containing history of allocation,
        and therefore it is responsible as well to destroy and free allocated
        memory with allocator.

        Params:
            converted = component that should be destroyed.
            allocator = allocator used to allocate converted component.
        **/
        void destruct(ref Object converted, RCIAllocator allocator = theAllocator) {
            auto destructors = this.convertors.byValue.filter!(convertor => convertor.convertsTo(converted));

            enforce!ConvertorException(!destructors.empty, text("Could not destroy ", converted.identify, ", no suitable convertor found."));

            destructors.front.destruct(converted, allocator);
        }
    }
}

/**
An implementation of document container that holds an advised convertor along the document for usage as default constructor for convertors
in configuration api.
**/
class AdvisedDocumentContainer(DocumentType, FieldType, alias AdvisedConvertor) : DocumentContainer!(DocumentType, FieldType) {

    public {

        this(DocumentType document) {
            super(document);
        }
    }
}