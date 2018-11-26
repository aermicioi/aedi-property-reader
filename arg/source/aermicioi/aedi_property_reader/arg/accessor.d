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
module aermicioi.aedi_property_reader.arg.accessor;

import aermicioi.aedi.exception.not_found_exception;
import aermicioi.aedi_property_reader.convertor.accessor;
import std.algorithm;
import std.array;
import std.string;
import std.conv;
import std.range;
import std.experimental.allocator;

/**
Accessor filtering a list of strings out of strings that are not containing a command line property
**/
class ArgumentAccessor : PropertyAccessor!(const(string)[]) {

    private static struct Filter {
        string property;

        const(string)[] component;
        const(string)[] buff;

        nothrow {
            this(const(string)[] component, string property) {
                this.component = component;
                this.property = property;
                take(1);
            }

            Filter save() {
                return this;
            }

            string front() {

                return buff[0];
            }

            void popFront() {
                if (buff.length > 1) {

                    buff = buff.drop(1);
                    return;
                }

                if (buff.length > 0) {

                    buff = buff.drop(1);
                    this.advance;
                }
            }

            bool empty() {
                return buff.empty && component.empty;
            }

            private void take(size_t amount = 1) {
                buff = (component.length >= amount) ? component.take(amount) : component.take(component.length);
                component = (component.length >= amount) ? component.drop(amount) : component.drop(component.length);
            }

            private void advance() {
                while (!component.empty) {
                    try {

                        if (component.front.commonPrefix("--").equal("--")) {
                            auto splitted = component.front.splitter("=");

                            if ((splitted.front.strip('-') == property) && !splitted.take(1).empty) {
                                take(1);
                                return;
                            }

                            if (
                                (component.length > 1) && (splitted.front.strip('-') == property) &&
                                splitted.drop(1).front.commonPrefix("--").empty
                            ) {
                                take(2);
                                return;
                            }
                        }

                        if (component.front.commonPrefix("--").equal("-")) {

                            if (
                                (component.front.strip('-').equal(property)) || ((property.length == 1) &&
                                component.front.strip('-').canFind(property))
                            ) {
                                take(1);
                                return;
                            }
                        }

                        if (
                            !component.front.splitter("=").drop(1).empty &&
                            component.front.splitter("=").front.equal(property)
                        ) {
                            take(1);
                            return;
                        }

                        if (property.isNumeric) {
                            immutable auto up = property.to!size_t;
                            size_t current;

                            auto count = component.countUntil!(c => c.commonPrefix("--").empty &&
                                c.splitter("=").drop(1).empty && (current++ == up));
                            component = component.drop(count);
                            take(1);
                            component = null;
                            return;
                        }

                        component = component.empty ? component : component.drop(1);
                    } catch (Exception e) {
                        assert(false, text("Could not filter out command line arguments for ", property));
                    }
                }
            }
        }
    }

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
    const(string)[] access(const(string)[] component, string property, RCIAllocator allocator = theAllocator) const {
        if (property.empty) {
            return component;
        }

        return Filter(component, property).array;
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
    bool has(in const(string)[] component, string property, RCIAllocator allocator = theAllocator) const nothrow {

        if (component.length > 1) {

            return !Filter(component, property).drop(1).empty;
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
    TypeInfo componentType(const(string)[] component) const nothrow {
        return typeid(const(string)[]);
    }
}