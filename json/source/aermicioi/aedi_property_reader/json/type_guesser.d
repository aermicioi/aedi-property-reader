module aermicioi.aedi_property_reader.json.type_guesser;

import aermicioi.aedi_property_reader.core.type_guesser;
import aermicioi.aedi_property_reader.json.accessor;
import std.json;

class JsonTypeGuesser : TypeGuesser!JSONValue {

    public {

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