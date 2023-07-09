# Miniweb

A minimal yet complete webframework.

Notice: miniweb will NOT recieve further updates; please switch to [ninox-d_web](https://github.com/Bithero-Agency/ninox.d-web)!

## License

The code in this repository is licensed under AGPL-3.0-or-later; for more details see the `LICENSE` file in the repository.

## Getting started

This library aims to have an small but complete webframework for dlang projects.

A simple hello world project:
```d
module test;

import miniweb;
import miniweb.main;
mixin MiniWebMain!test;

@OnServerStart
void configureServer(ServerConfig conf) {
    conf.setCustomServerInfo("My Fancy Server");
}

@Route("/doSomething")
void doSomething() {
    writeln("Does something!");
}

@GET @Route("/returnSomething")
Response returnSomething(HeaderBag headers) {
    auto resp = Response.build_200_OK();
    resp.headers.set("X-My-Header", headers.get("X-My-Header"));
    resp.setBody("Hello world!");
    return resp;
}
```
Miniweb has the ability to analyse annotated functions and call them with any order of parameters, as long as minweb supports the type.

Currently supported are:
- `Request` get the raw http request
- `MiniwebRequest` get the miniweb request
- `HeaderBag` get the headers of the request
- `URI` get the uri of the request
- `QueryParamBag` get the query params of the request
- `HttpMethod` get the requests HTTP method of the request
- `@Header` annotated `string` or `string[]` params get the specified header;
    Uses the parameter name if none is supplied
- `@QueryParam` annotated `string` or `string[]` params get the specified header;
    Uses the parameter name as queryparam name if none is supplied, same with default value
- `@PathParam` annotated `string` params get the specified path parameter;
    Uses the parameter name if none is supplied

To use middlewares you have two options, either create a named one or use functionals:
```d
@RegisterMiddleware("my_middleware")    // registers a named middleware
MaybeResponse handler(Request req) {
    return MaybeResponse.none();    // returns a Option!Response with no value set,
                                    // which effectivly means to call either the next middleware
                                    // or the handler.
}

// Middlewares can either return MaybeResponse or void and have
// the same freedom in their parameters as normal route handlers
@RegisterMiddleware("other")
void otherHandler() {}

@Route("/returnSomething")
@Middleware("my_middleware")    // applies a named middleware
Response returnSomething(HeaderBag headers) {
    // ...
}

@Route("/someWhereOther")
// This is a functional middleware, it accepts a delegate/function directly
@Middleware((req) {
    return MaybeReponse.none();
})
Response someWhereOther() {
    // ...
}
```

Usage of path parameters:
```d
// To use path parameters, just use the syntax :<a-zA-Z0-9_> inside the route matcher.
// @Route declarations also now support the `?` specified which make the character before it optional.
@GET @Route("/user/:username/?")
Response getUser(@PathParam string username) {
    // ...
}
```

Custom return types:
```d
import std.conv : to;
class CustomValue {
    private int num;
    this(int num) { this.num = num; }
    Response toResponse(Request req) {
        auto resp = Response.build_200_OK();
        resp.setBody(
            "host is: " ~ req.headers.getOne("host") ~ "\n"
            ~ "num is: " ~ to!string(this.num) ~ "\n");
        return resp;
    }
}
@GET @Route("/customValue/:val")
CustomValue getCustomValue(@PathParam string val) {
    return new CustomValue( to!int(val) );
}
```

## Serialization

Miniweb supports serialization via three annotations:
- `@Produces`: sets a list of valid content-types the endpoint can return. Also has the effect that the route is secured through a need for the client to specify the wanted mime-type via the `Accept` header. If nothing is matched a 406 can be returned to indicate that the server could not satisfy the request because of the `Accept` constraint. As a second side-effect, you also can then use **any** custom type as returntype and miniweb's serialization module ensures that the object is properly serialized (if setup that is!)

- `@Consumes`: sets a list of valid content-types the endpoint can consume. Should only be used when the endpoint can actually recieve data (unlike HEAD and GET request!). It also adds an constraint to ensure that only requests with the desired content-type are getting wired through to the handler. And last but not least it allows to use one otherwise not matched parameter to be used for the body of the request and is deserialized through miniweb's serialization module.

Now to setup serialization: either you use the subpackage `miniweb:serialize-d` (see below) or you can implement your own serialization logic. For that simply implement something similar to the following:

```d
import miniweb.serialization;

// the 'Mapper' UDA serves two purposes: allows to specify the mime-types that serializer applies to,
// as well as to actually being picked by miniweb as a serializer / mapper.
@Mapper(["application/json"])
class JsonMapperImpl {
    // the deserialize function; responsible to deserialize any buffer of data into an instance of T
    static T deserialize(T)(void[] buffer) {
        import serialize_d.json.serializer;
        auto mapper = new JsonMapper();
        return mapper.deserialize!(T)( cast(string) buffer );
    }

    // the serialize function; responsible to serialize any given value into a string
    static string serialize(T)(auto ref T value) {
        import serialize_d.json.serializer;
        auto mapper = new JsonMapper();
        return mapper.serialize!T(value);
    }
}
```
Note: both methods **need** to be static in order to work!

## Subpackages

### miniweb:serialize-d

A package vital if you want to utilize the [serialize-d](https://code.dlang.org/packages/serialize-d) package in your project to handle serialization.

To use it, simple import it and use any of the provided templates + mixin to generate the glue code:
```d
import miniweb.serialize_d;
mixin(mkJsonMapper!());

mixin MiniWebMain!(test);
```
Since miniweb searches all mappers automatically in the modules you provide to `MiniWebMain` and the `mixin(mkJsonMapper!());` exposes the glue code into your module, everything is setup to simply start using serialization!

Note: the package expects your project to depend on every single serializer you want from serialize-d; so for json support you need to add `serialize-d:json` to your dependencies!

Note: also make sure to setup all mappers via this way **before** you call miniwebs init-code (for example via `MiniWebMain`). Otherwise the glue code dosnt get properly detected and miniweb dosnt pick up on the serializers/mappers.

## Roadmap

- More bodytypes to move data
- Allowing more returntypes, i.e. auto-serializing
- Allowing detection of more request parameters
- Routes with regex
- Full http/1.1 support
- http/2 support
- ssl/tls support
- ...
