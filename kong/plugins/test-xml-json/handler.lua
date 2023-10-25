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
      if kong.request.get_header("Content-Type") ~= "application/xml" then
        local error_response = {
          message = "XML request body not found",
        }
        return kong.response.exit(400, error_response, {
          ["Content-Type"] = "application/json"
        })
      end
      local initialRequest = kong.request.get_raw_body()
      local xml = initialRequest
      local handler = require("xmlhandler.tree")
      handler = handler:new()
      --Instantiates the XML parser
      local parser = xml2lua.parser(handler)

      parser:parse(xml)

      -- Function to convert the XML tree to a Lua table recursively
      local function xml_tree_to_lua_table(xml_tree)
        local result = {}
        for tag, value in pairs(xml_tree) do
          if type(value) == "table" then
            if #value == 1 and type(value[1]) == "string" then
              -- Handle single-value elements
              result[tag] = value[1]
            else
              -- Handle nested elements recursively
              result[tag] = xml_tree_to_lua_table(value)
            end
          else
            -- Handle attributes
            result[tag] = value
          end
        end
        return result
      end

      -- Convert the XML tree to a Lua table
      local lua_table = xml_tree_to_lua_table(handler.root)
      kong.service.request.set_raw_body(json.encode(lua_table))
    end
    function xmlToJsonErrorhandler( err )
      kong.log.set_serialize_value("request.Xml-To-Json_Request", err)
      local error_response = {
        message = "Invalid xml request payload",
      }
      return kong.response.exit(400, error_response, {
        ["Content-Type"] = "application/json"
      })
    end
   
    status = xpcall( xmlToJsonFunction, xmlToJsonErrorhandler )
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
    local initialResponse = kong.service.response.get_raw_body()
    local xmlResponse = initialResponse
    local handler = require("xmlhandler.tree")
    handler = handler:new()
    local parser = xml2lua.parser(handler)
    parser:parse(xmlResponse)

    -- Function to convert the XML tree to a Lua table recursively
    local function xml_tree_to_lua_table(xml_tree)
      local result = {}
      for tag, value in pairs(xml_tree) do
        if type(value) == "table" then
          if #value == 1 and type(value[1]) == "string" then
            -- Handle single-value elements
            result[tag] = value[1]
          else
            -- Handle nested elements recursively
            result[tag] = xml_tree_to_lua_table(value)
          end
        else
          -- Handle attributes
          result[tag] = value
        end
      end
      return result
    end
    local response_lua_table = xml_tree_to_lua_table(handler.root)
    kong.response.set_raw_body(json.encode(response_lua_table))
  end
end
-- return our plugin object
return plugin
