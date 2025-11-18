local Size = require("ui/size")
local Geom = require("ui/geometry")
local Font = require("ui/font")
local UIManager = require("ui/uimanager")
local TextBoxWidget = require("ui/widget/textboxwidget")
local InputText = require("ui/widget/inputtext")
local Button = require("ui/widget/button")
local RadioButtonTable = require("ui/widget/radiobuttontable")
local CheckButton = require("ui/widget/checkbutton")
local ButtonDialog = require("ui/widget/buttondialog")
local VerticalGroup = require("ui/widget/verticalgroup")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local T = require("gettext")
local logger = require("logger")
local TagInput = require("tag_input")
local DialogManager = require("dialog_manager")
local ScrollingPages = require("scrolling_pages")

local fields = {
	{
		key = "query",
		label = T("Any Field"),
		type = "text",
		default = { "" },
	},
	{
		key = "title",
		label = T("Title"),
		type = "text",
		default = { "" },
	},
	{
		key = "creators",
		label = T("Creator"),
		type = "text",
		default = { "" },
	},
	{
		key = "revised_at",
		label = T("Date"),
		type = "text",
		default = { "" },
	},
	{
		key = "complete",
		label = T("Completion status"),
		type = "radio",
		default = { "" },
		options = {
			{ value = "", label = T("All works") },
			{ value = "T", label = T("Complete works only") },
			{ value = "F", label = T("Works in progress only") },
		},
	},
	{
		key = "crossover",
		label = T("Crossovers"),
		type = "radio",
		default = { "" },
		options = {
			{ value = "", label = T("Include crossovers") },
			{ value = "F", label = T("Exclude crossovers") },
			{ value = "T", label = T("Crossovers only") },
		},
	},
	{
		key = "single_chapter",
		label = T("Single Chapter"),
		type = "checkbox",
		default = { 0 },
	},
	{
		key = "word_count",
		label = T("Word Count"),
		type = "text",
		default = { "" },
	},
	{
		key = "language_id",
		label = T("Language"),
		type = "dropdown",
		default = { "" },
		options = {
			{ value = "", label = " " },
			{ value = "so", label = "af Soomaali" },
			{ value = "afr", label = "Afrikaans" },
			{ value = "ain", label = "Aynu itak | アイヌ イタㇰ" },
			{ value = "akk", label = "𒀝𒅗𒁺𒌑" },
			{ value = "ar", label = "العربية" },
			{ value = "amh", label = "አማርኛ" },
			{ value = "egy", label = "𓂋𓏺𓈖 𓆎𓅓𓏏𓊖" },
			{ value = "oji", label = "Anishinaabemowin" },
			{ value = "arc", label = "ܐܪܡܝܐ | ארמיא" },
			{ value = "hy", label = "հայերեն" },
			{ value = "ase", label = "American Sign Language" },
			{ value = "ast", label = "asturianu" },
			{ value = "azj", label = "Azərbaycan dili | آذربایجان دیلی" },
			{ value = "id", label = "Bahasa Indonesia" },
			{ value = "ms", label = "Bahasa Malaysia" },
			{ value = "bg", label = "Български" },
			{ value = "bn", label = "বাংলা" },
			{ value = "jv", label = "Basa Jawa" },
			{ value = "ba", label = "Башҡорт теле" },
			{ value = "be", label = "беларуская" },
			{ value = "bar", label = "Boarisch" },
			{ value = "bos", label = "Bosanski" },
			{ value = "br", label = "Brezhoneg" },
			{ value = "bfi", label = "British Sign Language" },
			{
				value = "bua",
				label = "Буряад хэлэн | ᠪᠤᠷᠢᠶᠠᠳ ᠮᠣᠩᠭᠣᠯ ᠬᠡᠯᠡ",
			},
			{ value = "ca", label = "Català" },
			{ value = "ceb", label = "Cebuano" },
			{ value = "cs", label = "Čeština" },
			{ value = "chn", label = "Chinuk Wawa" },
			{ value = "crh", label = "къырымтатар тили | qırımtatar tili" },
			{ value = "cy", label = "Cymraeg" },
			{ value = "da", label = "Dansk" },
			{ value = "de", label = "Deutsch" },
			{ value = "et", label = "eesti keel" },
			{ value = "el", label = "Ελληνικά" },
			{ value = "sux", label = "𒅴𒂠" },
			{ value = "en", label = "English" },
			{ value = "ang", label = "Eald Englisċ" },
			{ value = "es", label = "Español" },
			{ value = "eo", label = "Esperanto" },
			{ value = "eu", label = "Euskara" },
			{ value = "fa", label = "فارسی" },
			{ value = "fil", label = "Filipino" },
			{ value = "cha", label = "Finuʼ Chamorro" },
			{ value = "fr", label = "Français" },
			{ value = "frr", label = "Friisk" },
			{ value = "fry", label = "Frysk" },
			{ value = "fur", label = "Furlan" },
			{ value = "ga", label = "Gaeilge" },
			{ value = "gd", label = "Gàidhlig" },
			{ value = "gl", label = "Galego" },
			{ value = "got", label = "𐌲𐌿𐍄𐌹𐍃𐌺𐌰" },
			{ value = "gyn", label = "Creolese" },
			{ value = "hak", label = "中文-客家话" },
			{ value = "ko", label = "한국어" },
			{ value = "hau", label = "Hausa | هَرْشَن هَوْسَ" },
			{ value = "hi", label = "हिन्दी" },
			{ value = "hr", label = "Hrvatski" },
			{ value = "haw", label = "ʻŌlelo Hawaiʻi" },
			{ value = "ia", label = "Interlingua" },
			{ value = "zu", label = "isiZulu" },
			{ value = "is", label = "Íslenska" },
			{ value = "it", label = "Italiano" },
			{ value = "he", label = "עברית" },
			{ value = "kal", label = "Kalaallisut" },
			{ value = "xal", label = "Хальмг Өөрдин келн" },
			{ value = "kan", label = "ಕನ್ನಡ" },
			{ value = "kat", label = "ქართული" },
			{ value = "cor", label = "Kernewek" },
			{ value = "khm", label = "ភាសាខ្មែរ" },
			{ value = "qkz", label = "Khuzdul" },
			{ value = "sw", label = "Kiswahili" },
			{ value = "ht", label = "kreyòl ayisyen" },
			{ value = "ku", label = "Kurdî | کوردی" },
			{ value = "kir", label = "Кыргызча" },
			{ value = "fcs", label = "Langue des signes québécoise" },
			{ value = "lv", label = "Latviešu valoda" },
			{ value = "lb", label = "Lëtzebuergesch" },
			{ value = "lt", label = "Lietuvių kalba" },
			{ value = "la", label = "Lingua latina" },
			{ value = "hu", label = "Magyar" },
			{ value = "mk", label = "македонски" },
			{ value = "ml", label = "മലയാളം" },
			{ value = "mt", label = "Malti" },
			{ value = "mnc", label = "ᠮᠠᠨᠵᡠ ᡤᡳᠰᡠᠨ" },
			{ value = "qmd", label = "Mando'a" },
			{ value = "mr", label = "मराठी" },
			{ value = "mik", label = "Mikisúkî" },
			{
				value = "mon",
				label = "ᠮᠣᠩᠭᠣᠯ ᠪᠢᠴᠢᠭ᠌ | Монгол Кирилл үсэг",
			},
			{ value = "my", label = "မြန်မာဘာသာ" },
			{ value = "myv", label = "Эрзянь кель" },
			{ value = "nah", label = "Nāhuatl" },
			{ value = "nan", label = "中文-闽南话 臺語" },
			{ value = "ppl", label = "Nawat" },
			{ value = "nl", label = "Nederlands" },
			{ value = "ja", label = "日本語" },
			{ value = "no", label = "Norsk" },
			{ value = "ce", label = "Нохчийн мотт" },
			{ value = "ood", label = "O’odham Ñiok" },
			{ value = "ota", label = "لسان عثمانى" },
			{ value = "ps", label = "پښتو" },
			{ value = "nds", label = "Plattdüütsch" },
			{ value = "pl", label = "Polski" },
			{ value = "ptBR", label = "Português brasileiro" },
			{ value = "ptPT", label = "Português europeu" },
			{ value = "fuc", label = "Pulaar" },
			{ value = "pa", label = "ਪੰਜਾਬੀ" },
			{ value = "kaz", label = "qazaqşa | қазақша" },
			{ value = "qlq", label = "Uncategorized Constructed Languages" },
			{ value = "qya", label = "Quenya" },
			{ value = "ro", label = "Română" },
			{ value = "rom", label = "RRomani Ćhib" },
			{ value = "ru", label = "Русский" },
			{ value = "smi", label = "Sámi" },
			{ value = "sah", label = "саха тыла" },
			{ value = "sco", label = "Scots" },
			{ value = "sq", label = "Shqip" },
			{ value = "sjn", label = "Sindarin" },
			{ value = "si", label = "සිංහල" },
			{ value = "sk", label = "Slovenčina" },
			{ value = "slv", label = "Slovenščina" },
			{ value = "sla", label = "Slověnьskъ Językъ" },
			{ value = "gem", label = "Sprēkō Þiudiskō" },
			{ value = "sr", label = "Српски" },
			{ value = "fi", label = "suomi" },
			{ value = "sv", label = "Svenska" },
			{ value = "ta", label = "தமிழ்" },
			{ value = "tat", label = "татар теле" },
			{ value = "mri", label = "te reo Māori" },
			{ value = "tel", label = "తెలుగు" },
			{ value = "tir", label = "ትግርኛ" },
			{ value = "th", label = "ไทย" },
			{ value = "tqx", label = "Thermian" },
			{ value = "bod", label = "བོད་སྐད་" },
			{ value = "vi", label = "Tiếng Việt" },
			{ value = "cop", label = "ϯⲙⲉⲧⲣⲉⲙⲛ̀ⲭⲏⲙⲓ" },
			{ value = "tlh", label = "tlhIngan-Hol" },
			{ value = "tok", label = "toki pona" },
			{ value = "trf", label = "Trinidadian Creole" },
			{ value = "tsd", label = "τσακώνικα" },
			{ value = "chr", label = "ᏣᎳᎩ ᎦᏬᏂᎯᏍᏗ" },
			{ value = "tr", label = "Türkçe" },
			{ value = "uk", label = "Українська" },
			{ value = "ale", label = "Unangam Tunuu" },
			{ value = "urd", label = "اُردُو" },
			{ value = "uig", label = "ئۇيغۇر تىلى" },
			{ value = "vol", label = "Volapük" },
			{ value = "wuu", label = "中文-吴语" },
			{ value = "yi", label = "יידיש" },
			{ value = "yua", label = "maayaʼ tʼàan" },
			{ value = "yue", label = "中文-广东话 粵語" },
			{ value = "zh", label = "中文-普通话 國語" },
		},
	},
	{
		key = "fandom_names",
		label = T("Fandoms"),
		type = "tags",
		type_value = "fandom",
		default = { "" },
	},
	{
		key = "rating_ids",
		label = T("Rating"),
		type = "dropdown",
		default = { "" },
		options = {
			{ value = "", label = " " },
			{ value = "9", label = "Not Rated" },
			{ value = "10", label = "General Audiences" },
			{ value = "11", label = "Teen And Up Audiences" },
			{ value = "12", label = "Mature" },
			{ value = "13", label = "Explicit" },
		},
	},
	{
		key = "archive_warning_ids",
		label = T("Warnings"),
		type = "checkboxes",
		default = {},
		options = {
			{ value = "14", label = "Creator Chose Not To Use Archive Warnings" },
			{ value = "17", label = "Graphic Depictions Of Violence" },
			{ value = "18", label = "Major Character Death" },
			{ value = "16", label = "No Archive Warnings Apply" },
			{ value = "19", label = "Rape/Non-Con" },
			{ value = "20", label = "Underage Sex" },
		},
	},
	{
		key = "category_ids",
		label = T("Categories"),
		type = "checkboxes",
		default = {},
		options = {
			{ value = "116", label = "F/F" },
			{ value = "22", label = "F/M" },
			{ value = "21", label = "Gen" },
			{ value = "23", label = "M/M" },
			{ value = "2246", label = "Multi" },
			{ value = "24", label = "Other" },
		},
	},
	{
		key = "character_names",
		label = T("Characters"),
		type = "tags",
		type_value = "character",
		default = { "" },
	},
	{
		key = "relationship_names",
		label = T("Relationships"),
		type = "tags",
		type_value = "relationship",
		default = { "" },
	},
	{
		key = "freeform_names",
		label = T("Additional Tags"),
		type = "tags",
		type_value = "freeform",
		default = { "" },
	},
	{
		key = "hits",
		label = T("Hits"),
		type = "text",
		default = { "" },
	},
	{
		key = "kudos_count",
		label = T("Kudos"),
		type = "text",
		default = { "" },
	},
	{
		key = "comments_count",
		label = T("Comments"),
		type = "text",
		default = { "" },
	},
	{
		key = "bookmarks_count",
		label = T("Bookmarks"),
		type = "text",
		default = { "" },
	},

	{
		key = "sort_column",
		label = T("Sort by"),
		type = "dropdown",
		default = { "_score" },
		options = {
			{ value = "_score", label = "Best Match" },
			{ value = "authors_to_sort_on", label = "Creator" },
			{ value = "title_to_sort_on", label = "Title" },
			{ value = "created_at", label = "Date Posted" },
			{ value = "revised_at", label = "Date Updated" },
			{ value = "word_count", label = "Word Count" },
			{ value = "hits", label = "Hits" },
			{ value = "kudos_count", label = "Kudos" },
			{ value = "comments_count", label = "Comments" },
			{ value = "bookmarks_count", label = "Bookmarks" },
		},
	},
	{
		key = "sort_direction",
		label = T("Sort direction"),
		type = "dropdown",
		default = { "desc" },
		options = {
			{ value = "asc", label = "Ascending" },
			{ value = "desc", label = "Descending" },
		},
	},
}

