local mysql = exports.mysql

-- keep track of all clothing items, used in shops afterwards
savedClothing = {}

local fileNames = {}
local errorLoading = false

-- Fernando:
-- store encrypted file names so they can be used in case of needing to clear cache
function encryptFileNameServer(text)
	local new = sha256(tostring(text))
	if new then addFilenameToList(new) end
	return new
end

function addFilenameToList(name)

	if errorLoading then return end
	fileNames[name] = true
end

addEventHandler( "onResourceStop", resourceRoot,
function ()
	-- Save the file names list to file
	local file
	if not fileExists(listFilePath) then
		file = xmlCreateFile(listFilePath, rootNodeName)
	else
		file = xmlLoadFile(listFilePath)
	end
	if not file then

		return print("Error(4) opening file: "..listFilePath)
	end

	local names = xmlNodeGetChildren(file)
	if not names then
		return print("Error(4) getting file names on parent: "..rootNodeName)
	end

	-- Don't add to the file those already there
	for i,n in pairs(names) do
		local nn = xmlNodeGetName(n)
    	if tostring(nn) == tostring(entryNodeName) then
    		local nv = tostring(xmlNodeGetValue(n))
    		if fileNames[nv] then
    			fileNames[nv] = nil
    		end
    	end
	end

	for fileName,_  in pairs(fileNames) do
		local newEntry = xmlCreateChild(file, entryNodeName)
	    if not newEntry then
	    	break
	    end
	    xmlNodeSetValue(newEntry, fileName)
    end

    xmlSaveFile(file)
    xmlUnloadFile(file)
end)


addEventHandler( "onResourceStart", resourceRoot,
function()
	-- Load saved file names into Lua table

	local file
	if not fileExists(listFilePath) then
		file = xmlCreateFile(listFilePath, rootNodeName)
	else
		file = xmlLoadFile(listFilePath)
	end
	if not file then

		errorLoading = true
		return print("Error(3) opening file: "..listFilePath)
	end

    local names = xmlNodeGetChildren(file)
    if not names then
    	errorLoading = true
    	xmlUnloadFile(file)
		return print("Error(3) getting file names on parent: "..rootNodeName)
    end

    local count = 0
    for k, n in pairs(names) do
    	local nn = xmlNodeGetName(n)
    	if tostring(nn) == tostring(entryNodeName) then
    		local nv = tostring(xmlNodeGetValue(n))
    		if nv then
    			local fn = string.format(cacheFileNameServer, nv)
    			if not fileExists(fn) then
	    			xmlDestroyNode(n)
	    		else
	    			fileNames[nv] = true
	    			count = count +1
	    		end
    		else
	    		xmlDestroyNode(n)
	    	end
    	else
	    	xmlDestroyNode(n)
	    end
    end

    xmlSaveFile(file)
    xmlUnloadFile(file)

    -- print("[clothes-system] Found "..count.." cached files (server).")
end)

function flushClothesSystemCache(thePlayer)
	if not exports.integration:isPlayerScripter(thePlayer) then return end
	-- Deletes all cached files
	local count = 0
	for fileName,_ in pairs(fileNames) do
		local fn = string.format(cacheFileNameServer, fileName)
		if fileExists(fn) then
			fileDelete(fn)
			fileNames[fileName] = nil
			count = count + 1
		end
	end

	local delay = 10000
	outputChatBox("Flushed "..count.." custom skin textures (server). Restarting in "..(delay/1000).." seconds.", thePlayer, 211, 122, 255)

	-- Flush online clients
	for k, player in ipairs(getElementsByType("player")) do
		triggerClientEvent(player, "clothes-system:flush_client", player)
	end

	setTimer(restartResource, delay, 1, getThisResource())
end
addCommandHandler("flushserver", flushClothesSystemCache, false, false)

-- returns the file path for a texture file
function getPath(clothing_id)
	return string.format(cacheFileNameServer, encryptFileNameServer(clothing_id))
end

-- addEventHandler('onResourceStop', resourceRoot, function()
	-- for key, value in pairs(savedClothing) do
		-- local clothingID = tonumber(key)
		-- local date_added = value.date
		-- local date_manufactured = value.mdate

		-- if value.mdate and value.mdate > 0 and value.mdate > exports.datetime:now() then
			-- outputDebugString("Resetting manufactured_date for skin " .. clothingID)
			-- exports.mysql:query_free("UPDATE `clothing` SET manufactured_date=NOW() WHERE id=" .. clothingID)
		-- end
	-- end
-- end)

