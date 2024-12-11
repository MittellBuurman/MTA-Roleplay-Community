-- Fernando

------------------------------------ CONFIG & VARIABLES ------------------------------------

local allocatedIDs = {}
local atimers = {}
local adelay = 5000

local queuedSkins = {}

local loadingDelay = 5000

local waiting = false

--    Client debug mode for newmods
local debugMode = false

--    Client debug drawing mode for newmods
local drawingMode = false

local sx,sy = guiGetScreenSize()
local drawing = false

local downloadedMods = {}
local pendingDownloads = {}

-- veh specific
local handlingNoSpam
local handlingQueue = {}

--------------------------------------------------------------------------------------------

-- as of writing this handling of a vehicle is reset after its model is changed, so this is needed:
function setVehicleModelAndHandling(veh, newmodel)
	if setElementModel(veh, newmodel) then
		if isTimer(handlingNoSpam) then killTimer(handlingNoSpam) end
		handlingQueue[veh] = true
		handlingNoSpam = setTimer(function()
			if debugMode then outputChatBox("Requesting handling for "..table.size(handlingQueue).." vehs", 255,194,255) end
			triggerServerEvent("vehicle-manager:requestVehicleHandlings", localPlayer, handlingQueue)
			handlingQueue = {}
			handlingNoSpam = nil
		end, 5000, 1)
	end
end

function receiveModFromServer(modType, serverMod)
	waiting = true
	downloadModFiles(modType, serverMod)
end
addEvent("loadModFromServer", true)
addEventHandler("loadModFromServer", root, receiveModFromServer)


function downloadModFiles(modType, mod)

	local modDff = mod.dffPath
	local modTxd = mod.txdPath

	if not modDff or not modTxd then
		-- outputChatBox("Model ID #"..mod.id.." missing dff/txd path", 255,0,0)
		return
	end

	-- outputChatBox("Downloading "..modDff.." / "..modTxd.." ..", 187,187,187)

	pendingDownloads[mod.upid] = {
		dff = {modDff, false},
		txd = {modTxd, false},
		modType = modType,
		mod = mod,
	}

	if not downloadFile(modTxd) then
		local msg = "ERROR DOWNLOADING: File doesn't exist on server (meta.xml): "..modTxd
		outputConsole(msg)
		outputDebugString(msg, 1)
	end
	if not downloadFile(modDff) then
		local msg = "ERROR DOWNLOADING: File doesn't exist on server (meta.xml): "..modDff
		outputConsole(msg)
		outputDebugString(msg, 1)
	end
end

addEventHandler( "onClientFileDownloadComplete", resourceRoot, 
function (fileName, success, requestResource)

	if success then
		local found

		for upid, v in pairs(pendingDownloads) do
			if v.dff[1] == fileName then

				if v.txd[2] == true then
					found = {v.modType, v.mod}
					-- iprint("DFF downloaded, DFF already done", found)
					pendingDownloads[upid] = nil
				else
					pendingDownloads[upid].dff[2] = true -- mark dff as loaded
				end

				break

			elseif v.txd[1] == fileName then

				if v.dff[2] == true then
					found = {v.modType, v.mod}
					-- iprint("TXD downloaded, DFF already done", found)
					pendingDownloads[upid] = nil
				else
					pendingDownloads[upid].txd[2] = true -- mark txd as loaded
				end
				break
			end
		end

		if found then
			local modType, mod = unpack(found)
			downloadedMods[mod.modelid] = found
			loadOneMod(modType, mod)
		end

	else
		for upid, v in pairs(pendingDownloads) do
			if v.dff[1] == fileName or v.txd[1] == fileName then
				-- clear
				downloadedMods[v.mod.modelid] = nil
				pendingDownloads[upid] = nil
				break
			end
		end
		outputConsole("[Add-ons] Error downloading file: "..fileName)
	end
end)

