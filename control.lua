local Table = require('__stdlib__/stdlib/utils/table')
local Event = require('__stdlib__/stdlib/event/event')
Event.protected_mode = true

local forbidden_entities_on_nauvis = Table.array_to_dictionary({"belt", "inserter"}, true)

Event.register({defines.events.on_built_entity, defines.events.on_robot_built_entity}, function forbid_belts_and_inserters_on_nauvis(event)
	-- called at player creation
	local created_entity = event.created_entity
	if created_entity.surface.name == "nauvis" and forbidden_entities_on_nauvis[created_entity.type] then
		entity.surface.create_entity{name="flying-text", position=entity.position, text="Cannot build belts nor inserters on Nauvis"}
		created_entity.destroy()
	end
end)
