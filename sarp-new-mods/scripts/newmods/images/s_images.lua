-- Fernando
local path = "files/img/%s.png"
local temppath = "files/img_tmp/%s.png"

local images = {}

function loadAllImages(reload)

	images = {}
	for k, modType in pairs(availableModTypes) do

		local xmlpath = string.format(xmlPath, modType)
		local xml = xmlLoadFile(xmlpath)
		if xml then

			local mods = xmlNodeGetChildren(xml)
			for i, mod in pairs(mods) do

				local attrs = xmlNodeGetAttributes ( mod )

				local foundUpid
			    for name, value in pairs ( attrs ) do

			        if tostring(name) == "id" and tonumber(value) then--modelid
			        	local p = string.format(path, value)
			        	if fileExists(p) then
			        		images[tonumber(value)] = p
			        		-- outputDebugString("image loaded: "..p)
			        	end
			        end

			        if tostring(name)=="upid" and tonumber(value) then --upid
			        	foundUpid = tonumber(value)
			        end
			    end

			    if foundUpid then
				    -- temp image stored
				    local p = string.format(temppath, -foundUpid)
		        	if fileExists(p) then
		        		images[-foundUpid] = p
		        		-- outputDebugString("temp image loaded: "..p)
		        	end
		        end
			end
			xmlUnloadFile(xml)
		end
	end

	if reload then
		-- refresh all online players images
		for k, player in ipairs(getElementsByType("player")) do
			triggerClientEvent(player, "newmods:deleteImages", player)
		end
	end
end
addEvent("newmods:loadAllImages", true)
addEventHandler("newmods:loadAllImages", root, loadAllImages)

addEventHandler( "onResourceStart", resourceRoot,
function()

	loadAllImages()

end)

function getAnImage(id)
	local filedata = false
	id = tonumber(id)
	if id then
		local imgp = images[id]
		if imgp then
			if fileExists(imgp) then
				local f = fileOpen(imgp)
				if f then
					local count = fileGetSize(f)
	                local data = fileRead(f, count)
	                filedata = data
	                fileClose(f)
	                -- outputDebugString("Found image "..id)
				end
			else
				-- the image was deleted from the filesystem
			end
		end
	end

	return filedata
end

function obtainImage(id)
	local data = getAnImage(id)
	if data then
		triggerClientEvent(client, "newmods:receiveImage", client, id, data)
	end
end
addEvent("newmods:obtainImage", true)
addEventHandler("newmods:obtainImage", root, obtainImage)

function storeImage(id, data, giveresponse, theMod)
	id = tonumber(id)
	if id and data then
		local fp = string.format(path, id)
		if id < 0 then
			fp = string.format(temppath, id)
		end

		-- delete if exists
		if fileExists(fp) then
			fileDelete(fp)
		end

		local f = fileCreate(fp)
		if f then
			fileWrite(f, data)
			fileClose(f)
			images[id] = fp

			if giveresponse then
				local respMsg = "image validated!!"
				triggerEvent("newmods:makeResponse", client, client, giveresponse, true, respMsg, theMod)
				return true
			end
		end
	end
	triggerEvent("newmods:makeResponse", client, client, giveresponse, false, "Unexpected error occured!")
end
addEvent("newmods:storeImage", true)
addEventHandler("newmods:storeImage", root, storeImage)

function deleteModImage(id)
	if images[id] then

		local fp = string.format(path, id)
		if id < 0 then
			fp = string.format(temppath, id)
		end
		if fileExists(fp) then
			fileDelete(fp)
			loadAllImages(true)
			return true
		end
	end
	return false
end

function moveImageToMain(id, newid)
	if images[id] and id < 0 and newid then

		local fp = string.format(temppath, id)
		local newp = string.format(path, newid)

		if fileExists(fp) then
			if fileCopy(fp, newp, true) then
				fileDelete(fp)
				loadAllImages(true)
				return true
			end
		end
	end
	return false
end

function moveImageToTmp(id, newid)
	if images[id] and id > 0 and newid then

		local fp = string.format(path, id)
		local newp = string.format(temppath, newid)

		if fileExists(fp) then
			if fileCopy(fp, newp, true) then
				loadAllImages(true)
				return true
			end
		end
	end
	return false
end


function justMoveImage(id, newid)
	local fp = string.format(temppath, id)
	local newp = string.format(path, newid)

	if fileExists(fp) then
		if fileCopy(fp, newp, true) then
			print("IMG MOVED: "..id.." -> "..newid)
			fileDelete(fp)
			loadAllImages(true)
			return true
		end
	end
	return false
end

function fetchCallBack( responseData, errorno, player, id, giveresponse, theMod)
	if errorno == 0 then
		triggerClientEvent( player, "newmods:testImage", resourceRoot, responseData, id, giveresponse, theMod)
	else

		if giveresponse then
			triggerEvent("newmods:makeResponse", player, player, giveresponse, false, "Error fetching image from URL")
		end
	end
end

-- image response -> continue uploading mod?
function makeResponse(player, rtype, success, msg, theMod)
	if isElement(player) then

		if success then
			if rtype == "playerUpload" and theMod then
				-- decide availability of mod
				triggerEvent("newmods:validateModAvailability", player, theMod[1], theMod[2])
			elseif rtype == "staffUpload" then
				-- admin just changing image of the mod upload request
				-- success

				-- reload for everyone
				for k, p in ipairs(getElementsByType("player")) do
					triggerClientEvent(p, "newmods:deleteImages", p)
				end


				triggerClientEvent(player, "modloader:receiveUploadEditConfirmation", player, true, msg.."\nMod preview image successfully changed.")
			end
		else

			if rtype == "playerUpload" then
				triggerClientEvent(player, "modloader:receiveUploadConfirmation_notFinal", player, false, msg)
			elseif rtype == "staffUpload" then
				-- admin just changing image of the mod upload request
				-- failed
				triggerClientEvent(player, "modloader:receiveUploadEditConfirmation", player, false, msg)
			end
		end
	end
end
addEvent("newmods:makeResponse", true)
addEventHandler("newmods:makeResponse", root, makeResponse)

function fetchImageFromURL(id, url, giveresponse, theMod)
	local player = client or source

	if GetFileExtension(url) ~= ".png" then
		if giveresponse then
			local respMsg = "Image URL has to end in .png | Upload to imgur.com and right click > Copy direct image URL"
			triggerEvent("newmods:makeResponse", player, player, giveresponse, false, respMsg)
			return
		end
	end

	id = tonumber(id)
	if id and url then
		-- more checks on clientside
		fetchRemote ( url, fetchCallBack, "", false, player, id, giveresponse, theMod )
	end
end
addEvent("newmods:fetchImageFromURL", true)
addEventHandler("newmods:fetchImageFromURL", root, fetchImageFromURL)
