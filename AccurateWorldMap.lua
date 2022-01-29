-- Hi, welcome to the code for AccurateWorldMap
-- Thanks to the esoui glitter community and the authors of Highly Detailed World Map, uespLog, GuildShrines and World Wayshrine Controller for me 
-- being able to figure out how to make this work

-- ascii title art done on https://texteditor.com/ascii-art/

-- define root addon object
local addon = {
	name = "AccurateWorldMap",
	title = "Accurate World Map",
	version = "1.0",
	author = "|CFF0000Breaux|r & |C6b51faThal-J|r",
}

-- Base tamriel map tiles
local tiles = {
    "Art/maps/tamriel/Tamriel_0.dds",
    "Art/maps/tamriel/Tamriel_1.dds",
    "Art/maps/tamriel/Tamriel_2.dds",
    "Art/maps/tamriel/Tamriel_3.dds",
    "Art/maps/tamriel/Tamriel_4.dds",
    "Art/maps/tamriel/Tamriel_5.dds",
    "Art/maps/tamriel/Tamriel_6.dds",
    "Art/maps/tamriel/Tamriel_7.dds",
    "Art/maps/tamriel/Tamriel_8.dds",
    "Art/maps/tamriel/Tamriel_9.dds",
    "Art/maps/tamriel/Tamriel_10.dds",
    "Art/maps/tamriel/Tamriel_11.dds",
    "Art/maps/tamriel/Tamriel_12.dds",
    "Art/maps/tamriel/Tamriel_13.dds",
    "Art/maps/tamriel/Tamriel_14.dds",
    "Art/maps/tamriel/Tamriel_15.dds",
}

-- defaults
local normalisedMouseX = 0
local normalisedMouseY = 0

local recordCoordinates = false

local mouseDownOnPolygon = false


local enabled = true
local debug = false
local UNITTAG_PLAYER = 'player' 
local debugOutput = false
local _GetMapTileTexture = GetMapTileTexture

local LAM = LibAddonMenu2
local saveData = {} -- TODO this should be a reference to your actual saved variables table
local panelName = "addonvar" -- TODO the name will be used to create a global variable, pick something unique or you may overwrite an existing variable!

local panelData = {
    type = "panel",
    name = "Accurate World Map",
    author = "Breaux & Thal-J",
}

local currentCoordinateCount = 0

local currentPolygon = nil
local polygonData = {}
local newPolygonData = {}

local mapDimensions = 4096 -- px


local hackyTable = {}

local function hackyJoin(extra)
    table.insert(hackyTable, extra)
    return hackyTable
end

local isInBlobHitbox = false
local currentlySelectedBlobName = ""
local currentZoneInfo = {}
local isExclusive = false


-- Data table of all the wayshrine nodes and zone blobs we want to modify or move, sorted by map (zone).
-- We use the zone's name as a base to get the correct zone texture (and later texture dimensions) to draw on the map

