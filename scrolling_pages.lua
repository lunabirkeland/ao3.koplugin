local Device = require("device")
local Screen = Device.screen
local Blitbuffer = require("ffi/blitbuffer")
local Font = require("ui/font")
local Size = require("ui/size")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local TextBoxWidget = require("ui/widget/textboxwidget")
local IconButton = require("ui/widget/iconbutton")
local LineWidget = require("ui/widget/linewidget")
local VerticalSpan = require("ui/widget/verticalspan")
local FrameContainer = require("ui/widget/container/framecontainer")
local ScrollableContainer = require("ui/widget/container/scrollablecontainer")
local FocusManager = require("ui/widget/focusmanager")

local DGENERIC_ICON_SIZE = G_defaults:readSetting("DGENERIC_ICON_SIZE")

local ScrollingPages = FocusManager:extend({
	title = nil,
	width = nil,
	height = nil,
	page = nil,
	pages = nil,
	page_turn_callback = nil,
	content = nil,
	content_generator = nil,
	close_callback = nil,
	left_icon = nil,
	left_icon_tap_callback = nil,
	left_icon_2 = nil,
	left_icon_2_tap_callback = nil,
	bordersize = 0,
	padding = 0,
	radius = 0,
	margin = 0,

	mirror_scrollbar_gap = true,

	show_parent = nil,
	is_always_active = true,
	focused = nil,
})

