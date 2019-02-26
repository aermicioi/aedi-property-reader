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
module aermicioi.aedi_property_reader.core.config;

import aermicioi.aedi.configurer.annotation.annotation;
import aermicioi.aedi_property_reader.convertor.chaining_convertor;
import aermicioi.aedi_property_reader.convertor.convertor;
import std.typecons : Yes, No;

@component
auto force() {
    return Yes.force;
}

@component
auto conversion() {
    return Yes.conversion;
}

@component
auto skip() {
    return Yes.skip;
}

@component
@qualifier!Convertor
auto defaultConvertor(PricingStrategy strategy) {
    import aermicioi.aedi_property_reader.convertor.chaining_convertor;
    return new ChainingConvertor(strategy);
}

@component
@qualifier!PricingStrategy
auto pricingStrategy(
	DefaultPricingStrategy first,
	NumericPricingStrategy second,
	IdenticalTypePriceStrategy third,
	ByTypePricingStrategy fourth
) {
	return new MinimalBidPricingStrategy(
		first,
		second,
		third,
		fourth
	);
}

@component
auto defaultPricingStrategy(@qualifier("pricing_strategy.default.price") size_t price = 1000) {
	return new DefaultPricingStrategy(price);
}

@component
auto numericPricingStrategy() {
	return new NumericPricingStrategy();
}

@component
auto identicalTypePriceStrategy() {
	return new IdenticalTypePriceStrategy();
}

@component
auto byTypePricingStrategy() {
	return new ByTypePricingStrategy();
}

@component
auto stringGuesser() {
    import aermicioi.aedi_property_reader.convertor.type_guesser : StdConvTypeGuesser;
    import aermicioi.aedi_property_reader.convertor.convertor : DefaultConvertibleTypes;
    return new StdConvTypeGuesser!(string, DefaultConvertibleTypes);
}

@component
auto stringMapInspector() {
	import aermicioi.aedi_property_reader.convertor.inspector : AssociativeArrayInspector;
	return new AssociativeArrayInspector!string;
}

// import std.traits;
// import aermicioi.aedi_property_reader.convertor.inspector : Inspector;

// debug pragma(msg, ReturnType!stringMapInspector, is(ReturnType!stringMapInspector : Inspector!(string[string], string)));
// static if (is(ReturnType!stringMapInspector : Inspector!(C, W), C, W)) {
// 	debug pragma(msg, C, " key ", W);
// }

@component
auto stringMapSetter() {
	import aermicioi.aedi_property_reader.convertor.setter : AssociativeArraySetter;
	return new AssociativeArraySetter!string;
}