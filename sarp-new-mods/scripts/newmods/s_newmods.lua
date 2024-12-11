-- Fernando

local useTriggerLatentClient = false
local clientLatentBW = 500000

skinMods = {}
vehicleMods = {}
reloadModsTime = 60000

local restartTimer
local delay = 10000

function updateMetaXml() -- updates meta.xml according with current mod uploads

	local metaXML = xmlLoadFile("meta.xml")
	if not metaXML then
		return false, "Failed to open meta.xml"
	end
	local addedAny = false

	-- outputChatBox("AUTO UPDATING meta.xml", root, 0,255,0)--testing
	local nodes = xmlNodeGetChildren(metaXML)

	-- Check if any of the listed mod files no longer exist in the meta.xml
	for i, node in pairs(nodes) do
		if xmlNodeGetName(node) == "file" then
			local download = xmlNodeGetAttribute(node, "download")
			if download and download == "false" then
				local src = xmlNodeGetAttribute(node, "src")
				if not fileExists(src) then
					xmlDestroyNode(node)
					-- print("AUTO-META","Destroyed XML node coz file not found:", src)
				end
			end
		end
	end

	nodes = xmlNodeGetChildren(metaXML)

	-- Check if all mod files stored in Uploads exist in the meta.xml
	-- that are accepted
	for modType, v in pairs(getModUploads()) do
		for k, upload in pairs(v) do

			local dff = upload.dffPath
			local txd = upload.txdPath
			
			if upload.status == "Accepted" and dff and txd then

				for _, filename in pairs({dff,txd}) do

					if not fileExists(filename) then
						local found = nil

						for i, node in pairs(nodes) do
							if node and xmlNodeGetName(node) == "file" then
								local src = xmlNodeGetAttribute(node, "src")
								if string.lower(src) == string.lower(filename) then
									found = node
									break
								end
							end
						end

						if found then
							xmlDestroyNode(found)
							-- print("AUTO-META","Upload #"..upload.upid, "Destroyed XML node coz file not found:", filename)
						end
					else

						local found = nil

						for i, node in pairs(nodes) do
							if node and xmlNodeGetName(node) == "file" then
								local src = xmlNodeGetAttribute(node, "src")
								if string.lower(src) == string.lower(filename) then
									found = node
									break
								end
							end
						end

						if not found then
							local node = xmlCreateChild(metaXML, "file")
							xmlNodeSetAttribute(node, "src", filename)
							xmlNodeSetAttribute(node, "download", "false") -- Important: so that we control file download
							-- print("AUTO-META","Upload #"..upload.upid, "Saved in XML:", filename)
							addedAny = true
						end
					end
				end
			end
		end
	end

	xmlSaveFile(metaXML)
	xmlUnloadFile(metaXML)

	if addedAny then
		
		-- print("Added at least 1 mod to meta.xml | Restarting "..getResourceName(getThisResource()).." in "..(delay/1000).." secs")
		if isTimer(restartTimer) then killTimer(restartTimer) end
		restartTimer = setTimer(function()
			print("RESTARTING "..getResourceName(getThisResource()))
			restartResource(getThisResource())
		end, delay, 1)
		return false
	end
	return true
end

function loadOneMod(modType, modelID, doReturn)
	local player = client or source

	if availableModTypesBis[modType] then

		local path = string.format(xmlPath, modType)
		local xml = xmlLoadFile(path)
		if xml then

			local mods = xmlNodeGetChildren(xml)
			for i, mod in pairs(mods) do

				local preferredID, modName, modDff, modTxd

				local tab = {}

				local isaccepted = false
				local foundModelID, foundPurpose, foundUploadBy

				local foundGender, foundRace

	            local attrs = xmlNodeGetAttributes ( mod )
			    for name, value in pairs ( attrs ) do
			    	if tostring(name) == "status" then
			        	if tostring(value) == "Accepted" then
			        		isaccepted = true
			        	end
			        end
			        if tostring(name) == "upid" then
			        	tab.upid = tonumber(value)
			        end
			        if tostring(name) == "id" then
			        	tab.modelid = tonumber(value)
			        	foundModelID = tonumber(value)
			        end
			        if tostring(name) == "basemodel" then
			        	tab.basemodel = tonumber(value)
			        end
			        if tostring(name) == "title" then
			        	tab.title = tostring(value)
			        end
			        if tostring(name) == "purpose" then
			        	foundPurpose = tonumber(value)
			        end
			        if tostring(name) == "gender" then
			        	foundGender = tonumber(value)
			        end
			        if tostring(name) == "race" then
			        	foundRace = tonumber(value)
			        end
			        if tostring(name) == "uploadBy" then
			        	foundUploadBy = tonumber(value)
			        end
			        if tostring(name) == "dffPath" then
			        	tab.dffPath = tostring(value)
			        end
			        if tostring(name) == "txdPath" then
			        	tab.txdPath = tostring(value)
			        end
			    end

			    if (foundModelID and foundModelID == tonumber(modelID)) then

				    if isaccepted then

			    		if doReturn then
					    	xmlUnloadFile(xml)
					    	return tab
					    else
					    	if isTimer(restartTimer) then
					    		-- print("Not sending a mod to "..getPlayerName(player).." because server will restart")
					    	else
						    	if useTriggerLatentClient then
						    		triggerLatentClientEvent(player, "loadModFromServer", clientLatentBW, player, modType, tab)
						    	else
						    		triggerClientEvent(player, "loadModFromServer", player, modType, tab)
						    	end
						    end
					    end
				    end
			    end
			end

			xmlUnloadFile(xml)
		end
	end
end
-- addEvent("newmods:loadOneMod", true)
-- addEventHandler("newmods:loadOneMod", root, loadOneMod)



function loadModsOnServer(startUp)

	skinMods = {}
	vehicleMods = {}
	setElementData(getRootElement(), "moddedSkins", skinMods)
	setElementData(getRootElement(), "moddedVehicles", vehicleMods)

	local modType = "ped"
	local path = string.format(xmlPath, modType)
	local xml = xmlLoadFile(path)

	if xml then

		local mods = xmlNodeGetChildren(xml)
		for i, mod in pairs(mods) do

			local isaccepted = false
			local tab = {}

            local attrs = xmlNodeGetAttributes ( mod )
		    for name, value in pairs ( attrs ) do
		    	if tostring(name) == "status" then
		        	if tostring(value) == "Accepted" then
		        		isaccepted = true
		        	end
		        end
		        if tostring(name) == "id" then
		        	tab.modelid = tonumber(value)
		        end
		        if tostring(name) == "purpose" then
		        	tab.purpose = tonumber(value)
		        end
		        if tostring(name) == "gender" then
		        	tab.gender = tonumber(value)
		        end
		        if tostring(name) == "race" then
		        	tab.race = tonumber(value)
		        end
		        if tostring(name) == "uploadBy" then
		        	tab.uploadBy = tostring(value)
		        end
		        if tostring(name) == "title" then
		        	tab.title = tostring(value)
		        end
		        if tostring(name) == "uploadDate" then
		        	tab.uploadDate = tostring(value)
		        end
		    end

		    if isaccepted then

		    	if tab.modelid then
		    		table.insert(skinMods, {
		    			modelid = tab.modelid,
		    			purpose = tab.purpose or false,
		    			gender = tab.gender or 0,
		    			race = tab.race or 1,
		    			title = tab.title or false,
		    			uploadBy = tab.uploadBy or false,
		    			uploadDate = tab.uploadDate or false,
		    		})
		    	end

		    end
		end

		xmlUnloadFile(xml)
	end

	-- save table in data
	table.sort(skinMods, function(a,b) return a.modelid < b.modelid end)
	setElementData(getRootElement(), "moddedSkins", skinMods)


	-----
	modType = "vehicle"
	local path = string.format(xmlPath, modType)
	local xml = xmlLoadFile(path)

	if xml then

		local mods = xmlNodeGetChildren(xml)
		for i, mod in pairs(mods) do

			local isaccepted = false
			local tab = {}

            local attrs = xmlNodeGetAttributes ( mod )
		    for name, value in pairs ( attrs ) do
		    	if tostring(name) == "status" then
		        	if tostring(value) == "Accepted" then
		        		isaccepted = true
		        	end
		        end
		        if tostring(name) == "id" then
		        	tab.modelid = tonumber(value)
		        end
		        if tostring(name) == "upid" then
		        	tab.upid = tonumber(value)
		        end
		        if tostring(name) == "basemodel" then
		        	tab.basemodel = tonumber(value)
		        end
		        if tostring(name) == "purpose" then
		        	tab.purpose = tonumber(value)
		        end
		        if tostring(name) == "uploadBy" then
		        	tab.uploadBy = tostring(value)
		        end
		        if tostring(name) == "title" then
		        	tab.title = tostring(value)
		        end
		        if tostring(name) == "uploadDate" then
		        	tab.uploadDate = tostring(value)
		        end
		    end

		    if isaccepted then

		    	if tab.modelid then
		    		table.insert(vehicleMods, {
		    			upid = tab.upid,
		    			modelid = tab.modelid,
		    			basemodel = tab.basemodel,
		    			purpose = tab.purpose or false,
		    			title = tab.title or false,
		    			uploadBy = tab.uploadBy or false,
		    			uploadDate = tab.uploadDate or false,
		    		})
		    	end

		    end
		end

		xmlUnloadFile(xml)
	end

	-- save table in data
	table.sort(vehicleMods, function(a,b) return a.modelid < b.modelid end)
	setElementData(getRootElement(), "moddedVehicles", vehicleMods)
	-----

	if not startUp then
		-- refresh all online players images
		for k, player in ipairs(getElementsByType("player")) do
			triggerClientEvent(player, "newmods:deleteImages", player)
		end
	end

	updateMetaXml()
	return true
