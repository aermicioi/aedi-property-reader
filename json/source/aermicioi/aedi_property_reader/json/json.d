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
module aermicioi.aedi_property_reader.json.json;

import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi_property_reader.json.accessor;
import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi_property_reader.json.convertor;
import aermicioi.aedi_property_reader.core.convertor;
import aermicioi.aedi_property_reader.core.type_guesser;
import aermicioi.aedi_property_reader.core.document;
import aermicioi.aedi_property_reader.json.type_guesser;
import std.json;
import std.experimental.allocator;

alias JsonDocumentContainer = AdvisedDocumentContainer!(JSONValue, JSONValue, JsonConvertor);

/**
Create a convertor container with data source being json document.

Params:
    value = source of data for container to use to construct components.
    accessor = property accessing logic
    guesser = type guesser based on held json value
    allocator = allocator used to allocate converted values
Returns:
    JsonConvertorContainer
**/
auto json(JSONValue value, PropertyAccessor!JSONValue accessor, TypeGuesser!JSONValue guesser, IAllocator allocator = theAllocator) {

    JsonDocumentContainer container = new JsonDocumentContainer(value);
    container.guesser = guesser;
    container.accessor = accessor;
    container.allocator = allocator;

    return container;
}

/**
ditto
**/
auto json(JSONValue value, TypeGuesser!JSONValue guesser, IAllocator allocator = theAllocator) {

    return value.json(accessor, guesser, allocator);
}

/**
ditto
**/
auto json(JSONValue value, IAllocator allocator = theAllocator) {

    return value.json(accessor, new JsonTypeGuesser, allocator);
}

/**
ditto
**/
auto json(IAllocator allocator = theAllocator) {

    return JSONValue().json(allocator);
}

/**
Create a convertor container with data source being json document.

Params:
    pathOrData = path to source of data or source data itself in form of string for container to use to construct components.
    returnEmpty = wheter to return or not a locator with empty data source
Returns:
    JsonConvertorContainer
**/
auto json(string pathOrData, bool returnEmpty = true) {
    import std.file;

    if (pathOrData.exists) {
        pathOrData = pathOrData.readText();
    }

    try {

        return json(parseJSON(pathOrData));
    } catch (Exception e) {

        if (returnEmpty) {
            return json();
        }

        throw new Exception(
            "Could not create json convertor container from file or content passed in pathOrData: " ~ pathOrData,
            e
        );
    }
}

private auto accessor() {
    return dsl(new JsonPropertyAccessor, new JsonIndexAccessor);
}