mapData = {

  [27] = { -- Tamriel World Map

    isExclusive = true,
        
    -- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
    -- ██░▄▄▄░██░█▀▄██░███░██░▄▄▀█▄░▄██░▄▀▄░██
    -- ██▄▄▄▀▀██░▄▀███▄▀▀▀▄██░▀▀▄██░███░█░█░██
    -- ██░▀▀▀░██░██░████░████░██░█▀░▀██░███░██
    -- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    -- [x] = { xN = x, yN = y }, -- 

    -- Bleakrock Isle --

    [172] = { xN = 0.613, yN = 0.236 }, -- Bleakrock Isle Wayshrine

    zoneData = hackyJoin({
      zoneName = "Bleakrock Isle",
      zoneID = 74,
      xN = "0.603",
      yN = "0.227",
      zonePolygonData = {
        { xN = 0.625, yN = 0.234 },
        { xN = 0.622, yN = 0.241 },
        { xN = 0.619, yN = 0.245 },
        { xN = 0.615, yN = 0.246 },
        { xN = 0.610, yN = 0.247 },
        { xN = 0.606, yN = 0.242 },
        { xN = 0.602, yN = 0.238 },
        { xN = 0.601, yN = 0.231 },
        { xN = 0.605, yN = 0.226 },
        { xN = 0.612, yN = 0.225 },
        { xN = 0.619, yN = 0.227 },
        { xN = 0.622, yN = 0.231 },
      }
    }),

    -- Eastmarch --

    [87] = { xN = 0.585, yN = 0.258 }, -- Windhelm Wayshrine
    [88] = { xN = 0.567, yN = 0.281 }, -- Fort Morvunskar Wayshrine
    [89] = { xN = 0.581, yN = 0.279 }, -- Kynesgrove Wayshrine
    [90] = { xN = 0.571, yN = 0.269 }, -- Voljar Meadery Wayshrine
    [91] = { xN = 0.544, yN = 0.284 }, -- Cradlecrush Wayshrine
    [92] = { xN = 0.544, yN = 0.308 }, -- Fort Amol Wayshrine
    [93] = { xN = 0.573, yN = 0.304 }, -- Wittestadr Wayshrine
    [94] = { xN = 0.583, yN = 0.323 }, -- Mistwatch Wayshrine
    [95] = { xN = 0.610, yN = 0.313 }, -- Jorunn's Stand Wayshrine
    [96] = { xN = 0.600, yN = 0.306 }, -- Logging Camp Wayshrine
    [97] = { xN = 0.614, yN = 0.297 }, -- Skuldafn Wayshrine
    [195] = { xN = 0.621, yN = 0.320 }, -- Direfrost Keep Dungeon
    [389] = { xN = 0.552, yN = 0.281 }, -- Frostvault Dungeon
    [312] = { xN = 0.590, yN = 0.258 }, -- Grymhearth's Woe House
    [392] = { xN = 0.550, yN = 0.282 }, -- Frostvault Chasm House

    zoneData = hackyJoin({
      zoneName = "Eastmarch",
      zoneID = 61,
      xN = "0.521",
      yN = "0.235",
      zonePolygonData = {
        { xN = 0.624, yN = 0.323 },
        { xN = 0.623, yN = 0.316 },
        { xN = 0.620, yN = 0.304 },
        { xN = 0.613, yN = 0.295 },
        { xN = 0.608, yN = 0.286 },
        { xN = 0.605, yN = 0.277 },
        { xN = 0.608, yN = 0.268 },
        { xN = 0.613, yN = 0.262 },
        { xN = 0.616, yN = 0.253 },
        { xN = 0.614, yN = 0.250 },
        { xN = 0.610, yN = 0.249 },
        { xN = 0.605, yN = 0.252 },
        { xN = 0.598, yN = 0.252 },
        { xN = 0.597, yN = 0.240 },
        { xN = 0.592, yN = 0.241 },
        { xN = 0.588, yN = 0.247 },
        { xN = 0.575, yN = 0.244 },
        { xN = 0.559, yN = 0.248 },
        { xN = 0.551, yN = 0.255 },
        { xN = 0.546, yN = 0.264 },
        { xN = 0.547, yN = 0.273 },
        { xN = 0.538, yN = 0.278 },
        { xN = 0.532, yN = 0.279 },
        { xN = 0.522, yN = 0.290 },
        { xN = 0.519, yN = 0.298 },
        { xN = 0.522, yN = 0.311 },
        { xN = 0.526, yN = 0.321 },
        { xN = 0.536, yN = 0.325 },
        { xN = 0.550, yN = 0.328 },
        { xN = 0.558, yN = 0.332 },
        { xN = 0.584, yN = 0.333 },
        { xN = 0.593, yN = 0.327 },
        { xN = 0.596, yN = 0.326 },
        { xN = 0.605, yN = 0.325 },
        { xN = 0.613, yN = 0.327 },
        { xN = 0.616, yN = 0.323 },
        { xN = 0.619, yN = 0.323 }
      }
    }),
    
    -- The Rift --
    [109] = { xN = 0.603, yN = 0.366 }, -- Riften Wayshrine
    [111] = { xN = 0.616, yN = 0.388 }, -- Trollhetta Wayshrine
    [112] = { xN = 0.615, yN = 0.399 }, -- Trollhetta Summit Wayshrine 
    [187] = { xN = 0.626, yN = 0.387 }, -- Blessed Crucible Dungeon
    [120] = { xN = 0.620, yN = 0.375 }, -- Fullhelm Fort Wayshrine
    [110] = { xN = 0.595, yN = 0.374 }, -- Skald's Retreat Wayshrine
    [113] = { xN = 0.568, yN = 0.372 }, -- Honrich Tower Wayshrine
    [119] = { xN = 0.549, yN = 0.363 }, -- Ragged Hills Wayshrine
    [118] = { xN = 0.541, yN = 0.353 }, -- Nimalten Wayshrine
    [117] = { xN = 0.531, yN = 0.355 }, -- Taarengrav Wayshrine
    [116] = { xN = 0.533, yN = 0.340 }, -- Geirmund's Hall Wayshrine 
    [114] = { xN = 0.592, yN = 0.345 }, -- Fallowstone Hall Wayshrine 
    [115] = { xN = 0.573, yN = 0.345 }, -- Northwind Mine Wayshrine 
    [322] = { xN = 0.608, yN = 0.370 }, -- Old Mistveil Manor House 
    [372] = { xN = 0.609, yN = 0.354 }, -- Hunter's Glade House 
    [301] = { xN = 0.556, yN = 0.341 }, -- Autumn's Gate House 

    -- Western Skyrim --
    [424] = { xN = 0.404, yN = 0.157 }, -- Icereach Dungeon
    [434] = { xN = 0.408, yN = 0.186 }, -- Kyne's Aegis Trial

    -- The Reach --
    [445] = { xN = 0.377, yN = 0.270 }, -- Karthwasten Wayshrine
    [221] = { xN = 0.337, yN = 0.275 }, -- The Earth Forge Wayshrine

    -- Falkreath Hold --
    [332] = { xN = 0.451, yN = 0.356 }, -- Falkreath Hold Dungeon 


    -- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
    -- ██░▄▄▀██░███░██░▄▄▀██░▄▄▄░██░▄▄▀█▄░▄█▄░▄██░█████
    -- ██░█████▄▀▀▀▄██░▀▀▄██░███░██░██░██░███░███░█████
    -- ██░▀▀▄████░████░██░██░▀▀▀░██░▀▀░█▀░▀█▀░▀██░▀▀░██
    -- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    -- [x] = { xN = x, yN = y }, -- 
    
    -- Cyrodiil --
    [201] = { xN = 0.509, yN = 0.593, name = "Western Elsweyr Gate Wayshrine" }, -- Western Elsweyr Wayshrine
    [200] = { xN = 0.556, yN = 0.594, name = "Eastern Elsweyr Gate Wayshrine" }, -- Eastern Elsweyr Wayshrine
    [202] = { xN = 0.622, yN = 0.410, name = "Northern Morrowind Gate Wayshrine" }, -- Northern Morrowind Wayshrine
    [203] = { xN = 0.643, yN = 0.455, name = "Southern Morrowind Gate Wayshrine" }, -- Southern Morrowind Wayshrine
    [170] = { xN = 0.449, yN = 0.411, name = "Northern Hammerfell Gate Wayshrine" }, -- Northern Hammerfell Wayshrine
    [199] = { xN = 0.429, yN = 0.449, name = "Southern Hammerfell Gate Wayshrine" }, -- Southern Hammerfell Wayshrine
    [236] = { xN = 0.542, yN = 0.475 }, -- Imperial City Prison Dungeon
    [247] = { xN = 0.536, yN = 0.486 }, -- White Gold Tower Dungeon

    -- Gold Coast --
    [390] = { xN = 0.304, yN = 0.559 }, -- Depths of Malatar Dungeon 

    -- Blackwood --
    [458] = { xN = 0.597, yN = 0.685 }, -- Leyawiin Wayshrine 
    [467] = { xN = 0.601, yN = 0.677 }, -- Leyawin Outskirts Wayshrine
    [471] = { xN = 0.600, yN = 0.683 }, -- Pilgrim's Rest House 
    [469] = { xN = 0.664, yN = 0.610 }, -- The Dread Cellar Dungeon 
    [481] = { xN = 0.617, yN = 0.627 }, -- Doomvault Vulpinaz Wayshrine 
    [461] = { xN = 0.611, yN = 0.645 }, -- Fort Redmane Wayshrine 
    [482] = { xN = 0.630, yN = 0.680 }, -- Blackwood Crosslands Wayshrine
    [460] = { xN = 0.590, yN = 0.653 }, -- Borderwatch Wayshrine 
    [463] = { xN = 0.620, yN = 0.703 }, -- Blueblood Wayshrine
    [472] = { xN = 0.603, yN = 0.687 }, -- Water's Edge House


    -- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
    -- ██░██░█▄░▄██░▄▄░██░██░████░▄▄▀██░▄▄▄░██░▄▄▀██░█▀▄██
    -- ██░▄▄░██░███░█▀▀██░▄▄░████░▀▀▄██░███░██░█████░▄▀███
    -- ██░██░█▀░▀██░▀▀▄██░██░████░██░██░▀▀▀░██░▀▀▄██░██░██
    -- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    -- [x] = { xN = x, yN = y }, -- 

    -- Rivenspire --
    [428] = { xN = 0.214, yN = 0.250 }, -- Forgemaster Falls House

    -- Wrothgar --
    [250] = { xN = 0.310, yN = 0.221 }, -- Maelstrom Arena Trial

    -- Betnikh --
    [182] = { xN = 0.074, yN = 0.435 }, -- Grimfield Wayshrine 
    [181] = { xN = 0.082, yN = 0.436 }, -- Stonetooth Wayshrine
    [183] = { xN = 0.082, yN = 0.444 }, -- Carved Hills Wayshrine


    -- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
    -- ██░██░█░▄▄▀██░▄▀▄░██░▄▀▄░██░▄▄▄██░▄▄▀██░▄▄▄██░▄▄▄██░█████░█████
    -- ██░▄▄░█░▀▀░██░█░█░██░█░█░██░▄▄▄██░▀▀▄██░▄▄███░▄▄▄██░█████░█████
    -- ██░██░█░██░██░███░██░███░██░▀▀▀██░██░██░█████░▀▀▀██░▀▀░██░▀▀░██
    -- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    -- [x] = { xN = x, yN = y }, -- 

    -- Craglorn --
    [217] = { xN = 0.379, yN = 0.374 }, -- Seeker's Archive Wayshrine
    [341] = { xN = 0.405, yN = 0.348 }, -- Fang Lair Dungeon
    [225] = { xN = 0.392, yN = 0.377 }, -- Spellscar Wayshrine 
    [220] = { xN = 0.387, yN = 0.387 }, -- Belkarth Wayshrine 
    [326] = { xN = 0.404, yN = 0.395 }, -- Bloodroot Forge Dungeon 
    [226] = { xN = 0.401, yN = 0.359 }, -- Mountain Overlook Wayshrine 
    [227] = { xN = 0.421, yN = 0.367 }, -- Inazzur's Hold Wayshrine
    [229] = { xN = 0.420, yN = 0.382 }, -- Elinhir Wayshrine 
    [231] = { xN = 0.428, yN = 0.377 }, -- Aetherian Archive Trial 
    [233] = { xN = 0.334, yN = 0.338 }, -- Dragonstar Wayshrine 
    [270] = { xN = 0.335, yN = 0.324 }, -- Dragonstar Arena Dungeon
    [219] = { xN = 0.354, yN = 0.373 }, -- Sandy Path Wayshrine
    [235] = { xN = 0.388, yN = 0.350 }, -- Valley of Scars Wayshrine 
    [218] = { xN = 0.344, yN = 0.353 }, -- Shada's Tear Wayshrine 
    [234] = { xN = 0.362, yN = 0.349 }, -- Skyreach Wayshrine 
    [230] = { xN = 0.344, yN = 0.380 }, -- Hel Ra Citadel Trial
    [232] = { xN = 0.366, yN = 0.330 }, -- Sanctum Ophidia Trial
    [327] = { xN = 0.328, yN = 0.351 }, -- Earthtear Caverns
    [395] = { xN = 0.410, yN = 0.394 }, -- Elinhir Private Arena House
    [310] = { xN = 0.432, yN = 0.381 }, -- Domus Phrasticus House

    -- Abah's Landing --
    [255] = { xN = 0.261, yN = 0.500 }, -- Abah's Landing Wayshrine
    [257] = { xN = 0.263, yN = 0.524 }, -- No Shira Citadel Wayshrine 
    [256] = { xN = 0.250, yN = 0.510 }, -- Zeht's Displeasure Wayshrine 

    -- Stros M'Kai --
    [179] = { xN = 0.169, yN = 0.534 }, -- Sandy Grotto Wayshrine 
    [180] = { xN = 0.159, yN = 0.551 }, -- Saintsport Wayshrine 
    [324] = { xN = 0.167, yN = 0.547 }, -- Hunding's Palatial Hall House
    [138] = { xN = 0.159, yN = 0.542 }, -- Port Hunding Wayshrine 


    -- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
    -- ██░▄▀▄░██░▄▄▄░██░▄▄▀██░▄▄▀██░▄▄▄░██░███░█▄░▄██░▀██░██░▄▄▀██
    -- ██░█░█░██░███░██░▀▀▄██░▀▀▄██░███░██░█░█░██░███░█░█░██░██░██
    -- ██░███░██░▀▀▀░██░██░██░██░██░▀▀▀░██▄▀▄▀▄█▀░▀██░██▄░██░▀▀░██
    -- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    -- [x] = { xN = x, yN = y }, -- 

    -- Vvardenfell --
    [330] = { xN = 0.685, yN = 0.266 }, -- Urskilaku Camp Wayshrine
    [282] = { xN = 0.757, yN = 0.265 }, -- Valley of the Wind Wayshrine
    [280] = { xN = 0.777, yN = 0.278 }, -- Tel Mora Wayshrine
    [273] = { xN = 0.671, yN = 0.290 }, -- Gnisis Wayshrine
    [329] = { xN = 0.691, yN = 0.308 }, -- West Gash Wayshrine
    [274] = { xN = 0.710, yN = 0.315 }, -- Ald'ruhn Wayshrine
    [281] = { xN = 0.812, yN = 0.324 }, -- Sadrith Mora Wayshrine 
    [331] = { xN = 0.798, yN = 0.336 }, -- Halls of Fabrication Trial
    [279] = { xN = 0.774, yN = 0.346 }, -- Nchuleftingth Wayshrine 
    [275] = { xN = 0.714, yN = 0.359 }, -- Balmora Wayshrine
    [276] = { xN = 0.750, yN = 0.369 }, -- Suran Wayshrine
    [277] = { xN = 0.796, yN = 0.377 }, -- Molag Mar Wayshrine 
    [278] = { xN = 0.796, yN = 0.407 }, -- Tel Branora Wayshrine
    [272] = { xN = 0.716, yN = 0.384 }, -- Seyda Neen Wayshrine 
    [284] = { xN = 0.733, yN = 0.398 }, -- Vivec City Wayshrine 
    [333] = { xN = 0.741, yN = 0.402 }, -- Saint Delyn Penthouse 
    [328] = { xN = 0.744, yN = 0.407 }, -- Vivec Temple Wayshrine
    [334] = { xN = 0.725, yN = 0.374 }, -- Amanya Lake Lodge House
    [335] = { xN = 0.673, yN = 0.269 }, -- Ald Velothi Harbour House
    [465] = { xN = 0.718, yN = 0.261 }, -- Kushalit Sanctuary House

    -- Firemoth Island --

    zoneData = hackyJoin({
      zoneName = "Firemoth Island",
      zoneID = 1313,
      xN = "0.674",
      yN = "0.381",
      zonePolygonData = {
        { xN = 0.682, yN = 0.403 },
        { xN = 0.688, yN = 0.399 },
        { xN = 0.694, yN = 0.394 },
        { xN = 0.696, yN = 0.387 },
        { xN = 0.694, yN = 0.380 },
        { xN = 0.686, yN = 0.379 },
        { xN = 0.679, yN = 0.383 },
        { xN = 0.676, yN = 0.387 },
        { xN = 0.672, yN = 0.396 },
        { xN = 0.674, yN = 0.400 },
        { xN = 0.678, yN = 0.402 },
      }
    }),


    -- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
    -- ██░▄▄▀██░████░▄▄▀██░▄▄▀██░█▀▄████░▄▀▄░█░▄▄▀██░▄▄▀██░▄▄▄░██░██░██
    -- ██░▄▄▀██░████░▀▀░██░█████░▄▀█████░█░█░█░▀▀░██░▀▀▄██▄▄▄▀▀██░▄▄░██
    -- ██░▀▀░██░▀▀░█░██░██░▀▀▄██░██░████░███░█░██░██░██░██░▀▀▀░██░██░██
    -- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    -- [x] = { xN = x, yN = y }, -- 
    
    -- Shadowfen --
    [48] = { xN = 0.748, yN = 0.584 }, -- Stormhold Wayshrine
    [260] = { xN = 0.712, yN = 0.582 }, -- Ruins of Mazzatun Dungeon 
    [171] = { xN = 0.760, yN = 0.593 }, -- Bogmother Wayshrine
    [85] = { xN = 0.777, yN = 0.605 }, -- Forsaken Hamlet Wayshrine 
    [47] = { xN = 0.722, yN = 0.593 }, -- Stillrise Wayshrine
    [261] = { xN = 0.716, yN = 0.594 }, -- Cradle of Shadows Dungeon
    [78] = { xN = 0.721, yN = 0.611 }, -- Venomnous Fens Wayshrine 
    [49] = { xN = 0.754, yN = 0.627 }, -- Hatching Pools Wayshrine 
    [50] = { xN = 0.765, yN = 0.625 }, -- Alten Corimont Wayshrine 
    [51] = { xN = 0.771, yN = 0.647 }, -- Perlocating Mire Wayshrine
    [192] = { xN = 0.707, yN = 0.622 }, -- Arx Corinium Dungeon
    [52] = { xN = 0.739, yN = 0.639 }, -- Hissmir Wayshrine 
    [53] = { xN = 0.712, yN = 0.641 }, -- Loriasel Wayshrine 
    [305] = { xN = 0.734, yN = 0.583 }, -- The Ample Domicile House 
    [316] = { xN = 0.755, yN = 0.611 }, -- Stay-Moist Mansion House

    -- Murkmire --
    [376] = { xN = 0.703, yN = 0.754 }, -- Dead-Water Wayshrine 
    [378] = { xN = 0.712, yN = 0.769 }, -- Blackrose Prison Dungeon
    [379] = { xN = 0.725, yN = 0.780 }, -- Blackrose Prison Wayshrine 
    [375] = { xN = 0.755, yN = 0.782 }, -- Bright-Throat Wayshrine 
    [377] = { xN = 0.758, yN = 0.739 }, -- Root-Whisper Wayshrine
    [388] = { xN = 0.724, yN = 0.735 }, -- Lakemire Xanmeer Manor House 

    -- Blackwood --
    [462] = { xN = 0.671, yN = 0.631 }, -- Bloodrun Wayshrine 
    [483] = { xN = 0.673, yN = 0.657 }, -- Hutan-Tzel Wayshrine
    [459] = { xN = 0.654, yN = 0.680 }, -- Gideon Wayshrine 
    [464] = { xN = 0.662, yN = 0.721 }, -- Stonewastes Wayshrine
    [484] = { xN = 0.688, yN = 0.714 }, -- Vunalk Wayshrine
    [468] = { xN = 0.684, yN = 0.742 }, -- Rockgrove Trial
    [473] = { xN = 0.687, yN = 0.624 }, -- Pantherfang Chapel House 

    -- Topal Hideout --
    [325] = { xN = 0.627, yN = 0.744 }, -- Topal Hideaway House


    -- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
    -- ██░▄▄▄██░█████░▄▄▄░██░███░██░▄▄▄██░███░██░▄▄▀██
    -- ██░▄▄▄██░█████▄▄▄▀▀██░█░█░██░▄▄▄██▄▀▀▀▄██░▀▀▄██
    -- ██░▀▀▀██░▀▀░██░▀▀▀░██▄▀▄▀▄██░▀▀▀████░████░██░██
    -- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    -- [x] = { xN = x, yN = y }, -- 

    -- Southern Elsweyr --
    [407] = { xN = 0.614, yN = 0.790 }, -- Dragonguard Sanctum Wayshrine


    -- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
    -- ██░███░█░▄▄▀██░█████░▄▄▄██░▀██░██░███░██░▄▄▄░██░▄▄▄░██░▄▄▀██
    -- ███░█░██░▀▀░██░█████░▄▄▄██░█░█░██░█░█░██░███░██░███░██░██░██
    -- ███▄▀▄██░██░██░▀▀░██░▀▀▀██░██▄░██▄▀▄▀▄██░▀▀▀░██░▀▀▀░██░▀▀░██
    -- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    -- [x] = { xN = x, yN = y }, -- 
    
    -- Reapers March --
    [158] = { xN = 0.461, yN = 0.564 }, -- Arenthia Wayshrine
    [156] = { xN = 0.436, yN = 0.569 }, -- Fort Grimwatch Wayshrine
    [144] = { xN = 0.420, yN = 0.600 }, -- Vinedusk Wayshrine
    [157] = { xN = 0.481, yN = 0.569 }, -- Fort Sphinxmoth Wayshrine
    [371] = { xN = 0.450, yN = 0.556 }, -- Moon Hunter Keep Dungeon
    [321] = { xN = 0.483, yN = 0.579 }, -- Dawnshadow House

    -- Malabal Tor --
    [188] = { xN = 0.283, yN = 0.604 }, -- Tempest Island Dungeon


    -- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
    -- ██░▄▄▄░██░██░██░▄▀▄░██░▄▀▄░██░▄▄▄██░▄▄▀██░▄▄▄░██░▄▄▄█▄▄░▄▄███▄░▄██░▄▄▄░██░█████░▄▄▄██░▄▄▄░██
    -- ██▄▄▄▀▀██░██░██░█░█░██░█░█░██░▄▄▄██░▀▀▄██▄▄▄▀▀██░▄▄▄███░██████░███▄▄▄▀▀██░█████░▄▄▄██▄▄▄▀▀██
    -- ██░▀▀▀░██▄▀▀▄██░███░██░███░██░▀▀▀██░██░██░▀▀▀░██░▀▀▀███░█████▀░▀██░▀▀▀░██░▀▀░██░▀▀▀██░▀▀▀░██
    -- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    -- [x] = { xN = x, yN = y }, -- 

    -- Summerset Isle --
    [369] = { xN = 0.131, yN = 0.627 }, -- Veyond Wyte Wayshrine 
    [349] = { xN = 0.157, yN = 0.660 }, -- King's Haven Pass Wayshrine 
    [359] = { xN = 0.164, yN = 0.688 }, -- Eldbur Ruins Wayshrine
    [350] = { xN = 0.166, yN = 0.715 }, -- Shimmerene Wayshrine 
    [351] = { xN = 0.195, yN = 0.748 }, -- Sil-Var-Woad Wayshrine 
    [357] = { xN = 0.182, yN = 0.768 }, -- Eastern Pass Wayshrine
    [365] = { xN = 0.143, yN = 0.782 }, -- Sunhold Wayshrine
    [352] = { xN = 0.132, yN = 0.714 }, -- Russafield Heights Wayshrine
    [364] = { xN = 0.134, yN = 0.679 }, -- Cloudrest Trial
    [358] = { xN = 0.090, yN = 0.656 }, -- Crystal Tower Wayshrine
    [354] = { xN = 0.104, yN = 0.687 }, -- Ebon Stadmont Wayshrine
    [356] = { xN = 0.058, yN = 0.703 }, -- Lilandril Wayshrine
    [353] = { xN = 0.093, yN = 0.729 }, -- Cey-Tarn Keep Wayshrine
    [366] = { xN = 0.090, yN = 0.747 }, -- Golden Gryphon Garret House
    [355] = { xN = 0.094, yN = 0.757 }, -- Alinor Wayshrine
    [367] = { xN = 0.089, yN = 0.760 }, -- Alinor Crest Townhouse 
    [368] = { xN = 0.177, yN = 0.797 }, -- Colossal Aldmeri Grotto

    -- Auridon --
    [194] = { xN = 0.185, yN = 0.594 }, -- Banished Cells I Dungeon 
    [262] = { xN = 0.185, yN = 0.594 }, -- Banished Cells II Dungeon 
    [175] = { xN = 0.192, yN = 0.619 }, -- Firsthold Wayshrine 
    [124] = { xN = 0.177, yN = 0.626 }, -- Greenwater Wayshrine 
    [123] = { xN = 0.218, yN = 0.631 }, -- College Wayshrine 
    [122] = { xN = 0.231, yN = 0.648 }, -- Quendeluun Wayshrine
    [121] = { xN = 0.237, yN = 0.662 }, -- Skywatch Wayshrine 
    [176] = { xN = 0.219, yN = 0.674 }, -- Mathiisen Wayshrine 
    [174] = { xN = 0.221, yN = 0.698 }, -- Tanzelwil Wayshrine
    [178] = { xN = 0.232, yN = 0.706 }, -- Phaer Wayshrine 
    [127] = { xN = 0.222, yN = 0.715 }, -- Windy Glade Wayshrine
    [288] = { xN = 0.236, yN = 0.725 }, -- Mara's Kiss Public House 
    [211] = { xN = 0.247, yN = 0.730 }, -- The Harborage 
    [177] = { xN = 0.237, yN = 0.728 }, -- Vulkhel Guard Wayshrine
    [315] = { xN = 0.231, yN = 0.688 }, -- Mathiisen Manor House
    [285] = { xN = 0.245, yN = 0.668 }, -- Barbed Hook Private Room House
    
    -- Eyevea --
    [215] = { xN = 0.077, yN = 0.598 }, -- Eyevea Wayshrine

  },

  [439] = {}, -- Aurbis Map (nothing here, for now)

  [16] = {  -- Cyrodiil PVP Map --
    [202] = { name = "Northern Morrowind Gate Wayshrine" }, -- Northern Morrowind Wayshrine
    [203] = { name = "Southern Morrowind Gate Wayshrine" }, -- Southern Morrowind Wayshrine
    [170] = { name = "Northern Hammerfell Gate Wayshrine" }, -- Northern Hammerfell Wayshrine
    [199] = { name = "Southern Hammerfell Gate Wayshrine" }, -- Southern Hammerfell Wayshrine
    [200] = { name = "Eastern Elsweyr Gate Wayshrine" }, -- Eastern Elsweyr Wayshrine
    [201] = { name = "Western Elsweyr Gate Wayshrine" }, -- Western Elsweyr Wayshrine
    [236] = { xN = 0.523, yN = 0.382 }, -- Imperial City Prison Dungeon
    [247] = { xN = 0.497, yN = 0.428 }, -- White Gold Tower Dungeon
  },

  [1719] = { -- Western Skyrim Map 
    [434] = { xN = 0.442, yN = 0.193 }, -- Kyne's Aegis
  },
}


