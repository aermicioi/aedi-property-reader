module aermicioi.aedi_property_reader.yaml.accessor;

import dyaml;
import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi.exception.not_found_exception : NotFoundException;
import std.exception;

class YamlNodePropertyAccessor : PropertyAccessor!(Node, Node) {

    Node access(Node component, in string property) const {

        if (this.has(component, property)) {
            return component[property];
        }

        throw new NotFoundException("yaml tag " ~ component.tag ~ " doesn't have child " ~ property);
    }

    bool has(in Node component, in string property) const {
        return component.isMapping && component.containsKey(property);
    }
}

class YamlIntegerIndexAccessor : PropertyAccessor!(Node, Node) {

    Node access(Node component, in string property) const {

        if (this.has(component, property)) {
            import std.conv : to;

            return component[property.to!size_t];
        }

        throw new NotFoundException("yaml tag " ~ component.tag ~ " doesn't have child on index " ~ property);
    }

    bool has(in Node component, in string property) const {
        import std.string;
        import std.conv;

        return property.isNumeric && component.isSequence && (property.to!size_t < component.length);
    }
}