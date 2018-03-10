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

    Element access(Element component, in string property) const {

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

class XmlElementIndexAccessor : PropertyAccessor!Element {

    Element access(Element component, in string property) const {

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
    string access(Element component, in string property) const {

        if (this.has(component, property)) {
            return component.tag.attr[property];
        }

        throw new NotFoundException("Xml tag " ~ component.toString ~ " doesn't have attribute " ~ property);
    }

    bool has(in Element component, in string property) const {
        enforce!Exception(component !is null, "Cannot access " ~ property ~ " of null component");

        return (property in component.tag.attr) !is null;
    }
}