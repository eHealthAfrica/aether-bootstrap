Kong.rewrite()

            -- # rewrite based on bad routes
            -- # match /*-app/ url being routed to the base, which is incorrect.
            local m, err = ngx.re.match(ngx.var.uri, "/(?<app>[^/]+)-app(?<url>.+)", "ao")
            if err then
                ngx.log(ngx.ERR, err)
            elseif ngx.var["cookie_EOAuthToken"] ~= nil then
                local service  = m["app"]
                local remaining_url = m["url"]
                local realm = ngx.header["X-Oauth-realm"]
                ngx.log(ngx.ERR, realm .. "/" .. service .. "/" .. remaining_url)
            else
                ngx.log(ngx.ERR, "Ignored " .. ngx.var.uri)
                -- local cookie_name = "cookie_" .. "EOAuthToken"
                -- ngx.log(ngx.ERR, "Cookies " .. ngx.var[cookie_name])
                -- if ngx.header["Set-Cookie"] ~= nil then
                --     ngx.log(ngx.ERR, "Set-Cookies " ngx.header["Set-Cookie"])
                -- end
            end