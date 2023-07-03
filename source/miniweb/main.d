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
 * Module to hold code to reduce boilerplate code
 * 
 * License:   $(HTTP https://www.gnu.org/licenses/agpl-3.0.html, AGPL 3.0).
 * Copyright: Copyright (C) 2023 Mai-Lapyst
 * Authors:   $(HTTP codeark.it/Mai-Lapyst, Mai-Lapyst)
 */

module miniweb.main;

/** 
 * Used to reduce boilerplate in miniweb projects; defines an async main and calls miniweb's startup.
 * 
 * Supply it with all modules where miniweb should search for route handlers.
 * 
 * Example:
 * ---
 * module test;
 * import miniweb.main;
 * mixin MiniWebMain!(test);
 * ---
 * 
 * See_Also: $(REF async.main.AsyncMain)
 */
template MiniWebMain(Modules...) {
	mixin MiniWebAsyncMain!Modules;

	import async;
	import async.main;
	mixin AsyncMain;
}

/** 
 * Used to reduce boilerplate in miniweb projects;
 * Wrapper around $(REF async.main.AsyncLoop); also defines miniweb's startup.
 * 
 * Supply it with all modules where miniweb should search for route handlers.
 * 
 * Example:
 * ---
 * module test;
 * import miniweb.main;
 * mixin MiniWebLoop!(test);
 * 
 * int main(string[] args) {
 *     return mainAsyncLoop();
 * }
 * ---
 * 
 * See_Also: $(REF async.main.AsyncLoop)
 */
template MiniWebLoop(Modules...) {
	mixin MiniWebAsyncMain!Modules;

	import async;
	import async.main;
	mixin AsyncLoop;
}

/** 
 * Used to reduce boilerplate in miniweb projects;
 * Defines a async main with miniweb's startup.
 * 
 * Supply it with all modules where miniweb should search for route handlers.
 * 
 * See_Also: $(REF async.main.AsyncLoop) and $(REF async.main.AsyncMain)
 */
template MiniWebAsyncMain(Modules...) {
	mixin MiniWebStartup!Modules;

	int async_main() {
		return miniWebStartup();
	}
}

/** 
 * Used to reduce boilerplate in miniweb projects;
 * Defines miniweb's startup.
 * 
 * Supply it with all modules where miniweb should search for route handlers.
 * 
 * Example:
 * ---
 * module test;
 * import miniweb.main;
 * mixin MiniWebStartup!test;
 * 
 * import async.main;
 * mixin AsyncMain;
 * 
 * int async_main(string[] args) {
 *     return miniWebStartup();
 * }
 * ---
 */
template MiniWebStartup(Modules...) {
	import std.meta : AliasSeq;
	import std.traits : getSymbolsByUDA, isFunction, ReturnType, Parameters;
	import miniweb.config;

	alias allMods = AliasSeq!(Modules);

	int miniWebStartup() {
		ServerConfig conf = new ServerConfig();

		foreach (mod; allMods) {
			foreach (fn; getSymbolsByUDA!(mod, OnServerStart)) {
				static assert(isFunction!fn, "`" ~ __traits(identifier, fn) ~ "` is annotated with OnServerStart but is not a function");
				static assert(is(ReturnType!fn == void), "`" ~ __traits(identifier, fn) ~ "` needs to have a return value of `void`");

				static if (is(Parameters!fn == AliasSeq!(ServerConfig))) {
					fn(conf);
				}
				else static if (is(Parameters!fn == AliasSeq!())) {
					fn();
				}
				else {
					assert(false, "`" ~ __traits(identifier, fn) ~ "` needs either have no parameters or only one of type `miniweb.config.ServerConfig`");
				}
			}
		}

		import miniweb.serialization;
		checkMappers!(allMods);

		Router router = initRouter!(allMods)(conf);

		int exitCode = miniwebRunServer(conf, router);

		foreach (mod; allMods) {
			foreach (fn; getSymbolsByUDA!(mod, OnServerShutdown)) {
				static assert(isFunction!fn, "`" ~ __traits(identifier, fn) ~ "` is annotated with OnServerShutdown but is not a function");
				static assert(is(ReturnType!fn == void), "`" ~ __traits(identifier, fn) ~ "` needs to have a return value of `void`");

				static if (is(Parameters!fn == AliasSeq!(ServerConfig))) {
					fn(conf);
				}
				else static if (is(Parameters!fn == AliasSeq!())) {
					fn();
				}
				else {
					assert(false, "`" ~ __traits(identifier, fn) ~ "` needs either have no parameters or only one of type `miniweb.config.ServerConfig`");
				}
			}
		}

		return exitCode;
	}
}
