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
-- Print
-------------------------------------------------------------------------------

function print(message, ...)
	df("[%s] %s", AWM.name, tostring(message):format(...))
end

