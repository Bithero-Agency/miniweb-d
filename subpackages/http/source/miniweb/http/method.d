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
 * Module to hold code for the http method
 * 
 * License:   $(HTTP https://www.gnu.org/licenses/agpl-3.0.html, AGPL 3.0).
 * Copyright: Copyright (C) 2023 Mai-Lapyst
 * Authors:   $(HTTP codeark.it/Mai-Lapyst, Mai-Lapyst)
 */

module miniweb.http.method;

/** 
 * The http method a request can have
 */
enum HttpMethod {
	/// custom method
	custom,

	HEAD,
	GET,
	POST,
	PUT,
	PATCH,
	DELETE,
	OPTIONS,
	TRACE,
}

private static HttpMethod[string] str_to_method;
static this() {
	str_to_method = [
		"HEAD": HttpMethod.HEAD,
		"GET": HttpMethod.GET,
		"POST": HttpMethod.POST,
		"PUT": HttpMethod.PUT,
		"PATCH": HttpMethod.PATCH,
		"DELETE": HttpMethod.DELETE,
		"OPTIONS": HttpMethod.OPTIONS,
		"TRACE": HttpMethod.TRACE,
	];
}

/**
 * Parses a http method from a string.
 * 
 * Params:
 *   str = the string to check
 * 
 * Returns: the http method or $(REF HttpMethod.custom) if the version string is not known.
 */
HttpMethod httpMethodFromString(string str) {
	import std.string : toUpper;
	auto p = toUpper(str) in str_to_method;
	if (p !is null) return *p;
	return HttpMethod.custom;
}

/**
 * Stringifies a http method.
 * 
 * Params:
 *   ver = the http method to stringify
 * 
 * Returns: the string representation or `null` if the method is $(REF HttpMethod.custom).
 */
string httpMethodToString(HttpMethod method) {
	final switch (method) {
		case HttpMethod.custom: return null;
		case HttpMethod.HEAD: return "HEAD";
		case HttpMethod.GET: return "GET";
		case HttpMethod.POST: return "POST";
		case HttpMethod.PUT: return "PUT";
		case HttpMethod.PATCH: return "PATCH";
		case HttpMethod.DELETE: return "DELETE";
		case HttpMethod.OPTIONS: return "OPTIONS";
		case HttpMethod.TRACE: return "TRACE";
	}
}
