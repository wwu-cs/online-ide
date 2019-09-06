-- set the content type
ngx.header["Content-Type"] = "text/html"

-- load templating system for errors and add default header
local template = require("resty.template")

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

-- parse the request uri to get image type and name and if missing, go to dashboard
local args = ngx.decode_args(ngx.var.query_string,0)
if (not args.ws_type) or (not args.ws_name) then
    template.render("templates/error.html",{ message = "Missing Parameters" })
    ngx.exit(ngx.HTTP_OK)
end

-- make sure the type is a valid image
local res = redis:hgetall("image:" .. args.ws_type)
if not res then
    template.render("templates/error.html",{ message = "Invalid Image: " .. args.ws_type })
    ngx.exit(ngx.HTTP_OK)
end
local iinfo = common:hash_to_table(res)

-- send them the template page which will invoke second setp
template.render("templates/create.html", { 
    workspace = iinfo.title,
    params = ngx.var.query_string
})