function loadOneMod(modType, mod)

	local modDff = mod.dffPath
	local modTxd = mod.txdPath
	local preferredID = tonumber(mod.modelid)
	local modName = mod.title
	local baseModel = mod.basemodel or defaultBaseModels[modType]

	if preferredID and modName and modDff and modTxd then

		-- unload previous
		if allocatedIDs[preferredID] then

			engineFreeModel(allocatedIDs[preferredID].id)
			allocatedIDs[preferredID] = nil
		end

	    local newid = engineRequestModel(modType, baseModel)
		if tonumber(newid) then

	    	local txdworked,dffworked = false,false
	    	local txdmodel,dffmodel = nil,nil

	    	if modTxd then
		    	local txd = engineLoadTXD(modTxd)
		    	if txd then
		    		txdmodel = txd
					if engineImportTXD(txd,newid) then
						txdworked = true
					else
						if debugMode then outputChatBox("ERROR applying TXD on server "..modType.." #"..preferredID, 255,0,0) end
					end
				else
					if debugMode then outputChatBox("ERROR loading TXD - server "..modType.." #"..preferredID, 255,25,25) end
				end
			end

			if modDff then
				local dff = engineLoadDFF(modDff, newid)
				if dff then
		    		dffmodel = dff
					if engineReplaceModel(dff,newid) then
						dffworked = true
					else
						if debugMode then outputChatBox("ERROR applying DFF on server "..modType.." #"..preferredID, 255,0,0) end
					end
				else
					if debugMode then outputChatBox("ERROR loading DFF - server "..modType.." #"..preferredID, 255,25,25) end
				end
			end

			if not (txdworked and dffworked) then
				engineFreeModel(newid)
				if txdmodel then destroyElement(txdmodel) end -- free memory
				if dffmodel then destroyElement(dffmodel) end -- free memory

				if debugMode then
					outputChatBox("Failed to load "..modType.." (New #"..preferredID..") on ID #"..newid..".", 255, 0, 0)
				end
					
				outputConsole("[SA-RP New-Mods] Failed to load "..modType.." (New #"..preferredID..") on ID #"..newid..". DFF/TXD broken.")
			else
				if debugMode then
					outputChatBox("New "..modType.." (#"..preferredID..") allocated to #"..newid, 255, 255, 255)
				end

				if isTimer(atimers[preferredID]) then
					-- if debugMode then outputChatBox("KILLED FREE TIMER "..preferredID, 255,255,50) end
					killTimer(atimers[preferredID])
				end

				-- save it
				allocatedIDs[preferredID] = {
					id = newid,
					modType = modType,
					modName = modName,
					baseModel = baseModel,
					txdmodel = txdmodel,
					dffmodel = dffmodel,
				}

				if modType == "ped" then updatePlayersWithThisID(preferredID, newid) end
				if modType == "vehicle" then updateVehiclesWithThisID(preferredID, newid) end
			end
		else
			if debugMode then
				outputChatBox("Failed to get new ID for "..modType.." (#"..preferredID..").", 255,25,25)
			end
		end
	else
		if debugMode then
			outputChatBox("Failed to get mod stuff for "..modType.." (#"..tostring(preferredID)..").", 255,25,25)
		end
	end

	waiting = false
end

-- [PEDS]
-- update streamed in elements
function updatePlayersWithThisID(id, myID)
	id = tonumber(id)
	myID = tonumber(myID)
	if id and myID then
		local count = 0
		for k, player in ipairs(getElementsByType("player", true)) do
			-- if getElementData(player, "loggedin") == 1 then
				local s = getElementData(player, "skinID")
				if s then
					s = tonumber(s)
					if s and s == id then
						setElementModel(player, myID)
						count = count + 1
					end
				end
			-- end
		end
		for k, player in ipairs(getElementsByType("ped", true)) do
			local s = getElementData(player, "skinID")
			if s and tonumber(s) == id then
				setElementModel(player, myID)
				count = count + 1
			end
		end

		for i, skinID in pairs(queuedSkins) do
			if tonumber(skinID) == id then
				queuedSkins[i] = nil
				break
			end
		end
		if debugMode then outputChatBox("Updating "..count.." players/peds with my server skin #"..id, 25, 25, 255) end
	end
end

-- [VEHICLES]
-- update streamed in elements
function updateVehiclesWithThisID(id, myID)
	id = tonumber(id)
	myID = tonumber(myID)
	if id and myID then
		local count = 0

		for k, vehicle in ipairs(getElementsByType("vehicle", true)) do
			local s = tonumber(getElementData(vehicle, vehDatas.model))
			if s and s == id then
				setVehicleModelAndHandling(vehicle, myID)
				count = count + 1
			end
		end

		if debugMode then outputChatBox("Updating "..count.." vehicles with my server model #"..id, 25, 25, 255) end
	end
end

function endLoading()
	waiting = false
end
addEvent("endLoading", true)
addEventHandler("endLoading", root, endLoading)

-- function queueAllOnlineSkins()

-- 	local moddedSkins = getElementData(getRootElement(), "moddedSkins")
-- 	queuedSkins = {}
-- 	if moddedSkins then

-- 		local foundSkins = {}

