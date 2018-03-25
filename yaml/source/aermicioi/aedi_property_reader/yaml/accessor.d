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
module aermicioi.aedi_property_reader.yaml.accessor;

import dyaml;
import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi.exception.not_found_exception : NotFoundException;
import std.exception;
import std.experimental.logger;
import aermicioi.aedi_property_reader.core.traits : n;

/**
An accessor allowing access to child yaml nodes of a parent yaml node by their name
**/
class YamlNodePropertyAccessor : PropertyAccessor!(Node, Node) {

    /**
     Get a property out of component

     Params:
         component = a component which has some properties identified by property.
     Throws:
         NotFoundException in case when no requested property is available.
         InvalidArgumentException in case when passed arguments are somehow invalid for use.
     Returns:
         FieldType accessed property.
     **/
    Node access(Node component, in string property) const {

        if (this.has(component, property)) {
            return component[property];
        }

        throw new NotFoundException("yaml tag " ~ component.tag ~ " doesn't have child " ~ property);
    }

    /**
     Check if requested property is present in component.

     Check if requested property is present in component.
     The method could have allocation side effects due to the fact that
     it is not restricted in calling access method of the accessor.

     Params:
         component = component which is supposed to have property
         property = speculated property that is to be tested if it is present in component
     Returns:
         true if property is in component
     **/
    bool has(in Node component, in string property) const nothrow {
        try {
            return component.isMapping && component.containsKey(property);
        } catch (Exception e) {

            error("Failed to check property ", property, " existence due to ", e).n;
        }

        return false;
    }

    /**
     Identify the type of supported component.

     Identify the type of supported component. It returns type info of component
     if it is supported by accessor, otherwise it will return typeid(void) denoting that
     the type isn't supported by accessor. The accessor is not limited to returning the type
     info of passed component, it can actually return type info of super type or any type
     given the returned type is implicitly convertible or castable to ComponentType.

     Params:
         component = the component for which accessor should identify the underlying type

     Returns:
         TypeInfo type information about passed component, or typeid(void) if component is not supported.
     **/
    TypeInfo componentType(Node component) const nothrow {
        return typeid(Node);
    }
}

/**
An accessor allowing access to child yaml nodes of a parent yaml node by their index
**/
class YamlIntegerIndexAccessor : PropertyAccessor!(Node, Node) {

    /**
     Get a property out of component

     Params:
         component = a component which has some properties identified by property.
     Throws:
         NotFoundException in case when no requested property is available.
         InvalidArgumentException in case when passed arguments are somehow invalid for use.
     Returns:
         FieldType accessed property.
     **/
    Node access(Node component, in string property) const {

        if (this.has(component, property)) {
            import std.conv : to;

            return component[property.to!size_t];
        }

        throw new NotFoundException("yaml tag " ~ component.tag ~ " doesn't have child on index " ~ property);
    }

    /**
     Check if requested property is present in component.

     Check if requested property is present in component.
     The method could have allocation side effects due to the fact that
     it is not restricted in calling access method of the accessor.

     Params:
         component = component which is supposed to have property
         property = speculated property that is to be tested if it is present in component
     Returns:
         true if property is in component
     **/
    bool has(in Node component, in string property) const nothrow {
        try {
            import std.string;
            import std.conv;

            return property.isNumeric && component.isSequence && (property.to!size_t < component.length);
        } catch (Exception e) {

            error("Failed to check property ", property, " existence due to ", e).n;
        }

        return false;
    }

    /**
     Identify the type of supported component.

     Identify the type of supported component. It returns type info of component
     if it is supported by accessor, otherwise it will return typeid(void) denoting that
     the type isn't supported by accessor. The accessor is not limited to returning the type
     info of passed component, it can actually return type info of super type or any type
     given the returned type is implicitly convertible or castable to ComponentType.

     Params:
         component = the component for which accessor should identify the underlying type

     Returns:
         TypeInfo type information about passed component, or typeid(void) if component is not supported.
     **/
    TypeInfo componentType(Node component) const nothrow {
        return typeid(Node);
    }

}