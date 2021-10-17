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


local function debugOutput()
  
  local totalNodes = GetNumFastTravelNodes()
  d("TotalNodes: "..totalNodes)
  local i = 1
  
  local zos_GetFastTravelNodeInfo = GetFastTravelNodeInfo
  
  
  while i <= totalNodes do

    
    GetFastTravelNodeInfo = function(nodeIndex)
      local known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked = zos_GetFastTravelNodeInfo(nodeIndex)

      if poiType == 6 then
        d("Node: "..nodeIndex)
        d(name)
      end
      return known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked
    end
    
    
    GetFastTravelNodeInfo(i)
    
    
    i = i + 1
  end
  
end


local function MoveWayshrines()
  
  local zos_GetFastTravelNodeInfo = GetFastTravelNodeInfo

  
  GetFastTravelNodeInfo = function(nodeIndex)
		local known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked = zos_GetFastTravelNodeInfo(nodeIndex)
		local disabled = false
    
    
    if GetCurrentMapIndex() == 1 then --Check to see if we are inside the "Tamriel" map
      
      if nodeIndex == 172 then --Bleakrock Isle Wayshrine
          isLocatedInCurrentMap = true
          normalizedX = 0.613
          normalizedY = 0.236
      end
      
      
      
    if nodeIndex == 424 then --Icereach dungeon
          isLocatedInCurrentMap = true
          normalizedX = 0.403
          normalizedY = 0.156
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
    
    SLASH_COMMANDS["/awm"] = debugOutput
    
    GetMapTileTexture = AWM.GetMapTileTexture
    GetMapCustomMaxZoom = AWM.GetMapCustomMaxZoom
    

end

-- register events

LAM:RegisterOptionControls(panelName, optionsData)
EVENT_MANAGER:RegisterForEvent(AWM.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
