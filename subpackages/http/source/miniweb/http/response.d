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
 * Module to hold code for a http response
 * 
 * License:   $(HTTP https://www.gnu.org/licenses/agpl-3.0.html, AGPL 3.0).
 * Copyright: Copyright (C) 2023 Mai-Lapyst
 * Authors:   $(HTTP codeark.it/Mai-Lapyst, Mai-Lapyst)
 */

module miniweb.http.response;

import miniweb.http.httpversion;
import miniweb.http.client;
import miniweb.http.headers;
import miniweb.http.body;

/** 
 * The http code a response can have
 */
enum HttpResponseCode {
	custom = 0,

	// 1xx
	Continue_100 = 100,
	Switching_Protocols_101 = 101,
	Processing_102 = 102,
	Early_Hints_103 = 103,

	// 2xx
	OK_200 = 200,
	Created_201 = 201,
	Accepted_202 = 202,
	Non_Authoritative_Information_203 = 203,
	No_Content_204 = 204,
	Reset_Content_205 = 205,
	Partial_Content_206 = 206,
	Multi_Status_207 = 207,
	Already_Reported_208 = 208,
	IM_Used_226 = 226,

	// 3xx
	Multiple_Choices_300 = 300,
	Moved_Permanently_301 = 301,
	Found_302 = 302,
	See_Other_303 = 303,
	Not_Modified_304 = 304,
	Use_Proxy_305 = 305,
	Switch_Proxy_306 = 306,
	Temporary_Redirect_307 = 307,
	Permanent_Redirect_308 = 308,

	// 4xx
	Bad_Request_400 = 400,
	Unauthorized_401 = 401,
	Payment_Required_402 = 402,
	Forbidden_403 = 403,
	Not_Found_404 = 404,
	Method_Not_Allowed_405 = 405,
	Not_Acceptable_406 = 406,
	Proxy_Authentication_Required_407 = 407,
	Request_Timeout_408 = 408,
	Conflict_409 = 409,
	Gone_410 = 410,
	Length_Required_411 = 411,
	Precondition_Failed_412 = 412,
	Payload_Too_Large_413 = 413,
	URI_Too_Long_414 = 414,
	Unsupported_Media_Type_415 = 415,
	Range_Not_Satisfiable_416 = 416,
	Expectation_Failed_417 = 417,
	Im_a_teapot_418 = 418,
	Misdirected_Request_421 = 421,
	Unprocessable_Entity_422 = 422,
	Locked_423 = 423,
	Failed_Dependency_424 = 424,
	Too_Early_425 = 425,
	Upgrade_Required_426 = 426,
	Precondition_Required_428 = 428,
	Too_Many_Requests_429 = 429,
	Request_Header_Fields_Too_Large_431 = 431,
	Unavailable_For_Legal_Reasons_451 = 451,

	// 5xx
	Internal_Server_Error_500 = 500,
	Not_Implemented_501 = 501,
	Bad_Gateway_502 = 502,
	Service_Unavailable_503 = 503,
	Gateway_Timeout_504 = 504,
	HTTP_Version_Not_Supported_505 = 505,
	Variant_Also_Negotiates_506 = 506,
	Insufficient_Storage_507 = 507,
	Loop_Detected_508 = 508,
	Not_Extended_510 = 510,
	Network_Authentication_Required_511 = 511,
}

/// Template to generate code containing cases of `HttpResponseCode` to be used in `httpResponseCodeToString`
private template GenerateResponseCodeStrings(members...) {
	static if (members.length == 0) {
		enum GenerateResponseCodeStrings = "";
	}
	else {
		alias tail = GenerateResponseCodeStrings!(members[1 .. $]);
		alias member = members[0];

		enum Name = __traits(identifier, member);
		static if (Name == "custom") {
			enum Value = "null";
		} else {
			enum Code = Name[$-3 .. $];
			static if (Code == "203") {
				enum Str = "Non-Authoritative Information";
			} else static if (Code == "207") {
				enum Str = "Multi-Status";
			} else static if (Code == "418") {
				enum Str = "I'm a teapot";
			} else {
				import std.string : replace;
				enum Str = replace(Name[0 .. $-4], "_", " ");
			}
			enum Value = "\"" ~ Code ~ " " ~ Str ~ "\"";
		}

		enum GenerateResponseCodeStrings =
			"case HttpResponseCode." ~ Name ~ ": return " ~ Value ~ ";\n"
				~ tail;
	}
}

unittest {
	import std.traits : EnumMembers, fullyQualifiedName;
	static foreach (m; EnumMembers!HttpResponseCode) {
		import std.stdio;
		writeln(
			"- ",
			httpResponseCodeToString(
				mixin("HttpResponseCode." ~ __traits(identifier, m))
			)
		);
	}
}

/**
 * Stringifies a http response code.
 * 
 * Params:
 *   ver = the http response code to stringify
 * 
 * Returns: the string representation or `null` if the method is $(REF HttpResponseCode.custom).
 * 
 * See_Also: $(REF miniweb.http.Response.respCode)
 */
string httpResponseCodeToString(HttpResponseCode code) {
	import std.traits : EnumMembers;
	enum __code = GenerateResponseCodeStrings!(EnumMembers!HttpResponseCode);
	final switch (code) {
		mixin(__code);
	}
}

/** 
 * Representing a HTTP response message
 */
class Response {
	/// The http response code; if this is $(REF HttpResponseCode.custom), then use $(REF rawCode) instead.
	private HttpResponseCode code;

	/// The raw http response code; only valid if $(REF rawCode) is $(REF HttpResponseCode.custom).
	private string rawCode;

	/// The headers for the response
	private HeaderBag _headers;

	/// The body for the response
	private ResponseBody _respBody = null;

	private this() {
		this._headers = new HeaderBag();
	}

	/**
	 * Gets the http response code of the response.
	 * 
	 * Returns: the stringified reponse code or $(REF rawCode) if the response code it $(REF HttpResponseCode.custom).
	 */
	@property string respCode() {
		if (code == HttpResponseCode.custom) {
			return rawCode;
		} else {
			return httpResponseCodeToString(code);
		}
	}

	/// Gets the headers of the response
	@property HeaderBag headers() {
		return this._headers;
	}

	/// Gets the body of the response
	@property ResponseBody responseBody() {
		return _respBody;
	}

	/**
	 * Sets the body of the response.
	 * 
	 * Params:
	 *   respBody = the body to set
	 * 
	 * Throws: Exception if the body is already set on the response.
	 */
	@property void responseBody(ResponseBody respBody) {
		if (_respBody !is null) {
			throw new Exception("Cannot overwrite an already set body of an Response");
		}
		_respBody = respBody;
	}

	/**
	 * Builds a Response with the `200 OK` response code.
	 * 
	 * Returns: a new response, preconfigured with the `200 OK` response code.
	 */
	static Response build_200_OK() {
		Response resp = new Response();
		resp.code = HttpResponseCode.OK_200;
		return resp;
	}
}

/**
 * Sends a response to a client.
 * 
 * Params:
 *   ver = the http version to use
 *   resp = the response to send
 *   client = the client to send to
 */
void sendResponse(HttpVersion ver, Response resp, HttpClient client) {
	client.writeLine(
		httpVersionToString(ver) ~ " " ~ resp.respCode
	);
	if (resp._headers !is null) {
		resp._headers.foreachHeader((key, values) {
			foreach (val; values) {
				client.writeLine(key ~ ": " ~ val);
			}
		});
	}
	client.writeLine("");
	if (resp._respBody !is null) {
		resp._respBody.sendTo(client);
	}
}