local function print(message, ...)
	df("[%s] %s", addon.name, tostring(message:format(...)))
end


function addon.GetMapTileTexture(index)
    local tex = _GetMapTileTexture(index)
    if not enabled then return tex end
    for i = 1, 16 do
        if tiles[i] == tex then
            ---- Replace certain tiles if you are on live server and have spoilers enabled
            if debug then
               i = tostring(i) .. "_debug"  
            end
            return "AccurateWorldMap/tiles/tamriel_" .. i .. ".dds"
        end
    end
    return tex
end

local _GetMapCustomMaxZoom = GetMapCustomMaxZoom

local providedPoiType = 1
local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()



local function toggleDebugOutput()

  if debugOutput == true then
    d("Debug output turned off")
  end

  if debugOutput == false then
    d("Debug output turned on")
  end

  debugOutput = not debugOutput


  
end

local function getCurrentZoneID()

  local zoneID = GetCurrentMapId()

  if (zoneID == nil) then

    -- do something, get the subzone id or figure out why it is nil in the first place
    zoneID = 0
  end


  return zoneID

end




local function getZoneInfoByID(zoneID)


  local zoneData = mapData[getCurrentZoneID()]
  local zoneInfo = zoneData.zoneData

  for zoneIndex, zoneInfo in pairs(zoneInfo) do

    if (zoneInfo.zoneID == zoneID) then
      return zoneInfo
    end
  end