end

addEventHandler( "onResourceStart", resourceRoot,
function ()


	-- creating files if missing
	for k, modType in pairs(availableModTypes) do
		local path = string.format(xmlPath, modType)
		if not fileExists(path) then
			local f = fileCreate(path)
			if f then
				fileWrite(f, "<mods></mods>")
				fileClose(f)
			end
		end
	end
	if updateMetaXml() then
		if loadModsOnServer(true) then

			if VEHICLE_TESTING_ENABLED then
				-- testing /tmv
				testMakeVehicles()
			end

			-- iprint(getElementData(getRootElement(), "moddedSkins"))
			-- iprint(getElementData(getRootElement(), "moddedVehicles"))
		end
	end
end)

-- Exported (HTTP)
function getNewMods(modType)
	if modType then
		if modType == "vehicle" then
			return getElementData(getRootElement(), "moddedVehicles") or {}
		elseif modType == "ped" then
			return getElementData(getRootElement(), "moddedSkins") or {}
		end
	end
	return {
		["vehicle"] = (getElementData(getRootElement(), "moddedVehicles") or {}),
		["ped"] = (getElementData(getRootElement(), "moddedSkins") or {}),
	}
end

-- peds
function updateSkinForClientIfValid(skin)
	skin = tonumber(skin)
	local mod = loadOneMod("ped", skin, true)
	if mod then
		if isTimer(restartTimer) then
    		-- print("Not sending a mod to "..getPlayerName(client).." because server will restart")
    	else
			-- force set
			if useTriggerLatentClient then
				triggerLatentClientEvent(client, "loadModFromServer", clientLatentBW, client, "ped", mod)
			else
				triggerClientEvent(client, "loadModFromServer", client, "ped", mod)
			end
		end
	else
		-- invalid skin mod trying to be loaded
		outputConsole("Invalid skin detected: #"..skin, client)
		triggerClientEvent(client, "endLoading", client)
	end
end
addEvent("newmods:updateSkinForClientIfValid", true)
addEventHandler("newmods:updateSkinForClientIfValid", root, updateSkinForClientIfValid)

-- vehicles
function updateVehicleModel(vehModel)
	vehModel = tonumber(vehModel)
	local mod = loadOneMod("vehicle", vehModel, true)
	if mod then
		if isTimer(restartTimer) then
    		-- print("Not sending a mod to "..getPlayerName(client).." because server will restart")
    	else
			-- force set
			if useTriggerLatentClient then
				triggerLatentClientEvent(client, "loadModFromServer", clientLatentBW, client, "vehicle", mod)
			else
				triggerClientEvent(client, "loadModFromServer", client, "vehicle", mod)
			end
		end
	else
		-- invalid skin mod trying to be loaded
		outputConsole("Invalid vehicle model detected: #"..vehModel, client)
	end
end
addEvent("newmods:updateVehicleModel", true)
addEventHandler("newmods:updateVehicleModel", root, updateVehicleModel)

-- all uploads will be counted to prevent recycling IDs
function getNextAvailableID(modType)
	local newid = false
	if availableModTypesBis[modType] then

		local usedIDs = {}

		for k, modType in pairs(availableModTypes) do
			local path = string.format(xmlPath, modType)
			local xml = xmlLoadFile(path)
			if xml then

				local mods = xmlNodeGetChildren(xml)
				for i, mod in pairs(mods) do

					local attrs = xmlNodeGetAttributes ( mod )

					-- local isDeclined = false
					local thisID

				    for name, value in pairs ( attrs ) do
				    	if tostring(name) == "id" and tonumber(value) then
							thisID = tonumber(value)
						end
				  --   	if tostring(name) == "status" and (tostring(value)~="Accepted") then
						-- 	isDeclined = true
						-- end
					end

					-- if not isDeclined and thisID then
					if thisID then
						usedIDs[thisID] = true
					end
				end
				xmlUnloadFile(xml)
			end
		end
		-- iprint(usedIDs)
		for id=30000, 99999 do -- new arbitrary model IDs range from 30k upwards
			if not usedIDs[tonumber(id)] then
				newid = tonumber(id)
				break
			end
		end
	end
	-- print("New ID:" ..newid)
	return newid
end

function preSubmitModUpload(modType, mod)


	local newmodtype = reverseFormatModType(modType)
	if availableModTypesBis[newmodtype] then
		local newid = getNextAvailableID(newmodtype)
		if not newid then

			triggerClientEvent(client, "modloader:receiveUploadConfirmation", client, false, "Error. Failed to get next available ID for "..modType.." mod")
			return false
		end
		mod.modelid = newid
		local upid = getNextUploadID()
		if not upid then
			triggerClientEvent(client, "modloader:receiveUploadConfirmation", client, false, "Error. Failed to process new mod upload.")
			return false
		end
		triggerEvent("newmods:fetchImageFromURL", client, - (tonumber(upid)), mod.image, "playerUpload", {newmodtype, mod})
	else
		triggerClientEvent(client, "modloader:receiveUploadConfirmation", client, false, "Uploading "..modType.." is not supported yet.")
	end
end
addEvent("newmods:preSubmitModUpload", true)
addEventHandler("newmods:preSubmitModUpload", root, preSubmitModUpload)


