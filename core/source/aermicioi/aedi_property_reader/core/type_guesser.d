module aermicioi.aedi_property_reader.core.type_guesser;

interface TypeGuesser(SerializedType) {

    public {

        TypeInfo guess(SerializedType serialized);
    }
}

class StdConvTypeGuesser(SerializedType, ConvertableTypes...) : TypeGuesser!SerializedType {

    public {

        TypeInfo guess(SerializedType serialized) {
            import std.conv;

            foreach (ConvertableType; ConvertableTypes) {
                try {
                    cast(void) serialized.to!ConvertableType;
                    return typeid(ConvertableType);
                } catch (ConvException ex) {

                }
            }

            return typeid(SerializedType);
        }
    }
}

alias StringStdConvTypeGuesser(ConvertableTypes...) = StdConvTypeGuesser!(string, ConvertableTypes);
alias StringToScalarConvTypeGuesser = StringStdConvTypeGuesser!(
    bool,
    ubyte,
    ushort,
    uint,
    ulong,
    byte,
    short,
    int,
    long,
    float,
    double,
    bool[],
    ubyte[],
    ushort[],
    uint[],
    ulong[],
    byte[],
    short[],
    int[],
    long[],
    float[],
    double[],
);