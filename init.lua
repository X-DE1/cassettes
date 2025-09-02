local S = minetest.get_translator("cassettes")

local path = minetest.get_modpath("cassettes")

cassettes = {}
cassettes.registered_cassettes = {}
cassettes.after = {}

function cassettes.register_cassette(name, def)
	def.stack_max = 1
	
	local music_name = def.music_name
	def.music_name = nil

	minetest.register_craftitem(":" .. name, def)

	cassettes.registered_cassettes[name] = music_name
end

local handlers = {}

minetest.register_node("cassettes:cassette_player", {
	description = S("Cassette player"),
	paramtype2 = "facedir",
	stack_max = 1,
    drawtype = "mesh",
    mesh = "cassette_player.glb",
    tiles = {"cassette_player.png"},
    wield_scale = { x = 1.4, y = 1.4, z = 1.4 },
    selection_box = {
        type = 'fixed',
        fixed = {-0.5, -0.5, -0.15, 0.5, 0.5, 0.25}
    },
    collision_box = {
        type = 'fixed',
        fixed = {-0.5, -0.5, -0.15, 0.5, 0.5, 0.25}
    },
	groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
	sounds = default.node_sound_wood_defaults(),

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 1)
	end,

	on_destruct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		if inv:is_empty("main") then return end

		local drop_pos = minetest.find_node_near(pos, 1, "air")
		if not drop_pos then drop_pos = {x = pos.x, y = pos.y + 1, z = pos.z} end

		minetest.add_item(drop_pos, inv:get_stack("main", 1))
		inv:remove_item("main", inv:get_stack("main", 1))

		local pos_string = minetest.pos_to_string(pos)

		if handlers[pos_string] then
			minetest.sound_stop(handlers[pos_string])
		end
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local name = clicker:get_player_name()

		local pos_string = minetest.pos_to_string(pos)

		if inv:is_empty("main") then
			local item_name = itemstack:get_name()
			local music_name = cassettes.registered_cassettes[item_name]

			if not music_name then return end

			inv:set_stack("main", 1, itemstack:take_item())

			local handle = minetest.sound_play(music_name, {
				pos = pos,
				gain = 0.5,
				max_hear_distance = 25,
				loop = true
			})

			handlers[pos_string] = handle

			meta:set_string("music_name", music_name) -- for LBM

			if minetest.get_modpath("mcla_music_api") then

				mcla_music_api.stop_playback(clicker)
			
				if cassettes.after[name] then
					cassettes.after[name]:cancel()
				end
				
				cassettes.after[name] = minetest.after(240, function()
					mcla_music_api.next_song(clicker)
				end)
				
			end
			
		else
			local drop_pos = minetest.find_node_near(pos, 1, "air")
			if not drop_pos then drop_pos = {x = pos.x, y = pos.y + 1, z = pos.z} end

			minetest.add_item(drop_pos, inv:get_stack("main", 1))
			inv:remove_item("main", inv:get_stack("main", 1))

			if handlers[pos_string] then
				minetest.sound_stop(handlers[pos_string])
			end
		end
	end
})

minetest.register_lbm({
	name = "cassettes:resume_playing",
	nodenames = "cassettes:cassette_player",
	action = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		local pos_string = minetest.pos_to_string(pos)

		if inv:is_empty("main") then return end
		if handlers[pos_string] then return end

		local music_name = meta:get_string("music_name")
		local handle = minetest.sound_play(music_name, {
			pos = pos,
			gain = 0.5,
			max_hear_distance = 25,
			loop = true
		})

		handlers[pos_string] = handle
	end
})

minetest.register_craft({
	output = "cassettes:cassette_player",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:wood", "default:mese_crystal", "group:wood"},
		{"group:wood", "group:wood", "group:wood"}
	}
})

if minetest.get_modpath("mcla_music_api") then

	minetest.register_on_joinplayer(function(player)
		minetest.after(0.1, function()
			mcla_music_api.set_volume(player, 15)
		end)
	end)
end


