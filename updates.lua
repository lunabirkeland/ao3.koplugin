local HorizontalGroup = require("ui/widget/horizontalgroup")
local VerticalGroup = require("ui/widget/verticalgroup")
local FrameContainer = require("ui/widget/container/framecontainer")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")

local DialogManager = require("dialog_manager")

local Updates = WidgetContainer:extend({
	plugin_path = nil,
	close_callback = nil,
})

local function getVersion(plugin_path)
	local ok, result = pcall(dofile, plugin_path .. "_meta.lua")

	if not (ok and result) then
		DialogManager:showError("Failed to get plugin version\nfailed to load _meta.lua")
		logger.err("failed to load _meta.lua")
		return
	end

	local v1, v2, v3 = result.version:match("(%d+)%.(%d+)%.(%d+)")
	if not v1 and v2 and v3 then
		DialogManager:showError(
			string.format("Failed to get plugin version\nfailed to extract version parts from\n%s", result.version)
		)
		logger.err(string.format("failed to extract version parts from %s", result.version))
		return
	end

	return v1, v2, v3
end

function Updates:init()
	local v1, v2, v3 = getVersion(self.plugin_path)
	logger.info(string.format("v1: %s, v2: %s, v3: %s", v1, v2, v3))
end

return Updates
