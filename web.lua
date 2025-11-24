local https = require("ssl.https")
local socketutil = require("socketutil")
local ltn12 = require("ltn12")
local JSON = require("json")
local htmlparser = require("htmlparser")
local lfs = require("libs/libkoreader-lfs")
local logger = require("logger")
local Cookies = require("cookies")

local Web = {
	filetype = "epub",
	download_dir = nil,
	cookies = nil,
	user_agent = "ao3.koreader",
}

function Web:init()
	if not self.cookies then
		self.cookies = Cookies:new({ view_adult = true })
	end

	if not self.download_dir then
		self.download_dir = (
			(G_reader_settings:readSetting("home_dir") or require("apps/filemanager/filemanagerutil").getDefaultDir())
			.. "/ao3/"
		):gsub("/+", "/")
	end
end

function Web:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	if o.init then
		o:init()
	end
	return o
end

function Web.sanitize_response(text)
	local result = text:gsub("&#39;", "'")
		:gsub("&lt;", "<")
		:gsub("&gt;", ">")
		:gsub("&quot;", '"')
		:gsub("&amp;", "&")
		:gsub("<br>", "\n")
		:gsub("<.->", "")
	return result
end

function Web.sanitize_request(text)
	if type(text) ~= "string" then
		text = string.format("%s", text)
	end

	local result = text:gsub("%p", function(match)
		local ignore = { "*", "-", ".", "_" }
		for _, value in ipairs(ignore) do
			if match == value then
				return match
			end
		end

		-- convert to hexadecimal ascii code
		return "%" .. string.format("%X", match:byte())
	end)
	return result:gsub(" ", "+")
end

function Web:search_works(query, page)
	local t = {}

	local url = { "https://archiveofourown.org/works/search?commit=Search" }

	if page then
		table.insert(url, string.format("page=%s", page))
	end

	for key, values in pairs(query) do
		for _, value in ipairs(values) do
			local extra = ""
			if key == "category_ids" or key == "archive_warning_ids" then
				extra = "%5B%5D"
			end
			local parameter = string.format("work_search%%5B%s%%5D%s=%s", key, extra, Web.sanitize_request(value))
			table.insert(url, parameter)
		end
	end

	self:httpsRequest({
		method = "GET",
		url = table.concat(url, "&"),
		sink = ltn12.sink.table(t),
		headers = {
			Accept = "text/html",
		},
	})

	local ret, root = pcall(htmlparser.parse, table.concat(t), 10000)
	if not ret then
		logger.err("failed to parse html from " .. url .. table.concat(t, "\n"))
		return
	end

	local pages = 1
	local pagination = root("#main > ol.pagination")
	if pagination and pagination[1] then
		pages = Web.getPages(pagination[1])
	end

	local selection = root("ol.work.index.group > li")

	local works = {}

	for _, e in ipairs(selection) do
		local work = {}
		work.id = e.id:gsub("work_", "")

		local heading = e("h4.heading > a")
		for _, e2 in ipairs(heading) do
			if e2.attributes.href:find("^/works/") then
				work.title = Web.sanitize_response(e2:getcontent())
			elseif e2.attributes.rel == "author" then
				work.author = Web.sanitize_response(e2:getcontent())
			end
		end
		work.author = work.author or "Anonymous"

		local fandoms = e("h5.fandoms.heading > a")
		work.fandoms = {}
		for _, e2 in ipairs(fandoms) do
			table.insert(work.fandoms, Web.sanitize_response(e2:getcontent()))
		end

		local required_tags = e("ul.required-tags")[1]
		work.required_tags = {}
		if required_tags then
			local rating = required_tags("span.rating")[1]
			work.required_tags.rating = rating and rating.classes[1] or "error"
			local warnings = required_tags("span.warnings")[1]
			work.required_tags.warnings = warnings and warnings.classes[1] or "error"
			local category = required_tags("span.category")[1]
			work.required_tags.category = category and category.classes[1] or "error"
			local complete = required_tags("span.iswip")[1]
			work.required_tags.complete = complete and complete.classes[1] or "error"
		else
			work.required_tags = {
				rating = "error",
				warnings = "error",
				category = "error",
				complete = "error",
			}
		end

		local datetime = e("p.datetime")[1]
		work.datetime = datetime and Web.sanitize_response(datetime:getcontent()) or ""

		local tags = e("ul.tags.commas > li a")
		work.tags = {}
		for _, e2 in ipairs(tags) do
			local content = Web.sanitize_response(Web.sanitize_response(e2:getcontent()))
			-- TODO: bold archive warnings
			table.insert(work.tags, content)
		end

		local summary = e("blockquote.userstuff.summary > p")
		work.summary = {}

		for _, e2 in ipairs(summary) do
			local content = Web.sanitize_response(e2:getcontent())
			table.insert(work.summary, content)
		end
		work.summary = table.concat(work.summary, "\n")

		local stats = e("dl.stats")[1]
		work.stats = {}
		if stats then
			local language = stats("dd.language")[1]
			work.stats.language = language and Web.sanitize_response(language:getcontent()) or nil
			local words = stats("dd.words")[1]
			work.stats.words = words and Web.sanitize_response(words:getcontent()) or nil
			local chapters = stats("dd.chapters")[1]
			work.stats.chapters = chapters and Web.sanitize_response(chapters:getcontent()) or nil
			local collections = stats("dd.collections > a")[1]
			work.stats.collections = collections and Web.sanitize_response(collections:getcontent()) or nil
			local comments = stats("dd.comments > a")[1]
			work.stats.comments = comments and Web.sanitize_response(comments:getcontent()) or nil
			local kudos = stats("dd.kudos > a")[1]
			work.stats.kudos = kudos and Web.sanitize_response(kudos:getcontent()) or nil
			local bookmarks = stats("dd.bookmarks > a")[1]
			work.stats.bookmarks = bookmarks and Web.sanitize_response(bookmarks:getcontent()) or nil
			local hits = stats("dd.hits")[1]
			work.stats.hits = hits and Web.sanitize_response(hits:getcontent()) or nil
		end

		table.insert(works, work)
	end

	return works, pages
