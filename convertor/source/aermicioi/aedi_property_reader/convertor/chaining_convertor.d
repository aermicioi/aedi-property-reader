module aermicioi.aedi_property_reader.convertor.chaining_convertor;

import std.algorithm;
import std.experimental.allocator;
import std.experimental.logger;
import std.conv;
import std.array;
import std.range : drop;
import std.range.primitives : isInputRange, ElementType;
import std.typecons : No;
import aermicioi.aedi_property_reader.convertor.convertor;
import aermicioi.aedi_property_reader.convertor.exception;
import aermicioi.aedi_property_reader.convertor.placeholder;
import aermicioi.aedi_property_reader.convertor.traits : n;

@safe interface PricingStrategy {

    size_t rate(const TypeInfo from, const TypeInfo to) const nothrow;
}

private bool passable(size_t score) @safe nothrow {
    return score !is size_t.max;
}

@safe class NumericPricingStrategy : PricingStrategy {

    private const TypeInfo[] identifications = [typeid(ulong), typeid(uint), typeid(ushort), typeid(ubyte), typeid(long), typeid(int), typeid(short), typeid(byte), typeid(real), typeid(double), typeid(float)];
    private const size_t[][] prices = [
        [0, 1, 2, 3, 1, 2, 3, 4, 5, 6, 7], // typeid(ulong),
        [0, 0, 1, 2, 0, 1, 2, 3, 5, 6, 7], // typeid(uint),
        [0, 0, 0, 1, 0, 0, 1, 2, 5, 6, 7], // typeid(ushort),
        [0, 0, 0, 0, 0, 0, 0, 1, 5, 6, 7], // typeid(ubyte),
        [1, 2, 3, 4, 0, 1, 2, 3, 5, 6, 7], // typeid(long),
        [1, 1, 2, 3, 0, 0, 1, 2, 5, 6, 7], // typeid(int),
        [1, 1, 1, 2, 0, 0, 0, 1, 5, 6, 7], // typeid(short),
        [1, 1, 1, 1, 0, 0, 0, 0, 5, 6, 7], // typeid(byte),
        [5, 6, 7, 8, 4, 5, 6, 7, 0, 1, 2], // typeid(real),
        [5, 6, 7, 8, 4, 5, 6, 7, 0, 0, 1], // typeid(double),
        [5, 6, 7, 8, 4, 5, 6, 7, 0, 0, 0], // typeid(float)
    ];

    size_t rate(const TypeInfo from, const TypeInfo to) const nothrow {
        import std.math;
        import std.algorithm : canFind;

        if (!identifications.canFind!(tested => tested is from) || !identifications.canFind!(tested => tested is to)) {
            return size_t.max;
        }

        size_t fromIndex = identifications.countUntil!(tested => tested is from);
        size_t toIndex = identifications.countUntil!(tested => tested is to);

        return prices[fromIndex][toIndex];
    }
}

@safe class DefaultPricingStrategy : PricingStrategy {
    private size_t price = 1000;

    this() {

    }

    this(size_t price) {
        this.price = price;
    }

    size_t rate(const TypeInfo from, const TypeInfo to) const nothrow {
        return price;
    }
}

@safe class MinimalBidPricingStrategy : PricingStrategy {

    private const(PricingStrategy)[] strategies;

    this(PricingStrategy[] strategies...)
        in (!strategies.empty, "Cannot select minimal bidding strategy when none provided.") {
        this.strategies = strategies.dup;
    }

    typeof(this) add(const PricingStrategy strategy) nothrow {
        import std.algorithm : canFind;
        if (!this.strategies.canFind!(candidate => candidate is strategy)) {

            this.strategies ~= strategy;
        }

        return this;
    }

    typeof(this) remove(const PricingStrategy strategy) @trusted nothrow {
        import std.algorithm : filter;
        this.strategies = this.strategies.filter!(candidate => candidate !is strategy).array;

        return this;
    }

