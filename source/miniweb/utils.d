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
