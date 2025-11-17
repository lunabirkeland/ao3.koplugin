local Blitbuffer = require("ffi/blitbuffer")
local Size = require("ui/size")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local LineWidget = require("ui/widget/linewidget")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local logger = require("logger")
local T = require("gettext")
local ScrollingPages = require("scrolling_pages")
local Web = require("web")

local ChapterButton = InputContainer:extend({
	width = nil,
	name = nil,
	datetime = nil,
	chapter_id = nil,
	on_tap_callback = nil,
})

function ChapterButton:init()
	local datetime = TextWidget:new({

		face = Font:getFace("smallinfofont"),
		text = self.datetime,
	})
	local frame = FrameContainer:new({
		bordersize = 0,
		padding = 0,
		HorizontalGroup:new({
			TextBoxWidget:new({
				face = Font:getFace("cfont"),
				text = self.name,
				width = self.width - datetime:getSize().w,
			}),
			datetime,
		}),
	})

	self.dimen = frame:getSize()
	self[1] = frame

	self.ges_events = {
		TapSelectButton = {
			GestureRange:new({
				ges = "tap",
				range = self.dimen,
			}),
		},
	}
end

function ChapterButton:onTapSelectButton(args, ges)
	if self.on_tap_callback then
		self.on_tap_callback(self.chapter_id)
	end
end

local ChapterPicker = WidgetContainer:extend({
	work_id = nil,
	plugin_path = nil,
	show_parent = nil,
	on_tap_callback = nil,
	single_chapter_callback = nil,
	close_callback = nil,
})

function ChapterPicker:init()
	local scrolling_pages = ScrollingPages:new({
		title = T("Chapter Picker"),
		close_callback = function()
			if self.close_callback then
				self.close_callback()
			end
		end,

		content_generator = function(width, container, page)
			local chapters = Web:getChapters(self.work_id)
			local vertical_group = VerticalGroup:new({
				align = "left",
				width = width,
			})

			if #chapters == 1 and self.single_chapter_callback then
				self.single_chapter_callback(chapters[1].id)
			end

			for _, chapter in ipairs(chapters) do
				table.insert(
					vertical_group,
					ChapterButton:new({
						width = width,
						name = chapter.name,
						datetime = chapter.datetime,
						chapter_id = chapter.id,
						on_tap_callback = self.on_tap_callback,
					})
				)

				table.insert(
					vertical_group,
					VerticalGroup:new({
						LineWidget:new({
							background = Blitbuffer.COLOR_DARK_GRAY,
							dimen = Geom:new({
								w = width,
								h = 2,
							}),
						}),
						VerticalSpan:new({
							width = Size.span.vertical_large,
						}),
					})
				)
			end

			return vertical_group
		end,
		show_parent = self.show_parent,
	})

	self[1] = scrolling_pages
end

return ChapterPicker