end

function Web:autocomplete(type, value)
	local t = {}
	local url = "https://archiveofourown.org/autocomplete/" .. type .. "?term=" .. Web.sanitize_request(value or "")

	self:httpsRequest({
		method = "GET",
		url = url,
		sink = ltn12.sink.table(t),
		headers = {
			Accept = "application/json",
		},
	})

	local ret, result = pcall(JSON.decode, table.concat(t))
	if not ret then
		logger.err("failed to parse json from " .. url .. table.concat(t))
		return
	end

	return result
end

function Web:getDownloadDetails(id)
	local t = {}
	local url = "https://archiveofourown.org/works/" .. id

	self:httpsRequest({
		method = "GET",
		url = url,
		sink = ltn12.sink.table(t),
		headers = {
			Accept = "text/html",
			Cookie = "view_adult=true",
		},
	})

	local ret, root = pcall(htmlparser.parse, table.concat(t), 10000)
	if not ret then
		logger.err("failed to parse html from " .. url .. table.concat(t, "\n"))
		return
	end

	local downloads = root("li.download > ul > li > a")

	local download_ref = nil

	for _, a in ipairs(downloads) do
		local href = a.attributes.href
		if href:match("%." .. self.filetype) then
			download_ref = href
		end
	end

	if not download_ref then
		logger.err(
			"failed to find download url for filetype " .. self.filetype .. " from url " .. url .. table.concat(t, "\n")
		)
		return
	end

	local filename, filetype, updated = string.match(download_ref, "/([%w_]+)%.([%w_]+)%?updated_at=(%d+)$")

	if not (filename and filetype and updated) then
		logger.err(string.format("failed to obtain filename, filetype or updated from: %s", download_ref))
	end

	return download_ref, filename, filetype, updated
end

function Web:download(id)
	local download_ref, filename, filetype, updated = self:getDownloadDetails(id)
	local new_filename = string.format("%s-%s-%s.%s", filename, id, updated, filetype)

	lfs.mkdir(self.download_dir)

	local filepath = (self.download_dir .. "/" .. new_filename):gsub("/+", "/")
	local file, err_open = io.open(filepath, "wb")
	if not file then
		logger.err(string.format("file open error at: %s, with error: %s", filepath, err_open))
		return
	end

	local download_url = "https://download.archiveofourown.org" .. download_ref
	self:httpsRequest({
		method = "GET",
		url = download_url,
		sink = socketutil.file_sink(file),
		headers = {
			Cookie = "view_adult=true",
		},
	})

	return filepath
end

