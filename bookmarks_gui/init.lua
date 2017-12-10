--[[

Bookmarks GUI for Minetest

Copyright (c) 2012 cornernote, Brett O'Donnell <cornernote@gmail.com>
Source Code: https://github.com/cornernote/minetest-bookmarks_gui
License: BSD-3-Clause https://raw.github.com/cornernote/minetest-bookmarks_gui/master/LICENSE

]]--

-- expose api
bookmarks_gui = {}

-- filename
bookmarks_gui.filename = minetest.get_worldpath()..'/bookmarks_gui'

-- load_bookmarks
local bookmarkspos = {}
local load_bookmarks = function()
    local input = io.open(bookmarks_gui.filename..".bookmarks", "r")
    if input then
        while true do
            local x = input:read("*n")
            if x == nil then
                break
            end
            local y = input:read("*n")
            local z = input:read("*n")
            local name = input:read("*l")
			table.insert(bookmarkspos,{name=name:sub(2),x=x,y=y,z=z})
        end
        io.close(input)
    else
        bookmarkspos = {}
    end
end
load_bookmarks() -- run it now

-- set
bookmarks_gui.set = function(name, pos)
	name = string.lower(string.gsub(name, "%W", "_"))
	for i, v in ipairs(bookmarkspos) do
		if v.name==name then
			table.remove(bookmarkspos,i)
		end
	end
	table.insert(bookmarkspos,{name=name,x=pos.x,y=pos.y+1,z=pos.z})
	-- save the bookmarks data from the table to the file
	local output = io.open(bookmarks_gui.filename..".bookmarks", "w")
	for i, v in ipairs(bookmarkspos) do
		if v ~= nil then
			output:write(math.floor(v.x).." "..math.floor(v.y).." "..math.floor(v.z).." "..v.name.."\n")
		end
	end
	io.close(output)
end

-- del
bookmarks_gui.del = function(name, pos)
	name = string.lower(string.gsub(name, "%W", "_"))
	for i, v in ipairs(bookmarkspos) do
		if v.name==name then
			table.remove(bookmarkspos,i)
		end
	end
	-- save the bookmarks data from the table to the file
	local output = io.open(bookmarks_gui.filename..".bookmarks", "w")
	for i, v in ipairs(bookmarkspos) do
		if v ~= nil then
			output:write(math.floor(v.x).." "..math.floor(v.y).." "..math.floor(v.z).." "..v.name.."\n")
		end
	end
	io.close(output)
end

-- go 
bookmarks_gui.go = function(name, player)
	name = string.lower(string.gsub(name, "%W", "_"))
	local pos
	for i, v in ipairs(bookmarkspos) do
		if v.name==name then
			pos = v
			break
		end
	end
	if pos~=nil then
		-- move bookmark to the top of the list
		local bmp = {}
		for i,v in ipairs(bookmarkspos) do
			if v.name~=name then
				table.insert(bmp,v)
			end
		end
		table.insert(bmp,pos)
		bookmarkspos = bmp
		-- teleport player
		player:setpos(pos)
	end
end

-- formspec
bookmarks_gui.formspec = function()
	local formspec = ""
	local pages = bookmarks_gui.get_names()
	local x,y = 0,0
	local p
	for i = #pages,1,-1 do
		p = pages[i]
		if x == 8 then
			y = y+1
			x = 0
		end
		formspec = formspec .."button_exit["..(x)..","..(y)..";2,0.5;bookmarks_gui_jump;"..p.."]"
		x = x+2
	end
	if #pages == 0 then
		formspec = formspec
			.."label[2,2; --== Bookmarks GUI ==--]"
			.."label[2,3.5; Create as many bookmarks as you like!]"
			.."label[2,4.0; Simply enter a name for your bookmark]"
			.."label[2,4.5; then click Set to save.]"
	end
	formspec = formspec
		.."field[0.5,8.1;1.5,1;bookmarks_gui_go_name;;]"
		.."button_exit[1.5,8;1,0.5;bookmarks_gui_go;Go]"
		.."field[3.0,8.1;1.5,1;bookmarks_gui_del_name;;]"
		.."button_exit[4.0,8;1,0.5;bookmarks_gui_del;Del]"
		.."field[5.5,8.1;1.5,1;bookmarks_gui_set_name;;]"
		.."button_exit[6.5,8;1,0.5;bookmarks_gui_set;Set]"
	return formspec
end

-- get_names
bookmarks_gui.get_names = function()
	local pages = {}
	for i,v in ipairs(bookmarkspos) do
		table.insert(pages,v.name)
	end
	return pages
end

bookmarks_gui.form_update = function(player, fields)
	if fields.bookmarks_gui_set and fields.bookmarks_gui_set_name then
		bookmarks_gui.set(fields.bookmarks_gui_set_name, player:getpos())
	end
	if fields.bookmarks_gui_del and fields.bookmarks_gui_del_name then
		bookmarks_gui.del(fields.bookmarks_gui_del_name, player:getpos())
	end
	if fields.bookmarks_gui_go and fields.bookmarks_gui_go_name then
		bookmarks_gui.go(fields.bookmarks_gui_go_name, player)
	end
	if fields.bookmarks_gui_jump then
		bookmarks_gui.go(fields.bookmarks_gui_jump, player)
	end
end

sfinv.register_page("bookmarks_gui:places", {
	title = "Places",
	get = function(self, player, context)
		return sfinv.make_formspec(player, context, bookmarks_gui.formspec(), false)
	end,
	is_in_nav = function(self, player, context)
		return minetest.check_player_privs(player, { instructor = true})
	end,
	on_player_receive_fields = function(self, player, context, fields)
		if minetest.check_player_privs(player, { instructor = true}) then
			bookmarks_gui.form_update(player, fields)
			sfinv.set_page(player, "bookmarks_gui:places")
		end
	end,
})