-- 		for k, player in ipairs(getElementsByType("player")) do
-- 			-- if getElementData(player, "loggedin") == 1 then
-- 				local s = getElementData(player, "skinID")
-- 				if tonumber(s) then
-- 					foundSkins[tonumber(s)] = true
-- 				end
-- 			-- end
-- 		end
-- 		for k, player in ipairs(getElementsByType("ped")) do
-- 			local s = getElementData(player, "skinID")
-- 			if tonumber(s) then
-- 				foundSkins[tonumber(s)] = true
-- 			end
-- 		end

-- 		for k, skin in pairs(moddedSkins) do
-- 			if foundSkins[tonumber(skin.modelid)] then
-- 				-- skin is a mod
-- 				table.insert(queuedSkins, tonumber(skin.modelid))
-- 			end
-- 		end


-- 	end
-- end

-- function setLoadingQueueInfinite()
-- 	setTimer(function()

-- 		if not waiting then
-- 			for i, skinID in pairs(queuedSkins) do

-- 				if not allocatedIDs[skinID] then
-- 					if debugMode then outputChatBox("Queue: loading "..skinID, 0,25,200) end
-- 					waiting = true
-- 					triggerServerEvent("newmods:updateSkinForClientIfValid", localPlayer, skinID)
-- 				end
-- 				queuedSkins[i] = nil
-- 				break
-- 			end
-- 		else
-- 			if debugMode then outputChatBox("Queue: waiting", 0,25,200) end
-- 		end


-- 	end, loadingDelay, 0)
-- end


-- from es-sys bug after spawn fix
function forceUpdateSkin(ped)
	local serverSkin = tonumber(getElementData(ped, "skinID"))
	if serverSkin then

		local moddedSkins = getElementData(getRootElement(), "moddedSkins")
		if moddedSkins then

			-- local x,y,z = getElementPosition(ped)
			-- local i,d = getElementInterior(ped), getElementDimension(ped)

			-- local lx,ly,lz = getElementPosition(localPlayer)
			-- local li,ld = getElementInterior(localPlayer), getElementDimension(localPlayer)

			-- if i==li and d==ld  then --and getDistanceBetweenPoints3D(x,y,z, lx,ly,lz) < 100

				local fm = false
				for k, skin in pairs(moddedSkins) do
					if serverSkin == tonumber(skin.modelid) then
						fm = true
						break
					end
				end

				if fm then
					if allocatedIDs[serverSkin] then
						local aid = allocatedIDs[serverSkin].id
						if debugMode then outputChatBox("Load ped: setting loaded mod skin #"..serverSkin, 255,200,0) end
						setElementModel(ped, aid)
					else

						-- remove from queue if its there
						for i, skinID in pairs(queuedSkins) do
							if tonumber(skinID) == serverSkin then
								queuedSkins[i] = nil
								break
							end
						end

						local dlMod = downloadedMods[serverSkin]
						if dlMod ~= nil then
							loadOneMod(unpack(dlMod))
						else

							if debugMode then outputChatBox("Load ped: asking to load mod skin #"..serverSkin, 255,200,0) end
							waiting = true
							triggerServerEvent("newmods:updateSkinForClientIfValid", localPlayer, serverSkin)
						end
					end
				else
					if debugMode then outputChatBox("Load ped: unknown custom skin #"..serverSkin, 255,125,0) end
				end
			-- end
		end
	end
end
addEvent("forceUpdateSkin", true)
addEventHandler("forceUpdateSkin", root, forceUpdateSkin)

function onElementStreamedIn()
	local et = getElementType(source)
	if et == "ped" or et == "player" then

		forceUpdateSkin(source)
	
	elseif et == "vehicle" then

		local veh = source
		local vehModel = tonumber(getElementData(veh, vehDatas.model))
		if vehModel then
			-- vehicle is modded
			if allocatedIDs[vehModel] then
				if debugMode then outputChatBox("Load vehicle [si]: setting loaded vehicle mod model #"..vehModel.." (( dbid #"..getElementData(veh, "dbid").." ))", 255,200,0) end
				setVehicleModelAndHandling(veh, allocatedIDs[vehModel].id)
			else

				local dlMod = downloadedMods[vehModel]
				if dlMod ~= nil then
					loadOneMod(unpack(dlMod))
				else
					if debugMode then outputChatBox("Requesting mod [si] for vehicle model #"..vehModel.." (( dbid #"..getElementData(veh, "dbid").." ))", 25, 255, 25) end
					triggerServerEvent("newmods:updateVehicleModel", localPlayer, vehModel)
				end
			end
		end
	end
end
addEvent("newmods:onElementStreamedIn", true)
addEventHandler("newmods:onElementStreamedIn", root, onElementStreamedIn)
addEventHandler( "onClientElementStreamIn", root, onElementStreamedIn)

