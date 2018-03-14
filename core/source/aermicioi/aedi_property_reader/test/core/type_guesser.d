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
module aermicioi.aedi_property_reader.core.test.type_guesser;

import aermicioi.aedi_property_reader.core.type_guesser;

unittest {
    auto guesser = new StringToScalarConvTypeGuesser;

    assert(guesser.guess("true") is typeid(bool));
    assert(guesser.guess("20") is typeid(long));
    assert(guesser.guess("20.0") is typeid(double));
    assert(guesser.guess("a") is typeid(char));
    assert(guesser.guess("[true]") is typeid(bool[]));
    assert(guesser.guess("[20]") is typeid(long[]));
    assert(guesser.guess("[20.0]") is typeid(double[]));
    assert(guesser.guess("[\"20\"]") is typeid(string[]));
    assert(guesser.guess("a string") is typeid(string));
}