-- define root addon object
local AWM = {
	name = "AccurateWorldMap",
	title = "Accurate World Map",
	version = "1.0",
	author = "|CFF0000Breaux|r & |C6b51faThal-J|r",
	defaults = {}, --put default variables here
}

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


-- Table of all the wayshrines we want to move, sorted by map (zone). Inner zone names are just for readability and do not actually affect zones themselves.
-- Some wayshrines have been renamed to be more consistent and lore friendly, this is denoted by the "name=blah" attribute.

-- Wayshrine template: |[x] = { xN = x, yN = y }, -- |

local globalWayshrines = {

  -- Tamriel Map --
  [1] = { 

    -- Bleakrock Isle --
    [172] = { xN = 0.613, yN = 0.236 }, -- Bleakrock Isle Wayshrine

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
    


    -- Western Skyrim --
    [424] = { xN = 0.403, yN = 0.156 }, -- Icereach Dungeon
    [434] = { xN = 0.408, yN = 0.186 }, -- Kyne's Aegis Trial



    -- Craglorn --
    [217] = { xN = 0.379, yN = 0.374 }, -- Seeker's Archive Wayshrine
    [341] = { xN = 0.405, yN = 0.348 }, -- Fang Lair Dungeon
    [225] = { xN = 0.392, yN = 0.377 }, -- Spellscar Wayshrine 
    [220] = { xN = 0.387, yN = 0.387 }, -- Belkarth Wayshrine 
    [326] = { xN = 0.410, yN = 0.394 }, -- Bloodroot Forge Dungeon 
    [226] = { xN = 0.401, yN = 0.359 }, -- Mountain Overlook Wayshrine 
    [227] = { xN = 0.421, yN = 0.367 }, -- Inazzur's Hold Wayshrine
    [229] = { xN = 0.420, yN = 0.382 }, -- Elinhir Wayshrine 
    [231] = { xN = 0.428, yN = 0.377 }, -- Aetherian Archive Trial 
    [332] = { xN = 0.449, yN = 0.357 }, -- Falkreath Hold Dungeon 
    [233] = { xN = 0.334, yN = 0.338 }, -- Dragonstar Wayshrine 
    [270] = { xN = 0.335, yN = 0.324 }, -- Dragonstar Arena Dungeon
    [219] = { xN = 0.354, yN = 0.373 }, -- Sandy Path Wayshrine
    [235] = { xN = 0.388, yN = 0.350 }, -- Valley of Scars Wayshrine 
    [218] = { xN = 0.344, yN = 0.353 }, -- Shada's Tear Wayshrine 
    [234] = { xN = 0.362, yN = 0.349 }, -- Skyreach Wayshrine 
    [230] = { xN = 0.344, yN = 0.377 }, -- Hel Ra Citadel Trial
    [232] = { xN = 0.366, yN = 0.330 }, -- Sanctum Ophidia Trial 



    
    -- Cyrodiil --
    [201] = { xN = 0.509, yN = 0.593, name = "Western Elsweyr Gate Wayshrine" }, -- Western Elsweyr Wayshrine
    [200] = { xN = 0.556, yN = 0.594, name = "Eastern Elsweyr Gate Wayshrine" }, -- Eastern Elsweyr Wayshrine
    [202] = { xN = 0.622, yN = 0.410, name = "Northern Morrowind Gate Wayshrine" }, -- Northern Morrowind Wayshrine
    [203] = { xN = 0.643, yN = 0.455, name = "Southern Morrowind Gate Wayshrine" }, -- Southern Morrowind Wayshrine
    [170] = { xN = 0.449, yN = 0.411, name = "Northern Hammerfell Gate Wayshrine" }, -- Northern Hammerfell Wayshrine
    [199] = { xN = 0.429, yN = 0.449, name = "Southern Hammerfell Gate Wayshrine" }, -- Southern Hammerfell Wayshrine

    [236] = { xN = 0.542, yN = 0.475 }, -- Imperial City Prison Dungeon
    [247] = { xN = 0.536, yN = 0.486 }, -- White Gold Tower Dungeon

  },

  -- Cyrodiil Map --
  [14] = {

    [202] = { name = "Northern Morrowind Gate Wayshrine" }, -- Northern Morrowind Wayshrine
    [203] = { name = "Southern Morrowind Gate Wayshrine" }, -- Southern Morrowind Wayshrine
    [170] = { name = "Northern Hammerfell Gate Wayshrine" }, -- Northern Hammerfell Wayshrine
    [199] = { name = "Southern Hammerfell Gate Wayshrine" }, -- Southern Hammerfell Wayshrine
    [200] = { name = "Eastern Elsweyr Gate Wayshrine" }, -- Eastern Elsweyr Wayshrine
    [201] = { name = "Western Elsweyr Gate Wayshrine" }, -- Western Elsweyr Wayshrine

    [236] = { xN = 0.523, yN = 0.382 }, -- Imperial City Prison Dungeon
    [247] = { xN = 0.497, yN = 0.428 }, -- White Gold Tower Dungeon
  },

  -- Western Skyrim Map --
  [38] = {
    [434] = { xN = 0.442, yN = 0.193 }, -- Kyne's Aegis
  }

  --TODO: add earthforge to the reach map as well

}
    
    

