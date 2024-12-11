 --[[

    SA-RP Modloader
    by Fernando

    File: global.lua

]]

debugMode = false

title = "SA-RP Mod Loader (v2.0) - By Fernando"

settingsFile = "mods/_Settings.xml"

tutURL = "https://forums.sa-roleplay.net/topic/1016-sa-rp-mod-loader/?tab=comments#comment-5943"
uploadTutURL = "https://forums.sa-roleplay.net/topic/1115-sa-rp-new-skin-mods-unique-ids/?tab=comments#comment-6512"
premiumURL = "sa-roleplay.net/mta/premium"

readMeName = "READ-ME.txt"
readMeContent = "** SA-RP Mod Loader**\n\nMade by Fernando.\n\nDocumentation: "..tutURL


uploadReadMeName = "upload/READ-ME.txt"
uploadReadMeContent = "** SA-RP Mod Loader**\n\nMade by Fernando.\n\nUpload (submit) your mods to the server onto new Unique IDs!\n\nDocumentation: "..uploadTutURL

ModLogsName = "mods/_Logs.txt"
ModLogsContent = "««« SARP MOD LOADER »»»\n> Client Logs <\n"

helpMsg = "To understand how the SA-RP Mod Loader works, read about it on the Forums under 'Guides & Showcases'."
uploadHelpMsg = "Visit our Tutorial on this forum thread that explains how to use the Upload functionality."

-- see validateModAvailability
uploadTypes = {
    [1] = {
        desc = "Personal - First 3 uploads are free; Only obtainable by you",
        allowedTypes = {"ped"},
        perm = "player",
    },
    [2] = {
        desc = "Faction - Limited by the amount of skin slots your faction has; Only obtainable by faction members",
        allowedTypes = {"ped"},
        perm = "player",
    },
    [3] = {
        desc = "Public - Always free and infinite uploads; Allows you to globally distribute your mod on the server",
        allowedTypes = {"ped"},
        perm = "player",
    },
    [4] = {
        desc = "Special - Reserved for server/script use only",
        allowedTypes = {"vehicle", "ped"},
        perm = "staff",
    },
}

function table.size(tab)
    local length = 0
    for _ in pairs(tab) do length = length + 1 end
    return length
end


function xmlHasIllegalCharacters(text)
    -- https://stackoverflow.com/questions/1091945/what-characters-do-i-need-to-escape-in-xml-documents
    for k, char in pairs({'"',"'", "<",">", "&"}) do
        if string.find(text, char) then
            return true
        end
    end
    return false
end
function urlHasIllegalCharacters(text)
    for k, char in pairs({'>','<','-','!','"', '\\', '`', '´', "'"}) do
        if string.find(text, char) then
            return true
        end
    end
    return false
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

-- Model, DFF/TXD Name
weaponMods = {
    {331, "brassknuckle"},
    {333, "golfclub"},
    {334, "nitestick"},
    {335, "knifecur"},
    {336, "bat"},
    {337, "shovel"},
    {338, "poolcue"},
    {339, "katana"},
    {341, "chnsaw"},

    {346, "colt45"},
    {347, "silenced"},
    {348, "desert_eagle"},
    {349, "chromegun"},
    {350, "sawnoff"},
    {351, "shotgspa"},
    {352, "micro_uzi"},
    {353, "mp5lng"},
    {372, "tec9"},
    {355, "ak47"},
    {356, "m4"},

    {357, "cuntgun"},
    {358, "sniper"},
    {359, "rocketla"},
    {360, "heatseek"},
    {361, "flame"},
    {362, "minigun"},

    {342, "grenade"},
    {343, "teargas"},
    {344, "molotov"},
    {363, "satchel"},
    {365, "spraycan"},
    {366, "fire_ex"},
    {367, "camera"},

    {321, "gun_dildo1"},
    {322, "gun_dildo2"},
    {323, "gun_vibe1"},

    {325, "flowera"},
    {326, "gun_cane"},
    {368, "nvgoggles"},
    {369, "irgoggles"},
    {371, "gun_para"},
    {364, "bomb"},

    -- other
    {324, "gun_vibe2"},
    {1672, "Gasgrenade"},
    {2035, "CJ_M16"},
    {2036, "CJ_psg1"},
    {1654, "dynamite"},
    {1242, "bodyarmour"},
    {370, "jetpack"},
    {345, "missile"},
}


