-- Fernando

xmlPath = "files/%s_mods.xml" -- used by s_newmods and s_images

-- Custom ID datas: skinID and vehicleID
availableModTypes = { "ped", "vehicle" }
availableModTypesBis = {
	["ped"] = true,
	["vehicle"] = true,
}


--Vehicle related:
vehDatas = {
	model = "vehModel",
	name = "vehName",
	properties = "vehProperties",
	base = "baseModel",
}


-- Exported:
function getVehicleCustomModel(theVehicle)
	return getElementData(theVehicle, vehDatas.model)
end
function getVehicleCustomName(theVehicle)
	return getElementData(theVehicle, vehDatas.name)
end
function getVehicleCustomProperties(theVehicle)
	return getElementData(theVehicle, vehDatas.properties)
end
function getVehicleBaseModel(theVehicle)
	return getElementData(theVehicle, vehDatas.base)
end
function getVehicleNameFromModelNew(model)
	local moddedVehicles = getElementData(getRootElement(), "moddedVehicles") or {}
	for k, v in pairs(moddedVehicles) do

		local _model = v.modelid
		local name = v.title

		if tonumber(_model) == tonumber(model) then
			return name
		end
	end
	return false
end
function getVehicleModelFromNameNew(name)
	local moddedVehicles = getElementData(getRootElement(), "moddedVehicles") or {}
	for k, v in pairs(moddedVehicles) do

		local model = v.modelid
		local _name = v.title

		if string.lower(_name) == string.lower(name) then
			return tonumber(model)
		end
	end
	return nil
end
function getOriginalHandlingNew(model)
	if not tonumber(model) then return false end
	model = tonumber(model)

	local moddedVehicles = getElementData(getRootElement(), "moddedVehicles") or {}
	for k, v in pairs(moddedVehicles) do

		local _model = v.modelid
		local name = v.title

		if tonumber(_model) == tonumber(model) then
			local base = v.basemodel
			local handling = getOriginalHandling(base)
			if handling then
				return handling
			else
				return false
			end
		end
	end
	return getOriginalHandling(model)
end
function createVehicleNew(model, x,y,z, rx,ry,rz, plate)
	local moddedVehicles = getElementData(getRootElement(), "moddedVehicles") or {}
	for k, v in pairs(moddedVehicles) do

		local _model = v.modelid
		local name = v.title

		if tonumber(_model) == tonumber(model) then
			local base = v.basemodel
			local veh = exports.vehicle_load:createVehicleHere(base, x,y,z, rx,ry,rz, plate)
			if veh then

				setElementData(veh, vehDatas.model, model)
				setElementData(veh, vehDatas.base, base)
				setElementData(veh, vehDatas.name, name)
				
				return veh
			else
				return false
			end
		end
	end
	return exports.vehicle_load:createVehicleHere(model, x,y,z, rx,ry,rz, plate)
end

-- Exported
function isCustomMod(id, modType)
	local mods
	if modType == "vehicle" then
		mods = getElementData(getRootElement(), "moddedVehicles") or nil
	elseif modType == "ped" then
		mods = getElementData(getRootElement(), "moddedSkins") or nil
	end
	if mods then
		for k,v in pairs(mods) do
			if tonumber(v.modelid) == tonumber(id) then
				return true
			end
		end
	end
	return false
end

function getHash(str)
	return md5(str)
end

tempFactionSlots = {
	["government"] = 50,
	["illegal"] = 25,
	["legal"] = 25,
}

skinStoreName = "No/Sense Clothing"

defaultBaseModels = {
    ["ped"] = 1,
    ["vehicle"] = 400,
}

maxFreeModUploads = 3 -- personal
refresh_rate = 250 -- image refresh rate
maxImageWidth = 200 -- pixels
maxImageFileSize = 350*1024 -- kb

maxFileSizes = {
    ["dff"] = (800 * 1024), -- kb
    ["txd"] = (800 * 1024), -- kb
    ["dffBigger"] = (2000 * 1024), -- kb
    ["txdBigger"] = (1000 * 1024), -- kb
}

