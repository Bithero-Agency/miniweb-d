module test;

import miniweb;
import miniweb.serialization;

import std.stdio;
import std.json;

import miniweb.serialize_d;
mixin(mkJsonMapper!());

mixin MiniWebMain!(test);

@RegisterMiddleware("a")
MaybeResponse myfun() {
    writeln("Applying myfun middleware...");
    return MaybeResponse.none();
}

@OnServerStart
void my_server_conf(ServerConfig conf) {
    writeln("Called on server start!");
    conf.setCustomServerInfo("My Fancy Server");
}

@OnServerShutdown
void my_server_shutdown() {
    writeln("Called on server shutdown!");
}

@Route("/doOther")
void doOther() {}

@Route("/doThing")
@Middleware("a")
@Middleware((r) { writeln("Applying functional middleware..."); return MaybeResponse.none(); })
Response doThing(Request r, HeaderBag h, URI uri) {
    writeln("Got request on doThing!");
    writeln(" req: ", r);
    writeln(" headers: ", h);
    writeln(" uri: ", uri.encode());
    auto resp = Response.build_200_OK();
    resp.headers.set("Bla", "blup");
    resp.setBody("Hello world :D");
    return resp;
}

@Route("/doSome")
void doSome1(HttpMethod method) {
    writeln("called doSome1: ", method);
}

@GET @Route("/doSome")
void doSome2() {
    writeln("called doSome2");
}

@GET @Route("/user/:username/?")
void getUserByName(@PathParam string username) {
    writeln("called getUserByName: username = ", username);
}

class CustomValue {
    private int num;

    this(int num) {
        this.num = num;
    }

    Response toResponse(Request req) {
        import std.conv : to;
        auto resp = Response.build_200_OK();
        resp.setBody(
            "host is: " ~ req.headers.getOne("host") ~ "\n"
            ~ "num is: " ~ to!string(this.num) ~ "\n"
        );
        return resp;
    }
}
@GET @Route("/customValue/:val")
CustomValue getCustomValue(@PathParam string val) {
    import std.conv : to;
    return new CustomValue( to!int(val) );
}

@GET @Route("/testJson")
JSONValue testJson() {
    JSONValue test;
    test["s"] = "Hello world";
    test["n"] = 42;
    test["a"] = [11, 22, 33];
    return test;
}

class MyValue {
    int i = 42;
}

@GET @Route("/testJson2")
@Produces("application/json")
MyValue testJson2(@Header string accept) {
    writeln("Accept: ", parseHeaderQualityList(accept));
    return new MyValue();
}

@Post @Route("/testJson3")
@Consumes("application/json")
void testJson3(MyValue val) {
    writeln("Handle testJson3; i=", val.i);
}