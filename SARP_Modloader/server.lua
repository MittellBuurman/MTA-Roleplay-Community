 --[[

    SA-RP Modloader
    by Fernando

    File: server.lua

]]

mysql = exports.mysql

-- makes a log of the mods loaded by the player at that moment if they are unchanged from the previous log.
function makeModLog(player, loadedMods)

	if not isElement(player) or getElementType(player)~="player" then
		return false, "invalid player"
	end

	local acc = getElementData(player, "account:id")

	-- get latest mod log of player
	local lastLog = nil

	local qh1 = dbQuery(mysql:getConn("mta"), "SELECT * FROM modlogs WHERE acc=? ORDER BY id DESC", tonumber(acc))
	local result1, num_affected_rows1 = dbPoll ( qh1, 10000 )
	if result1 and num_affected_rows1 > 0 then

	    for _, row in pairs(result1) do
	        lastLog = {id = row.id, acc = row.acc, timestamp = row.timestamp, mods_loaded = row.mods_loaded, note = row.note}
	        break
	    end
	end
	dbFree(qh1)

	if lastLog then
		-- found one last log

		local mods = fromJSON(lastLog.mods_loaded)

		if compareMods(loadedMods, mods) then
			return false, "same mods found"
		else
			local mods = toJSON(loadedMods)
			local note = "New mods loaded"
			if dbExec(mysql:getConn('mta'), "INSERT INTO modlogs SET acc=?, timestamp=?, mods_loaded=?, note=?", acc, getRealTime().timestamp, mods, note) then
				return true, "added new mod log"
			end
		end
	else
		local mods = toJSON(loadedMods)
		local note = "First mod log ever"
		if dbExec(mysql:getConn('mta'), "INSERT INTO modlogs SET acc=?, timestamp=?, mods_loaded=?, note=?", acc, getRealTime().timestamp, mods, note) then
			return true, "added 1st mod log"
		end
	end

	return false, "db error"
end

function tryMakeServerLog(loadedMods)

	local result, msg = makeModLog(client, loadedMods)
	if debugMode then
		outputDebugString("ML: "..(result and "Log added" or "No log").." - "..msg)
	end
end
addEvent("ML:makeServerLog", true)
addEventHandler("ML:makeServerLog", root, tryMakeServerLog)

function compareMods(mods1, mods2)

	if debugMode then
		iprint(mods1)
		iprint(mods2)
	end

	return table.compare(mods1, mods2)
end


local MLUnderMaintenance = false

function setUnderMaintenance(thePlayer)
	if not exports.integration:isPlayerScripter(thePlayer) then return end
	MLUnderMaintenance = not MLUnderMaintenance
	print("modloader maintenance: "..tostring(MLUnderMaintenance))
end
addCommandHandler("mlm", setUnderMaintenance, false,false)

function requestOpenGUI()

	if MLUnderMaintenance and not exports.integration:isPlayerLeadAdmin(client) then
		return outputChatBox("The modloader is under maintenance. Sorry for the inconvenience!", client,255,100,100)
	end

    -- refer to sarp-new-mods s_newmods.lua
    local myUploads = exports["sarp-new-mods"]:getModUploads(getElementData(client, "account:id"))

    local allUploads = false
    if exports["sarp-new-mods"]:isModReviewer(client) then
    	allUploads = exports["sarp-new-mods"]:getModUploads()
    end

    triggerClientEvent(client, "modloader:openGUI", client, myUploads, allUploads)
end
addEvent("modloader:requestOpenGUI", true)
addEventHandler("modloader:requestOpenGUI", root, requestOpenGUI)
