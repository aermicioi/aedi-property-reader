module aermicioi.aedi_property_reader.properd.accessor;

import properd;
import aermicioi.aedi_property_reader.core.accessor;
import aermicioi.aedi.exception.not_found_exception : NotFoundException;
import std.exception;

alias ProperdPropertyAccessor = AssociativeArrayAccessor!(string, string);