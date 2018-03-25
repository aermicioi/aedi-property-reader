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


class DocumentContainer(DocumentType, FieldType = DocumentType) : Container, Storage!(Convertor, string), AllocatorAware!() {

    mixin AllocatorAwareMixin!(typeof(this));

    private {
        Convertor[string] convertors;
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

            trace("Searching for suitable convertor for ", identity, " of ", typeid(FieldType));

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

class AdvisedDocumentContainer(DocumentType, FieldType, alias AdvisedConvertor) : DocumentContainer!(DocumentType, FieldType) {

    public {

        this(DocumentType document) {
            super(document);
        }
    }
}