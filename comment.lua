local Screen = require("device").screen
local Size = require("ui/size")
local Font = require("ui/font")
local GestureRange = require("ui/gesturerange")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local InputContainer = require("ui/widget/container/inputcontainer")
local FrameContainer = require("ui/widget/container/framecontainer")

local Comment = InputContainer:extend({
	width = nil,
	depth = 0,
	text = nil,
	author = nil,
	datetime = nil,
	comment_id = nil,
	on_tap_callback = nil,
})

function Comment:init()
	local padding = Size.padding.default
	local offset = self.depth * Screen:scaleBySize(15)

	local comment_width = self.width - offset - 2 * padding
	local datetime = TextWidget:new({

		face = Font:getFace("xx_smallinfofont"),
		text = self.datetime,
	})
	local vertical_group = VerticalGroup:new({
		HorizontalGroup:new({
			align = "top",
			TextBoxWidget:new({
				face = Font:getFace("x_smallinfofont"),
				text = self.author,
				width = comment_width - datetime:getSize().w,
			}),
			datetime,
		}),

		VerticalSpan:new({
			width = Size.span.vertical_default,
		}),

		TextBoxWidget:new({
			face = Font:getFace("x_smallinfofont"),
			text = self.text,
			width = comment_width,
		}),
	})

	local frame = FrameContainer:new({
		bordersize = 0,
		padding = padding,
		HorizontalGroup:new({ HorizontalSpan:new({ width = offset }), vertical_group }),
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

function Comment:onTapSelectButton(_args, _ges)
	if self.on_tap_callback then
		self.on_tap_callback(self.comment_id)
	end
end

return Comment
