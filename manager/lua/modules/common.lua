-- configuration values for our application
local _common = {

    -- how long logins should last witout activit (currently 30 minutes)
    login_time          = 1800,

    -- static values for Redis connection
    redis_host          = "127.0.0.1",
    redis_port          = 6379,
    redis_pwd           = "MBGwR73znZspcSUg6yGNHcKt1IEgDOfalyY35z4GrNL4CyhUB",

    -- static values for LDAP connection
    ldap_server         = "auth.cs.wallawalla.edu",
    ldap_user_query     = "uid=%uname%,ou=Users,dc=cs,dc=wallawalla,dc=edu",
    ldap_base           = "dc=cs,dc=wallawalla,dc=edu",
    ldap_filter         = "(uid=%uname%)",
    ldap_uid            = "uidNumber",
    ldap_fullname       = "cn",
    ldap_group          = "(cn=cs_professor)",

    -- static values for interacting with docker
    docker_min_port     = 2000,
    docker_max_port     = 4000,
    
    docker_create_json  = [[ {
      "Hostname":"code",
      "User":"%uid%:100",
      "Env": [ "LDAPUSER=%uname%" ],
      "Image": "%image%",
      "ExposedPorts": { "3000/tcp": {} },
      "HostConfig": {
          "Mounts": [
              {
                  "Target":"/home/project",
                  "Source":"/mnt/home/%uname%",
                  "Type":"bind"
              }
          ],
          "CapAdd": [ "SYS_PTRACE" ],
          "SecurityOpt" : [ "seccomp=unconfined" ],
          "PortBindings": {
              "3000/tcp": [
                  {
                      "HostIp":"127.0.0.1",
                      "HostPort":"%port%"
                  }
              ]
          }
      }
    } ]],
      
    docker_start_json   = [[ {
    } ]],

    docker_stop_json    = [[ {
    } ]],

    docker_rm_json      = [[ {
    } ]]
    
    
}

-- function to convert a redis hash to a lua table
function _common:hash_to_table(hash)
    local nextkey
    local data = {}
    for index, val in ipairs(hash) do
	if index % 2 == 1 then 
	nextkey = val
	else
	    data[nextkey] = val
	end
    end
    return data	
end

-- sprintf-like function to fill out string templates
function _common:srepf(str,vars)
    return (string.gsub(str, "(%%([^%%]+)%%)",
        function(whole,i)
            return vars[i] or whole
        end))
end

return _common