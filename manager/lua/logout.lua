-- only something to do if there is a cookie
if ngx.var.cookie_codeLogin then

    -- set content type
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
	template.render("templates/error.html",{ message = "Redis Connect: " .. err })
	ngx.exit(ngx.HTTP_OK)
    end
    local ok, err = redis:auth(common.redis_pwd)
    if not ok then
	template.render("templates/error.html",{ message = "Redis Auth: ", err })
	ngx.exit(ngx.HTTP_OK)
    end

    -- delete the login cookie from redis
    local res,err = redis:del("login:" .. ngx.var.cookie_codeLogin)
    if not res then
	template.render("templates/error.html",{ message = "Redis Delete: ", err })
	ngx.exit(ngx.HTTP_OK)
    end

    -- and from the client
    ngx.header["Set-Cookie"] = "codeLogin=; Path=/; Expires=" .. ngx.cookie_time(ngx.now()-1)

    -- put redis connection back in the pool
    local ok, err = redis:set_keepalive(10000, 10)
    if not ok then
	template.render("templates/error.html",{ message = "Pooling Redis: " .. err })
	ngx.exit(ngx.HTTP_OK)
    end    

end

-- redirect to the login page
ngx.redirect("/")
ngx.exit(ngx.HTTP_OK)