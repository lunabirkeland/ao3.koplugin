local Blitbuffer = require("ffi/blitbuffer")
local Size = require("ui/size")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local InputText = require("ui/widget/inputtext")
local TextBoxWidget = require("ui/widget/textboxwidget")
local LineWidget = require("ui/widget/linewidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local FrameContainer = require("ui/widget/container/framecontainer")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local T = require("gettext")
local ScrollingPages = require("scrolling_pages")
local Comment = require("comment")
local Web = require("web")

local CommentDialog = WidgetContainer:extend({
	work_id = nil,
	chapter_id = nil,
	comment_id = nil,
	comment_author = nil,
	comment_datetime = nil,
	comment_text = nil,
	plugin_path = nil,
	show_parent = nil,
	close_callback = nil,
})

function CommentDialog:init()
	local scrolling_pages = ScrollingPages:new({
		title = T("Send Comment"),
		close_callback = function()
			if self.close_callback then
				self.close_callback()
			end
		end,

		left_icon = "check",
		left_icon_tap_callback = function()
			if
				self.name_input:getText() ~= ""
				and self.email_input:getText():match(".*@.*%..*")
				and self.comment_input:getText() ~= ""
			then
				Web:sendComment(
					self.work_id,
					self.chapter_id,
					self.comment_id,
					self.name_input:getText(),
					self.email_input:getText(),
					self.comment_input:getText()
				)
				if self.close_callback then
					self.close_callback()
				end
			end
		end,

		content_generator = function(width, container, page)
			local vertical_group = VerticalGroup:new({
				align = "left",
				width = width,
				layout = {},
			})

			if self.comment_id then
				table.insert(
					vertical_group,
					Comment:new({
						width = width,
						depth = 0,
						text = self.comment_text,
						author = self.comment_author,
						datetime = self.comment_datetime,
						comment_id = self.comment_id,
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

			local label_width = width * 0.25
			local input_width = width - label_width

			self.name_input = InputText:new({
				text = "",
				width = input_width - InputText.bordersize * 2,
				scroll = false,
				focused = false,
				padding = 0,
				margin = 0,
				parent = self.show_parent,
			})
			table.insert(vertical_group.layout, { self.name_input })

			table.insert(
				vertical_group,
				HorizontalGroup:new({
					dimen = Geom:new({
						w = width,
					}),
					FrameContainer:new({
						bordersize = 0,
						padding = 0,
						margin = Size.margin.fine_tune,
						TextBoxWidget:new({
							text = T("Guest name"),
							face = Font:getFace("x_smallinfofont"),
							width = label_width - 2 * Size.margin.fine_tune,
						}),
					}),
					self.name_input,
				})
			)
			table.insert(
				vertical_group,
				VerticalSpan:new({
					width = Size.span.vertical_large,
				})
			)

			self.email_input = InputText:new({
				text = "",
				width = input_width - InputText.bordersize * 2,
				scroll = false,
				focused = false,
				padding = 0,
				margin = 0,
				parent = self.show_parent,
			})
			table.insert(vertical_group.layout, { self.email_input })

			table.insert(
				vertical_group,
				HorizontalGroup:new({
					dimen = Geom:new({
						w = width,
					}),
					FrameContainer:new({
						bordersize = 0,
						padding = 0,
						margin = Size.margin.fine_tune,
						TextBoxWidget:new({
							text = T("Guest email"),
							face = Font:getFace("x_smallinfofont"),
							width = label_width - 2 * Size.margin.fine_tune,
						}),
					}),
					self.email_input,
				})
			)

			table.insert(
				vertical_group,
				VerticalSpan:new({
					width = Size.span.vertical_large,
				})
			)

			local remaining_height = container.inner_height - vertical_group:getSize().h - Size.span.vertical_large
			local content_input_height = math.max(remaining_height, container.inner_height * 0.5)
			self.comment_input = InputText:new({
				text = "",
				width = width - InputText.bordersize * 2 - Size.margin.fine_tune,
				height = content_input_height,
				scroll = false,
				focused = false,
				padding = 0,
				margin = 0,
				parent = self.show_parent,
			})
			table.insert(vertical_group.layout, { self.comment_input })

			table.insert(
				vertical_group,
				HorizontalGroup:new({
					dimen = Geom:new({
						w = width,
					}),
					HorizontalSpan:new({
						width = Size.margin.fine_tune,
					}),
					self.comment_input,
				})
			)

			-- required to update _offsets
			vertical_group._size = nil
			vertical_group:getSize()

			return vertical_group
		end,
		show_parent = self,
	})

	self[1] = scrolling_pages
end

function CommentDialog:onSwitchFocus(focus)
	if self[1] and self[1].onSwitchFocus then
		self[1]:onSwitchFocus(focus)
	end
end

function CommentDialog:toClose()
	if self[1] and self[1].toClose then
		self[1]:toClose()
	end
end

return CommentDialog