exclusiveUsernames = {
	["Black"] = true,
	["Fernando"] = true,
	["Portside"] = true,
}

function canUploadBigger(player)
	local username = getElementData(player, "account:username")
	if exclusiveUsernames[username] then
		return true
	end
	return isModFullPerm(player)
end

GCUploadPrice = 50 -- for 1 mod upload after the 3 free uploads
GCUploadPrice_Bigger = 100 -- IF the mod is over you will be taxed X gcs more


function isModReviewer(player)
	-- return false
	return exports.integration:isPlayerTrialAdmin(player) or exports.integration:isPlayerSupporter(player) or exports.integration:isPlayerScripter(player)
end

function isModFullPerm(player)
	-- return false
	return exports.integration:isPlayerSeniorAdmin(player) or exports.integration:isPlayerScripter(player)
end

function formatModPurpose(pr)
	local nicePurpose
	local pr = tonumber(pr)
	if pr == 1 then
		nicePurpose = "Personal"
	elseif pr < 0 then
		nicePurpose = "Faction #"..math.abs(pr)
	elseif pr == 0 then
		nicePurpose = "Public"
	elseif pr == 2 then
		nicePurpose = "Server"
	else
		nicePurpose = "Unknown"
	end
	return nicePurpose
end

function formatModType(modType)
	local niceModType
	if modType == "ped" then
		niceModType = "Skin"
	elseif modType == "vehicle" then
		niceModType = "Vehicle"
	elseif modType == "weapon" then
		niceModType = "Weapon"
	else
		niceModType = "Unknown"
	end
	return niceModType
end

-- No longer needed as I've removed the autism of calling "ped" mods "skin" mods instead.
function reverseFormatModType(modType)
	modType = string.lower(modType)
	local technicalModType = modType
	if modType == "skin" then
		technicalModType = "ped"
	end
	return technicalModType
end

function formatGender(gender)
	if tonumber(gender) == 0 then
		return "Male"
	end
	return "Female"
end

function formatRace(race)
	if tonumber(race) == 0 then
		return "Black"
	elseif tonumber(race) == 1 then
		return "White"
	end
	return "Asian"
end

function GetFileExtension(url)
  return url:match("^.+(%..+)$")
end


-- to iterate in order :)
function pairsByKeys (t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
	  i = i + 1
	  if a[i] == nil then return nil
	  else return a[i], t[a[i]]
	  end
	end
	return iter
end

normalSkins = {1, 2, 7, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 32, 33, 34, 35, 36, 37, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 57, 58, 59, 60, 61, 62, 66, 67, 68, 70, 71, 72, 73, 78, 79, 80, 81, 82, 83, 84, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 120, 121, 122, 123, 124, 125, 126, 127, 128, 132, 133, 134, 135, 136, 137, 142, 143, 144, 146, 147, 153, 154, 155, 156, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 170, 171, 173, 174, 175, 176, 177, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 200, 202, 203, 204, 206, 209, 210, 212, 213, 217, 220, 221, 222, 223, 227, 228, 229, 230, 234, 235, 236, 239, 240, 241, 242, 247, 248, 249, 250, 252, 253, 254, 255, 258, 259, 260, 261, 262, 264, 265, 266, 267, 268, 269, 270, 271, 272, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 290, 291, 292, 293, 294, 295, 296, 297, 299, 300, 301, 302, 303, 305, 306, 307, 308, 309, 310, 311, 312, 9, 10, 11, 12, 13, 31, 38, 39, 40, 41, 53, 54, 55, 56, 63, 64, 69, 75, 76, 77, 85, 87, 88, 89, 90, 91, 92, 93, 129, 130, 131, 138, 139, 140, 141, 145, 148, 150, 151, 152, 157, 169, 172, 178, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 201, 205, 207, 211, 214, 215, 216, 218, 219, 224, 225, 226, 231, 232, 233, 237, 238, 243, 244, 245, 246, 251, 256, 257, 263, 298, 304}

function table.size(tab)
    local length = 0
    for _ in pairs(tab) do length = length + 1 end
    return length
end