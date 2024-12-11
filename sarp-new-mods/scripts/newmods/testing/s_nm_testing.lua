-- Fernando
-- New Mods Testing
-- [CLIENTSIDE]
-- File created: 21/10/2021

VEHICLE_TESTING_ENABLED = false -- this is a bad idea with 100+ vehicle addons xD

if VEHICLE_TESTING_ENABLED then

	-- Spawn "moddedVehicles" that can be driven
	local DBIDs = -1000
	local dontSpamTmv
	local spawnedVehs = {}
	local startx,starty,startz = 2051.15234375, -2504.6396484375, 14.5
	local locname = "LS Airport"

	function testMakeVehiclesGoto(thePlayer, cmd)
		if not isModReviewer(thePlayer) then return end

		setElementDimension(thePlayer, 0)
		setElementInterior(thePlayer, 0)
		setCameraInterior(thePlayer, 0)
		setElementPosition(thePlayer, startx,starty,startz)
		triggerEvent("frames:loadInteriorTextures", thePlayer, 0)
	end
	addCommandHandler("tmvg", testMakeVehiclesGoto, false, false)

	function testMakeVehicles(thePlayer, cmd)
		if isElement(thePlayer) and getElementType(thePlayer)=="player" then
			if not isModReviewer(thePlayer) then return end
			if dontSpamTmv then
				outputChatBox("Please wait a bit. /"..cmd.." can't be spammed.", thePlayer, 255,50,50)
				return
			end
		end

		if isTimer(dontSpamTmv) then killTimer(dontSpamTmv) end
		dontSpamTmv = setTimer(function()
			dontSpamTmv = nil
		end, 5000, 1)

		-- reset start ----------------------
		for k, veh in pairs(spawnedVehs) do
			if isElement(veh) then
				destroyElement(veh)
			end
		end
		spawnedVehs = {}
		-- reset end ------------------------

		-- Place player in
		local x,y,z = startx,starty,startz
		local rx,ry,rz = 0,0,90

		local count = 0
		local count2 = 0
		local moddedVehicles = getElementData(getRootElement(), "moddedVehicles") or {}

		for k, v in pairs(moddedVehicles) do

			x = x - 13

			local name = v.title
			local basemodel = v.basemodel
			local upid = v.upid
			local model = v.modelid

			local veh = createVehicleNew(model, x,y,z,rx,ry,rz)
			if veh then

				local dbid = DBIDs

				setVehicleOverrideLights(veh, 1)
				exports.anticheat:changeProtectedElementDataEx(veh, "lights", 1, true)
				setVehicleFuelTankExplodable(veh, false)

				exports.anticheat:changeProtectedElementDataEx(veh, "dbid", dbid)
				exports.pool:allocateElement(veh, dbid)

				exports.anticheat:changeProtectedElementDataEx(veh, "fuel", 100, false)
				exports.anticheat:changeProtectedElementDataEx(veh, "Impounded", 0)
				exports.anticheat:changeProtectedElementDataEx(veh, "engine", 0, true)
				setVehicleEngineState(veh, false)
				exports.anticheat:changeProtectedElementDataEx(veh, "faction", -1)
				exports.anticheat:changeProtectedElementDataEx(veh, "owner", -1, false)
				exports.anticheat:changeProtectedElementDataEx(veh, "job", 0, false)
				exports.anticheat:changeProtectedElementDataEx(veh, "handbrake", 0, true)

				--Custom properties
				exports.anticheat:changeProtectedElementDataEx(veh, "year", "", true)
				exports.anticheat:changeProtectedElementDataEx(veh, "brand", "", true)
				exports.anticheat:changeProtectedElementDataEx(veh, "maximemodel", name.." (newid #"..model..") (upid #"..upid..") (base: "..(getVehicleNameFromModel(basemodel) or "?")..")", true)

				exports.anticheat:changeProtectedElementDataEx(veh, "variant", -1, true)
				exports.anticheat:changeProtectedElementDataEx(veh, "vehicle_shop_id", -1, true)
				exports.anticheat:changeProtectedElementDataEx(veh, "fueldata", {}, true)
				exports.anticheat:changeProtectedElementDataEx(veh, "vehlib_enabled", true, true)

				triggerEvent("onVehicleCreated", veh) -- Fernando  08/11/2021  Used across various scripts

				DBIDs = DBIDs - 1

				table.insert(spawnedVehs, veh)
				count = count +1
				count2 = count2 +1

				if count2 == 50 then
					count2 = 0
					x,y,z = startx,y+6,startz
				end
			end
		end

		if isElement(thePlayer) and getElementType(thePlayer)=="player" then
			outputChatBox("Created "..count.." test vehicles at "..locname..". Use /tmvg to teleport there.", thePlayer, 255,194,14)
		end
	end
	addCommandHandler("tmv", testMakeVehicles, false, false)


	addEventHandler( "onResourceStop", resourceRoot, 
	function (stoppedResource, wasDeleted) 
		for k,veh in pairs(spawnedVehs) do
			destroyElement(veh)
		end
	end)
