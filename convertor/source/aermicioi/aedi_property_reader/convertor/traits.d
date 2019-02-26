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
module aermicioi.aedi_property_reader.convertor.traits;

import std.traits : functionAttributes, variadicFunctionStyle, Variadic, FunctionAttribute, arity;

/**
Tests if field is property getter.
**/
template isPropertyGetter(alias func) {
    bool isPropertyGetter() {
        static foreach (overload; __traits(getOverloads, func)) {

            if (
                (variadicFunctionStyle!overload == Variadic.no) &&
                (arity!overload == 0) && (functionAttributes!overload & FunctionAttribute.property)
            ) {
                return true;
            }
        }

        return false;
    }
}

/**
Tests if field is property setter
**/
template isPropertyPropertySetter(alias Type, string member) {
    static foreach (overload; __traits(getOverloads, Type, member)) {
        static if (!is(found) && isPropertyPropertySetter!overload) {
            enum found = true;
            enum isPropertyPropertySetter = found;
        }
    }

    static if (!is(found) && isPropertyPropertySetter!overload) {
        enum isPropertyPropertySetter = false;
    }

}

/**
ditto
**/
enum isPropertyPropertySetter(alias func) = (variadicFunctionStyle!func == Variadic.no) &&
    (arity!func == 1) && (functionAttributes!func & FunctionAttribute.property);

template match(alias predicate, Types...) {

    static foreach (alias T; Types) {
        static if (!is(typeof(found)) && predicate!T) {
            enum found = true;
            alias match = T;
        }
    }

    static if (!is(typeof(found)) || !found) {

        static assert(false, "No match found for passed template args");
    }
}

/**
Well, it's a nothrow wrapper usable for logger to allow logging in nothrow functions.
**/
T n(T)(lazy T value) nothrow {
    try {
        static if (is(T == void)) {

            value();
        } else {

            return value();
        }
    } catch (Exception e) {
        assert(false, "An exception was thrown where it wasn't expected to.");
    }
}

enum isD(T, X) = is(T : X);

interface PureSafeNothrowToString {
    string toString() @safe pure nothrow;
}