/**
Aedi property reader - a library for reading configuration out of multiple sources.

Usage:

Building an application often requires for it to be able to read configuration information
out from exterior, being command line arguments, or a json file with properties.
Aedi property reader provides an unified interface for reading config properties out of
a multitude of sources. It is able to read configuration out of following sources:
$(UL
	$(LI Command line )
	$(LI Environment )
	$(LI Xml document )
	$(LI Json document )
 )

To use aedi property reader to load configuration information following steps are required:

$(OL
	$(LI Create a config container )
	$(LI Pass config file, or any required data to it)
	$(LI Define config properties to be read from source)
	$(LI Use properties out of config container)
)

The example below shows the simplest use case presented in steps above:
------------------
module app;
import std.stdio;

import aermicioi.aedi;
import aermicioi.aedi_property_reader;

void properties(T : ConvertorContainer!(FromType, ToType), FromType, ToType)(T container) {
		with (container.configure) { // Create a configuration context for config container
			property!string("protocol"); // Define $(D_INLINECODE protocol ) property of type $(D_INLINECODE string)
			property!string("host");
			property!string("resource");
			property!ushort("port");
			property!(string[string])("arguments"); // Define $(D_INLINECODE arguments ) property of type $(D_INLINECODE string[string])
			property!(size_t[])("nope-an-array");
		}
}

auto load() {
	auto cont = json("config.json");

	cont.properties();
	return cont;
}

void main()
{
	auto cont = load(); // Initialize config container

	writeln("Dumping network connection information:");
	writeln("Protocol: ", cont.locate!string("protocol")); // Write property found in configuration
	writeln("Host: ", cont.locate!string("host"));
	writeln("Port: ", cont.locate!ushort("port"));
	writeln("Arguments: ", cont.locate!(string[string])("arguments")); // Write property found in configuration
	writeln("nope-an-array: ", cont.locate!(size_t[])("nope-an-array"));
}
------------------

The output of example, will yield following answers:
------------------
Dumping network connection information:
Protocol: http
Host: host.io
Port: 8080
Arguments: ["pass":"json.weak-pass", "user":"json.bold-logic"]
nope-an-array: [6, 5, 4, 3, 2, 1]
------------------

Modifying the config.json file will be reflected on next run of the application.

Overriding:

Often it is desired to have a config file that stores default configuration
data, while allowing to override those values from environment or command line.
The library does allow usage of multiple configuration sources toghether,
that in turn allows to implement easily the case above, when certain values may be
overriden. The example below shows a variaton of load function that implements
desired behavior:

-------------------
// ...

auto load() {
	auto cont = container( // Create a config container consisting of other 4 config containers
		argument(), // Create a config container that reads properties from command line
		environment(), // Create a config container that reads properties from environment variables
		xml("config.xml"), // Create a config container that reads properties from $(D_INLINECODE config.xml)
		json("config.json") // Create a config container that reads properties from $(D_INLINECODE config.json)
	);

	foreach (c; cont.containers) { // Iterate each container from composite one and define properties that are to be read from sources.
		c.properties();
	}

	return cont;
}

// ...
-------------------

The modified load function, instead of creating a json config container, creates a joint/composite
container out of 4 different containers, command line argument, environment, xml, and json containers.
The joint container, will search for properties in those subcontainers in order they were defined.
Therefore if a property is defined on command line as an argument, joint container will stop searching
and use it to serve requested property. Same logic applies when a property is passed as environment variable,
the joint container will use it to serve the property to client code. If a property is not defined either
in command line, or environment, container will search in xml config container, and afterwards in json
config container. If a property is not found in all of subcontainers, a $(D_INLINECODE NotFoundException)
is thrown denoting of inexistence of a property.

Replacing old load function with new version, and running the example with following command below,
will show how environment variable and command line argument overrides properties defined in xml config:
-------------------
port=9000 ./initial --host=command.line
-------------------

The result yielded from command run above is below:
-------------------
Dumping network connection information:
Protocol: https
Host: command.line
Port: 9000
Arguments: ["pass":"xml.bold-pass", "user":"xml.weak-logic"]
nope-an-array: [1, 2, 3, 4, 5, 6]
-------------------

As seen from output, the command line argument, and environment variable override the data defined in xml config.
This is due to the behavior of composite config container, that searches for a property through all subcontainers
in order that they were defined during it's construction. Passing other properties as command line arguments or environment
variables will be automatically reflected in example that is run.

Fallback:

An application for end user, that has configuration files, should be able to
read configs from multiple sources in a fallback manner, such as from config
file in root folder of application, then from users configuration directory,
and at end from system wide config.

Due to overriding properties when using multiple config sources as one presented
above, implementing a fallback behavior is straightforward as in example below:
-------------------
// ...

auto load() {
	auto cont = container( // Create a config container consisting of other 4 config containers
		xml("~/.config/aedi-property-reader/config.xml"),
		xml("/etc/aedi-property-reader/config.xml"),
		xml("./config-primary.xml"),
		xml("./config.xml")
	);

	foreach (c; cont.containers) { // Iterate each container from composite one and define properties that are to be read from sources.
		c.properties();
	}

	return cont;
}

// ...
-------------------

The joint container logic is same as in Overriding section. The difference is in contents
of joint container, which are a set of xml config containers reading information from
different config files. Thus, as in order defined in example above, a joint container
will ask config container that reads from users config folder, for a property,
if not found, it will query next, and next containers, until it will find required property.
In case when a config file is inexistent, the config container is initialized with empty
xml document. Same behavior is expected for json config containers.

Running the example, will yield following output:
-------------------
Dumping network connection information:
Protocol: https
Host: overriden.host
Port: 8081
Arguments: ["pass":"xml.bold-pass", "user":"xml.weak-logic"]
nope-an-array: [1, 2, 3, 4, 5, 6]
-------------------

Modyfing $(D_INLINECODE config-primary.xml ), will in turn override values defined in $(D_INLINECODE config.xml ).

The example can be compiled with three different versions, showing each usecase.
$(UL
	$(LI singleSource - a single json config container using config.json file)
	$(LI allSources - multiple config containers used toghether)
	$(LI fallbackSources - multiple config containers reading from different xml files)
)

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
module app;
import std.stdio;

import aermicioi.aedi;
import aermicioi.aedi_property_reader;

/**
Define properties that are available in a config container for use.

Define properties that are available in a config container for use.
Defining of properties for a container is imperative due to need
of specifying the type that a property has, since the format of data
source from which is read the property is not guaranteed to provide
the type of data it's passing, or simply does not provide means of
defining more complex types than existing primitives.

Params:
	container = config container for which properties are defined
**/
void properties(T : DocumentContainer!(FromType, ToType), FromType, ToType)(T container) {
		with (container.configure) { // Create a configuration context for config container
			property!string("server"); // Define $(D_INLINECODE protocol ) property of type $(D_INLINECODE string)
			property!string("host");
			property!string("resource");
			property!ushort("port");
			property!(string[string])("arguments"); // Define $(D_INLINECODE arguments ) property of type $(D_INLINECODE string[string])
			property!(size_t[])("nope-an-array");
		}
}

