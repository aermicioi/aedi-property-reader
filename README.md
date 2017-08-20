# Aedi property reader, a library for reading configuration properties from multiple sources. 

[![Dub license](https://img.shields.io/dub/l/aedi-property-reader.svg)]()
[![Travis CI](https://img.shields.io/travis/aermicioi/aedi-property-reader/master.svg)](https://travis-ci.org/aermicioi/aedi-property-reader)
[![Code cov](https://img.shields.io/codecov/c/github/aermicioi/aedi-property-reader.svg)]()
[![Dub version](https://img.shields.io/dub/v/aedi-property-reader.svg)](https://code.dlang.org/packages/aedi-property-reader)
[![Dub downloads](https://img.shields.io/dub/dt/aedi-property-reader.svg)](https://code.dlang.org/packages/aedi-property-reader)

Aedi property reader is a config reader, with ability to read from
xml, json, environment, and command line.

It allows to define a set of default parameters, and extend or override them
from environment, command line or any other configuration file.

## Features

- Simple - Get started fast.
- Powerful - For multi-deployment configurations.
- Flexible - Supports multiple config formats and sources.
- Predictable - Well tested foundation for library and app developers.

## Installation

Add Aedi property reader as a dependency to a dub project:

Json configuration:

```json
"aedi-property-reader": "~master"
```

SDL configuration:

```sdl
dependency "aedi-property-reader" version="~>0.3.0"
```

## Quickstart

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

## Documentation

All public api documentation is available on [aermicioi.github.io/aedi-property-reader/](https://aermicioi.github.io/aedi-property-reader/).

For a more comprehensive understanding of how framework should be used, a set of tutorials are available on
github [wiki](https://github.com/aermicioi/aedi-property-reader/wiki).