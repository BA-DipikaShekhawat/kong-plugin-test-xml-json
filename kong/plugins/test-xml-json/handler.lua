local xml2lua = require("xml2lua")
local json = require "cjson"

local plugin = {
  PRIORITY = 803,  -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1", -- version in X.Y.Z format. Check hybrid-mode compatibility requirements.
}
-- runs in the 'access_by_lua_block'
-- runs in the 'access_by_lua_block'
function plugin:access(config)
  kong.service.request.enable_buffering()
  -- Check the request body content type is application/xml or not
  if kong.request.get_header("Content-Type") ~= "application/xml" then
    local error_response = {
      success = "false",
      status = "failed",
      errorCode = "8003",
      message = "XML request body not found",
    }
    return kong.response.exit(400, error_response, {
      ["Content-Type"] = "application/json"
    })
  end
  -- Check the request body is empty or not
  if kong.request.get_raw_body() == "" then
    local error_response = {
      success = "false",
      status = "failed",
      errorCode = "8003",
      message = "XML request body is Empty",
    }
    return kong.response.exit(400, error_response, {
      ["Content-Type"] = "application/json"
    })
  end

  if config.enable_on_request then
    local initialRequest = kong.request.get_raw_body()

    local xml = initialRequest

    local handler = require("xmlhandler.tree")

    handler = handler:new()

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

    kong.service.request.set_header("Content-Type", "application/json")
    kong.service.request.enable_buffering()
  end
end

function plugin:rewrite()
  -- your custom code here
  kong.service.request.enable_buffering()
end
--runs in the 'body_filter_by_lua_block'
function plugin:body_filter(config)
  -- If enable on response is true
  --if config.enable_on_response then
  local initialResponse = kong.service.response.get_raw_body()
  --kong.log.set_serialize_value("dataResponse", initialResponse)

    -- local initialRequest = kong.service.response.get_raw_body()

    -- local xml = initialRequest

    -- local handler = require("xmlhandler.tree")

    -- handler = handler:new()

    -- local parser = xml2lua.parser(handler)

    -- parser:parse(xml)
    -- -- Function to convert the XML tree to a Lua table recursively
    -- local function xml_tree_to_lua_table(xml_tree)
    --   local result = {}
    --   for tag, value in pairs(xml_tree) do
    --     if type(value) == "table" then
    --       if #value == 1 and type(value[1]) == "string" then
    --         -- Handle single-value elements
    --         result[tag] = value[1]
    --       else
    --         -- Handle nested elements recursively
    --         result[tag] = xml_tree_to_lua_table(value)
    --       end
    --     else
    --       -- Handle attributes
    --       result[tag] = value
    --     end
    --   end
    --   return result
    -- end
    -- -- Convert the XML tree to a Lua table
    -- local lua_table = xml_tree_to_lua_table(handler.root)

    -- kong.service.response.set_raw_body(json.encode(lua_table))

    -- kong.service.response.set_header("Content-Type", "application/json")
  -- end
end
-- return our plugin object
return plugin
