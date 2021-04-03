--[[

	Minecart
	========

	Copyright (C) 2019-2021 Joachim Stolberg

	MIT
	See license.txt for more information
	
]]--

local S = minecart.S

print(dump(minecart.on_nodecart_place))

minetest.register_node("minecart:cart_node", {
	description = S("Minecart (Sneak+Click to pick up)"),
	tiles = {
		-- up, down, right, left, back, front		
			"carts_cart_top.png",
			"carts_cart_top.png",
			"carts_cart_side.png^minecart_logo.png",
			"carts_cart_side.png^minecart_logo.png",
			"carts_cart_side.png^minecart_logo.png",
			"carts_cart_side.png^minecart_logo.png",
		},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-8/16,-8/16,-8/16,  8/16, 8/16,-7/16},
			{-8/16,-8/16, 7/16,  8/16, 8/16, 8/16},
			{-8/16,-8/16,-8/16, -7/16, 8/16, 8/16},
			{ 7/16,-8/16,-8/16,  8/16, 8/16, 8/16},
			{-8/16,-8/16,-8/16,  8/16,-6/16, 8/16},
		},
	},
	collision_box = {
        type = "fixed",
        fixed = {
            {-8/16,-8/16,-8/16,  8/16,-4/16, 8/16},
        },
    },
	paramtype2 = "facedir",
	paramtype = "light",
	use_texture_alpha = minecart.CLIP,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 2, crumbly = 2, choppy = 2},
	node_placement_prediction = "",
	
	on_place = minecart.on_nodecart_place,
	--on_punch = minecart.on_nodecart_punch,
	on_dig = minecart.on_nodecart_dig,
	
	set_cargo = function(pos, data)
		for _,item in ipairs(data or {}) do
			minetest.add_item(pos, ItemStack(item))
		end
	end,
	
	get_cargo = function(pos)
		local data = {}
		for _, obj in pairs(minetest.get_objects_inside_radius(pos, 1)) do
			local entity = obj:get_luaentity()
			if not obj:is_player() and entity and entity.name == "__builtin:item" then
				obj:remove()
				data[#data + 1] = entity.itemstring
			end
		end
		return data
	end,
})

minecart.register_cart_entity("minecart:cart", "minecart:cart_node", {
	initial_properties = {
		physical = false,
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		visual = "wielditem",
		textures = {"minecart:cart_node"},
		visual_size = {x=0.66, y=0.66, z=0.66},
		static_save = true,
	},
})


minetest.register_craft({
	output = "minecart:cart_node",
	recipe = {
		{"default:steel_ingot", "default:cobble", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	},
})

