-- turn off client caching for this page and set content type
ngx.header["Cache-Control"] = "no-store,must-revalidate"
ngx.header["Expires"] = "0"
ngx.header["Content-Type"] = "text/html"

-- initialize variables
local uname = ''
local uid = -1
local fullname = ''
local admin = ''
local c_code = ''

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

-- check to see if the cookie is set (0 = no cookie, -1 = redis error, 1 = success)
local success = 0
if ngx.var.cookie_codeLogin then

    -- assume we don't find user in redis
    success = -1

    -- check to see if it exists in Redis and if so...
    local res, err = redis:exists("login:" .. ngx.var.cookie_codeLogin)
    
    -- yes, we found the login
    if res == 1 then

	-- load information into local variables
	uname = redis:hget("login:" .. ngx.var.cookie_codeLogin,"uname")
	uid = redis:hget("login:" .. ngx.var.cookie_codeLogin,"uid")
	fullname = redis:hget("login:" .. ngx.var.cookie_codeLogin,"fullname")
	admin = redis:hget("login:" .. ngx.var.cookie_codeLogin,"admin")
	c_code = ngx.var.cookie_codeLogin

	-- reset the login TTL in redis
	local expires = ngx.time() + common.login_time
	redis:expireat("login:" .. c_code,expires)

	-- if we found everything then we were successful
	if not (uname == '') and not (uid == -1) and not (fullname == '') then
	    success = 1	
	end
        
    end
    
end

-- if we weren't successful, redirect or throw an error
if not (success == 1) then
    if success == 0 then
        template.render("templates/error.html",{ message = "Error Loading Login" })
	ngx.exit(ngx.HTTP_OK)
    else    
	ngx.redirect("/logout/")
	return
    end
end

-- we have a user, so look up available images for creation
images = {}
local results = redis:keys("image:*")
for index,val in ipairs(results) do
    local temp = redis:hgetall(val)
    local data = common:hash_to_table(temp)
    data["id"] = val:gsub("image:","")
    images[index] = data
end

-- now look up containers belonging to this user
containers = {}
local results = redis:keys("container:" .. uname .. ":*")
for index,val in ipairs(results) do

    -- get container hash and turn it into a table
    local temp = redis:hgetall(val)
    local data = common:hash_to_table(temp)
    
    -- compute how long its been running
    if data["started"] then
	local seconds = ngx.now() - data["started"]
	local ellapsed = ""
	if seconds >= 3600 then
	    hours = math.floor(seconds/3600)
	    seconds = seconds - hours*3600
	    ellapsed = string.format("%d",hours) .. " hrs"
	end
	local min = math.floor(seconds/60)
	data["ellapsed"] = ellapsed .. " " .. string.format("%d",min) .. " min"
	data["id"] = val:gsub("container:" .. uname .. ":","")
    end
    if data.type and data.port and data.name and data.id then
	containers[index] = data
    end
end

-- return redis connection to pool
local ok, err = redis:set_keepalive(10000, 10)
if not ok then
    template.render("templates/error.html",{ message = "Pooling Redis: " .. err })
    ngx.exit(ngx.HTTP_OK)
end

-- display the dashboard template
template.render("templates/dashboard.html", {
  fullname = fullname,
  containers = containers,
  images = images,
  admin = admin
})

