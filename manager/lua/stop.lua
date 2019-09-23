-- load common config and redis modules
local common = require("lua/modules/common")
local redisLib = require "resty.redis"
local redis = redisLib:new()

-- set redis timeouts and connect
redis:set_timeouts(1000, 1000, 1000) -- 1 sec
local ok, err = redis:connect(common.redis_host, common.redis_port)
if not ok then
    ngx.redirect("/error/?" .. ngx.encode_args({message = "Redis Connect: " .. err }))
    return
end
local ok, err = redis:auth(common.redis_pwd)
if not ok then
    ngx.redirect("/error/?" .. ngx.encode_args({message = "Redis Auth: " .. err }))
    return
end

-- if no login cookie exists, send home
if not ngx.var.cookie_codeLogin then
    ngx.redirect("/")
    return
end

-- parse the request uri to get container id
local cid = ngx.var.request_uri:match "/stop/[^/]+/"
if not cid then
    ngx.redirect("/error/?" .. ngx.encode_args({message = "No Container ID"}))
    return
end
cid = cid:gsub("/stop/",""):sub(1,-2)

-- get username, uid, and admin based on login cookie
local uname,err = redis:hget("login:" .. ngx.var.cookie_codeLogin, "uname")
local uid,err   = redis:hget("login:" .. ngx.var.cookie_codeLogin, "uid")
local admin,err = redis:hget("login:" .. ngx.var.cookie_codeLogin, "admin")
if (uname == ngx.null) or (uid == ngx.null) then
    ngx.redirect("/error/?" .. ngx.encode_args({message = "User Lookup Error" }))
    return
end

-- verify that this container exists for this user (or any user if admin)
local port = ngx.null
if admin == 'true' then
    local res = redis:keys("container:*:" .. cid)
    if res then
        port = redis:hget(res[1],"port")
    end    
else
    port = redis:hget("container:" .. uname .. ":" .. cid,"port")
end    
if (port == ngx.null) then
    ngx.redirect("/error/?" .. ngx.encode_args({message = "Invalid Container"}))
    return
end

-- ask to stop our container
ngx.req.read_body()
ngx.req.set_header("Content-Type","application/json")
local res = ngx.location.capture(
    "/docker/containers/" .. cid .. "/stop",
    { 
        method = ngx.HTTP_POST
    }
)

-- check for errors stopping the container
cjson = require("cjson")
if not (res.body == "") then
    local temp = cjson.decode(res.body)
    ngx.redirect("/error/?" .. ngx.encode_args({message = "Stopping Container: " .. temp.message }))
    return
end

-- delete the container
ngx.req.read_body()
ngx.req.set_header("Content-Type","application/json")
local res = ngx.location.capture(
    "/docker/containers/" .. cid,
    { 
        method = ngx.HTTP_DELETE
    }
)

-- check for errors deleting the container
if not (res.body == "") then
    local temp = cjson.decode(res.body)
    ngx.redirect("/error/?" .. ngx.encode_args({message = "Deleting Container: " .. temp.message }))
    return
end

-- delete the port in redis
local res,err = redis:del("port:" .. port)
if not res then
    ngx.redirect("/error/?" .. ngx.encode_args({message = "Redis Delete Port: " .. err}))
    return
end

-- delete redis container entry
local resDel,err
if admin == 'true' then
    resDel,err = redis:del("container:*:" .. cid)
else
    resDel,err = redis:del("container:" .. uname .. ":" .. cid)
end
if not resDel then
    ngx.redirect("/error/?" .. ngx.encode_args({message = "Redis Delete Container: " .. err}))
    return
end

-- release our redis connection
local ok, err = redis:set_keepalive(10000, 10)
if not ok then
    ngx.say("document.location = \"/error/?" .. ngx.encode_args({message = "Pooling Redis: " .. err }) .. "\"")
    ngx.exit(ngx.HTTP_OK)
end    

-- then direct the browser back to the dashboard
ngx.redirect("/dashboard/")
return