end


local function getZoneIDFromPolygonName(polygonName)
  return tonumber(string.match (polygonName, "%d+"))
end


-- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
-- ██░▄▄▄░██░▄▄▄░██░▄▄▄░████░▄▄▄██░██░██░▀██░██░▄▄▀█▄▄░▄▄█▄░▄██░▄▄▄░██░▀██░██░▄▄▄░██
-- ██▀▀▀▄▄██░███░██▄▄▄▀▀████░▄▄███░██░██░█░█░██░██████░████░███░███░██░█░█░██▄▄▄▀▀██
-- ██░▀▀▀░██░▀▀▀░██░▀▀▀░████░█████▄▀▀▄██░██▄░██░▀▀▄███░███▀░▀██░▀▀▀░██░██▄░██░▀▀▀░██
-- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀

local zos_GetMapMouseoverInfo = GetMapMouseoverInfo
GetMapMouseoverInfo = function(xN, yN)

  local mapIndex = getCurrentZoneID()

  -- invisible blank default mouseover data
  local locationName = ""
  local textureFile = ""
  local widthN = 0.01
  local heightN = 0.01
  local locXN = 0
  local locYN = 0

  -- if the current map is not set to exclusive, or we don't have any data for it, get vanilla values
  if (isExclusive == false or mapData[mapIndex] == nil) then
    locationName, textureFile, widthN, heightN, locXN, locYN = zos_GetMapMouseoverInfo(xN, yN)
  end

  if (mapData[mapIndex] ~= nil) then

    if (isInBlobHitbox) then 

        locationName = currentZoneInfo.zoneName
        textureFile = currentZoneInfo.blobTexture
        widthN = currentZoneInfo.nBlobTextureWidth
        heightN = currentZoneInfo.nBlobTextureHeight
        locXN = currentZoneInfo.xN
        locYN = currentZoneInfo.yN
        
    end

  end

  return locationName, textureFile, widthN, heightN, locXN, locYN
