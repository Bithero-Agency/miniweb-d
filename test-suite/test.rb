#!ruby
require 'net/http';

################################################################################
# Framework                                                                    #
################################################################################

class Condition
    def is_ensured?(resp)
        raise "Conditions need to implement is_ensured?"
    end

    def reason(resp)
        raise "Conditions need to implement reason"
    end
end

class ResponseCodeCondition < Condition
    def initialize(code)
        @code = code;
    end

    def is_ensured?(resp)
        return resp.code.to_i === @code;
    end

    def reason(resp)
        return "expected a response code of #{@code} but was #{resp.code.to_i}"
    end
end

class ResponseBodyCondition < Condition
    def initialize(body, mode, negate = false)
        @body = body;
        @mode = mode;
        @negate = negate;
    end

    private def inner(resp)
        if @mode === :equals then
            return resp.body === @body;
        elsif @mode === :contains then
            return resp.body.include?(@body);
        else
            throw "Unknown mode for ResponseBodyCondition";
        end
    end

    def is_ensured?(resp)
        if @negate then
            return !inner(resp)
        else
            return inner(resp)
        end
    end

    def reason(resp)
        if @negate then
            if @mode === :equals then
                return "expected not a response body of #{@body.inspect} but was #{resp.body.inspect}"
            elsif @mode === :contains then
                return "expected response body to not contain #{@body.inspect} but has";
            else
                throw "Unknown mode for ResponseBodyCondition";
            end
        else
            if @mode === :equals then
                return "expected a response body of #{@body.inspect} but was #{resp.body.inspect}"
            elsif @mode === :contains then
                return "expected response body to contain #{@body.inspect} but hasn't";
            else
                throw "Unknown mode for ResponseBodyCondition";
            end
        end
    end
end

class SetCookieCondition < Condition
    def initialize(name)
        @name = name;
    end

    def is_ensured?(resp)
        set_cookies = resp.get_fields("set-cookie")
        for set_cookie in set_cookies do
            data = set_cookie.split('; ');
            if data[0].start_with?(@name + '=') then
                $globals[:cookies][@name] = data[0].split('=')[1];
                return true;
            end
        end
        return false;
    end

    def reason(resp)
        return "expected a Set-Cookie header for cookie #{@name} but found none"
    end
end

class ResponseHeaderCondition < Condition
    def initialize(name, value)
        @name = name;
        @value = value;
    end

    def is_ensured?(resp)
        headers = resp.get_fields(@name)
        if headers.nil? || headers.size != 1 then
            return false
        end
        return headers[0] === @value;
    end

    def reason(resp)
        headers = resp.get_fields(@name)
        if headers.nil? || headers.size < 1 then
            return "expected a Header with the name #{@name.inspect} to be present, but it wasnt"
        elsif headers.size > 1 then
            return "expected only one Header with the name #{@name.inspect} to be present, but found #{headers.size}"
        else
            return "expected the Header #{@name.inspect} to have the value #{@value.inspect}, but got #{headers[0].inspect}"
        end
    end
end

class TestFailedError < StandardError; end

$globals = {
    cookies: {}
}

