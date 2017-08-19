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
module aermicioi.aedi_property_reader.convertor_container;

import aermicioi.aedi;
import aermicioi.aedi_property_reader.convertor_factory;

/**
An interface for containers that are storing convertor factories.

An interface for containers that are storing convertor factories and are
able to use a source of FromType data to provision contained factories with
required FromType data to build components out of it.

Params:
	FromType = original form of data based on which components are constructed.
	KeyType = identity's type of converter factory.
**/
interface ConvertorContainer(FromType, KeyType = string) : 
	Container, 
	Storage!(ConvertorFactory!(FromType, Object), KeyType) {
    
    public {
        @property {

			/**
			Get locator of FromType data
			
			Returns:
				Locator!(FromType, string)
			**/
        	Locator!(FromType, string) locator() @safe nothrow;

			/**
			Set locator
			
			Params: 
				locator = locator that provides container with FromType data for convertor factories
			
			Returns:
				ConvertorContainer!FromType
			**/
        	ConvertorContainer!FromType locator(Locator!(FromType, string) locator) @safe nothrow;
        }
    }
}