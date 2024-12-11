local loaded = { --[[ [clothing] = {tex = texture, shader = shader} ]] }
local streaming = { --[[ [clothing] = {players} ]] }
local players = {}

local fileNames = {}
local errorLoading = false

-- store encrypted file names so they can be used in case of needing to clear cache
function encryptFileNameClient(text)
	local new = sha256(tostring(text))
	if new then addFilenameToList(new) end
	return new
end

function addFilenameToList(name)

	if errorLoading then return end
	fileNames[name] = true
end

addEventHandler( "onClientResourceStop", resourceRoot,
function ()
	-- Save the file names list to file
	local file
	if not fileExists(listFilePath) then
		file = xmlCreateFile(listFilePath, rootNodeName)
	else
		file = xmlLoadFile(listFilePath)
	end
	if not file then

		return print("Error(6) opening file: "..listFilePath)
	end

	local names = xmlNodeGetChildren(file)
	if not names then
		return print("Error(6) getting file names on parent: "..rootNodeName)
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


addEventHandler( "onClientResourceStart", resourceRoot,
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
		return print("Error(5) opening file: "..listFilePath)
	end

    local names = xmlNodeGetChildren(file)
    if not names then
    	errorLoading = true
    	xmlUnloadFile(file)
		return print("Error(5) getting file names on parent: "..rootNodeName)
    end

    local count = 0
    for k, n in pairs(names) do
    	local nn = xmlNodeGetName(n)
    	if tostring(nn) == tostring(entryNodeName) then
    		local nv = tostring(xmlNodeGetValue(n))
    		if nv then
    			local fn = string.format(cacheFileName, nv)
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

    -- print("[clothes-system] Found "..count.." cached files.")
end)

function flushClothesSystemCache()

	-- Deletes all cached files
	local count = 0
	for fileName,_ in pairs(fileNames) do
		local fn = string.format(cacheFileName, fileName)
		if fileExists(fn) then
			fileDelete(fn)
			fileNames[fileName] = nil
			count = count + 1
		end
	end
	-- remove all current textures
	local count = flushSkin('player') + flushSkin('ped')
	outputChatBox("Flushed "..count.." loaded custom skin textures.", 110, 255, 221)
end
addEvent("clothes-system:flush_client", true)
addEventHandler("clothes-system:flush_client", root, flushClothesSystemCache)
addCommandHandler("flush", flushClothesSystemCache, false, false)

-- returns the file path for a texture file
function getPath(clothing_id)
	return string.format(cacheFileName, encryptFileNameClient(clothing_id))
end


-- skins with 2+ texture names:	12, 19, 21, 28, 30, 40, 46, 47, 55, 91, 93, 98, 100, 107, 110, 115, 116, 141, 156, 174, 223, 233, 249
local accessoires = { head = true, watchcro = true, neckcross = true, earing = true, glasses = true, specsm = true }

local fixedTextureNames = {
	[312] = {"psycho"},
}

local function getPrimaryTextureName(model_)

	local model = exports["sarp-new-mods"]:getRealModelID(model_)
	if model then
		local tnames = engineGetModelTextureNames(model)
		local f = fixedTextureNames[model]
		if f then
			tnames = f
		end

		if tnames then
			for k, v in ipairs(tnames) do
				if not accessoires[v] then
					return v
				end
			end
		else
			print("couldnt get tex names for "..model)
		end
	end
	return ""
end


addCommandHandler('getclothingtexture',
	function(command, model)
		local model_ = tonumber(model) or (getElementData(localPlayer, "skinID") or getElementModel(localPlayer))
		local model = exports["sarp-new-mods"]:getRealModelID(model_)
		if model then
			outputChatBox('Model ' .. model_ .. '  ('..model..') has ' .. (getPrimaryTextureName(model) or 'N/A') .. ' as primary texture.', 255, 127, 0)
		end
	end)

function getSkin(command)
	local skin = getElementData(localPlayer, "skinID") or getElementModel(localPlayer)
	local clothing = getElementData(localPlayer, "clothing:id") or "N/A"
	outputChatBox("This is skin #"..skin.." with the clothing ID #"..clothing)
end
addCommandHandler("skininfo", getSkin)
addCommandHandler("gskin", getSkin)
addCommandHandler("getskin", getSkin)

-- adds clothing to a player, possibly streaming it from the server if needed
function addClothing(player, clothing, event)
	removeClothing(player, event)

	local skinid = getElementData(player, "skinID") or getElementModel(player)

	if exports["SARP_Modloader"]:isReplacingSkin(skinid) then

		-- we should not apply texture to a skin that the player is replacing with the
		-- sarp modloader // Fernando
		-- february 2021

		-- outputDebugString("not adding clothes texture to "..skinid.." because replacing with mod")
		return
	end
	-- outputDebugString("adding clothes texture to "..skinid.."..")

	local texName = getPrimaryTextureName(skinid)

	-- does the shader for the relevant skin already exist?
	local L = loaded[clothing]
	if L then
		players[player] = { id = clothing, texName = texName }
		if getElementData(player, 'clothing:id') == clothing then
			engineApplyShaderToWorldTexture(L.shader, texName, player)
		end
	else
		-- shader not yet created, do we have the file available locally?
		local getNew = true
		local path = getPath(clothing)
		if fileExists(path) then
			getNew = false

			local texture = dxCreateTexture(path)
			if texture then
				local shader, t = dxCreateShader('tex.fx', 0, 0, true, 'ped')
				if shader then
					dxSetShaderValue(shader, 'tex', texture)

					engineApplyShaderToWorldTexture(shader, texName, player)

					loaded[clothing] = { texture = texture, shader = shader }
					players[player] = { id = clothing, texName = texName }
				else
					destroyElement(texture)
				end
			else
				fileDelete(path)
			end
		end
		if getNew then
			-- clothing not yet downloaded
			if streaming[clothing] then
				table.insert(streaming[clothing], player)
			else
				streaming[clothing] = { player }
				-- triggerServerEvent('clothing:stream', resourceRoot, clothing)
				triggerLatentServerEvent('clothing:stream', resourceRoot, clothing)
			end
			players[player] = { id = clothing, texName = texName, pending = true }
		end
	end
end

-- remove the clothes - that's rather easy
function removeClothing(player, event)
	local clothes = players[player]
	if clothes and loaded[clothes.id] and isElement(loaded[clothes.id].shader) then
		-- possibly clean up shaders
		local stillUsed = false
		for p, data in pairs(players) do
			if p ~= player and data.id == clothes.id then
				stillUsed = true
				break
			end
		end

		if stillUsed then
			if not clothes.pending then
				-- just remove the shader from that one player
				engineRemoveShaderFromWorldTexture(loaded[clothes.id].shader, clothes.texName, player)
			end
		else
			-- destroy the shader and texture since no player uses it
			local L = loaded[clothes.id]
			if L then
				destroyElement(L.texture)
				destroyElement(L.shader)

				loaded[clothes.id] = nil
			end
		end
		players[player] = nil
	end
end

-- file we asked for is there
addEvent('clothing:file', true)
addEventHandler( 'clothing:file', resourceRoot,
	function(id, content)
		if dxGetPixelsFormat(content) then
			local file = fileCreate(getPath(id))
			local written = fileWrite(file, content)
			fileClose(file)

			for _, player in ipairs(streaming[id]) do
				addClothing(player, id, 'clothing:file')
			end

			streaming[id] = nil
		else
			-- Remove invalid file
			triggerServerEvent('clothing:delete', resourceRoot, tonumber(clothing))
		end
	end, false)

-- initialize all skins upon resource startup
addEventHandler( 'onClientResourceStart', resourceRoot,
	function()
		for _, name in ipairs({'player', 'ped'}) do
			for _, p in ipairs(getElementsByType(name, getRootElement(), true)) do
				local clothing = getElementData(p, 'clothing:id')
				if clothing then
					addClothing(p, clothing, 'onClientResourceStart')
				end
			end
		end
	end)

-- apply skins when people are to be streamed in.
addEventHandler( 'onClientElementStreamIn', root,
	function()
		if getElementType(source) == 'player' or getElementType(source) == 'ped' then
			local clothing_id = getElementData(source, 'clothing:id')
			if clothing_id then
				addClothing(source, clothing_id, 'onClientElementStreamIn')
			end
		end
	end)

-- remove them when streamed out
addEventHandler( 'onClientElementStreamOut', root,
	function()
		if getElementType(source) == 'player' or getElementType(source) == 'ped' then
			if getElementData(source, 'clothing:id') then
				removeClothing(source, 'onClientElementStreamOut')
			end
		end
	end)

-- remove them when they quit
addEventHandler( 'onClientPlayerQuit', root,
	function()
		if getElementData(source, 'clothing:id') then
			removeClothing(source, 'onClientPlayerQuit')
		end
	end)

addEventHandler( 'onClientElementDestroy', root,
	function()
		if getElementType(source) == 'ped' and getElementData(source, 'clothing:id') then
			removeClothing(source, 'onClientElementDestroy')
		end
	end)

-- apply changed clothing
addEventHandler( 'onClientElementDataChange', root,
	function(name, oldValue, newValue)
		if name == 'clothing:id' and (isElement(source) and getElementType(source) == 'player' or getElementType(source) == 'ped') then -- isElementStreamedIn(source)
			local clothing_id = getElementData(source, 'clothing:id')
			if clothing_id then
				setTimer(function(element)
					addClothing(element, getElementData(element, 'clothing:id'), 'onClientElementDataChange')
				end, 50, 1, source)
			else
				removeClothing(source, 'onClientElementDataChange')
			end
		end
	end
)


function flushSkin(type)
	local count = 0
	for i, p in pairs(getElementsByType(type, getRootElement(), true)) do
		local id = getElementData(p, 'clothing:id')
		if id then
			removeClothing(p, 'flush')
			count = count + 1
			streaming[id] = nil
			addClothing(p, id, 'flush')
		end
	end
	return count
end

function flushSkins()
	flushClothesSystemCache()
end
addCommandHandler('flushskins', flushSkins, false)
