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
module aermicioi.aedi_property_reader.test.convertor.core;

import aermicioi.aedi_property_reader.convertor.accessor;
import aermicioi.aedi_property_reader.convertor.placeholder : unwrap;
import aermicioi.aedi.exception.not_found_exception;
import aermicioi.aedi_property_reader.convertor.placeholder;
import aermicioi.aedi_property_reader.convertor.exception;
import std.exception;
import std.experimental.allocator;

unittest {
    string[string] elems = [
		"foo": "foofoo",
		"moo": "moomoo"
	];

	AssociativeArrayAccessor!(string[string]) accessor = new AssociativeArrayAccessor!(string[string]);

	assert(accessor.has(elems, "foo"));
	assert(accessor.has(elems, "moo"));
	assert(!accessor.has(elems, "coo"));

	assert(accessor.access(elems, "foo") == "foofoo");
	assert(accessor.access(elems, "moo") == "moomoo");
	assertThrown!NotFoundException(!accessor.access(elems, "coo"));
}

unittest {
    const(string[string]) elems = [
		"foo": "foofoo",
		"moo": "moomoo"
	];

	AssociativeArrayAccessor!(const(string[string])) accessor = new AssociativeArrayAccessor!(const(string[string]));

	assert(accessor.has(elems, "foo"));
	assert(accessor.has(elems, "moo"));
	assert(!accessor.has(elems, "coo"));

	assert(accessor.access(elems, "foo") == "foofoo");
	assert(accessor.access(elems, "moo") == "moomoo");
	assertThrown!NotFoundException(!accessor.access(elems, "coo"));
}

unittest {
    immutable(string[string]) elems = [
		"foo": "foofoo",
		"moo": "moomoo"
	];

	AssociativeArrayAccessor!(immutable(string[string])) accessor = new AssociativeArrayAccessor!(immutable(string[string]));

	assert(accessor.has(elems, "foo"));
	assert(accessor.has(elems, "moo"));
	assert(!accessor.has(elems, "coo"));

	assert(accessor.access(elems, "foo") == "foofoo");
	assert(accessor.access(elems, "moo") == "moomoo");
	assertThrown!NotFoundException(!accessor.access(elems, "coo"));
}

unittest {

	auto elems = ["foofoo", "moomoo"];

	ArrayAccessor!(string[]) accessor = new ArrayAccessor!(string[]);

	assert(accessor.has(elems, 0));
	assert(accessor.has(elems, 1));
	assert(!accessor.has(elems, 2));

	assert(accessor.access(elems, 0) == "foofoo");
	assert(accessor.access(elems, 1) == "moomoo");
	assertThrown!NotFoundException(!accessor.access(elems, 2));
}

unittest {

	const(string[]) elems = ["foofoo", "moomoo"];

	ArrayAccessor!(const(string[])) accessor = new ArrayAccessor!(const(string[]));

	assert(accessor.has(elems, 0));
	assert(accessor.has(elems, 1));
	assert(!accessor.has(elems, 2));

	assert(accessor.access(elems, 0) == "foofoo");
	assert(accessor.access(elems, 1) == "moomoo");
	assertThrown!NotFoundException(!accessor.access(elems, 2));
}

unittest {

	immutable(string[]) elems = ["foofoo", "moomoo"];

	ArrayAccessor!(immutable(string[])) accessor = new ArrayAccessor!(immutable(string[]));

	assert(accessor.has(elems, 0));
	assert(accessor.has(elems, 1));
	assert(!accessor.has(elems, 2));

	assert(accessor.access(elems, 0) == "foofoo");
	assert(accessor.access(elems, 1) == "moomoo");
	assertThrown!NotFoundException(!accessor.access(elems, 2));
}

static struct Placeholder {
	int getter_ = 10;

	string foo = "foofoo";
	string moo = "moomoo";

	void coo(string, string) {

	}

	@property int getter() {
		return this.getter_;
	}

	@property int getter() const {
		return this.getter_;
	}

	@property int getter() immutable {
		return this.getter_;
	}

