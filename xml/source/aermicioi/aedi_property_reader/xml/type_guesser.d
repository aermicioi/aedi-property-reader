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
module aermicioi.aedi_property_reader.xml.type_guesser;

import aermicioi.aedi.configurer.annotation.annotation;
import aermicioi.aedi_property_reader.convertor.type_guesser;
import aermicioi.aedi_property_reader.xml.accessor;
import std.xml;

@component
auto delegatingObjectTypeGuesser(
    TypeGuesser!Element elementGuesser,
    TypeGuesser!string attributeGuesser
) {
    return new DelegatingObjectTypeGuesser!(Element, string)(elementGuesser, attributeGuesser);
}

/**
ditto
**/
@component
class ElementTypeGuesser : TypeGuesser!Element {

    public {

        /**
        Guess type of underlying xml element or attribute

        Params:
            serialized = xml element or attribute

        Returns:
            TypeInfo of contained element
        **/
        TypeInfo guess(Element serialized) const @trusted {
            import std.algorithm : all;
            import std.meta : AliasSeq;

            if (serialized.items.all!(item => (() @trusted => cast(Text) item)() !is null)) {
                return typeid(string);
            }

            static foreach (Type; AliasSeq!(CData, ProcessingInstruction, Element)) {
                if (serialized.items.all!(item => (() @trusted => cast(Type) item)() !is null)) {
                    return typeid(Type[]);
                }
            }

            return typeid(Item[]);
        }
    }
}