end


local zos_GetFastTravelNodeInfo = GetFastTravelNodeInfo    
GetFastTravelNodeInfo = function(nodeIndex)
  local known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked = zos_GetFastTravelNodeInfo(nodeIndex)
  local disabled = false


  if debugOutput == true then
        d("Current Node: "..nodeIndex)
        d("Name: "..name)
        d(" ")
  end

  local mapIndex = getCurrentZoneID()


  if (mapData[mapIndex] ~= nil) then

    if (mapData[mapIndex][nodeIndex] ~= nil) then

      local zoneData = mapData[mapIndex]

      if (zoneData[nodeIndex] ~= nil) then 


        if zoneData[nodeIndex].xN ~= nil then
          normalizedX = zoneData[nodeIndex].xN
        end

        if zoneData[nodeIndex].yN ~= nil then
          normalizedY = zoneData[nodeIndex].yN
        end

        if zoneData[nodeIndex].name ~= nil then
          name = zoneData[nodeIndex].name
        end


      end


    end

  end

  return known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked, disabled

end

local zos_ProcessMapClick = ProcessMapClick    
ProcessMapClick = function(x, y)
  local resultingMapIndex = zos_ProcessMapClick(x, y)


  print(tostring(resultingMapIndex))


  -- check 
  -- if isExclusive is true



  return resultingMapIndex
  
