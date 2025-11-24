local Blitbuffer = require("ffi/blitbuffer")
local Size = require("ui/size")
local Geom = require("ui/geometry")
local UIManager = require("ui/uimanager")
local FocusManager = require("ui/widget/focusmanager")
local LineWidget = require("ui/widget/linewidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local logger = require("logger")
local T = require("gettext")
local ScrollingPages = require("scrolling_pages")
local Comment = require("comment")
local ChapterPicker = require("chapter_picker")
local CommentDialog = require("comment_dialog")
local Web = require("web")
local DialogManager = require("dialog_manager")

local Comments = FocusManager:extend({
	work_id = nil,
	chapter_id = nil,
	is_always_active = true,
	close_callback = nil,
})

function Comments:init()
	self:showChapters()
end

function Comments:onSwitchFocus(focus)
	if self[1] and self[1].onSwitchFocus then
		self[1]:onSwitchFocus(focus)
	end
end

function Comments:toClose()
	if self[1] and self[1].toClose then
		self[1]:toClose()
	end
end

function Comments:showComments()
	if self[1] and self[1].toClose then
		self[1]:toClose()
	end

	local scrolling_pages = ScrollingPages:new({
		title = T("Comments"),
		close_callback = function()
			if self.close_callback then
				self.close_callback()
			end
		end,

		left_icon = "appbar.navigation",
		left_icon_tap_callback = function()
			self:showChapters()
		end,
		left_icon_2 = "plus",
		left_icon_2_tap_callback = function()
			self:showCommentDialog()
		end,

		page = 1,

		content_generator = function(width, container, page)
			local close_info = DialogManager:showInfo(T("Fetching comments"))
			UIManager:nextTick(function()
				local comments = Web:loadComments(self.work_id, self.chapter_id, page)
				UIManager:nextTick(close_info)
				if not comments then
					logger.err("empty comments")
					DialogManager:showErr(T("Failed to get comments\nempty"))
					return
				end

				container.page = comments.page
				container.pages = comments.pages

				local vertical_group = VerticalGroup:new({
					align = "left",
					width = width,
				})

				local function renderThread(comment, depth)
					table.insert(
						vertical_group,
						Comment:new({
							width = width,
							depth = depth,
							text = comment.text,
							author = comment.author,
							datetime = comment.datetime,
							comment_id = comment.id,
							on_tap_callback = function()
								if comment.id then
									self:showCommentDialog(comment.id, comment.author, comment.datetime, comment.text)
								end
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
									h = 2,
								}),
							}),
							VerticalSpan:new({
								width = Size.span.vertical_large,
							}),
						})
					)
					for _, child in ipairs(comment.children or {}) do
						renderThread(child, depth + 1)
					end
				end

				for _, thread in ipairs(comments.threads or {}) do
					renderThread(thread, 0)
				end

				container:set_content(vertical_group)
			end)
			return VerticalGroup:new({
				width = width,
			})
		end,
		show_parent = self,
	})

	self[1] = scrolling_pages

	UIManager:setDirty(self, "ui")
end

function Comments:showChapters()
	if self[1] and self[1].toClose then
		self[1]:toClose()
	end

	self[1] = ChapterPicker:new({
		work_id = self.work_id,
		show_parent = self,
		on_tap_callback = function(chapter_id)
			self.chapter_id = chapter_id
			self:showComments()
		end,
		single_chapter_callback = function(chapter_id)
			self.chapter_id = chapter_id
			UIManager:nextTick(function()
				self:showComments()
			end)
		end,
		close_callback = function()
			if self.close_callback then
				self.close_callback()
			end
		end,
	})

	UIManager:setDirty(self, "ui")
end

function Comments:showCommentDialog(id, author, datetime, text)
	if self[1] and self[1].toClose then
		self[1]:toClose()
	end

	self[1] = CommentDialog:new({
		work_id = self.work_id,
		chapter_id = self.chapter_id,
		comment_id = id,
		comment_author = author,
		comment_datetime = datetime,
		comment_text = text,
		show_parent = self,
		close_callback = function()
			self:showComments()
		end,
	})

	UIManager:setDirty(self, "ui")
end

return Comments
