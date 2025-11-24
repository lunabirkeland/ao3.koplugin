local InputContainer = require("ui/widget/container/inputcontainer")
local ReaderUI = require("apps/reader/readerui")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local T = require("gettext")
local Search = require("search")
local util = require("util")
local Web = require("web")
local Comments = require("comments")
local DownloadDialog = require("download_dialog")
local DialogManager = require("dialog_manager")
local Updates = require("updates")

logger.info("Loading AO3 plugin...")

local AO3 = InputContainer:extend({
	name = "ao3",
	plugin_path = nil,
})

-- We can get initialized from two contexts:
-- - when the `FileManager` is initialized, we're called
-- - when the `ReaderUI` is initialized, we're also called
-- so we should register to the menu accordingly
function AO3:init()
	local full_source_path = debug.getinfo(1, "S").source
	if full_source_path:sub(1, 1) == "@" then
		full_source_path = full_source_path:sub(2)
	end

	self.plugin_path = util.splitFilePathName(full_source_path):gsub("/+", "/")
	Web:init()

	if self.ui and self.ui.menu then
		self.ui.menu:registerToMainMenu(self)
	else
		logger.warn("self.ui or self.ui.menu not initialized in AO3:init")
	end
end

function AO3:addToMainMenu(menu_items)
	local getCurrentFic = function()
		local file
		if ReaderUI and ReaderUI.instance and ReaderUI.instance.document and ReaderUI.instance.document.file then
			file = ReaderUI.instance.document.file
		else
			logger.err("failed to get current file")
			DialogManager:showErr(T("Failed to get current fic\nFic must be open"))
			return
		end

		local id, updated = file:match("/[%w_]+%-(%d+)%-(%d+)%.%w+$")

		if not (id and updated) then
			logger.err("file name not of expected format")
			DialogManager:showErr(T("Failed to get current fic\nFic must have been downloaded by this plugin"))
			return nil
		end

		return 1, id, updated
	end
	menu_items.ao3 = {
		text = T("AO3"),
		sorting_hint = "search",
		sub_item_table = {
			{
				text = T("This fic"),
				keep_menu_open = true,
				sub_item_table = {
					{
						text = T("Leave kudos"),
						callback = function()
							local result, id, _updated = getCurrentFic()

							if not result then
								return
							end

							local close_info = DialogManager:showInfo(T("Leaving kudos"))
							UIManager:nextTick(function()
								Web:giveKudos(id)
								UIManager:nextTick(close_info)
							end)
						end,
					},
					{
						text = T("Comments"),
						callback = function()
							local result, id, _updated = getCurrentFic()

							if not result then
								return
							end

							local dialog = Comments:new({ work_id = id })
							dialog.close_callback = function()
								DialogManager:close(dialog)
							end
							DialogManager:show(dialog)
						end,
					},
					{
						text = T("Check for updates"),
						callback = function()
							local result, id, updated = getCurrentFic()

							if not result then
								return
							end

							local close_info = DialogManager:showInfo(T("Checking for fic updates"))
							UIManager:nextTick(function()
								local has_updates = Web:checkForFicUpdates(id, updated)
								UIManager:nextTick(close_info)

								if has_updates then
									local dialog = DownloadDialog:new({
										title = T("Fic has updates"),
										id = id,
									})
									dialog.close_callback = function()
										DialogManager:close(dialog)
									end
									DialogManager:show(dialog)
								elseif has_updates == nil then
									DialogManager:showErr(T("Failed to get fic updates"))
								end
							end)
						end,
					},
				},
			},
			{
				text = T("Search works"),

				callback = function()
					local dialog = Search:new({
						plugin_path = self.plugin_path,
					})
					dialog.close_callback = function()
						DialogManager:close(dialog)
					end

					DialogManager:show(dialog)
				end,
			},
			{
				text = T("Check for updates"),
				callback = function()
					local dialog = Updates:new({
						plugin_path = self.plugin_path,
					})
					dialog.close_callback = function()
						DialogManager:close(dialog)
					end

					DialogManager:show(dialog)
				end,
			},
		},
	}
end

return AO3