-- at this point it's permanently adding the mod uploaded
function saveModFromClient(modType, mod, dff, txd, av, extra, forceUpload)

	local player = client or source

	-- check if the same mod has already been uploaded
	local foundSame = nil

	local path = string.format(xmlPath, modType)
	local xml = xmlLoadFile(path)
	if xml then

		local mods = xmlNodeGetChildren(xml)
		for i, mod in pairs(mods) do

			local dffSame, txdSame = false, false

            local attrs = xmlNodeGetAttributes ( mod )

            local isDeclined = false
		    for name, value in pairs ( attrs ) do
		        if tostring(name) == "dffPath" then
		        	if fileExists(tostring(value)) then
			        	local f = fileOpen(tostring(value), true)
			            if f then
			                local count = fileGetSize(f)
			                local data = fileRead(f, count)
			                local tmp = data
			                fileClose(f)
			                if tostring(tmp) == tostring(dff) then
			                	dffSame = true
			                end
			            end
			        end
		        end
		        if tostring(name) == "txdPath" then
		        	if fileExists(tostring(value)) then
			        	local f = fileOpen(tostring(value), true)
			            if f then
			                local count = fileGetSize(f)
			                local data = fileRead(f, count)
			                local tmp = data
			                fileClose(f)
			                if tostring(tmp) == tostring(txd) then
			                	txdSame = true
			                end
			            end
			        end
		        end
		        if tostring(name) == "status" and (tostring(value)=="Declined" or tostring(value)=="Cancelled") then
					isDeclined = true
				end
		    end

		    if dffSame and txdSame and not isDeclined then
		    	foundSame = tonumber(i)
		    	break
		    end
		end
		xmlUnloadFile(xml)
	end
	if foundSame then
		return triggerClientEvent(player, "modloader:receiveUploadConfirmation_notFinal", player, false, "The exact same mod you are uploading has already been submitted: upload #"..foundSame)
	end


	---------------------------------------------------- TRY SAVE FINAL UPLOAD ----------------------------------------------------


	local uploadID = getNextUploadID()
	local fname = uploadID.."_"..(mod.modelid)
	local savePathDff = "files/"..modType.."/"..fname..".dff"
	local savePathTxd = "files/"..modType.."/"..fname..".txd"

	-- delete if something's already there first
	if fileExists(savePathDff) then
		fileDelete(savePathDff)
	end
	if fileExists(savePathTxd) then
		fileDelete(savePathTxd)
	end

	local f1 = fileCreate(savePathDff)
	if not f1 then
		return triggerClientEvent(player, "modloader:receiveUploadConfirmation", player, false, "Failed to save your "..mod.name..".dff on the server.")
	end
	local f2 = fileCreate(savePathTxd)
	if not f2 then
		return triggerClientEvent(player, "modloader:receiveUploadConfirmation", player, false, "Failed to save your "..mod.name..".txd on the server.")
	end

	fileWrite(f1, dff)
	fileWrite(f2, txd)

	local f1size = fileGetSize(f1)
	local f2size = fileGetSize(f2)

	if not canUploadBigger(player) then

		if f1size > maxFileSizes["dff"] then
			fileClose(f1)
			fileClose(f2)
			fileDelete(savePathDff)
			fileDelete(savePathTxd)
			return triggerClientEvent(player, "modloader:receiveUploadConfirmation_notFinal", player, false, mod.name..".dff is too big! Max size: "..(maxFileSizes["dff"] / 1024).." KB. Make sure your model is optimized and low-polygon. For more info head to our Tutorial page.")
		end

		if f2size > maxFileSizes["txd"] then
			fileClose(f1)
			fileClose(f2)
			fileDelete(savePathDff)
			fileDelete(savePathTxd)
			return triggerClientEvent(player, "modloader:receiveUploadConfirmation_notFinal", player, false, mod.name..".txd is too big! Max size: "..(maxFileSizes["txd"] / 1024).." KB. Make sure you compress the images in your txd. For more info head to our Tutorial page.")
		end
	elseif not isModFullPerm(player) then
		if f1size > maxFileSizes["dffBigger"] then
			fileClose(f1)
			fileClose(f2)
			fileDelete(savePathDff)
			fileDelete(savePathTxd)
			return triggerClientEvent(player, "modloader:receiveUploadConfirmation_notFinal", player, false, mod.name..".dff is too big! Max size: "..(maxFileSizes["dffBigger"] / 1024).." KB (Exclusive). Make sure your model is optimized and low-polygon. For more info head to our Tutorial page.")
		end

		if f2size > maxFileSizes["txdBigger"] then
			fileClose(f1)
			fileClose(f2)
			fileDelete(savePathDff)
			fileDelete(savePathTxd)
			return triggerClientEvent(player, "modloader:receiveUploadConfirmation_notFinal", player, false, mod.name..".txd is too big! Max size: "..(maxFileSizes["txdBigger"] / 1024).." KB (Exclusive). Make sure you compress the images in your txd. For more info head to our Tutorial page.")
		end
	end


	fileClose(f1)
	fileClose(f2)

	if ((f2size > maxFileSizes["txd"]) or (f1size > maxFileSizes["dff"])) and not isModFullPerm(player) then
		-- tax for the higher size upload
		local gcPrice = GCUploadPrice_Bigger

		local currentGC = exports.mysql:query_fetch_assoc("SELECT `credits` FROM `accounts` WHERE `id`='"..getElementData(player, "account:id").."'  LIMIT 1")["credits"]
		if not currentGC or not exports.donators:takeCredit(player, gcPrice) then

			fileDelete(savePathDff)
			fileDelete(savePathTxd)
			return triggerClientEvent(player, "modloader:receiveUploadConfirmation_notFinal", player, false, "You need "..gcPrice.." GCs to upload this mod that is bigger than the normal allowed limit.")
		end

		triggerClientEvent(player, "displayMesaage", player, gcPrice.." coins (can't be refunded automatically) have been spent on a bigger filesize mod upload.", "success")
		makeUploadNotification(player, "You have spent "..gcPrice.." coins on a bigger filesize Mod Upload.\n\nThis ability is exclusive! These coins cannot be refunded automatically. Contact Head Admins for inquiries.")

	end


	local path = string.format(xmlPath, modType)
	local xml = xmlLoadFile(path)
	if xml then

		------------------ PERMANENTLY UPLOADING MOD ------------------

		local newmod = xmlCreateChild(xml, "mod")
		local dateStr = getTimeStrNow()


		local paid = 0
		if av == 1 then
			-- Paid Personal upload
			local totaluploads, maxFreeModUploads, gcPrice = unpack(extra)
			local isAdm = exports["sarp-new-mods"]:isModFullPerm(player) -- pay check #2

        	if totaluploads >= maxFreeModUploads then--and not isAdm 

				if not exports.donators:takeCredit(player, gcPrice) then
					return triggerClientEvent(player, "modloader:receiveUploadConfirmation_notFinal", player, false, "We can't accept your mod upload request because you don't have "..gcPrice.." coins.")
				end

				triggerClientEvent(player, "displayMesaage", player, gcPrice.." coins (refundable) have been spent on: 1 Personal Mod Upload.", "success")
				makeUploadNotification(player, "You have spent "..gcPrice.." coins on a personal mod upload ID #"..uploadID..".\n\nThese coins will be refunded if your request is declined.")
				paid = gcPrice
			end
		elseif av == 3 or av == 4 then
			-- global/server mod

			if modType == "ped" then
				local gender,race = unpack(extra)
				xmlNodeSetAttribute(newmod, "gender", gender)
				xmlNodeSetAttribute(newmod, "race", race)
			
			elseif modType == "vehicle" then
				local basemodel = unpack(extra)
				xmlNodeSetAttribute(newmod, "basemodel", basemodel)
			end
		end

		-- outputDebugString("ADD: "..savePathDff)
		-- outputDebugString("ADD: "..savePathTxd)


		xmlNodeSetAttribute(newmod, "upid", uploadID)
		xmlNodeSetAttribute(newmod, "id", mod.modelid)
		xmlNodeSetAttribute(newmod, "name", mod.name) --serves no purpose
		xmlNodeSetAttribute(newmod, "title", mod.title)
		xmlNodeSetAttribute(newmod, "author", mod.author)
		xmlNodeSetAttribute(newmod, "desc", mod.desc)
		xmlNodeSetAttribute(newmod, "uploadBy", getElementData(player, "account:id"))
		xmlNodeSetAttribute(newmod, "uploadDate", dateStr)
		xmlNodeSetAttribute(newmod, "dffPath", savePathDff)
		xmlNodeSetAttribute(newmod, "txdPath", savePathTxd)
		xmlNodeSetAttribute(newmod, "purpose", mod.purpose)
		xmlNodeSetAttribute(newmod, "paid", paid)

		xmlNodeSetAttribute(newmod, "status", "Pending") -- will be pending admin review for now
		xmlNodeSetAttribute(newmod, "revBy", "-")
		xmlNodeSetAttribute(newmod, "comment", "-")
		xmlNodeSetAttribute(newmod, "revDate", "-")

		xmlSaveFile(xml)
		xmlUnloadFile(xml)
		updateMetaXml()


		av = tonumber(av)
		if (av == 1) or ( av < 0) or (av == 0) then
			-- personal / faction / global upload

			local niceModType = formatModType(modType)
			local nicePurpose = formatModPurpose(tonumber(mod.purpose))

			local modInfo = "New mod uploaded and submitted to the server. It is now pending review.\n\n"
			modInfo = modInfo .. " - Upload date: "..dateStr.."\n"
			modInfo = modInfo .. " - Upload type: "..nicePurpose.."\n"
			modInfo = modInfo .. " - Mod type: "..niceModType.."\n"
			modInfo = modInfo .. " - Unique "..string.lower(niceModType).." ID: "..mod.modelid.."\n"
			modInfo = modInfo .. " - Author(s): "..mod.author.."\n"
			modInfo = modInfo .. " - Title: "..mod.title.."\n"
			modInfo = modInfo .. " - Description: "..mod.desc.."\n\n"
			modInfo = modInfo .. "You will be contacted again via notification once your mod has been reviewed."

			makeUploadNotification(player, modInfo)
		end

		if forceUpload then
			if acceptUpload(modType, uploadID, "Mass Upload - Implemented by force", forceUpload, player) then
				outputChatBox(mod.name.." successfully uploaded & implemented.", player, 0,255,0)
			end
		else
			makeAdminAnnouncement(player, "has submitted a new mod now pending review: upload #"..uploadID..".", true)
			return triggerClientEvent(player, "modloader:receiveUploadConfirmation", player, true, "Mod uploaded successfully! Upload ID #"..uploadID.."\nPending admin review.")
		end
	else

		fileDelete(savePathDff)
		fileDelete(savePathTxd)
		return triggerClientEvent(player, "modloader:receiveUploadConfirmation_notFinal", player, false, "Failed to save your mod on the server.")
	end
end
addEvent("newmods:saveModFromClient", true)
addEventHandler("newmods:saveModFromClient", root, saveModFromClient)

-- from mass upload
function forceDeleteMod(modType, name)

	local uploadID

	for modType, v in pairs(getModUploads()) do
		for k, upload in pairs(v) do
			if upload.name == name then
				uploadID = upload.upid
				break
			end
		end
	end

	if not uploadID then
		return outputChatBox(modType.." mod '"..name.."' not found in all uploads", client, 255,255,0)
	end


	if deleteUpload(modType, uploadID, nil, client) then
		outputChatBox("Successfully deleted upload #"..uploadID.." ("..name..")", client, 0,255,100)
	else
		outputChatBox("Faield to delete upload #"..uploadID.." ("..name..")", client, 255,0,0)
	end
end
addEvent("newmods:forceDeleteMod", true)
addEventHandler("newmods:forceDeleteMod", root, forceDeleteMod)

-- called after mod image and files are valid...
function validateModAvailability(modType, mod)
	local player = client or source

	local av = mod.purpose
	av = tonumber(av)

	if av then

		if av == 1 then
			local myuploads = getModUploads(getElementData(player, "account:id"), false, true) or {}

			local count = 0
			for k, upload in pairs(myuploads["ped"]) do
				local status = upload.status
				if status == "Accepted" or status == "Pending" then
					-- don't count those declined
					count = count + 1
				end
			end

			myuploads = count

			if myuploads then
				-- continue to check mod
		        triggerClientEvent(player, "modloader:getModFromClient", player, modType, mod, av, {myuploads, maxFreeModUploads, GCUploadPrice})
			else
				triggerClientEvent(player, "modloader:receiveUploadConfirmation_notFinal", player, false, "Error processing mod availability #3.")
			end
		elseif av == 2 then

			local factions = getElementData(player, "faction") or {}
			local foundFac = false
			for k,v in pairs(factions) do
				foundFac = true
				break
			end
			if foundFac then
				local fTable = {}
				for k,v in pairs(factions) do
					local ft = exports["faction-system"]:getFactionType(k)
					if ft >= 2 and ft <= 4 then -- law/gov/med
						fTable[k] = {v, tempFactionSlots["government"]}
					elseif ft <= 1 then -- illegal official
						fTable[k] = {v, tempFactionSlots["illegal"]}
					elseif ft < 8 then -- not a legal F3 from county hall
						fTable[k] = {v, tempFactionSlots["legal"]}
					end
				end
				triggerClientEvent(player, "modloader:getModFromClient", player, modType, mod, av, {fTable})
			else
				triggerClientEvent(player, "modloader:receiveUploadConfirmation_notFinal", player, false, "You are not in a faction (F3). This is used to upload mods that will be exclusively obtainable by the faction members.")
			end

		elseif av == 3 or av == 4 then
			triggerClientEvent(player, "modloader:getModFromClient", player, modType, mod, av)
		else
			triggerClientEvent(player, "modloader:receiveUploadConfirmation_notFinal", player, false, "Error processing mod availability #2.")
		end
	else
		triggerClientEvent(player, "modloader:receiveUploadConfirmation_notFinal", player, false, "Error processing mod availability #1.")
	end
