local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local random = require("random")
local logger = require("logger")

local DialogManager = {
	open_dialogs = {},
	info_messages = {},
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
	UIManager:setDirty(dialog, "ui")
end

function DialogManager:closeAll()
	for _, open_dialog in ipairs(self.open_dialogs) do
		UIManager:close(open_dialog)
	end

	self.open_dialogs = {}

	for _, info_message in ipairs(self.info_messages) do
		UIManager:close(info_message)
	end

	self.info_messages = {}

	UIManager:setDirty("all", "ui")
end

function DialogManager:showInfo(text)
	local id = random.uuid()
	local close_fn = function()
		for i, popup in ipairs(self.info_messages) do
			if popup.id == id then
				table.remove(self.info_messages, i)
				UIManager:close(popup.widget)
				UIManager:setDirty("all", "ui")
				if self.info_messages and self.info_messages[1] then
					UIManager:show(self.info_messages[1].widget)
				end
				return
			end
		end
	end

	local info_message = InfoMessage:new({
		text = text,
		show_icon = false,
		dismissable = true,
		dismiss_callback = close_fn,
	})

	table.insert(self.info_messages, { id = id, widget = info_message })

	UIManager:show(info_message)

	return close_fn
end

function DialogManager:showErr(text)
	text = "Error: " .. text

	self:showInfo(text)
end

return DialogManager