    size_t rate(const TypeInfo from, const TypeInfo to) const nothrow {
        return strategies.map!(strategy => strategy.rate(from, to)).minElement(size_t.max);
    }
}

@safe class IdenticalTypePriceStrategy : PricingStrategy {

    private size_t price;

    this(size_t price = 0) {
        this.price = price;
    }

    size_t rate(const TypeInfo from, const TypeInfo to) const nothrow {
        if (from is to) {
            return price;
        }

        return size_t.max;
    }
}

@safe class OffsettingPriceStrategy : PricingStrategy {

    private size_t offset;
    private const PricingStrategy strategy;

    this(const PricingStrategy strategy, size_t price = 1)
        in (strategy !is null, "Cannot offset a price when decorated pricing is missing.") {
        this.offset = price;
        this.strategy = strategy;
    }

    size_t rate(const TypeInfo from, const TypeInfo to) const nothrow {
        size_t result = strategy.rate(from, to);

        if (result.passable) {
            result += this.offset;
        }

        return result;
    }
}

@safe class OverridablePricingStrategy : PricingStrategy {
    private {
        const PricingStrategy strategy;

        @safe static struct Relation {
            const TypeInfo from;
            const TypeInfo to;
            size_t price;

            ptrdiff_t opEquals(in ref Relation relation) const nothrow {
                return (this.from is relation.from) && (this.to is relation.to);
            }

            ref typeof(this) opAssign(in ref Relation relation) nothrow
                in (this == relation, "Cannot assign to a relation with different identity") {
                this.price = relation.price;

                return this;
            }
        }

        Relation[] relations;
    }

    this(const PricingStrategy strategy) nothrow
        in (strategy !is null, "Cannot override a price when no underlying strategy is provided") {
        this.strategy = strategy;

    }

    typeof(this) modify(const TypeInfo from, const TypeInfo to, size_t price) nothrow {
        auto fresh = Relation(from, to, price);

        foreach (ref relation; relations) {

            if (relation == fresh) {
                relation = fresh;
                return this;
            }
        }

        relations ~= fresh;

        return this;
    }

    typeof(this) modify(const TypeInfo from, const TypeInfo to) nothrow {
        this.modify(from, to, size_t.max);

        return this;
    }

    typeof(this) clear() {
        this.relations = null;

        return this;
    }

    size_t rate(const TypeInfo from, const TypeInfo to) const nothrow {
        auto modified = this.relations[].filter!(relation => (relation.from is from) && (relation.to is to));

        if (!modified.empty) {
            return modified.front.price;
        }

        return this.strategy.rate(from, to);
    }
}

class ByTypePricingStrategy : PricingStrategy {
    struct Entry {
        const TypeInfo type;
        size_t price;
    }

    private const(Entry)[] entries;
    private const(size_t delegate(size_t from, size_t to) @safe scope nothrow) adjuster;

    this() {
        import std.functional : toDelegate;
        this((size_t from, size_t to) scope nothrow => cast(size_t) ((from + to) / 2));
    }

    this(size_t delegate(size_t from, size_t to) @safe scope nothrow adjuster) {
        this.adjuster = adjuster;
    }

    /**
    Set entry

    Params:
        entries = an overriding entry;

    Returns:
        typeof(this)
    **/
    typeof(this) add(Entry[] entries...) @safe nothrow pure {
        foreach (entry; entries) {
            if (!this.entries.canFind!(candidate => candidate.type is entry.type)) {
                this.entries ~= entry;
            }
        }

        return this;
    }

    /**
    ditto
    **/
    typeof(this) add(const TypeInfo type, size_t price) @safe nothrow pure {
        return this.add(Entry(type, price));
    }

    size_t rate(const TypeInfo from, const TypeInfo to) const nothrow {
        auto fromCandidate = this.entries.filter!(entry => entry.type is from);
        auto toCandidate = this.entries.filter!(entry => entry.type is to);


        if (fromCandidate.empty || toCandidate.empty) {
            return size_t.max;
        }

        return adjuster(fromCandidate.front.price, toCandidate.front.price);
    }
}