end
addEvent("newmods:validateModAvailability", true)
addEventHandler("newmods:validateModAvailability", root, validateModAvailability)


-- Fixed 10/05/2021
function getNextUploadID()

	local lastUploadID = 0

	for k, modType in pairs(availableModTypes) do
		local path = string.format(xmlPath, modType)
		local xml = xmlLoadFile(path)
		if xml then

			local mods = xmlNodeGetChildren(xml)
			for i, mod in pairs(mods) do

	            local attrs = xmlNodeGetAttributes ( mod )
			    for name, value in pairs ( attrs ) do
			        if tostring(name) == "upid" and tonumber(value) then
			        	if tonumber(value) > lastUploadID then
			        		lastUploadID = tonumber(value)
			        	end
			        end
			    end
			end
			xmlUnloadFile(xml)
		end
	end
	return lastUploadID + 1
end

function getTimeStrNow()
	local time = getRealTime()
	local monthday = time.monthday
	local month = time.month
	local year = time.year

	local date = string.format("%04d-%02d-%02d", year + 1900, month + 1, monthday)
	date = date.." "..string.format("%02d:%02d", time.hour, time.minute)
	return date
end


function cancelModUpload(modType, upID)
	local cancelled = false

	local path = string.format(xmlPath, modType)
	local xml = xmlLoadFile(path)
	if xml then

		local mods = xmlNodeGetChildren(xml)
		for i, mod in pairs(mods) do

			local foundUpID
			local attrs = xmlNodeGetAttributes ( mod )
		    for name, value in pairs ( attrs ) do
		        if tostring(name) == "upid" then
		        	foundUpID = tonumber(value)
		        end
		    end

			if foundUpID == tonumber(upID) then

				xmlNodeSetAttribute(mod, "status", "Cancelled")
				xmlSaveFile(xml)
				cancelled = true
				break
			end
		end

		xmlUnloadFile(xml)
		updateMetaXml()
	end
	return cancelled
end


function declineModUpload(admin, modType, upID, msg)
	local declined = false

	local path = string.format(xmlPath, modType)
	local xml = xmlLoadFile(path)
	if xml then

		local mods = xmlNodeGetChildren(xml)
		for i, mod in pairs(mods) do

			local foundUpID
			local attrs = xmlNodeGetAttributes ( mod )
		    for name, value in pairs ( attrs ) do
		        if tostring(name) == "upid" then
		        	foundUpID = tonumber(value)
		        end
		    end

			if foundUpID == tonumber(upID) then

				local accid
				for name, value in pairs ( attrs ) do

				    if tostring(name) == "uploadBy" and tonumber(value) then
				    	accid = tonumber(value)
				    end
				end

				xmlNodeSetAttribute(mod, "status", "Declined")

				xmlNodeSetAttribute(mod, "revBy", getElementData(admin, "account:id"))
				xmlNodeSetAttribute(mod, "comment", msg)
				xmlNodeSetAttribute(mod, "revDate", getTimeStrNow())

				xmlSaveFile(xml)

				if accid then
					makeUploadNotification(accid, "Your mod upload request ID #"..upID.." has been declined by "..getElementData(admin, "account:username")..".\nReason: "..msg.."\nIn order to get refunded (if you paid to upload) you have to cancel the request.")
				end

				declined = true
				break
			end
		end

		xmlUnloadFile(xml)
		updateMetaXml()
	end
	return declined
end


function deleteModUpload(admin, modType, upID, delType)
	local deleted = false

	local dffP, txdP, foundUpID, name1

	local soft = delType and delType == "soft"

	local path = string.format(xmlPath, modType)
	local xml = xmlLoadFile(path)
	if xml then

		local mods = xmlNodeGetChildren(xml)
		for i, mod in pairs(mods) do

			local attrs = xmlNodeGetAttributes ( mod )
		    for name, value in pairs ( attrs ) do
		        if tostring(name) == "upid" then
		        	foundUpID = tonumber(value)
		        end
		    end

			if foundUpID == tonumber(upID) then

				for name, value in pairs ( attrs ) do

				    if tostring(name) == "dffPath" then
				    	dffP = tostring(value)
				    end
				    if tostring(name) == "txdPath" then
				    	txdP = tostring(value)
				    end
				    if tostring(name) == "name" then
				    	name1 = tostring(value)
				    end
				end

				if xmlDestroyNode(mod) then
					xmlSaveFile(xml)

					deleted = true
				end
				break
			end
		end

		xmlUnloadFile(xml)
	end

	if deleted and name1 and foundUpID then
		if dffP then
			if fileExists(dffP) then
				if soft then
					local f = fileOpen(dffP)
					if f then
						local content = fileRead(f, fileGetSize(f))
						fileClose(f)
						local newPath = "del_files/"..modType.."/"..foundUpID.."_"..name1..".dff"
						fileDelete(dffP)
						local f2 = fileCreate(newPath)
						fileWrite(f2, content)
						fileClose(f2)
						-- outputDebugString("SOFT-DEL: "..newPath)
					end
				else
					fileDelete(dffP)
					-- outputDebugString("DEL: "..dffP)
				end
			end
		end
		if txdP then
			if fileExists(txdP) then
				if soft then
					local f = fileOpen(txdP)
					if f then
						local content = fileRead(f, fileGetSize(f))
						fileClose(f)
						local newPath = "del_files/"..modType.."/"..foundUpID.."_"..name1..".txd"
						fileDelete(txdP)
						local f2 = fileCreate(newPath)
						fileWrite(f2, content)
						fileClose(f2)
						-- outputDebugString("SOFT-DEL: "..newPath)
					end
				else
					fileDelete(txdP)
					-- outputDebugString("DEL: "..txdP)
				end
			end
		end
	end

	updateMetaXml()
	return (deleted and name1 and foundUpID)
end


function acceptModUpload(admin, niceModType, modType, newid, upID, msg)
	local accepted = false

	local path = string.format(xmlPath, modType)
	local xml = xmlLoadFile(path)
	if xml then

		local mods = xmlNodeGetChildren(xml)
		for i, mod in pairs(mods) do

			local foundUpID
			local attrs = xmlNodeGetAttributes ( mod )
		    for name, value in pairs ( attrs ) do
		        if tostring(name) == "upid" then
		        	foundUpID = tonumber(value)
		        end
		    end

			if foundUpID == tonumber(upID) then

				xmlNodeSetAttribute(mod, "id", tostring(newid))
				xmlNodeSetAttribute(mod, "status", "Accepted")
				xmlNodeSetAttribute(mod, "revBy", getElementData(admin, "account:id"))
				xmlNodeSetAttribute(mod, "comment", msg)
				xmlNodeSetAttribute(mod, "revDate", getTimeStrNow())
				xmlSaveFile(xml)


				local extra = ""
				local accid

				for name, value in pairs ( attrs ) do

				    if tostring(name) == "uploadBy" and tonumber(value) then
				    	accid = tonumber(value)
				    end
				    if tostring(name) == "purpose" and tonumber(value) then
				    	local purpose = tonumber(value)
				    	if purpose == 1 then
				    		if modType  == "ped" then
				    			extra = "IMPORTANT: Your personal "..modType.." mod can now be obtained as an item at the "..skinStoreName.." (located on F11 Map as t-shirt icon and /gps). Only you will have access to it since it's a private mod upload."
				    		end
				    	elseif purpose == 0 then

				    		if modType  == "ped" then
				    			extra = "IMPORTANT: Your public "..modType.." mod can now be purchased as an item at the "..skinStoreName.." (located on F11 Map as t-shirt icon and /gps), as well as ALL clothing stores in the server by anyone."
				    		end
				    	elseif purpose < 0 then
				    		if modType  == "ped" then
				    			local facname = exports["faction-system"]:getFactionName(math.abs(purpose))
				    			local facid = math.abs(purpose)
				    			extra = "IMPORTANT: Your faction ("..facname.." - ID #"..facid..") "..modType.." mod can now be purchased as an item at the "..skinStoreName.." (located on F11 Map as t-shirt icon and /gps) by yourself and all faction members."
				    		end
				    	end
				    end
				end

				if accid then
					makeUploadNotification(accid, "Your mod upload request ID #"..upID.." has been accepted by "..getElementData(admin, "account:username")..".\nComment: "..msg.."\n"..extra)
				end

				accepted = true
				break
			end
		end

		xmlUnloadFile(xml)
	end
	
	updateMetaXml()
	return accepted