local enabled = true
local spoilers = false -- Set this to true if you want the map containing spoilers by default
local _GetMapTileTexture = GetMapTileTexture

local LAM = LibAddonMenu2
local saveData = {} -- TODO this should be a reference to your actual saved variables table
local panelName = "AWMvar" -- TODO the name will be used to create a global variable, pick something unique or you may overwrite an existing variable!

local panelData = {
    type = "panel",
    name = "Accurate World Map",
    author = "Breaux & Thal-J",
}

function AWM.log(text)
    d(text)
end


function AWM.GetMapTileTexture(index)
    local tex = _GetMapTileTexture(index)
    if not enabled then return tex end
    for i = 1, 16 do
        if tiles[i] == tex then
            ---- Replace certain tiles if you are on live server and have spoilers enabled
            --if GetAPIVersion() == 100035 and not spoilers and (i == 99) then
            --    i = tostring(i) .. "_spoilerfree"  
            --end
            return "AccurateWorldMap/tiles/tamriel_" .. i .. ".dds"
        end
    end
    return tex
end

local _GetMapCustomMaxZoom = GetMapCustomMaxZoom

local providedPoiType = 1

local function debugOutput(int)
  
  providedPoiType = tonumber(int)
  
  d(providedPoiType)
  
  if providedPoiType == nil then
    providedPoiType = 1
  end
  
  
  local totalNodes = GetNumFastTravelNodes()
  d("Total Fast Travel Nodes: "..totalNodes)
  local i = 1
  local zos_GetFastTravelNodeInfo = GetFastTravelNodeInfo
  
  
  while i <= totalNodes do
    
    GetFastTravelNodeInfo = function(nodeIndex)
      local known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked = zos_GetFastTravelNodeInfo(nodeIndex)

      if poiType == providedPoiType then
        d("Current Node: "..nodeIndex)
        d("Name: "..name)
        d(" ")
      end
      return known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked
    end
    
    
    GetFastTravelNodeInfo(i)
    
    
    i = i + 1
  end
  
end


local function printCurrentMapIndex()
  
  d("Current Map Index: "..GetCurrentMapIndex())
  
end

-- Function to add custom blobs to the map

local function YourCustomData(x, y)

  local locationName = "Eastmarch"
  local textureFile = "AccurateWorldMap/blobs/tamriel-eastmarch.dds"
  local normalisedWidth = 0.109375
  local normalisedHeight = 0.109375
  local normalisedX = 0.518
  local normalisedY = 0.233
  return locationName, textureFile, normalisedWidth, normalisedHeight, normalisedX, normalisedY