/**
A convertor tries to build a chain of convertors from source to destination.
**/
class ChainingConvertor : CombinedConvertorImpl {
    import std.algorithm : canFind, find;

    private {
        @safe struct Node {
            import std.typecons : Rebindable;
            size_t price = size_t.max;
            bool visited;
            Rebindable!(const(TypeInfo)) type;
            Rebindable!(const(TypeInfo)) next;

            this(const(TypeInfo) type, size_t price, bool visited, const(TypeInfo) next = null) @trusted {
                this(type);
                this.price = price;
                this.visited = visited;
                this.next = next;
            }

            this(const(TypeInfo) type) @trusted
                in (type !is null, "Cannot create node for a null type") {
                this.type = type;
            }

            bool opEquals(in ref Node node) const {
                return this.type.get is node.type.get;
            }

            size_t toHash() const nothrow {
                try {

                    return this.type.toHash;
                } catch (Exception e) {

                    assert(false, "Something completely wrong went during hashing");
                }
            }
        }

        @safe static struct Path {
            import std.typecons : Rebindable;
            private Node[const TypeInfo] graph;
            private Rebindable!(const TypeInfo) current;
            private Rebindable!(const TypeInfo) next;

            this(Node[const TypeInfo] graph, const TypeInfo from) nothrow {
                this.graph = graph;
                this.current = this.graph[from].type;
                this.next = this.graph[from].next;
            }

            const(TypeInfo) front() inout nothrow {
                return current;
            }

            bool empty() nothrow const {
                return current.get is null;
            }

            void popFront() nothrow {
                current = next;

                if (next !is null) {
                    next = graph[next].next;
                }
            }

            Path save() nothrow {
                return Path(graph, current);
            }
        }

        Convertor[] convertors_;
        PricingStrategy appraiser;
    }

