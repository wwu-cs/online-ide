-- turn off client caching for this page and set content type
ngx.header["Cache-Control"] = "no-store,must-revalidate"
ngx.header["Expires"] = "0"
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

-- if a "codeLogin" cookie exists...
if ngx.var.cookie_codeLogin then

    -- check to see if it exists in Redis and if so...
    local res, err = redis:exists("login:" .. ngx.var.cookie_codeLogin)

    -- put the redis connection back in the pool as we're done with it
    local ok, err = redis:set_keepalive(10000, 10)
    if not ok then
	template.render("templates/error.html",{ message = "Pooling Redis: " .. err })
	ngx.exit(ngx.HTTP_OK)
    end

    -- now if the cookie is valid, go to the dashboard
    if res == 1 then
        ngx.redirect("/dashboard/")
	
    -- otherwise call logout to clear things
    else
	ngx.redirect("/logout/")
	
    end

    ngx.exit(ngx.HTTP_OK)

end

-- try to import username and password post variables
ngx.req.read_body()
local args,err = ngx.req.get_post_args()
if not args then
    template.render("templates/error.html",{ message = "Post Variables: ", err })
    ngx.exit(ngx.HTTP_OK)
end

-- if we have a username and password, process them
if args['uname'] and args['pword'] then

    -- load the ldap library and set some variables
    local ldap = require("lualdap")
    local uid = ""
    local fullname = ""
    local uname = args['uname']

    -- try to log in
    local ld,err = ldap.open_simple(
        common.ldap_server,
        common.ldap_user_query:gsub("%%uname%%",args['uname']),
	args['pword']
    )

    -- if we didn't succeed, 
    if not ld then
	
	-- put redis back in its pool, and ...
	local ok, err = redis:set_keepalive(10000, 10)
	if not ok then
	    template.render("templates/error.html",{ message = "Pooling Redis: " .. err })
	    ngx.exit(ngx.HTTP_OK)
	end    

	-- go back to login page
	ngx.redirect("/?failed=true")
	ngx.exit(ngx.HTTP_OK)
	
    end
    
    -- if we did succeed load information from ldap
    for dn, attribs in ld:search( { 
        base = common.ldap_base, 
        scope="subtree",
	filter=common.ldap_filter:gsub("%%uname%%",args['uname'])
    }) do
	for attrib_name,attrib_val in pairs (attribs) do
	    if attrib_name == common.ldap_uid then
		uid = attrib_val
	    elseif attrib_name == common.ldap_fullname then
		fullname = attrib_val
	    end
	end
    end

    -- and look for group membership
    local admin = "false"
    for dn, attribs in ld:search({
        base = common.ldap_base,
	scope="subtree",
	filter=common.ldap_group
    }) do
	for attrib_name,attrib_val in pairs(attribs) do
	    if attrib_name == "memberUid" then
		for _,v in pairs(attrib_val) do
		    if v == uname then
			admin = "true"
		    end
		end
	    end
	end
    end
	
    -- if we didn't get what we needed, throw an error
    if (uid == "") or (fullname == "") then
	template.render("templates/error.html",{ message = "Incomplete LDAP Info" })
	ngx.exit(ngx.HTTP_OK)
    end

    -- otherwise, create token for cookie
    local c_code = ngx.encode_base64(ngx.hmac_sha1(ngx.cookie_time(ngx.time()),uname))

    -- set the login cookie (doesn't need to expire)
    ngx.header["Set-Cookie"] = "codeLogin=" .. c_code .. "; Path=/;"
    
    -- and save info in Redis with an expiration time
    local expires = ngx.time() + common.login_time
    redis:hmset("login:" .. c_code,"uname",uname,"uid",uid,"fullname",fullname,"ip",ngx.var.remote_addr,"admin",admin)
    redis:expireat("login:" .. c_code,expires)

    -- put our redis connection back in the pool
    local ok, err = redis:set_keepalive(10000, 10)
    if not ok then
	template.render("templates/error.html",{ message = "Pooling Redis: " .. err })
	ngx.exit(ngx.HTTP_OK)
    end    
    
    -- if we got here, we can go to the dashboard
    ngx.redirect("/dashboard/")
    ngx.exit(ngx.HTTP_OK)

end

-- but if we got here, we were missing login info and after putting redis back in pool...
local ok, err = redis:set_keepalive(10000, 10)
if not ok then
    template.render("templates/error.html",{ message = "Pooling Redis: " .. err })
    ngx.exit(ngx.HTTP_OK)
end    

-- we should try again
ngx.redirect("/?failed=true")
ngx.exit(ngx.HTTP_OK)