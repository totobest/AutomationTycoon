require("utils")
local table = require('__stdlib__/stdlib/utils/table')

-- -- hide mining-drills
-- local entities_to_hide = table.array_to_dictionary(table.map(data.raw["mining-drill"], function(entity, name)
-- 	return entity.name
-- end), true)
--
-- table.each(data.raw.recipe, function(recipe, name)
-- 	if entities_to_hide[recipe.result] or recipe.results and table.any(recipe.results, function (result)
-- 			return result.type == "item" and entities_to_hide[result.name]
-- 	end) then
-- 		recipe.hidden = true
-- 	end
-- end)

-- require("utils")
-- local table = require('__stdlib__/stdlib/utils/table')
require("bigassembly")

data:extend({
	{
    type = "recipe-category",
    name = "at-ucoin"
	}
})

local function create_ucoin_recipe(item_name, price, enabled)
	LOG("create_ucoin_recipe item_name=" .. item_name .. " price=" .. price)
	data:extend({
		{
			type = "recipe",
			name = "at-".. item_name .."-to-ucoin",
			category = "at-ucoin",
			icon = "__LibMoney__/graphics/ucoin.png",
			icon_size = 32,
			enabled = enabled or false,
			hidden = true,
			energy_required = 1,
			ingredients = {
				{item_name, 1}
			},
			results = {
				{
					name = "ucoin",
					amount = price
				},
			}
		}
	})
end

vanilla_resources_prices = {
--	["water"] = 0,
	["coal"] = 16,
	["stone"] = 27,
	["iron-ore"] = 19,
	["copper-ore"] = 21,
--	["crude-oil"] = 100,
}

local cached_technology_cost = {}
local item_cost = {}

local technology_time_unit_cost = 5
local technology_complexity_cost = 2
local technology_count_cost = 1

local recipe_energy_required_cost = 7
local recipe_complexity_cost = 2

local function get_techonology_cost(technology)
	assert(technology ~= nil)
	LOG("get_techonology_cost technology.name=" .. technology.name)

	local cached_cost = cached_technology_cost[technology.name]
	if cached_cost ~= nil then
		return cached_cost
	end

	local local_cost =
		(technology.unit.count ~= nil and technology.unit.count or 0) * technology_count_cost +
		#technology.unit.ingredients * technology_complexity_cost +
		technology.unit.time * technology_time_unit_cost

	local deps_cost = 0
	if technology.prerequisites ~= nil then
		local deps_cost = table.sum(table.map(technology.prerequisites, function(prereq_technology_name)
			assert (prereq_technology_name ~= nil)
			local prereq_technology = data.raw.technology[prereq_technology_name]
			if prereq_technology == nil then
				LOG("Prerequisited technology \"" .. prereq_technology_name .. " does not exist.")
				return 0
			else
				return get_techonology_cost(prereq_technology)
			end
		end))
	end
	local c = deps_cost + local_cost
	cached_technology_cost[technology.name] = c
	return c
end

local recipe_to_technology = {}
local technology_index = 1
local all_technologies = table.keys(data.raw.technology, true)

-- LOG(serpent.block(all_technologies))

