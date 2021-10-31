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




-- Table of all zones & related data that we want to move
local zoneData = {

    -- Wayshrine template: [ [x] = { xN = x, yN = y }, -- ]

    -- if disabled = true, set normalised x and y to 0 and return disabled


    -- Eastmarch
    [13] = {  
        wayshrines = {
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
          --[97] = { disabled = true }, -- Skuldafn Wayshrine
          [195] = { xN = 0.621, yN = 0.320 }, -- Direfrost Keep Dungeon
          [389] = { xN = 0.552, yN = 0.281 } -- Frostvault Dungeon
        },        
        zoneBlobData = {
          texture = "AccurateWorldMap/blobs/tamriel-eastmarch.dds",
          xN = 0.4,
          yN = 0.4,
        },
        zonePolygonData = {
          -- generate polygon based on texture? edge detection? (for each zone that would be slooow on startup)
          -- way to move existing polygons? by zoneID?
        },
    },

};

local globalWayshrines = {}

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


local function parseWayshrines()

  for mapID, mapData in pairs(zoneData) do
    local wayshrines = mapData.wayshrines
    
    if (wayshrines ~= nil) then
      for wayshrineID, wayshrineData in pairs(wayshrines) do
        globalWayshrines[wayshrineID] = wayshrineData
      end
    end
  end
end



-- upon loading a map, eso iterates through GetFastTravelInfo and loads all the wayshrine data
-- you need to go through your wayshrine list in the order that it is being iterated through
-- to do this, you need to compile all of your wayshrines in order, from 1 to 400 odd
-- this means you need an init function that parses your zonedata Wayshrine stuff
-- and adds it to a new global wayshrine object in the order that getfasttravelnodes is iterated through
-- so you will need to sort the list too
-- then in the getfasttravelinfo function, simply do (does globalwayshrine[nodeIndex] exist? if so, load the data)

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

    
    
    if globalWayshrines[nodeIndex] ~= nil then
      normalizedX = globalWayshrines[nodeIndex].xN
      normalizedY = globalWayshrines[nodeIndex].yN
    end


    -- for id, data in pairs(globalWayshrines) do
    --   d(id)
    -- end

    if nodeIndex == 424 then -- Icereach
      normalizedX = 0.403
      normalizedY = 0.156
    end

    --d("Test")

    --d(nodeIndex)


    -- if (not wayshrineData.disabled) 
    --   then


    --   else
    --   normalisedX = 0
    --   normalisedY = 0
    --   disabled = true

    -- end

    return known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked, disabled

  end

end

-- GetFastTravelNodeInfo = function(nodeIndex)
-- 	local known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked = zos_GetFastTravelNodeInfo(nodeIndex)
-- 	local disabled = false
  
  
--   if GetCurrentMapIndex() == 1 then -- Check to see if we are inside the Tamriel map

--     -- Cyrodiil --
    
--     if nodeIndex == 201 then --Western Elsweyr Wayshrine
--       normalizedX = 0.509
--       normalizedY = 0.593
--       name = "Western Elsweyr Gate Wayshrine"
--     end
    
--     if nodeIndex == 200 then --Eastern Elsweyr Wayshrine
--       normalizedX = 0.556
--       normalizedY = 0.594
--       name = "Eastern Elsweyr Gate Wayshrine"
--     end
    
--     if nodeIndex == 202 then --Northern Morrowind Wayshrine
--       normalizedX = 0.622
--       normalizedY = 0.410
--       name = "Northern Morrowind Gate Wayshrine"
--     end
    
--     if nodeIndex == 203 then --Southern Morrowind Wayshrine
--       normalizedX = 0.643
--       normalizedY = 0.455
--       name = "Southern Morrowind Gate Wayshrine"
--     end
    
--     if nodeIndex == 170 then --Northern Hammerfell Wayshrine
--       normalizedX = 0.449
--       normalizedY = 0.411
--       name = "Northern Hammerfell Gate Wayshrine"
--     end
    
--     if nodeIndex == 199 then --Southern Hammerfell Wayshrine
--       normalizedX = 0.429
--       normalizedY = 0.449
--       name = "Southern Hammerfell Gate Wayshrine"
--     end
    
    
    
  
--     -- Bleakrock Isle --
    
--     if nodeIndex == 172 then --Bleakrock Isle Wayshrine
--       normalizedX = 0.613
--       normalizedY = 0.236
--     end
    
    
    
--     -- Dungeons
    
--     if nodeIndex == 424 then -- Icereach
--       normalizedX = 0.403
--       normalizedY = 0.156
--     end
    
--     if nodeIndex == 236 then -- Imperial City Prison
--       normalizedX = 0.542
--       normalizedY = 0.475
--     end
    
--     if nodeIndex == 247 then -- White Gold Tower
--       normalizedX = 0.536
--       normalizedY = 0.486
--     end
    
--     if nodeIndex == 341 then -- Fang Lair
--       normalizedX = 0.405
--       normalizedY = 0.348
--     end
    
    
--     -- Trials
    
--     if nodeIndex == 434 then -- Kyne's Aegis
--       normalizedX = 0.408
--       normalizedY = 0.186
--     end
    
    
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
  
  
--   if GetCurrentMapIndex() == 38 then -- Check to see if we are inside the Western Skyrim zone
    
--     if nodeIndex == 434 then -- Kyne's Aegis
--       normalizedX = 0.442
--       normalizedY = 0.193
--     end
    
--   end
  
--   if GetCurrentMapIndex() == 14 then -- Check to see if we are inside the Cyrodiil zone
    
    
--   if nodeIndex == 236 then -- Imperial City Prison
--       normalizedX = 0.523
--       normalizedY = 0.382
--     end
    
--     if nodeIndex == 247 then -- White Gold Tower
--       normalizedX = 0.497
--       normalizedY = 0.428
--     end
    
--     if nodeIndex == 202 then --Northern Morrowind Wayshrine
--       name = "Northern Morrowind Gate Wayshrine"
--     end
    
--     if nodeIndex == 203 then --Southern Morrowind Wayshrine
--       name = "Southern Morrowind Gate Wayshrine"
--     end
    
--     if nodeIndex == 170 then --Northern Hammerfell Wayshrine
--       name = "Northern Hammerfell Gate Wayshrine"
--     end
    
--     if nodeIndex == 199 then --Southern Hammerfell Wayshrine
--       name = "Southern Hammerfell Gate Wayshrine"
--     end
    
--     if nodeIndex == 200 then --Eastern Elsweyr Wayshrine
--       name = "Eastern Elsweyr Gate Wayshrine"
--     end
    
--     if nodeIndex == 201 then --Western Elsweyr Wayshrine
--       name = "Western Elsweyr Gate Wayshrine"
--     end
    
--   end
  
-- 	return known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked, disabled
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


    parseWayshrines()

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