function onElementStreamOut()
	local et = getElementType(source)
	if et == "ped" or et == "player" or et == "vehicle" then
		
		local modelid, dataName

		if et == "ped" or et == "player" then
			dataName = "skinID"
			modelid = tonumber(getElementData(source, dataName))
		elseif et == "vehicle" then
			dataName = vehDatas.model
			modelid = getElementData(source, dataName)
		end

		local a = allocatedIDs[modelid]
		if modelid and a then
			
			if isTimer(atimers[modelid]) then
				-- if debugMode then outputChatBox("KILLED FREE TIMER "..modelid, 255,255,50) end
				killTimer(atimers[modelid])
			end
			-- if debugMode then outputChatBox("TRYING TO FREE SOON "..modelid, 2550,255,255) end
			atimers[modelid] = setTimer(function(id, dn, et2)

				local aid, txdmodel, dffmodel = a.id, a.txdmodel, a.dffmodel

				local oneStreamedIn = false

				-- check if no elements streamed in have that id
				for k, element in ipairs(getElementsByType(et)) do
					local id3 = tonumber(getElementData(element, dataName))
					if id3 and id3 == id then
						if isElementStreamedIn(element) then
							oneStreamedIn = element
							break
						end
					end
				end

				if (not oneStreamedIn) then

					allocatedIDs[id] = nil

					if isElement(txdmodel) then destroyElement(txdmodel) end
					if isElement(dffmodel) then destroyElement(dffmodel) end

					if engineFreeModel(aid) then
						if debugMode then outputChatBox("FREED "..id.." real: "..aid, 0,255,50) end
					else
						if debugMode then outputChatBox("FREED (return false) "..id.." real: "..aid, 0,255,50) end
					end

				else
					if debugMode then outputChatBox("NOT FREEING "..id.." real: "..aid, 255,25,25) end
				end

				atimers[id] = nil

			end, adelay, 1, modelid, dataName, et)
		end
	end
end
addEventHandler( "onClientElementStreamOut", root, onElementStreamOut)
addEventHandler( "onClientElementDestroy", root, onElementStreamOut)

function loadStreamedElements()
	for k,veh in ipairs(getElementsByType("vehicle")) do
		if isElementStreamedIn(veh) then
			triggerEvent("newmods:onElementStreamedIn", veh)
		end
	end
	for k,veh in ipairs(getElementsByType("ped")) do
		if isElementStreamedIn(veh) then
			triggerEvent("newmods:onElementStreamedIn", veh)
		end
	end
	for k,veh in ipairs(getElementsByType("player")) do
		if isElementStreamedIn(veh) then
			triggerEvent("newmods:onElementStreamedIn", veh)
		end
	end
end

addEventHandler( "onClientElementDataChange", root,
function (theKey, oldValue, newValue)

	local element = source
	local et = getElementType(element)
	if theKey == "skinID" and (et == "ped" or et == "player") then
		if not isElementStreamedIn(element) then return end
		local serverSkin = tonumber(newValue)
		if serverSkin then
			local moddedSkins = getElementData(getRootElement(), "moddedSkins")
			if moddedSkins then

				local fm = false
				for k, skin in pairs(moddedSkins) do
					if serverSkin == tonumber(skin.modelid) then
						fm = true
						break
					end
				end

				if fm then
					if allocatedIDs[serverSkin] then
						if isElementStreamedIn(element) then
							local aid = allocatedIDs[serverSkin].id
							if debugMode then outputChatBox("Change skin: setting loaded mod skin #"..serverSkin, 255,255,0) end
							setElementModel(element, aid)
						end
					else
						if not isElementStreamedIn(element) then

							-- take it out of the queue if it's there
							for i, skinID in pairs(queuedSkins) do
								if tonumber(skinID) == serverSkin then
									queuedSkins[i] = nil
									break
								end
							end
							-- add to queue to load later
							table.insert(queuedSkins, serverSkin)

						else
							local dlMod = downloadedMods[serverSkin]
							if dlMod ~= nil then
								loadOneMod(unpack(dlMod))
							else

								-- the element changed skin and is streamed; update it now
								if debugMode then outputChatBox("Change skin: asking to load mod skin #"..serverSkin, 255,255,0) end
								waiting = true
								triggerServerEvent("newmods:updateSkinForClientIfValid", localPlayer, serverSkin)
							end
						end
					end
				else
					if debugMode then outputChatBox("Load ped: unknown custom skin #"..serverSkin, 255,125,0) end
				end
			end
		end
	elseif theKey == vehDatas.model and et == "vehicle" then
		if not isElementStreamedIn(element) then return end
		local vehModel = tonumber(newValue)
		if vehModel then
			-- vehicle is modded
			if allocatedIDs[vehModel] then
				if debugMode then outputChatBox("Load vehicle [dc]: setting loaded vehicle mod model #"..vehModel.." (( dbid #"..getElementData(element, "dbid").." ))", 255,200,0) end
				setVehicleModelAndHandling(element, allocatedIDs[vehModel].id)
			else
				local dlMod = downloadedMods[vehModel]
				if dlMod ~= nil then
					loadOneMod(unpack(dlMod))
				else

					if debugMode then outputChatBox("Requesting mod [dc] for vehicle model #"..vehModel.." (( dbid #"..getElementData(element, "dbid").." ))", 25, 255, 25) end
					triggerServerEvent("newmods:updateVehicleModel", localPlayer, vehModel)
				end
			end
		end
	end
end)


