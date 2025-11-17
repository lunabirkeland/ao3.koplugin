local logger = require("logger")

local Cookies = {}

function Cookies:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	if o.init then
		o:init()
	end
	return o
end

function Cookies:setCookies(cookies_string)
	for cookie_string in string.gmatch(", " .. cookies_string, ", ([^,]-=[^,]-);") do
		local key, value = string.match(cookie_string, "^(.*)=(.*)$")

		if key and value then
			self[key] = value
		else
			logger.err(string.format("error in Cookies:setCookie with string: %s", cookie_string))
		end
	end
end

function Cookies:getCookieString()
	local cookie_strings = {}

	for key, value in pairs(self) do
		table.insert(cookie_strings, string.format("%s=%s", key, value))
	end

	return table.concat(cookie_strings, "; ")
end

return Cookies