function ScrollingPages:init()
	if not self.width then
		self.width = Screen:getWidth()
	end
	if not self.height then
		self.height = Screen:getHeight()
	end

	local vertical_group = VerticalGroup:new({})

	local frame_padding = Size.padding.default
	self.inner_width = self.width - 2 * self.bordersize - 2 * self.padding - 2 * self.margin
	self.inner_height = self.height - 2 * self.bordersize - 2 * self.padding - 2 * self.margin

	local icon_width = Screen:scaleBySize(DGENERIC_ICON_SIZE)

	if self.title then
		local left_icon_button
		if self.left_icon and self.left_icon_2 then
			left_icon_button = HorizontalGroup:new({
				IconButton:new({
					icon = self.left_icon,
					width = icon_width,
					height = icon_width,
					callback = self.left_icon_tap_callback,
					allow_flash = false,
					show_parent = self.show_parent,
				}),
				HorizontalSpan:new({
					width = icon_width,
				}),
				IconButton:new({
					icon = self.left_icon_2,
					width = icon_width,
					height = icon_width,
					callback = self.left_icon_2_tap_callback,
					allow_flash = false,
					show_parent = self.show_parent,
				}),
			})
		elseif self.left_icon then
			left_icon_button = HorizontalGroup:new({
				IconButton:new({
					icon = self.left_icon,
					width = icon_width,
					height = icon_width,
					callback = self.left_icon_tap_callback,
					allow_flash = false,
					show_parent = self.show_parent,
				}),
				HorizontalSpan:new({
					width = 2 * icon_width,
				}),
			})
		else
			left_icon_button = HorizontalSpan:new({
				width = 3 * icon_width,
			})
		end
		local right_icon_button
		if self.close_callback then
			right_icon_button = HorizontalGroup:new({
				HorizontalSpan:new({
					width = 2 * icon_width,
				}),
				IconButton:new({
					icon = "close",
					width = icon_width,
					height = icon_width,
					callback = function()
						self:toClose()
						self.close_callback()
					end,
					allow_flash = false,
					show_parent = self.show_parent,
				}),
			})
		else
			right_icon_button = HorizontalSpan:new({
				width = 3 * icon_width,
			})
		end

		self.titlebar = HorizontalGroup:new({
			left_icon_button,
			TextBoxWidget:new({
				text = self.title,
				face = Font:getFace("smalltfont"),
				width = self.inner_width - 6 * icon_width - 2 * frame_padding,
				alignment = "center",
			}),
			right_icon_button,
		})
		table.insert(
			vertical_group,
			FrameContainer:new({
				padding = frame_padding,
				bordersize = 0,
				self.titlebar,
			})
		)
		table.insert(
			vertical_group,
			LineWidget:new({
				dimen = Geom:new({ w = self.inner_width, h = Size.line.thin }),
				background = Blitbuffer.COLOR_DARK_GRAY,
			})
		)

		self.inner_height = self.inner_height - self.titlebar:getSize().h - Size.line.thin - 2 * frame_padding
	end

	if self.page then
		self.page_navigation_widget = HorizontalGroup:new({
			IconButton:new({
				icon = "chevron.left",
				width = icon_width,
				height = icon_width,
				callback = function()
					self.page = math.max(1, self.page - 1)
					if self.page_turn_callback then
						self.page_turn_callback(self.page)
					end
					self:refresh_content()
				end,
				allow_flash = true,
				show_parent = self.show_parent,
			}),
			TextBoxWidget:new({
				text = string.format("Page %s/%s", self.page, self.pages),
				face = Font:getFace("x_smalltfont"),
				width = self.inner_width - 2 * frame_padding - 2 * icon_width,
				alignment = "center",
				padding = 0,
			}),
			IconButton:new({
				icon = "chevron.right",
				width = icon_width,
				height = icon_width,
				callback = function()
					self.page = math.min(self.pages or math.huge, self.page + 1)
					if self.page_turn_callback then
						self.page_turn_callback(self.page)
					end
					self:refresh_content()
				end,
				allow_flash = true,
				show_parent = self.show_parent,
			}),
		})

		table.insert(
			vertical_group,
			FrameContainer:new({
				padding = frame_padding,
				bordersize = 0,
				self.page_navigation_widget,
			})
		)
		table.insert(
			vertical_group,
			LineWidget:new({
				dimen = Geom:new({ w = self.inner_width, h = Size.line.thin }),
				background = Blitbuffer.COLOR_GRAY,
			})
		)

		self.inner_height = self.inner_height
			- self.page_navigation_widget:getSize().h
			- Size.line.thin
			- 2 * frame_padding
	end

	table.insert(
		vertical_group,
		VerticalSpan:new({
			width = Size.padding.default,
		})
	)
	self.inner_height = self.inner_height - 2 * Size.padding.default

	self.scrollable_container = ScrollableContainer:new({
		dimen = Geom:new({
			w = self.inner_width,
			h = self.inner_height,
		}),
		show_parent = self.show_parent,
	})
	self.show_parent.cropping_widget = self.scrollable_container

	local scrollbar_width = self.scrollable_container:getScrollbarWidth()
	if self.mirror_scrollbar_gap then
		self.content_width = self.inner_width - 2 * scrollbar_width
		self.scrollable_container.dimen.w = self.scrollable_container.dimen.w - scrollbar_width
		table.insert(
			vertical_group,
			HorizontalGroup:new({
				HorizontalSpan:new({ width = scrollbar_width }),
				self.scrollable_container,
			})
		)
	else
		self.content_width = self.inner_width - scrollbar_width
		table.insert(vertical_group, self.scrollable_container)
	end

	if self.content_generator then
		self.content = self.content_generator(self.content_width, self, self.page)
		self:updatePageDisplay()
	end

	self.layout = self.content.layout
	table.insert(self.scrollable_container, self.content)

	self:generateStepScrollGrid()

	local frame = FrameContainer:new({
		width = self.width,
		height = self.height,
		background = Blitbuffer.COLOR_WHITE,
		bordersize = self.bordersize,
		padding = self.padding,
		radius = self.radius,
		margin = self.margin,
		vertical_group,
	})

	self.dimen = frame:getSize()
	self.ges_events.Tap = {
		GestureRange:new({
			ges = "tap",
			range = self.dimen,
		}),
	}

	self[1] = frame
end

