local UIManager = require("ui/uimanager")
local FocusManager = require("ui/widget/focusmanager")
local NetworkMgr = require("ui/network/manager")
local T = require("gettext")
local logger = require("logger")
local WorkResults = require("work_results")
local Web = require("web")

local SearchQuery = require("search_query")

local Search = FocusManager:extend({
	query = {},
	plugin_path = nil,
	is_always_active = true,
})

function Search:init()
	self:showQuery()
end

function Search:onSwitchFocus(focus)
	if self[1] and self[1].onSwitchFocus then
		self[1]:onSwitchFocus(focus)
	end
end

function Search:toClose()
	if self[1] and self[1].toClose then
		self[1]:toClose()
	end
end

function Search:showQuery()
	if self[1] and self[1].toClose then
		self[1]:toClose()
	end

	local search_query = SearchQuery:new({
		title = T("AO3 Work Search"),
		left_icon = "appbar.search",
		left_icon_tap_callback = function()
			self.query = self[1]:getQuery()
			self:showResults()
		end,
		close_callback = function()
			UIManager:close(self)
		end,
		query = self.query,
		show_parent = self,
	})

	self[1] = search_query
end

function Search:showResults()
	if self[1] and self[1].toClose then
		self[1]:toClose()
	end

	if not NetworkMgr:isOnline() then
		logger.err("network offline")
		return
		-- TODO: handle offline
	end

	local work_results = WorkResults:new({
		title = T("AO3 Work Search Results"),
		left_icon = "appbar.search",
		left_icon_tap_callback = function()
			self:showQuery()
		end,
		close_callback = function()
			UIManager:close(self)
		end,
		query = self.query,

		works_generator = function(page, parent)
			local works, pages = Web:search_works(self.query, page)
			parent.pages = pages

			return works
		end,
		plugin_path = self.plugin_path,
		show_parent = self,
	})

	self[1] = work_results

	UIManager:setDirty(self, "ui")
end

return Search
