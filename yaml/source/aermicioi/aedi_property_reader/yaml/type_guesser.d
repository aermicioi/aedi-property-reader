module aermicioi.aedi_property_reader.yaml.type_guesser;

import aermicioi.aedi_property_reader.core.type_guesser;
import dyaml;

class YamlTypeGuesser : TypeGuesser!Node {

    public {

        TypeInfo guess(Node serialized) {

            if (serialized.isInt) {
                return typeid(long);
            }

            if (serialized.isFloat) {
                return typeid(real);
            }

            if (serialized.isBinary) {
                return typeid(ubyte[]);
            }

            if (serialized.isBool) {
                return typeid(bool);
            }

            if (serialized.isString) {
                return typeid(string);
            }

            if (serialized.isTime) {
                import std.datetime : SysTime;
                return typeid(SysTime);
            }

            return typeid(serialized);
        }
    }
}