class Test
    def initialize(path, method, body = nil)
        @path = path;
        @method = method;
        @body = body;
        @headers = {}
        @conditions = [];
        @with_cookies = false;
    end

    def ensure_set_cookie(name)
        @conditions << SetCookieCondition.new(name)
        self
    end

    def with_cookies
        @with_cookies = true
        self
    end

    def with_header(name, value)
        @headers[name] = value;
        self
    end

    def ensure_code(code)
        @conditions << ResponseCodeCondition.new(code)
        self
    end

    def ensure_body(body)
        @conditions << ResponseBodyCondition.new(body, :equals)
        self
    end

    def ensure_header(name, value)
        @conditions << ResponseHeaderCondition.new(name, value)
        self
    end

    def ensure_body_has(body)
        @conditions << ResponseBodyCondition.new(body, :contains)
        self
    end

    def reject_body_has(body)
        @conditions << ResponseBodyCondition.new(body, :contains, true)
        self
    end

    def ensure_basic_auth
        # TODO
        self
    end

    def with_credentials(user, pass)
        # TODO
        self
    end

    METHOD_MAP = {
        :head => Net::HTTP::Head,
        :get => Net::HTTP::Get,
        :post => Net::HTTP::Post,
        :post_form => Net::HTTP::Post,
        :put => Net::HTTP::Put,
        :put_form => Net::HTTP::Put,
        :delete => Net::HTTP::Delete,
    }

    def run
        name = "#{ @method.to_s.upcase } #{@path}"

        uri = URI.parse('http://localhost:5000');
        http = Net::HTTP.new(uri.host, uri.port);

        if @with_cookies then
            @headers["Cookies"] = $globals[:cookies].map {|k,v| "#{k}=#{v}"}.join('; ');
        end

        req = METHOD_MAP[@method].new(@path, @headers);

        if (@method == :post_form || @method == :put_form) then
            req.form_data = @body;
            @body = nil;
        end

        begin
            res = http.request(req, @body);
        rescue StandardError => e
            raise TestFailedError.new("Failed request: #{e.message}")
        end

        if res == nil then
            raise "Failed to recieve response object"
        end

        for cond in @conditions do
            if !cond.is_ensured?(res) then
                puts "[#{name}] failed condition: " + cond.reason(res);
                raise TestFailedError.new("Failed conditions")
            end
        end

        puts "[#{name}] request was successfull";
        return res;
    end
end

def head(path)
    return Test.new(path, :head)
end

def get(path)
    return Test.new(path, :get)
end

def post_form(path, form_data)
    return Test.new(path, :post_form, form_data)
end

def put(path, body)
    return Test.new(path, :put, form_data)
end

def put_form(path, form_data)
    return Test.new(path, :put_form, form_data)
end

def delete(path)
    return Test.new(path, :delete)
end

################################################################################
# Tests                                                                        #
################################################################################

$tests = []
def test(name, &block)
    $tests << { name: name, block: block }
end

## Dynamic Routes

test "Cat Form" do
    get("/cat-form/data")
        .ensure_code(404)
        .run

    post_form("/cat-form", {data: "fatcat"})
        .ensure_code(201)
        .ensure_header("location", "/cat-form/data")
        .run

    get("/cat-form/data")
        .ensure_code(200)
        .ensure_body("data=fatcat")
        .run

    put_form("/cat-form/data", {data: 'tabbycat'})
        .ensure_code(200)
        .run

    get("/cat-form/data")
        .ensure_code(200)
        .ensure_body("data=tabbycat")
        .run

    delete("/cat-form/data")
        .ensure_code(200)
        .run

    get("/cat-form/data")
        .ensure_code(404)
        .run
end

test "CookieData" do
    r = get("/cookie?type=choclate")
        .ensure_code(200)
        .ensure_body("Eat")
        .ensure_set_cookie("type")
        .run

    get("/eat_cookie")
        .with_cookies
        .ensure_code(200)
        .ensure_body("mmmm choclate")
        .run
end

test "FourEightTeen" do
    get("/coffee")
        .ensure_code(418)
        .ensure_body("I'm a teapot")
        .run

    get("/tea")
        .ensure_code(200)
        .run
end

test "ParameterDecode" do
    get("/parameters?variable_1=a%20query%20string%20parameter")
        .ensure_body("variable_1 = a query string parameter")
        .run

    get("/parameters?variable_1=Operators%20%3C%2C%20%3E%2C%20%3D%2C%20!%3D%3B%20%2B%2C%20-%2C%20*%2C%20%26%2C%20%40%2C%20%23%2C%20%24%2C%20%5B%2C%20%5D%3A%20%22is%20that%20all%22%3F&variable_2=stuff")
        .ensure_body(
            "variable_1 = Operators <, >, =, !=; +, -, *, &, @, #, $, [, ]: \"is that all\"?\n"
            + "variable_2 = stuff"
        )
        .run
end

test "PatchWithEtag" do
    get("/patch-content.txt")
        .ensure_code(200)
        .ensure_body("default content")
        .run

    patch("/patch-content.txt", "patched content")
        .with_header("If-Match", "dc50a0d27dda2eee9f65644cd7e4c9cf11de8bec")
        .ensure_code(204)
        .run

    get("/patch-content.txt")
        .ensure_code(200)
        .ensure_body("patched content")
        .run

    patch("/patch-content.txt")
        .with_header("If-Match", "5c36acad75b78b82be6d9cbbd6143ab7e0cc04b0")
        .run

    get("/patch-content.txt")
        .ensure_body("default content")
        .run
