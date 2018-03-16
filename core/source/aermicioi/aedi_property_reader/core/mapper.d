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
module aermicioi.aedi_property_reader.core.mapper;

import aermicioi.aedi_property_reader.core.exception;
import aermicioi.aedi_property_reader.core.convertor;
import aermicioi.aedi_property_reader.core.inspector;
import aermicioi.aedi_property_reader.core.setter;
import aermicioi.aedi_property_reader.core.accessor;
import std.experimental.allocator;
import std.experimental.logger;
import std.exception;
import std.algorithm;
import std.conv;

interface Mapper(From, To) {

    void map(From from, ref To to, RCIAllocator allocator = theAllocator) const;
}

class CompositeMapper(From, To) {

    private {
        bool conversion_;

        Convertor[] convertors_;

        Setter!(To, Object) setter_;
        PropertyAccessor!(From, Object) accessor_;
        Inspector!From fromInspector_;
        Inspector!To toInspector_;
    }

    public {

        @property {
            /**
            Set convertors

            Params:
                convertors = a list of optional convertors used to convert from one format to another one

            Returns:
                typeof(this)
            **/
            typeof(this) convertors(Convertor[] convertors) @safe nothrow pure {
                this.convertors_ = convertors;

                return this;
            }

            /**
            Get convertors

            Returns:
                Convertor[]
            **/
            inout(Convertor[]) convertors() @safe nothrow pure inout {
                return this.convertors_;
            }

            /**
            Set conversion

            Params:
                conversion = wether to convert or not values using convertors.

            Returns:
                typeof(this)
            **/
            typeof(this) conversion(bool conversion) @safe nothrow pure {
                this.conversion_ = conversion;

                return this;
            }

            /**
            Get conversion

            Returns:
                bool
            **/
            inout(bool) conversion() @safe nothrow pure inout {
                return this.conversion_;
            }

            /**
            Set setter

            Params:
                setter = setter used to pass values to component.

            Returns:
                typeof(this)
            **/
            typeof(this) setter(Setter!(To, Object) setter) @safe nothrow pure {
                this.setter_ = setter;

                return this;
            }

            /**
            Get setter

            Returns:
                Setter!(To, Object)
            **/
            inout(Setter!(To, Object)) setter() @safe nothrow pure inout {
                return this.setter_;
            }

            /**
            Set accessor

            Params:
                accessor = property accessor used to extract values from mapped component

            Returns:
                typeof(this)
            **/
            typeof(this) accessor(PropertyAccessor!(From, Object) accessor) @safe nothrow pure {
                this.accessor_ = accessor;

                return this;
            }

            /**
            Get accessor

            Returns:
                PropertyAccessor!(From, Object)
            **/
            inout(PropertyAccessor!(From, Object)) accessor() @safe nothrow pure inout {
                return this.accessor_;
            }

            /**
            Set fromInspector

            Params:
                fromInspector = inspector providing information about mapped component

            Returns:
                typeof(this)
            **/
            typeof(this) fromInspector(Inspector!From fromInspector) @safe nothrow pure {
                this.fromInspector_ = fromInspector;

                return this;
            }

            /**
            Get fromInspector

            Returns:
                Inspector!From
            **/
            inout(Inspector!From) fromInspector() @safe nothrow pure inout {
                return this.fromInspector_;
            }

            /**
            Set toInspector

            Params:
                toInspector = inspector used to provide information about component that will store mapped data

            Returns:
                typeof(this)
            **/
            typeof(this) toInspector(Inspector!To toInspector) @safe nothrow pure {
                this.toInspector_ = toInspector;

                return this;
            }

            /**
            Get toInspector

            Returns:
                Inspector!To
            **/
            inout(Inspector!To) toInspector() @safe nothrow pure inout {
                return this.toInspector_;
            }
        }

        void map(From from, ref To to, RCIAllocator allocator = theAllocator) {

            trace("Mapping ", this.fromInspector.properties(from), " of ", typeid(from), " to ", typeid(to));
            foreach (property; this.fromInspector.properties(from)) {

                trace("Migrating ", property, " property ");
                if (this.toInspector.has(to, property)) {

                    Object value = this.accessor.access(from, property);
                    if (this.fromInspector.typeOf(from, property) != this.toInspector.typeOf(to, property)) {
                        if (this.conversion) {
                            trace(
                                property,
                                " type differs in original component and destination component, ",
                                this.fromInspector.typeOf(from, property), " and ",
                                this.toInspector.typeOf(to, property)
                            );

                            auto compatible = convertors.filter!(c =>
                                c.convertsFrom(this.fromInspector.typeOf(from, property)) &&
                                c.convertsTo(this.toInspector.typeOf(to, property))
                            );

                            enforce!ConvertorException(!compatible.empty, text(
                                "Could not find convertor to convert ", property, " from ", this.fromInspector.typeOf(from, property),
                                " to ", this.toInspector.typeOf(to, property)
                            ));

                            trace("Found convertor for ", property, " from ", compatible.front.from, " to ", compatible.front.to);

                            value = compatible.front.convert(value, this.toInspector.typeOf(to, property), allocator);
                        } else {

                            throw new InvalidArgumentException(text(
                                "Invalid assignment ", property, " has type of ", this.fromInspector.typeOf(from, property),
                                " in from component while in to component it has ", this.toInspector.typeOf(to, property)
                            ));
                        }
                    }

                    this.setter.set(
                        to,
                        value,
                        property
                    );

                    trace("Migrated ", property, " from ", typeid(from), " to ", typeid(to));
                } else {

                    error(typeid(to), " element does not have ", property);
                }
            }
        }
    }
}

class CompositeConvertor(From, To) : Convertor {

    private {
        Mapper!(From, To) mapper_;
    }

    public {
        @property {
            /**
            Set mapper

            Params:
                mapper = mapper used to map from component to component

            Returns:
                typeof(this)
            **/
            typeof(this) mapper(Mapper!(From, To) mapper) @safe nothrow pure {
                this.mapper_ = mapper;

                return this;
            }

            /**
            Get mapper

            Returns:
                Mapper!(From, To)
            **/
            inout(Mapper!(From, To)) mapper() @safe nothrow pure inout {
                return this.mapper_;
            }

            TypeInfo from() const {
                return typeid(From);
            }

            TypeInfo to() const {
                return typeid(To);
            }
        }

        bool convertsFrom(TypeInfo from) const {
            return this.from is from;
        }

        bool convertsFrom(in Object from) const {
            return this.convertsFrom(from.identify);
        }

        bool convertsTo(TypeInfo to) const {
            return this.to is to;
        }

        bool convertsTo(in Object to) const {
            return this.convertsTo(to.identify);
        }

        Object convert(in Object from, TypeInfo to, RCIAllocator allocator = theAllocator) {
            enforce!InvalidArgumentException(this.convertsFrom(from), text(
                "Cannot convert ", from.identify, " to ", typeid(To), " not supported by ", typeid(this)
            ));

            static if (is(To : Object)) {
                To placeholder = allocator.make!To;
            } else {
                Placeholder!To placeholder = allocator.make!(PlaceholderImpl!To)(To.init);
            }

            this.mapper.map(from.unwrap!From, to, allocator);
        }

        void destruct(ref Object converted, RCIAllocator allocator = theAllocator) {
            enforce!InvalidArgumentException(this.convertsFrom(from), text(
                "Cannot destruct ", from.identify, " to ", typeid(To), " not supported by ", typeid(this)
            ));

            allocator.dispose(converted);
            converted = Object.init;
        }
    }
}