    public {

        /**
        Default constructor for AggregateConvertor
        **/
        this(PricingStrategy appraiser, Convertor[] convertors...) {
            this.convertors = convertors.dup;
            this.appraiser = appraiser;
        }

        /**
        Check whether convertor is able to convert from type to type.

        Check whether convertor is able to convert from type to type.
        This set of methods should be the most precise way of determining
        whether convertor is able to convert from type to type, since it
        provides both components to the decision logic implemented by convertor
        compared to the case with $(D_INLINECODE convertsTo) and $(D_INLINECODE convertsFrom).
        Note that those methods are still useful when categorization or other
        logic should be applied per original or destination type.

        Implementation:
            This is default implementation of converts methods which delegate
            the decision to $(D_INLINECODE convertsTo) and $(D_INLINECODE convertsFrom).

        Params:
            from = the original component or it's type to convert from
            to = the destination component or it's type to convert to

        Returns:
            true if it is able to convert from component to destination component
        **/
        override bool converts(const TypeInfo from, const TypeInfo to) @safe const nothrow {
            debug(trace) trace("Checking if ", from, " is convertable to ", to).n;
            return !this.convertors.filter!(convertor => convertor.converts(from, to)).empty || !this.search(from, to).empty;
        }

        /**
        ditto
        **/
        override bool converts(const TypeInfo from, in Object to) @safe const nothrow {
            debug(trace) trace("Checking if ", from, " is convertable to ", to.identify).n;
            return !this.convertors.filter!(convertor => convertor.converts(from, to)).empty || !this.search(from, to.identify).empty;
        }

        /**
        ditto
        **/
        override bool converts(in Object from, const TypeInfo to) @safe const nothrow {
            debug(trace) trace("Checking if ", from.identify, " is convertable to ", to).n;
            return !this.convertors.filter!(convertor => convertor.converts(from, to)).empty || !this.search(from, to).empty;
        }

        /**
        ditto
        **/
        override bool converts(in Object from, in Object to) @safe const nothrow {
            debug(trace) trace("Checking if ", from.identify, " is convertable to ", to.identify).n;
            return !this.convertors.filter!(convertor => convertor.converts(from, to)).empty || !this.search(from, to.identify).empty;
        }

        /**
        Convert from component to component.

        Finds a right convertor from component to component and uses it
        to execute conversion from component to component.

        Params:
            from = typeal component that is to be converted.
            to = destination object that will be constructed out for typeal one.
            allocator = optional allocator that could be used to construct to component.
        Throws:
            ConvertorException when convertor is not able to convert from, or to component.
        Returns:
            Resulting converted component.
        **/
        override Object convert(in Object from, const TypeInfo to, RCIAllocator allocator = theAllocator)  const
        {
            static union Context {
                const Object constant;
                Object mutable;
            }

            import std.range : slide, take, drop;

            if (super.converts(from, to)) {
                return super.convert(from, to, allocator);
            }

            Path path = this.search(from, to);

            if (path.empty) {
                throw new ConvertorException(text("Could not find a way to convert from ", from.identify, " to ", to, " type"));
            }

            debug(trace) trace("Found best conversion path commencing conversion ", path, ".");
            Context value = Context(from);

            foreach (conversion; path.slide(2).take(2)) {
                value.mutable = this.convertors.filter!(c => c.converts(conversion.front, conversion.drop(1).front)).front
                    .convert(value.mutable, conversion.drop(1).front, allocator);
            }

            path = path.drop(1);

            foreach (conversion; path.slide!(No.withPartial)(3)) {
                Object temporary = this.convertors.filter!(c => c.converts(conversion.drop(1).front, conversion.drop(2).front)).front
                    .convert(value.mutable, conversion.drop(2).front, allocator);
                this.convertors.filter!(c => c.destroys(conversion.front, conversion.drop(1).front)).front
                    .destruct(conversion.front, value.mutable, allocator);

                value.mutable = temporary;
            }

            return value.mutable;
        }

        mixin ToStringMixin!();
        mixin OpCmpMixin!();

        override size_t toHash() @trusted {
            import std.range : only;
            size_t result = super.toHash();

            foreach (convertor; convertors) {
                Object hashable = cast(Object) convertor;

                size_t hash = (hashable !is null) ? hashable.toHash() : typeid(convertor).getHash(cast(void*) convertor);

                result = result * 31 + hash;
            }

            return result;
        }

        override bool opEquals(Object o) {
            return super.opEquals(o) || ((this.classinfo is o.classinfo) && this.opEquals(cast(ChainingConvertor) o));
        }

        bool opEquals(ChainingConvertor convertor) {
            import std.algorithm : equal;
            return (convertor !is null) && (this.convertors.equal(convertor.convertors));
        }
    }

    private Path search(T)(T from, const TypeInfo to) @safe const nothrow
        if (is(T : const Object) || is(T : const TypeInfo)) {
        import std.range : slide, take, generate, chain;
        import aermicioi.aedi_property_reader.convertor.traits : n;

        debug(trace) trace("Searching for a way to convert ", from.identify, " to ", to).n;

        OverridablePricingStrategy appraiser = new OverridablePricingStrategy(this.appraiser);

        foreach (path; this.range(from.identify, to, appraiser)) {

            debug(trace) trace("Found a way to convert ", from.identify, " to ", to, " using a chain of ", path, " convertors.").n;

            bool found = false;
            auto step = path.take(2);
            if (!this.convertors.filter!(c => c.converts(from, step.drop(1).front)).empty) {
                auto remainder = path.drop(1).slide(2).find!(
                    (conversion) => this.convertors.filter!(c => c.converts(conversion.front, conversion.drop(1).front)).empty
                );

                found = remainder.empty;
                if (!remainder.empty) {
                    step = remainder.front;
                }
            }

            if (found) {

                return path;
            }

            debug(trace) trace("Found chain of convertors broke at ", step, " marking it to avoid in next chain.").n;
            appraiser.modify(step.front, step.drop(1).front);
        }

        debug(trace) trace("Could not find a way to convert ", from.identify, " to ", to).n;
        return Path.init;
    }

