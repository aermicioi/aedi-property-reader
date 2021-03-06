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
module aermicioi.aedi_property_reader.json.inspector;

import aermicioi.aedi.configurer.annotation.annotation;
import aermicioi.aedi_property_reader.convertor.inspector;
import aermicioi.aedi_property_reader.convertor.type_guesser;
import std.string;
import std.conv;
import std.json;
import std.range;
import std.algorithm;

@component
auto runtimeJsonInspector(JsonInspector inspector) {
    return new RuntimeInspector!JSONValue(inspector);
}

/**
Inspector for json values.
**/
@component
class JsonInspector : Inspector!JSONValue {

    /**
    Identify the type of child field of component.

    Params:
        component = a composite component (class, struct, assoc array etc.) containing some fields

    Returns:
        Type of field, or typeid(void) if field is not present in component
    **/
    TypeInfo typeOf(JSONValue component, in string property) const nothrow {
        try {

            switch (component.type) {
                case JSON_TYPE.ARRAY: {
                    if (property.isNumeric) {
                        return this.typeOf(component.array[property.to!size_t]);
                    }

                    break;
                }

                case JSON_TYPE.OBJECT: {
                    return this.typeOf(component.object[property]);
                }

                default: {
                    return typeid(void);
                }
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
    TypeInfo typeOf(JSONValue component) const nothrow {
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
    bool has(JSONValue component, in string property) const nothrow {
        try {

            switch (component.type) {
                case JSON_TYPE.OBJECT: {
                    return (property in component.object) !is null;
                }

                default: {
                    return false;
                }
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
    string[] properties(JSONValue component) const nothrow {
        try {

            switch (component.type) {
                case JSON_TYPE.OBJECT: {
                    return component.object.byKey.array;
                }

                default: {
                    return [];
                }
            }
        } catch (Exception e) {

        }

        return [];
    }
}