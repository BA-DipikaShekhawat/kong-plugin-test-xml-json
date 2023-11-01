  local xml2lua = require("xml2lua")

  local json = require "cjson"



  local plugin = {
    PRIORITY = 803, -- set the plugin priority, which determines plugin execution order
    VERSION = "0.1", -- version in X.Y.Z format. Check hybrid-mode compatibility requirements.
  }

  function plugin:rewrite(config)
    -- Implement logic for the rewrite phase here (http)
    kong.service.request.enable_buffering()
  end

  -- runs in the 'access_by_lua_block'
  function plugin:access(config)
    -- your custom code here
    kong.service.request.enable_buffering()
    if config.enable_on_request then
      function xmlToJsonFunction ()
        return kong.response.error(400, "The payload is not in expected format", {["Content-Type"] = "application/json"})
        end
        local initialRequest = kong.request.get_raw_body()
        local xml = initialRequest
        local handler = require("xmlhandler.tree")
        handler = handler:new()
        --Instantiates the XML parser
        local parser = xml2lua.parser(handler)
        --local status, errormessage = pcall(parser:parse(), xml)
        parser:parse(xml)
        --if status == false then
        --  return kong.response.error(400, "unable to parse", {["Content-Type"] = "application/json"})
        --end
        local lua_table = handler.root
        kong.service.request.set_raw_body(json.encode(lua_table))
      end
      function xmlToJsonError( err )
        kong.log.set_serialize_value("request.Xml-To-Json_Request", err)
        return kong.response.error(400, "Invalid request payload", {["Content-Type"] = "application/json"})
      end
    
      local status = xpcall( xmlToJsonFunction, xmlToJsonError )
      kong.log.set_serialize_value("request.Xml-To-Json_Request-status", status)
    end
  end

  function plugin:header_filter(config)
    kong.response.clear_header("Content-Length")
    kong.response.set_header("Content-Type", "application/json")
  end

  function plugin:body_filter(config)
    -- Implement logic for the body_filter phase here (http)
    if config.enable_on_response then
    if kong.service.response.get_header("Content-Type") == "application/xml" or kong.service.response.get_header("Content-Type") == "application/xml; charset=utf-8"then
      local initialResponse = kong.service.response.get_raw_body()
      local xmlResponse = initialResponse
      local handler = require("xmlhandler.tree")
      handler = handler:new()
      local parser = xml2lua.parser(handler)
      parser:parse(xmlResponse)
      local response_lua_table = handler.root
      kong.response.set_raw_body(json.encode(response_lua_table))
      end
    end
  end
  -- return our plugin object
  return plugin
