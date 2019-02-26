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
module aermicioi.aedi_property_reader.csv.test.csv;

import aermicioi.aedi_property_reader.csv;
import aermicioi.aedi_property_reader.core;
import aermicioi.aedi.storage.locator;
import std.exception;

unittest {
	auto document = csv("float,integer,string\n" ~
        "1.0,10,\"One hundred\"\n" ~
        "2.0,20,\"Two hundred\"\n");

    Locator!() c;
    with (document.configure) {
        register!(string[string])("0");
        register!(string[string])("1");

        c = container;
    }

    assert(c.locate!(string[string])("0") == ["float": "1.0", "integer": "10", "string": "One hundred"]);
    assert(c.locate!(string[string])("1") == ["float": "2.0", "integer": "20", "string": "Two hundred"]);
}

unittest {
	import std.path : dirName;
	auto document = csv(dirName(__FILE__) ~ "/config.csv", false);

    Locator!() c;
	with (document.configure) {
        register!(string[string])("0");
        register!(string[string])("1");
        register!(string[string])("2");

        c = container;
    }

    assert(c.locate!(string[string])("0") == ["float": "1.0", "integer": "10", "string": "One hundred"]);
    assert(c.locate!(string[string])("1") == ["float": "2.0", "integer": "20", "string": "Two hundred"]);
    assert(c.locate!(string[string])("2") == ["float": "3.0", "integer": "30", "string": "Three hundred"]);

	assertNotThrown(csv("unknown"));
	assertThrown(csv("unkown\"", false));

	assertNotThrown(csv(dirName(__FILE__) ~ "/config_malformed.csv", true));
	assertThrown(csv(dirName(__FILE__) ~ "/config_malformed.csv", false));
}

unittest {
	auto document = csv("first,second,third\n" ~
        "1.0,10,\"One hundred\"\n" ~
        "2.0,20,\"Two hundred\"\n");

    Locator!() c;

	static struct Placeholder {
		float first;
		int second;
		string third;
	}

	with (document.configure) {
		register!Placeholder("0");
		register!Placeholder("1");

        c = container;
    }

	assert(c.locate!Placeholder("0") == Placeholder(1.0, 10, "One hundred"));
	assert(c.locate!Placeholder("1") == Placeholder(2.0, 20, "Two hundred"));
}