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
module aermicioi.aedi_property_reader.json.convertor;

import aermicioi.aedi_property_reader.core.convertor;
import aermicioi.aedi.factory;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.wrapper;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.exception;
import std.json;
import std.traits;
import std.conv : to;
import std.experimental.allocator;

alias JsonConvertor = ChainedAdvisedConvertor!(
    AdvisedConvertor!(convert, destruct),
    CompositeAdvisedConvertor
).AdvisedConvertorImplementation;

/**
Convert JSONValue into T scalar/array/assocarray value.

Params:
    value = storage where to put converted JSONValue
    json = the data that is to be converted.
Throws:
    InvalidCastException when the type of value does not match stored data.
Returns:
    value
**/
void convert(To, From : JSONValue)(in From json, ref To value, RCIAllocator allocator = theAllocator)
    if (isFloatingPoint!To && !is(To == enum)) {

    if (json.type != JSON_TYPE.FLOAT) {
        throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!To);
    }

    value = json.floating.to!To;
}

/**
ditto
**/
void convert(To, From : JSONValue)(in From json, ref To value, RCIAllocator allocator = theAllocator)
    if (is(To : bool) && !is(To == enum)) {

    if (json.type == JSON_TYPE.TRUE) {
        value = true;
        return;
    }

    if (json.type == JSON_TYPE.FALSE) {
        value = false;
        return;
    }

    throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!To);
}

/**
ditto
**/
void convert(To, From : JSONValue)(in From json, ref To value, RCIAllocator allocator = theAllocator)
    if (isUnsigned!To && isIntegral!To && !is(To == enum)) {

    if ((json.type == JSON_TYPE.INTEGER) && (json.integer >= 0)) {
        value = json.integer.to!To;
        return;
    }

    if (json.type != JSON_TYPE.UINTEGER) {
        throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!To);
    }

    value = json.uinteger.to!To;
}

/**
ditto
**/
void convert(To, From : JSONValue)(in From json, ref To value, RCIAllocator allocator = theAllocator)
    if (!isUnsigned!To && isIntegral!To && !is(To == enum)) {

    if (json.type != JSON_TYPE.INTEGER) {
        throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!To);
    }

    value = json.integer.to!To;
}

/**
ditto
**/
void convert(To, From : JSONValue)(in From json, ref To value, RCIAllocator allocator = theAllocator)
    if (isSomeString!To && !is(To == enum)) {

    if (json.type != JSON_TYPE.STRING) {
        throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!To);
    }

    value = json.str.to!To;
}

/**
ditto
**/
void convert(To : Z[], From : JSONValue, Z)(in From json, ref To value, RCIAllocator allocator = theAllocator)
    if (!isSomeString!To && !is(To == enum)) {

    if (json.type != JSON_TYPE.ARRAY) {
        throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!To);
    }

    value = allocator.makeArray!Z(json.array.length);

    foreach (index, ref el; value) {
        convert!Z(json.array[index], el, allocator);
    }
}

/**
ditto
**/
void convert(To : Z[string], From : JSONValue, Z)(in From json, ref To value, RCIAllocator allocator = theAllocator) if (!is(To == enum)) {

    if (json.type != JSON_TYPE.OBJECT) {
        throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!To);
    }

    auto jsonAssociativeArray = json.object;

    foreach (key, ref el; jsonAssociativeArray) {

        Z temp;
        convert!Z(el, temp, allocator);
        value[key] = temp;
    }
}

/**
ditto
**/
void convert(To, From : JSONValue)(in From json, ref To value, RCIAllocator allocator = theAllocator) if (is(To == enum)) {

    string temp;
    json.convert!string(temp, allocator);
    value = temp.to!To;
	temp.destruct(allocator);
}

void destruct(To)(ref To to, RCIAllocator allocator = theAllocator) {
    destroy(to);
    to = to.init;
}

void destruct(To : Z[], Z)(ref To to, RCIAllocator allocator = theAllocator)
    if (!isSomeString!To) {
    allocator.dispose(to);
    to = To.init;
}