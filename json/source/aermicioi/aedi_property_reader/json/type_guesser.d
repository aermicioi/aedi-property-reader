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
module aermicioi.aedi_property_reader.json.type_guesser;

import aermicioi.aedi_property_reader.core.type_guesser;
import aermicioi.aedi_property_reader.json.accessor;
import std.json;

/**
Json type guesser
**/
class JsonTypeGuesser : TypeGuesser!JSONValue {

    public {

        /**
        Guess type of underlying json element.

        Params:
            serialized = json element to be inspected

        Returns:
            TypeInfo of underlying data
        **/
        TypeInfo guess(JSONValue serialized) {

            final switch (serialized.type) {
                case JSON_TYPE.ARRAY:
                    return typeid(JSONValue[]);
                case JSON_TYPE.OBJECT:
                    return typeid(JSONValue[string]);
                case JSON_TYPE.FALSE:
                    return typeid(bool);
                case JSON_TYPE.FLOAT:
                    return typeid(double);
                case JSON_TYPE.INTEGER:
                    return typeid(long);
                case JSON_TYPE.NULL:
                    return typeid(void*);
                case JSON_TYPE.STRING:
                    return typeid(string);
                case JSON_TYPE.TRUE:
                    return typeid(bool);
                case JSON_TYPE.UINTEGER:
                    return typeid(ulong);
            }
        }
    }
}