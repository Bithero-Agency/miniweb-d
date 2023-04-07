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
 * Module to hold header related code
 * 
 * License:   $(HTTP https://www.gnu.org/licenses/agpl-3.0.html, AGPL 3.0).
 * Copyright: Copyright (C) 2023 Mai-Lapyst
 * Authors:   $(HTTP codeark.it/Mai-Lapyst, Mai-Lapyst)
 */

module miniweb.http.headers;

import std.string : toLower;

/**
 * Stores headers for an HTTP Message, all keys are case insensitive.
 * 
 * Note: all keys are automatically transformed into lowercase to ensure the case insensitivity.
 */
class HeaderBag {
	/// internal assocative array storing the headers
	private string[][string] map;

	/**
	 * Checks if a key is set
	 * 
	 * Params:
	 *  key = the key to check for
	 * 
	 * Returns: true if the key is set, false otherwise
	 */
	bool has(string key) {
		auto p = key.toLower() in map;
		return p !is null;
	}

	/**
	 * Get's all values for the given key
	 * 
	 * Params:
	 *   key = the key to get values for
	 *   defaultValue = a default value if the key dosnt exist
	 * 
	 * Returns: the values for the key or a array with `defaultValue` as single element if no values are present.
	 */
	string[] get(string key, string defaultValue = "") {
		auto p = key.toLower() in map;
		if (p !is null) {
			return *p;
		}
		return [defaultValue];
	}

	/**
	 * Gets exactly one value for the given key
	 * 
	 * Params:
	 *   key = the key to get values for
	 *   defaultValue = a default value if the key dosnt exist
	 * 
	 * Returns: the values for the key or `defaultValue` if no values are present.
	 */
	string getOne(string key, string defaultValue = "") {
		return get(key, defaultValue)[0];
	}

	/** 
	 * Sets the given key to the given values
	 * 
	 * Params:
	 *   key = the key to get values for
	 *   values = the values to set
	 */
	void set(string key, string[] values) {
		map[key.toLower()] = values;
	}

	/** 
	 * Sets the given key to the given value
	 * 
	 * Params:
	 *   key = the key to get values for
	 *   value = the value to set
	 */
	void set(string key, string value) {
		map[key.toLower()] = [ value ];
	}

	/** 
	 * Appends the given values to the values of the given key
	 * 
	 * Params:
	 *   key = the key to append values to
	 *   values = the values to append
	 */
	void append(string key, string[] values) {
		key = key.toLower();
		if (!has(key)) {
			map[key] = values;
		} else {
			map[key] ~= values;
		}
	}

	/** 
	 * Appends the given value to the values of the given key
	 * 
	 * Params:
	 *   key = the key to append values to
	 *   value = the value to append
	 */
	void append(string key, string value) {
		append(key, [ value ]);
	}

	/** 
	 * Unsets the given key; effectively deletes all values for the key
	 * 
	 * Params:
	 *   key = the key to unset
	 */
	void unset(string key) {
		map.remove(key.toLower());
	}

	/** 
	 * Iterates over all key`s and run the given delegate on it and the values
	 * 
	 * Params:
	 *   dg = delegate to call for each header key
	 */
	void foreachHeader(void delegate(string, string[]) dg) {
		foreach (key, value; map) {
			dg(key, value);
		}
	}

	/** 
	 * Iterates over all key`s and run the given function on it and the values
	 * 
	 * Params:
	 *   fn = function to call for each header key
	 */
	void foreachHeader(void function(string, string[]) fn) {
		foreach (key, value; map) {
			fn(key, value);
		}
	}
}
