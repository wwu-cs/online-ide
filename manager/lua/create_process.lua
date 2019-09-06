-- set the content type
ngx.header["Content-Type"] = "text/javascript"


-- load common config and redis modules
local common = require("lua/modules/common")
local redisLib = require "resty.redis"
local redis = redisLib:new()

-- set redis timeouts and connect
redis:set_timeouts(1000, 1000, 1000) -- 1 sec
local ok, err = redis:connect(common.redis_host, common.redis_port)
if not ok then
    ngx.say("document.location = \"/error/?" .. ngx.encode_args({message = "Redis Connect: " .. err }) .. "\"")
    ngx.exit(ngx.HTTP_OK)
end
local ok, err = redis:auth(common.redis_pwd)
if not ok then
    ngx.say("document.location = \"/error/?" .. ngx.encode_args({message = "Redis Auth: " .. err }) .. "\"")
    ngx.exit(ngx.HTTP_OK)
end

-- if no login cookie exists, send home
if not ngx.var.cookie_codeLogin then
    ngx.redirect("/")
    return
end

-- parse the request uri to get image type and name and if missing, go to dashboard
local args = ngx.decode_args(ngx.var.query_string,0)
if (not args.ws_type) or (not args.ws_name) then
    ngx.say("document.location = \"/error/?" .. ngx.encode_args({message = "Missing Parameters" }) .. "\"")
    ngx.exit(ngx.HTTP_OK)
end

-- make sure the type is a valid image
local res = redis:exists("image:" .. args.ws_type)
if not (res == 1) then
    ngx.say("document.location = \"/error/?" .. ngx.encode_args({message = "Invalid Image: " .. args.ws_type }) .. "\"")
    ngx.exit(ngx.HTTP_OK)
end

-- get username and uid based on login cookie
local uname,err = redis:hget("login:" .. ngx.var.cookie_codeLogin, "uname")
local uid,err   = redis:hget("login:" .. ngx.var.cookie_codeLogin, "uid")
if (uname == ngx.null) or (uid == ngx.null) then
    ngx.say("document.location = \"/error/?" .. ngx.encode_args({message = "User Lookup Error" }) .. "\"")
    ngx.exit(ngx.HTTP_OK)
end

-- create array of used ports by querying redis
-- TODO lock
uports = {}
local portList,err = redis:keys("port:*")
for index,val in ipairs(portList) do
    uports[ val:gsub("port:","") ] = 1
end

-- pick the first one that is not used
local port = ''
for i=common.docker_min_port,common.docker_max_port do
    if not (uports[tostring(i)] == 1) then
        port = i
        break
    end            
end

-- reserve the port in redis
local res,err = redis:set("port:" .. port, "creating")
if not res then
    ngx.say("document.location = \"/error/?" .. ngx.encode_args({message = "Redis Port: " .. err }) .. "\"")
    ngx.exit(ngx.HTTP_OK)
end

-- we have our port
-- TODO unlock

-- now construct our json for the docker api
local json = common:srepf(
    common.docker_create_json, {
        uid = uid,
        uname = uname,
        image = args.ws_type,
        port = port
    }
)

-- request a new container from docker API
ngx.req.read_body()
ngx.req.set_header("Content-Type","application/json")
local res = ngx.location.capture(
    "/docker/containers/create",
    { 
        method = ngx.HTTP_POST,
	body = json
    }
)

-- parse the returned value
cjson = require("cjson")
local response = cjson.decode(res.body)

-- check for errors (delete port reservation if found)
if not response.Id then
    redis:del("port:" .. port)
    ngx.say("document.location = \"/error/?" .. ngx.encode_args({message = "Error Creating Workspace: " .. response.Warnings }) .. "\"")
    ngx.exit(ngx.HTTP_OK)
end

-- grab the first 12 characters of the id for our unique name
local cname = response.Id:sub(1,12)
local cid = "container:" .. uname .. ":" .. cname

-- ammend the port entry (delete port reservation if found)
local res,err = redis:set("port:" .. port, cid)
if not res then
    redis:del("port:" .. port)
    ngx.say("document.location = \"/error/?" .. ngx.encode_args({message = "Redis Port: " .. err }) .. "\"")
    ngx.exit(ngx.HTTP_OK)
end

-- ask to start our container
ngx.req.read_body()
ngx.req.set_header("Content-Type","application/json")
local res = ngx.location.capture(
    "/docker/containers/" .. cname .. "/start",
    { 
        method = ngx.HTTP_POST
    }
)

-- check for errors starting the container (release port if found)
if not (res.body == "") then
    redis:del("port:" .. port)
    local temp = cjson.decode(res.body)
    ngx.say("document.location = \"/error/?" .. ngx.encode_args({message = "Starting Container: " .. temp.message }) .. "\"")
    ngx.exit(ngx.HTTP_OK)
end

-- create our redis container entry
local res,err = redis:hset(cid,"type",args.ws_type,"started",math.floor(ngx.now()),"port",port,"name",args.ws_name)
if not res then
    ngx.say("document.location = \"/error/?" .. ngx.encode_args({message = "Redis Container: " .. err }) .. "\"")
    ngx.exit(ngx.HTTP_OK)
end

-- release our redis connection
local ok, err = redis:set_keepalive(10000, 10)
if not ok then
    ngx.say("document.location = \"/error/?" .. ngx.encode_args({message = "Pooling Redis: " .. err }) .. "\"")
    ngx.exit(ngx.HTTP_OK)
end    

-- pause to give the container time to start up
ngx.sleep(5)

-- then direct the browser to connect
ngx.say("document.location = \"/connect/" .. cname .. "/\"");
ngx.exit( ngx.HTTP_OK )