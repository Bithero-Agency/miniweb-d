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
 * Module to hold code for a http request
 * 
 * License:   $(HTTP https://www.gnu.org/licenses/agpl-3.0.html, AGPL 3.0).
 * Copyright: Copyright (C) 2023 Mai-Lapyst
 * Authors:   $(HTTP codeark.it/Mai-Lapyst, Mai-Lapyst)
 */

module miniweb.http.request;

import miniweb.http.headers;
import miniweb.http.client;
import miniweb.http.method;
import miniweb.http.httpversion;
import miniweb.http.uri;

/** 
 * Representing a HTTP request message
 */
class Request {
	/// The http client the request was parsed from
	private HttpClient client;

	/// The raw HTTP method; only valid if $(REF method) is $(REF miniweb.http.method.HttpMethod.custom)
	private string _raw_method;

	/// The HTTP method; if this is $(REF miniweb.http.method.HttpMethod.custom), the real method is in $(REF raw_method)
	private HttpMethod _method;

	/// The request uri
	private URI _uri;
	
	/// The http version of the request
	private HttpVersion ver;

	/// Storage for parsed headers
	private HeaderBag _headers;

	/// The request's body (if one is available)
	private RequestBody _body = null;

	this(HttpClient client) {
		this.client = client;
		this._headers = new HeaderBag();
	}

	/// Returns the HTTP version of the request
	@property HttpVersion httpVersion() {
		return this.ver;
	}

	/// Returns the URL of the request
	URI getURI() {
		return _uri;
	}

	/// Returns the URL of the request
	@property URI uri() {
		return _uri;
	}

	/// Gets the raw method of the request
	string getRawMethod() {
		return _raw_method;
	}

	@property string rawMethod() {
		return _raw_method;
	}

	/// Gets the method of the request; if this returns $(REF miniweb.http.method.HttpMethod.custom) use $(REF getRawMethod) instead
	HttpMethod getMethod() {
		return _method;
	}

	/// Gets the method of the request; if this returns $(REF miniweb.http.method.HttpMethod.custom) use $(REF getRawMethod) instead
	@property HttpMethod method() {
		return _method;
	}

	/// Gets the headers
	@property HeaderBag headers() {
		return this._headers;
	}

	/// Gets the request's body
	@property RequestBody reqBody() {
		return _body;
	}
}

/**
 * Represents the body of an request
 */
class RequestBody {
	private void[] buffer;

	private this() {}

	void[] getBuffer() {
		return buffer;
	}
}

/**
 * Exception type for HTTP parsing exceptions
 */
class RequestParsingException : Exception {
	this(string msg) {
		super(msg);
	}
}

/**
 * Parses a request from the supplied client
 * 
 * Params:
 *   client = the current client
 * 
 * Returns: the parsed http request
 * 
 * Throws: RequestParsingException if the parsing failed
 */
Request parseRequest(HttpClient client) {
	import std.array : split;

	Request r = new Request(client);

	// parse the request line
	auto requestLine = client.readLine().split(" ");
	if (requestLine.length != 3) {
		throw new RequestParsingException("requestline has wrong format");
	}

	debug (miniweb_parseRequest) {
		import std.stdio;
		writeln("[miniweb.http.parseRequest] requestLine: ", requestLine);
	}

	r._method = httpMethodFromString(requestLine[0]);
	r._raw_method = requestLine[0];

	r._uri = new URI(requestLine[1]);

	r.ver = httpVersionFromString(requestLine[2]);

	// start header parsing
	while (true) {
		auto line = client.readLine();
		debug (miniweb_parseRequest) {
			import std.stdio;
			writeln("[miniweb.http.parseRequest] got headerline: ", line);
		}

		if (line.length < 1) { break; }

		string key = "";
		string value = "";
		bool splitHeader() {
			foreach(i, ch; line) {
				if (ch == ':') {
					auto j = i + 1;
					if (j >= line.length) {
						return false;
					}
					if (line[j] == ' ') {
						key ~= line[0 .. i];
						value ~= line[i+2 .. $];
					}
				}
			}
			return false;
		}

		if (splitHeader()) {
			throw new RequestParsingException("header line has wrong format");
		}

		debug (miniweb_parseRequest) {
			import std.stdio;
			writeln("[miniweb.http.parseRequest] got header: key=", key, "|value=", value);
		}

		import std.string : toLower;
		r._headers.append(key.toLower(), value);
	}

	// TODO: this needs to be made more secure...
	if (r._headers.has("Content-Length")) {
		import std.conv : to;
		size_t contentLength = to!size_t( r._headers.getOne("Content-Length") );
		r._body = new RequestBody();
		r._body.buffer = client.read(contentLength);
	}

	return r;
}
