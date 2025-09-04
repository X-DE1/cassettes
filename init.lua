local S = minetest.get_translator("cassettes")

local path = minetest.get_modpath("cassettes")

cassettes = {}
cassettes.registered_cassettes = {}
cassettes.after = {}

function cassettes.register_cassette(name, def)
	
	minetest.register_craftitem(name, {
		description = def.description,
		inventory_image = "(casette1.png^[colorize:" .. def.color1 .. ")^(casette2.png^[colorize:" .. def.color2 .. ")",
	})
	
	def.stack_max = 1
	
	local music_name = def.music_name
	def.music_name = nil

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

cassettes.register_cassette("cassettes:forest", {
color1 = "#9AEA02:100",
color2 = "#BFC4BC:110",
description = "X-DE - Forest",
music_name = "forest"
})

cassettes.register_cassette("cassettes:icesheet", {
color1 = "#C96AB8:100",
color2 = "#81C871:100",
description = "X-DE - Icesheet",
music_name = "icesheet"
})

cassettes.register_cassette("cassettes:savanna", {
color1 = "#730304:100",
color2 = "#84FEB7:100",
description = "X-DE - Savanna",
music_name = "savanna"
})

cassettes.register_cassette("cassettes:taiga", {
color1 = "#6A46FC:100",
color2 = "#46FC69:100",
description = "X-DE - Taiga",
music_name = "taiga"
})

cassettes.register_cassette("cassettes:tundra", {
color1 = "#FFFFFF:100",
color2 = "#FFFFFF:100",
description = "X-DE - Tundra",
music_name = "tundra"
})

if minetest.get_modpath("mcla_music_api") then

	minetest.register_on_newplayer(function(player)
		minetest.after(0.1, function()
			mcla_music_api.set_volume(player, 40)
		end)
	end)

	mcla_music_api.register_song({
		name = "forest",
		title = "X-DE - Forest",
		length = 210,
	})

	mcla_music_api.register_song({
		name = "icesheet",
		title = "X-DE - Icesheet",
		length = 210,
	})

	mcla_music_api.register_song({
		name = "savanna",
		title = "X-DE - Savanna",
		length = 210,
	})

	mcla_music_api.register_song({
		name = "taiga",
		title = "X-DE - Taiga",
		length = 210,
	})

	mcla_music_api.register_song({
		name = "tundra",
		title = "X-DE - Tundra",
		length = 210,
	})

end
