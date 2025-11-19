local Blitbuffer = require("ffi/blitbuffer")
local Size = require("ui/size")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local CenterContainer = require("ui/widget/container/centercontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local Device = require("device")
local FrameContainer = require("ui/widget/container/framecontainer")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local Screen = Device.screen
local logger = require("logger")

local InfoPopup = InputContainer:extend({
	text = nil,
	is_always_active = true,
	tap_close_callback = nil,
	toast = true, -- tells UIManager to show at front of stack
})

function InfoPopup:init()
	local width = Screen:getWidth() * 0.75
	local text_widget = TextWidget:new({
		text = self.text,
		face = Font:getFace("cfont"),
	})

	if text_widget:getWidth() > width then
		text_widget:free()
		text_widget = TextBoxWidget:new({

			text = self.text,
			face = Font:getFace("cfont"),
			alignment = "center",
		})
	end

	self.ges_events = {
		TapClose = {
			GestureRange:new({
				ges = "tap",
				range = Geom:new({
					x = 0,
					y = 0,
					w = Screen:getWidth(),
					h = Screen:getHeight(),
				}),
			}),
		},
	}

	self[1] = CenterContainer:new({
		dimen = Screen:getSize(),
		FrameContainer:new({

			radius = Size.radius.window,
			bordersize = Size.border.window,
			padding = Size.padding.default,
			margin = 0,
			background = Blitbuffer.COLOR_WHITE,
			text_widget,
		}),
	})
end

function InfoPopup:onTapClose(_arg, _ges)
	if self.tap_close_callback then
		self.tap_close_callback()
	end

	return true
end

return InfoPopup
