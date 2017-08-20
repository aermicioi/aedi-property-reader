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
module aermicioi.aedi_property_reader.json.json_container;

import aermicioi.aedi;
import aermicioi.aedi_property_reader.json.json_factory;
import aermicioi.aedi_property_reader.generic_convertor_container;
import aermicioi.aedi.storage.locator;
import std.json;
import std.range;
import std.typecons;

/**
Json document data source/locator used by converting containers.
**/
class JsonLocator : Locator!(JSONValue, string) {
    
    private {
        JSONValue json_;
    }
    
    public {
		/**
		Default constructor for JsonLocator

		Initializes container with an empty json object
		**/
		this() {
			JSONValue[string] obj;
			this.json = JSONValue(obj);
		}
        
        @property {
			/**
			Set json
			
			Params: 
				json = json document used as source
			
			Returns:
				typeof(this)
			**/
        	JsonLocator json(JSONValue json) @safe nothrow
        	in {
        	    assert(json.type == JSON_TYPE.OBJECT, "Json value for locator should be of object type");
        	}
        	body {
        		this.json_ = json;
        	
        		return this;
        	}
        	
			/**
			Get json
			
			Returns:
				JSONValue
			**/
        	JSONValue json() @safe nothrow {
        		return this.json_;
        	}
        }
        
        /**
		Get a json element that is accessable from root element.
		
		Params:
			path = the element id.
			
		Throws:
			NotFoundException in case if the element wasn't found.
		
		Returns:
			JSONValue child json element if it is available.
		**/
        JSONValue get(string path) {
            foreach (key, json; this.json.object) {
                if (key == path) {
                    return json;
                }
            }
            
            throw new NotFoundException("Could not find child json node identified by " ~ path ~ " in root json");
        }
        
        /**
        Check if a json element is present in json by key.
        
        Params:
        	path = identity of element.
        	
    	Returns:
    		bool true if an element by key is present in Locator.
        **/
        bool has(in string path) inout {
            foreach (key, json; this.json_.object) {
                if (key == path) {
                    return true;
                }
            }
            
            return false;
        }
    }
}

/**
Generic convertor container version for json documents.
**/
alias JsonConvertorContainer = GenericConvertorContainer!(JSONValue, JsonConvertorFactory);