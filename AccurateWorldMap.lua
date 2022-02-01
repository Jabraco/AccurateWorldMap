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
local hasDragged = false


local currentMapIndex

local waitForRelease = false
local currentMapOffsetX
local currentMapOffsetY


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
    [172] = { xN = 0.617, yN = 0.232 }, -- Bleakrock Isle Wayshrine

    zoneData = hackyJoin({
      zoneName = "Bleakrock Isle",
      zoneID = 74,
      xN = "0.6075",
      yN = "0.223",
      zonePolygonData = {
        { xN = 0.605, yN = 0.233 },
        { xN = 0.614, yN = 0.244 },
        { xN = 0.619, yN = 0.243 },
        { xN = 0.629, yN = 0.233 },
        { xN = 0.628, yN = 0.229 },
        { xN = 0.620, yN = 0.221 },
        { xN = 0.615, yN = 0.221 },
        { xN = 0.605, yN = 0.224 },
        { xN = 0.605, yN = 0.228 },
      }
    }),

    -- Eastmarch --
    [88] = { xN = 0.559, yN = 0.287 }, -- Fort Morvunskar Wayshrine
    [90] = { xN = 0.565, yN = 0.274 }, -- Voljar Meadery Wayshrine
    [89] = { xN = 0.575, yN = 0.283 }, -- Kynesgrove Wayshrine
    [93] = { xN = 0.569, yN = 0.308 }, -- Wittestadr Wayshrine
    [97] = { xN = 0.608, yN = 0.306 }, -- Skuldafn Wayshrine
    [96] = { xN = 0.592, yN = 0.308 }, -- Logging Camp Wayshrine
    [95] = { xN = 0.601, yN = 0.314 }, -- Jorunn's Stand Wayshrine
    [91] = { xN = 0.541, yN = 0.289 }, -- Cradlecrush Wayshrine
    [392] = { xN = 0.547, yN = 0.286 }, -- Frostvault Chasm House
    [389] = { xN = 0.548, yN = 0.284 }, -- Frostvault Dungeon
    [312] = { xN = 0.582, yN = 0.264 }, -- Grymhearth's Woe House
    [87] = { xN = 0.578, yN = 0.264 }, -- Windhelm Wayshrine
    [94] = { xN = 0.576, yN = 0.324 }, -- Mistwatch Wayshrine
    [195] = { xN = 0.610, yN = 0.328 }, -- Direfrost Keep Dungeon
    [92] = { xN = 0.539, yN = 0.310 }, -- Fort Amol Wayshrine

    zoneData = hackyJoin({
      zoneName = "Eastmarch",
      zoneID = 61,
      xN = "0.5275",
      yN = "0.249",
      zonePolygonData = {
        { xN = 0.617, yN = 0.331 },
        { xN = 0.618, yN = 0.324 },
        { xN = 0.612, yN = 0.314 },
        { xN = 0.614, yN = 0.309 },
        { xN = 0.610, yN = 0.304 },
        { xN = 0.606, yN = 0.303 },
        { xN = 0.603, yN = 0.296 },
        { xN = 0.600, yN = 0.291 },
        { xN = 0.599, yN = 0.279 },
        { xN = 0.599, yN = 0.274 },
        { xN = 0.601, yN = 0.273 },
        { xN = 0.605, yN = 0.258 },
        { xN = 0.602, yN = 0.255 },
        { xN = 0.598, yN = 0.256 },
        { xN = 0.593, yN = 0.257 },
        { xN = 0.586, yN = 0.256 },
        { xN = 0.577, yN = 0.255 },
        { xN = 0.568, yN = 0.256 },
        { xN = 0.561, yN = 0.257 },
        { xN = 0.554, yN = 0.262 },
        { xN = 0.549, yN = 0.268 },
        { xN = 0.546, yN = 0.271 },
        { xN = 0.548, yN = 0.276 },
        { xN = 0.547, yN = 0.280 },
        { xN = 0.545, yN = 0.282 },
        { xN = 0.541, yN = 0.285 },
        { xN = 0.533, yN = 0.287 },
        { xN = 0.529, yN = 0.295 },
        { xN = 0.526, yN = 0.306 },
        { xN = 0.526, yN = 0.316 },
        { xN = 0.529, yN = 0.324 },
        { xN = 0.539, yN = 0.326 },
        { xN = 0.547, yN = 0.329 },
        { xN = 0.555, yN = 0.331 },
        { xN = 0.560, yN = 0.332 },
        { xN = 0.567, yN = 0.334 },
        { xN = 0.572, yN = 0.333 },
        { xN = 0.581, yN = 0.331 },
        { xN = 0.589, yN = 0.329 },
        { xN = 0.605, yN = 0.334 },
        { xN = 0.611, yN = 0.332 },        
      }
    }),
    
    -- The Rift --
    [119] = { xN = 0.556, yN = 0.361 }, -- Ragged Hills Wayshrine
    [115] = { xN = 0.580, yN = 0.343 }, -- Northwind Mine Wayshrine 
    [301] = { xN = 0.552, yN = 0.346 }, -- Autumn's Gate House 
    [114] = { xN = 0.598, yN = 0.341 }, -- Fallowstone Hall Wayshrine 
    [372] = { xN = 0.611, yN = 0.356 }, -- Hunter's Glade House 
    [118] = { xN = 0.549, yN = 0.354 }, -- Nimalten Wayshrine
    [116] = { xN = 0.541, yN = 0.337 }, -- Geirmund's Hall Wayshrine 
    [117] = { xN = 0.538, yN = 0.353 }, -- Taarengrav Wayshrine
    [113] = { xN = 0.571, yN = 0.367 }, -- Honrich Tower Wayshrine
    [110] = { xN = 0.599, yN = 0.371 }, -- Skald's Retreat Wayshrine
    [322] = { xN = 0.610, yN = 0.372 }, -- Old Mistveil Manor House 
    [109] = { xN = 0.607, yN = 0.363 }, -- Riften Wayshrine
    [112] = { xN = 0.608, yN = 0.396 }, -- Trollhetta Summit Wayshrine 
    [111] = { xN = 0.616, yN = 0.385 }, -- Trollhetta Wayshrine
    [120] = { xN = 0.620, yN = 0.373 }, -- Fullhelm Fort Wayshrine
    [187] = { xN = 0.627, yN = 0.379 }, -- Blessed Crucible Dungeon

    zoneData = hackyJoin({
      zoneName = "The Rift",
      zoneID = 125,
      xN = "0.5275",
      yN = "0.3145",
      zonePolygonData = {
        { xN = 0.626, yN = 0.397 },
        { xN = 0.625, yN = 0.391 },
        { xN = 0.630, yN = 0.384 },
        { xN = 0.633, yN = 0.379 },
        { xN = 0.631, yN = 0.361 },
        { xN = 0.627, yN = 0.358 },
        { xN = 0.621, yN = 0.340 },
        { xN = 0.617, yN = 0.331 },
        { xN = 0.607, yN = 0.334 },
        { xN = 0.600, yN = 0.334 },
        { xN = 0.588, yN = 0.331 },
        { xN = 0.568, yN = 0.335 },
        { xN = 0.566, yN = 0.335 },
        { xN = 0.557, yN = 0.332 },
        { xN = 0.549, yN = 0.332 },
        { xN = 0.541, yN = 0.328 },
        { xN = 0.531, yN = 0.326 },
        { xN = 0.527, yN = 0.335 },
        { xN = 0.527, yN = 0.340 },
        { xN = 0.528, yN = 0.348 },
        { xN = 0.527, yN = 0.353 },
        { xN = 0.527, yN = 0.356 },
        { xN = 0.529, yN = 0.364 },
        { xN = 0.534, yN = 0.378 },
        { xN = 0.536, yN = 0.386 },
        { xN = 0.533, yN = 0.394 },
        { xN = 0.542, yN = 0.397 },
        { xN = 0.552, yN = 0.400 },
        { xN = 0.555, yN = 0.399 },
        { xN = 0.564, yN = 0.403 },
        { xN = 0.571, yN = 0.404 },
        { xN = 0.580, yN = 0.400 },
        { xN = 0.594, yN = 0.404 },
        { xN = 0.602, yN = 0.408 },
        { xN = 0.609, yN = 0.403 },
        { xN = 0.619, yN = 0.400 },
        { xN = 0.623, yN = 0.397 },        
      }
    }),

    -- Western Skyrim --
    [424] = { xN = 0.404, yN = 0.157 }, -- Icereach Dungeon
    [434] = { xN = 0.408, yN = 0.186 }, -- Kyne's Aegis Trial

    zoneData = hackyJoin({
      zoneName = "Western Skyrim",
      zoneID = 1719,
      xN = "0.352",
      yN = "0.166",
      zonePolygonData = {
        { xN = 0.464, yN = 0.279 },
        { xN = 0.469, yN = 0.273 },
        { xN = 0.468, yN = 0.270 },
        { xN = 0.477, yN = 0.253 },
        { xN = 0.473, yN = 0.234 },
        { xN = 0.478, yN = 0.221 },
        { xN = 0.476, yN = 0.213 },
        { xN = 0.478, yN = 0.210 },
        { xN = 0.471, yN = 0.207 },
        { xN = 0.469, yN = 0.197 },
        { xN = 0.464, yN = 0.198 },
        { xN = 0.444, yN = 0.205 },
        { xN = 0.437, yN = 0.203 },
        { xN = 0.436, yN = 0.190 },
        { xN = 0.435, yN = 0.185 },
        { xN = 0.420, yN = 0.182 },
        { xN = 0.411, yN = 0.179 },
        { xN = 0.405, yN = 0.180 },
        { xN = 0.387, yN = 0.183 },
        { xN = 0.384, yN = 0.178 },
        { xN = 0.349, yN = 0.192 },
        { xN = 0.354, yN = 0.221 },
        { xN = 0.358, yN = 0.234 },
        { xN = 0.352, yN = 0.244 },
        { xN = 0.358, yN = 0.247 },
        { xN = 0.361, yN = 0.251 },
        { xN = 0.367, yN = 0.250 },
        { xN = 0.369, yN = 0.256 },
        { xN = 0.373, yN = 0.257 },
        { xN = 0.377, yN = 0.261 },
        { xN = 0.382, yN = 0.259 },
        { xN = 0.387, yN = 0.266 },
        { xN = 0.384, yN = 0.272 },
        { xN = 0.387, yN = 0.282 },
        { xN = 0.397, yN = 0.284 },
        { xN = 0.406, yN = 0.281 },
        { xN = 0.418, yN = 0.277 },
        { xN = 0.429, yN = 0.270 },
        { xN = 0.448, yN = 0.270 },
        { xN = 0.448, yN = 0.274 },
        { xN = 0.460, yN = 0.279 },
      }
    }),

    -- Grayhome --
    zoneData = hackyJoin({
      zoneName = "Grayhome",
      zoneID = 1864,
      xN = "0.242",
      yN = "0.125",
      zonePolygonData = {
        { xN = 0.247, yN = 0.144 },
        { xN = 0.254, yN = 0.144 },
        { xN = 0.261, yN = 0.136 },
        { xN = 0.258, yN = 0.126 },
        { xN = 0.248, yN = 0.122 },
        { xN = 0.241, yN = 0.126 },
        { xN = 0.239, yN = 0.134 },
        { xN = 0.243, yN = 0.140 },
      }
    }),

    -- Icereach --
    zoneData = hackyJoin({
      zoneName = "Icereach",
      zoneID = 1737,
      xN = "0.390",
      yN = "0.146",
      zonePolygonData = {
        { xN = 0.389, yN = 0.164 },
        { xN = 0.398, yN = 0.166 },
        { xN = 0.410, yN = 0.165 },
        { xN = 0.417, yN = 0.162 },
        { xN = 0.420, yN = 0.155},
        { xN = 0.414, yN = 0.150 },
        { xN = 0.397, yN = 0.151 },
        { xN = 0.386, yN = 0.152 },
        { xN = 0.386, yN = 0.159 },
      }
    }),

    -- The Reach --
    [445] = { xN = 0.377, yN = 0.270 }, -- Karthwasten Wayshrine
    [221] = { xN = 0.337, yN = 0.275 }, -- The Earth Forge Wayshrine

    zoneData = hackyJoin({
      zoneName = "The Reach",
      zoneID = 1814,
      xN = "0.323",
      yN = "0.243",
      zonePolygonData = {
        { xN = 0.352, yN = 0.245 },
        { xN = 0.359, yN = 0.251 },
        { xN = 0.366, yN = 0.253 },
        { xN = 0.368, yN = 0.258 },
        { xN = 0.373, yN = 0.259 },
        { xN = 0.378, yN = 0.262 },
        { xN = 0.383, yN = 0.262 },
        { xN = 0.386, yN = 0.266 },
        { xN = 0.383, yN = 0.270 },
        { xN = 0.382, yN = 0.277 },
        { xN = 0.386, yN = 0.282 },
        { xN = 0.390, yN = 0.286 },
        { xN = 0.396, yN = 0.292 },
        { xN = 0.405, yN = 0.294 },
        { xN = 0.410, yN = 0.296 },
        { xN = 0.409, yN = 0.304 },
        { xN = 0.413, yN = 0.311 },
        { xN = 0.408, yN = 0.320 },
        { xN = 0.390, yN = 0.325 },
        { xN = 0.378, yN = 0.322 },
        { xN = 0.373, yN = 0.320 },
        { xN = 0.359, yN = 0.322 },
        { xN = 0.349, yN = 0.322 },
        { xN = 0.337, yN = 0.317 },
        { xN = 0.336, yN = 0.314 },
        { xN = 0.335, yN = 0.303 },
        { xN = 0.330, yN = 0.300 },
        { xN = 0.333, yN = 0.295 },
        { xN = 0.330, yN = 0.292 },
        { xN = 0.333, yN = 0.286 },
        { xN = 0.329, yN = 0.278 },
        { xN = 0.334, yN = 0.272 },
        { xN = 0.337, yN = 0.259 },
        { xN = 0.348, yN = 0.254 },
        { xN = 0.350, yN = 0.249 },
        { xN = 0.351, yN = 0.245 },
      }
    }),

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

    zoneData = hackyJoin({
      zoneName = "Cyrodiil",
      zoneID = 16,
      xN = "0.420",
      yN = "0.384",
      zonePolygonData = {
        { xN = 0.445, yN = 0.397 },
        { xN = 0.464, yN = 0.400 },
        { xN = 0.479, yN = 0.404 },
        { xN = 0.488, yN = 0.395 },
        { xN = 0.496, yN = 0.394 },
        { xN = 0.506, yN = 0.396 },
        { xN = 0.509, yN = 0.400 },
        { xN = 0.518, yN = 0.399 },
        { xN = 0.523, yN = 0.395 },
        { xN = 0.531, yN = 0.394 },
        { xN = 0.541, yN = 0.398 },
        { xN = 0.548, yN = 0.401 },
        { xN = 0.557, yN = 0.402 },
        { xN = 0.566, yN = 0.404 },
        { xN = 0.570, yN = 0.406 },
        { xN = 0.579, yN = 0.403 },
        { xN = 0.589, yN = 0.405 },
        { xN = 0.595, yN = 0.405 },
        { xN = 0.604, yN = 0.409 },
        { xN = 0.616, yN = 0.403 },
        { xN = 0.625, yN = 0.399 },
        { xN = 0.627, yN = 0.399 },
        { xN = 0.630, yN = 0.405 },
        { xN = 0.633, yN = 0.406 },
        { xN = 0.640, yN = 0.422 },
        { xN = 0.637, yN = 0.431 },
        { xN = 0.642, yN = 0.436 },
        { xN = 0.646, yN = 0.443 },
        { xN = 0.651, yN = 0.447 },
        { xN = 0.652, yN = 0.459 },
        { xN = 0.644, yN = 0.471 },
        { xN = 0.636, yN = 0.478 },
        { xN = 0.632, yN = 0.482 },
        { xN = 0.627, yN = 0.498 },
        { xN = 0.619, yN = 0.504 },
        { xN = 0.616, yN = 0.515 },
        { xN = 0.614, yN = 0.523 },
        { xN = 0.597, yN = 0.552 },
        { xN = 0.582, yN = 0.560 },
        { xN = 0.579, yN = 0.575 },
        { xN = 0.574, yN = 0.579 },
        { xN = 0.566, yN = 0.579 },
        { xN = 0.564, yN = 0.588 },
        { xN = 0.562, yN = 0.603 },
        { xN = 0.552, yN = 0.602 },
        { xN = 0.542, yN = 0.606 },
        { xN = 0.537, yN = 0.604 },
        { xN = 0.516, yN = 0.601 },
        { xN = 0.507, yN = 0.603 },
        { xN = 0.504, yN = 0.602 },
        { xN = 0.497, yN = 0.588 },
        { xN = 0.491, yN = 0.586 },
        { xN = 0.488, yN = 0.578 },
        { xN = 0.491, yN = 0.574 },
        { xN = 0.492, yN = 0.569 },
        { xN = 0.488, yN = 0.563 },
        { xN = 0.480, yN = 0.558 },
        { xN = 0.473, yN = 0.548 },
        { xN = 0.464, yN = 0.536 },
        { xN = 0.460, yN = 0.527 },
        { xN = 0.461, yN = 0.522 },
        { xN = 0.456, yN = 0.503 },
        { xN = 0.451, yN = 0.501 },
        { xN = 0.445, yN = 0.484 },
        { xN = 0.436, yN = 0.481 },
        { xN = 0.418, yN = 0.449 },
        { xN = 0.420, yN = 0.436 },
        { xN = 0.432, yN = 0.418 },
        { xN = 0.438, yN = 0.413 },
        { xN = 0.441, yN = 0.408 },
        { xN = 0.443, yN = 0.400 },        
      }
    }),

    -- Gold Coast --
    [390] = { xN = 0.304, yN = 0.559 }, -- Depths of Malatar Dungeon 

    zoneData = hackyJoin({
      zoneName = "Gold Coast",
      zoneID = 1006,
      xN = "0.291",
      yN = "0.524",
      zonePolygonData = {
        { xN = 0.384, yN = 0.574 },
        { xN = 0.380, yN = 0.562 },
        { xN = 0.383, yN = 0.557 },
        { xN = 0.378, yN = 0.540 },
        { xN = 0.380, yN = 0.536 },
        { xN = 0.377, yN = 0.532 },
        { xN = 0.360, yN = 0.531 },
        { xN = 0.357, yN = 0.537 },
        { xN = 0.344, yN = 0.542 },
        { xN = 0.335, yN = 0.544 },
        { xN = 0.331, yN = 0.541 },
        { xN = 0.329, yN = 0.536 },
        { xN = 0.321, yN = 0.533 },
        { xN = 0.321, yN = 0.525 },
        { xN = 0.318, yN = 0.525 },
        { xN = 0.309, yN = 0.531 },
        { xN = 0.303, yN = 0.539 },
        { xN = 0.302, yN = 0.553 },
        { xN = 0.299, yN = 0.559 },
        { xN = 0.301, yN = 0.564 },
        { xN = 0.307, yN = 0.564 },
        { xN = 0.308, yN = 0.570 },
        { xN = 0.308, yN = 0.575 },
        { xN = 0.312, yN = 0.581 },
        { xN = 0.317, yN = 0.580 },
        { xN = 0.323, yN = 0.582 },
        { xN = 0.326, yN = 0.580 },
        { xN = 0.330, yN = 0.585 },
        { xN = 0.331, yN = 0.592 },
        { xN = 0.333, yN = 0.595 },
        { xN = 0.362, yN = 0.591 },
        { xN = 0.383, yN = 0.576 },      
      }
    }),


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

    -- Balfiera --
    zoneData = hackyJoin({
      zoneName = "Balfiera",
      zoneID = 1997,
      xN = "0.136",
      yN = "0.331",
      zonePolygonData = {
        { xN = 0.137, yN = 0.341 },
        { xN = 0.142, yN = 0.345 },
        { xN = 0.143, yN = 0.350 },
        { xN = 0.158, yN = 0.354 },
        { xN = 0.159, yN = 0.343 },
        { xN = 0.152, yN = 0.340 },
        { xN = 0.149, yN = 0.342 },
        { xN = 0.139, yN = 0.336 },
      }
    }),


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

    zoneData = hackyJoin({
      zoneName = "Vvardenfell",
      zoneID = 1060,
      xN = "0.646",
      yN = "0.221",
      zonePolygonData = {
        { xN = 0.712, yN = 0.218 },
        { xN = 0.710, yN = 0.223 },
        { xN = 0.712, yN = 0.228 },
        { xN = 0.709, yN = 0.233 },
        { xN = 0.704, yN = 0.232 },
        { xN = 0.700, yN = 0.238 },
        { xN = 0.691, yN = 0.249 },
        { xN = 0.671, yN = 0.263 },
        { xN = 0.660, yN = 0.270 },
        { xN = 0.649, yN = 0.272 },
        { xN = 0.649, yN = 0.276 },
        { xN = 0.654, yN = 0.281 },
        { xN = 0.664, yN = 0.296 },
        { xN = 0.675, yN = 0.312 },
        { xN = 0.681, yN = 0.333 },
        { xN = 0.682, yN = 0.352 },
        { xN = 0.688, yN = 0.367 },
        { xN = 0.691, yN = 0.376 },
        { xN = 0.698, yN = 0.379 },
        { xN = 0.701, yN = 0.387 },
        { xN = 0.713, yN = 0.395 },
        { xN = 0.725, yN = 0.408 },
        { xN = 0.730, yN = 0.413 },
        { xN = 0.747, yN = 0.413 },
        { xN = 0.757, yN = 0.415 },
        { xN = 0.772, yN = 0.408 },
        { xN = 0.783, yN = 0.405 },
        { xN = 0.797, yN = 0.414 },
        { xN = 0.805, yN = 0.413 },
        { xN = 0.805, yN = 0.399 },
        { xN = 0.808, yN = 0.391 },
        { xN = 0.817, yN = 0.388 },
        { xN = 0.822, yN = 0.389 },
        { xN = 0.829, yN = 0.384 },
        { xN = 0.825, yN = 0.343 },
        { xN = 0.829, yN = 0.343 },
        { xN = 0.832, yN = 0.322 },
        { xN = 0.831, yN = 0.316 },
        { xN = 0.820, yN = 0.305 },
        { xN = 0.812, yN = 0.296 },
        { xN = 0.803, yN = 0.294 },
        { xN = 0.802, yN = 0.286 },
        { xN = 0.801, yN = 0.281 },
        { xN = 0.797, yN = 0.274 },
        { xN = 0.801, yN = 0.271 },
        { xN = 0.797, yN = 0.262 },
        { xN = 0.787, yN = 0.262 },
        { xN = 0.786, yN = 0.248 },
        { xN = 0.788, yN = 0.243 },
        { xN = 0.786, yN = 0.234 },
        { xN = 0.768, yN = 0.234 },
        { xN = 0.758, yN = 0.219 },
        { xN = 0.736, yN = 0.219 },
        { xN = 0.715, yN = 0.217 },
        { xN = 0.710, yN = 0.220 },
      }
    }),

    -- Firemoth Island --
    zoneData = hackyJoin({
      zoneName = "Firemoth Island",
      zoneID = 1248,
      xN = "0.674",
      yN = "0.3815",
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

    -- Stonefalls --
    zoneData = hackyJoin({
      zoneName = "Stonefalls",
      zoneID = 7,
      xN = "0.668",
      yN = "0.380",
      zonePolygonData = {
        { xN = 0.678, yN = 0.406 },
        { xN = 0.682, yN = 0.405 },
        { xN = 0.688, yN = 0.400 },
        { xN = 0.697, yN = 0.398 },
        { xN = 0.702, yN = 0.403 },
        { xN = 0.707, yN = 0.407 },
        { xN = 0.711, yN = 0.406 },
        { xN = 0.711, yN = 0.412 },
        { xN = 0.720, yN = 0.419 },
        { xN = 0.719, yN = 0.426 },
        { xN = 0.717, yN = 0.433 },
        { xN = 0.715, yN = 0.437 },
        { xN = 0.726, yN = 0.448 },
        { xN = 0.731, yN = 0.447 },
        { xN = 0.736, yN = 0.441 },
        { xN = 0.732, yN = 0.433 },
        { xN = 0.733, yN = 0.428 },
        { xN = 0.738, yN = 0.423 },
        { xN = 0.743, yN = 0.428 },
        { xN = 0.746, yN = 0.435 },
        { xN = 0.764, yN = 0.425 },
        { xN = 0.773, yN = 0.420 },
        { xN = 0.781, yN = 0.419 },
        { xN = 0.793, yN = 0.423 },
        { xN = 0.796, yN = 0.428 },
        { xN = 0.797, yN = 0.434 },
        { xN = 0.795, yN = 0.438 },
        { xN = 0.795, yN = 0.443 },
        { xN = 0.794, yN = 0.447 },
        { xN = 0.794, yN = 0.453 },
        { xN = 0.796, yN = 0.454 },
        { xN = 0.786, yN = 0.461 },
        { xN = 0.783, yN = 0.467 },
        { xN = 0.783, yN = 0.475 },
        { xN = 0.773, yN = 0.478 },
        { xN = 0.764, yN = 0.479 },
        { xN = 0.751, yN = 0.487 },
        { xN = 0.745, yN = 0.485 },
        { xN = 0.737, yN = 0.488 },
        { xN = 0.730, yN = 0.489 },
        { xN = 0.720, yN = 0.486 },
        { xN = 0.701, yN = 0.491 },
        { xN = 0.695, yN = 0.485 },
        { xN = 0.685, yN = 0.484 },
        { xN = 0.679, yN = 0.473 },
        { xN = 0.674, yN = 0.471 },
        { xN = 0.672, yN = 0.463 },
        { xN = 0.668, yN = 0.460 },
        { xN = 0.668, yN = 0.453 },
        { xN = 0.671, yN = 0.449 },
        { xN = 0.668, yN = 0.440 },
        { xN = 0.669, yN = 0.436 },
        { xN = 0.674, yN = 0.431 },
        { xN = 0.675, yN = 0.426 },
        { xN = 0.675, yN = 0.415 },
        { xN = 0.677, yN = 0.406 },        
      }
    }),

    -- Bal Foyen --
    zoneData = hackyJoin({
      zoneName = "Bal Foyen",
      zoneID = 75,
      xN = "0.795",
      yN = "0.428",
      zonePolygonData = {
        { xN = 0.796, yN = 0.454 },
        { xN = 0.802, yN = 0.459 },
        { xN = 0.810, yN = 0.461 },
        { xN = 0.818, yN = 0.456 },
        { xN = 0.821, yN = 0.448 },
        { xN = 0.827, yN = 0.442 },
        { xN = 0.821, yN = 0.438 },
        { xN = 0.818, yN = 0.432 },
        { xN = 0.814, yN = 0.430 },
        { xN = 0.807, yN = 0.433 },
        { xN = 0.798, yN = 0.429 },
        { xN = 0.797, yN = 0.435 },
        { xN = 0.795, yN = 0.440 },
        { xN = 0.797, yN = 0.444 },
        { xN = 0.795, yN = 0.450 },
        { xN = 0.795, yN = 0.452 },        
      }
    }),

    -- Deshaan --
    zoneData = hackyJoin({
      zoneName = "Deshaan",
      zoneID = 13,
      xN = "0.699",
      yN = "0.430",
      zonePolygonData = {
        { xN = 0.701, yN = 0.493 },
        { xN = 0.697, yN = 0.498 },
        { xN = 0.698, yN = 0.509 },
        { xN = 0.699, yN = 0.516 },
        { xN = 0.701, yN = 0.518 },
        { xN = 0.698, yN = 0.520 },
        { xN = 0.697, yN = 0.529 },
        { xN = 0.707, yN = 0.534 },
        { xN = 0.721, yN = 0.531 },
        { xN = 0.727, yN = 0.530 },
        { xN = 0.735, yN = 0.534 },
        { xN = 0.742, yN = 0.534 },
        { xN = 0.753, yN = 0.539 },
        { xN = 0.774, yN = 0.539 },
        { xN = 0.787, yN = 0.539 },
        { xN = 0.800, yN = 0.537 },
        { xN = 0.807, yN = 0.538 },
        { xN = 0.844, yN = 0.522 },
        { xN = 0.847, yN = 0.515 },
        { xN = 0.847, yN = 0.511 },
        { xN = 0.846, yN = 0.508 },
        { xN = 0.848, yN = 0.505 },
        { xN = 0.847, yN = 0.500 },
        { xN = 0.849, yN = 0.496 },
        { xN = 0.847, yN = 0.492 },
        { xN = 0.844, yN = 0.483 },
        { xN = 0.837, yN = 0.480 },
        { xN = 0.828, yN = 0.477 },
        { xN = 0.822, yN = 0.476 },
        { xN = 0.815, yN = 0.478 },
        { xN = 0.804, yN = 0.480 },
        { xN = 0.799, yN = 0.474 },
        { xN = 0.792, yN = 0.471 },
        { xN = 0.784, yN = 0.475 },
        { xN = 0.778, yN = 0.479 },
        { xN = 0.768, yN = 0.481 },
        { xN = 0.762, yN = 0.481 },
        { xN = 0.750, yN = 0.488 },
        { xN = 0.745, yN = 0.488 },
        { xN = 0.740, yN = 0.490 },
        { xN = 0.731, yN = 0.490 },
        { xN = 0.724, yN = 0.489 },
        { xN = 0.719, yN = 0.489 },
        { xN = 0.713, yN = 0.491 },
        { xN = 0.706, yN = 0.492 },
        { xN = 0.702, yN = 0.493 },
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

    zoneData = hackyJoin({
      zoneName = "Shadowfen",
      zoneID = 26,
      xN = "0.689",
      yN = "0.561",
      zonePolygonData = {
        { xN = 0.692, yN = 0.653 },
        { xN = 0.691, yN = 0.646 },
        { xN = 0.705, yN = 0.605 },
        { xN = 0.705, yN = 0.586 },
        { xN = 0.712, yN = 0.573 },
        { xN = 0.718, yN = 0.567 },
        { xN = 0.750, yN = 0.575 },
        { xN = 0.775, yN = 0.576 },
        { xN = 0.785, yN = 0.581 },
        { xN = 0.793, yN = 0.598 },
        { xN = 0.797, yN = 0.615 },
        { xN = 0.797, yN = 0.619 },
        { xN = 0.804, yN = 0.626 },
        { xN = 0.804, yN = 0.651 },
        { xN = 0.796, yN = 0.657 },
        { xN = 0.779, yN = 0.659 },
        { xN = 0.693, yN = 0.654 },
      }
    }),

    -- Murkmire --
    [376] = { xN = 0.703, yN = 0.754 }, -- Dead-Water Wayshrine 
    [378] = { xN = 0.712, yN = 0.769 }, -- Blackrose Prison Dungeon
    [379] = { xN = 0.725, yN = 0.780 }, -- Blackrose Prison Wayshrine 
    [375] = { xN = 0.755, yN = 0.782 }, -- Bright-Throat Wayshrine 
    [377] = { xN = 0.758, yN = 0.739 }, -- Root-Whisper Wayshrine
    [388] = { xN = 0.724, yN = 0.735 }, -- Lakemire Xanmeer Manor House 

    zoneData = hackyJoin({
      zoneName = "Murkmire",
      zoneID = 1484,
      xN = "0.677",
      yN = "0.720",
      zonePolygonData = {
        { xN = 0.682, yN = 0.752 },
        { xN = 0.686, yN = 0.748 },
        { xN = 0.694, yN = 0.744 },
        { xN = 0.699, yN = 0.739 },
        { xN = 0.704, yN = 0.739 },
        { xN = 0.708, yN = 0.738 },
        { xN = 0.711, yN = 0.733 },
        { xN = 0.721, yN = 0.725 },
        { xN = 0.727, yN = 0.721 },
        { xN = 0.731, yN = 0.721 },
        { xN = 0.739, yN = 0.727 },
        { xN = 0.749, yN = 0.729 },
        { xN = 0.757, yN = 0.728 },
        { xN = 0.771, yN = 0.730 },
        { xN = 0.768, yN = 0.739 },
        { xN = 0.766, yN = 0.746 },
        { xN = 0.762, yN = 0.746 },
        { xN = 0.765, yN = 0.760 },
        { xN = 0.762, yN = 0.765 },
        { xN = 0.759, yN = 0.764 },
        { xN = 0.759, yN = 0.767 },
        { xN = 0.764, yN = 0.771 },
        { xN = 0.763, yN = 0.779 },
        { xN = 0.767, yN = 0.780 },
        { xN = 0.774, yN = 0.778 },
        { xN = 0.778, yN = 0.780 },
        { xN = 0.782, yN = 0.792 },
        { xN = 0.784, yN = 0.799 },
        { xN = 0.782, yN = 0.806 },
        { xN = 0.769, yN = 0.811 },
        { xN = 0.758, yN = 0.807 },
        { xN = 0.748, yN = 0.804 },
        { xN = 0.745, yN = 0.806 },
        { xN = 0.738, yN = 0.804 },
        { xN = 0.734, yN = 0.800 },
        { xN = 0.722, yN = 0.793 },
        { xN = 0.718, yN = 0.795 },
        { xN = 0.704, yN = 0.787 },
        { xN = 0.704, yN = 0.780 },
        { xN = 0.698, yN = 0.780 },
        { xN = 0.689, yN = 0.770 },
        { xN = 0.685, yN = 0.766 },
        { xN = 0.685, yN = 0.759 },
        { xN = 0.683, yN = 0.753 },        
      }
    }),

    -- Norg-Tzel --
    zoneData = hackyJoin({
      zoneName = "Norg-Tzel",
      zoneID = 1552,
      xN = "0.792",
      yN = "0.791",
      zonePolygonData = {
        { xN = 0.798, yN = 0.799 },
        { xN = 0.803, yN = 0.807 },
        { xN = 0.815, yN = 0.804 },
        { xN = 0.814, yN = 0.799 },
        { xN = 0.807, yN = 0.796 },
        { xN = 0.804, yN = 0.790 },
        { xN = 0.798, yN = 0.794 },
        { xN = 0.797, yN = 0.796 },        
      }
    }),

    -- Blackwood --
    [462] = { xN = 0.671, yN = 0.631 }, -- Bloodrun Wayshrine 
    [483] = { xN = 0.673, yN = 0.657 }, -- Hutan-Tzel Wayshrine
    [459] = { xN = 0.654, yN = 0.680 }, -- Gideon Wayshrine 
    [464] = { xN = 0.662, yN = 0.721 }, -- Stonewastes Wayshrine
    [484] = { xN = 0.688, yN = 0.714 }, -- Vunalk Wayshrine
    [468] = { xN = 0.684, yN = 0.742 }, -- Rockgrove Trial
    [473] = { xN = 0.687, yN = 0.624 }, -- Pantherfang Chapel House 
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

    zoneData = hackyJoin({
      zoneName = "Blackwood",
      zoneID = 1887,
      xN = "0.581",
      yN = "0.594",
      zonePolygonData = {
        { xN = 0.593, yN = 0.708 },
        { xN = 0.583, yN = 0.696 },
        { xN = 0.582, yN = 0.690 },
        { xN = 0.586, yN = 0.681 },
        { xN = 0.587, yN = 0.675 },
        { xN = 0.585, yN = 0.656 },
        { xN = 0.583, yN = 0.650 },
        { xN = 0.585, yN = 0.646 },
        { xN = 0.588, yN = 0.637 },
        { xN = 0.589, yN = 0.628 },
        { xN = 0.601, yN = 0.631 },
        { xN = 0.608, yN = 0.631 },
        { xN = 0.612, yN = 0.627 },
        { xN = 0.615, yN = 0.620 },
        { xN = 0.618, yN = 0.609 },
        { xN = 0.623, yN = 0.599 },
        { xN = 0.628, yN = 0.598 },
        { xN = 0.636, yN = 0.605 },
        { xN = 0.646, yN = 0.609 },
        { xN = 0.660, yN = 0.607 },
        { xN = 0.675, yN = 0.613 },
        { xN = 0.683, yN = 0.617 },
        { xN = 0.687, yN = 0.620 },
        { xN = 0.697, yN = 0.620 },
        { xN = 0.693, yN = 0.633 },
        { xN = 0.690, yN = 0.641 },
        { xN = 0.691, yN = 0.654 },
        { xN = 0.693, yN = 0.661 },
        { xN = 0.695, yN = 0.665 },
        { xN = 0.692, yN = 0.676 },
        { xN = 0.691, yN = 0.680 },
        { xN = 0.694, yN = 0.688 },
        { xN = 0.700, yN = 0.691 },
        { xN = 0.702, yN = 0.701 },
        { xN = 0.700, yN = 0.705 },
        { xN = 0.704, yN = 0.711 },
        { xN = 0.707, yN = 0.716 },
        { xN = 0.706, yN = 0.722 },
        { xN = 0.704, yN = 0.725 },
        { xN = 0.711, yN = 0.732 },
        { xN = 0.706, yN = 0.739 },
        { xN = 0.698, yN = 0.738 },
        { xN = 0.694, yN = 0.743 },
        { xN = 0.683, yN = 0.750 },
        { xN = 0.682, yN = 0.752 },
        { xN = 0.674, yN = 0.747 },
        { xN = 0.669, yN = 0.748 },
        { xN = 0.664, yN = 0.747 },
        { xN = 0.651, yN = 0.744 },
        { xN = 0.653, yN = 0.738 },
        { xN = 0.650, yN = 0.731 },
        { xN = 0.642, yN = 0.723 },
        { xN = 0.638, yN = 0.714 },
        { xN = 0.633, yN = 0.714 },
        { xN = 0.631, yN = 0.719 },
        { xN = 0.624, yN = 0.720 },
        { xN = 0.622, yN = 0.716 },
        { xN = 0.614, yN = 0.713 },
        { xN = 0.603, yN = 0.701 },
        { xN = 0.594, yN = 0.707 },        
      }
    }),


    -- Grand Topal Hideaway --
    [325] = { xN = 0.641, yN = 0.738 }, -- Grand Topal Hideaway House


    -- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
    -- ██░▄▄▄██░█████░▄▄▄░██░███░██░▄▄▄██░███░██░▄▄▀██
    -- ██░▄▄▄██░█████▄▄▄▀▀██░█░█░██░▄▄▄██▄▀▀▀▄██░▀▀▄██
    -- ██░▀▀▀██░▀▀░██░▀▀▀░██▄▀▄▀▄██░▀▀▀████░████░██░██
    -- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    -- [x] = { xN = x, yN = y }, -- 

    -- Northern Elsweyr --
    zoneData = hackyJoin({
      zoneName = "Anequina",
      zoneID = 1555,
      xN = "0.451",
      yN = "0.605",
      zonePolygonData = {
        { xN = 0.584, yN = 0.654 },
        { xN = 0.582, yN = 0.651 },
        { xN = 0.585, yN = 0.645 },
        { xN = 0.586, yN = 0.635 },
        { xN = 0.590, yN = 0.628 },
        { xN = 0.589, yN = 0.622 },
        { xN = 0.581, yN = 0.619 },
        { xN = 0.580, yN = 0.608 },
        { xN = 0.562, yN = 0.604 },
        { xN = 0.553, yN = 0.603 },
        { xN = 0.542, yN = 0.608 },
        { xN = 0.529, yN = 0.604 },
        { xN = 0.516, yN = 0.603 },
        { xN = 0.509, yN = 0.603 },
        { xN = 0.504, yN = 0.602 },
        { xN = 0.501, yN = 0.608 },
        { xN = 0.498, yN = 0.614 },
        { xN = 0.496, yN = 0.614 },
        { xN = 0.487, yN = 0.627 },
        { xN = 0.482, yN = 0.632 },
        { xN = 0.477, yN = 0.634 },
        { xN = 0.474, yN = 0.639 },
        { xN = 0.472, yN = 0.643 },
        { xN = 0.471, yN = 0.648 },
        { xN = 0.466, yN = 0.651 },
        { xN = 0.463, yN = 0.661 },
        { xN = 0.457, yN = 0.661 },
        { xN = 0.455, yN = 0.665 },
        { xN = 0.446, yN = 0.671 },
        { xN = 0.450, yN = 0.675 },
        { xN = 0.452, yN = 0.685 },
        { xN = 0.453, yN = 0.692 },
        { xN = 0.456, yN = 0.694 },
        { xN = 0.462, yN = 0.695 },
        { xN = 0.466, yN = 0.699 },
        { xN = 0.473, yN = 0.700 },
        { xN = 0.484, yN = 0.700 },
        { xN = 0.487, yN = 0.702 },
        { xN = 0.495, yN = 0.704 },
        { xN = 0.508, yN = 0.698 },
        { xN = 0.514, yN = 0.699 },
        { xN = 0.522, yN = 0.691 },
        { xN = 0.528, yN = 0.687 },
        { xN = 0.532, yN = 0.689 },
        { xN = 0.540, yN = 0.689 },
        { xN = 0.549, yN = 0.686 },
        { xN = 0.553, yN = 0.681 },
        { xN = 0.553, yN = 0.676 },
        { xN = 0.555, yN = 0.672 },
        { xN = 0.561, yN = 0.670 },
        { xN = 0.572, yN = 0.657 },
        { xN = 0.584, yN = 0.655 },
        { xN = 0.583, yN = 0.650 },
        { xN = 0.585, yN = 0.643 },
        { xN = 0.587, yN = 0.634 },
      }
    }),

    -- Southern Elsweyr --
    [407] = { xN = 0.614, yN = 0.790 }, -- Dragonguard Sanctum Wayshrine

    zoneData = hackyJoin({
      zoneName = "Quin'rawl",
      zoneID = 1654,
      xN = "0.484",
      yN = "0.707",
      zonePolygonData = {
        { xN = 0.556, yN = 0.751 },
        { xN = 0.556, yN = 0.737 },
        { xN = 0.568, yN = 0.731 },
        { xN = 0.576, yN = 0.722 },
        { xN = 0.578, yN = 0.716 },
        { xN = 0.574, yN = 0.707 },
        { xN = 0.568, yN = 0.702 },
        { xN = 0.562, yN = 0.702 },
        { xN = 0.556, yN = 0.708 },
        { xN = 0.547, yN = 0.709 },
        { xN = 0.539, yN = 0.706 },
        { xN = 0.531, yN = 0.712 },
        { xN = 0.520, yN = 0.716 },
        { xN = 0.509, yN = 0.728 },
        { xN = 0.505, yN = 0.734 },
        { xN = 0.508, yN = 0.745 },
        { xN = 0.507, yN = 0.748 },
        { xN = 0.511, yN = 0.759 },
        { xN = 0.511, yN = 0.762 },
        { xN = 0.505, yN = 0.763 },
        { xN = 0.505, yN = 0.766 },
        { xN = 0.504, yN = 0.770 },
        { xN = 0.500, yN = 0.772 },
        { xN = 0.502, yN = 0.775 },
        { xN = 0.505, yN = 0.779 },
        { xN = 0.510, yN = 0.779 },
        { xN = 0.512, yN = 0.778 },
        { xN = 0.519, yN = 0.781 },
        { xN = 0.526, yN = 0.785 },
        { xN = 0.531, yN = 0.786 },
        { xN = 0.534, yN = 0.787 },
        { xN = 0.537, yN = 0.790 },
        { xN = 0.540, yN = 0.795 },
        { xN = 0.543, yN = 0.797 },
        { xN = 0.546, yN = 0.796 },
        { xN = 0.556, yN = 0.791 },
        { xN = 0.568, yN = 0.789 },
        { xN = 0.576, yN = 0.787 },
        { xN = 0.582, yN = 0.795 },
        { xN = 0.589, yN = 0.795 },
        { xN = 0.614, yN = 0.802 },
        { xN = 0.626, yN = 0.786 },
        { xN = 0.612, yN = 0.782 },
        { xN = 0.592, yN = 0.777 },
        { xN = 0.586, yN = 0.771 },
        { xN = 0.578, yN = 0.764 },
        { xN = 0.567, yN = 0.753 },
        { xN = 0.554, yN = 0.751 },        
      }
    }),


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
    [371] = { xN = 0.450, yN = 0.560 }, -- Moon Hunter Keep Dungeon
    [321] = { xN = 0.483, yN = 0.579 }, -- Dawnshadow House
    [320] = { xN = 0.472, yN = 0.560 }, -- Strident Springs Demesne House

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
    [215] = { xN = 0.070, yN = 0.600 }, -- Eyevea Wayshrine

    zoneData = hackyJoin({
      zoneName = "Eyevea",
      zoneID = 108,
      xN = "0.054",
      yN = "0.592",
      zonePolygonData = {
        { xN = 0.061, yN = 0.607 },
        { xN = 0.059, yN = 0.604 },
        { xN = 0.059, yN = 0.596 },
        { xN = 0.062, yN = 0.590 },
        { xN = 0.068, yN = 0.589 },
        { xN = 0.077, yN = 0.590 },
        { xN = 0.080, yN = 0.596 },
        { xN = 0.082, yN = 0.603 },
        { xN = 0.079, yN = 0.608 },
        { xN = 0.065, yN = 0.609 },           
      }
    }),

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
    if (not enabled) then 
      return tex 
    end
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


-- * WouldProcessMapClick(*number* _normalizedClickX_, *number* _normalizedClickY_)
-- ** _Returns:_ *bool* _wouldProcess_, *luaindex:nilable* _resultingMapIndex_


-- local zos_GetNormalisedOffsetAndZoom = GetNormalizedPositionFocusZoomAndOffset
-- GetNormalizedPositionFocusZoomAndOffset = function(normalizedX, normalizedY, useCurrentZoom)

--   local targetNormalizedZoom, offsetX, offsetY = zos_GetNormalisedOffsetAndZoom(normalizedX, normalizedY, useCurrentZoom)


--   print(tostring(offsetX))
--   print(tostring(offsetY))


--   return targetNormalizedZoom, offsetX, offsetY
-- end


local zos_WouldProcessMapClick = WouldProcessMapClick
WouldProcessMapClick = function(xN, yN)
  local wouldProcess, resultingMapIndex = zos_WouldProcessMapClick(xN, yN)

  -- check if we are currently hovering over a custom polygon
  if (isInBlobHitbox and currentZoneInfo ~= nil) then
    wouldProcess = false
    resultingMapIndex = GetMapIndexByZoneId(currentZoneInfo.zoneID)
  end

  if (isExclusive) then
    wouldProcess = false
    resultingMapIndex = nil
  end

  return wouldProcess, resultingMapIndex
end


-- * ProcessMapClick(*number* _normalizedClickX_, *number* _normalizedClickY_)
-- ** _Returns:_ *[SetMapResultCode|#SetMapResultCode]* _setMapResult_

local zos_ProcessMapClick = ProcessMapClick
ProcessMapClick = function(xN, yN)

  local setMapResult = zos_ProcessMapClick(xN, yN)

    -- check if we are currently hovering over a custom polygon
    if (isInBlobHitbox and currentZoneInfo ~= nil) then
      setMapResult = SET_MAP_RESULT_FAILED
    end
  
    if (isExclusive) then
      setMapResult = SET_MAP_RESULT_FAILED
    end

  return setMapResult

end

local zos_GetMapMouseoverInfo = GetMapMouseoverInfo
GetMapMouseoverInfo = function(xN, yN)


  -- local targetNormalizedZoom, offsetX, offsetY = ZO_MapPanAndZoom:GetNormalizedPositionFocusZoomAndOffset(xN, yN, true)


  -- print("Target offset X:"..offsetX.." Target offsetY:"..offsetY)



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
    

-- function to check if the mouse cursor is within or over the map window
local function isMouseWithinMapWindow()
  local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
  return (not ZO_WorldMapContainer:IsHidden() and (mouseOverControl == ZO_WorldMapContainer or mouseOverControl:GetParent() == ZO_WorldMapContainer))
end

local function onMousePressed()

  if isMouseWithinMapWindow() then

    if (recordCoordinates) then 
      PlaySound(SOUNDS.COUNTDOWN_TICK)

      table.insert(newPolygonData, {xN = normalisedMouseX, yN = normalisedMouseY})
      currentCoordinateCount = currentCoordinateCount + 1

    end

    print("Map clicked!")
  end

  if IsControlKeyDown() then
    print("ctrl + click")
  end


end




local function getWorldMapOffsets()

  local currentOffsetX =  math.floor(ZO_WorldMapContainer:GetLeft())
  local currentOffsetY = math.floor(ZO_WorldMapContainer:GetTop())

  return currentOffsetX, currentOffsetY

end


local function mapTick()

  local mouseX, mouseY = GetUIMousePosition()

  local currentOffsetX = ZO_WorldMapContainer:GetLeft()
  local currentOffsetY = ZO_WorldMapContainer:GetTop()
  local parentOffsetX = ZO_WorldMap:GetLeft()
  local parentOffsetY = ZO_WorldMap:GetTop()
  local mapWidth, mapHeight = ZO_WorldMapContainer:GetDimensions()
  local parentWidth, parentHeight = ZO_WorldMap:GetDimensions()

  --print(currentOffsetX.." "..currentOffsetY)

  normalisedMouseX = math.floor((((mouseX - currentOffsetX) / mapWidth) * 1000) + 0.5)/1000
  normalisedMouseY = math.floor((((mouseY - currentOffsetY) / mapHeight) * 1000) + 0.5)/1000









  if (currentPolygon ~= nil) then

    -- check to make sure that the user has actually left the hitbox, and is not just hovering over a wayshrine
    if (currentPolygon:IsPointInside(mouseX , mouseY) and currentMapIndex == GetCurrentMapIndex()) then

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


    local polygonCode = ""

    if (isDebug) then
      AWM_EditTextWindow:SetHidden(false)
    end


    for key, data in pairs(polygonData) do

      if (isDebug) then
        polygonCode = polygonCode .. ("{ xN = "..string.format("%.03f", data.xN)..", yN = "..string.format("%.03f", data.yN).." },\n")  
      end


      print(tostring("Coordinate set "..key .. ": "))
  
      print("X: "..tostring(data.xN))
      print("Y: "..tostring(data.yN))
  
  
      polygon:AddPoint(data.xN, data.yN)
  
  
    end

    if (isDebug) then
      AWM_EditTextTextBox:SetText(polygonCode)
    end



  
  
    if (isDebug) then
      polygon:SetCenterColor(0, 1, 0, 0.5)
    else
      polygon:SetCenterColor(0, 0, 0, 0)
    end
    
    polygon:SetMouseEnabled(true)
    polygon:SetHandler("OnMouseDown", function(control, button, ctrl, alt, shift, command)

      if (waitForRelease == false) then
        currentMapOffsetX, currentMapOffsetY = getWorldMapOffsets()
        waitForRelease = true
      end


      currentPolygon = polygon
      ZO_WorldMap_MouseDown(button, ctrl, alt, shift)    
    end)

    polygon:SetHandler("OnMouseUp", function(control, button, upInside, ctrl, alt, shift, command)
      
      ZO_WorldMap_MouseUp(control, button, upInside)



      if (currentZoneInfo ~= nil and upInside and button == MOUSE_BUTTON_INDEX_LEFT) then

        if (waitForRelease) then

          local mapOffsetX, mapOffsetY = getWorldMapOffsets()

          local deltaX, deltaY


          if (mapOffsetX >= currentMapOffsetX) then
            deltaX = mapOffsetX - currentMapOffsetX
          else 
            deltaX = currentMapOffsetX - mapOffsetX
          end

          if (mapOffsetY >= currentMapOffsetY) then
            deltaY = mapOffsetY - currentMapOffsetY
          else 
            deltaY = currentMapOffsetY - mapOffsetY
          end

          print(tostring(deltaX))

          if (deltaX <= 10 and deltaX <= 10) then

            currentPolygon = nil
            isInBlobHitbox = false
      
            SetMapToMapId(currentZoneInfo.zoneID)
            currentZoneInfo = {}
            CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")

          end


        end


      end

      waitForRelease = false

    end)
      
      
      
  
    polygon:SetHandler("OnMouseEnter", function()

      currentMapIndex = GetCurrentMapIndex()
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
  providedZoneName = providedZoneName:gsub("-", "") -- replace all instances of ` ` with empty string

  providedZoneName = providedZoneName:lower()

  local blobFileDirectory = ("AccurateWorldMap/blobs/tamriel-"..providedZoneName..".dds")

  return blobFileDirectory
end




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
            AWM_TextureControl:SetTexture(textureDirectory)

            -- check if texture exists before doing stuff
            if (AWM_TextureControl:IsTextureLoaded()) then

              -- get the dimensions
              local textureHeight, textureWidth = AWM_TextureControl:GetTextureFileDimensions()

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


local function setMapTo(int)

  currentPolygon = nil
  isInBlobHitbox = false

  SetMapToMapId(int)
  currentZoneInfo = {}
  CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")

end





local function OnAddonLoaded(event, addonName)
  if addonName ~= addon.name then return end
  EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)




  


  getBlobTextureDetails()


  -- AccurateWorldMapTLC = CreateTopLevelWindow("AccurateWorldMapTLC")
  -- AccurateWorldMapTLC:SetResizeToFitDescendents(true) --will make the TLC window resize with it's childen -> the Tex01 texture control
  -- comment these two to hide the control
  --AccurateWorldMapTLC:SetAlpha(1)

  -- AccurateWorldMapPolyBoxTLC = CreateTopLevelWindow("AccurateWorldMapPolyBoxTLC")
	-- AccurateWorldMapPolyBox = WINDOW_MANAGER:CreateControlFromVirtual("AccurateWorldMapPolyBoxEdit", AccurateWorldMapPolyBoxTLC, "CT_EDITBOX")
	-- AccurateWorldMapPolyBox:SetMaxInputChars(3000)
  -- AccurateWorldMapPolyBox:SetText("ligma")




    
    






  SLASH_COMMANDS["/awm_debug"] = toggleDebugOutput
  SLASH_COMMANDS["/get_map_id"] = function() print(tostring(GetCurrentMapId())) end
  SLASH_COMMANDS["/zones_debug"] = initialise
  SLASH_COMMANDS["/record_polygon"] = recordPolygon
  SLASH_COMMANDS["/get_blobs"] = getBlobTextureDetails
  SLASH_COMMANDS["/get_controls"] = cleanUpZoneBlobs
  SLASH_COMMANDS["/set_map_to"] = setMapTo

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
EVENT_MANAGER:RegisterForEvent("onMouseDown", EVENT_GLOBAL_MOUSE_DOWN, onMousePressed)
EVENT_MANAGER:RegisterForUpdate("uniqueName", 0, checkIfCanTick)
CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", onZoneChanged)