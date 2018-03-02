module aermicioi.aedi_property_reader.yaml.test.type_guesser;

import dyaml;
import aermicioi.aedi_property_reader.yaml.type_guesser;

unittest {

    YamlTypeGuesser guesser = new YamlTypeGuesser();

    Node root = Loader.fromString("first:\n  long: 10\n  string: \"test\"".dup).load;
    assert(guesser.guess(root["first"]["long"]) is typeid(long));
    assert(guesser.guess(root["first"]["string"]) is typeid(string));
}