module test;

import miniweb;

import std.stdio;

mixin MiniWebMain!test;

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