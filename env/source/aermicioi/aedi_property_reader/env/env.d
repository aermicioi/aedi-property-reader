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
module aermicioi.aedi_property_reader.env.env;

import aermicioi.aedi_property_reader.core.convertor;
import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi_property_reader.core.type_guesser;
import aermicioi.aedi_property_reader.core.document;
import aermicioi.aedi_property_reader.core.std_conv;

alias EnvironmentDocumentContainer = AdvisedDocumentContainer!(string[string], string, StdConvAdvisedConvertor);

auto env() {
    auto container = env(new StringToScalarConvTypeGuesser);
    import std.traits;

    static if (is(StringToScalarConvTypeGuesser: StdConvTypeGuesser!(S, ToTypes), S, ToTypes...)) {
        static foreach (To; ToTypes) {
            container.set(new StdConvAdvisedConvertor!(To, S), fullyQualifiedName!To);
        }
    }

    return container;
}

auto env(TypeGuesser!string guesser) {
    import std.process : environment;
    import std.experimental.allocator;

    EnvironmentDocumentContainer container = new EnvironmentDocumentContainer(environment.toAA);

    container.guesser = guesser;
    container.accessor = new AssociativeArrayAccessor!string;
    container.allocator = theAllocator;

    return container;
}