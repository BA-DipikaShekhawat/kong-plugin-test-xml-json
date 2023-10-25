local typedefs = require "kong.db.schema.typedefs"


local PLUGIN_NAME = "test-xml-json"


local schema = {
  name = PLUGIN_NAME,
  fields = {
    -- the 'fields' array is the top-level entry with fields defined by Kong
    { consumer = typedefs.no_consumer }, -- this plugin cannot be configured on a consumer (typical for auth plugins)
    { protocols = typedefs.protocols_http },
    {
      config = {
        -- The 'config' record is the custom part of the plugin schema
        type = "record",
        fields = {
          -- a standard defined field (typedef), with some customizations
          {
            enable_on_request = {
              type = "boolean",
              default = false,
            }
          }, -- adding a constraint for the value
          {
            enable_on_response = {
              type = "boolean",
              default = false,
            }
          },  -- adding a constraint for the value
        },
        entity_checks = {
          -- add some validation rules across fields
          { at_least_one_of = { "enable_on_response", "enable_on_request" }, }
        },
      },
    },
  },
}

return schema
