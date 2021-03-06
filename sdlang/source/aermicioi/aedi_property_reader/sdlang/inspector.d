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
module aermicioi.aedi_property_reader.sdlang.inspector;

import aermicioi.aedi.configurer.annotation.annotation;
import aermicioi.aedi_property_reader.convertor.exception : NotFoundException;
import aermicioi.aedi_property_reader.convertor.inspector;
import aermicioi.aedi_property_reader.sdlang.accessor;
import sdlang;
import sdlang.ast;
import std.algorithm;

/**
Inspector for sdlang tags.
**/
@component
class SdlangTagInspector : Inspector!Tag {

    /**
    Identify the type of child field of component.

    Params:
        component = a composite component (class, struct, assoc array etc.) containing some fields

    Returns:
        Type of field, or typeid(void) if field is not present in component
    **/
    TypeInfo typeOf(Tag component, in string property) const nothrow {
        try {
            auto fields = component.tags.filter!(c => c.name == property);

            if (!fields.empty) {
                return typeid(Tag);
            }

            auto attributes = component.attributes.filter!(a => a.name == property);

            if (!attributes.empty) {
                return typeid(Attribute);
            }
        } catch (Exception e) {

        }

        return typeid(void);
    }

    /**
    Identify the type of component itself.

    Identify the type of component itself. It will inspect the component and will return accurate
    type info that the component represents.

    Params:
        component = component which should be identified.

    Returns:
        Type info of component, or typeid(void) if component cannot be identified by inspector
    **/
    TypeInfo typeOf(Tag component) const nothrow {
        return typeid(component);
    }

    /**
    Check if component has a field or a property.

    Params:
        component = component with fields
        property = component property that is tested for existence

    Returns:
        true if field is present either in readonly, or writeonly form (has getters and setters).
    **/
    bool has(Tag component, in string property) const nothrow {
        try {

            auto fields = component.tags.filter!(c => c.name == property);

            if (!fields.empty) {
                return true;
            }

            auto attributes = component.attributes.filter!(a => a.name == property);

            if (!attributes.empty) {
                return true;
            }
        } catch (Exception e) {

        }

        return false;
    }

    /**
    Return a list of properties that component holds.

    Params:
        component = the component with fields

    Returns:
        an arary of property identities.
    **/
    string[] properties(Tag component) const nothrow {
        try {
            import std.range : only, chain;
            import std.array : array;
            return chain(component.tags.map!(c => c.name), component.attributes.map!(c => c.name)).array;
        } catch (Exception e) {

        }

        return [];
    }
}