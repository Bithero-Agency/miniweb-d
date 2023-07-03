/*
 * Copyright (C) 2023 Mai-Lapyst
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/** 
 * Module to hold utility code
 * 
 * License:   $(HTTP https://www.gnu.org/licenses/agpl-3.0.html, AGPL 3.0).
 * Copyright: Copyright (C) 2023 Mai-Lapyst
 * Authors:   $(HTTP codeark.it/Mai-Lapyst, Mai-Lapyst)
 */

module miniweb.utils;

/** 
 * Accquires informations about parameters.
 * 
 * Returns an $(REF std.meta.AliasSeq) containing typeinfo, identifier and storageclass of an parameter.
 * 
 * Example:
 * ---
 * class SomeClass {}
 * void foo(const int i, ref SomeClass z, int f = 23);
 * 
 * alias info = GetParameterInfo!foo;
 * import std.traits : ParameterStorageClass;
 * static assert(info[0] == ParameterStorageClass.none);
 * static assert(is(info[1] == const int));
 * static assert(info[2] == "i");
 * static assert(is(info[3] == void));
 * 
 * static assert(info[4] == ParameterStorageClass.ref_);
 * static assert(is(info[5] == SomeClass));
 * static assert(info[6] == "z");
 * static assert(is(info[7] == void));
 * 
 * static assert(info[8] == ParameterStorageClass.none);
 * static assert(is(info[9] == int));
 * static assert(info[10] == "f");
 * static assert(info[11] == 23);
 * ---
 * 
 * Params:
 *   T = the function to get infos from
 */
template GetParameterInfo(alias T) {
    import std.meta : AliasSeq;
    import std.traits : ParameterStorageClassTuple, Parameters, ParameterIdentifierTuple, ParameterDefaultValueTuple;

    alias storageclasses = ParameterStorageClassTuple!T;
    alias types = Parameters!T;
    alias identifiers = ParameterIdentifierTuple!T;
    alias defaultValues = ParameterDefaultValueTuple!T;

    template GetSC(size_t i) { alias GetSC = storageclasses[i]; }
    template GetType(size_t i) { alias GetType = types[i]; }
    template GetIdentifier(size_t i) { alias GetIdentifier = identifiers[i]; }
    template GetDefault(size_t i) { alias GetDefault = defaultValues[i]; }

    template Impl(size_t i = 0) {
        static if (i == types.length) {
            alias Impl = AliasSeq!();
        } else {
            alias Impl = AliasSeq!(
                GetSC!i, GetType!i, GetIdentifier!i, GetDefault!i,
                Impl!(i+1)
            );
        }
    }

    alias GetParameterInfo = Impl!();
}

unittest {
    class SomeClass {}
    void foo(const int i, ref SomeClass z, int f = 23);

    alias info = GetParameterInfo!foo;
    import std.traits : ParameterStorageClass;
    static assert(info[0] == ParameterStorageClass.none);
    static assert(is(info[1] == const int));
    static assert(info[2] == "i");
    static assert(is(info[3] == void));

    static assert(info[4] == ParameterStorageClass.ref_);
    static assert(is(info[5] == SomeClass));
    static assert(info[6] == "z");
    static assert(is(info[7] == void));

    static assert(info[8] == ParameterStorageClass.none);
    static assert(is(info[9] == int));
    static assert(info[10] == "f");
    static assert(info[11] == 23);
}

private template isDesiredUDA(alias attribute) {
    template isDesiredUDA(alias toCheck) {
        static if (is(typeof(attribute)) && !__traits(isTemplate, attribute)) {
            static if (__traits(compiles, toCheck == attribute)) {
                enum isDesiredUDA = toCheck == attribute;
            }
            else {
                enum isDesiredUDA = false;
            }
        }
        else static if (is(typeof(toCheck))) {
            static if (__traits(isTemplate, attribute)) {
                enum isDesiredUDA =  isInstanceOf!(attribute, typeof(toCheck));
            }
            else {
                enum isDesiredUDA = is(typeof(toCheck) == attribute);
            }
        }
        else static if (__traits(isTemplate, attribute)) {
            enum isDesiredUDA = isInstanceOf!(attribute, toCheck);
        }
        else {
            enum isDesiredUDA = is(toCheck == attribute);
        }
    }
}

/**
 * Filters the supplied list of attributes for one certain attribute.
 * 
 * Params:
 *   attribute = the attribute to filter for
 *   attribute_list = the list of attributes to filter
 * 
 * See_Also: $(REF std.traits.getUDAs) when wanting to filter directly from a symbol
 */
template filterUDAs(alias attribute, attribute_list...) {
    import std.meta : Filter;
    alias filterUDAs = Filter!(isDesiredUDA!attribute, attribute_list);
}

/**
 * Checks if the supplied list of attributes contains one specific attribute.
 * 
 * Params:
 *   attribute = the attribute to search for
 *   attribute_list = the list of attributes to search
 * 
 * See_Also: $(REF std.traits.hasUDAs) when wanting to check a symbol directly
 */
enum containsUDA(alias attribute, attribute_list...) = filterUDAs!(attribute, attribute_list).length != 0;

/**
 * Extracts the base mimetype from any given mime type.
 * 
 * This means that for example `application/vnd.custom+json` gets turned into `application/json`.
 * 
 * Params:
 *   inp = the input mimetype to get the base mimetype of
 * 
 * Returns: the base mimetype extracted
 */
string extractBaseMime(string inp) {
    import std.string;

    string res = "";

    auto d1 = split(inp, "/");
    res ~= d1[0];
    res ~= '/';

    auto d2 = split(d1[1], "+");
    res ~= d2[$-1];

    return res;
}

unittest {
    assert (extractBaseMime("application/vnd.custom+json") == "application/json");
}

/**
 * Compile-time helper to generate code to import any time via the "imported!" mecanism.
 * 
 * Params:
 *   T = the type to generate code for
 */
template BuildImportCodeForType(alias T) {
    import std.traits;

    enum FullType = fullyQualifiedName!T;
    enum Mod = moduleName!T;
    auto delMod(Range)(Range inp, Range mod) {
        import std.traits : isDynamicArray;
        import std.range.primitives : ElementEncodingType;
        static import std.ascii;
        static import std.uni;

        size_t i = 0;
        for (const size_t end = mod.length; i < end; ++i) {
            if (inp[i] != mod[i]) {
                break;
            }
        }
        inp = inp[i .. $];
        return inp;
    }
    enum Name = delMod(FullType, Mod);

    enum BuildImportCodeForType = "imported!\"" ~ Mod ~ "\"" ~ Name;
}

unittest {
    import miniweb.serialization : Mapper;
    static assert (BuildImportCodeForType!Mapper == "imported!\"miniweb.serialization\".Mapper");
}
