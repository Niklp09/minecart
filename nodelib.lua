--[[

	Minecart
	========

	Copyright (C) 2019-2021 Joachim Stolberg

	MIT
	See license.txt for more information
	
]]--

-- for lazy programmers
local M = minetest.get_meta
local S = minecart.S
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2P = minetest.string_to_pos

function minecart.get_nodecart_nearby(pos, param2, radius)	
	local pos2 = param2 and vector.add(pos, minecart.param2_to_dir(param2)) or pos
	local pos3 = minetest.find_node_near(pos2, radius or 0.5, minecart.lCartNodeNames, true)
	if pos3 then
		return pos3, minetest.get_node(pos3)
	end
end

-- Convert node to entity and start cart
function minecart.start_nodecart(pos, node_name, puncher)
	local owner = M(pos):get_string("owner")
	if minecart.is_owner(puncher, owner) then
		local entity_name = minecart.tEntityNames[node_name]
		local objID, obj = minecart.node_to_entity(pos, node_name, entity_name)
		if objID then
			local entity = obj:get_luaentity()
			entity.is_running = true
		end
	end
end

-- Player places the node
function minecart.on_nodecart_place(itemstack, placer, pointed_thing)
	
	local add_cart = function(pos, node_name, param2, owner)
		local ndef = minetest.registered_nodes[node_name]
		local node = minetest.get_node(pos)
		local rail = node.name
		minetest.swap_node(pos, {name = node_name, param2 = param2})
		local meta = M(pos)
		meta:set_string("removed_rail", rail)
		meta:set_string("owner", owner)
		meta:set_string("infotext", 
				minetest.get_color_escape_sequence("#FFFF00") .. owner .. ": 0")
		--meta:set_string("cart_pos", P2S(pos))
		if ndef.after_place_node then
			ndef.after_place_node(pos)
		end
	end
	
	local node_name = itemstack:get_name()
	local param2 = minetest.dir_to_facedir(placer:get_look_dir())
	local owner = placer:get_player_name()
	
	-- Add node
	if minecart.is_rail(pointed_thing.under) then
		add_cart(pointed_thing.under, node_name, param2, owner)
		placer:get_meta():set_string("cart_pos", P2S(pointed_thing.under))
	elseif minecart.is_rail(pointed_thing.above) then
		add_cart(pointed_thing.above, node_name, param2, owner)
		placer:get_meta():set_string("cart_pos", P2S(pointed_thing.above))
	else
		return itemstack
	end

	minetest.sound_play({name = "default_place_node_metal", gain = 0.5},
		{pos = pointed_thing.above})

	if not (creative and creative.is_enabled_for
			and creative.is_enabled_for(placer:get_player_name())) then
		itemstack:take_item()
	end
	
	minetest.show_formspec(owner, "minecart:userID_node",
                "size[4,3]" ..
                "label[0,0;Enter cart number:]" ..
                "field[1,1;3,1;userID;;]" ..
                "button_exit[1,2;2,1;exit;Save]")	
	
	return itemstack
end

function minecart.on_nodecart_punch(pos, node, puncher, pointed_thing)
	--minecart.start_nodecart(pos, node.name, puncher)
end

function minecart.on_nodecart_dig(pos, node, digger)
	local meta = M(pos)
	local userID = meta:get_int("userID")
	local owner = meta:get_string("owner")
	local ndef = minetest.registered_nodes[node.name]
	
	if not ndef.can_dig or ndef.can_dig(pos, digger) then
		minecart.add_node_to_player_inventory(pos, digger, node.name)
		node.name = M(pos):get_string("removed_rail")
		print("on_nodecart_dig", userID, owner, node.name)
		if node.name == "" then
			node.name = "carts:rail"
		end
		minetest.swap_node(pos, node)
		minecart.update_cart_status(owner, userID)
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "minecart:userID_node" then
		if fields.exit == "Save" or fields.key_enter == "true" then
			local cart_pos = S2P(player:get_meta():get_string("cart_pos"))
			local owner = M(cart_pos):get_string("owner")
			local pname = player:get_player_name()
			if owner == pname then
				local userID = tonumber(fields.userID) or 0
				M(cart_pos):set_int("userID", userID)
				M(cart_pos):set_string("infotext", 
						minetest.get_color_escape_sequence("#FFFF00") ..
						player:get_player_name() .. ": " .. userID)
				minecart.update_cart_status(owner, userID, true)
			end
		end
		return true
	end
    return false
end)
