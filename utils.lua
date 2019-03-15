require("stdlib/log/logger")

IS_DEBUG = settings.startup.is_debug

LOGGER = Logger.new('TechnologyMarket', nil, IS_DEBUG, {
		log_ticks = false,
})

LOG = function() end

if IS_DEBUG:
  LOG = function(msg)
  	if _G.game then
  		LOGGER.log(msg)
  	else
  		print("TechnologyMarket: " .. msg)
  	end
  end
end
LOG("Hello!")

if _G.game then
	assert(LOGGER.write(), "Logger.write() did not work!")
end