end


function updateModUpload(admin, niceModType, modType, upID, author, title, desc, comment, gender, race)
	local updated = false

	local path = string.format(xmlPath, modType)
	local xml = xmlLoadFile(path)
	if xml then

		local mods = xmlNodeGetChildren(xml)
		for i, mod in pairs(mods) do

			local foundUpID
			local attrs = xmlNodeGetAttributes ( mod )
		    for name, value in pairs ( attrs ) do
		        if tostring(name) == "upid" then
		        	foundUpID = tonumber(value)
		        end
		    end

			if foundUpID == tonumber(upID) then

				local message = ""
				local accid

				for name, value in pairs ( attrs ) do

				    if tostring(name) == "uploadBy" and tonumber(value) then
				    	accid = tonumber(value)
				    end

				    if tostring(name) == "author" and tostring(value) ~= author then
				    	message = message.."\nAuthor(s): "..author
				    end

				    if tostring(name) == "title" and tostring(value) ~= title then
				    	message = message.."\nTitle: "..title
				    end

				    if tostring(name) == "desc" and tostring(value) ~= desc then
				    	message = message.."\nDescription: "..desc
				    end

				    if comment and tostring(name) == "comment" and tostring(value) ~= comment then
				    	message = message.."\nReview Comment: "..comment
				    end

				    if gender and tostring(name) == "gender" and tostring(value) ~= gender then
				    	message = message.."\nGender: "..formatGender(gender)
				    end

				    if race and tostring(name) == "race" and tostring(value) ~= race then
				    	message = message.."\nRace: "..formatRace(gender)
				    end
				end


				xmlNodeSetAttribute(mod, "title", tostring(title))
				xmlNodeSetAttribute(mod, "author", tostring(author))
				xmlNodeSetAttribute(mod, "desc", tostring(desc))
				if comment then
					xmlNodeSetAttribute(mod, "comment", tostring(comment))
				end
				if gender and race then
					xmlNodeSetAttribute(mod, "gender", tostring(gender))
					xmlNodeSetAttribute(mod, "race", tostring(race))
				end
				xmlSaveFile(xml)

				if accid then
					makeUploadNotification(accid, "Your mod upload request ID #"..upID.." has been updated by "..getElementData(admin, "account:username")..". The following details were changed:\n"..message)
				end

				updated = true
				break
			end
		end

		xmlUnloadFile(xml)
	end
	updateMetaXml()
	return updated
end


function makeGlobalModUpload(admin, niceModType, modType, upID, makePersonal, selfChange)
	local updated = false

	local path = string.format(xmlPath, modType)
	local xml = xmlLoadFile(path)
	if xml then

		local mods = xmlNodeGetChildren(xml)
		for i, mod in pairs(mods) do

			local foundUpID
			local attrs = xmlNodeGetAttributes ( mod )
		    for name, value in pairs ( attrs ) do
		        if tostring(name) == "upid" then
		        	foundUpID = tonumber(value)
		        end
		    end

			if foundUpID == tonumber(upID) then

				local accid

				for name, value in pairs ( attrs ) do

				    if tostring(name) == "uploadBy" and tonumber(value) then
				    	accid = tonumber(value)
				    end
				end

				local new = "0"
				local extra = ""
				if makePersonal then new = "1" end

				xmlNodeSetAttribute(mod, "purpose", new)

				-- Defaults for global skin
				if modType == "ped" then
					xmlNodeSetAttribute(mod, "gender", 0)--male/female
					xmlNodeSetAttribute(mod, "race", 1)--black/white/asian
				end

				xmlSaveFile(xml)

				if accid then
					if makePersonal then
						extra = "IMPORTANT: Your personal "..niceModType.." mod can now be obtained as an item at the "..skinStoreName.." (located on F11 Map as t-shirt icon and /gps). Only you will have access to it since it's a private mod upload."
						if selfChange then
							makeUploadNotification(accid, "Your mod upload request ID #"..upID.." has been changed to: PERSONAL.\n\n"..extra)
						else
							makeUploadNotification(accid, "Your mod upload request ID #"..upID.." has been changed to: PERSONAL by "..getElementData(admin, "account:username")..".\n\n"..extra)
						end
					else
						extra = "IMPORTANT: Your public "..niceModType.." mod can now be purchased as an item at the "..skinStoreName.." (located on F11 Map as t-shirt icon and /gps), as well as ALL clothing stores in the server by anyone."
						if selfChange then
							makeUploadNotification(accid, "Your mod upload request ID #"..upID.." has been changed to: GLOBAL.\n\n"..extra)
						else
							makeUploadNotification(accid, "Your mod upload request ID #"..upID.." has been changed to: GLOBAL by "..getElementData(admin, "account:username")..".\n\n"..extra)
						end
					end
				end

				updated = true
				break
			end
		end

		xmlUnloadFile(xml)
	end
	updateMetaXml()
	return updated
end

function getModUploadModel(modType, upID)
	local foundModel = false

	local path = string.format(xmlPath, modType)
	local xml = xmlLoadFile(path)
	if xml then

		local mods = xmlNodeGetChildren(xml)
		for i, mod in pairs(mods) do

			local foundUpID
			local attrs = xmlNodeGetAttributes ( mod )
		    for name, value in pairs ( attrs ) do
		        if tostring(name) == "upid" then
		        	foundUpID = tonumber(value)
		        end
		    end

			if foundUpID == tonumber(upID) then

				foundModel = {}

				local extra = ""
				local accid

				for name, value in pairs ( attrs ) do

				    if tostring(name) == "id" then
						if tonumber(value) then
							foundModel.modelid = tonumber(value)
						end
			        end
				    if tostring(name) == "basemodel" then
						if tonumber(value) then
							foundModel.basemodel = tonumber(value)
						end
			        end
				    if tostring(name) == "dffPath" then
						-- load the file raw data to send to the client
			        	local p = tostring(value)
			        	if fileExists(p) then
			        		local f = fileOpen(p, true)
				            if f then
				                local count = fileGetSize(f)
				                local data = fileRead(f, count)
				                foundModel.dff = data
				                foundModel.dffSize = count
				                fileClose(f)
				            end
				        end
			        end
			        if tostring(name) == "txdPath" then
			        	-- load the file raw data to send to the client
			        	local p = tostring(value)
			        	if fileExists(p) then
			        		local f = fileOpen(p, true)
				            if f then
				                local count = fileGetSize(f)
				                local data = fileRead(f, count)
				                foundModel.txd = data
				                foundModel.txdSize = count
				                fileClose(f)
				            end
				        end
			        end
				end
			end
		end

		xmlUnloadFile(xml)
	end

	return foundModel
end

function getModUpload(upID)
	return getModUploads(uploader, upID)
end

function getModUploads(uploader, upID, countPersonal)
	if uploader then uploader = tonumber(uploader) end
	local uploads = {}

	for k, modType in pairs(availableModTypes) do

		uploads[modType] = {}

		local path = string.format(xmlPath, modType)
		local xml = xmlLoadFile(path)
		if xml then

			local mods = xmlNodeGetChildren(xml)
			for i, mod in pairs(mods) do

				local attrs = xmlNodeGetAttributes ( mod )
				local uploadedByUploader = false
				local a1 = false
				local a2 = false


				if uploader then

				    for name, value in pairs ( attrs ) do

				    	if uploader > 0 then
				    		-- checking account id
					        if tostring(name) == "uploadBy" and tonumber(value) then
					        	if tonumber(value) == uploader then
					        		a1 = true
					        	end
					        end
					        if tostring(name) == "purpose" and tonumber(value) then
					        	if tonumber(value) == 1 then
					        		a2 = true
					        	end
					        end
					    else
					    	-- checking uploaded for which faction

					        if tostring(name) == "purpose" and tonumber(value) then
					        	if tonumber(value) == uploader then
					        		uploadedByUploader = true
					        		break
					        	end
					        end
					    end
				    end
				end

				if uploader and uploader > 0 and a1 and (a2 or not countPersonal) then
					uploadedByUploader = true
				end

			    if not uploader or uploadedByUploader or upID then

			    	local tab = {}

			    	for name, value in pairs ( attrs ) do
			    		if tostring(name) == "upid" then
			        		tab.upid = tonumber(value)
				        end
			    		if tostring(name) == "id" then
			        		tab.modelid = tonumber(value)
				        end
			    		if tostring(name) == "basemodel" then
			        		tab.basemodel = tonumber(value)
				        end
				        if tostring(name) == "name" then
				        	tab.name = tostring(value)
				        end
				        if tostring(name) == "title" then
				        	tab.title = tostring(value)
				        end
				        if tostring(name) == "author" then
				        	tab.author = tostring(value)
				        end
				        if tostring(name) == "desc" then
				        	tab.desc = tostring(value)
				        end
				        if tostring(name) == "uploadBy" then
				        	tab.uploadBy = tostring(value)
				        end
				        if tostring(name) == "uploadDate" then
				        	tab.uploadDate = tostring(value)
				        end
				        if tostring(name) == "dffPath" then
				        	tab.dffPath = tostring(value)
				        end
				        if tostring(name) == "txdPath" then
				        	tab.txdPath = tostring(value)
				        end
				        if tostring(name) == "status" then
				        	tab.status = tostring(value)
				        end
				        if tostring(name) == "revBy" then
				        	tab.revBy = tostring(value)
				        end
				        if tostring(name) == "comment" then
				        	tab.comment = tostring(value)
				        end
				        if tostring(name) == "purpose" then
				        	tab.purpose = tonumber(value)
				        end
				        if tostring(name) == "gender" then
				        	tab.gender = tonumber(value)
				        end
				        if tostring(name) == "race" then
				        	tab.race = tonumber(value)
				        end
				        if tostring(name) == "paid" then
				        	tab.paid = tonumber(value)
				        end
				        if tostring(name) == "revDate" then
				        	tab.revDate = tostring(value)
				        end

				        if tostring(name) == "dffPath" then
							-- load the file raw data to send to the client
				        	local p = tostring(value)
				        	if fileExists(p) then
				        		local f = fileOpen(p, true)
					            if f then
					                local count = fileGetSize(f)
					                local data = fileRead(f, count)
					                tab.dffSize = count
					                fileClose(f)
					            end
					        end
				        end
				        if tostring(name) == "txdPath" then
				        	-- load the file raw data to send to the client
				        	local p = tostring(value)
				        	if fileExists(p) then
				        		local f = fileOpen(p, true)
					            if f then
					                local count = fileGetSize(f)
					                local data = fileRead(f, count)
					                tab.txdSize = count
					                fileClose(f)
					            end
					        end
				        end

				    end
				    tab.modtype = modType


				    if upID and tonumber(upID) then
				    	if tonumber(upID) == tab.upid then
				    		-- return the mod uploaded with id provided
				    		return tab
				    	end
				    end

					table.insert(uploads[modType], tab)
			    end
			end
			xmlUnloadFile(xml)
		end
	end

	-- return table of mod uploads
	return uploads
