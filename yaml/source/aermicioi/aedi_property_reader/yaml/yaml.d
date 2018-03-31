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
module aermicioi.aedi_property_reader.yaml.yaml;

import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi_property_reader.core.convertor;
import aermicioi.aedi_property_reader.core.type_guesser;
import aermicioi.aedi_property_reader.yaml.accessor;
import aermicioi.aedi_property_reader.yaml.convertor;
import aermicioi.aedi_property_reader.core.document;
import aermicioi.aedi_property_reader.yaml.type_guesser;
import dyaml;
import std.experimental.logger;
import std.experimental.allocator;

alias YamlDocumentContainer = AdvisedDocumentContainer!(Node, Node, YamlConvertor);

/**
Create a convertor container with data source being yaml document.

Params:
    value = source of data for container to use to construct components.
    accessor = property accessing logic
    guesser = type guesser based on held yaml value
    allocator = allocator used to allocate converted values
Returns:
    JsonConvertorContainer
**/
auto yaml(Node value, PropertyAccessor!Node accessor, TypeGuesser!Node guesser, RCIAllocator allocator = theAllocator) {

    YamlDocumentContainer container = new YamlDocumentContainer(value);
    container.guesser = guesser;
    container.accessor = accessor;
    container.allocator = allocator;

    return container;
}

/**
ditto
**/
auto yaml(Node value, TypeGuesser!Node guesser, RCIAllocator allocator = theAllocator) {

    return value.yaml(accessor, guesser, allocator);
}

/**
ditto
**/
auto yaml(Node value, RCIAllocator allocator = theAllocator) {
    import std.meta : AliasSeq;
    auto container = value.yaml(accessor, new YamlTypeGuesser, allocator);
    import std.datetime;
    import std.traits;

    static foreach (T; AliasSeq!(
        long,
        real,
        ubyte[],
        bool,
        string,
        SysTime
    )) {
        container.set(YamlConvertor!(T, Node)(), fullyQualifiedName!T);
    }

    return container;
}

/**
ditto
**/
auto yaml(RCIAllocator allocator = theAllocator) {

    return Node("").yaml(allocator);
}

/**
Create a convertor container with data source being yaml document.

Params:
    pathOrData = path to a yaml file or yaml data itself
    returnEmpty = wheter to return or not a locator with empty data source
Returns:
    yamlConvertorContainer
**/
auto yaml(string pathOrData, bool returnEmpty = true) {
    import std.file;

    try {

        if (pathOrData.exists) {
            return yaml(Loader(pathOrData).load());
        } else {
            return yaml(Loader.fromString(pathOrData.dup).load());
        }
    } catch (YAMLException e) {
        debug(trace) trace("Error parsing yaml: ", e);

        if (returnEmpty) {
            debug(trace) trace("Providing empty container");
            return yaml();
        }

        throw new Exception("Could not create yaml convertor container from file or content passed in pathOrData: " ~ pathOrData, e);
    }
}

package auto accessor() {
    import aermicioi.aedi_property_reader.core.accessor;

    return dsl(
        new YamlNodePropertyAccessor(),
        new YamlIntegerIndexAccessor()
    );
}