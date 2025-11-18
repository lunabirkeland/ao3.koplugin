local Blitbuffer = require("ffi/blitbuffer")
local ButtonTable = require("ui/widget/buttontable")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Font = require("ui/font")
local FocusManager = require("ui/widget/focusmanager")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local Size = require("ui/size")
local DownloadMgr = require("ui/downloadmgr")
local TextBoxWidget = require("ui/widget/textboxwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local ReaderUI = require("apps/reader/readerui")
local Web = require("web")
local Screen = Device.screen
local logger = require("logger")
local T = require("gettext")
local DialogManager = require("dialog_manager")

local DownloadDialog = FocusManager:extend({
	title = nil,
	id = nil,
	work = nil,
	width = nil,
	close_callback = nil,
})

function DownloadDialog:init()
	if not self.width then
		self.width = Screen:getWidth() * 0.75
	end
	self.ges_events.TapClose = {
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

	self.title = FrameContainer:new({
		bordersize = 0,
		TextBoxWidget:new({
			text = self.title,
			width = self.width,
			face = Font:getFace("infofont"),
		}),
	})

	self:showMainPage()
end

function DownloadDialog:showMainPage()
	local buttontable = ButtonTable:new({
		buttons = {
			{
				{
					text = T("Download and open"),
					callback = function()
						local filepath = Web:download(self.id)

						if self.close_callback then
							self.close_callback()
						end
						DialogManager:closeAll()

						if ReaderUI then
							UIManager:tickAfterNext(function()
								ReaderUI:showReader(filepath)
							end)
						else
							logger.err("ReaderUI missing")
						end
					end,
				},
			},
			{
				{
					text = T("Download"),
					callback = function()
						Web:download(self.id)

						if self.close_callback then
							self.close_callback()
						end
					end,
				},
			},
			{
				{
					text = T("Filetype: ") .. Web.filetype,
					callback = function()
						self:showFileTypes()
					end,
				},
			},
			{
				{
					text = T("Download directory: ") .. Web.download_dir,
					callback = function()
						self:showDownloadDir()
					end,
				},
			},
		},
		width = self.width,
		show_parent = self,
	})

	self.frame = FrameContainer:new({
		background = Blitbuffer.COLOR_WHITE,
		bordersize = Size.border.window,
		radius = Size.radius.window,
		-- padding = Size.padding.button,
		-- padding_top = 0,
		-- padding_bottom = 0,
		VerticalGroup:new({
			self.title,
			buttontable,
		}),
	})

	self[1] = CenterContainer:new({
		dimen = Screen:getSize(),
		self.frame,
	})
	UIManager:setDirty("all", "ui")
end

function DownloadDialog:showFileTypes()
	local filetypes = { "azw3", "epub", "mobi", "pdf", "html" }
	local buttons = {}
	for _, filetype in ipairs(filetypes) do
		table.insert(buttons, {
			{

				text = filetype,
				callback = function()
					Web.filetype = filetype
					self:showMainPage()
				end,
			},
		})
	end

	local buttontable = ButtonTable:new({
		buttons = buttons,
		width = self.width,
		show_parent = self,
	})

	self.frame = FrameContainer:new({
		background = Blitbuffer.COLOR_WHITE,
		bordersize = Size.border.window,
		radius = Size.radius.window,
		VerticalGroup:new({
			self.title,
			buttontable,
		}),
	})

	self[1] = CenterContainer:new({
		dimen = Screen:getSize(),
		self.frame,
	})
	UIManager:setDirty("all", "ui")
end

function DownloadDialog:showDownloadDir()
	DownloadMgr:new({
		title = T("Select AO3 Download Directory"),
		onConfirm = function(path)
			if path then
				Web.download_dir = path
				logger.info(string.format(T("Download directory set to: %s"), path))
				self:showMainPage()
			else
				logger.err("No directory selected")
			end
		end,
	}):chooseDir(Web.download_dir)
end

function DownloadDialog:onTapClose(arg, ges)
	if ges.pos:notIntersectWith(self.frame.dimen) then
		if self.close_callback then
			self.close_callback()
		end
	end
	return true
end

return DownloadDialog
