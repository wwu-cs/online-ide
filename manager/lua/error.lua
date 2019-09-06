-- set content type
ngx.header["Content-Type"] = "text/html"

-- load templating system for errors and add default header
local template = require("resty.template")

-- return error
local msg = ngx.decode_args(ngx.var.query_string,1)
template.render("templates/error.html",{ message = msg.message })
ngx.exit(ngx.HTTP_OK)
