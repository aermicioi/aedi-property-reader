module aermicioi.aedi_property_reader.arg.accessor;

import aermicioi.aedi.exception.not_found_exception;
import aermicioi.aedi_property_reader.core.accessor;
import std.algorithm;
import std.array;
import std.string;
import std.conv;
import std.range;

class ArgumentAccessor : PropertyAccessor!(const(string)[]) {

    private static struct Filter {
        string property;

        const(string)[] component;
        string front_;

        this(const(string)[] component, string property) {
            this.component = component;
            this.property = property;
            this.popFront;
        }

        Filter save() {
            return this;
        }

        string front() {

            return front_;
        }

        void popFront() {

            while (!component.empty) {
                front_ = component.front;

                if (component.front.commonPrefix("--").equal("--")) {
                    auto splitted = component.front.splitter("=");

                    if ((splitted.front.strip('-') == property) && !splitted.take(1).empty) {
                        break;
                    }

                    // if ((component.length > 1) && (splitted.front.strip('-') == property) && splitted.drop(1).front.commonPrefix("--").empty) {
                    //     this.front_ = component[0 .. 2];
                    //     component = component[1 .. $];
                    //     break;
                    // }
                }

                if (component.front.commonPrefix("--").equal("-")) {
                    if ((component.front.strip('-').equal(property)) || ((property.length == 1) && component.front.strip('-').canFind(property))) {
                        break;
                    }
                }

                if (!component.front.splitter("=").drop(1).empty && component.front.splitter("=").front.equal(property)) {
                    break;
                }

                if (property.isNumeric) {
                    auto up = property.to!size_t;
                    size_t current;

                    auto count = component.countUntil!(c => c.commonPrefix("--").empty && c.splitter("=").drop(1).empty && (current++ == up));
                    break;
                }

                component.popFront;
            }

            if (!component.empty) {
                component.popFront;
            }
        }

        bool empty() {
            return component.empty;
        }
    }

    const(string)[] access(const(string)[] component, string property) const {

        return Filter(component, property).array;
    }

    bool has(string[] component, string property) const {

        return Filter(component, property).empty;
    }
}