	@property {
		ref Placeholder self() {
			return this;
		}

		ref const(Placeholder) self() const {
			return this;
		}

		ref immutable(Placeholder) self() immutable {
			return this;
		}
	}
}
unittest {

	Placeholder elems;
	CompositeAccessor!Placeholder accessor = new CompositeAccessor!Placeholder;

	assert(accessor.has(elems, "getter"));
	assert(accessor.has(elems, "foo"));
	assert(accessor.has(elems, "moo"));
	assert(accessor.has(elems, "self"));
	assert(!accessor.has(elems, "coo"));

	assert(accessor.access(elems, "foo").unwrap!string == "foofoo");
	assert(accessor.access(elems, "moo").unwrap!string == "moomoo");
	assert(accessor.access(elems, "getter").unwrap!int == 10);
	assert(accessor.access(elems, "self").unwrap!Placeholder.getter == 10);
	assertThrown!NotFoundException(!accessor.access(elems, "coo"));
}

unittest {
	const Placeholder elems;
	CompositeAccessor!(const Placeholder) accessor = new CompositeAccessor!(const Placeholder);

	assert(accessor.has(elems, "getter"));
	assert(accessor.has(elems, "foo"));
	assert(accessor.has(elems, "moo"));
	assert(accessor.has(elems, "self"));
	assert(!accessor.has(elems, "coo"));

	assert(accessor.access(elems, "foo").unwrap!(const(string)) == "foofoo");
	assert(accessor.access(elems, "moo").unwrap!(const(string)) == "moomoo");
	assert(accessor.access(elems, "self").unwrap!(const Placeholder).getter == 10);
	assert(accessor.access(elems, "getter").unwrap!(const int) == 10);
	assertThrown!NotFoundException(!accessor.access(elems, "coo"));
}

unittest {
	immutable Placeholder elems;
	CompositeAccessor!(immutable Placeholder) accessor = new CompositeAccessor!(immutable Placeholder);

	assert(accessor.has(elems, "getter"));
	assert(accessor.has(elems, "foo"));
	assert(accessor.has(elems, "moo"));
	assert(accessor.has(elems, "self"));
	assert(!accessor.has(elems, "coo"));

	assert(accessor.access(elems, "foo").unwrap!(immutable(string)) == "foofoo");
	assert(accessor.access(elems, "moo").unwrap!(immutable(string)) == "moomoo");
	assert(accessor.access(elems, "self").unwrap!(immutable Placeholder).getter == 10);
	assert(accessor.access(elems, "getter").unwrap!(immutable int) == 10);
	assertThrown!NotFoundException(!accessor.access(elems, "coo"));
}

