-------------------------------- Fernando --------------------------------

-- Change this if you want EVERYTHING to be re-cached
uniqueCacheString = "32VTMU8E"

local cacheFolder = "sarp_cache/"
local fileExt = ".sarp"

cacheFileNameServer = cacheFolder.."%s"..uniqueCacheString..fileExt
cacheFileName = "@"..cacheFolder.."%s"..uniqueCacheString..fileExt

listFilePath = "@"..cacheFolder.."file_list.xml"
rootNodeName, entryNodeName = "list", "file"


max_collection_items = 200

normalSkins = {1, 2, 7, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 32, 33, 34, 35, 36, 37, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 57, 58, 59, 60, 61, 62, 66, 67, 68, 70, 71, 72, 73, 78, 79, 80, 81, 82, 83, 84, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 120, 121, 122, 123, 124, 125, 126, 127, 128, 132, 133, 134, 135, 136, 137, 142, 143, 144, 146, 147, 153, 154, 155, 156, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 170, 171, 173, 174, 175, 176, 177, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 200, 202, 203, 204, 206, 209, 210, 212, 213, 217, 220, 221, 222, 223, 227, 228, 229, 230, 234, 235, 236, 239, 240, 241, 242, 247, 248, 249, 250, 252, 253, 254, 255, 258, 259, 260, 261, 262, 264, 265, 266, 267, 268, 269, 270, 271, 272, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 290, 291, 292, 293, 294, 295, 296, 297, 299, 300, 301, 302, 303, 305, 306, 307, 308, 309, 310, 311, 312, 9, 10, 11, 12, 13, 31, 38, 39, 40, 41, 53, 54, 55, 56, 63, 64, 69, 75, 76, 77, 85, 87, 88, 89, 90, 91, 92, 93, 129, 130, 131, 138, 139, 140, 141, 145, 148, 150, 151, 152, 157, 169, 172, 178, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 201, 205, 207, 211, 214, 215, 216, 218, 219, 224, 225, 226, 231, 232, 233, 237, 238, 243, 244, 245, 246, 251, 256, 257, 263, 298, 304}
table.sort(normalSkins)

obtainCost = 100 -- dollars
defaultSkinCost = 50 -- dollars

function isModerator(player)
	return exports.integration:isPlayerScripter(player)
end

function getSkinSlots(player)
	return tonumber( getElementData(player, "account:skinslots") or 5 )
end

function sortList(list)
	local newList = {}
	for k, v in pairs(list) do
		v.id = tonumber(v.id)
		v.skin = tonumber(v.skin)
		v.price = tonumber(v.price)

		table.insert(newList, v)
	end

	table.sort(newList,
		function(a, b)
			if a.skin == b.skin then
				if a.id == 0 then
					return false
				else
					return a.description < b.description
				end
			else
				return a.skin < b.skin
			end
		end)
	return newList
end

function getSkinBasicInfo(id)
	local gender, race, restricted
	for gender_, categories in pairs(exports["shop-system"]:getFittingSkins()) do
		for race_, cate in pairs(categories) do
			for _, skin_id in pairs(cate) do
				if skin_id == id then
					gender = gender_
					race = race_
					restricted = exports["shop-system"]:getRestrictedSkins()[id]
					break
				end
			end
		end
	end

	if gender and race then
		return (race == 0 and 'Black' or (race == 1 and 'White' or 'Asian'))..' '..(gender == 0 and 'male' or 'female')..(restricted and ' (Restricted)' or ''), gender, race, restricted
	end
	local moddedSkins = getElementData(getRootElement(), "moddedSkins")
	for i, skin in pairs(moddedSkins) do

		local skinid = skin.modelid
		if skinid == id then
			return skin
		end
	end

	return ''
end

function getInteriorOwner(player)
	local dbid, theEntrance, theExit, interiorType, interiorElement = exports["interior_system"]:findProperty(player)
	local stt = getElementData(interiorElement, "status")
	for key, value in ipairs(getElementsByType("player")) do
		local id = getElementData(value, "dbid")
		if (id==stt.owner) then
			return stt.owner, value
		end
	end
	return stt.owner, nil -- no player found
end

function getPlayerName(player)
	return exports.global:getPlayerName(player)
end

function getGtaDesigners()
	local designers = {"ARSS", "Base 5", "Binco", "Bobo", "Bobo Dodger Boutique", "Didier Sachs", "Eris", "Exotic Boutique", "Gnocchi", "Heat", "Kevin Clone", "Little Lady",
	"Los Santos Fashions", "Mercury", "Monsiuer Trousers", "Phat Clothing", "ProLaps", "Princess P Fashions", "Ranch", "RRSS", "SEMI", "Soap Dodger Boutique", "Son of a Beach",
	"Sub Urban", "Victim", "Vulgari", "Zapateria", "Zip"}
	return designers[math.random(1,#designers)]
end

function getStatus(clothes)
	if clothes.distribution == 0 then
		return "Hidden"
	elseif clothes.distribution == 1 then
		return "Draft (Private)"
	elseif clothes.distribution == 2 then
		if clothes.mdate and clothes.mdate > 0 and clothes.mdate > exports.datetime:now() then
			return 'Arriving in '..exports.datetime:formatFutureTimeInterval(clothes.mdate)
		else
			return "Personal (Private)"
		end
	elseif clothes.distribution == 3 then
		return "Public"
	elseif clothes.distribution == 4 then
		if clothes.for_sale_until > exports.datetime:now() then
			return "Distributed globally for "..exports.datetime:formatFutureTimeInterval(clothes.for_sale_until)
		else
			return "Distribution expired "..exports.datetime:formatTimeInterval(clothes.for_sale_until).." (Private)"
		end
	elseif clothes.distribution == 5 then
		return "Faction Uniform"
	else
		return "Archived"
	end
end

function isDeletable(clothes)
	return clothes.distribution == 1 or clothes.distribution == 5
end

function canEditPrice(clothes)
	return clothes.distribution ~=3
end

function canEditModel(clothes)
	return clothes.distribution == 1
end

function isForSale(clothes)
	return clothes.distribution == 3 or (clothes.distribution == 4 and clothes.for_sale_until > exports.datetime:now())
end

function canDistribute(clothes)
	if clothes.distribution == 0 then
		return false
	elseif clothes.distribution == 1 then
		return true
	elseif clothes.distribution == 2 then
		return not (clothes.mdate and clothes.mdate>0 and clothes.mdate > exports.datetime:now())
	end
	return false
end

function formatManuDate(clothes)
	if clothes.fmdate then
		return clothes.fmdate
	elseif clothes.mdate and clothes.mdate > 0 then
		return clothes.mdate > exports.datetime:now() and ('Arriving in '..exports.datetime:formatFutureTimeInterval(clothes.mdate)) or exports.datetime:formatTimeInterval(clothes.mdate)
	end
	return 'Never'
end

function canUploadForFaction(player)
	local fid = exports["faction-system"]:getCurrentFactionDuty(player)
	if fid then
		local faction = exports["faction-system"]:getFactionFromID( fid )
		-- if faction and getElementData( faction, 'permissions' ).free_custom_skins == 1 and exports["faction-system"]:isPlayerFactionLeader( player, fid ) then
		if faction and exports["faction-system"]:isPlayerFactionLeader( player, fid ) then
			return fid
		end
	end
	return false
end


function table.size(tab)
    local length = 0
    for _ in pairs(tab) do length = length + 1 end
    return length
end