addEventHandler('onResourceStart', resourceRoot, function()
	dbQuery(function (qh)
		local result, num_affected_rows, last_insert_id = dbPoll ( qh, 0 )
		if result then
			local count = 0
			for _, row in ipairs(result) do
				row.id = tonumber(row.id)
				row.skin = tonumber(row.skin)
				row.price = tonumber(row.price)
				row.creator_charname = row.creator_charname and string.gsub(row.creator_charname, "_", " ") or getGtaDesigners()
				row.creator_char = tonumber(row.creator_char)
				row.for_sale_until = tonumber(row.for_sale_until) or nil
				row.date = tonumber(row.date)
				row.mdate = tonumber(row.mdate) or 0
				row.fmdate = row.fmdate and row.fmdate or nil
				row.distribution = tonumber(row.distribution)
				row.sold = tonumber(row.sold) or 0
				row.new_textures = row.new_textures and fromJSON(row.new_textures) or {}
				
				savedClothing[row.id] = row
				count = count + 1
			end
		end
	end, {}, exports.mysql:getConn('mta') , "SELECT cl.sold, cl.id, cl.skin, url, new_textures, cl.description, cl.price, cl.creator_char, cl.distribution, "..
	"DATE_FORMAT(cl.date,'%b %d, %Y at %h:%i %p') AS fdate, "..
	"TO_SECONDS(cl.date) AS date, "..
	"DATE_FORMAT(cl.manufactured_date,'%b %d, %Y at %h:%i %p') AS fmdate, "..
	"TO_SECONDS(cl.manufactured_date) AS mdate, "..
	"CASE WHEN cl.creator_char>0 THEN c.charactername ELSE f.name END AS creator_charname, "..
	"CASE WHEN cl.for_sale_until IS NOT NULL THEN TO_SECONDS(cl.for_sale_until) ELSE 0 END AS for_sale_until "..
	"FROM clothing cl LEFT JOIN characters c ON cl.creator_char=c.id "..
	"LEFT JOIN factions f ON cl.creator_char=-f.id "..
	"ORDER BY cl.date DESC, cl.id DESC" )
end)


-- loads a skin from an url
function loadFromURL(data, id)
	local url = data.url
	fetchRemote(url, "clothes", function(str, errno)
		if str == 'ERROR' then
			triggerEvent('clothing:delete', resourceRoot, id)
		else
			local file = fileCreate(getPath(id))
			fileWrite(file, str)
			fileClose(file)

			for k, player in pairs(data.pending) do
				triggerClientEvent(player, 'clothing:file', resourceRoot, id, str)
			end
			data.pending = nil
		end
	end)
end

-- loads the multiple textures on one skin
-- (new) Fernando 21/08/2021
function loadFromMultipleURLs_New(data, id)
	--todo
end

-- send clothing to the client
addEvent( 'clothing:stream', true )
addEventHandler( 'clothing:stream', resourceRoot,
	function(id)
		local id = tonumber(id)
		-- if its not a number, this'll fail
		if type(id) == 'number' then
			local data = savedClothing[id]
			if data then
				local path = getPath(id)
				if fileExists(path) then
					local file = fileOpen(path, true)
					if file then
						local size = fileGetSize(file)
						local content = fileRead(file, size)

						if #content == size then
							triggerClientEvent(client, 'clothing:file', resourceRoot, id, content)
							fileClose(file)
						else
							fileClose(file)
							fileDelete(path)
						end
					else
						fileClose(file)
						fileDelete(path)
					end
				else
					-- try to reload the file from the given url
					if data.pending then
						table.insert(data.pending, client)
					else
						data.pending = { client }
						loadFromURL(data, id)
						-- loadFromMultipleURLs_New(data, id)
					end
				end
			end
		end
	end, false)

addEvent('clothes:duty:fetchFactionSkins', true)
addEventHandler('clothes:duty:fetchFactionSkins', root, function ()
	local fid = getElementData(source, 'faction')
	local tab = {}
	for id, value in pairs(savedClothing) do
		if value.distribution == 5 and fid[-value.creator_char] then
			table.insert(tab, value.skin..':'..id)
		end
	end
	triggerClientEvent( source, 'faction:dutySkins', source, tab)
end)

addEvent( 'clothes:tempfix', true )
addEventHandler( 'clothes:tempfix', resourceRoot, function ()
	local theResource = getResourceFromName("clothes-system")
	restartResource( theResource )
end)


-- Temp
-- Find skins uploaded by non existing chars
function findBrokenUploads(thePlayer, cmd)
	if not exports.integration:isPlayerScripter(thePlayer) then return end

	local count = 0
	local query = mysql:query("SELECT * FROM `clothing` WHERE `creator_char`>0")
	while true do
		local row = mysql:fetch_assoc(query)
		if not row then break end

		local charName = exports.cache:getCharacterNameFromID(tonumber(row["creator_char"]))
		if not charName then
			outputChatBox("ID "..row["id"].." | By "..row["creator_char"], thePlayer,255,194,14)
			count = count + 1
		end
	end
	mysql:free_result(query)

	outputChatBox("Total "..count.." broken custom clothes uploaded.", thePlayer,255,126,0)
end
addCommandHandler("brokenclothes", findBrokenUploads, false,false)