function ScrollingPages:generateStepScrollGrid()
	local step_scroll_grid = {}
	local vertical_group = self.content
	local size = vertical_group:getSize() -- generates the _offsets field
	local offsets = vertical_group._offsets
	local idx = 1
	while idx + 2 <= #vertical_group do
		local top = offsets[idx].y
		local bottom = idx + 2 <= #vertical_group and offsets[idx + 2].y - 1 or size.h - 1

		while top < bottom do
			-- add extra steps when items are longer than the cropping area
			local height = math.min(bottom - top, self.inner_height * 0.67)
			table.insert(step_scroll_grid, {
				top = top,
				bottom = top + height,
			})
			top = top + height
		end

		idx = idx + 2
	end

	self.scrollable_container.step_scroll_grid = step_scroll_grid
end

function ScrollingPages:toClose()
	if self.focused and self.focused:isKeyboardVisible() then
		self.focused:onCloseKeyboard()
	end
end

function ScrollingPages:onTap(_arg, ges)
	if self.focused and self.focused:isKeyboardVisible() then
		if
			self.focused.keyboard
			and self.focused.keyboard.dimen
			and ges.pos:notIntersectWith(self.focused.keyboard.dimen)
		then
			self.focused:unfocus()
			UIManager:setDirty(self.focused, "ui")
			self.focused:onCloseKeyboard()
			self.focused = nil
			self.scrollable_container._crop_h = self.inner_height
		end
	end
end

function ScrollingPages:onSwitchFocus(inputbox)
	if self.focused then
		self.focused:unfocus()
		UIManager:setDirty(self.focused, "ui")
		self.focused:onCloseKeyboard()
	end

	self.focused = inputbox
	self.focused:focus()
	UIManager:setDirty(self.focused, "ui")

	if (Device:hasKeyboard() or Device:hasScreenKB()) and G_reader_settings:isFalse("virtual_keyboard_enabled") then
		-- do not load virtual keyboard when user is hiding it.
		return
	end
	self.focused:onShowKeyboard()
	UIManager:tickAfterNext(function()
		self.scrollable_container._crop_h = self.inner_height - self.focused.keyboard.dimen.h
		self:scrollToFocused()
	end)
end

function ScrollingPages:scrollToFocused()
	if self.focused and self.focused.dimen and self.focused.keyboard and self.focused.keyboard.height then
		local scrolled_offset = self.scrollable_container:getScrolledOffset()
		local focused_bottom = self.focused.dimen.y + self.focused.dimen.h
		-- assuming virtual keyboard is anchored and bottom
		-- can't use self.keyboard.dimen as only accurate once UIManager has processed show command
		if focused_bottom > Screen:getHeight() - self.focused.keyboard.height then
			local new_scrolled_offset = Geom:new({
				x = scrolled_offset.x,
				y = scrolled_offset.y + self.focused.dimen.y - self.scrollable_container.dimen.y,
			})
			local top = 0
			-- get closest step_scroll_grid offset
			for _, offset in ipairs(self.scrollable_container.step_scroll_grid or {}) do
				if offset.top <= new_scrolled_offset.y then
					top = offset.top
				else
					new_scrolled_offset.y = top
					break
				end
			end
			self.scrollable_container:setScrolledOffset(new_scrolled_offset)
			UIManager:setDirty(self.scrollable_container, "ui")
		end
	end
end

function ScrollingPages:updatePageDisplay()
	if self.page_navigation_widget and self.page_navigation_widget[2] and self.page_navigation_widget[2].setText then
		self.page_navigation_widget[2]:setText(string.format("Page %s/%s", self.page, self.pages))
		UIManager:setDirty(self.show_parent, "ui")
	end
end

function ScrollingPages:refresh_content()
	if self.focused and self.focused:isKeyboardVisible() then
		self.focused:onCloseKeyboard()
	end

	if self.content_generator then
		self.content = self.content_generator(self.content_width, self, self.page)
	end

	self:updatePageDisplay()

	self.scrollable_container[1] = self.content
	self.scrollable_container:reset()
	self.layout = self.content.layout
	self:generateStepScrollGrid()

	UIManager:setDirty(self.show_parent, "ui")
end

return ScrollingPages
