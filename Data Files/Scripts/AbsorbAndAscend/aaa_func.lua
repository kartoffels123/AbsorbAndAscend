local storage = require('openmw.storage')

--local settings = storage.playerSection("SettingsAbsorbAndAscend")

function getSettingAAAToggle()
    return settings:get("aaaToggle")
end

function getSettingProtectedItems()
    return settings:get("aaaProtectedItems")
end

function getSettingCustomKeyToggle()
    return settings:get("aaaCustomKeyToggle")
end

function getSettingCustomKey1()
    return settings:get("aaaCustomKey1")
end

function getSettingCustomKey2()
    return settings:get("aaaCustomKey2")
end

-- Helper function to split the protected items string into a table
function getProtectedItemsTable()
    local itemsString = getSettingProtectedItems()
    local items = {}
    for item in string.gmatch(itemsString, "([^,]+)") do
        items[string.trim(item)] = true
    end
    return items
end

-- Helper function to check if an item is protected
function isItemProtected(itemId)
    local protectedItems = getProtectedItemsTable()
    return protectedItems[string.lower(itemId)] ~= nil
end