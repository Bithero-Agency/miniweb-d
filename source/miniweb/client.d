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
 * Module to hold miniweb's http client
 * 
 * License:   $(HTTP https://www.gnu.org/licenses/agpl-3.0.html, AGPL 3.0).
 * Copyright: Copyright (C) 2023 Mai-Lapyst
 * Authors:   $(HTTP codeark.it/Mai-Lapyst, Mai-Lapyst)
 */

module miniweb.client;

import async.io.socket;
import std.variant;
import miniweb.http.client;
import miniweb.http.request;

/** 
 * Miniweb's HTTP Client
 * 
 * See_Also: $(REF miniweb.http.client.BaseHttpClient)
 */
class MiniWebHttpClient : BaseHttpClient {
	/// The underlaying socket
	private AsyncSocket sock;

	/// Creates a new client from a socket
	this(AsyncSocket sock) {
		this.sock = sock;
	}

	/// Get the underlaying socket
	AsyncSocket getSocket() {
		return this.sock;
	}

	protected override size_t nativeRead(scope void[] buffer) {
		return this.sock.recieve(buffer).await();
	}

	protected override void nativeWrite(scope const(void)[] buffer) {
		this.sock.send(buffer).await();
	}

}

class MiniwebRequest {
	private Request _http_request;

	/// Storage for path parameters
	public string[string] pathParams;

	this(Request http_request) {
		this._http_request = http_request;
	}

	@property Request http() {
		return this._http_request;
	}

	string getPathParam(string key) {
		auto p = key in this.pathParams;
		if (p !is null) {
			return *p;
		}
		throw new Exception("Tried to access un-available path parameter '" ~ key ~ "'");
	}
}
