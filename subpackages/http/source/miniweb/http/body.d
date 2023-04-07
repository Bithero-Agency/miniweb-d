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
 * Module to hold all http body types
 * 
 * License:   $(HTTP https://www.gnu.org/licenses/agpl-3.0.html, AGPL 3.0).
 * Copyright: Copyright (C) 2023 Mai-Lapyst
 * Authors:   $(HTTP codeark.it/Mai-Lapyst, Mai-Lapyst)
 */

module miniweb.http.body;

import miniweb.http.headers;
import miniweb.http.client;

/** 
 * Interface for http response bodies
 */
interface ResponseBody {

	/**
	 * Allows bodies to modify response headers.
	 * 
	 * Params:
	 *  headers = headers to modify
	 *  client = current client
	 */
	void modifyHeaders(HeaderBag headers, HttpClient client);

	/**
	 * Called when the body should be send to the client.
	 * This is an blocking operation.
	 * 
	 * Params:
	 *  client = current client
	 */
	void sendTo(HttpClient client);

}
