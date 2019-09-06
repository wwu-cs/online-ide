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

-- parse the request uri into container id and request path
local cid = ngx.var.request_uri:match "/connect/[^/]+/"
if not cid then
    ngx.redirect("/error/?" .. ngx.encode_args({message = "No Container ID"}))
    return    
end
ngx.var.path = ngx.var.request_uri:gsub(cid,"")
cid = cid:gsub("/connect/",""):sub(1,-2)

-- look up container with this id and get the owner and port for our container
local cname = redis:keys("container:*:" .. cid)
local owner = cname[1]:gsub("container:",""):gsub(":.*","")
local port = redis:hget(cname[1],"port")
if (port == ngx.null) then
    ngx.redirect("/error/?" .. ngx.encode_args({message = "Container Lookup Error" }))
    return
end

-- get username and admin status based on login cookie
local uname,err = redis:hget("login:" .. ngx.var.cookie_codeLogin, "uname")
local admin,err = redis:hget("login:" .. ngx.var.cookie_codeLogin, "admin")
if (uname == ngx.null) or (admin == ngx.null) then
    ngx.redirect("/error/?" .. ngx.encode_args({message = "Username Lookup Error" }))
    return;
end

-- if they don't match, not authorized
if not (uname == owner) and not (admin == "true") then

    -- release the redis connection to the pool
    local ok, err = redis:set_keepalive(10000, 10)
    if not ok then
	ngx.redirect("/error/?" .. ngx.encode_args({message = "Pooling Redis: " .. err }))
	return
    end
    
    -- and send back to dashboard
    ngx.redirect("/dashboard/")
    return
    
end

-- update TTL for login in redis
local expires = ngx.time() + common.login_time
redis:expireat("login:" .. ngx.var.cookie_codeLogin,expires)

-- return redis connection to the pool
local ok, err = redis:set_keepalive(10000, 10)
if not ok then
    ngx.say("failed to set keepalive: ", err)
end

-- set the port for proxy
ngx.var.port = port
