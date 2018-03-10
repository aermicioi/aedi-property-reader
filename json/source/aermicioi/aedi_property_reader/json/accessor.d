module aermicioi.aedi_property_reader.json.accessor;

import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi.exception.not_found_exception : NotFoundException;
import std.json;
import std.exception;
import std.conv : text;

class JsonPropertyAccessor : PropertyAccessor!JSONValue {

    JSONValue access(JSONValue component, in string property) const {

        if (this.has(component, property)) {
            return component.object[property];
        }

        throw new NotFoundException(text("Json ", component, " doesn't have ", property));
    }

    bool has(in JSONValue component, in string property) const {

        return (component.type == JSON_TYPE.OBJECT) && ((property in component.object) !is null);
    }
}

class JsonIndexAccessor : PropertyAccessor!JSONValue {

    JSONValue access(JSONValue component, in string property) const {

        if (this.has(component, property)) {
            import std.conv : to;

            return component.array[property.to!size_t];
        }

        throw new NotFoundException(text("Json ", component, " doesn't have child on index ", property));
    }

    bool has(in JSONValue component, in string property) const {
        import std.string : isNumeric;
        import std.conv : to;

        return (component.type == JSON_TYPE.ARRAY) && property.isNumeric && (component.array.length > property.to!size_t);
    }
}