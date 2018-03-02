module aermicioi.aedi_property_reader.sdlang.accessor;

import sdlang.ast;
import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi.exception.not_found_exception : NotFoundException;
import taggedalgebraic : TaggedAlgebraic;
import std.exception;

union SdlangElementUnion {
    Tag tag;
    Attribute attribute;
};

alias SdlangElement = TaggedAlgebraic!(SdlangElementUnion);

class SdlangTagPropertyAccessor : PropertyAccessor!(Tag, Tag) {

    Tag access(Tag component, string property) const {

        if (property in component.tags) {
            return component.tags[property].front;
        }

        throw new NotFoundException("Sdlang tag " ~ component.getFullName.toString ~ " doesn't have child " ~ property);
    }

    bool has(in Tag component, string property) const {
        enforce!Exception(component !is null, "Cannot access " ~ property ~ " of null component");

        return property in (cast(Tag) component).tags;
    }
}

class SdlangIntegerIndexAccessor : PropertyAccessor!(Tag, Tag) {

    Tag access(Tag component, string property) const {

        if (this.has(component, property)) {
            import std.conv : to;

            return component.tags[property.to!size_t];
        }

        throw new NotFoundException("Sdlang tag " ~ component.getFullName.toString ~ " doesn't have child on index " ~ property);
    }

    bool has(in Tag component, string property) const {
        import std.string;
        import std.conv;
        enforce!Exception(component !is null, "Cannot access " ~ property ~ " of null component");

        return property.isNumeric && ((cast(Tag) component).tags.length > property.to!size_t);
    }
}

class SdlangAttributePropertyAccessor : PropertyAccessor!(Tag, Attribute) {
    Attribute access(Tag component, string property) const {

        if (property in component.attributes) {
            return component.attributes[property].front;
        }

        throw new NotFoundException("Sdlang tag " ~ component.getFullName.toString ~ " doesn't have attribute " ~ property);
    }

    bool has(in Tag component, string property) const {
        enforce!Exception(component !is null, "Cannot access " ~ property ~ " of null component");

        return property in (cast(Tag) component).attributes;
    }
}