local function get_unlocking_techonology_from_recipe(recipe_name)
	LOG("get_unlocking_techonology_from_recipe recipe_name=" .. recipe_name .. " technology_index=" .. technology_index)

	local saved = recipe_to_technology[recipe_name]
	if saved ~= nil then
		return saved
	end

	-- LOG("#data.raw.technology=" .. #all_technologies)
	while technology_index <= #all_technologies do
		local technology = data.raw.technology[all_technologies[technology_index]]
		LOG("technology.name=" .. technology.name)
		local found = nil
		if technology.effects ~= nil then
			table.each(technology.effects, function(effect)
				if effect.type ~= "unlock-recipe" then
					return
				end
				if not found and effect.recipe == recipe_name then
					found = true
				end
				recipe_to_technology[effect.recipe] = technology
			end)
		end
		technology_index = technology_index + 1
		if found then
			return technology
		end
	end -- while

	return nil
end
-- in
-- recipes -> item
 --> price is recipe + techno

-- out
-- item list with price
--   \-> recipe to ucoin

local function get_recipe_cost_for_result(recipe, result_name)
	-- LOG("get_recipe_cost_for_result recipe.name=" .. recipe.name .. " result_name=" .. result_name)
	local technology = get_unlocking_techonology_from_recipe(recipe.name)
	local technology_cost = 0
	if technology ~= nil then
		technology_cost =  get_techonology_cost(technology)
	end

	local recipe_cost = (function(recipe_sub)
		if #recipe_sub.ingredients == 0 then
			return 0
		end

		local result_count
		if recipe_sub.results ~= nil then
			result_count = table.find(recipe_sub.results, function(v)
				return v.name == result_name
			end).amount
		else
			assert(recipe_sub.result ~= nil)
			assert(result_name == recipe_sub.result)
			result_count = recipe_sub.result_count or 1
		end
		return math.floor(
			((recipe.energy_required or 0.5) * recipe_energy_required_cost +
			#recipe_sub.ingredients * recipe_complexity_cost) / result_count)
	end)(recipe.normal or recipe.expensive or recipe)

	LOG("get_recipe_cost_for_result recipe.name=" .. recipe.name .. " result_name=" .. result_name .." technology_cost=" .. technology_cost .. " recipe_cost=" .. recipe_cost)
	return technology_cost + recipe_cost
end

local item_to_recipes = {}

local create_ucoin_recipes_from_item
do
	local ucoin_recipe_created = {}
	create_ucoin_recipes_from_item = function (item)
		assert(item ~= nil)
		LOG("create_ucoin_recipes_from_item item.name=" .. item.name)

		if ucoin_recipe_created[item.name] ~= nil then
			return
		end

		local recipes = item_to_recipes[item.name]
		assert(recipes ~= nil)
		local recipe_cost = table.min(table.map(recipes, function(recipe)
			return get_recipe_cost_for_result(recipe, item.name)
		end))
		if recipe_cost and recipe_cost > 0 then
			create_ucoin_recipe(item.name, recipe_cost)
			ucoin_recipe_created[item.name] = true
		else
			LOG("No price for item " .. item.name)
		end
	end
end

local function link_recipe_to_item(recipe, item_name)
	assert(item_name ~= nil)

	local i = item_to_recipes[item_name]
	if i ~= nil then
		table.insert(i, recipe)
	else
		item_to_recipes[item_name] = {recipe}
	end
end

local function find_all_results_sub(recipe_sub)
	assert(recipe_sub ~= nil)
	if recipe_sub.result ~= nil then
		return {recipe_sub.result}
	else
		assert(recipe_sub.results ~= nil, "result and results both set for recipe " .. recipe_sub.name)
		return table.map(table.filter(recipe_sub.results, function(i)
			return i.type == "item"
		end), function(i)
			return i.name
		end)
	end
end

local function find_all_results(recipe)
	assert(recipe ~= nil)
	-- TODO: Maybe go through all recipes including difficulties
	-- as output might be differents
	return find_all_results_sub(recipe.normal or recipe.expensive or recipe)
end
-- start from recipe so we know player can craft/assemble the item
table.each(data.raw.recipe, function(recipe)
		table.each(find_all_results(recipe), function(result_name)
			link_recipe_to_item(recipe, result_name)
		end)
end)

LOG(serpent.block(table.map(item_to_recipes, function(value, key)
 	return #value
end)))

table.each(table.keys(item_to_recipes, true), function(item_name)
	local i =
		data.raw.item[item_name] or
		data.raw.tool[item_name] or
		data.raw.armor[item_name] or
		data.raw.gun[item_name] or
		data.raw.module[item_name] or
		data.raw.capsule[item_name] or
		data.raw["item-with-entity-data"][item_name] or
		data.raw["repair-tool"][item_name] or
		data.raw["rail-planner"][item_name] or
		data.raw.ammo[item_name]
	if i == nil then
		LOG("ignoring item " .. item_name)
	else
		create_ucoin_recipes_from_item(i)
	end
end)

table.each(data.raw.resource, function(resource)
	local price = vanilla_resources_prices[resource.name]
	if price == nil then
		LOG("unknown price for resource " .. resource.name)
	else
		create_ucoin_recipe(resource.name, price, true)
	end
end)

create_ucoin_recipe("ucoin", 0)
