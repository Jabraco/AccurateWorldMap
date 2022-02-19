--[[ 
===============================================================================
                        AccurateWorldMap Utility Functions
===============================================================================
]]--

-------------------------------------------------------------------------------
-- Get Addon Info Function
-------------------------------------------------------------------------------

function AWM_GetAddonInfo(addonName)
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

        return addonTable
        end
    end
end