    private Path pave(const TypeInfo from, const TypeInfo to, PricingStrategy appraiser) @safe const nothrow {
        import std.algorithm;
        import std.range;

        try {

            Node[const TypeInfo] nodes;
            foreach (type; this.convertors.map!((c) @safe => chain(c.to, c.from)).joiner.filter!((type) @safe => type !is typeid(void))) {
                nodes[type] = Node(type, size_t.max, false);
            }

            Node current = Node(to, 0, true);
            nodes[to] = current;
            Node[] unvisited;

            do {
                debug(ChainingConvertorTraceGraph) trace("Processing neighbors of ", current.type).n;

                auto candidates = this.convertors.filter!(c => c.convertsTo(current.type));

                foreach (convertor; candidates) {
                    foreach (fromType; convertor.from) {
                        size_t score = appraiser.rate(fromType, current.type);

                        debug(ChainingConvertorTraceGraph) trace("Checking convertion price to ", current.type, " from ", fromType, " of ", score).n;
                        if (score.passable && ((current.price + score) < nodes[fromType].price)) {

                            debug(ChainingConvertorTraceGraph) trace(score, " less than one of ", nodes[fromType].price, " setting new one.").n;
                            nodes[fromType].price = current.price + score;
                            nodes[fromType].next = current.type;
                        }
                    }
                }

                unvisited = unvisited
                    .filter!(candidate => !nodes[candidate.type].visited)
                    .chain(candidates.map!(convertor => convertor.from).joiner.map!(from => nodes[from]).filter!(node => !node.visited))
                    .array;
                unvisited.sort!((f, s) => f.price < s.price);

                nodes[current.type] = current;

                if (!unvisited.empty) {
                    debug(ChainingConvertorTraceGraph) trace("Selecting new unvisited node of ", unvisited.front.type).n;
                    current = unvisited.front;
                    current.visited = true;

                    unvisited.popFront;
                }
            } while (!unvisited.empty && (current.type !is from));

            if (current.type !is from) {
                return Path.init;
            }

            return Path(nodes, current.type);
        } catch (Exception e) {

            throw new Error("Encountered unexpected exception during paving", e);
        }
    }

    auto range(const TypeInfo from, const TypeInfo to, PricingStrategy appraiser) const nothrow @safe {
        import std.range : generate, chain, only;
        import std.algorithm : until;
        auto searcher = generate!(() => this.pave(from, to, appraiser)).until!(path => path.empty || path.drop(1).empty);

        return searcher;
    }
}

/**
A convertor that will run a chain of conversions.
**/
class ChainedConvertor : Convertor {
    import std.algorithm : canFind, find;

    private {
        Convertor[] convertors;
    }

