-- Big Assembly prototype and item definition
local table = require('__stdlib__/stdlib/utils/table')
require("adjustVisuals")
require("util")

data:extend({
  {
    type = "autoplace-control",
    category = "resource",
    name = "at-city"
  },
  {
  name = "cities",
  type = "noise-layer"
  }
})

local function city_autoplace_settings(multiplier, rectangle)
  local peak =
  {
    noise_layer = "cities",
    noise_octaves_difference = -2,
    noise_persistence = 0.9
  }

  if rectangle ~= nil then
    local aux_center = (rectangle[2][1] + rectangle[1][1]) / 2
    local aux_range = math.abs(rectangle[2][1] - rectangle[1][1]) / 2
    local water_center = (rectangle[2][2] + rectangle[1][2]) / 2
    local water_range = math.abs(rectangle[2][2] - rectangle[1][2]) / 2

    peak["aux_optimal"] = aux_center
    peak["aux_range"] = aux_range
    peak["aux_max_range"] = water_range + 0.05

    peak["water_optimal"] = water_center
    peak["water_range"] = water_range
    peak["water_max_range"] = water_range + 0.05
  end

  return
  {
    order = "city",
    coverage = multiplier * 0.01,
    sharpness = 0.7,
    max_probability = multiplier * 0.7,
    peaks = { peak }
  }
end

local function commonAdjustments(factory)
    factory.minable = nil
    factory.next_upgrade = nil
    factory.fast_replaceable_group = nil
    factory.dying_explosion = "big-explosion"
    factory.max_health = 1600

    factory.scale_entity_info_icon = true
    factory.autoplace = city_autoplace_settings(0.093, {{1, 1}, {1, 1}})
    factory.create_ghost_on_death = false
    factory.flags = {
      -- "indestructible",
      -- "not-minable",
      "placeable-neutral", "not-deconstructable", "not-blueprintable",
      "not-rotatable", "not-repairable", "not-flammable", "hide-alt-info"
    }
    factory.collision_mask = factory.collision_mask or {"item-layer", "object-layer", "player-layer", "water-tile"}
    table.insert(factory.collision_mask, "resource-layer")
    factory.resistances = {{type="poison", percent=90}, {type="acid", percent=80}, {type="physical", percent=70},
        {type="fire", percent=70}, {type="explosion", percent=-100}}

    factory.has_backer_name = nil
end

local function create_city()
    local name = "at-city"
    local city = table.deep_copy(data.raw["assembling-machine"]["assembling-machine-3"])
    local icon = "__AutomationTycoon__/graphics/icons/big-assembly.png"

    city.name = name
    city.icon = icon
    city.localised_name = "City"

    city.collision_box = {{-8.1, -8.1}, {8.1, 8.1}}
    city.selection_box = {{-8.8, -9}, {8.8, 9}}
    city.drawing_box = {{-8.8, -8.8}, {8.8, 8.8}}

    city.crafting_categories = {"at-ucoin"}
    city.crafting_speed = 1
    city.order = "a"

    -- city.energy_usage =
    city.ingredient_count = 10
    city.module_specification.module_slots = 5
    city.map_color = {r=103, g=247, b=247}

    city.energy_source = {
      type = "void",
      render_no_power_icon = false,
      render_no_network_icon = false
    }

    city.fixed_recipe = "at-".. "ucoin" .."-to-ucoin"

    commonAdjustments(city)

    local function fluidBox(type, position)
        retvalue = {
                production_type = type,
                pipe_picture = assembler3pipepictures(),
                pipe_covers = pipecoverspictures(),
                base_area = 10,
                pipe_connections = {{ type=type, position=position }},
                secondary_draw_orders = { north = -1 }
            }
        if type == "input" then
            retvalue.base_level = -1
        else
            retvalue.base_level = 1
        end
        return retvalue
    end

        city.fluid_boxes = {
            fluidBox("input", {0, -9}),
            fluidBox("input", {-9, 0}),
            fluidBox("output", {9, 0}),
            fluidBox("output", {0, 9}),
        }

    adjustVisuals(city, 6, 1/32)

    data.raw["assembling-machine"][name] = city
end

create_city()