end


-- process upload payment etc
function validateUpload(modType, mod, dffdata, txddata, av, extra, forceUpload)

	av = tonumber(av)
	if av == 1 then
		-- paid personal upload
		-- check if can pay

		local currentGC = exports.mysql:query_fetch_assoc("SELECT `credits` FROM `accounts` WHERE `id`='"..getElementData(client, "account:id").."'  LIMIT 1")["credits"]
		if not currentGC then
			return triggerClientEvent(client, "modloader:receiveUploadConfirmation", client, false, "Error fetching your GCs.")
		end

		mod.purpose = 1
		-- finish upload
        triggerEvent("newmods:saveModFromClient", client, modType, mod, dffdata, txddata, av, extra)
	elseif av == 2 then
		-- faction upload

		local fTable, fselected = unpack(extra)
		local fac = exports["faction-system"]:getFactionFromName(fselected)
		if not fac then
			return triggerClientEvent(client, "modloader:receiveUploadConfirmation", client, false, "Error processing your faction upload #1.")
		end
		local facid = getElementData(fac, "id")
		local faction = fTable[facid]
		local fstuff, maxslots = unpack(faction)
		maxslots = tonumber(maxslots)
		if not maxslots then
			return triggerClientEvent(client, "modloader:receiveUploadConfirmation", client, false, "Error processing your faction upload #2.")
		end

		local currentUploads = getModUploads(-facid) or {}

		local count = 0
		for k, upload in pairs(currentUploads["ped"]) do
			count = count + 1
		end

		currentUploads = count

		if currentUploads >= maxslots then
			return triggerClientEvent(client, "modloader:receiveUploadConfirmation_notFinal", client, false, "Your faction "..fselected.." (#"..facid..") has maxed out "..currentUploads.."/"..maxslots.." mod uploads. Contact UAT to obtain more slots.")
		end

		mod.purpose = -facid
		-- finish upload
        triggerEvent("newmods:saveModFromClient", client, modType, mod, dffdata, txddata, av, extra, forceUpload)

    elseif av == 3 then
    	-- global upload
    	mod.purpose = 0

    	-- finish upload
        triggerEvent("newmods:saveModFromClient", client, modType, mod, dffdata, txddata, av, extra)
    
    elseif av == 4 then
    	-- server/script only upload
    	mod.purpose = 2

    	-- finish upload
        triggerEvent("newmods:saveModFromClient", client, modType, mod, dffdata, txddata, av, extra, forceUpload)
	else
		triggerClientEvent(client, "modloader:receiveUploadConfirmation", client, false, "coming soon")
	end
end
addEvent("newmods:validateUpload", true)
addEventHandler("newmods:validateUpload", root, validateUpload)

-- exported
function makeUploadNotification(player_, msg)

	local accid
	if isElement(player_) then
		accid = getElementData(player_, "account:id")
	elseif tonumber(player_) then
		accid = tonumber(player_)
	end

	if accid then
		exports.announcement:makePlayerNotification(accid, "[SA-RP] Mod Upload", msg)
	end
end
-- exported
function makeAdminAnnouncement(admin, msg, standout)

	if isElement(admin) then
		for k, player in ipairs(getElementsByType("player")) do
			if isModReviewer(player) then
				if getElementData(player, "duty_admin") == 1 or getElementData(player, "duty_supporter") == 1 then
					if not standout then
						outputChatBox("#ffffff[#f59e42MOD-UPLOADS#ffffff] #ffd857"..exports.global:getPlayerName(admin).." ("..getElementData(admin, "account:username")..") #ffffff"..msg, player, 255,255,255, true)
					else
						outputChatBox("#ffffff[#f59e42MOD-UPLOADS#ffffff] #ffd857"..exports.global:getPlayerName(admin).." ("..getElementData(admin, "account:username")..") #ffff00"..msg, player, 255,255,255, true)
					end
				end
			end
		end
	end
end


---------- view upload


function loadUploadData(mt, upID, isAdmin)

	-- print(upID)
	upID = tonumber(upID)
	local upload = getModUpload(upID)
	if not upload then
		return triggerClientEvent(client, "modloader:viewUploadMsg", client, false, "Failed to find this upload ID #"..upID.."!")
	end

	if isAdmin then
		-- edit and manage upload as admin
		triggerClientEvent(client, "modloader:viewUploadAdmin", client, mt, upload)
	else
		-- view upload as uploader
		triggerClientEvent(client, "modloader:viewUpload", client, mt, upload)
	end
end
addEvent("newmods:loadUploadData", true)
addEventHandler("newmods:loadUploadData", root, loadUploadData)

-- admin stuff
function declineUpload(mt, upID, msg)

	upID = tonumber(upID)
	local upload = getModUpload(upID)
	if not upload then
		return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed to find this upload ID #"..upID.."!")
	end

	local modType = reverseFormatModType(mt)
	if not modType or not declineModUpload(client, modType, upID, msg) then
		return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed decline upload ID #"..upID.."!")
	end


	local extra = ""
	if upload.status == "Accepted" then

		loadModsOnServer()

		-- was implemented, unload for everyone
		for k, player in ipairs(getElementsByType("player")) do
			triggerClientEvent(player, "unloadModelID", player, modType, upload.modelid)
		end
		exports["item-system"]:deleteAll(16, upload.modelid)

		-- disabling accepted mod -> move image
		local imageMoved = moveImageToTmp(upload.modelid, - upID)
		if not imageMoved then
			return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed to process preview image for upload ID #"..upID.." upon declining.")
		end
		extra = " which is now disabled"



		if modType == "vehicle" and VEHICLE_TESTING_ENABLED then
			-- testing /tmv
			testMakeVehicles()
		end

	else
		-- image stays stored in tmp as: - upID
	end

	makeAdminAnnouncement(client, "has declined mod request #"..upID..extra..".")

	-- upload declined
	return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, true, "Mod upload request ID #"..upID.." declined. The uploader will only be refunded when deleted.")
end
addEvent("newmods:declineUpload", true)
addEventHandler("newmods:declineUpload", root, declineUpload)

-- perm. delete
function deleteUpload(mt, upID, playerDecision, forceClient)

	local client = isElement(forceClient) and forceClient or client

	upID = tonumber(upID)
	local upload = getModUpload(upID)
	if not upload then
		return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed to find this upload ID #"..upID.."!")
	end


	local modType = reverseFormatModType(mt)
	if not modType or not deleteModUpload(client, modType, upID) then
		return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed to delete upload ID #"..upID.."!")
	end

	if upload.status == "Accepted" then
		-- check if no one is wearing skin

		-- was implemented, unload for everyone
		for k, player in ipairs(getElementsByType("player")) do
			triggerClientEvent(player, "unloadModelID", player, modType, upload.modelid)
		end
		exports["item-system"]:deleteAll(16, upload.modelid)

	end

	if upload.status ~= "Accepted" then
		-- was already cancelled so has no image
		local deletedImage = deleteModImage(- upID)
		if not forceClient then
			if not deletedImage then
				return triggerClientEvent(client, "modloader:viewUploadMsg", client, false, "Failed to delete preview image for upload ID #"..upID.." upon deleting.")
			end
		end
	else
		local deletedImage = deleteModImage(upload.modelid)
		if not forceClient then
			if not deletedImage then
				return triggerClientEvent(client, "modloader:viewUploadMsg", client, false, "Failed to delete preview image for upload ID #"..upID.." upon deleting.")
			end
		end
	end

	-- refund only when perma delete
	if upload.purpose == 1 then
		local gcPaid = upload.paid
		if tonumber(gcPaid) and tonumber(gcPaid) > 0 then
			if exports.donators:giveCredit(client, gcPaid) then
				makeUploadNotification(client, "You have been refunded "..gcPaid.." coins because your personal mod upload ID #"..upID.." was cancelled.")
			else
				outputChatBox("Error refunding "..gcPaid.." coins.", client, 255,0,0)
			end
		end
	end

	loadModsOnServer()

	if not forceClient then
		if not playerDecision then
			makeAdminAnnouncement(client, "has permanently deleted mod request #"..upID..".")

		else
			if upload.status == "Accepted" then
				makeUploadNotification(client, "You have deleted your "..mt.." mod ID #"..upload.modelid.." (Request ID #"..upID..").")
			else
				makeUploadNotification(client, "You have cancelled your mod upload request ID #"..upID..".")
			end

		end

		-- upload deleted forever
		return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, true, "Mod upload request ID #"..upID.." permanently deleted.")
	else
		makeAdminAnnouncement(client, "has force-deleted mod request #"..upID..".")
		return true
	end
