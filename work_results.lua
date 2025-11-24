local Blitbuffer = require("ffi/blitbuffer")
local Size = require("ui/size")
local Geom = require("ui/geometry")
local UIManager = require("ui/uimanager")
local LineWidget = require("ui/widget/linewidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local T = require("gettext")
local DialogManager = require("dialog_manager")
local WorkResult = require("work_result")
local ScrollingPages = require("scrolling_pages")

local WorkResults = WidgetContainer:extend({
	works_generator = nil,
	works = nil,
	plugin_path = nil,
	show_parent = nil,
	title = nil,
	left_icon = nil,
	left_icon_tap_callback = nil,
})

function WorkResults:init()
	local scrolling_pages = ScrollingPages:new({
		title = self.title,
		left_icon = self.left_icon,
		left_icon_tap_callback = self.left_icon_tap_callback,
		close_callback = self.close_callback,

		page = 1,

		content_generator = function(width, container, page)
			local close_info = DialogManager:showInfo(T("Searching works"))

			UIManager:nextTick(function()
				local vertical_group = VerticalGroup:new({
					align = "left",
					width = width,
				})

				if self.works_generator then
					self.works = self.works_generator(page, container)
				end
				UIManager:nextTick(close_info)

				for _, work in ipairs(self.works or {}) do
					local widget = WorkResult:new({
						width = width,
						work = work,
						plugin_path = self.plugin_path,
						parent = self.show_parent,
					})

					table.insert(vertical_group, widget)

					table.insert(
						vertical_group,
						VerticalGroup:new({
							LineWidget:new({
								background = Blitbuffer.COLOR_DARK_GRAY,
								dimen = Geom:new({
									w = width,
									h = Size.line.thick,
								}),
							}),
							VerticalSpan:new({
								width = Size.span.vertical_large,
							}),
						})
					)
				end

				container:setContent(vertical_group)
			end)
			return VerticalGroup:new({
				width = width,
			})
		end,
		show_parent = self.show_parent,
	})

	self[1] = scrolling_pages
end

return WorkResults