end


local function YourCustomData2(x, y)

  local locationName = "Glenumbra"
  local textureFile = "AccurateWorldMap/blobs/tamriel-glenumbra.dds"
  local normalisedWidth = 0.15625
  local normalisedHeight = 0.15625
  local normalisedX = 0.023
  local normalisedY = 0.265
  return locationName, textureFile, normalisedWidth, normalisedHeight, normalisedX, normalisedY

end





local function MoveZones()
  

  local originalGetMapMouseoverInfo = GetMapMouseoverInfo
  
  function GetMapMouseoverInfo(x, y)
    return YourCustomData(0.5, 0.5)
  end
  
  originalGetMapMouseoverInfo(0.5, 0.5)



  local zos_GetFastTravelNodeInfo = GetFastTravelNodeInfo    
  GetFastTravelNodeInfo = function(nodeIndex)
    local known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked = zos_GetFastTravelNodeInfo(nodeIndex)
    local disabled = false

    --d("Currently Selected Node: "..name.." ("..nodeIndex..")")

    if globalWayshrines[GetCurrentMapIndex()] ~= nil then

      mapIndex = GetCurrentMapIndex()

      if globalWayshrines[mapIndex][nodeIndex] ~= nil then

        if globalWayshrines[mapIndex][nodeIndex].xN ~= nil then
          normalizedX = globalWayshrines[mapIndex][nodeIndex].xN
        end

        if globalWayshrines[mapIndex][nodeIndex].yN ~= nil then
          normalizedY = globalWayshrines[mapIndex][nodeIndex].yN
        end

        if globalWayshrines[mapIndex][nodeIndex].name ~= nil then
          name = globalWayshrines[mapIndex][nodeIndex].name
        end

      end

    end


    return known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked, disabled

  end

end


  
    

    


    

    
    
--     -- Houses
    
--     if nodeIndex == 428 then -- Forgemaster Falls
--       normalizedX = 0.214
--       normalizedY = 0.250
--     end
    
--     if nodeIndex == 325 then -- Topal Hideaway
--       normalizedX = 0.627
--       normalizedY = 0.744
--     end
    
--   end
  
  

  

  --         zoneBlobData = {
--           texture = "AccurateWorldMap/blobs/tamriel-eastmarch.dds",
--           xN = 0.4,
--           yN = 0.4,
--         },
--         zonePolygonData = {
--           -- generate polygon based on texture? edge detection? (for each zone that would be slooow on startup)
--           -- way to move existing polygons? by zoneID?
--         },
--     },

-- };


-- local function parseWayshrines()

--   for mapID, mapData in pairs(zoneData) do
--     local wayshrines = mapData.wayshrines
    
--     if (wayshrines ~= nil) then
--       for wayshrineID, wayshrineData in pairs(wayshrines) do
--         globalWayshrines[wayshrineID] = wayshrineData
--       end
--     end
--   end
-- end




function AWM.GetMapCustomMaxZoom()
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
        name = "My First Checkbox",
        getFunc = function() return saveData.myValue end,
        setFunc = function(value) saveData.myValue = value end
    }
}

local function OnAddonLoaded(event, addonName)
    if addonName ~= AWM.name then return end
    EVENT_MANAGER:UnregisterForEvent(AWM.name, EVENT_ADD_ON_LOADED)

    MoveZones()


    
    SLASH_COMMANDS["/awm_debug"] = debugOutput
    SLASH_COMMANDS["/map_index"] = printCurrentMapIndex
    SLASH_COMMANDS["/zones_debug"] = MoveZones
    
    GetMapTileTexture = AWM.GetMapTileTexture
    GetMapCustomMaxZoom = AWM.GetMapCustomMaxZoom
    

end

-- register events

LAM:RegisterOptionControls(panelName, optionsData)
EVENT_MANAGER:RegisterForEvent(AWM.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
