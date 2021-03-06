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
	aermicioi
**/
module app;

import aermicioi.aedi;
import aermicioi.aedi : AediNotFoundException = NotFoundException;
import aermicioi.aedi.util.range : exceptions, filterByInterface;
import aermicioi.aedi_property_reader;
import std.stdio;
import std.algorithm;
import std.range;
import std.array : array;
import std.experimental.allocator;
import std.conv;

public alias configure = aermicioi.aedi.configurer.register.context.configure;
public alias configure = aermicioi.aedi_property_reader.core.core.configure;

@component
class Car {
    @setter("car.color".lref)
    Color color;

    @setter("car.size".lref)
    Size size;

    @setter("car.weight".lref)
    double weight;

    @callback((Locator!() locator, ref Car component) {
        component.doors = [
            locator.locate!Door("car.door.front.left"),
            locator.locate!Door("car.door.front.right"),
            locator.locate!Door("car.door.back.left"),
            locator.locate!Door("car.door.back.right"),
        ];
    })
    Door[] doors;

    @callback((Locator!() locator, ref Car component) {
        component.tires = [
            locator.locate!Tire,
            locator.locate!Tire,
            locator.locate!Tire,
            locator.locate!Tire,
        ];
    })
    Tire[] tires;

    @autowired
    Engine engine;

    @setter("car.vendor".lref)
    string vendor;

    override string toString() {return text("Car(", color, ", ", size, ", ", doors, ", ", tires, ", ", weight, ", ", engine, ", ", vendor, ")");}
}

class Door {
    enum Locking {
        manual,
        automatic
    }

    Window window;

    Locking locking;

    string position;

    override string toString() {return text("Door(", window, ", ", locking, ", ", position, ")");}
}

class Window {

    Size size;
    double transparency;
    Color color;

    override string toString() {return text("Window(", size, ", ", transparency, ", ", color, ")");}
}

class Tire {
    double pressure;
    double size;
    string vendor;

    override string toString() {return text("Tire(", pressure, ", ", size, ", ", vendor, ")");}
}

struct Color {
    ubyte r;
    ubyte g;
    ubyte b;
}

struct Size {

    long width;
    long height;
    long length;
}

/**
Interface for engines.

An engine should implement it, in order to be installable in a car.
**/
interface Engine {

    public {

        void run();
    }
}

/**
A concrete implementation of Engine that uses gasoline for propelling.
**/
class GasolineEngine : Engine {

    public {

        void run() {
            writeln("Gasoline engine running sound...");
        }
    }
}

/**
A concrete implementation of Engine that uses diesel for propelling.
**/
class DieselEngine : Engine {

    public {

        void run() {
            writeln("Diesel engine running sound...");
        }
    }
}

/**
A concrete implementation of Engine that uses electricity for propelling.
**/
class ElectricEngine : Engine {
    public {

        void run() {
            writeln("Electric engine running sound...");
        }
    }
}

void drive(Car car) {
    writeln("What a nice car, with following specs:");
    writeln("Size:\t", car.size);
    writeln("Color:\t", car.color);
    writeln("Engine:\t", car.engine);

    writeln("Door front left:\t", car.doors[0], "\t located at memory ", cast(void*) car.doors[0]);
    writeln("Door front right:\t", car.doors[1], "\t located at memory ", cast(void*) car.doors[1]);
    writeln("Door back left: \t", car.doors[2], "\t located at memory ", cast(void*) car.doors[2]);
    writeln("Door back right:\t", car.doors[3], "\t located at memory ", cast(void*) car.doors[3]);

    writeln("Tire front left:\t", car.tires[0], "\t located at memory ", cast(void*) car.tires[0]);
    writeln("Tire front right:\t", car.tires[1], "\t located at memory ", cast(void*) car.tires[1]);
    writeln("Tire back left: \t", car.tires[2], "\t located at memory ", cast(void*) car.tires[2]);
    writeln("Tire back right:\t", car.tires[3], "\t located at memory ", cast(void*) car.tires[3]);
}

void main(string[] args) {

    auto c = container(
        singleton.typed,
        prototype,
        values,
        container(
            container(
                argument,
                env,
                properd("car.properties"),
            ),
            container(
                xml("car.xml"),
                json("car.json"),
                sdlang("car.sdlang"),
                yaml("car.yaml")
            )
        )
    ).describing("Car manufacturing application");

    foreach (subcontainer; c.decorated[3][0]) {
        with (subcontainer.configure(c)) {
            register!string("car.vendor").describe("car vendor", "vendor of constructed car");
            register!string("tire.vendor").describe("tire vendor", "vendor of tires used in car").optional("good.tire");
            register!double("car.weight").describe("car weight", "weight of constructoed car");
            register!ubyte("car.color.r").optional(cast(ubyte) 255).describe("car red color", "");
            register!ubyte("car.color.g").optional(cast(ubyte) 255).describe("car green color", "");
            register!ubyte("car.color.b").optional(cast(ubyte) 255).describe("car blue color", "");
            register!bool("help").optional(false).describe("Help information", "Display help information in console");
		    register!bool("verbose").optional(false).describe("Verbose mode", "Display any issues in console");
        }
    }

    foreach (subcontainer; c.decorated[3][1]) {
        with (subcontainer.configure(c)) {
            register!Door("car.door.front.left").describe("front left door", "front left door of constructed car");
            register!Door("car.door.front.right").describe("front right door", "front right door of constructed car");
            register!Door("car.door.back.left").describe("back left door", "back left door of constructed car");
            register!Door("car.door.back.right").describe("back right door", "back right door of constructed car");
            register!Window;
            register!Size("car.size");
            register!Color("car.color");
            register!(Door.Locking);
        }
    }

    with (c.decorated[0].configure(c)) {
        c.decorated[0].scan!app(c);

        register!(Engine, ElectricEngine);
        register!Color("car.color")
            .set!"r"("car.color.r".lref)
            .set!"g"("car.color.g".lref)
            .set!"b"("car.color.b".lref);
    }

    with(c.decorated[1].configure) {
        register!Tire
            .set!"pressure"(1.0)
            .set!"size"(17)
            .set!"vendor"("tire.vendor".lref);
    }

    if (c.locate!bool("help")) {
        import std.getopt : defaultGetoptPrinter, Option;

        defaultGetoptPrinter(
            c.locate!(Describer!()).describe(null, c).title,
            c.locate!(DescriptionsProvider!string)
                .provide
                .map!(description => Option(description.identity, text(description.title, "\t-\t", description.description)))
                .array
        );

        return;
    }

    try {

        c.locate!Car.drive;
    } catch (Exception e) {
        import std.getopt : defaultGetoptPrinter, Option;

        // foreach (exception; e.exceptions.filterByInterface!AediNotFoundException) {
        //     defaultGetoptPrinter(
        //         text("Missing ", c.locate!(Describer!()).describe(exception.identity, null).title, " please provide it on command line, environment, or configuration file"),
        //         c.locate!(Describer!()).describe(exception.identity, null)
        //             .only
        //             .map!(description => Option(description.identity, text(description.title, "\t-\t", description.description)))
        //             .array
        //     );
        // }

        // if (c.locate!bool("verbose")) {
        //     throw e;
        // }
        throw e;
    }
}