local UIManager = require("ui/uimanager")
local logger = require("logger")

local DialogManager = {
	open_dialogs = {},
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
end

return DialogManager
