--[[ 
===============================================================================
                        AccurateWorldMap Utility Functions
===============================================================================
]]--

-------------------------------------------------------------------------------
-- Get Addon Info Function
-------------------------------------------------------------------------------

function getAddonInfo(addonName)
  local AddOnManager = GetAddOnManager()

  local numAddons = AddOnManager:GetNumAddOns()

  for i = 1, numAddons do
    local name, title, author, description = AddOnManager:GetAddOnInfo(i)

    if (name == addonName) then -- we've found our addon!
      local addonTable = {}

      local version = AddOnManager:GetAddOnVersion(i)

      addonTable.title = title
      addonTable.name = name
      addonTable.author = author
      addonTable.description = description
      addonTable.version = tostring(version)
      addonTable.options = {}

      return addonTable
    end
  end
end

-------------------------------------------------------------------------------
-- Print text to chat
-------------------------------------------------------------------------------

function print(message, ...)
  df("[%s] %s", AWM.name, tostring(message):format(...))
end

-------------------------------------------------------------------------------
-- Check if mouse is inside of the map window
-------------------------------------------------------------------------------

function isMouseWithinMapWindow()
  local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
  return (not ZO_WorldMapContainer:IsHidden() and (mouseOverControl == ZO_WorldMapContainer or mouseOverControl:GetParent() == ZO_WorldMapContainer))
end
  
-------------------------------------------------------------------------------
-- Get world map offsets from the sides of the screen
-------------------------------------------------------------------------------

function getWorldMapOffsets()
  return math.floor(ZO_WorldMapContainer:GetLeft()), math.floor(ZO_WorldMapContainer:GetTop())
end