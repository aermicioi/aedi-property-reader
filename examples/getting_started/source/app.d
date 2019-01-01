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
module app;

import aermicioi.aedi_property_reader;
import aermicioi.aedi : container;
import std.socket;

public alias configure = aermicioi.aedi.configurer.register.context.configure;
public alias configure = aermicioi.aedi_property_reader.core.core.configure;

struct Component {
	long first;
	double second;
	string third;
}

void load(T : DocumentContainer!X, X...)(T container) {
	with (container.configure) {
		register!long("first");
		register!double("second");
		register!string("third");
		register!Component("");
		register!Component("json");
		register!Component("xml");
		register!Component("sdlang");
		register!Component("yaml");
	}
}

void main()
{
	auto c = container(
		xml("config.xml"),
		json("config.json"),
		yaml("config.yaml"),
		sdlang("config.sdlang")
	);

	foreach (subcontainer; c) {
		subcontainer.load;
	}

	import std.stdio;
	c.locate!Component("").writeln;
	c.locate!Component("xml").writeln;
	c.locate!Component("json").writeln;
	c.locate!Component("yaml").writeln;
	c.locate!Component("sdlang").writeln;
	writeln("first: ", c.locate!long("first"));
	writeln("second: ", c.locate!double("second"));
	writeln("third: ", c.locate!string("third"));
}
