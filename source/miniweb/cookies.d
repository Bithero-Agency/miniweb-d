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
 * Module to provide handling with HTTP cookie data
 * 
 * License:   $(HTTP https://www.gnu.org/licenses/agpl-3.0.html, AGPL 3.0).
 * Copyright: Copyright (C) 2023 Mai-Lapyst
 * Authors:   $(HTTP codeark.it/Mai-Lapyst, Mai-Lapyst)
 */

module miniweb.cookies;

import miniweb.http;
import miniweb.routing;

/// Requires the `Cookies` HTTP header to be present.
enum RequireCookies = RequireHeader("Cookies");

/**
 * Gets the `Cookies` header to parse it yourself.
 * If you only want to work with cookies, use $(LREF CookieBag) instead.
 */
enum Cookies = Header("Cookies");

/**
 * Storage container for cookies
 */
class CookieBag {
    private string[string] data;

    /// Parses cookies from a HTTP request directly.
    this(Request req) {
        foreach(header; req.headers.get("Cookies")) {
            parseFrom(header);
        }
    }

    /// Parses cookies from a single `Cookie` header value
    this(string header_value) {
        parseFrom(header_value);
    }

    /// Parses cookies form multiple `Cookie` header values
    this(string[] header_values) {
        foreach(header; header_values) {
            parseFrom(header);
        }
    }

    private void parseFrom(string header) {
        import std.string : split, indexOf;
        auto cookies = header.split("; ");
        foreach (entry; cookies) {
            auto i = entry.indexOf('=');
            auto key = entry[0 .. i];
            if (key.length < 1) {
                continue;
            }
            data[key] = entry[i+1 .. $];
        }
    }

    /**
     * Gets a cookie
     * 
     * Params:
     *   name = the name of the cookie
     * 
     * Returns: the cookies value
     */
    string get(string name) {
        return data[name];
    }

    /// Creates a CookieBag instance from a request
    static CookieBag fromRequest(Request req) {
        return new CookieBag(req);
    }
}