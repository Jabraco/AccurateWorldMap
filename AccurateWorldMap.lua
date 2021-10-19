-- define root addon object
local AWM = {
	name = "AccurateWorldMap",
	title = "Accurate World Map",
	version = "1.0",
	author = "Braux & Thal-J",
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



local function MoveWayshrines()
  
  local zos_GetFastTravelNodeInfo = GetFastTravelNodeInfo

  local originalGetMapMouseoverInfo = GetMapMouseoverInfo
  
  function GetMapMouseoverInfo(x, y)
    return YourCustomData(0.5, 0.5)
  end
  
  originalGetMapMouseoverInfo(0.5, 0.5)
  
  
  GetFastTravelNodeInfo = function(nodeIndex)
		local known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked = zos_GetFastTravelNodeInfo(nodeIndex)
		local disabled = false
    
    
    if GetCurrentMapIndex() == 1 then -- Check to see if we are inside the Tamriel map

      -- Cyrodiil --
      
      if nodeIndex == 201 then --Western Elsweyr Wayshrine
        normalizedX = 0.509
        normalizedY = 0.593
        name = "Western Elsweyr Gate Wayshrine"
      end
      
      if nodeIndex == 200 then --Eastern Elsweyr Wayshrine
        normalizedX = 0.556
        normalizedY = 0.594
        name = "Eastern Elsweyr Gate Wayshrine"
      end
      
      if nodeIndex == 202 then --Northern Morrowind Wayshrine
        normalizedX = 0.622
        normalizedY = 0.410
        name = "Northern Morrowind Gate Wayshrine"
      end
      
      if nodeIndex == 203 then --Southern Morrowind Wayshrine
        normalizedX = 0.643
        normalizedY = 0.455
        name = "Southern Morrowind Gate Wayshrine"
      end
      
      if nodeIndex == 170 then --Northern Hammerfell Wayshrine
        normalizedX = 0.449
        normalizedY = 0.411
        name = "Northern Hammerfell Gate Wayshrine"
      end
      
      if nodeIndex == 199 then --Southern Hammerfell Wayshrine
        normalizedX = 0.429
        normalizedY = 0.449
        name = "Southern Hammerfell Gate Wayshrine"
      end
      
      
      
      
      
      
      if nodeIndex == 172 then --Bleakrock Isle Wayshrine
        normalizedX = 0.613
        normalizedY = 0.236
      end
      
      
      
      -- Dungeons
      
      if nodeIndex == 424 then -- Icereach
        normalizedX = 0.403
        normalizedY = 0.156
      end
      
      if nodeIndex == 236 then -- Imperial City Prison
        normalizedX = 0.542
        normalizedY = 0.475
      end
      
      if nodeIndex == 247 then -- White Gold Tower
        normalizedX = 0.536
        normalizedY = 0.486
      end
      
      if nodeIndex == 341 then -- Fang Lair
        normalizedX = 0.405
        normalizedY = 0.348
      end
      
      
      -- Trials
      
      if nodeIndex == 434 then -- Kyne's Aegis
        normalizedX = 0.408
        normalizedY = 0.186
      end
      
      
      -- Houses
      
      if nodeIndex == 428 then -- Forgemaster Falls
        normalizedX = 0.214
        normalizedY = 0.250
      end
      
      if nodeIndex == 325 then -- Topal Hideaway
        normalizedX = 0.627
        normalizedY = 0.744
      end
      
    end
    
    
    if GetCurrentMapIndex() == 38 then -- Check to see if we are inside the Western Skyrim zone
      
      if nodeIndex == 434 then -- Kyne's Aegis
        normalizedX = 0.442
        normalizedY = 0.193
      end
      
    end
    
    if GetCurrentMapIndex() == 14 then -- Check to see if we are inside the Cyrodiil zone
      
      
    if nodeIndex == 236 then -- Imperial City Prison
        normalizedX = 0.523
        normalizedY = 0.382
      end
      
      if nodeIndex == 247 then -- White Gold Tower
        normalizedX = 0.497
        normalizedY = 0.428
      end
      
      if nodeIndex == 202 then --Northern Morrowind Wayshrine
        name = "Northern Morrowind Gate Wayshrine"
      end
      
      if nodeIndex == 203 then --Southern Morrowind Wayshrine
        name = "Southern Morrowind Gate Wayshrine"
      end
      
      if nodeIndex == 170 then --Northern Hammerfell Wayshrine
        name = "Northern Hammerfell Gate Wayshrine"
      end
      
      if nodeIndex == 199 then --Southern Hammerfell Wayshrine
        name = "Southern Hammerfell Gate Wayshrine"
      end
      
      if nodeIndex == 200 then --Eastern Elsweyr Wayshrine
        name = "Eastern Elsweyr Gate Wayshrine"
      end
      
      if nodeIndex == 201 then --Western Elsweyr Wayshrine
        name = "Western Elsweyr Gate Wayshrine"
      end
      
    end
    
		return known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked, disabled
	end
  
  
  
end



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
    
    local zos_GetFastTravelNodeInfo = GetFastTravelNodeInfo
    

    MoveWayshrines()
    
    SLASH_COMMANDS["/awm_debug"] = debugOutput
    SLASH_COMMANDS["/awm_map_index"] = printCurrentMapIndex
    
    GetMapTileTexture = AWM.GetMapTileTexture
    GetMapCustomMaxZoom = AWM.GetMapCustomMaxZoom
    

end

-- register events

LAM:RegisterOptionControls(panelName, optionsData)
EVENT_MANAGER:RegisterForEvent(AWM.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