end


    

-- function to check if the mouse cursor is within or over the map window
local function isMouseWithinMapWindow()
  local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
  return (not ZO_WorldMapContainer:IsHidden() and (mouseOverControl == ZO_WorldMapContainer or mouseOverControl:GetParent() == ZO_WorldMapContainer))
end

local function clickListener()

  if isMouseWithinMapWindow() then

    if (recordCoordinates) then 
      PlaySound(SOUNDS.COUNTDOWN_TICK)

      table.insert(newPolygonData, {xN = normalisedMouseX, yN = normalisedMouseY})
      currentCoordinateCount = currentCoordinateCount + 1

    end



    print("Map clicked!")
  end

  if IsControlKeyDown() then
    print("booba")
  end


end





local function mapTick()

  local mouseX, mouseY = GetUIMousePosition()

  local currentOffsetX = ZO_WorldMapContainer:GetLeft()
  local currentOffsetY = ZO_WorldMapContainer:GetTop()
  local parentOffsetX = ZO_WorldMap:GetLeft()
  local parentOffsetY = ZO_WorldMap:GetTop()
  local mapWidth, mapHeight = ZO_WorldMapContainer:GetDimensions()
  local parentWidth, parentHeight = ZO_WorldMap:GetDimensions()

  normalisedMouseX = math.floor((((mouseX - currentOffsetX) / mapWidth) * 1000) + 0.5)/1000
  normalisedMouseY = math.floor((((mouseY - currentOffsetY) / mapHeight) * 1000) + 0.5)/1000



  if (currentPolygon ~= nil) then

    -- check to make sure that the user has actually left the hitbox, and is not just hovering over a wayshrine
    if (currentPolygon:IsPointInside(mouseX , mouseY)) then

      --print("still in hitbox!")


    else

      --print("left hitbox!")
      isInBlobHitbox = false
      currentPolygon = nil
      currentZoneInfo = {}

    end

  end

