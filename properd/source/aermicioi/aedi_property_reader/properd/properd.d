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
module aermicioi.aedi_property_reader.properd.properd;

import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi_property_reader.core.convertor;
import aermicioi.aedi_property_reader.core.std_conv;
import aermicioi.aedi_property_reader.core.document;
import aermicioi.aedi_property_reader.core.type_guesser;
import lproperd = properd;
import std.experimental.logger;
import std.experimental.allocator;

alias ProperdDocumentContainer = AdvisedDocumentContainer!(string[string], string, StdConvAdvisedConvertor);

/**
Create a convertor container with data source being properd document.

Params:
    value = source of data for container to use to construct components.
    accessor = property accessing logic
    guesser = type guesser based on held properd value
    allocator = allocator used to allocate converted values
Returns:
    JsonConvertorContainer
**/
auto properd(string[string] value, PropertyAccessor!(string[string], string) accessor, TypeGuesser!string guesser, RCIAllocator allocator = theAllocator) {

    ProperdDocumentContainer container = new ProperdDocumentContainer(value);
    container.guesser = guesser;
    container.accessor = accessor;
    container.allocator = allocator;

    return container;
}

/**
ditto
**/
auto properd(string[string] value, TypeGuesser!string guesser, RCIAllocator allocator = theAllocator) {

    return value.properd(accessor, guesser, allocator);
}

/**
ditto
**/
auto properd(string[string] value, RCIAllocator allocator = theAllocator) {
    import std.meta : AliasSeq;
    auto container = value.properd(accessor, new StringToScalarConvTypeGuesser, allocator);
    import std.datetime;
    import std.traits;

    static if (is(StringToScalarConvTypeGuesser: StdConvTypeGuesser!(S, ToTypes), S, ToTypes...)) {
        static foreach (To; ToTypes) {
            container.set(new StdConvAdvisedConvertor!(To, S), fullyQualifiedName!To);
        }
    }

    return container;
}

/**
ditto
**/
auto properd(RCIAllocator allocator = theAllocator) {

    return (cast(string[string]) null).properd(allocator);
}

/**
Create a convertor container with data source being properd document.

Params:
    pathOrData = path to a properd file or properd data itself
    returnEmpty = wheter to return or not a locator with empty data source
Returns:
    properdConvertorContainer
**/
auto properd(string pathOrData, bool returnEmpty = true) {
    import std.file;
    import p = properd;

    try {

        if (pathOrData.exists) {
            return properd(p.readProperties(pathOrData));
        } else {
            return properd(p.parseProperties(pathOrData));
        }
    } catch (p.PropertyException e) {
        debug(trace) trace("Error parsing properd: ", e);

        if (returnEmpty) {
            debug(trace) trace("Providing empty container");
            return properd();
        }

        throw new Exception("Could not create properd convertor container from file or content passed in pathOrData: " ~ pathOrData, e);
    }
}

private auto accessor() {
    import aermicioi.aedi_property_reader.core.accessor;

    return new AssociativeArrayAccessor!string;
}