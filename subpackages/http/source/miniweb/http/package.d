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
 * Module to hold all code around http handling
 * 
 * License:   $(HTTP https://www.gnu.org/licenses/agpl-3.0.html, AGPL 3.0).
 * Copyright: Copyright (C) 2023 Mai-Lapyst
 * Authors:   $(HTTP codeark.it/Mai-Lapyst, Mai-Lapyst)
 */

module miniweb.http;

public import miniweb.http.headers;
public import miniweb.http.request;
public import miniweb.http.response;
public import miniweb.http.method;
public import miniweb.http.httpversion;
public import miniweb.http.body;
public import miniweb.http.uri;

import std.datetime.systime : SysTime;

/** 
 * Converts a $(REF std.datetime.systime.SysTime) to an string representation,
 * suitable for usage in the HTTP `Date` header.
 * 
 * Params:
 *   time = the time to format
 * 
 * Returns: a datetime string to be used in the HTTP `Date` header
 */
string toHttpTimeFormat(SysTime time) {
	time = time.toUTC();

	import std.conv : to;
	import std.string : toUpper;
	with (time) {
		string capitalize(string inp) {
			return inp[0..1].toUpper ~ inp[1..$];
		}
		string pad(ubyte i) {
			return (i < 10 ? "0" ~ to!string(i) : to!string(i));
		}
		return(
			capitalize(to!string(dayOfWeek)) ~ ", "
				~ pad(day) ~ " "
				~ capitalize(to!string(month)) ~ " "
				~ to!string(year) ~ " "
				~ pad(hour) ~ ":" ~ pad(minute) ~ ":" ~ pad(second)
				~ " GMT"
		);
	}
}
