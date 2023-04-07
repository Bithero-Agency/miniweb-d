# Miniweb

A minimal yet complete webframework.

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

@Route("/returnSomething")
Response returnSomething(HeaderBag headers) {
    auto resp = Response.build_200_OK();
    resp.headers.set("X-My-Header", headers.get("X-My-Header"));
    return resp;
}
```
Miniweb has the ability to analyse annotated functions and call them with any order of parameters, as long as minweb supports the type.

Currently supported are:
- `Request` get the raw request
- `HeaderBag` get the headers of the request

## Roadmap

- Middlewares
- More bodytypes to move data
- Allowing more returntypes, i.e. auto-serializing
- Allowing detection of more request parameters
- Routes with placeholders / regex
- Full http/1.1 support
- http/2 support
- ssl/tls support
- ...
