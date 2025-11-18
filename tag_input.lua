local Button = require("ui/widget/button")
local Device = require("device")
local Font = require("ui/font")
local FocusManager = require("ui/widget/focusmanager")
local InputText = require("ui/widget/inputtext")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local Size = require("ui/size")
local IconButton = require("ui/widget/iconbutton")
local TextWidget = require("ui/widget/textwidget")
local LineWidget = require("ui/widget/linewidget")
local UIManager = require("ui/uimanager")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local CenterContainer = require("ui/widget/container/centercontainer")
local Web = require("web")
local Screen = Device.screen
local logger = require("logger")
local T = require("gettext")

local ScrollingPages = require("scrolling_pages")

local DGENERIC_ICON_SIZE = G_defaults:readSetting("DGENERIC_ICON_SIZE")

local TagInput = FocusManager:extend({
	title = nil,
	tags = "",
	type = nil,
	width = nil,
	close_callback = nil,
	is_always_active = true,
	focused = nil,
	show_parent = nil,
})

function TagInput:init()
	if not self.width then
		self.width = Screen:getWidth() * 0.75
	end
	if not self.height then
		self.height = Screen:getHeight() * 0.75
	end
	if not self.show_parent then
		self.show_parent = self
	end
	if self.tags and type(self.tags) == "string" then
		local tags = {}
		for tag in string.gmatch(self.tags, " *[^,]+ *[,$]") do
			table.insert(tags, { name = tag, id = tag })
		end

		self.tags = tags
	end

	self.ges_events.Tap = {
		GestureRange:new({
			ges = "tap",
			range = Geom:new({
				x = 0,
				y = 0,
				w = Screen:getWidth(),
				h = Screen:getHeight(),
			}),
		}),
	}
	if self[1] and self[1].toClose then
		self[1]:toClose()
	end

	local scrolling_pages = ScrollingPages:new({
		title = self.title,
		width = self.width,
		height = self.height,
		bordersize = Size.border.window,
		radius = Size.radius.window,
		padding = 0,

		mirror_scrollbar_gap = true,
		content_generator = function(width, container, page)
			local icon_width = Screen:scaleBySize(DGENERIC_ICON_SIZE) / 2

			self.input = InputText:new({
				text = "",
				face = Font:getFace("infofont"),
				width = width - 2 * Size.border.inputtext - 2 * icon_width,
				scroll = false,
				focused = false,
				padding = 0,
				margin = 0,
				parent = self.show_parent,
			})

			local showSuggestions
			showSuggestions = function(suggestions)
				local vertical_group = VerticalGroup:new({})

				local addSeparator = function(with_line)
					if with_line then
						table.insert(
							vertical_group,
							VerticalGroup:new({
								VerticalSpan:new({
									width = Size.span.vertical_default,
								}),
								LineWidget:new({
									dimen = Geom:new({
										w = width,
										h = Size.line.thin,
									}),
								}),
							})
						)
					else
						table.insert(
							vertical_group,
							VerticalSpan:new({
								width = Size.span.vertical_default,
							})
						)
					end
				end

				for i, tag in ipairs(self.tags) do
					local close_button = IconButton:new({
						icon = "close",

						width = icon_width,
						height = icon_width,
						padding = icon_width / 2,
						padding_h = icon_width,
						callback = function()
							table.remove(self.tags, i)
							showSuggestions({})
						end,
					})
					local label = TextWidget:new({
						text = tag.name,
						face = Font:getFace("infofont"),
						width = width - close_button:getSize().w,
					})
					table.insert(
						vertical_group,
						HorizontalGroup:new({
							label,
							close_button,
						})
					)
					addSeparator()
				end

				table.insert(
					vertical_group,
					HorizontalGroup:new({
						self.input,
						IconButton:new({
							icon = "plus",

							width = icon_width,
							height = icon_width,
							padding = icon_width / 2,
							callback = function()
								local text = self.input.text
								table.insert(self.tags, { name = text, id = text })
								self.input:delAll()
								showSuggestions({})
							end,
						}),
					})
				)
				addSeparator()

				for _, suggestion in ipairs(suggestions or {}) do
					local button = Button:new({
						text = suggestion.name,
						width = width,
						bordersize = 0,
						margin = 0,
						padding = 0,
						callback = function()
							self.input:delAll()
							table.insert(self.tags, suggestion)
							showSuggestions({})
						end,
					})
					table.insert(vertical_group, button)
					addSeparator(true)
				end

				container.scrollable_container[1] = vertical_group
				container.scrollable_container:reset()
				UIManager:setDirty("all", "ui")
			end

			self.input.edit_callback = function()
				local text = self.input.text
				UIManager:scheduleIn(1, function()
					if self and self.input and text == self.input.text and text ~= "" then
						local suggestions = Web:autocomplete(self.type, text)
						showSuggestions(suggestions)
					end
				end)
			end

			showSuggestions({})

			return container.scrollable_container[1]
		end,
		show_parent = self,
	})

	self[1] = CenterContainer:new({
		dimen = Screen:getSize(),
		scrolling_pages,
	})
end

function TagInput:toClose()
	if self[1] and self[1][1] and self[1][1].toClose then
		self[1][1]:toClose()
	end
end

function TagInput:onTap(arg, ges)
	if self[1] and self[1][1] and self[1][1].onTap then
		self[1][1]:onTap(arg, ges)
	end
	if self[1] and self[1][1] and ges.pos:notIntersectWith(self[1][1].dimen) and self.close_callback then
		self:toClose()
		self.close_callback()
	end
end

function TagInput:onSwitchFocus(focus)
	if self[1] and self[1][1] and self[1][1].onSwitchFocus then
		self[1][1]:onSwitchFocus(focus)
	end
end

function TagInput.tagsToString(tags)
	local t = {}
	for _, tag in ipairs(tags) do
		table.insert(t, tag.id)
	end

	return table.concat(t, ",")
end

return TagInput
