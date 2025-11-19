local UIManager = require("ui/uimanager")
local random = require("random")
local logger = require("logger")
local InfoPopup = require("info_popup")

local DialogManager = {
	open_dialogs = {},
	info_popups = {},
}

function DialogManager:show(dialog)
	if not dialog then
		logger.warn("DialogManager: called show with nil argument")
		return nil
	end

	UIManager:show(dialog)
	table.insert(self.open_dialogs, dialog)
	return dialog
end

function DialogManager:untrack(dialog)
	for i, open_dialog in ipairs(self.open_dialogs) do
		if open_dialog == dialog then
			table.remove(self.open_dialogs, i)
			return
		end
	end
	logger.err("DialogManager: called untrack with untracked dialog")
end

function DialogManager:close(dialog)
	for i, open_dialog in ipairs(self.open_dialogs) do
		if open_dialog == dialog then
			table.remove(self.open_dialogs, i)
			UIManager:close(dialog)
			return
		end
	end

	logger.err("DialogManager: closing untracked dialog")
	UIManager:close(dialog)
end

function DialogManager:closeAll()
	for _, open_dialog in ipairs(self.open_dialogs) do
		UIManager:close(open_dialog)
	end

	self.open_dialogs = {}

	for _, info_popup in ipairs(self.info_popups) do
		UIManager:close(info_popup)
	end

	self.info_popups = {}
end

function DialogManager:showInfo(text)
	local id = random.uuid()
	local close_fn = function()
		for i, popup in ipairs(self.info_popups) do
			if popup.id == id then
				table.remove(self.info_popups, i)
				UIManager:close(popup.widget)
				if self.info_popups and self.info_popups[1] then
					UIManager:show(self.info_popups[1].widget)
				end
				return
			end
		end
		logger.err("attempt to close an already closed popup with text: %s", text)
	end

	local info_popup = InfoPopup:new({
		text = text,
		tap_close_callback = close_fn,
	})

	table.insert(self.info_popups, { id = id, widget = info_popup })

	UIManager:show(info_popup)

	return close_fn
end

function DialogManager:showErr(text)
	text = "Error: " .. text

	self:showInfo(text)
end

return DialogManager