version (singleSource) {
	/**
	Create a config container that reads information from json file.

	Returns:
		Container a container with loaded config properties
	**/
	auto load() {
		auto cont = json("config.json");

		cont.properties();
		return cont;
	}
}

version (allSources) {
	/**
	Create a config container that reads from 4 sources of information.

	Create a config container that reads from 4 sources of information.
	Those sources are:
		$(UL
			$(LI Command line )
			$(LI Environment variables )
			$(LI Xml document )
			$(LI Json document )
		)
	A config container consisting of more than one source of information will attempt
	to find requested parameter sequentally in all sources in order defined at creation
	of config container.

	Returns:
		Container a container with loaded config properties
	**/
	auto load() {
		auto cont = container( // Create a config container consisting of other 4 config containers
			argument(), // Create a config container that reads properties from command line
			environment(), // Create a config container that reads properties from environment variables
			xml("config.xml"), // Create a config container that reads properties from $(D_INLINECODE config.xml)
			json("config.json") // Create a config container that reads properties from $(D_INLINECODE config.json)
		);

		foreach (c; cont.containers) { // Iterate each container from composite one and define properties that are to be read from sources.
			c.properties();
		}

		return cont;
	}
}

version (fallbackSources) {
	/**
	Create a config container that is able to fallback to default config file.

	Create a config container that is able to fallback to default config file.

	Returns:
		Container a container with loaded config properties
	**/
	auto load() {
		auto cont = container( // Create a config container consisting of other 4 config containers
			xml("~/.config/aedi-property-reader/config.xml"),
			xml("/etc/aedi-property-reader/config.xml"),
			xml("./config-primary.xml"),
			xml("./config.xml")
		);

		foreach (c; cont.containers) { // Iterate each container from composite one and define properties that are to be read from sources.
			c.properties();
		}

		return cont;
	}
}


void main()
{
	auto cont = load(); // Initialize config container

	writeln("Dumping network connection information:");
	writeln("Protocol: ", cont.locate!string("protocol")); // Write property found in configuration
	writeln("Host: ", cont.locate!string("host"));
	writeln("Port: ", cont.locate!ushort("port"));
	writeln("Arguments: ", cont.locate!(string[string])("arguments")); // Write assoc array found in configuration
	writeln("nope-an-array: ", cont.locate!(size_t[])("nope-an-array"));
}