-- ok; + reset skin on serverisde
function unloadModelID(modType, modelid, noOutput)
	modelid = tonumber(modelid)
	if allocatedIDs[modelid] then


		if modType == "ped" then

			triggerServerEvent("prison:resetSkin", localPlayer, localPlayer, true)
			triggerEvent("displayMesaage", localPlayer, "The skin you were wearing has been disabled so it was reset.", "info")

			if not noOutput then

				local outputted = false
				for k, player in ipairs(getElementsByType("player", true)) do
					if player ~= localPlayer and getElementData(player, "skinID") == modelid then

						triggerEvent("displayMesaage", localPlayer, "At least one of the players near you had their skin mod unloaded.", "warning")
						return
					end
				end
			end
		end

		if engineFreeModel(allocatedIDs[modelid].id) then
			if isElement(allocatedIDs[modelid].txdmodel) then destroyElement(allocatedIDs[modelid].txdmodel) end
			if isElement(allocatedIDs[modelid].dffmodel) then destroyElement(allocatedIDs[modelid].dffmodel) end
			if debugMode then outputChatBox("FREED "..modelid.." real: "..allocatedIDs[modelid].id, 0,255,50) end
			allocatedIDs[modelid] = nil
		end
	end
end
addEvent("unloadModelID", true)
addEventHandler("unloadModelID", root, unloadModelID)


-- exported; clothes-system for texture apply
function getRealModelID(id)
	if allocatedIDs[id] then
		return allocatedIDs[id].id
	end
	return id
end

function onStop()

	for prefid, v in pairs(allocatedIDs) do
        engineFreeModel(v.id)
    end
	
	triggerEvent("displayMesaage", localPlayer, "The mod add-ons system has been reloaded", "info")
end
addEventHandler("onClientResourceStop", resourceRoot, onStop)

local startTimer

function onStart()

	startTimer = setTimer(function()

		if getElementData(localPlayer, "loggedin") == 1 then

			-- Skin queue is no longer needed

			-- queueAllOnlineSkins()
			-- setLoadingQueueInfinite()

			loadStreamedElements()
			killTimer(startTimer)
		end
	end, 5000, 0)

	-- testing debugmode
	-- togDebugMode()
	
	-- testing drawingmode
	-- togDrawingMode()


	-- testing ids

	-- local testMT = "vehicle"
	-- local temp = testMT.."_temp.txt"
	-- local f
	-- if not fileExists(temp) then
	-- 	f = fileCreate(temp)
	-- else
	-- 	f = fileOpen(temp)
	-- end

	-- local ids = {}
	-- local works = true
	-- while (works) do
	-- 	works = engineRequestModel(testMT)
	-- 	if works then
	-- 		table.insert(ids, works)
	-- 	end
	-- end

	-- local text = "{ "
	-- for k, id in pairs(ids) do
	-- 	text=text..id..", "
	-- end
	-- text=text.." }"

	-- fileWrite(f, text)
	-- fileClose(f)

end
addEventHandler("onClientResourceStart", resourceRoot, onStart)