end

function addon.GetMapCustomMaxZoom()
    if not enabled then return _GetMapCustomMaxZoom() end
    if GetMapName() == "Tamriel" then
        return 3
    else
        return _GetMapCustomMaxZoom()
    end
end

local panel = LAM:RegisterAddonPanel(panelName, panelData)
local optionsData = {
    {
        type = "checkbox",
        name = "Enable debug tiles",
        getFunc = function() return saveData.myValue end,
        setFunc = function(value) debug = value end
    }
}

local function checkIfCanTick()

  if isMouseWithinMapWindow() then
    mapTick()
  end


end



local function createOrShowZonePolygon(polygonData, zoneInfo, isDebug)

  local polygonID


  if (zoneInfo ~= nil) then

    polygonID = "blobHitbox-"..zoneInfo.zoneID.."-"..zoneInfo.zoneName


  else

    isDebug = true
    polygonID = "debugPolygon"

  end

  -- check if polygon by this name exists
  if (WINDOW_MANAGER:GetControlByName(polygonID) == nil) then


    local polygon = ZO_WorldMapContainer:CreateControl(polygonID, CT_POLYGON)
    polygon:SetAnchorFill(ZO_WorldMapContainer)

    for key, data in pairs(polygonData) do
      print(tostring("Coordinate set "..key .. ": "))
  
      print("X: "..tostring(data.xN))
      print("Y: "..tostring(data.yN))
  
  
      polygon:AddPoint(data.xN, data.yN)
  
  
    end
  
  
    if (isDebug) then
      polygon:SetCenterColor(0, 1, 0, 0.5)
    else
      polygon:SetCenterColor(0, 0, 0, 0)
    end
    
  
  
  
    polygon:SetMouseEnabled(true)

    polygon:SetHandler("OnMouseDown", function()


      mouseDownOnPolygon = true
      ZO_WorldMap_MouseDown(MOUSE_BUTTON_INDEX_LEFT)

    end)
    polygon:SetHandler("OnMouseUp", function()

      -- travel to zone


      ZO_WorldMap_MouseUp(MOUSE_BUTTON_INDEX_LEFT)
      
    end)
      
      
  
  
    polygon:SetHandler("OnMouseEnter", function()
      isInBlobHitbox = true
      --print("User has entered zone hitbox")
      currentPolygon = polygon
  
      -- update with current zone info
      currentZoneInfo = getZoneInfoByID(getZoneIDFromPolygonName(polygon:GetName()))
    end)
  
  else 
    -- it already exists, we just need to show it again
    WINDOW_MANAGER:GetControlByName(polygonID):SetHidden(false)
    WINDOW_MANAGER:GetControlByName(polygonID):SetMouseEnabled(true)
  end
end

local function recordPolygon()

  if recordCoordinates == true then
    d("Coordinates recorded.")

    createOrShowZonePolygon(newPolygonData)


    newPolygonData = {}
    currentCoordinateCount = 0
    recordCoordinates = false
  end

  if recordCoordinates == false then
    d("Recording coordinates... click on the map to draw a polygon")
    recordCoordinates = true
  end


end

local function getFileDirectoryFromZoneName(providedZoneName)

  local providedZoneName = providedZoneName

  providedZoneName = providedZoneName:gsub("'", "") -- replace all instances of `'` with empty string
  providedZoneName = providedZoneName:gsub(" ", "") -- replace all instances of ` ` with empty string

  providedZoneName = providedZoneName:lower()

  local blobFileDirectory = ("AccurateWorldMap/blobs/tamriel-"..providedZoneName..".dds")

  return blobFileDirectory
end



AccurateWorldMapTLC = CreateTopLevelWindow("AccurateWorldMapTLC")
AccurateWorldMapTLC:SetResizeToFitDescendents(true) --will make the TLC window resize with it's childen -> the Tex01 texture control
AccurateWorldMapTex01 = CreateControl("AccurateWorldMapTex01", AccurateWorldMapTLC, CT_TEXTURE)
AccurateWorldMapTex01:SetResizeToFitFile(true)


