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
module aermicioi.aedi_property_reader.env.env_container;

import aermicioi.aedi;
import aermicioi.aedi_property_reader.env.env_factory;
import aermicioi.aedi_property_reader.generic_convertor_container;
import std.process;
import std.range;
import std.typecons;

/**
Environment variables data source/locator used by converting containers.
**/
class EnvironmentLocator : Locator!(string, string) {
    
    public {
        
        /**
		Get an environment variable from environment.
		
		Params:
			path = the element id.
			
		Throws:
			NotFoundException in case if the element wasn't found.
		
		Returns:
			string element if it is available.
		**/
        string get(string path) {
            auto env = environment.get(path);
            
            if (env is null) {
                throw new NotFoundException("Could not find environment variable identified by " ~ path);
            }
            
            return env;
        }
        
        /**
        Check if environment variable is set.
        
        Params:
        	path = identity of element.
        	
    	Returns:
    		bool true if an element by key is present in Locator.
        **/
        bool has(in string path) inout {
            return environment.get(path) !is null;
        }
    }
}

/**
Generic convertor container version for environment variables.
**/
alias EnvironmentConvertorContainer = GenericConvertorContainer!(string, StringConvertorFactory);