function drawNewmodsDebug()

	local px,py,pz = getElementPosition(localPlayer)
	local int,dim = getElementInterior(localPlayer), getElementDimension(localPlayer)
	local lx, ly, lz = getCameraMatrix()

	for k, veh in ipairs(getElementsWithinRange(px,py,pz, 35, "vehicle")) do

		local i,d = getElementInterior(veh), getElementDimension(veh)
		if d == dim and i == int then

			local x,y,z = getElementPosition(veh)
			z=z+1

			local collision, cx, cy, cz, element = processLineOfSight(lx, ly, lz, x,y,z,
			false, false, false, false, false, false, false, true, veh)

			if not collision then

				local onScreenX, onScreenY, distance = getScreenFromWorldPosition(x,y,z)
				if onScreenX and onScreenY then

					local text = ""

					local dbid = getElementData(veh, "dbid")
					if dbid then
						text=text.."(( DBID: #"..dbid.." ))"
					end
					
					local vehModel = getElementData(veh, vehDatas.model)
					if vehModel then
						text=text.."\nNew: #"..vehModel.." ("..getElementData(veh, vehDatas.name)..")"
					end

					local parentModel = getElementData(veh, vehDatas.base)
					if parentModel then
						text=text.."\nParent: #"..parentModel.." ("..getVehicleNameFromModel(parentModel)..")"
					end

					local fsize = 1.6
					local fcolor = "0xffffffff"

					local allocatedID = allocatedIDs[vehModel]
					if allocatedID then
						fsize = 1.2
						fcolor = "0xff00ff00"
					end
						
					local width = dxGetTextWidth(text, fsize)
					local dx, dy = onScreenX - width/2, onScreenY

					dxDrawText(text, dx, dy, dx, dy, fcolor, fsize)
				end
			end
		end
	end
end


----------------------------------------------- preview skin ---------------------------------------

sx,sy = guiGetScreenSize()
local drawing = false
local modInfo_, modPicture_, imageID
local replacingModel = nil
local modelElements = {}
local previewElement = nil
local previewButtons = {}


function startPreviewing(modType, modInfo, imageID_, model, upload)
	local dff = model.dff
	local txd = model.txd

	if not dff or not txd then
		return triggerEvent("displayMesaage", localPlayer, "Failed to get DFF/TXD for model.", "error")
	end

	local baseModel = model.basemodel or defaultBaseModels[modType]

	local newid = engineRequestModel(modType, baseModel)
	if not tonumber(newid) then
		return triggerEvent("displayMesaage", localPlayer, "Failed to allocate "..modType.." model for preview.", "error")
	end

	-- try load model
	local txdworked, dffworked = false,false
	local txdModel = engineLoadTXD(txd)
	if txdModel then
		table.insert(modelElements, txdModel)
		if engineImportTXD(txdModel, newid) then
			txdworked = true
		end
	else
		engineFreeModel(newid)
		return triggerEvent("displayMesaage", localPlayer, "Failed to load model's TXD file.", "error")
	end

	local dffModel = engineLoadDFF(dff, newid)
	if dffModel then
		table.insert(modelElements, dffModel)
		if engineReplaceModel(dffModel, newid) then
			dffworked = true
		end
	else
		engineFreeModel(newid)
		return triggerEvent("displayMesaage", localPlayer, "Failed to load model's DFF file.", "error")
	end

	if not (txdworked and dffworked) then
		engineFreeModel(newid)
		for k, el in pairs(modelElements) do if isElement(el) then destroyElement(el) modelElements = {} end end -- free memory
		return triggerEvent("displayMesaage", localPlayer, "There was an error applying DFF/TXD.", "error")
	end

	replacingModel = newid

	-- start previewing
	setElementData(localPlayer, "modloader:previewing", true)
	imageID = imageID_
	setDrawingPreview(true, modInfo)

	if modType == "vehicle" then
		local vehName = upload.name.." (newid #"..upload.modelid..") (upid #"..upload.upid..") (base: "..(getVehicleNameFromModel(upload.basemodel) or "?")..")"
		triggerServerEvent("newmods:createPreviewElement", localPlayer, modType, baseModel, vehName)
	else

		setElementData(localPlayer, "beforePreviewModel", getElementModel(localPlayer))
		setElementModel(localPlayer, replacingModel)
		outputChatBox("INFO: #ffffffOnly you can see the custom model on your character.", 255,255,0,true)
	end

	local bw, bh = 150, 30
	previewButtons["end"] = guiCreateButton(sx/2 - bw/2, 5, bw, bh, "End Mod Preview", false)
	guiSetProperty(previewButtons["end"], "NormalTextColour", "FFFFFF00")
	guiSetAlpha(previewButtons["end"], 0.9)
	
	addEventHandler( "onClientGUIClick", previewButtons["end"],
	function (button)
		if button == "left" then
			stopPreviewing()
		end
	end, false)

	if modType == "vehicle" then

		previewButtons["doors"] = guiCreateButton(sx/2 - bw/2 - bw - 6, 5, bw, bh, "Open/Close Doors", false)
		addEventHandler( "onClientGUIClick", previewButtons["doors"],
		function (button)
			if button == "left" then
				if isElement(previewElement) then
					local openorclose = (getVehicleDoorOpenRatio(previewElement, 2) > 0) and 0 or 1--check one state only
					for door=0,5 do
			    		setVehicleDoorOpenRatio(previewElement, door, openorclose, 600)
					end
				end
			end
		end, false)
	end
