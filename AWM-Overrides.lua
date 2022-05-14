--[[===========================================================================
                        AccurateWorldMap Overrides
===============================================================================

            Vanilla/ZOS functions that AccurateWorldMap needs to override
                              in order to function.

---------------------------------------------------------------------------]]--

-------------------------------------------------------------------------------
-- ZOS Pin Tooltip Controller
-------------------------------------------------------------------------------

-- Borrowed from GuildShrines addon. Overrides default tooltip handler to adds 
-- custom tooltips to Eyevea and Earth Forge wayshrines in both gamepad and 
-- keyboard & mouse mode.

-------------------------------------------------------------------------------

ZO_MapPin.TOOLTIP_CREATORS[MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE].creator = function(pin)
  local nodeIndex = pin:GetFastTravelNodeIndex()
  local _, name, _, _, _, _, _, _, _, disabled = GetFastTravelNodeInfo(nodeIndex)
  local info_tooltip

  if not isInGamepadMode() then 
    if not disabled then
      if nodeIndex ~= 215 and nodeIndex ~= 221 or ZO_Map_GetFastTravelNode() then -- Eyevea and the Earth Forge cannot be "jumped" to so we'll add "This area is not accessible via jumping." when they're not using a wayshrine
        InformationTooltip:AppendWayshrineTooltip(pin)																			-- Normal Wayshrine tooltip data
      else
        InformationTooltip:AddLine(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, name), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())	-- Wayshrine Name
        InformationTooltip:AddLine("This location can only be accessed via other Wayshrines.", "", 1, 0, 0)				-- "This area is not accessible via jumping."
      end	
    else
      InformationTooltip:AddLine(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, name), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())		-- Wayshrine Name Only (unknown wayshrine)
    end		
  else
    if not disabled then 
      if nodeIndex ~= 215 and nodeIndex ~= 221 or ZO_Map_GetFastTravelNode() then -- Eyevea and the Earth Forge cannot be "jumped" to so we'll add "This area is not accessible via jumping." when they're not using a wayshrine 
        ZO_MapLocationTooltip_Gamepad:AppendWayshrineTooltip(pin)
      else
        local lineSection = ZO_MapLocationTooltip_Gamepad.tooltip:AcquireSection(ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapMoreQuestsContentSection"))
        lineSection:AddLine(name, ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapLocationTooltipContentLabel"), ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("gamepadElderScrollTooltipContent"))									-- Wayshrine Name
        lineSection:AddLine(GetString("This location can only be accessed via other Wayshrines."), ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapLocationTooltipContentLabel"), ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("gamepadElderScrollTooltipContent"))	-- "This area is not accessible via jumping."
        ZO_MapLocationTooltip_Gamepad.tooltip:AddSection(lineSection)
      end
    else
      local lineSection = ZO_MapLocationTooltip_Gamepad.tooltip:AcquireSection(ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapMoreQuestsContentSection"))
      lineSection:AddLine(name, ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapLocationTooltipContentLabel"), ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("gamepadElderScrollTooltipContent")) -- Wayshrine Name Only (unknown wayshrine)
      ZO_MapLocationTooltip_Gamepad.tooltip:AddSection(lineSection)
    end
  end
end
   
-------------------------------------------------------------------------------
-- ZOS WorldMap Get Map Title
-------------------------------------------------------------------------------

-- Override ESO's zone names with AccurateWorldMap's custom ones.

-------------------------------------------------------------------------------

local zos_GetMapTitle = ZO_WorldMap_GetMapTitle
ZO_WorldMap_GetMapTitle = function()
  return getZoneNameFromID(getCurrentMapID())
end

-------------------------------------------------------------------------------
-- ZOS WorldMap Zoom controller
-------------------------------------------------------------------------------

-- Override ESO's zone zoom levels with any custom defined ones.

-------------------------------------------------------------------------------

local zos_GetMapCustomMaxZoom = GetMapCustomMaxZoom
GetMapCustomMaxZoom = function()
  if (getCurrentZoneInfo() ~= nil and getCurrentZoneInfo().zoomLevel ~= nil ) then
    return getCurrentZoneInfo().zoomLevel
  else
    return zos_GetMapCustomMaxZoom()
  end
end