local function getBlobTextureDetails()

  print("getting blob info!")


  -- iterate through all of mapData
  for mapID, zoneData in pairs(mapData) do


    if (zoneData.zoneData ~= nil) then

      print("got to here!")

      local zoneInfo = zoneData.zoneData

      for zoneIndex, zoneInfo in pairs(zoneInfo) do

        print("checking zone info!")

        if (zoneInfo.zoneName ~= nil) then

          print("there is a zone name!")

          if (zoneInfo.blobTexture == nil or zoneInfo.nBlobTextureHeight == nil or zoneInfo.nBlobTextureWidth == nil ) then

            print("displaying textures!")

            local textureDirectory = getFileDirectoryFromZoneName(zoneInfo.zoneName)




            -- load texture into control from name
            AccurateWorldMapTex01:SetTexture(textureDirectory)

            -- check if texture exists before doing stuff
            if (AccurateWorldMapTex01:IsTextureLoaded()) then

              -- get the dimensions
              local textureHeight, textureWidth = AccurateWorldMapTex01:GetTextureFileDimensions()

              -- save texture name and dimensions
              mapData[mapID].zoneData[zoneIndex].blobTexture = textureDirectory
              mapData[mapID].zoneData[zoneIndex].nBlobTextureHeight = textureHeight / mapDimensions
              mapData[mapID].zoneData[zoneIndex].nBlobTextureWidth = textureWidth / mapDimensions

            else

              print("The following texture failed to load: "..textureDirectory)


            end

          end


        end

      end

    end
  end
end


local function cleanUpZoneBlobs()

  local numChildren = ZO_WorldMapContainer:GetNumChildren()


  for i = 1, numChildren do


    local childControl = ZO_WorldMapContainer:GetChild(i)
    local controlName = childControl:GetName()

    if (string.match(controlName, "blobHitbox-")) then
      childControl:SetHidden(true)
      childControl:SetMouseEnabled(false)

    end

  end




end

local function OnAddonLoaded(event, addonName)
    if addonName ~= addon.name then return end
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)


    getBlobTextureDetails()

    -- comment these two to hide the control
    AccurateWorldMapTLC:SetAlpha(1)
    AccurateWorldMapTLC:SetHidden(false)

    
    






    SLASH_COMMANDS["/awm_debug"] = toggleDebugOutput
    SLASH_COMMANDS["/get_map_id"] = function() print(tostring(GetCurrentMapId())) end
    SLASH_COMMANDS["/zones_debug"] = initialise
    SLASH_COMMANDS["/record_polygon"] = recordPolygon
    SLASH_COMMANDS["/get_blobs"] = getBlobTextureDetails
    SLASH_COMMANDS["/get_controls"] = cleanUpZoneBlobs

  --   SLASH_COMMANDS["/joke"] = function() 
  --     d(GetRandomElement(jokes)) 
  -- end
    
    GetMapTileTexture = addon.GetMapTileTexture
    GetMapCustomMaxZoom = addon.GetMapCustomMaxZoom
    

end






-- Function that gets called whenever the user changes zone, or clicks to a new zone on the world map.

local function onZoneChanged()

  local zoneName = GetUnitZone(UNITTAG_PLAYER)
  local mapIndex = getCurrentZoneID()

  print("Zone changed!")



  -- Delete any existing controls on the world map before iterating over anything else
  cleanUpZoneBlobs()

  if (mapIndex ~= nil) then


    print("Current map id: ".. mapIndex)


    -- Check if the current zone/map has any custom map data set to it
    if (mapData[mapIndex] ~= nil) then
      
      print("This map has custom data!")


      if (mapData[mapIndex].isExclusive ~= nil) then
        isExclusive = mapData[mapIndex].isExclusive
      else
        isExclusive = false
      end


      if (mapData[mapIndex].zoneData ~= nil) then
        print("This map has custom zone data!")
        local zoneData = mapData[mapIndex].zoneData

        for zoneAttribute, zoneInfo in pairs(zoneData) do


          if (zoneInfo.zoneName ~= nil) then

            print(zoneInfo.zoneName)

            print(tostring(zoneAttribute))
            print(tostring(zoneInfo))

            if (zoneInfo.xN ~= nil and zoneInfo.yN ~= nil) then
              if (zoneInfo.blobTexture ~= nil and zoneInfo.nBlobTextureHeight ~= nil and zoneInfo.nBlobTextureHeight ~= nil ) then
                if (zoneInfo.zonePolygonData ~= nil) then

                  createOrShowZonePolygon(zoneInfo.zonePolygonData, zoneInfo)


                  -- add polygons, make zone data

                else 
                  print("Warning: Custom Zone "..zoneInfo.zoneName.." ".."is missing its hitbox polygon!")
                end
              else
                print("Warning: Custom Zone "..zoneInfo.zoneName.." ".."is missing its texture details!")

                -- rerun texture details for this zone
                -- getTextureDetails() --getTextureDetails(nil)

              end
            else
              print("Warning: Custom Zone "..zoneInfo.zoneName.." ".." has invalid zone coordinates!")
            end
          else
            print("Warning: Custom Zone ID #"..tostring(zoneInfo.zoneID).." has no name!")
          end
        end
      end

    else
      isExclusive = false
    end
  end
  print("isExclusive: "..tostring(isExclusive))
end




-- Registering events and callbacks
LAM:RegisterOptionControls(panelName, optionsData)
EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
EVENT_MANAGER:RegisterForEvent("Click Listener", EVENT_GLOBAL_MOUSE_DOWN, clickListener)
EVENT_MANAGER:RegisterForUpdate("uniqueName", 0, checkIfCanTick)
CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", onZoneChanged)



-- frame.edit = CHAIN(wm:CreateControlFromVirtual("$(parent)_Edit",
-- frame, "ZO_DefaultEditMultiLine"))
-- :SetAnchor(TOPLEFT, frame, TOPLEFT, 2, 2)
-- :SetAnchor(BOTTOMRIGHT, frame, BOTTOMRIGHT, -2, -2)
-- :SetMaxInputChars(2000)
-- :SetFont("ZoFontGame")
-- :SetHidden(true)
-- :SetHandler("OnShow", function()
-- -- hide all line controls
-- for i, line in ipairs(FRAME_LINES) do
-- line:SetHidden(true)
-- end
-- -- disable Zgoo:Update() while this box is shown
-- frame.lines = nil
-- end)
-- :SetHandler("OnHide", function()
-- frame.lines = FRAME_LINES
-- Zgoo:Update()
-- end)
-- .__END