end
addEvent("newmods:startPreviewing", true)
addEventHandler("newmods:startPreviewing", root, startPreviewing)

function doPreviewModel(modType, element)

	if isElement(element) then
		previewElement = element
		setElementModel(previewElement, replacingModel)
		outputChatBox("INFO: #ffffffOnly you can see the custom model on the "..modType.." spawned serverside.", 255,255,0,true)
	end
end
addEvent("newmods:receivePreviewElement", true)
addEventHandler("newmods:receivePreviewElement", root, doPreviewModel)

-- also triggered from s_characters account
function stopPreviewing()

	setElementData(localPlayer, "modloader:previewing", nil)
	setDrawingPreview(false)

	if replacingModel then
		engineFreeModel(replacingModel)
		replacingModel = nil
	end
	
	for k, el in pairs(modelElements) do if isElement(el) then destroyElement(el) modelElements = {} end end -- free memory


	if isElement(previewButtons["end"]) then
		
		destroyElement(previewButtons["end"])

		if isElement(previewButtons["doors"]) then
			destroyElement(previewButtons["doors"])
		end
		previewButtons = {}


		if isElement(previewElement) then
			-- destroy the element that was being previwed (e.g. vehicle)
			triggerServerEvent("newmods:destroyPreviewElement", localPlayer, previewElement)
			previewElement = nil
		else
			-- reset the player's skin as no element was created to preview the mod
			local oldSkin = getElementData(localPlayer, "skinID")
			if oldSkin then
				setElementData(localPlayer, "skinID", oldSkin)
			else
				setElementModel(localPlayer, getElementData(localPlayer, "beforePreviewModel"))
				setElementData(localPlayer, "beforePreviewModel", nil)
			end
		end

		
		triggerEvent("displayMesaage", localPlayer, "Preview has ended. Reopening Modloader...", "info")
		executeCommandHandler("modloader", "bypass")

	end
end
addEvent("newmods:stopPreviewing", true)
addEventHandler("newmods:stopPreviewing", root, stopPreviewing)

function makeTestVeh(id, x,y,z, rx,ry,rz)
	-- Make the vehicle serverside so it's enterable etc
	local veh = createVehicle(id, x,y,z, rx,ry,rz)
	if veh then
		setVehicleOverrideLights(veh, 1)
		setVehicleFuelTankExplodable(veh, false)
		setElementData(veh, "engine", 1, true)
		setVehicleEngineState(veh, true)

		setElementData(veh, "dbid", -9999)
		setElementData(veh, "fuel", 100, false)
		setElementData(veh, "Impounded", 0)
		setElementData(veh, "oldx", x, false)
		setElementData(veh, "oldy", y, false)
		setElementData(veh, "oldz", z, false)
		setElementData(veh, "faction", -1)
		setElementData(veh, "owner", -1, false)
		setElementData(veh, "job", 0, false)
		setElementData(veh, "handbrake", 0, true)

		--Custom properties
		setElementData(veh, "year", "", true)
		setElementData(veh, "brand", "", true)
		setElementData(veh, "maximemodel", "Preview", true)
		setElementData(veh, "variant", -1, true)
		setElementData(veh, "vehicle_shop_id", -1, true)
		setElementData(veh, "fueldata", {}, true)
		setElementData(veh, "vehlib_enabled", true, true)
	end
	return veh
end

function setDrawingPreview(on, modInfo)

	if on and not drawing and modInfo then
		modInfo_ = modInfo
		drawing = true
		addEventHandler("onClientRender", root, drawPreview)
	else
		removeEventHandler("onClientRender", root, drawPreview)
		drawing = false
		modInfo_ = nil
		modPicture_ = nil
	end
end

