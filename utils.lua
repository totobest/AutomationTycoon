local Logger = require("__stdlib__/stdlib/misc/logger")
local table = require("__stdlib__/stdlib/utils/table")

IS_DEBUG = settings.startup.is_debug

LOGGER = Logger.new('AutomationTycoon', nil, IS_DEBUG, {
		log_ticks = false,
})

local function l(s)
	local r = 0
	for i, v in string.gmatch(s, "\n") do
		r = r + 1
	end
	return r
end

if IS_DEBUG then
  LOG = function(msg)
		msg = string.rep(" ", l(debug.traceback()) - 3) .. msg
  	if _G.game then
  		LOGGER.log(msg)
  	else
  		print("AutomationTycoon: " .. msg)
  	end
  end
else
	LOG = function() end
end
LOG("Hello!")

if _G.game then
	assert(LOGGER.write(), "Logger.write() did not work!")
end
