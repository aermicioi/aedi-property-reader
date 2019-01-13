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
module aermicioi.aedi_property_reader.test.sdlang.convertor;

import std.meta;
import std.exception;
import sdlang;
import aermicioi.aedi_property_reader.convertor.exception : NotFoundException;
import aermicioi.aedi_property_reader.convertor.exception : InvalidCastException;
import aermicioi.aedi_property_reader.sdlang.convertor;
import aermicioi.aedi_property_reader.sdlang.accessor : SdlangElement;

unittest {
	enum T {
		first,
		second
	}

	Tag root = parseSource(q{
		valid 2 value=1
		array "an" " " "array"
		char "a"
		invalid "string" value="march"
		enum "first"
	});

	int i, k;
	ubyte u;
	char ch;
	string str;
	char[] charr;
	string[] s;
	T e;

	SdlangElement(root.tags["valid"].front).convert(i);
	SdlangElement(root.tags["valid"].front).convert(u);
	SdlangElement(root.tags["invalid"].front).convert(charr);
	SdlangElement(root.tags["invalid"].front.attributes["value"].front).convert(charr);
	SdlangElement(root.tags["invalid"].front.attributes["value"].front).convert(str);
	SdlangElement(root.tags["invalid"].front).convert(str);
	SdlangElement(root.tags["enum"].front).convert(e);
	SdlangElement(root.tags["array"].front).convert(s);
	assert(i == 2);
	assert(s == ["an", " ", "array"]);

	SdlangElement(root.tags["valid"].front.attributes["value"].front).convert(i);
	SdlangElement(root.tags["char"].front).convert(ch);
	assert(i == 1);

	assertThrown!InvalidCastException(SdlangElement(root.tags["invalid"].front).convert(i));

	try {
		SdlangElement(root.tags["invalid"].front.attributes["value"].front).convert(k);
		import std.stdio;
		writeln("***************", k);
		assert(false);
	} catch (InvalidCastException e) {

	}

}