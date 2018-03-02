module aermicioi.aedi_property_reader.yaml.test.accessor;

import aermicioi.aedi_property_reader.yaml.accessor;
import aermicioi.aedi.exception.not_found_exception : NotFoundException;
import dyaml;
import std.exception;

unittest {
    Node node = Loader.fromString("first: \"Joe\"".dup).load;
    auto accessor = new YamlNodePropertyAccessor;

    assert(accessor.has(node, "first"));
    assert(accessor.access(node, "first").as!string == "Joe");
    assert(!accessor.has(node, "unknown"));
    assertThrown!NotFoundException(accessor.access(node, "unknown"));
}

unittest {
    Node node = Loader.fromString("- \"Joe\"\n- \"Moe\"".dup).load;
    auto accessor = new YamlIntegerIndexAccessor;

    assert(accessor.has(node, "1"));
    assert(accessor.access(node, "1").as!string == "Moe");
    assert(!accessor.has(node, "2"));
    assertThrown!NotFoundException(accessor.access(node, "2"));
}