    public {

        /**
        Default constructor for AggregateConvertor
        **/
        this(Convertor[] convertors...)
            in (convertors.length > 0, "Chained convertor expects at least one convertor in chain to operate properly.")
            in (ChainedConvertor.valid(convertors), "Chained convertor expects a unbroken chain of convertors, one provided is broken at some point.") {
            this.convertors = convertors.dup;
        }

        @property {

            /**
            Get the type info of component that convertor can convert from.

            Get the type info of component that convertor can convert from.
            The method is returning the default type that it is able to convert,
            though it is not necessarily limited to this type only. More generalistic
            checks should be done by convertsFrom method.

            Returns:
                type info of component that convertor is able to convert.
            **/
            const(TypeInfo)[] from() @safe const nothrow pure {
                return this.convertors[0].from;
            }

            /**
            Get the type info of component that convertor is able to convert to.

            Get the type info of component that convertor is able to convert to.
            The method is returning the default type that is able to convert,
            though it is not necessarily limited to this type only. More generalistic
            checks should be done by convertsTo method.

            Returns:
                type info of component that can be converted to.
            **/
            const(TypeInfo)[] to() @safe const nothrow pure {
                return this.convertors[$ - 1].to;
            }
        }

        mixin ConvertsFromToMixin DefaultImplementation;

        /**
        Check whether this convertor is able to destroy to component.

        The destroys family of methods are designed purposely for identification
        whether convertor was able to convert from type to destination to, and
        is eligible for destruction of converted components.

        Params:
            from = original component which was converted.
            to = converted component that should be destroyed by convertor.

        Returns:
            true if convertor is eligible for destroying to, or false otherwise.
        **/
        bool destroys(const TypeInfo from, const TypeInfo to) @safe const nothrow {
            return this.convertors.back.converts(from, to);
        }

        /**
        ditto
        **/
        bool destroys(in Object from, const TypeInfo to) @safe const nothrow {
            return this.convertors.back.converts(from, to);
        }

        /**
        ditto
        **/
        bool destroys(const TypeInfo from, in Object to) @safe const nothrow {
            return this.convertors.back.converts(from, to);
        }

        /**
        ditto
        **/
        bool destroys(in Object from, in Object to) @safe const nothrow {
            return this.convertors.back.converts(from, to);
        }

        /**
        Convert from component to component.

        Finds a right convertor from component to component and uses it
        to execute conversion from component to component.

        Params:
            from = typeal component that is to be converted.
            to = destination object that will be constructed out for typeal one.
            allocator = optional allocator that could be used to construct to component.
        Throws:
            ConvertorException when convertor is not able to convert from, or to component.
        Returns:
            Resulting converted component.
        **/
        override Object convert(in Object from, const TypeInfo to, RCIAllocator allocator = theAllocator)  const
        {
            import std.math;

            union Context {
                const Object constant;
                Object mutable;
            }

            Context value = Context(from);

            foreach (convertor; convertors[0 .. $.min(2)]) {
                value.mutable = convertor.convert(value.mutable, convertor.to[0], allocator);
            }

            if (convertors.length > 2)
            foreach (index, convertor; convertors[2 .. $]) {
                Object temporary = convertor.convert(value.mutable, convertor.to[0], allocator);
                convertors[index - 1].destruct(convertors[index - 1].from[0], value.mutable, allocator);

                value.mutable = temporary;
            }

            return value.mutable;
        }

        /**
        Destroy component created using this convertor.

        Find a suitable convertor for destruction and use it to execute destruction.

        Params:
            converted = component that should be destroyed.
            allocator = allocator used to allocate converted component.
        **/
        void destruct(const TypeInfo from, ref Object converted, RCIAllocator allocator = theAllocator) const {
            import std.exception : enforce;
            enforce!ConvertorException(this.destroys(from, converted), text(
                "Cannot destroy ", converted.identify, " which was not converted from ", from, ".",
                " Expected destroyable type of ", this.to, " from origin of ", this.from
            ));

            this.convertors.back.destruct(from, converted, allocator);
        }

        mixin ToStringMixin!();
        mixin OpCmpMixin!();

        override size_t toHash() @trusted {
            import std.range : only;
            size_t result = super.toHash();

            foreach (convertor; convertors) {
                Object hashable = cast(Object) convertor;

                size_t hash = (hashable !is null) ? hashable.toHash() : typeid(convertor).getHash(cast(void*) convertor);

                result = result * 31 + hash;
            }

            return result;
        }

        override bool opEquals(Object o) {
            return super.opEquals(o) || ((this.classinfo is o.classinfo) && this.opEquals(cast(ChainedConvertor) o));
        }

        bool opEquals(ChainedConvertor convertor) {
            import std.algorithm : equal;
            return (convertor !is null) && (this.convertors.equal(convertor.convertors));
        }
    }

    private static valid(Convertor[] convertors) {
        import std.range : slide;
        import std.algorithm : any;

        if (convertors.length == 1) {
            return true;
        }

        foreach (window; convertors.slide(2)) {
            if (!window[0].to.any!(to => window[1].from.any!(from => from is to))) {
                return false;
            }
        }

        return true;
    }
}