module miniweb.serialization;

import miniweb.client;
import miniweb.http.response;

import std.meta : AliasSeq;

struct Mapper {
    string[] types;
}

// interface MapperImpl(T) {
//     T deserialize(void[] buffer);
//     string serialize(auto ref T value);
// }

private template checkMapper(alias clazz) {
    import std.traits;
    static assert (
        __traits(compiles, __traits(getMember, clazz, "deserialize")),
        "Mapper `" ~ fullyQualifiedName!clazz ~ "` needs to have a static method called `deserialize`!"
    );
    static assert (
        __traits(compiles, __traits(getMember, clazz, "serialize")),
        "Mapper `" ~ fullyQualifiedName!clazz ~ "` needs to have a static method called `serialize`!"
    );
}

private template isAliasSeq(Args...) {
    static if (Args.length != 1)
        enum isAliasSeq = true;
    else
        enum isAliasSeq = false;
}

private template getMappers(alias symbol, names...) {
    import std.traits;
    import std.meta : Alias, AliasSeq, Filter;
    static if (names.length == 0) {
        alias getMappers = AliasSeq!();
    } else {
        alias tail = getMappers!(symbol, names[1 .. $]);
        static if (!__traits(compiles, __traits(getMember, symbol, names[0]))) {
            alias getMappers = tail;
        } else {
            alias member = __traits(getMember, symbol, names[0]);
            static if (isAliasSeq!member ||
                    (isType!member && !isAggregateType!member && !is(member == enum)))
            {
                alias getMappers = tail;
            }
            else static if (__traits(getOverloads, symbol, names[0], true).length > 0)
            {
                enum hasSpecificUDA(alias member) = hasUDA!(member, Mapper);
                alias overloadsWithUDA = Filter!(hasSpecificUDA, __traits(getOverloads, symbol, names[0], true));
                alias getMappers = AliasSeq!(overloadsWithUDA, tail);
            }
            else static if (hasUDA!(member, Mapper))
            {
                alias getMappers = AliasSeq!(member, tail);
            }
            else
            {
                alias getMappers = tail;
            }
        }
    }
}

void checkMappers(Modules...)() {
    import std.traits;
    struct MyVal {}

    static foreach (mod; Modules) {
        static foreach (clazz; getSymbolsByUDA!(mod, Mapper)) {
            pragma(msg, "Found mapper: `", fullyQualifiedName!clazz, "`");
            mixin checkMapper!(clazz);
        }
    }
}

T requestbody_deserialize(T, Modules...)(MiniwebRequest req) {
    import miniweb.utils : extractBaseMime;

    string base_mime = extractBaseMime(req.consumes);

    template apply_mapper_deserialize(alias clazz) {
        import std.traits;

        alias udas = getUDAs!(clazz, Mapper);
        static assert (udas.length == 1, "Can only have one instance of @Mapper applied to `" ~ fullyQualifiedName!clazz ~ "`");

        enum types = udas[0].types;

        import miniweb.utils : BuildImportCodeForType;
        enum apply_mapper_deserialize =
            "if (" ~ types.stringof ~ ".canFind(base_mime)) {" ~
                "debug (miniweb_debug_mappers) {" ~
                    "import std.stdio;" ~ 
                    "writeln(\"[requestbody_deserialize] use `" ~ fullyQualifiedName!clazz ~ "` for mime '\" ~ base_mime ~ \"'\");" ~
                "}" ~
                "return " ~ BuildImportCodeForType!clazz ~ ".deserialize!(" ~ BuildImportCodeForType!T ~ ")(req.http.reqBody.getBuffer());" ~
            "}"
        ;
    }

    import std.traits;
    import std.algorithm : canFind;
    static foreach (mod; Modules) {
        static foreach (clazz; getSymbolsByUDA!(mod, Mapper)) {
            mixin( apply_mapper_deserialize!clazz );
        }
    }

    assert (0, "Could not find any mapper to apply for mimetype '" ~ base_mime ~ "'");
}

Response serialize_responsevalue(T, Modules...)(string accepted_product, auto ref T value) {
    import miniweb.utils : extractBaseMime;

    string base_mime = extractBaseMime(accepted_product);

    template apply_mapper_serialize(alias clazz) {
        import std.traits;

        alias udas = getUDAs!(clazz, Mapper);
        static assert (udas.length == 1, "Can only have one instance of @Mapper applied to `" ~ fullyQualifiedName!clazz ~ "`");

        enum types = udas[0].types;

        import miniweb.utils : BuildImportCodeForType;
        enum apply_mapper_serialize =
            "if (" ~ types.stringof ~ ".canFind(base_mime)) {" ~
                "debug (miniweb_debug_mappers) {" ~
                    "import std.stdio;" ~ 
                    "writeln(\"[serialize_responsevalue] use `" ~ fullyQualifiedName!clazz ~ "` for mime '\" ~ base_mime ~ \"'\");" ~
                "}" ~
                "auto str = " ~ BuildImportCodeForType!clazz ~ ".serialize!(" ~ BuildImportCodeForType!T ~ ")(value);" ~
                "auto resp = new Response(HttpResponseCode.OK_200);" ~
                "resp.setBody(str, accepted_product);" ~
                "return resp;" ~
            "}"
        ;
    }

    import std.traits;
    import std.algorithm : canFind;
    import miniweb.http.response;

    static foreach (mod; Modules) {
        static foreach (clazz; getSymbolsByUDA!(mod, Mapper)) {
            mixin( apply_mapper_serialize!clazz );
        }
    }

    assert (0, "Could not find any mapper to apply for mimetype '" ~ base_mime ~ "'");
}