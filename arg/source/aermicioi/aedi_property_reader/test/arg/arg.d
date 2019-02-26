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
module aermicioi.aedi_property_reader.test.arg.arg;

import aermicioi.aedi : locate, Locator;
import aermicioi.aedi_property_reader.convertor.exception : NotFoundException;
import aermicioi.aedi.test.fixture;
import aermicioi.aedi_property_reader.arg;
import aermicioi.aedi_property_reader.convertor.placeholder;
import aermicioi.aedi_property_reader.core;
import std.exception;
import std.json;
import std.process : env = environment;
import std.xml;

unittest {
	auto document = argument([
            "commandline",
            "--string=stringed",
            "--array=hello",
            "--array= ",
            "--array=world!",
            "--float=1.0",
            "--integer=10"
    ]);

	Locator!() c;

    with (document.configure) {
        property!(string)("string"); // Not testing it since factory takes arguments from
        property!(string[])("array");
        property!(float)("float");
        property!(size_t)("integer");

		c = container;
    }

    assert(c.locate!(string) == "stringed");
	import std.stdio; c.locate!float("float").writeln;
	assert(c.locate!(string[])("array") == ["hello", " ", "world!"]);
	assert(c.locate!float("float") == 1.0);
	assert(c.locate!size_t("integer") == 10);
}