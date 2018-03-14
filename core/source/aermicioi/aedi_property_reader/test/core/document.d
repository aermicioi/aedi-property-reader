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
module aermicioi.aedi_property_reader.core.test.document;

import aermicioi.aedi : locate, NotFoundException;
import aermicioi.aedi_property_reader.core.document : DocumentContainer;
import aermicioi.aedi_property_reader.core.type_guesser : StringToScalarConvTypeGuesser;
import aermicioi.aedi_property_reader.core.accessor : AssociativeArrayAccessor;
import aermicioi.aedi_property_reader.core.convertor : CallbackConvertor;
import aermicioi.aedi_property_reader.core.std_conv : StdConvAdvisedConvertor;
import std.experimental.allocator;
import std.exception;

unittest {

    DocumentContainer!(string[string], string) document = new DocumentContainer!(string[string], string)([
        "foo": "foofoo",
        "moo": "10"
    ]);

    document.guesser = new StringToScalarConvTypeGuesser;
    document.accessor = new AssociativeArrayAccessor!string;
    document.allocator = theAllocator;

    document.set(new StdConvAdvisedConvertor!(long, string), "long");
    document.set(new StdConvAdvisedConvertor!(string, string), "string");

    assert(document.has("foo"));
    assert(!document.has("coo"));

    assert(document.locate!long("moo") == 10);
    assert(document.locate!string("foo") == "foofoo");

    assertThrown!NotFoundException(document.locate!int("coo"));
}