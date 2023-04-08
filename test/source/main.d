module test;

import miniweb;

import std.stdio;

mixin MiniWebMain!test;

@OnServerStart
void my_server_conf(ServerConfig conf) {
    writeln("Called on server start!");
    conf.setCustomServerInfo("My Fancy Server");
}

@OnServerShutdown
void my_server_shutdown() {
    writeln("Called on server shutdown!");
}

@Route("/doThing")
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