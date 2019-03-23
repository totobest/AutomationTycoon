require("utils")
local table = require('__stdlib__/stdlib/utils/table')
local Event = require('__stdlib__/stdlib/event/event')
local Force = require('__stdlib__/stdlib/event/force').register_events()

Event.protected_mode = true

local forbidden_entities_on_nauvis = table.array_to_dictionary({
	"transport-belt",
	"underground-belt",
	"splitter",
--	"inserter"
}, true)

Event.register({"on_init", "on_configuration_changed"}, function()
	LOG("on_init/on_configuration_changed")
	local data = global
	local ucoin_recipes = {}

	table.each(game.recipe_prototypes, function(recipe)
		if not recipe.enabled then
			return
		end
		if string.find(recipe.name, "^at-") ~= nil then
			local ucoin_recipe_name = recipe.name
			LOG("unlocked ucoin recipe is now available ucoin_recipe_name=" .. ucoin_recipe_name)
			table.insert(ucoin_recipes, ucoin_recipe_name)
		else
			table.each(recipe.products, function(product)
				if product.type ~= "item" then
					return
				end
				LOG("product.name=" .. product.name)
				local ucoin_recipe_name = "at-".. product.name .."-to-ucoin"
				local ucoin_recipe = game.recipe_prototypes[ucoin_recipe_name]
				if ucoin_recipe ~= nil then
					LOG("ucoin recipe is now available ucoin_recipe_name=" .. ucoin_recipe_name)
					table.insert(ucoin_recipes, ucoin_recipe_name)
				end
			end) -- end table.each
		end
	end)

	-- local _, force_data = Force.get(technology.force)
	local data = global
	local g_ucoin_recipes_index = 1
	local g_ucoin_recipes = {}
	if #ucoin_recipes > 0 then
		g_ucoin_recipes[g_ucoin_recipes_index] = ucoin_recipes
		g_ucoin_recipes_index = g_ucoin_recipes_index + 1
	end
	data.ucoin_recipes = g_ucoin_recipes
	data.ucoin_recipes_index = g_ucoin_recipes_index
	LOG("g_ucoin_recipes_index=" .. g_ucoin_recipes_index)
	LOG(serpent.block(g_ucoin_recipes))

end)

Event.register({defines.events.on_built_entity, defines.events.on_robot_built_entity}, function (event)
	-- called at player creation
	local created_entity = event.created_entity
	LOG("created_entity.type=" .. created_entity.type)
	if forbidden_entities_on_nauvis[created_entity.type] and not string.find(created_entity.surface.name, "^Factory f") then
		created_entity.surface.create_entity{name="flying-text", position=created_entity.position, text="Cannot build belts on Nauvis"}
		created_entity.destroy()
	end
end)


Event.register(defines.events.on_research_finished, function (event)
	local technology = event.research
	LOG("on_research_finished technology.name=" .. technology.name)
	local ucoin_recipes = {}

	if technology.effects ~= nil then
		table.each(technology.effects, function(modifier)
			if modifier.type ~= "unlock-recipe" then
				return
			end
			LOG("modifier.recipe=" .. modifier.recipe)
			local recipe = game.recipe_prototypes[modifier.recipe]
			if recipe ~= nil then
				table.each(recipe.products, function(product)
					if product.type ~= "item" then
						return
					end
					LOG("product.name=" .. product.name)
					local ucoin_recipe_name = "at-".. product.name .."-to-ucoin"
					local ucoin_recipe = game.recipe_prototypes[ucoin_recipe_name]
					if ucoin_recipe ~= nil then
						LOG("ucoin recipe is now available ucoin_recipe_name=" .. ucoin_recipe_name)
						table.insert(ucoin_recipes, ucoin_recipe_name)
					end
				end) -- end table.each
			end -- if recipe ~= nil
		end)
	end

	if #ucoin_recipes > 0 then
		-- local _, force_data = Force.get(technology.force)
		local data = global
		local g_ucoin_recipes_index = data.ucoin_recipes_index or 1
		local g_ucoin_recipes = data.ucoin_recipes or {}
		g_ucoin_recipes[g_ucoin_recipes_index] = ucoin_recipes
		data.ucoin_recipes = g_ucoin_recipes
		data.ucoin_recipes_index = g_ucoin_recipes_index + 1
		LOG("g_ucoin_recipes_index=" .. g_ucoin_recipes_index)
	end
end)


Event.register(defines.events.on_chunk_generated, function (event)
	local surface = event.surface
	LOG("on_chunk_generated")
	table.each(surface.find_entities_filtered {
		area = event.area,
		name = "at-city"
	}, function(city)
		LOG("position" .. serpent.block(city.position))
		LOG("get_recipe=" .. city.get_recipe().name)
		if city.get_recipe().name ~= "at-ucoin-to-ucoin" then
			return
		end
		local data = global
		local g_ucoin_recipes_index = data.ucoin_recipes_index or 1
		local g_ucoin_recipes = data.ucoin_recipes or {}
		local window_size = 4

		local min_i = g_ucoin_recipes_index - window_size
		min_i = min_i > 1 and min_i or 1
		local max_i = g_ucoin_recipes_index + window_size
		max_i = max_i <= #g_ucoin_recipes and max_i or #g_ucoin_recipes

		LOG("#g_ucoin_recipes=" .. #g_ucoin_recipes .. " min_i=" .. min_i .. " max_i=" .. max_i)
		local s = table.flatten(table.slice(g_ucoin_recipes, min_i, max_i))
		LOG("#s=" .. #s)
		if #s > 0 then
			local i = math.floor(math.random() * #s) + 1
			LOG("i=" .. i)
			LOG("s[i]=" .. s[i])
			city.set_recipe(s[i])
		end


	end)

end)
