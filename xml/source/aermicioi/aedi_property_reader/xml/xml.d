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
	aermicioi
**/
module aermicioi.aedi_property_reader.xml.xml;

import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi_property_reader.xml.accessor;
import aermicioi.aedi_property_reader.xml.convertor;
import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi_property_reader.core.convertor;
import aermicioi.aedi_property_reader.core.type_guesser;
import aermicioi.aedi_property_reader.xml.type_guesser;
import std.experimental.allocator;
import std.xml;
import std.traits;

alias XmlDocumentContainer = AdvisedDocumentContainer!(XmlElement, XmlElement, XmlConvertor);

/**
Create a convertor container with data source being xml document.

Params:
    value = source of data for container to use to construct components.
    accessor = property accessing logic
    guesser = type guesser based on held xml value
    allocator = allocator used to allocate converted values
Returns:
    JsonConvertorContainer
**/
auto xml(XmlElement value, PropertyAccessor!XmlElement accessor, TypeGuesser!XmlElement guesser, IAllocator allocator = theAllocator) {

    XmlDocumentContainer container = new XmlDocumentContainer(value);
    container.guesser = guesser;
    container.accessor = accessor;
    container.allocator = allocator;

    return container;
}

/**
ditto
**/
auto xml(XmlElement value, TypeGuesser!XmlElement guesser, IAllocator allocator = theAllocator) {

    return value.xml(accessor, guesser, allocator);
}

/**
ditto
**/
auto xml(XmlElement value, IAllocator allocator = theAllocator) {

    auto container = value.xml(accessor, new XmlTypeGuesser(new StringToScalarConvTypeGuesser), allocator);

    static if (is(StringToScalarConvTypeGuesser : StdConvTypeGuesser!(S, Types), S, Types...)) {
        static foreach (T; Types) {
            container.set(new XmlConvertor!(T, S), fullyQualifiedName!T);
        }
    }

    return container;
}

/**
ditto
**/
auto xml(IAllocator allocator = theAllocator) {

    return XmlElement("").xml(allocator);
}


/**
Create a convertor container with data source being xml document.

Params:
    pathOrData = path to a xml file or xml data itself
    returnEmpty = wheter to return or not a locator with empty data source
Returns:
    XmlConvertorContainer
**/
auto xml(string pathOrData, bool returnEmpty = true) {
    import std.file;
    try {
        check(pathOrData);
        return xml(XmlElement(new Document(pathOrData)));
    } catch (CheckException e) {

    }

    if (pathOrData.exists) {
        pathOrData = pathOrData.readText();

        try {
            check(pathOrData);
            return xml(XmlElement(new Document(pathOrData)));
        } catch(CheckException e) {

            if (returnEmpty) {
                return xml();
            }

            throw new Exception("Could not create xml convertor container from file or content passed in pathOrData: " ~ pathOrData, e);
        }
    }

    if (returnEmpty) {
        return xml();
    }

    throw new Exception("Could not create xml convertor container from file or content passed in pathOrData: " ~ pathOrData);
}

private auto accessor() {
    return dsl(
        new AggregatePropertyAccessor!XmlElement(
            new TaggedElementPropertyAccessorWrapper!(XmlElement, XmlAttributePropertyAccessor)(new XmlAttributePropertyAccessor),
            new TaggedElementPropertyAccessorWrapper!(XmlElement, XmlElementPropertyAccessor)(new XmlElementPropertyAccessor)
        ),
        new TaggedElementPropertyAccessorWrapper!(XmlElement, XmlElementIndexAccessor)(new XmlElementIndexAccessor)
    );
}