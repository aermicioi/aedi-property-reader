module aermicioi.aedi_property_reader.sdlang.test.accessor;

import aermicioi.aedi_property_reader.sdlang.accessor;
import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi.exception.not_found_exception : NotFoundException;
import sdlang;
import std.exception;

unittest {
    Tag tag = parseSource(q{
        first "Joe"
    });
    auto accessor = new SdlangTagPropertyAccessor;

    assert(accessor.has(tag, "first"));
    assert(accessor.access(tag, "first").expectValue!string == "Joe");
    assert(!accessor.has(tag, "unknown"));
    assertThrown!NotFoundException(accessor.access(tag, "unknown"));
}

unittest {
    Tag tag = parseSource(q{
        first "Joe"
        second "Moe"
    });
    auto accessor = new SdlangIntegerIndexAccessor;

    assert(accessor.has(tag, "1"));
    assert(accessor.access(tag, "1").expectValue!string == "Moe");
    assert(!accessor.has(tag, "2"));
    assertThrown!NotFoundException(accessor.access(tag, "2"));
}

unittest {
    Tag tag = parseSource(q{
        first name="Joe"
    });
    auto accessor = new SdlangAttributePropertyAccessor;

    assert(accessor.has(tag.tags["first"].front, "name"));
    assert(accessor.access(tag.tags["first"].front, "name").value.get!string == "Joe");
    assert(!accessor.has(tag.tags["first"].front, "boli"));
    assertThrown!NotFoundException(accessor.access(tag.tags["first"].front, "boli"));
}

unittest {
    Tag tag = parseSource(q{
        first "Moe" name="Joe" {
            second "Doe"
        }
    });
    auto accessor = new AggregatePropertyAccessor!SdlangElement(
        new TaggedElementPropertyAccessorWrapper!(SdlangElement, SdlangAttributePropertyAccessor)(new SdlangAttributePropertyAccessor),
        new TaggedElementPropertyAccessorWrapper!(SdlangElement, SdlangTagPropertyAccessor)(new SdlangTagPropertyAccessor)
    );

    assert(accessor.has(SdlangElement(tag.tags["first"].front), "name"));
    assert((cast(Attribute) accessor.access(SdlangElement(tag.tags["first"].front), "name")).value.get!string == "Joe");
    assert(!accessor.has(SdlangElement(tag.tags["first"].front), "boli"));
    assertThrown!NotFoundException(accessor.access(SdlangElement(tag.tags["first"].front), "boli"));

    assert(accessor.has(SdlangElement(tag.tags["first"].front), "second"));
    assert((cast(Tag) accessor.access(SdlangElement(tag.tags["first"].front), "second")).expectValue!string == "Doe");
}