function drawPreview()
	if drawing and modInfo_ and imageID then

		local fname = "default-bold-small"
		local fsize = 1
		local text = modInfo_
		local length = dxGetTextWidth(text, fsize, fname)

		local _, lines = text:gsub('\n','\n')
		local startY = 80

		local recAlpha = 200

		local recWidth, recHeight = length + 6*2, 20*lines +5

		local text2 = "Mod is only loaded on your game, meaning that other players cannot see you previewing it."
		local length2 = dxGetTextWidth(text2, fsize, fname)
		if length2 > length then
			recWidth = length2 + 6*2
		end

		local x,y = sx/2 - recWidth/2, startY
		dxDrawRectangle(x,y, recWidth, recHeight, tocolor(0,0,0,recAlpha))

		local recWidth2, recHeight2 = recWidth + recHeight + 5, 30
		local x2,y2 = x, y - recHeight2 - 5
		dxDrawRectangle(x2,y2, recWidth2, recHeight2, tocolor(0,0,0,recAlpha))

		local tx2, ty2 = sx/2 - length2/2, startY - recHeight2 + 2.5
		dxDrawText(text2, tx2, ty2, tx2, ty2, tocolor(0,255,0,255), fsize, fname)

		local tx, ty = sx/2 - length/2, startY+5
		dxDrawText(text, tx, ty, tx, ty, tocolor(255,255,255,255), fsize, fname)

		local ix,iy = x + recWidth + 5, y
		local isize = recHeight

		dxDrawRectangle(ix,iy, isize, isize, tocolor(0,0,0,recAlpha), true)
		if not modPicture_ then
			-- print("getting image for "..imageID)
			modPicture_ = getImage(tonumber(imageID))
		end
		if modPicture_ and modPicture_.tex then
			dxDrawImage(ix,iy, isize, isize, modPicture_.tex, 0, 0, 0, tocolor(255,255,255,255), true)
		else
			local text = "Loading.."
            local length = dxGetTextWidth(text, 1, "default-bold-small")
            local ttx,tty = ix + isize/2 -length/2, iy + isize/2 -10
            dxDrawText(text, ttx,tty, ttx,tty, tocolor(255,255,255,255), 1, "default-bold-small", "left", "top", false, false, true)
		end

	end
end

stopPreviewing()

-- COMMANDS -------------------------------------------------------------------------

function togDebugMode()
	debugMode = not debugMode
	outputChatBox("sarp-new-mods Clientside debug: "..(debugMode and "ON" or "OFF"), 255,194,14)
end
addCommandHandler("newmodsdebug", togDebugMode, false)

function togDrawingMode()
	drawingMode = not drawingMode
	outputChatBox("sarp-new-mods Clientside drawing: "..(drawingMode and "ON" or "OFF"), 255,194,14)

	if drawingMode then
		if not drawing then
			addEventHandler("onClientRender", root, drawNewmodsDebug)
			drawing = true
		end
	else
		if drawing then
			removeEventHandler("onClientRender", root, drawNewmodsDebug)
			drawing = false
		end
	end
end
addCommandHandler("newmodsdrawing", togDrawingMode, false)

function viewSkinQueue()
	outputChatBox("Queued skins: ", 255,126,0)
	local count = 0
	for k, id in pairs(queuedSkins) do
		outputChatBox("  - "..id, 255,194,14)
		count = count + 1
	end
	outputChatBox("There are "..count.." skins left to load.", 0, 255, 0)
end
addCommandHandler("queuedskins", viewSkinQueue)


function cmdGetNewMods()
	local count = 0

	local text = ""
	for id, v in pairsByKeys(allocatedIDs) do

		local realid = v.id
		local modType = v.modType
		local modName = v.modName
		local baseModel = v.baseModel

		text=text.."#"..id.." ["..modType.."] '"..modName.."': Allocated to #"..realid.." (Base: #"..baseModel..")\n"
		count = count + 1
	end

	text=text.."\nTotal: "..count
	triggerEvent("openMemoBoxWithContent", localPlayer, "List of New Mods (allocated ID slots)", text)
end
addCommandHandler("loadednewmods", cmdGetNewMods, false, false)

function testNewModsVehicle()
	local veh = getPedOccupiedVehicle(localPlayer)
	if not veh then return end

	local model = getElementModel(veh) -- should be the allocated one
	local name = getVehicleNameFromModel(model) or "?"
	local vt = getVehicleType(veh) or "Unknown Type"

	local customModel = getElementData(veh, vehDatas.model)
	local customName = getElementData(veh, vehDatas.name)

	local parentModel = getElementData(veh, vehDatas.base)
	local parentName = getVehicleNameFromModel(parentModel)

	local lines = {}

	table.insert(lines, "Element Model #"..model.." ("..name..") - "..vt)
	table.insert(lines, "Custom Model #"..customModel.." ("..customName..")")
	table.insert(lines, "Parent Model #"..parentModel.." ("..parentName..")")

	for k,line in pairs(lines) do
		outputChatBox("[CLIENT] #ffffff"..line, 255,194,14, true)
	end
end
addCommandHandler("newmodsveh", testNewModsVehicle)