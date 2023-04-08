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
 * Module to hold middleware related structs
 * 
 * License:   $(HTTP https://www.gnu.org/licenses/agpl-3.0.html, AGPL 3.0).
 * Copyright: Copyright (C) 2023 Mai-Lapyst
 * Authors:   $(HTTP codeark.it/Mai-Lapyst, Mai-Lapyst)
 */

module miniweb.middlewares;

import miniweb.http.request;
import miniweb.http.response;
import miniweb.routing : MaybeResponse;

/**
 * UDA to apply to a function to register it as a middleware handler
 */
struct RegisterMiddleware {
    string name;
}

/**
 * UDA to apply to a route handler to specify which middleware to apply
 */
struct Middleware {
    this(MaybeResponse delegate(Request) dg) {
        this._kind = Kind.DG;
        this.dg = dg;
    }
    this(MaybeResponse function(Request) fn) {
        this._kind = Kind.FN;
        this.fn = fn;
    }
    this(string name) {
        this._kind = Kind.NAMED;
        this._name = name;
    }

    string toString() const {
        final switch (_kind) {
            case Kind.NO: return "<invalid Middleware>";
            case Kind.NAMED: return "<Named Middleware '" ~ _name ~ "'>";
            case Kind.DG: return "<Delegate Middleware>";
            case Kind.FN: return "<Function Middleware>";
        }
    }

    enum Kind { NO, NAMED, DG, FN }

    /// Get the kind of middleware
    @property Kind kind() {
        return _kind;
    }

    /**
     * Get the name of a named middleware
     * 
     * Returns: the name of the middleware to apply, if this is a named middleware
     * 
     * Throws: Exception if trying to get the name of an non-named middleware
     */
    @property string name() {
        if (_kind != Kind.NAMED) {
            throw new Exception("Cannot get name from non-named Middleware");
        }
        return _name;
    }

    /**
     * Runs functional and delegate based middlewares.
     * 
     * Params:
     *   req = the request
     * 
     * Returns: a MaybeResponse from the functional / delegate middleware
     * 
     * Throws: Exception if trying to all a named middleware
     */
    MaybeResponse opCall(Request req) {
        final switch (_kind) {
            case Kind.NO:
            case Kind.NAMED:
                throw new Exception("Cannot call non-function or non-delegate Middleware");
            case Kind.FN:
                return fn(req);
            case Kind.DG:
                return dg(req);
        }
    }

private:
    Kind _kind = Kind.NO;
    union {
        string _name;
        MaybeResponse delegate(Request) dg;
        MaybeResponse function(Request) fn;
    }
}