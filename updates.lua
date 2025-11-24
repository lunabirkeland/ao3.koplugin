local Blitbuffer = require("ffi/blitbuffer")
local Size = require("ui/size")
local Geom = require("ui/geometry")
local LineWidget = require("ui/widget/linewidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local Button = require("ui/widget/button")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local socketutil = require("socketutil")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local JSON = require("json")
local lfs = require("libs/libkoreader-lfs")
local T = require("gettext")
local DataStorage = require("datastorage")
local util = require("util")
local io = require("io")

local Web = require("web")
local DownloadDialog = require("download_dialog")
local DialogManager = require("dialog_manager")
local ScrollingPages = require("scrolling_pages")

local Updates = WidgetContainer:extend({
	plugin_path = nil,
	close_callback = nil,
})

function Updates.getVersion(plugin_path)
	local ok, result = pcall(dofile, plugin_path .. "_meta.lua")

	if not (ok and result) then
		DialogManager:showError("Failed to get plugin version\nfailed to load _meta.lua")
		logger.err("failed to load _meta.lua")
		return
	end

	local version = result.version:match("%d+%.%d+%.%d+")
	if not version then
		DialogManager:showError(
			string.format("Failed to get plugin version\nversion string of wrong form\n%s", result.version)
		)
		logger.err(string.format("local version string of wrong form %s", result.version))
		return
	end

	return version
end

local function getLatestReleaseInfo()
	local url = "https://api.github.com/repos/lunabirkeland/ao3.koplugin/releases"

	logger.dbg(string.format("request release info from %s", url))
	local t = {}
	local opts = {
		url = url,
		method = "GET",
		sink = ltn12.sink.table(t),
		headers = {
			Accept = "application/vnd.github.v3+json",
			["User-Agent"] = Web.user_agent,
		},
	}
	local r, c, h = https.request(opts)
	logger.dbg(string.format("received response: %s, %s, %s", r, c, h))
	local body = table.concat(t)
	logger.dbg(string.format("with body: %s", body))

	local ret, json = pcall(JSON.decode, table.concat(t))
	if not (ret and json) then
		logger.err("failed to parse json from " .. url .. table.concat(t))
		return
	end

	if not json[1] then
		logger.err(string.format("empty json responce from %s", url))
		return
	end

	local version_tag = json[1].tag_name
	if not version_tag then
		logger.err("tag_name missing from release info")
		return
	end

	local version = version_tag:match("v(%d+%.%d+%.%d+)")
	if not version then
		logger.err(string.format("remote version string of wrong form %s", version_tag))
		return
	end

	return json[1]
end

local function isNewer(remote_version, local_version)
	local local_v1, local_v2, local_v3 = local_version:match("(%d+)%.(%d+)%.(%d+)")
	local remote_v1, remote_v2, remote_v3 = remote_version:match("(%d+)%.(%d+)%.(%d+)")
	if tonumber(remote_v1) > tonumber(local_v1) then
		return true
	elseif tonumber(remote_v1) < tonumber(local_v1) then
		logger.err(
			string.format("local plugin version higher version than remote, %s, %s", local_version, remote_version)
		)
		return false
	end
	if tonumber(remote_v2) > tonumber(local_v2) then
		return true
	elseif tonumber(remote_v2) < tonumber(local_v2) then
		logger.err(
			string.format("local plugin version higher version than remote, %s, %s", local_version, remote_version)
		)
		return false
	end
	if tonumber(remote_v3) > tonumber(local_v3) then
		return true
	elseif tonumber(remote_v3) < tonumber(local_v3) then
		logger.err(
			string.format("local plugin version higher version than remote, %s, %s", local_version, remote_version)
		)
		return false
	end
	return false
end

local function updatePlugin(release, plugin_path)
	local download_dir = DataStorage:getDataDir() .. "/cache/"
	lfs.mkdir(download_dir)

	if
		not (release.assets and release.assets[1] and release.assets[1].name and release.assets[1].browser_download_url)
	then
		logger.err("failed to get release assets with release %s", release)
		return
	end
	local asset = release.assets[1]

	local download_path = download_dir .. asset.name

	local file, err_open = io.open(download_path, "wb")
	if not file then
		logger.err(string.format("file open error at: %s, with error: %s", download_path, err_open))
		return
	end

	local download_url = asset.browser_download_url
	logger.dbg(string.format("downloading release from %s", download_url))
	local opts = {
		url = download_url,
		method = "GET",
		sink = socketutil.file_sink(file),
		headers = {
			["User-Agent"] = Web.user_agent,
		},
	}
	local r, c, h = https.request(opts)
	logger.dbg(string.format("received response: %s, %s, %s", r, c, h))

	if not download_path or not util.fileExists(download_path) then
		logger.err("no file downloaded")
		return
	end

	if not plugin_path or not util.directoryExists(plugin_path) then
		logger.err(string.format("plugin path missing when updating: %s", plugin_path))
		return
	end

	local base_plugins_dir = plugin_path:match("(.+/)ao3.koplugin/")
	if not base_plugins_dir or not util.directoryExists(base_plugins_dir) then
		logger.err(string.format("plugins dir not found with path %s", plugin_path))
		return
	end

	local extract_command = string.format("tar -xzf '%s' -C '%s'", download_path, base_plugins_dir)

	local extract_ok, extract_error = os.execute(extract_command)

	if not extract_ok then
		logger.err(string.format("failed to extract with error: ", extract_error))
		return
	end

	local rm_ok, rm_err = os.remove(download_path)
	if not rm_ok then
		logger.err(string.format("failed to delete downloaded update with error: %s", rm_err))
		return
	end

	DialogManager:showInfo("Plugin successfully updated, restart koreader to take affect")
end

local function getFics()
	local fics = {}
	for file in lfs.dir(Web.download_dir) do
		local name, work_id, updated, extension = file:match("(.*)%-(%d+)-(%d+)%.([%w_]+)")
		if not (name and work_id and updated and extension) then
			goto continue
		end

		local valid_extension
		for _, x in ipairs({ "azw3", "epub", "mobi", "pdf", "html" }) do
			if extension == x then
				valid_extension = true
			end
		end
		if not valid_extension then
			goto continue
		end

		table.insert(fics, {
			name = name,
			work_id = work_id,
			updated = updated,
			extension = extension,
		})
		::continue::
	end

	return fics
end

local function getFicsWithUpdates()
	local fics = getFics()
	local fics_with_updates = {}

	for _, fic in ipairs(fics) do
		if Web:checkForFicUpdates(fic.work_id, fic.updated) then
			table.insert(fics_with_updates, fic)
		else
			for i, fic_with_update in ipairs(fics_with_updates) do
				if fic.work_id == fic_with_update.work_id then
					table.remove(fics_with_updates, i)
				end
			end
		end
	end

	return fics_with_updates
end

function Updates:init()
	local scrolling_pages = ScrollingPages:new({
		title = T("Updates"),
		close_callback = function()
			if self.close_callback then
				self:close_callback()
			end
		end,

		content_generator = function(width, container, page)
			local close_info = DialogManager:showInfo(T("Fetching updates"))
			UIManager:nextTick(function()
				local release_info = getLatestReleaseInfo()
				local remote_version = release_info and release_info.tag_name:match("v(%d+%.%d+%.%d+)")
				local local_version = Updates.getVersion(self.plugin_path)

				local available_plugin_update = false
				if remote_version and local_version then
					available_plugin_update = isNewer(remote_version, local_version)
				end

				if available_plugin_update then
					DialogManager:showInfo(
						string.format("Available plugin update v%s -> v%s", local_version, remote_version)
					)
				end

				local fics_with_updates = getFicsWithUpdates()

				UIManager:nextTick(close_info)

				local vertical_group = VerticalGroup:new({
					align = "left",
					width = width,
				})

				if available_plugin_update then
					table.insert(
						vertical_group,
						Button:new({
							text = string.format(
								T("Available plugin update:") .. " v%s -> v%s",
								local_version,
								remote_version
							),
							width = width,
							bordersize = 0,
							padding = 0,
							callback = function()
								logger.info(
									string.format("updating ao3.koplugin from %s to %s", local_version, remote_version)
								)
								updatePlugin(release_info, self.plugin_path)
							end,
						})
					)
					table.insert(
						vertical_group,
						VerticalGroup:new({
							LineWidget:new({
								background = Blitbuffer.COLOR_DARK_GRAY,
								dimen = Geom:new({
									w = width,
									h = Size.line.thick,
								}),
							}),
							VerticalSpan:new({
								width = Size.span.vertical_large,
							}),
						})
					)
				end

				for _, fic in ipairs(fics_with_updates or {}) do
					table.insert(
						vertical_group,
						Button:new({
							text = fic.name,
							width = width,
							bordersize = 0,
							padding = 0,
							callback = function()
								local dialog = DownloadDialog:new({
									title = T("Fic has updates"),
									id = fic.work_id,
								})
								dialog.close_callback = function()
									UIManager:setDirty(dialog, "ui")
									DialogManager:close(dialog)
								end
								DialogManager:show(dialog)
							end,
						})
					)
					table.insert(
						vertical_group,
						VerticalGroup:new({
							LineWidget:new({
								background = Blitbuffer.COLOR_DARK_GRAY,
								dimen = Geom:new({
									w = width,
									h = Size.line.thick,
								}),
							}),
							VerticalSpan:new({
								width = Size.span.vertical_large,
							}),
						})
					)
				end

				container:setContent(vertical_group)
			end)
			return VerticalGroup:new({
				width = width,
			})
		end,
		show_parent = self,
	})

	self[1] = scrolling_pages
end

return Updates