function Web:giveKudos(id)
	local t = {}
	local url = "https://archiveofourown.org/works/" .. id

	-- get works page
	self:httpsRequest({
		method = "GET",
		url = url,
		sink = ltn12.sink.table(t),
		headers = {
			Accept = "text/html",
		},
	})
	local ret, root = pcall(htmlparser.parse, table.concat(t), 10000)
	if not ret then
		logger.err("failed to parse html from " .. url .. table.concat(t, "\n"))
		return
	end

	local kudo_form_inputs = root("#new_kudo > input")

	local data = {}

	for _, input in ipairs(kudo_form_inputs) do
		if input.attributes.name and input.attributes.type == "hidden" then
			data[Web.sanitize_request(input.attributes.name)] = Web.sanitize_request(input.attributes.value)
		end
	end

	local token = self:tokenDispenser()

	if not token then
		logger.err("failed to get token in giveKudos")
		return
	end

	data["authenticity_token"] = token

	-- send kudos
	t = {}
	local data_strings = {}
	for key, value in pairs(data) do
		table.insert(data_strings, string.format("%s=%s", key, value))
	end
	local data_string = table.concat(data_strings, "&")
	local kudos_url = "https://archiveofourown.org/kudos.js"
	self:httpsRequest({
		method = "POST",
		url = kudos_url,
		sink = ltn12.sink.table(t),
		source = ltn12.source.string(data_string),
		headers = {
			["Accept"] = "*/*",
			["Content-Length"] = data_string:len(),
			["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8",
		},
	})
end

function Web:loadComments(work_id, chapter_id, page)
	local t = {}
	local url
	if chapter_id then
		url = string.format(
			"https://archiveofourown.org/works/%s/chapters/%s?page=%s&show_comments=true",
			work_id,
			chapter_id,
			page
		)
	else
		url = string.format("https://archiveofourown.org/works/%s?page=%s&show_comments=true", work_id, page)
	end
	self:httpsRequest({
		method = "GET",
		url = url,
		sink = ltn12.sink.table(t),
		headers = {
			Accept = "text/html",
		},
	})

	local ret, root = pcall(htmlparser.parse, table.concat(t), 10000)
	if not ret then
		logger.err("failed to parse html from " .. url .. table.concat(t, "\n"))
		return
	end

	local function parseComment(comment_html)
		local comment = {}
		if comment_html and comment_html.attributes and comment_html.attributes.id then
			comment.id = comment_html.attributes.id:match("comment_(%d+)")
		else
			logger.err(
				string.format("failed to get comment id from: %s", comment_html and comment_html:getcontent() or nil)
			)
		end

		local heading = comment_html("> h4.heading")
		if heading and heading[1] then
			local nodes = heading[1].nodes
			if nodes and nodes[1] and nodes[1].name == "a" then
				-- normal
				comment.author = nodes[1]:getcontent()
			elseif
				nodes
				and nodes[1]
				and nodes[1].name == "span"
				and nodes[2]
				and nodes[2].attributes.class == "role"
			then
				-- guest
				comment.author = string.format("%s %s", nodes[1]:getcontent(), nodes[2]:getcontent())
			else
				-- account deleted
				comment.author = heading[1]:getcontent():match("[ \n]*([^<]*%w)")
			end
			local datetime = heading[1]("> span.posted.datetime > *")
			if not datetime then
				logger.err(string.format("failed to get comment datetime with id: %s", comment.id))
			end
			local tmp = {}
			for _, node in ipairs(datetime) do
				table.insert(tmp, node:getcontent())
			end
			comment.datetime = table.concat(tmp, " ")
		else
			logger.err(string.format("failed to get comment heading with id: %s", comment.id))
		end

		local text_nodes = comment_html("> blockquote.userstuff > p")
		if not text_nodes then
			logger.err(string.format("failed to get comment text with id: %s", comment.id))
		end
		local tmp = {}
		for _, node in ipairs(text_nodes or {}) do
			table.insert(tmp, Web.sanitize_response(node:getcontent()))
		end
		comment.text = table.concat(tmp, "\n")

		return comment
	end

	local function parseThread(thread_html)
		local nodes = thread_html("> li")
		local threads = {}
		local thread = nil

		for _, node in ipairs(nodes) do
			if node.attributes and node.attributes.class and node.attributes.class:match("comment") then
				-- new thread
				if thread then
					table.insert(threads, thread)
				end
				thread = parseComment(node)
			else
				if thread and node.nodes and node.nodes[1] then
					thread.children = parseThread(node.nodes[1])
				else
					logger.err("failed to get children from comment")
				end
			end
		end

		table.insert(threads, thread)

		return threads
	end

	local comments = {
		page = page,
	}

	local comments_placeholder = root("#comments_placeholder")
	if not (comments_placeholder and comments_placeholder[1]) then
		logger.err("failed to get comments_placeholder")
		return
	end

	local thread = comments_placeholder[1]("> ol.thread")
	if thread and thread[1] then
		comments.threads = parseThread(thread[1])
	else
		logger.err("failed to get comment threads")
		return
	end

	local pagination = comments_placeholder[1]("> ol.pagination")
	if pagination and pagination[1] then
		comments.pages = Web.getPages(pagination[1])
	else
		comments.pages = 1
	end

	return comments
end

function Web:sendComment(work_id, chapter_id, comment_id, name, email, content)
	local url

	if comment_id then
		url = string.format("https://archiveofourown.org/comments/%s/comments", comment_id)
	elseif work_id and chapter_id then
		url = string.format("https://archiveofourown.org/works/%s/chapters/%s/comments", work_id, chapter_id)
	elseif chapter_id then
		url = string.format("https://archiveofourown.org/works/%s/comments", work_id)
	else
		logger.err("missing id in Web:sendComment")
	end

	local data = {
		["comment[name]"] = name,
		["comment[email]"] = email,
		["comment[comment_content]"] = content,
		["controller_name"] = "comments",
		["commit"] = "Comment",
	}

	local token = self:tokenDispenser()

	if not token then
		logger.err("failed to get token in giveKudos")
		return
	end

	data["authenticity_token"] = token

	-- send comment
	local t = {}
	local data_strings = {}
	for key, value in pairs(data) do
		table.insert(data_strings, string.format("%s=%s", self.sanitize_request(key), self.sanitize_request(value)))
	end
	local data_string = table.concat(data_strings, "&")
	self:httpsRequest({
		method = "POST",
		url = url,
		sink = ltn12.sink.table(t),
		source = ltn12.source.string(data_string),
		headers = {
			["Accept"] = "*/*",
			["Content-Length"] = data_string:len(),
			["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8",
		},
	})
end

function Web:getChapters(work_id)
	local t = {}
	local url = string.format("https://archiveofourown.org/works/%s/navigate", work_id)
	self:httpsRequest({
		method = "GET",
		url = url,
		sink = ltn12.sink.table(t),
		headers = {
			Accept = "text/html",
		},
	})

	local ret, root = pcall(htmlparser.parse, table.concat(t), 10000)
	if not ret then
		logger.err("failed to parse html from " .. url .. table.concat(t, "\n"))
		return
	end

	local chapter_nodes = root("#main > ol.chapter >	li")
	if not chapter_nodes then
		logger.err(string.format("failed to get chapters from work with id: %s", work_id))
		return
	end

	local chapters = {}
	for _, node in ipairs(chapter_nodes) do
		local chapter = {}
		local link = node("> a")
		if link and link[1] and link[1].attributes and link[1].attributes.href then
			chapter.name = link[1]:getcontent()
			chapter.id = link[1].attributes.href:match("/works/%d+/chapters/(%d+)")
		else
			logger.err(string.format("failed to get a chapter name and id from work with id: %s", work_id))
		end
		local datetime = node("> span.datetime")
		if datetime and datetime[1] then
			chapter.datetime = datetime[1]:getcontent():match("(.*)")
		else
			logger.err(string.format("failed to get a chapter datetime from work with id: %s", work_id))
		end

		table.insert(chapters, chapter)
	end

	return chapters
end

function Web:tokenDispenser()
	local t = {}
	local url = "https://archiveofourown.org/token_dispenser.json"
	self:httpsRequest({
		method = "GET",
		url = url,
		sink = ltn12.sink.table(t),
		headers = {
			Accept = "application/json",
		},
	})

	local ret, result = pcall(JSON.decode, table.concat(t))
	if not ret then
		logger.err("failed to parse json from " .. url .. table.concat(t))
		return
	end

	if not (result and result.token) then
		logger.err("unexpected response from token_dispenser")
		return
	end

	return result.token
end

function Web:httpsRequest(opts)
	if not opts.headers then
		opts.headers = {}
	end
	opts.headers["Cookie"] = self.cookies:getCookieString()
	opts.headers["User-Agent"] = self.user_agent

	logger.dbg(string.format("https request"))
	logger.dbg(opts)
	local r, c, h = https.request(opts)
	logger.dbg(string.format("received response: %s, %s, %s", r, c, h))
	if h and h["set-cookie"] then
		self.cookies:setCookies(h["set-cookie"])
	end
end

-- returns highest page in pagination or nil if none found
function Web.getPages(pagination_html)
	local nodes = pagination_html("> li > *")
	local pages = 0
	for _, node in ipairs(nodes) do
		local page = tonumber(node:getcontent())
		if page and page > pages then
			pages = page
		end
	end

	return pages
end

function Web:checkForFicUpdates(id, old_updated)
	local _, _, _, updated = self:getDownloadDetails(id)

	local local_updated = tonumber(old_updated)
	local remote_updated = tonumber(updated)

	if local_updated and remote_updated then
		return updated > old_updated
	else
		logger.err("failed to get number from updated: %s or %s", local_updated, remote_updated)
		return nil
	end
end

return Web
