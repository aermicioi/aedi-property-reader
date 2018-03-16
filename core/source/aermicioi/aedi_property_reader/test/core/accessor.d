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
module aermicioi.aedi_property_reader.test.core.core;

import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi_property_reader.core.convertor : unwrap;
import aermicioi.aedi.exception.not_found_exception;
import aermicioi.aedi_property_reader.core.exception;
import std.exception;
import std.experimental.allocator;

unittest {
    string[string] elems = [
		"foo": "foofoo",
		"moo": "moomoo"
	];

	AssociativeArrayAccessor!string accessor = new AssociativeArrayAccessor!string;

	assert(accessor.has(elems, "foo"));
	assert(accessor.has(elems, "moo"));
	assert(!accessor.has(elems, "coo"));

	assert(accessor.access(elems, "foo") == "foofoo");
	assert(accessor.access(elems, "moo") == "moomoo");
	assertThrown!NotFoundException(!accessor.access(elems, "coo"));
}

unittest {

	auto elems = ["foofoo", "moomoo"];

	ArrayAccessor!string accessor = new ArrayAccessor!string;

	assert(accessor.has(elems, 0));
	assert(accessor.has(elems, 1));
	assert(!accessor.has(elems, 2));

	assert(accessor.access(elems, 0) == "foofoo");
	assert(accessor.access(elems, 1) == "moomoo");
	assertThrown!NotFoundException(!accessor.access(elems, 2));
}

unittest {
	static struct Placeholder {
		int getter_ = 10;

		string foo = "foofoo";
		string moo = "moomoo";

		void coo(string, string) {

		}

		@property int getter() {
			return this.getter_;
		}
	}

	Placeholder elems;
	CompositeAccessor!Placeholder accessor = new CompositeAccessor!Placeholder;
	accessor.allocator = theAllocator;

	assert(accessor.has(elems, "getter"));
	assert(accessor.has(elems, "foo"));
	assert(accessor.has(elems, "moo"));
	assert(!accessor.has(elems, "coo"));

	assert(accessor.access(elems, "foo").unwrap!string == "foofoo");
	assert(accessor.access(elems, "moo").unwrap!string == "moomoo");
	assert(accessor.access(elems, "getter").unwrap!int == 10);
	assertThrown!NotFoundException(!accessor.access(elems, "coo"));
}

unittest {
	import std.variant;
    auto variant = Algebraic!(string[string], string)(
		[
			"foo": "foofoo",
			"moo": "moomoo"
		]
	);

	auto accessor = new VariantAccessor!(typeof(variant));

	assert(accessor.has(variant, "foo"));
	assert(accessor.has(variant, "moo"));
	assert(!accessor.has(variant, "coo"));

	assert(accessor.access(variant, "foo").get!string == "foofoo");
	assert(accessor.access(variant, "moo").get!string == "moomoo");
	assertThrown!NotFoundException(accessor.access(variant, "coo") == typeof(variant).init);
}

unittest {
	import std.variant;
    auto variant = Algebraic!(string[], string, size_t, immutable char)(
		[
			"foofoo", "moomoo"
		]
	);

	auto accessor = new VariantAccessor!(typeof(variant));

	assert(accessor.has(variant, 0UL));
	assert(accessor.has(variant, 1UL));
	assert(!accessor.has(variant, 2UL));

	assert(accessor.access(variant, 0UL).get!string == "foofoo");
	assert(accessor.access(variant, 1UL).get!string == "moomoo");
	assertThrown!NotFoundException(accessor.access(variant, 2) == typeof(variant).init);
}

unittest {
    string[string] elems = [
		"foo": "foofoo",
		"moo": "moomoo"
	];

	auto accessor = new TickedPropertyAccessor!(string[string], string)('\'', new AssociativeArrayAccessor!string);

	assert(accessor.has(elems, "'foo'"));
	assert(accessor.has(elems, "'moo'"));
	assert(!accessor.has(elems, "'coo'"));
	assert(!accessor.has(elems, "'coo"));
	assert(!accessor.has(elems, "coo'"));

	assert(accessor.access(elems, "'foo'"));
	assert(accessor.access(elems, "'moo'"));
	assertThrown!NotFoundException(!accessor.access(elems, "'coo'"));
}