unittest {
	import std.variant : Algebraic;
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
	import std.variant : Algebraic;
    auto variant = cast(const) Algebraic!(string[string], string)(
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
	import std.variant : Algebraic;
    auto variant = cast(immutable) Algebraic!(string[string], string)(
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
	import std.variant : Algebraic;
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
	import std.variant : Algebraic;
    auto variant = cast(const) Algebraic!(string[], string, size_t, immutable char)(
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
	import std.variant : Algebraic;
    auto variant = cast(immutable) Algebraic!(string[], string, size_t, immutable char)(
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

	auto accessor = new TickedPropertyAccessor!(string[string], string)('\'', new AssociativeArrayAccessor!(string[string]));

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
    const(string[string]) elems = [
		"foo": "foofoo",
		"moo": "moomoo"
	];

	auto accessor = new TickedPropertyAccessor!(const(string[string]), const string)('\'', new AssociativeArrayAccessor!(const(string[string])));

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
    immutable(string[string]) elems = [
		"foo": "foofoo",
		"moo": "moomoo"
	];

	auto accessor = new TickedPropertyAccessor!(immutable(string[string]), immutable string)('\'', new AssociativeArrayAccessor!(immutable(string[string])));

	assert(accessor.has(elems, "'foo'"));
	assert(accessor.has(elems, "'moo'"));
	assert(!accessor.has(elems, "'coo'"));
	assert(!accessor.has(elems, "'coo"));
	assert(!accessor.has(elems, "coo'"));

	assert(accessor.access(elems, "'foo'"));
	assert(accessor.access(elems, "'moo'"));
	assertThrown!NotFoundException(!accessor.access(elems, "'coo'"));
}

class PlaceholderClass {
	PlaceholderClass p;
	int v = 10;

	this(inout PlaceholderClass p, int v) inout {
		this.p = p;
		this.v = v;
	}

	@property {

		int getter() {
			return v;
		}

		int getter() const {
			return v;
		}

		int getter() immutable {
			return v;
		}
	}
}

unittest {
	PlaceholderClass p = new PlaceholderClass(new PlaceholderClass(null, 20), 30);

	auto accessor = new RuntimeCompositeAccessor!(PlaceholderClass, Object)(new CompositeAccessor!PlaceholderClass);

	assert(accessor.has(p, "p"));
	assert(accessor.has(p, "v"));
	assert(!accessor.has(p, "c"));

	assert(accessor.access(p, "p").unwrap!PlaceholderClass.v == 20);
	assert(accessor.access(p, "v").unwrap!int == 30);
	assert(accessor.access(p, "getter").unwrap!int == 30);
	assertThrown!NotFoundException(!accessor.access(p, "c"));
}

unittest {
	const PlaceholderClass p = new const PlaceholderClass(new const PlaceholderClass(cast(const) null, 20), 30);

	auto accessor = new RuntimeCompositeAccessor!(const PlaceholderClass, const Object)(new CompositeAccessor!(const PlaceholderClass));

	assert(accessor.has(p, "p"));
	assert(accessor.has(p, "v"));
	assert(!accessor.has(p, "c"));

	assert(accessor.access(p, "p").unwrap!(const PlaceholderClass).v == 20);
	assert(accessor.access(p, "getter").unwrap!(const int) == 30);
	assert(accessor.access(p, "v").unwrap!(const int) == 30);
	assertThrown!NotFoundException(!accessor.access(p, "c"));
}

unittest {
	immutable PlaceholderClass p = new immutable PlaceholderClass(new immutable PlaceholderClass(cast(immutable) null, 20), 30);

	auto accessor = new RuntimeCompositeAccessor!(immutable PlaceholderClass, immutable Object)(new CompositeAccessor!(immutable PlaceholderClass));

	assert(accessor.has(p, "p"));
	assert(accessor.has(p, "v"));
	assert(!accessor.has(p, "c"));

	assert(accessor.access(p, "p").unwrap!(immutable PlaceholderClass).v == 20);
	assert(accessor.access(p, "getter").unwrap!(immutable int) == 30);
	assert(accessor.access(p, "v").unwrap!(immutable int) == 30);
	assertThrown!NotFoundException(!accessor.access(p, "c"));
}

unittest {
    string[string] elems = [
		"foo": "foofoo",
		"moo": "moomoo"
	];


	auto accessor = new RuntimeFieldAccessor!(string[string], string)(new AssociativeArrayAccessor!(string[string]));

	assert(accessor.has(elems, "foo"));
	assert(accessor.has(elems, "moo"));
	assert(!accessor.has(elems, "coo"));

	assert(accessor.access(elems, "foo").identify is typeid(string));
	assert(typeid(accessor.access(elems, "foo")) is typeid(PlaceholderImpl!string));
	assert(accessor.access(elems, "foo").unwrap!string == "foofoo");
}

unittest {
    const(string[string]) elems = [
		"foo": "foofoo",
		"moo": "moomoo"
	];


	auto accessor = new RuntimeFieldAccessor!(const(string[string]), const string)(new AssociativeArrayAccessor!(const(string[string])));

	assert(accessor.has(elems, "foo"));
	assert(accessor.has(elems, "moo"));
	assert(!accessor.has(elems, "coo"));

	assert(accessor.access(elems, "foo").identify is typeid(string));
	assert(typeid(accessor.access(elems, "foo")) is typeid(PlaceholderImpl!(string)));
	assert(accessor.access(elems, "foo").unwrap!(string) == "foofoo");
}

// TODO reenable this, after a bug with immutable arrays decaying to mutable ones are fixed in templated code.
// unittest {
//     immutable(string[string]) elems = [
// 		"foo": "foofoo",
// 		"moo": "moomoo"
// 	];
// 	import aermicioi.aedi_property_reader.convertor.placeholder;
// 	import std.traits;

// 	auto accessor = new RuntimeFieldAccessor!(immutable(string[string]), immutable string, immutable string)(new AssociativeArrayAccessor!(immutable(string[string])));

// 	assert(accessor.has(elems, "foo"));
// 	assert(accessor.has(elems, "moo"));
// 	assert(!accessor.has(elems, "coo"));

// 	assert(accessor.access(elems, "foo").identify is typeid(string));
// 	assert(typeid(accessor.access(elems, "foo")) is typeid(PlaceholderImpl!(string)));
// 	assert(accessor.access(elems, "foo").unwrap!(string) == "foofoo");
// }

unittest {
    immutable(int[string]) elems = [
		"foo": 10,
		"moo": 20
	];


	auto accessor = new RuntimeFieldAccessor!(immutable(int[string]), immutable int, string)(new AssociativeArrayAccessor!(immutable(int[string])));

	assert(accessor.has(elems, "foo"));
	assert(accessor.has(elems, "moo"));
	assert(!accessor.has(elems, "coo"));

	assert(accessor.access(elems, "foo").identify is typeid(immutable int));
	assert(typeid(accessor.access(elems, "foo")) is typeid(PlaceholderImpl!(immutable int)));
	assert(accessor.access(elems, "foo").unwrap!(immutable int) == 10);
}

unittest {
	PlaceholderClass p = new PlaceholderClass(new PlaceholderClass(null, 20), 30);

	auto accessor = new PropertyPathAccessor!(Object)(
		'.',
		new RuntimeCompositeAccessor!(PlaceholderClass, Object)(
			new CompositeAccessor!PlaceholderClass
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
	const PlaceholderClass p = new PlaceholderClass(new PlaceholderClass(null, 20), 30);

	auto accessor = new PropertyPathAccessor!(const Object, const Object)(
		'.',
		new RuntimeCompositeAccessor!(const PlaceholderClass, const Object)(
			new CompositeAccessor!(const PlaceholderClass)
		)
	);

	assert(accessor.has(p, "v"));
	assert(accessor.has(p, "p.v"));
	assert(!accessor.has(p, "p.p.moo"));

	assert(accessor.access(p, "v").unwrap!(const int) == 30);
	assert(accessor.access(p, "p.v").unwrap!(const int) == 20);
	assertThrown!NotFoundException(!accessor.access(p, "p.p.moo"));
}

unittest {
	immutable PlaceholderClass p = new immutable(PlaceholderClass)(new immutable(PlaceholderClass)(cast(immutable) null, 20), 30);

	auto accessor = new PropertyPathAccessor!(immutable Object, immutable Object)(
		'.',
		new RuntimeCompositeAccessor!(immutable PlaceholderClass, immutable Object)(
			new CompositeAccessor!(immutable PlaceholderClass)
		)
	);

	assert(accessor.has(p, "v"));
	assert(accessor.has(p, "p.v"));
	assert(!accessor.has(p, "p.p.moo"));

	assert(accessor.access(p, "v").unwrap!(immutable int) == 30);
	assert(accessor.access(p, "p.v").unwrap!(immutable int) == 20);
	assertThrown!NotFoundException(!accessor.access(p, "p.p.moo"));
}

unittest {
	PlaceholderClass p = new PlaceholderClass(new PlaceholderClass(null, 20), 30);

	auto accessor = new ArrayIndexedPropertyAccessor!(Object)(
		'[',
		']',
		new RuntimeCompositeAccessor!(PlaceholderClass, Object)(
			new CompositeAccessor!PlaceholderClass
		),
		new RuntimeCompositeAccessor!(PlaceholderClass, Object)(
			new CompositeAccessor!PlaceholderClass
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
	const PlaceholderClass p = new PlaceholderClass(new PlaceholderClass(null, 20), 30);

	auto accessor = new ArrayIndexedPropertyAccessor!(const Object)(
		'[',
		']',
		new RuntimeCompositeAccessor!(const PlaceholderClass, const Object)(
			new CompositeAccessor!(const PlaceholderClass)
		),
		new RuntimeCompositeAccessor!(const PlaceholderClass, const Object)(
			new CompositeAccessor!(const PlaceholderClass)
		)
	);

	assert(accessor.has(p, "p[v]"));
	assert(!accessor.has(p, "p[]"));
	assert(!accessor.has(p, ""));
	assert(!accessor.has(p, "p["));
	assert(!accessor.has(p, "x[moo]"));
	assert(!accessor.has(p, "p[moo]"));

	assert(accessor.access(p, "p[v]").unwrap!(const int) == 20);
	assertThrown!NotFoundException(!accessor.access(p, "p[moo]"));
}

unittest {
	immutable PlaceholderClass p = new immutable(PlaceholderClass)(new immutable(PlaceholderClass)(cast(immutable) null, 20), 30);

	auto accessor = new ArrayIndexedPropertyAccessor!(immutable Object)(
		'[',
		']',
		new RuntimeCompositeAccessor!(immutable PlaceholderClass, immutable Object)(
			new CompositeAccessor!(immutable PlaceholderClass)
		),
		new RuntimeCompositeAccessor!(immutable PlaceholderClass, immutable Object)(
			new CompositeAccessor!(immutable PlaceholderClass)
		)
	);

	assert(accessor.has(p, "p[v]"));
	assert(!accessor.has(p, "p[]"));
	assert(!accessor.has(p, ""));
	assert(!accessor.has(p, "p["));
	assert(!accessor.has(p, "x[moo]"));
	assert(!accessor.has(p, "p[moo]"));

	assert(accessor.access(p, "p[v]").unwrap!(immutable int) == 20);
	assertThrown!NotFoundException(!accessor.access(p, "p[moo]"));
}

unittest {

	PlaceholderClass p = new PlaceholderClass(new PlaceholderClass(new PlaceholderClass(new PlaceholderClass(null, 0), 10), 20), 30);

	auto accessor = dsl(
		new RuntimeCompositeAccessor!(PlaceholderClass, Object)(
			new CompositeAccessor!PlaceholderClass
		),
		new RuntimeCompositeAccessor!(PlaceholderClass, Object)(
			new CompositeAccessor!PlaceholderClass
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

unittest {

	const PlaceholderClass p = new PlaceholderClass(new PlaceholderClass(new PlaceholderClass(new PlaceholderClass(null, 0), 10), 20), 30);

	auto accessor = dsl(
		new RuntimeCompositeAccessor!(const PlaceholderClass, const Object)(
			new CompositeAccessor!(const PlaceholderClass)
		),
		new RuntimeCompositeAccessor!(const PlaceholderClass, const Object)(
			new CompositeAccessor!(const PlaceholderClass)
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

	assert(accessor.access(p, "p[v]").unwrap!(const int) == 20);
	assert(accessor.access(p, "p[v]").unwrap!(const int) == 20);
	assert(accessor.access(p, "p[v]").unwrap!(const int) == 20);
	assert(accessor.access(p, "p[v]").unwrap!(const int) == 20);
}

unittest {

	immutable PlaceholderClass p = new immutable(PlaceholderClass)(new immutable(PlaceholderClass)(new immutable(PlaceholderClass)(new immutable(PlaceholderClass)(cast(immutable) null, 0), 10), 20), 30);

	auto accessor = dsl(
		new RuntimeCompositeAccessor!(immutable PlaceholderClass, immutable Object)(
			new CompositeAccessor!(immutable PlaceholderClass)
		),
		new RuntimeCompositeAccessor!(immutable PlaceholderClass, immutable Object)(
			new CompositeAccessor!(immutable PlaceholderClass)
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

	assert(accessor.access(p, "p[v]").unwrap!(immutable int) == 20);
	assert(accessor.access(p, "p[v]").unwrap!(immutable int) == 20);
	assert(accessor.access(p, "p[v]").unwrap!(immutable int) == 20);
	assert(accessor.access(p, "p[v]").unwrap!(immutable int) == 20);
}