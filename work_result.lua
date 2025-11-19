local Screen = require("device").screen
local Blitbuffer = require("ffi/blitbuffer")
local Size = require("ui/size")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local UIManager = require("ui/uimanager")
local GestureRange = require("ui/gesturerange")
local LineWidget = require("ui/widget/linewidget")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local ImageWidget = require("ui/widget/imagewidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local HorizontalSpan = require("ui/widget/horizontalspan")
local FrameContainer = require("ui/widget/container/framecontainer")
local RightContainer = require("ui/widget/container/rightcontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local T = require("gettext")
local DownloadDialog = require("download_dialog")
local DialogManager = require("dialog_manager")

local WorkResult = InputContainer:extend({
	width = nil,
	work = nil,
	plugin_path = nil,
	parent = nil,
})

function WorkResult:init()
	local vertical_group = VerticalGroup:new({ align = "left", width = self.width })

	local required_tags = FrameContainer:new({
		bordersize = 0,
		padding = 0,
		margin = Size.margin.fine_tune,
		VerticalGroup:new({
			HorizontalGroup:new({
				ImageWidget:new({
					width = Screen:scaleBySize(25),
					height = Screen:scaleBySize(25),
					file = self.plugin_path .. "resources/" .. self.work.required_tags.rating .. ".png",
				}),
				HorizontalSpan:new({ width = Size.padding.tiny }),
				ImageWidget:new({
					width = Screen:scaleBySize(25),
					height = Screen:scaleBySize(25),
					file = self.plugin_path .. "resources/" .. self.work.required_tags.category .. ".png",
				}),
			}),
			VerticalSpan:new({ width = Size.padding.tiny }),
			HorizontalGroup:new({
				ImageWidget:new({
					width = Screen:scaleBySize(25),
					height = Screen:scaleBySize(25),
					file = self.plugin_path .. "resources/" .. self.work.required_tags.warnings .. ".png",
				}),
				HorizontalSpan:new({ width = Size.padding.tiny }),
				ImageWidget:new({
					width = Screen:scaleBySize(25),
					height = Screen:scaleBySize(25),
					file = self.plugin_path .. "resources/" .. self.work.required_tags.complete .. ".png",
				}),
			}),
		}),
	})

	local datetime = TextWidget:new({
		text = self.work.datetime,
		face = Font:getFace("x_smallinfofont"),
	})

	local title_width = self.width - required_tags:getSize().h - datetime:getWidth()

	local fandoms = TextBoxWidget:new({
		text = table.concat(self.work.fandoms, ", "),
		face = Font:getFace("x_smallinfofont"),
		width = title_width,
	})

	local title = HorizontalGroup:new({
		align = "top",
		width = self.width,

		required_tags,
		VerticalGroup:new({
			align = "left",
			width = title_width,
			TextBoxWidget:new({
				text = self.work.title .. " by " .. self.work.author,
				face = Font:getFace("x_smallinfofont"),
				width = title_width,
			}),
			fandoms,
		}),
		datetime,
	})
	table.insert(vertical_group, title)

	local tags = TextBoxWidget:new({
		text = table.concat(self.work.tags, ", "),
		face = Font:getFace("xx_smallinfofont"),
		width = self.width,
	})
	table.insert(vertical_group, tags)

	table.insert(
		vertical_group,
		LineWidget:new({
			background = Blitbuffer.COLOR_LIGHT_GRAY,
			dimen = Geom:new({
				w = self.width,
				h = 2,
			}),
		})
	)

	table.insert(
		vertical_group,
		VerticalSpan:new({
			width = Size.span.vertical_large,
		})
	)

	local summary = TextBoxWidget:new({
		text = self.work.summary,
		face = Font:getFace("xx_smallinfofont"),
		width = self.width,
	})
	table.insert(vertical_group, summary)

	table.insert(
		vertical_group,
		VerticalSpan:new({
			width = Size.span.vertical_default,
		})
	)

	local stats = VerticalGroup:new({
		align = "right",
		width = self.width,
	})

	local row = HorizontalGroup:new({
		width = self.width,
	})

	local width

	for i, stat in ipairs({
		{ "language", T("Language") },
		{ "words", T("Words") },
		{ "chapters", T("Chapters") },
		{ "collections", T("Collections") },
		{ "comments", T("Comments") },
		{ "kudos", T("Kudos") },
		{ "bookmarks", T("Bookmarks") },
		{ "hits", T("Hits") },
	}) do
		if self.work.stats[stat[1]] then
			local stat_widget = TextWidget:new({
				text = stat[2] .. ": " .. self.work.stats[stat[1]],
				face = Font:getFace("smallffont"),
			})
			if i == 1 then
				table.insert(row, stat_widget)
				width = stat_widget:getWidth()
			elseif width + stat_widget:getWidth() + Size.padding.large <= self.width then
				table.insert(row, HorizontalSpan:new({ width = Size.padding.large }))
				table.insert(row, stat_widget)
				width = width + stat_widget:getWidth() + Size.padding.large
			else
				table.insert(stats, row)
				row = HorizontalGroup:new({

					width = self.width,
					stat_widget,
				})
				width = stat_widget:getWidth()
			end
		end
	end
	table.insert(stats, row)
	table.insert(
		vertical_group,
		RightContainer:new({

			dimen = Geom:new({
				w = self.width,
				h = stats:getSize().h,
			}),
			stats,
		})
	)

	local frame = FrameContainer:new({
		bordersize = 0,
		margin = 0,
		padding = 0,
		vertical_group,
	})

	self[1] = frame

	self.dimen = frame:getSize()
	self.ges_events = {
		TapSelectButton = {
			GestureRange:new({
				ges = "tap",
				range = self.dimen,
			}),
		},
	}
end

function WorkResult:onTapSelectButton(_arg, _ges)
	local dialog = DownloadDialog:new({
		title = string.format("%s by %s", self.work.title, self.work.author),
		id = self.work.id,
	})
	dialog.close_callback = function()
		DialogManager:close(dialog)
		UIManager:setDirty(self, "ui")
	end
	DialogManager:show(dialog)

	return true
end

return WorkResult