end
addEvent("newmods:deleteUpload", true)
addEventHandler("newmods:deleteUpload", root, deleteUpload)

function acceptUpload(mt, upID, msg, forceUpload, forceClient)

	local client = isElement(forceClient) and forceClient or client

	upID = tonumber(upID)
	local upload = getModUpload(upID)
	if not upload then
		return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed to find this upload ID #"..upID.."!")
	end
	local modType = reverseFormatModType(mt)

	-- force get a new id
	local newid = getNextAvailableID(modType)
	if not newid then
		return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed to find unique new mod ID for this request.")
	end

	if not modType or not acceptModUpload(client, mt, modType, newid, upID, msg) then
		return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed to accept upload ID #"..upID.."!")
	end

	upload = getModUpload(upID)
	if not upload or not upload.modelid then
		return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed to fetch accepted upload ID #"..upID..".")
	end

	-- move image to real models images folder
	local imageMoved = moveImageToMain(- upID, newid)
	if (not forceUpload) and (not imageMoved) then
		return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed to process preview image for upload ID #"..upID.." upon accepting.")
	end


	if loadModsOnServer() then

		-- if modType == "ped" and isModFullPerm(client) then
		-- 	exports.global:giveItem(client, 16, newid)
		-- 	outputChatBox("Clothes for skin #"..newid.." item spawned.", client, 0, 255, 0)
		-- end

		if forceUpload then
			makeAdminAnnouncement(client, "implemented a mass uploaded "..mt.." mod. New ID: "..newid)
		else
			makeAdminAnnouncement(client, "has accepted & implemented uploaded mod request #"..upID..". Assigned "..mt.." ID: "..newid)
		end


		-- load mod for everyone in-game
		local theMod = loadOneMod(modType, tonumber(upload.modelid), true)
		if theMod then
			if isTimer(restartTimer) then
    			-- print("Not sending a mod to all players because server will restart")
	    	else
				for k, player in ipairs(getElementsByType("player")) do
					if useTriggerLatentClient then
						triggerLatentClientEvent(player, "loadModFromServer", clientLatentBW, player, modType, theMod)
					else
						triggerClientEvent(player, "loadModFromServer", player, modType, theMod)
					end
				end
			end
		else
			iprint(theMod)
			return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed to load accepted mod upload ID #"..upID.." for players.")
		end

		if modType == "vehicle" and VEHICLE_TESTING_ENABLED then
			-- testing /tmv
			testMakeVehicles()
		end

		if not forceUpload then
			-- confirmation message
			return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, true, "Mod upload request ID #"..upID.." accepted & now available. "..mt.." ID: #"..newid)
		else
			return true
		end
	end
end
addEvent("newmods:acceptUpload", true)
addEventHandler("newmods:acceptUpload", root, acceptUpload)


function updateUploadDetails(mt, upID, author, title, desc, comment, gender, race)

	upID = tonumber(upID)
	local upload = getModUpload(upID)
	if not upload then
		return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed to find this upload ID #"..upID.."!")
	end

	local modType = reverseFormatModType(mt)
	if not modType or not updateModUpload(client, mt, modType, upID, author, title, desc, comment, gender, race) then
		return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed update details for upload ID #"..upID.."!")
	end

	makeAdminAnnouncement(client, "has updated details of uploaded mod request #"..upID..".")

	-- upload updated
	return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, true, "Mod upload request ID #"..upID.." details updated.")
end
addEvent("newmods:updateUploadDetails", true)
addEventHandler("newmods:updateUploadDetails", root, updateUploadDetails)

function updateGenderRace(upID, gender, race)
	upID = tonumber(upID)
	local upload = getModUpload(upID)
	if not upload then
		return outputChatBox("Couldn't find your mod upload #"..upID..".", client, 255,100,100)
	end

	local updated

	local path = string.format(xmlPath, "ped")
	local xml = xmlLoadFile(path)
	if xml then

		local mods = xmlNodeGetChildren(xml)
		for i, mod in pairs(mods) do

			local foundUpID
			local attrs = xmlNodeGetAttributes ( mod )
		    for name, value in pairs ( attrs ) do
		        if tostring(name) == "upid" then
		        	foundUpID = tonumber(value)
		        end
		    end

			if foundUpID == tonumber(upID) then

				if gender and race then
					xmlNodeSetAttribute(mod, "gender", tostring(gender))
					xmlNodeSetAttribute(mod, "race", tostring(race))
				end
				xmlSaveFile(xml)

				updated = true
				break
			end
		end
		xmlUnloadFile(xml)
	end
	if not updated then
		return outputChatBox("Failed to update your mod upload #"..upID..".", client, 255,100,100)
	end

	updateMetaXml()
	outputChatBox("[Upload #"..upID.."] Set gender to "..formatGender(gender).." and race to "..formatRace(race)..".", client, 25,255,25)
end
addEvent("newmods:updateGenderRace", true)
addEventHandler("newmods:updateGenderRace", root, updateGenderRace)

function makeModGlobal(mt, upID, makePersonal, selfChange)

	upID = tonumber(upID)
	local upload = getModUpload(upID)
	if not upload then
		if not selfChange then
			return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed to find this upload ID #"..upID.."!")
		else
			return outputChatBox("Failed to find this mod upload ID #"..upID.."!" , client, 255,25,25)
		end
	end
	local modType = reverseFormatModType(mt)
	if not modType then
		if not selfChange then
			return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed to fetch mod type (upload ID #"..upID..")")
		else
			return outputChatBox("Failed to fetch mod type (upload ID #"..upID..")" , client, 255,25,25)
		end
	end

	if selfChange and not makePersonal and modType == "ped" then
		local gender,race = tonumber(upload.gender), tonumber(upload.race)
		if not gender or not race then
			return triggerClientEvent(client, "modloader:chooseSkinGenderRace", client, upID)
		end
	end

	if not makeGlobalModUpload(client, mt, modType, upID, makePersonal, selfChange) then
		if not selfChange then
			return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, false, "Failed make mod "..(makePersonal and "Personal" or "Global").." (upload ID #"..upID..")")
		else
			return outputChatBox("Failed make mod "..(makePersonal and "Personal" or "Global").." (mod upload ID #"..upID..")" , client, 255,25,25)
		end
	end

	if not selfChange then
		makeAdminAnnouncement(client, "has made "..mt.." ID #"..upload.modelid.." "..(makePersonal and "personal" or "global").." (mod request #"..upID..").")

		-- upload updated
		return triggerClientEvent(client, "modloader:receiveUploadEditConfirmation", client, true, mt.." ID #"..upload.modelid.." is now "..(makePersonal and "Personal" or "Global").." (mod request ID #"..upID..").")
	else

		makeAdminAnnouncement(client, "has made "..mt.." ID #"..upload.modelid.." "..(makePersonal and "personal" or "global").." (mod request #"..upID..") from the NPC.", true)


		outputChatBox("Your "..mt.." ID #"..upload.modelid.." is now "..(makePersonal and "personal" or "global").."!", client, 0, 255, 0)
		if makePersonal then
			outputChatBox("It is no longer available in clothing stores.", client, 255,194,14)
		else
			outputChatBox("IMPORTANT: Set the gender & race by editing the upload in the modloader.", client, 255,255,0)
			outputChatBox("The skin is now available in clothing stores.", client, 255,194,14)
		end
	end

	loadModsOnServer()
end
addEvent("newmods:makeModGlobal", true)
addEventHandler("newmods:makeModGlobal", root, makeModGlobal)


