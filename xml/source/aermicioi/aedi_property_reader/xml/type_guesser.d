module aermicioi.aedi_property_reader.xml.type_guesser;

import aermicioi.aedi_property_reader.core.type_guesser;
import aermicioi.aedi_property_reader.xml.accessor;
import std.xml;

class XmlTypeGuesser : TypeGuesser!XmlElement {

    private {
        TypeGuesser!string guesser_;
    }

    public {
        this(TypeGuesser!string guesser) {
            this.guesser = guesser;
        }

        /**
        Set guesser

        Params:
            guesser = string based guesser of types

        Returns:
            typeof(this)
        **/
        typeof(this) guesser(TypeGuesser!string guesser) @safe nothrow pure {
            this.guesser_ = guesser;

            return this;
        }

        /**
        Get guesser

        Returns:
            TypeGuesser!string
        **/
        inout(TypeGuesser!string) guesser() @safe nothrow pure inout {
            return this.guesser_;
        }

        TypeInfo guess(XmlElement serialized) {

            final switch (serialized.kind) {
                case XmlElement.Kind.attribute: {
                    return guesser.guess(cast(string) serialized);
                }

                case XmlElement.Kind.element: {
                    return guesser.guess((cast(Element) serialized).text);
                }
            }
        }
    }
}