local SearchQuery = WidgetContainer:extend({
	width = nil,
	query = {},
	_fields = {},
	search_callback = nil,
	close_callback = nil,
	show_parent = nil,
	title = nil,
	left_icon = nil,
	left_icon_tap_callback = nil,
	always_active_callback = nil,
})

function SearchQuery:init()
	local scrolling_pages = ScrollingPages:new({
		title = self.title,
		left_icon = self.left_icon,
		left_icon_tap_callback = self.left_icon_tap_callback,
		close_callback = self.close_callback,

		content_generator = function(width, container, page)
			local vertical_group = VerticalGroup:new({
				align = "left",
				width = width,
				layout = {},
			})

			local label_width = width * 0.25
			local input_width = width - label_width

			for _, field in ipairs(fields) do
				local label = FrameContainer:new({
					bordersize = 0,
					padding = 0,
					margin = Size.margin.fine_tune,
					TextBoxWidget:new({
						text = field.label,
						face = Font:getFace("x_smallinfofont"),
						width = label_width - 2 * Size.margin.fine_tune,
					}),
				})

				local input

				if field.type == "text" then
					local default = self.query[field.key] or field.default

					input = InputText:new({
						text = default[1],
						width = input_width - InputText.bordersize * 2,
						scroll = false,
						focused = false,
						padding = 0,
						margin = 0,
						parent = self.show_parent,
					})

					table.insert(vertical_group.layout, { input })
				elseif field.type == "radio" then
					local radio_buttons = {}

					local default = self.query[field.key] or field.default

					for _, entry in pairs(field.options) do
						table.insert(radio_buttons, {
							{
								text = entry.label,
								value = entry.value,
								checked = entry.value == default[1],
							},
						})
					end

					input = RadioButtonTable:new({
						radio_buttons = radio_buttons,
						width = input_width,
						focused = true,
						scroll = false,
						parent = self.show_parent,
						face = Font:getFace("x_smallinfofont"),
						button_select_callback = function(btn_entry)
							self._fields[field.key].value = { btn_entry.value }
						end,
					})
				elseif field.type == "checkbox" then
					local default = self.query[field.key] or field.default

					input = CheckButton:new({
						checked = default[1] == 1,
						parent = self.show_parent,
						width = input_width,
						callback = function()
							self._fields[field.key].value = { self._fields[field.key].value[1] == 0 and 1 or 0 }
						end,
					})
				elseif field.type == "checkboxes" then
					local default = self.query[field.key] or field.default
					input = VerticalGroup:new({})

					for _, entry in pairs(field.options) do
						local checked = false
						for _, v in ipairs(default) do
							if v == entry.value then
								checked = true
							end
						end

						table.insert(
							input,
							CheckButton:new({
								checked = checked,
								text = entry.label,
								parent = self.show_parent,
								width = input_width,
								face = Font:getFace("x_smallinfofont"),
								value = entry.value,
								callback = function()
									local contains = nil
									for i, value in ipairs(self._fields[field.key].value) do
										if value == entry.value then
											contains = i
											break
										end
									end

									if contains ~= nil then
										table.remove(self._fields[field.key].value, contains)
									else
										table.insert(self._fields[field.key].value, entry.value)
									end
								end,
							})
						)
					end
				elseif field.type == "dropdown" then
					local dialog
					local buttons = {}

					local default = self.query[field.key] or field.default

					local default_text

					for _, entry in pairs(field.options) do
						if entry.value == default[1] then
							default_text = entry.label
						end

						table.insert(buttons, {
							{
								text = entry.label,
								value = entry.value,
								callback = function()
									self._fields[field.key].value = { entry.value }
									input:setText(entry.label, input_width)
									UIManager:setDirty(input, "ui")
									DialogManager:close(dialog)
									if self.always_active_callback then
										self.always_active_callback(true)
									end
								end,
							},
						})
					end
					input = Button:new({
						text = default_text,
						callback = function()
							dialog = ButtonDialog:new({
								buttons = buttons,
								title_align = "center",
								width = input_width,
							})
							dialog.tap_close_callback = function()
								DialogManager:untrack(dialog)
								if self.always_active_callback then
									self.always_active_callback(true)
								end
							end
							DialogManager:show(dialog)
							if self.always_active_callback then
								self.always_active_callback(false)
							end
						end,
						width = input_width,
						padding = 0,
						bordersize = Size.border.inputtext,
						margin = 0,
					})
				elseif field.type == "tags" then
					local default = self.query[field.key] or field.default

					input = Button:new({
						text = default[1],
						callback = function()
							local dialog = TagInput:new({

								title = field.label,
								tags = self._fields[field.key].value[0],
								type = field.type_value,
							})
							dialog.close_callback = function()
								local text = TagInput.tagsToString(dialog.tags)
								self._fields[field.key].value = { text }
								input:setText(text, input_width)
								DialogManager:close(dialog)
								UIManager:nextTick(function()
									if self.always_active_callback then
										self.always_active_callback(true)
									end
								end)
								UIManager:setDirty(input, "ui")
								UIManager:setDirty(dialog, "ui")
							end
							DialogManager:show(dialog)
							if self.always_active_callback then
								self.always_active_callback(false)
							end
						end,
						width = input_width,
						padding = 0,
						bordersize = Size.border.inputtext,
						margin = 0,
					})
				else
					logger.err(string.format("invalid field in SearchQuery.fields, %s", field.key))
				end

				self._fields[field.key] =
					{ type = field.type, input = input, value = self.query[field.key] or field.default }

				table.insert(
					vertical_group,
					HorizontalGroup:new({

						dimen = Geom:new({
							w = width,
						}),
						align = (field.type == "checkboxes" or field.type == "radio") and "top" or "center",
						label,
						input,
					})
				)
				table.insert(
					vertical_group,
					VerticalSpan:new({
						width = Size.span.vertical_large,
					})
				)
			end

			return vertical_group
		end,
		show_parent = self.show_parent,
	})

	self[1] = scrolling_pages
end

function SearchQuery:onSwitchFocus(focus)
	if self[1] and self[1].onSwitchFocus then
		self[1]:onSwitchFocus(focus)
	end
end

function SearchQuery:toClose()
	if self[1] and self[1].toClose then
		self[1]:toClose()
	end
end

function SearchQuery:getQuery()
	for key, value in pairs(self._fields) do
		if value.type == "text" then
			self.query[key] = { value.input:getText() }
		elseif value.type == "radio" then
			self.query[key] = value.value
		elseif value.type == "checkbox" then
			self.query[key] = value.value
		elseif value.type == "checkboxes" then
			self.query[key] = value.value
		elseif value.type == "dropdown" then
			self.query[key] = value.value
		end
	end

	return self.query
end

return SearchQuery