unittest {
    class Placeholder {
		Placeholder p;
		int v = 10;

		this(Placeholder p, int v) {
			this.p = p;
			this.v = v;
		}
	}

	Placeholder p = new Placeholder(new Placeholder(null, 20), 30);

	auto accessor = new UnwrappingAccessor!(Placeholder, Object)(new CompositeAccessor!Placeholder);

	assert(accessor.has(cast(Object) p, "p"));
	assert(accessor.has(cast(Object) p, "v"));
	assert(!accessor.has(cast(Object) p, "c"));

	assert(accessor.access(cast(Object) p, "p").unwrap!Placeholder.v == 20);
	assert(accessor.access(cast(Object) p, "v").unwrap!int == 30);
	assertThrown!NotFoundException(!accessor.access(p, "c"));
}

unittest {
	import aermicioi.aedi_property_reader.core.convertor;
    string[string] elems = [
		"foo": "foofoo",
		"moo": "moomoo"
	];


	auto accessor = new WrappingAccessor!(string[string], string)(new AssociativeArrayAccessor!string);

	assert(accessor.has(elems, "foo"));
	assert(accessor.has(elems, "moo"));
	assert(!accessor.has(elems, "coo"));

	assert(accessor.access(elems, "foo").identify is typeid(string));
	assert(typeid(accessor.access(elems, "foo")) is typeid(PlaceholderImpl!string));
	assert(accessor.access(elems, "foo").unwrap!string == "foofoo");
}

unittest {
	class Placeholder {
		Placeholder p;
		int v = 10;

		this(Placeholder p, int v) {
			this.p = p;
			this.v = v;
		}
	}

	Placeholder p = new Placeholder(new Placeholder(null, 20), 30);

	auto accessor = new PropertyPathAccessor!(Object)(
		'.',
		new UnwrappingAccessor!(Placeholder, Object)(
			new CompositeAccessor!Placeholder
		)
	);

	assert(accessor.has(p, "v"));
	assert(accessor.has(p, "p.v"));
	assert(!accessor.has(p, "p.p.moo"));

	assert(accessor.access(p, "v").unwrap!int == 30);
	assert(accessor.access(p, "p.v").unwrap!int == 20);
	assertThrown!NotFoundException(!accessor.access(p, "p.p.moo"));
}

unittest {
	class Placeholder {
		Placeholder p;
		int v = 10;

		this(Placeholder p, int v) {
			this.p = p;
			this.v = v;
		}
	}

	Placeholder p = new Placeholder(new Placeholder(null, 20), 30);

	auto accessor = new ArrayIndexedPropertyAccessor!(Object)(
		'[',
		']',
		new UnwrappingAccessor!(Placeholder, Object)(
			new CompositeAccessor!Placeholder
		),
		new UnwrappingAccessor!(Placeholder, Object)(
			new CompositeAccessor!Placeholder
		)
	);

	assert(accessor.has(p, "p[v]"));
	assert(!accessor.has(p, "p[]"));
	assert(!accessor.has(p, ""));
	assert(!accessor.has(p, "p["));
	assert(!accessor.has(p, "x[moo]"));
	assert(!accessor.has(p, "p[moo]"));

	assert(accessor.access(p, "p[v]").unwrap!int == 20);
	assertThrown!NotFoundException(!accessor.access(p, "p[moo]"));
}

unittest {
	class Placeholder {
		Placeholder p;
		int v = 10;

		this(Placeholder p, int v) {
			this.p = p;
			this.v = v;
		}
	}

	Placeholder p = new Placeholder(new Placeholder(new Placeholder(new Placeholder(null, 0), 10), 20), 30);

	auto accessor = dsl(
		new UnwrappingAccessor!(Placeholder, Object)(
			new CompositeAccessor!Placeholder
		),
		new UnwrappingAccessor!(Placeholder, Object)(
			new CompositeAccessor!Placeholder
		)
	);

	assert(accessor.has(p, "p.p"));
	assert(accessor.has(p, "p[p]"));
	assert(accessor.has(p, "p[\"p\"]"));
	assert(accessor.has(p, "p['p']"));
	assert(!accessor.has(p, "p.r"));
	assert(!accessor.has(p, "p[r]"));
	assert(!accessor.has(p, "p[\"r\"]"));
	assert(!accessor.has(p, "p['r']"));

	assert(accessor.access(p, "p[v]").unwrap!int == 20);
	assert(accessor.access(p, "p[v]").unwrap!int == 20);
	assert(accessor.access(p, "p[v]").unwrap!int == 20);
	assert(accessor.access(p, "p[v]").unwrap!int == 20);
}