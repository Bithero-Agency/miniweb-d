module miniweb.http.uri;

/**
 * Holds an URI; effectivly just a container/wrapper but as a distinct type so we can better work with it.
 * Utilizes $(REF std.uri) for parsing.
 */
class URI {
	private string _path;
	private QueryParamBag _queryparams;

	private this() {}

	/// Parses the given string as uri
	this(string str) {
		import std.uri;
		import std.string : indexOf, split;
		str = std.uri.decode(str);

		this._queryparams = new QueryParamBag();

		auto i = str.indexOf("?");
		if (i >= 0) {
			this._path = str[0 .. i];
			str = str[i+1 .. $];

			auto entries = str.split("&");
			foreach (e; entries) {
				auto j = e.indexOf("=");
				if (j >= 0) {
					this._queryparams.set( e[0..j], std.uri.decodeComponent(e[j+1..$]) );
				} else {
					this._queryparams.set( e, "" );
				}
			}
		} else {
			this._path = str;
		}
	}

	/// Encodes the uri back into a string
	string encode() {
		import std.uri;
		if (_queryparams.map.length <= 0) {
			return std.uri.encode(_path);
		}

		string querystr = "";
		foreach (key, values; _queryparams.map) {
			foreach (value; values) {
				querystr ~= key ~ "=" ~ std.uri.encodeComponent(value) ~ "&";
			}
		}
		return std.uri.encode(_path) ~ querystr[0 .. $-1];
	}

	/// The path of the uri
	@property string path() {
		return _path;
	}

	/// The query params of the uri
	@property QueryParamBag queryparams() {
		return _queryparams;
	}

	/// Parses the given string as uri
	static URI parse(string str) {
		return new URI(str);
	}
}

unittest {
	URI u = new URI("foo/bar?a=42&b=some%20%26str");
	assert(u._path == "foo/bar");
	assert(u._queryparams.map["a"] == ["42"]);
	assert(u._queryparams.map["b"] == ["some &str"]);
	assert(u.encode(), "foo/bar?a=42&b=some%20%26str");
}

/**
 * Stores query params for an HTTP URL, all keys are case sensitive.
 */
class QueryParamBag {
	/// internal assocative array storing the params
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
		auto p = key in map;
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
		auto p = key in map;
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
		map[key] = values;
	}

	/** 
	 * Sets the given key to the given value
	 * 
	 * Params:
	 *   key = the key to get values for
	 *   value = the value to set
	 */
	void set(string key, string value) {
		map[key] = [ value ];
	}

	/** 
	 * Appends the given values to the values of the given key
	 * 
	 * Params:
	 *   key = the key to append values to
	 *   values = the values to append
	 */
	void append(string key, string[] values) {
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
		map.remove(key);
	}
}
