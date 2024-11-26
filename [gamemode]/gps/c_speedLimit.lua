addCommandHandler("speednode",
	function()
		if exports.integration:isPlayerScripter(getLocalPlayer()) then
			outputChatBox(findNodeClosestToPoint(vehicleNodes, getElementPosition(getLocalPlayer())).id)
		end
	end
)

local speedlimits90 =
{
	-- node1, node2
	{ 786819, 1311230 },
	{ 786747, 852334 },
	{ 786741, 852258 },
	{ 786817, 786715 },
	{ 1311150, 786827 },
	{ 786827, 786818 },
	{ 786716, 1507768 },
	{ 786827, 1507768 },
	{ 1311487, 786623 },
	{ 786823, 1311512 },
	{ 786822, 1311513 },
	{ 786546, 786600 },
	{ 786600, 1376576 },
	{ 1376576, 1442183 },
	{ 786542, 786897 },
	{ 786897, 1376522 },
	{ 1376522, 1311054 },
	{ 1311054, 1376526 },
	{ 1376526, 1442183 },
	{ 1311514, 1376278 },
	{ 1376362, 1442123 },
	{ 1442123, 1441994 },
	{ 1441994, 1442260 },
	{ 1442123, 918080 },
	{ 1507456, 1507942 },
	{ 1507715, 1507708 },
	{ 1507862, 1507894 },
	{ 1507894, 983504 },
	{ 983495, 1507875 },
	{ 1507875, 1507864 },
	{ 983604, 983594 },
	{ 1442239, 1442238 },
	{ 983564, 983555 },
	{ 983531, 918022 },
	{ 983589, 983524 },
	{ 917953, 917954 },
	{ 917818, 917917 },
	{ 917917, 918079 },
	{ 918027, 918005 },
	{ 852267, 1376936 },
	{ 1376935, 852312 },
	{ 1441804, 1442490 },
	{ 1442490, 1376721 },
	{ 1442512, 1442509 },
	{ 1442566, 1442590 },
	{ 1441820, 1442335 },
	{ 1442464, 1441814 },
	{ 1442671, 1442650 },
	{ 1441802, 917569 },
	{ 917555, 917570 },
	{ 1441850, 1442298 },
	{ 1441847, 917554 },
	{ 327681, 852153 },
	{ 327821, 327818 },
	{ 327695, 327841 },
	{ 1376521, 1376589 },
	-- country road leading out of LS, near madd dogg's
	{ 1376948, 1835431 },
	
	{ 2162881, 2687039 }, 
	
	-- Flint county bridge to RS HAUL
	{ 786810, 1245343 },
	{ 1245343, 1245363 }, 
	{ 1245263, 1245397 },
	{ 1245397, 1179797 },
	
	-- Int.89 SF booth tunnel 
	{ 1179801, 1179811 },
	{ 1179811, 1179818 },
	{ 1179818, 1179821 },
	{ 1179794, 1179674 },
	{ 1179674, 1179690 },
	{ 1179690, 1114176 },
	{ 1114176, 1114196 }, 
	{ 1114196, 1114240 }, 
	{ 1114240, 1638445 },
	{ 1638461, 1179840 },
	{ 1704017, 1769562 },
	{ 1703936, 1704037 }, 
	{ 1704037, 1769495 },
	{ 1769495, 1703953 }, 
	{ 1703953, 2293797 }, 
	{ 2293797, 2228228 }, 
	{ 2228228, 2294049 },
	{ 2294049, 1769701 },
	{ 2294049, 2424856 },
	{ 1769701, 1835032 },
	{ 1835032, 1245363 },
	{ 1835014, 1835453 },
	{ 1311240, 1835463 },
	{ 1835463, 1835499 }, 
	{ 1835463, 2359586 },
	{ 2424856, 2490542 },
	{ 1245234, 720906 },
	{ 720906, 1245185 },
	{ 1245185, 655432 },
	{ 655432, 131100 },
	{ 131100, 131078 },
	{ 131078, 721006 },
	{ 721006, 721125 },
	{ 2359586, 2556009 },
	{ 2556302, 2556262 },
	{ 2556262, 2031763 },
	{ 2031763, 1507738 },
	{ 2555919, 2490663 },
	{ 2490663, 1966219 },
	{ 1966219, 1900793 },
	{ 1900551, 2424865 },
	{ 2424865, 2425264 },
	{ 1900860, 1900846 },
	{ 2490663, 1900550 },
	{ 1900550, 1376855 },
	{ 1900550, 1835383 },
	
	
	

	
}

local speedlimits120 = 
{
	{ 786747, 721310 },
	{ 786741, 721310 },
	{ 983594, 983587 },
	{ 983587, 918112 },
	{ 918112, 1441850 },
	{ 917570, 918007 },
	{ 918007, 918017 },
	{ 918017, 983564 },
	{ 852334, 327806 },
	{ 327795, 852258 },
	{ 1966173, 918098 },
	{ 918098, 917780 },
	{ 917780, 327843 },
	{ 327843, 393296 },
	{ 393296, 393510 },
	{ 393510, 983263 },
	{ 983263, 2031776 },
	
	{ 2031800, 983256 },
	{ 983256, 393249 },
	{ 393249, 327752 },
	{ 327752, 327814 },
	{ 327814, 918106 },
	{ 918106, 1442674 },
	{ 1442674, 1966167 },

	{ 918113, 918116 },
	-- highway leaving LS through the tunnel
	-- in LS , outside
	{ 1310734, 1245263 },
	{ 1310784, 1245284 },
	
	-- Flint County/LS Inlet highway
	{ 1638976, 1572897 }, -- SF to LS
	{ 1572897, 524322 },
	{ 524322, 94 },
	{ 94, 65661 }, 
	{ 65661, 131138 },
	{ 131138, 196720 },
	{ 196720, 1245284 },
	
	{ 1245270, 196691 }, -- To Angel Pine/SF and others
	{ 196691, 196676 },
	{ 196676, 196755 },
	{ 196755, 131112 },
	{ 131112, 131114 },
	{ 131114, 65645 },
	{ 65645, 4 },
	{ 4, 524289 },
	{ 524289, 524303 },
	{ 524303, 1048588 },
	{ 1048588, 1639029 },
	{ 2031776, 2555933 },
	{ 2555933, 2490426 },
	{ 2490426, 2490512 },
	{ 2490512, 2490546 --[[2490472 2556040]] },
	{ 2490546, 2556040 },
	{ 2556047, 2031801 },
	{ 3014978, 1966254 },
	{ 3014980, 1966181 },
}

addEventHandler('onClientResourceStart', resourceRoot, function ()
	for _, node in ipairs( speedlimits90 ) do
		local path = calculatePathByNodeIDs( node[1], node[2] )
		for key, value in ipairs(path) do
			value.speedlimit = 80
			--createBlip( value.x, value.y, value.z, 0, 1, 0, 255, 0 )
		end
	end

	for _, node in ipairs( speedlimits120 ) do
		local path = calculatePathByNodeIDs( node[1], node[2] )
		for key, value in ipairs(path) do
			value.speedlimit = 112
			--createBlip( value.x, value.y, value.z, 0, 1 )
		end
	end
end)

setTimer(
	function()
		local node = findNodeClosestToPoint( vehicleNodes, getElementPosition( localPlayer ) )
		local limit = node and node.speedlimit
		setElementData( getLocalPlayer(), "speedo:limit", limit or 48, false)
	end, 500, 0
)