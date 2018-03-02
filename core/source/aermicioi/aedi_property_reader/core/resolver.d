module aermicioi.aedi_property_reader.core.resolver;

import aermicioi.aedi_property_reader.core.convertor_factory;
import aermicioi.aedi_property_reader.core.convertor_container;
import std.traits;

auto resolve(ResolvedType, SerializedType, KeyType)(
    Locator!(SerializedType, KeyType) locator,
    KeyType identity,
    ConvertorFactory!(SerializedType, ResolvedType) convertor
) {
    scope(exit) convertor.convertible = SerializedType.init;

    convertor.convertible = locator.get(identity);

    return convertor.factory();
}

auto resolve(ResolvedType, SerializedType, KeyType)(
    Locator!(SerializedType, KeyType) locator,
    ConvertorFactory!(SerializedType, ResolvedType) convertor
) {
    return locator.resolve(fullyQualifiedName!T, convertor);
}

auto resolve(ResolvedType, SerializedType, KeyType)(
    Locator!(SerializedType, KeyType) locator,
    KeyType identity,
    Locator!(ConvertorFactory!(SerializedType, Object), TypeInfo) converters
) {

    return locator.resolve(identity, converters.get(identity));
}

auto resolve(ResolvedType, SerializedType, KeyType)(
    Locator!(SerializedType, KeyType) locator,
    Locator!(ConvertorFactory!(SerializedType, Object), TypeInfo) converters
) {

    return locator.resolve(fullyQualifiedName!ResolvedType, converters);
}

auto resolve(ResolvedType, LocatorType : Locator!(SerializedType, KeyType), SerializedType, KeyType)(
    LocatorType locator,
    KeyType identity,
) if (is(LocatorType : Locator!(ConvertorFactory!(SerializedType, Object), TypeInfo))) {

    return locator.resolve(identity, cast(Locator!(ConvertorFactory!(SerializedType, Object), TypeInfo)) locator);
}

auto resolve(ResolvedType, LocatorType : Locator!(SerializedType, KeyType), SerializedType, KeyType)(
    LocatorType locator
) if (is(LocatorType : Locator!(ConvertorFactory!(SerializedType, Object), TypeInfo))) {

    return locator.resolve(fullyQualifiedName!ResolvedType, cast(Locator!(ConvertorFactory!(SerializedType, Object), TypeInfo)) locator);
}