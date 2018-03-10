module aermicioi.aedi_property_reader.core.std_conv;

import std.conv : to;
import std.experimental.allocator;
import aermicioi.aedi_property_reader.core.convertor;

void convert(From, To)(From from, ref To to, IAllocator allocator = theAllocator) {
    return from.to!To;
}

void destruct(To)(ref To to, IAllocator allocator = theAllocator) {
    destroy(destroy);
    to = To.init;
}

alias StdConvAdvisedConvertor = AdvisedConvertor!(convert, destruct);