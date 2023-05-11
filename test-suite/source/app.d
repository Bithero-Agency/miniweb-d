module app;

import miniweb;
import miniweb.cookies;

import std.stdio;
import std.socket;

mixin MiniWebMain!app;

@OnServerStart
void configureServer(ServerConfig conf) {
    conf.addr = new InternetAddress("localhost", 5000);
    //conf.addr = new Internet6Address("::1", 5000);
}

string g_catform_data = null;

// TODO: support formdata parsing nativly
// application/x-www-form-urlencoded

/*
@Route("/cat-form/data")
Response catFormData() {
    if (g_catform_data is null) {
        return new Response(HttpResponseCode.Not_Found_404);
    } else {
        auto r = Response.build_200_OK();
        r.setBody(g_catform_data);
        return r;
    }
}

@POST @Route("/cat-form")
Response catForm(Request req) {
    const(char)[] data = cast(const(char)[]) req.reqBody.getBuffer();
    g_catform_data = data.idup();
    auto r = new Response(HttpResponseCode.Created_201);
    r.headers.set("Location", "/cat-form/data");
    return r;
}
*/

// --------------------------------------------------------------------------------

@GET @Route("/cookie")
Response cookie(@QueryParam("type") string t = "vanilla")
{
    auto r = Response.build_200_OK();
    r.setBody("Eat");
    r.headers.set("Set-Cookie", "type=" ~ t ~ "");
    return r;
}

@GET @Route("/eat_cookie")
@RequireCookies
Response eat_cookie(CookieBag cookies) {
    import std.string : split;
    auto r = Response.build_200_OK();
    auto type = cookies.get("type");
    r.setBody("mmmm " ~ type);
    return r;
}

// --------------------------------------------------------------------------------

@GET @Route("/coffee")
Response coffee() {
    auto r = new Response(HttpResponseCode.Im_a_teapot_418);
    r.setBody("I'm a teapot");
    return r;
}

@GET @Route("/tea")
Response tea() {
    auto r = new Response(HttpResponseCode.OK_200);
    return r;
}