-- Model, DFF/TXD Name
skinMods = {
    {1, "truth"},
    {2, "maccer"},
    {7, "male01"},
    {9, "bfori"},
    {10, "bfost"},
    {11, "vbfycrp"},
    {12, "bfyri"},
    {13, "bfyst"},
    {14, "bmori"},
    {15, "bmost"},
    {16, "bmyap"},
    {17, "bmybu"},
    {18, "bmybe"},
    {19, "bmydj"},
    {20, "bmyri"},
    {21, "bmycr"},
    {22, "bmyst"},
    {23, "wmybmx"},
    {24, "wbdyg1"},
    {25, "wbdyg2"},
    {26, "wmybp"},
    {27, "wmycon"},
    {28, "bmydrug"},
    {29, "wmydrug"},
    {30, "hmydrug"},
    {31, "dwfolc"},
    {32, "dwmolc1"},
    {33, "dwmolc2"},
    {34, "dwmylc1"},
    {35, "hmogar"},
    {36, "wmygol1"},
    {37, "wmygol2"},
    {38, "hfori"},
    {39, "hfost"},
    {40, "hfyri"},
    {41, "hfyst"},
    {43, "hmori"},
    {44, "hmost"},
    {45, "hmybe"},
    {46, "hmyri"},
    {47, "hmycr"},
    {48, "hmyst"},
    {49, "omokung"},
    {50, "wmymech"},
    {51, "bmymoun"},
    {52, "wmymoun"},
    {53, "ofori"},
    {54, "ofost"},
    {55, "ofyri"},
    {56, "ofyst"},
    {57, "omori"},
    {58, "omost"},
    {59, "omyri"},
    {60, "omyst"},
    {61, "wmyplt"},
    {62, "wmopj"},
    {63, "bfypro"},
    {64, "hfypro"},
    {66, "bmypol1"},
    {67, "bmypol2"},
    {68, "wmoprea"},
    {69, "sbfyst"},
    {70, "wmosci"},
    {71, "wmysgrd"},
    {72, "swmyhp1"},
    {73, "swmyhp2"},
    {75, "swfopro"},
    {76, "wfystew"},
    {77, "swmotr1"},
    {78, "wmotr1"},
    {79, "bmotr1"},
    {80, "vbmybox"},
    {81, "vwmybox"},
    {82, "vhmyelv"},
    {83, "vbmyelv"},
    {84, "vimyelv"},
    {85, "vwfypro"},
    {87, "vwfyst1"},
    {88, "wfori"},
    {89, "wfost"},
    {90, "wfyjg"},
    {91, "wfyri"},
    {92, "wfyro"},
    {93, "wfyst"},
    {94, "wmori"},
    {95, "wmost"},
    {96, "wmyjg"},
    {97, "wmylg"},
    {98, "wmyri"},
    {99, "wmyro"},
    {100, "wmycr"},
    {101, "wmyst"},
    {102, "ballas1"},
    {103, "ballas2"},
    {104, "ballas3"},
    {105, "fam1"},
    {106, "fam2"},
    {107, "fam3"},
    {108, "lsv1"},
    {109, "lsv2"},
    {110, "lsv3"},
    {111, "maffa"},
    {112, "maffb"},
    {113, "mafboss"},
    {114, "vla1"},
    {115, "vla2"},
    {116, "vla3"},
    {117, "triada"},
    {118, "triadb"},
    {120, "triboss"},
    {121, "dnb1"},
    {122, "dnb2"},
    {123, "dnb3"},
    {124, "vmaff1"},
    {125, "vmaff2"},
    {126, "vmaff3"},
    {127, "vmaff4"},
    {128, "dnmylc"},
    {129, "dnfolc1"},
    {130, "dnfolc2"},
    {131, "dnfylc"},
    {132, "dnmolc1"},
    {133, "dnmolc2"},
    {134, "sbmotr2"},
    {135, "swmotr2"},
    {136, "sbmytr3"},
    {137, "swmotr3"},
    {138, "wfybe"},
    {139, "bfybe"},
    {140, "hfybe"},
    {141, "sofybu"},
    {142, "sbmyst"},
    {143, "sbmycr"},
    {144, "bmycg"},
    {145, "wfycrk"},
    {146, "hmycm"},
    {147, "wmybu"},
    {148, "bfybu"},
    {150, "wfybu"},
    {151, "dwfylc1"},
    {152, "wfypro"},
    {153, "wmyconb"},
    {154, "wmybe"},
    {155, "wmypizz"},
    {156, "bmobar"},
    {157, "cwfyhb"},
    {158, "cwmofr"},
    {159, "cwmohb1"},
    {160, "cwmohb2"},
    {161, "cwmyfr"},
    {162, "cwmyhb1"},
    {163, "bmyboun"},
    {164, "wmyboun"},
    {165, "wmomib"},
    {166, "bmymib"},
    {167, "wmybell"},
    {168, "bmochil"},
    {169, "sofyri"},
    {170, "somyst"},
    {171, "vwmybjd"},
    {172, "vwfycrp"},
    {173, "sfr1"},
    {174, "sfr2"},
    {175, "sfr3"},
    {176, "bmybar"},
    {177, "wmybar"},
    {178, "wfysex"},
    {179, "wmyammo"},
    {180, "bmytatt"},
    {181, "vwmycr"},
    {182, "vbmocd"},
    {183, "vbmycr"},
    {184, "vhmycr"},
    {185, "sbmyri"},
    {186, "somyri"},
    {187, "somybu"},
    {188, "swmyst"},
    {189, "wmyva"},
    {190, "copgrl3"},
    {191, "gungrl3"},
    {192, "mecgrl3"},
    {193, "nurgrl3"},
    {194, "crogrl3"},
    {195, "gangrl3"},
    {196, "cwfofr"},
    {197, "cwfohb"},
    {198, "cwfyfr1"},
    {199, "cwfyfr2"},
    {200, "cwmyhb2"},
    {201, "dwfylc2"},
    {202, "dwmylc2"},
    {203, "omykara"},
    {204, "wmykara"},
    {205, "wfyburg"},
    {206, "vwmycd"},
    {207, "vhfypro"},
    {209, "omonood"},
    {210, "omoboat"},
    {211, "wfyclot"},
    {212, "vwmotr1"},
    {213, "vwmotr2"},
    {214, "vwfywai"},
    {215, "sbfori"},
    {216, "swfyri"},
    {217, "wmyclot"},
    {218, "sbfost"},
    {219, "sbfyri"},
    {220, "sbmocd"},
    {221, "sbmori"},
    {222, "sbmost"},
    {223, "shmycr"},
    {224, "sofori"},
    {225, "sofost"},
    {226, "sofyst"},
    {227, "somobu"},
    {228, "somori"},
    {229, "somost"},
    {230, "swmotr5"},
    {231, "swfori"},
    {232, "swfost"},
    {233, "swfyst"},
    {234, "swmocd"},
    {235, "swmori"},
    {236, "swmost"},
    {237, "shfypro"},
    {238, "sbfypro"},
    {239, "swmotr4"},
    {240, "swmyri"},
    {241, "smyst"},
    {242, "smyst2"},
    {243, "sfypro"},
    {244, "vbfyst2"},
    {245, "vbfypro"},
    {246, "vhfyst3"},
    {247, "bikera"},
    {248, "bikerb"},
    {249, "bmypimp"},
    {250, "swmycr"},
    {251, "wfylg"},
    {252, "wmyva2"},
    {253, "bmosec"},
    {254, "bikdrug"},
    {255, "wmych"},
    {256, "sbfystr"},
    {257, "swfystr"},
    {258, "heck1"},
    {259, "heck2"},
    {260, "bmycon"},
    {261, "wmycd1"},
    {262, "bmocd"},
    {263, "vwfywa2"},
    {264, "wmoice"},
    {265, "tenpen"},
    {266, "pulaski"},
    {267, "hern"},
    {268, "dwayne"},
    {269, "smoke"},
    {270, "sweet"},
    {271, "ryder"},
    {272, "forelli"},
    {274, "laemt1"},
    {275, "lvemt1"},
    {276, "sfemt1"},
    {277, "lafd1"},
    {278, "lvfd1"},
    {279, "sffd1"},
    {280, "lapd1"},
    {281, "sfpd1"},
    {282, "lvpd1"},
    {283, "csher"},
    {284, "lapdm1"},
    {285, "swat"},
    {286, "fbi"},
    {287, "army"},
    {288, "dsher"},
    {290, "rose"},
    {291, "paul"},
    {292, "cesar"},
    {293, "ogloc"},
    {294, "wuzimu"},
    {295, "torino"},
    {296, "jizzy"},
    {297, "maddogg"},
    {298, "cat"},
    {299, "claude"},
    {300, "ryder2"},
    {301, "ryder3"},
    {302, "emmet"},
    {303, "andre"},
    {304, "kendl"},
    {305, "jethro"},
    {306, "zero"},
    {307, "tbone"},
    {308, "sindaco"},
    {309, "janitor"},
    {310, "bbthin"},
    {311, "smokev"},
    {312, "psycho"},
}
-- Model, DFF/TXD Name
vehicleMods = {
    {400, "landstal"},
    {542, "clover"},
    {445, "admiral"},
    {602, "alpha"},
    {416, "ambulan"},
    {592, "androm"},
    {435, "artict1"},
    {450, "artict2"},
    {591, "artict3"},
    {577, "at400"},
    {606, "bagboxa"},
    {607, "bagboxb"},
    {585, "baggage"},
    {568, "bandito"},
    {429, "banshee"},
    {433, "barracks"},
    {511, "beagle"},
    {499, "benson"},
    {459, "topfun"},
    {424, "bfinject"},
    {581, "bf400"},
    {509, "bike"},
    {536, "blade"},
    {496, "blistac"},
    {504, "bloodra"},
    {481, "bmx"},
    {422, "bobcat"},
    {498, "boxville"},
    {609, "boxburg"},
    {401, "bravura"},
    {575, "broadway"},
    {538, "streak"},
    {570, "streakc"},
    {518, "buccanee"},
    {402, "buffalo"},
    {541, "bullet"},
    {482, "burrito"},
    {431, "bus"},
    {438, "cabbie"},
    {457, "caddy"},
    {527, "cadrona"},
    {483, "camper"},
    {548, "cargobob"},
    {524, "cement"},
    {415, "cheetah"},
    {589, "club"},
    {437, "coach"},
    {472, "coastg"},
    {532, "combine"},
    {480, "comet"},
    {512, "cropdust"},
    {578, "dft30"},
    {473, "dinghy"},
    {593, "dodo"},
    {486, "dozer"},
    {406, "dumper"},
    {573, "duneride"},
    {507, "elegant"},
    {562, "elegy"},
    {585, "emperor"},
    {427, "enforcer"},
    {419, "esperant"},
    {587, "euros"},
    {462, "faggio"},
    {610, "farmtr1"},
    {491, "fbiranch"},
    {528, "fbitruck"},
    {521, "fcr900"},
    {533, "feltzer"},
    {407, "firetruk"},
    {544, "firela"},
    {565, "flash"},
    {455, "flatbed"},
    {530, "forklift"},
    {526, "fortune"},
    {590, "freibox"},
    {463, "freeway"},
    {537, "freight"},
    {569, "freiflat"},
    {466, "glendale"},
    {604, "glenshit"},
    {492, "greenwoo"},
    {474, "hermes"},
    {588, "hotdog"},
    {434, "hotknife"},
    {494, "hotring"},
    {502, "hotrina"},
    {503, "hotrinb"},
    {523, "copbike"},
    {425, "hunter"},
    {579, "huntley"},
    {545, "hustler"},
    {520, "hydra"},
    {411, "infernus"},
    {546, "intruder"},
    {559, "jester"},
    {493, "jetmax"},
    {508, "journey"},
    {571, "kart"},
    {595, "launch"},
    {417, "leviathn"},
    {403, "linerun"},
    {517, "majestic"},
    {410, "manana"},
    {484, "marquis"},
    {487, "maverick"},
    {551, "merit"},
    {500, "mesa"},
    {444, "monster"},
    {556, "monstera"},
    {557, "monsterb"},
    {418, "moonbeam"},
    {510, "mtbike"},
    {572, "mower"},
    {423, "mrwhoop"},
    {414, "mule"},
    {516, "nebula"},
    {553, "nevada"},
    {488, "vcmav"},
    {582, "newsvan"},
    {522, "nrg500"},
    {467, "oceanic"},
    {443, "packer"},
    {470, "patriot"},
    {461, "pcj600"},
    {404, "peren"},
    {584, "petrotr"},
    {603, "phoenix"},
    {600, "picador"},
    {448, "pizzaboy"},
    {596, "copcarla"},
    {597, "copcarsf"},
    {598, "copcarlv"},
    {497, "polmav"},
    {413, "pony"},
    {430, "predator"},
    {426, "premier"},
    {436, "previon"},
    {547, "primo"},
    {471, "quad"},
    {563, "raindanc"},
    {489, "rancher"},
    {505, "rnchlure"},
    {599, "copcarru"},
    {441, "rcbandit"},
    {464, "rcbaron"},
    {594, "rccam"},
    {501, "rcgoblin"},
    {465, "rcraider"},
    {564, "rctiger"},
    {453, "reefer"},
    {479, "regina"},
    {534, "remingtn"},
    {432, "rhino"},
    {515, "rdtrain"},
    {442, "romero"},
    {440, "rumpo"},
    {476, "rustler"},
    {601, "swatvan"},
    {475, "sabre"},
    {543, "sadler"},
    {605, "sadlshit"},
    {468, "sanchez"},
    {495, "sandking"},
    {567, "savanna"},
    {447, "seaspar"},
    {428, "securica"},
    {405, "sentinel"},
    {519, "shamal"},
    {460, "skimmer"},
    {535, "slamvan"},
    {458, "solair"},
    {469, "sparrow"},
    {452, "speeder"},
    {446, "squalo"},
    {580, "stafford"},
    {439, "stallion"},
    {561, "stratum"},
    {409, "stretch"},
    {513, "stunt"},
    {560, "sultan"},
    {550, "sunrise"},
    {506, "supergt"},
    {574, "sweeper"},
    {566, "tahoma"},
    {549, "tampa"},
    {514, "petro"},
    {420, "taxi"},
    {576, "tornado"},
    {525, "towtruck"},
    {531, "tractor"},
    {449, "tram"},
    {408, "trash"},
    {454, "tropic"},
    {583, "tug"},
    {608, "tugstair"},
    {451, "turismo"},
    {558, "uranus"},
    {552, "utility"},
    {611, "utiltr1"},
    {540, "vincent"},
    {491, "virgo"},
    {412, "voodoo"},
    {539, "vortex"},
    {478, "walton"},
    {421, "washing"},
    {586, "wayfarer"},
    {529, "willard"},
    {555, "windsor"},
    {456, "yankee"},
    {554, "yosemite"},
    {477, "zr350"},
}

function table.compare( a1, a2 )
    if
        type( a1 ) == 'table' and
        type( a2 ) == 'table'
    then

        local function size( t )
            if type( t ) ~= 'table' then
                return false
            end
            local n = 0
            for _ in pairs( t ) do
                n = n + 1
            end
            return n
        end

        if size( a1 ) == 0 and size( a2 ) == 0 then
            return true
        elseif size( a1 ) ~= size( a2 ) then
            return false
        end

        for _, v in pairs( a1 ) do
            local v2 = a2[ _ ]
            if type( v ) == type( v2 ) then
                if type( v ) == 'table' and type( v2 ) == 'table' then
                    if size( v ) ~= size( v2 ) then
                        return false
                    end
                    if size( v ) > 0 and size( v2 ) > 0 then
                        if not table.compare( v, v2 ) then
                            return false
                        end
                    end
                elseif
                    type( v ) == 'string' or type( v ) == 'number' and
                    type( v2 ) == 'string' or type( v2 ) == 'number'
                then
                    if v ~= v2 then
                        return false
                    end
                else
                    return false
                end
            else
                return false
            end
        end
        return true
    end
    return false
end
