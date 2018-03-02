module aermicioi.aedi_property_reader.xml.accessor;

import std.xml;
import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi.exception.not_found_exception : NotFoundException;
import taggedalgebraic : TaggedAlgebraic;
import std.exception;
import std.algorithm;
import std.array;

union XmlElementUnion {
    string attribute;
    Element element;
};

alias XmlElement = TaggedAlgebraic!XmlElementUnion;

class XmlElementPropertyAccessor : PropertyAccessor!Element {

    Element access(Element component, string property) const {

        if (this.has(component, property)) {
            return component.elements.find!(e => e.tag.name == property).front;
        }

        throw new NotFoundException("Xml tag " ~ component.toString ~ " doesn't have child " ~ property);
    }

    bool has(in Element component, string property) const {
        enforce!Exception(component !is null, "Cannot access " ~ property ~ " of null component");

        return component.elements.canFind!(e => e.tag.name == property);
    }
}

class XmlElementIndexAccessor : PropertyAccessor!(Element, Element) {

    Element access(Element component, string property) const {

        if (this.has(component, property)) {
            import std.conv : to;

            return component.elements[property.to!size_t];
        }

        throw new NotFoundException("Xml tag " ~ component.toString ~ " doesn't have child on index " ~ property);
    }

    bool has(in Element component, string property) const {
        import std.string;
        import std.conv;
        enforce!Exception(component !is null, "Cannot access " ~ property ~ " of null component");

        return property.isNumeric && (component.elements.length > property.to!size_t);
    }
}

class XmlAttributePropertyAccessor : PropertyAccessor!(Element, string) {
    string access(Element component, string property) const {

        if (this.has(component, property)) {
            return component.tag.attr[property];
        }

        throw new NotFoundException("Xml tag " ~ component.toString ~ " doesn't have attribute " ~ property);
    }

    bool has(in Element component, string property) const {
        enforce!Exception(component !is null, "Cannot access " ~ property ~ " of null component");

        return (property in component.tag.attr) !is null;
    }
}