-- preview mod
function previewUploadedMod(on, mt, upID, imgid, isPlayer)
	local modType = reverseFormatModType(mt)
	if not defaultBaseModels[modType] then
		-- Unsupported
		return outputChatBox("This mod type cannot be previewed for now.", client, 255,25,25)
	end

	if not on then
		triggerClientEvent(client, "newmods:stopPreviewing", client)
		return
	end

	upID = tonumber(upID)
	local upload = getModUpload(upID)
	if not upload then
		return triggerClientEvent(client, "displayMesaage", client, "Failed to find this upload ID #"..upID.."!", "error")
	end


	local model = getModUploadModel(modType, upID)
	if not model then
		return triggerClientEvent(client, "displayMesaage", client, "Failed to fetch the model for upload ID #"..upID..".", "error")
	end


	local dffSize = tonumber(model.dffSize) or 0
	dffSize = math.ceil(dffSize/1000) --kb
	
	local txdSize = tonumber(model.txdSize) or 0
	txdSize = math.ceil(txdSize/1000) --kb

	local modText = ""
	if not isPlayer then
		makeAdminAnnouncement(client, "is now previewing uploaded mod #"..upID..".")
		modText = modText.."Uploader: "..(exports.cache:getUsernameFromId(tonumber(upload.uploadBy)) or upload.uploadBy).." | Uploader's file name: "..upload.name.."\n"
		modText = modText.."DFF Size: "..dffSize.." KB | TXD Size: "..txdSize.." KB\n\n"
		modText = modText.."Title: "..upload.title.."\n"
		modText = modText.."Author(s): "..upload.author
	else
		modText = modText.."File name: "..upload.name.."\n"
		modText = modText.."DFF Size: "..dffSize.." KB | TXD Size: "..txdSize.." KB\n\n"
		modText = modText.."Title: "..upload.title.."\n"
		modText = modText.."Author(s): "..upload.author
	end

	triggerClientEvent(client, "newmods:startPreviewing", client, modType, modText, imgid, model, upload)
end
addEvent("newmods:previewUploadedMod", true)
addEventHandler("newmods:previewUploadedMod", root, previewUploadedMod)

local previewElements = {}

function createPreviewElement(modType, baseModel, vehName)
	
	if modType == "vehicle" then


		local x,y,z = getElementPosition(client)
		local rx,ry,rz = getElementRotation(client)
		local int,dim = getElementInterior(client), getElementDimension(client)

		local veh = createVehicle(baseModel, x,y,z,rx,ry,rz)
		if veh then
			previewElements[client] = veh

			setElementInterior(veh, int)
			setElementDimension(veh, dim)

			exports.anticheat:changeProtectedElementDataEx(veh, "dbid", 0)
			exports.anticheat:changeProtectedElementDataEx(veh, "fuel", 100, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "Impounded", 0)
			exports.anticheat:changeProtectedElementDataEx(veh, "engine", 1, true)
			setVehicleEngineState(veh, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "faction", -1)
			exports.anticheat:changeProtectedElementDataEx(veh, "owner", -1, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "job", 0, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "handbrake", 0, true)

			--Custom properties
			exports.anticheat:changeProtectedElementDataEx(veh, "year", "", true)
			exports.anticheat:changeProtectedElementDataEx(veh, "brand", "", true)
			exports.anticheat:changeProtectedElementDataEx(veh, "maximemodel", vehName, true)

			exports.anticheat:changeProtectedElementDataEx(veh, "variant", -1, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "vehicle_shop_id", -1, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "fueldata", {}, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "vehlib_enabled", true, true)

			if getPedOccupiedVehicle(client) then
				removePedFromVehicle(client)
				setTimer(warpPedIntoVehicle, 500, 1, client, veh)
			else
				setTimer(warpPedIntoVehicle, 50, 1, client, veh)
			end

			triggerClientEvent(client, "newmods:receivePreviewElement", client, modType, veh)
		else
			outputChatBox("Failed to create preview vehicle base ID #"..baseModel, client, 255,0,0)
		end
	end
end
addEvent("newmods:createPreviewElement", true)
addEventHandler("newmods:createPreviewElement", root, createPreviewElement)

function destroyPreviewElement(element)
	if isElement(element) then
		destroyElement(element)
	end
	previewElements[client] = nil
end
addEvent("newmods:destroyPreviewElement", true)
addEventHandler("newmods:destroyPreviewElement", root, destroyPreviewElement)

addEventHandler( "onPlayerQuit", root, 
function (quitType, reason, responsibleElement)
	if isElement(previewElements[source]) then
		destroyElement(previewElements[source])
	end
	previewElements[source] = nil
end)

function requestOpenWizard(forFaction)

	local uploads

	if not forFaction then

    	uploads = getModUploads(getElementData(client, "account:id")) or {}

    else

	    local factionUploads = {}

	    local factions = getElementData(client, "faction") or {}
		local foundFac = false
		for k,v in pairs(factions) do
			foundFac = true
			break
		end
		if foundFac then
			local fTable = {}
			for k,v in pairs(factions) do
				local ft = exports["faction-system"]:getFactionType(k)
				if ft >= 2 and ft <= 4 then -- law/gov/med
					fTable[k] = {v, tempFactionSlots["government"]}
				elseif ft <= 1 then -- illegal official
					fTable[k] = {v, tempFactionSlots["illegal"]}
				elseif ft < 8 then -- not a legal F3 from county hall
					fTable[k] = {v, tempFactionSlots["legal"]}
				end
			end

			uploads = {}
			for id,f in pairs(fTable) do
				uploads[id] = getModUploads(- id) or {}
			end

			forFaction = fTable
		end
	end

	if not uploads then
		uploads = {}
		uploads["ped"] = {}
	end

    triggerClientEvent(client, "clothes:openModsCollection", client, uploads, forFaction)
end
addEvent("newmods:requestOpenWizard", true)
addEventHandler("newmods:requestOpenWizard", root, requestOpenWizard)


local uSure

function permDeleteAllAddons(thePlayer, cmd, modType, delType)
	if not exports.integration:isPlayerHeadAdmin(thePlayer) then return end
	if not modType or not delType then
		outputChatBox(tostring(inspect(availableModTypesBis)), thePlayer, 255,126,0)
		return outputChatBox("SYNTAX: /"..cmd.." [Mod Type from above] [Delete type: soft/perm]", thePlayer, 255,194,14)
	end
	if not availableModTypesBis[modType] then
		return permDeleteAllAddons(thePlayer, cmd)
	end
	if not (delType == "soft" or delType == "perm") then
		return permDeleteAllAddons(thePlayer, cmd)
	end

	if not isTimer(uSure) then
		outputChatBox("This will SOFT delete all "..modType.." mod files from the system", thePlayer, 255,0,0)
		outputChatBox("Are you sure you want to do this? (5 sec)", thePlayer, 255,194,14)
		uSure = setTimer(function()
			uSure = nil
		end, 5000, 1)
		return
	end
	killTimer(uSure)
	uSure = nil

	local count = 0
	for mt, v in pairs(getModUploads()) do
		if mt == modType then
			for k, upload in pairs(v) do
				local upID = upload.upid
				local worked = deleteModUpload(client, modType, upID, delType)
				if not worked then
					return outputChatBox("Aborting: failed to delete upload #"..upID, thePlayer,255,0,0)
				end
				count = count + 1
			end
		end
	end

	outputChatBox(string.upper(delType).." deleted "..count.." "..modType.." add-ons from the system.", thePlayer, 0,255,0)
	loadModsOnServer()
end
addCommandHandler("delnewmods", permDeleteAllAddons, false, false)

function updateModBaseModel(modType, upID, baseID)
	local updated = false

	local path = string.format(xmlPath, modType)
	local xml = xmlLoadFile(path)
	if xml then

		local mods = xmlNodeGetChildren(xml)
		for i, mod in pairs(mods) do

			local foundUpID
			local attrs = xmlNodeGetAttributes ( mod )
		    for name, value in pairs ( attrs ) do
		        if tostring(name) == "upid" then
		        	foundUpID = tonumber(value)
		        end
		    end

			if foundUpID == tonumber(upID) then

				xmlNodeSetAttribute(mod, "basemodel", baseID)
				xmlSaveFile(xml)
				updated = true
				break
			end
		end

		xmlUnloadFile(xml)
	end
	updateMetaXml()
	return updated
end

function changeBaseModelCmd(thePlayer, cmd, upid, base)
	if not isModFullPerm(thePlayer) then
		return
	end

	upid = tonumber(upid)
	if not upid or not base then
		return outputChatBox("SYNTAX: /"..cmd.." [Mod Upload ID] [New Base Model Name/ID]", thePlayer, 255,194,14)
	end

	local baseid
    if tonumber(base) then
        if not getVehicleNameFromModel(tonumber(base)) then
            return outputChatBox("Unknown MTA vehicle ID '"..base.."'", thePlayer, 255,0,0)
        end
        baseid = tonumber(base)
    else
        local model = getVehicleModelFromName(base)
        if not model then
            return outputChatBox("Unknown MTA vehicle Name '"..base.."'", thePlayer, 255,0,0)
        end
        baseid = model
    end

    local modType
    for mt, v in pairs(getModUploads()) do
		for k, upload in pairs(v) do
			if upload.upid == upid then
				modType = mt
				break
			end
		end
	end

	if not modType then
		return outputChatBox("Failed to find mod upload ID #"..upid, thePlayer, 255,0,0)
	end

	local worked = updateModBaseModel(modType, upid, baseid)
	if not worked then
		return outputChatBox("Failed to set base model #"..baseid.." on upload #"..upid, thePlayer,255,0,0)
	end
	outputChatBox("Base model #"..baseid.." ("..(getVehicleNameFromModel(baseid))..") set on upload #"..upid.."", thePlayer,0,255,0)

	if loadModsOnServer() and VEHICLE_TESTING_ENABLED then
		-- testing /tmv
		outputChatBox("Reloading /tmv", thePlayer,255,126,0)
		testMakeVehicles()
	end
end
addCommandHandler("changebasemodel", changeBaseModelCmd, false, false)