end

test "RedirectPath" do
    get("/redirect")
        .ensure_body(302)
        .ensure_header("Location", "/")
        .run
end

## File Server Test Suite

test "Basic Auth" do
    get("/logs")
        .ensure_code(401)
        .ensure_basic_auth
        .reject_body_has("GET /logs HTTP/1.1")
        .run

    get("/logs").run
    put("/these").run
    head("/requests").run

    get("/logs")
        .with_credentials("admin", "hunter2")
        .ensure_code(200)
        .ensure_body_has("GET /logs HTTP/1.1")
        .ensure_body_has("PUT /these HTTP/1.1")
        .ensure_body_has("HEAD /requests HTTP/1.1")
        .run

    post("/logs")
        .with_credentials("admin", "hunter2")
        .ensure_code(405)
        .reject_body_has("GET /logs HTTP/1.1")
        .run
end

test "CreateReadUpdateDelete" do
    get("/new_file.txt")
        .ensure_code(404)
        .run

    put("/new_file.txt", "Some text for a new file")
        .ensure_code(201)
        .run

    get("/new_file.txt")
        .ensure_code(200)
        .ensure_body("Some text for a new file")
        .run

    put("/new_file.txt", "Some updated text")
        .ensure_code(200)
        .run

    get("/new_file.txt")
        .ensure_code(200)
        .ensure_body("Some updated text")
        .run

    delete("/new_file.txt")
        .ensure_code(200)
        .run

    get("/new_file.txt")
        .ensure_code(404)
        .run
end

test "PublicDir" do
    # TODO: test that checks if a public dir is implemented
end

test "MediaTypes" do
    # TODO: test that checks if mimetype detection is supported
end

test "PartialContent" do
    partial_content = "This is a file that contains text to read part of in order to fulfill a 206.";

    get("/partial_content.txt")
        .with_header("Range", "0-4")
        .ensure_code(206)
        .ensure_header("Content-Range", "bytes 0-4/77")
        .ensure_body_has(partial_content[0 .. 4])
        .run

    get("/partial_content.txt")
        .with_header("Range", "-6")
        .ensure_code(206)
        .ensure_header("Content-Range", "bytes 71-76/77")
        .ensure_body_has(partial_content[71 .. 76])
        .run

    get("/partial_content.txt")
        .with_header("Range", "4-")
        .ensure_code(206)
        .ensure_header("Content-Range", "bytes 4-76/77")
        .ensure_body_has(partial_content[4 .. 76])
        .run

    get("/partial_content.txt")
        .with_header("Range", "10-0")
        .ensure_code(416)
        .ensure_header("Content-Range", "bytes */77")
        .run

    get("/partial_content.txt")
        .with_header("Range", "75-80")
        .ensure_code(206)
        .ensure_header("Content-Range", "bytes 75-76/77")
        .ensure_body_has(partial_content[75 .. 76])
        .run

    get("/partial_content.txt")
        .with_header("Range", "0-78")
        .ensure_code(206)
        .ensure_header("Content-Range", "bytes 0-76/77")
        .ensure_body_has(partial_content[0 .. 76])
        .run

    get("/partial_content.txt")
        .with_header("Range", "77-")
        .ensure_code(416)
        .ensure_header("Content-Range", "bytes */77")
        .run
end

count_success = 0
count_failures = 0
for t in $tests do
    # Clear globals before each test...
    $globals[:cookies] = {}

    puts "---------------------------------------- #{t[:name]} ----------------------------------------"
    begin
        t[:block].call()
        count_success += 1
    rescue TestFailedError => e
        puts "==> #{e.message}"
        count_failures += 1
    end
end

pad_length = $tests.size.to_s.size
puts ""
puts "Result: #{$tests.size   .to_s.rjust(pad_length, " ")} tests runned"
puts "        #{count_failures.to_s.rjust(pad_length, " ")} tests failed"
puts "        #{count_success .to_s.rjust(pad_length, " ")} tests succeeded"