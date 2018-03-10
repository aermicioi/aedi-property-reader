module aermicioi.aedi_property_reader.sdlang.type_guesser;

import aermicioi.aedi_property_reader.core.type_guesser;
import aermicioi.aedi_property_reader.sdlang.accessor;
import sdlang.ast;

class SdlangTypeGuesser : TypeGuesser!SdlangElement {

    public {

        TypeInfo guess(SdlangElement serialized) {

            final switch (serialized.kind) {
                case SdlangElement.Kind.tag: {
                    if ((cast(Tag) serialized).values.length > 0) {
                        return (cast(Tag) serialized).values[0].type;
                    }

                    return typeid(Tag);
                }
                case SdlangElement.Kind.attribute: {

                    return (cast(Attribute) serialized).value.type;
                }
            }
        }
    }
}