end


function cmdListNewVehs(thePlayer, cmd)

	local count = 0

	local text = ""
	local moddedVehicles = getElementData(getRootElement(), "moddedVehicles") or {}
	for k, v in pairs(moddedVehicles) do

		local model = v.modelid
		local name = v.title
		local base = v.basemodel
		local basename = getVehicleNameFromModel(base) or "?"

		text=text..name.." (#"..model..") - Base "..base.." (#"..basename..")\n"
		count = count + 1
	end

	text=text.."\nTotal: "..count
	triggerClientEvent(thePlayer, "openMemoBoxWithContent", thePlayer, "List of New Vehicles", text)
end
addCommandHandler("newvehs", cmdListNewVehs, false, false)

-- Testing
-- SERVERSIDE
function testNewModsVehicle(thePlayer)
	local veh = getPedOccupiedVehicle(thePlayer)
	if not veh then return end

	local customModel = getElementData(veh, vehDatas.model)
	local customName = getElementData(veh, vehDatas.name)

	local parentModel = getElementData(veh, vehDatas.base)
	local parentName = getVehicleNameFromModel(parentModel)

	local lines = {}

	table.insert(lines, "Custom Model #"..customModel.." ("..customName..")")
	table.insert(lines, "Base Model #"..parentModel.." ("..parentName..")")

	for k,line in pairs(lines) do
		outputChatBox("#ffffff"..line, thePlayer, 255,126,0, true)
	end
end
addCommandHandler("newvehinfo", testNewModsVehicle)


-- Was single use-only:
-- function FixUploadIds(thePlayer)
-- 	if not exports.integration:isPlayerScripter(thePlayer) then return end

-- 	local total=0
-- 	for k, modType in pairs(availableModTypes) do

-- 		local path = string.format(xmlPath, modType)
-- 		local xml = xmlLoadFile(path)
-- 		if xml then

-- 			local upIDCounter = 0
-- 			local mods = xmlNodeGetChildren(xml)
-- 			for i, mod in pairs(mods) do

-- 				upIDCounter = upIDCounter+1
-- 				xmlNodeSetAttribute(mod, "upid", upIDCounter)

-- 				-- fix image
-- 				local foundStatus
-- 				local attrs = xmlNodeGetAttributes ( mod )
-- 			    for name, value in pairs ( attrs ) do
-- 			        if tostring(name) == "status" then
-- 			        	foundStatus = tostring(value)
-- 			        end
-- 			    end
-- 			    if foundStatus == "Accepted" then
-- 					justMoveImage(tonumber(i), upIDCounter)
-- 				else
-- 					justMoveImage(-tonumber(i), -upIDCounter)
-- 				end
-- 			end
-- 			total = total+upIDCounter

-- 			xmlSaveFile(xml)
-- 			xmlUnloadFile(xml)
-- 		end
-- 	end

-- 	outputChatBox(total.." uploads fixed.", thePlayer)
-- end
-- addCommandHandler("fixuploadids", FixUploadIds)
