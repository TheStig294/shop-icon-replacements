if engine.ActiveGamemode() ~= "terrortown" then return end
CreateClientConVar("ttt_icon_replacement_folder", "Color-Coded Buy Menu Icons", true, false)

local folders = {"Color-Coded Buy Menu Icons", "Simplified Buy Menu Icons"}

-- Adding a dropdown menu to the settings tab to switch between icon sets
hook.Add("TTTSettingsTabs", "StigTTTIconsSetting", function(dtabs)
    -- First we have to travel down the panel hierarchy of the F1 menu
    local tabs = dtabs:GetItems()
    local settingsList

    for _, tab in ipairs(tabs) do
        if tab.Name == "Settings" then
            settingsList = tab.Panel
            break
        end
    end

    local settingsSections = settingsList:GetItems()
    -- Unfortunately there is no unique identifier to each section
    -- E.g. interfaceSettings:GetList() doesn't work, even to just get the child panels of the interface settings list
    -- So we just have to assume interface settings is the first settings section (So this won't work with any mod that heavily edits the F1 settings tab like say, TTT2)
    local interfaceSettings = settingsSections[1]
    -- From here we've finally gotten low enough into the panel hierarchy to add our own dropdown menu 
    local dropdown = vgui.Create("DComboBox", interfaceSettings)
    dropdown:SetConVar("ttt_icon_replacement_folder")
    dropdown:AddChoice("Default Buy Menu Icons", "Default Buy Menu Icons")

    for _, folder in pairs(folders) do
        dropdown:AddChoice(folder, folder)
    end

    dropdown.OnSelect = function(idx, val, data)
        RunConsoleCommand("ttt_icon_replacement_folder", data)
    end

    dropdown.Think = dropdown.ConVarStringThink
    interfaceSettings:Help("Buy Menu Icons:")
    interfaceSettings:AddItem(dropdown)
end)

-- Get a list of all icons in the pack
local files = file.Find("materials/vgui/ttt/shop-icon-replacements/Color-Coded Buy Menu Icons/*.png", "GAME")
local icons = {}

for _, path in ipairs(files) do
    local icon = string.StripExtension(path)
    icons[icon] = true
end

-- Manually re-use icons for duplicate items
local reusedIcons = {
    ["weapon_ttt_traitor_lightsaber"] = "weapon_ttt_detective_lightsaber",
    ["dancedead"] = "weapon_ttt_dancedead",
    ["weapon_vadim_defib"] = "weapon_detective_defib",
    ["weapon_ttt_nrgoldengun"] = "weapon_ttt_powerdeagle",
    ["weapon_ttt_foolsgoldengun"] = "weapon_ttt_powerdeagle",
    ["weapon_ttt_jetpack"] = "weapon_ttt_jetpackspawner",
    ["ttt_weapon_portalgun"] = "weapon_portalgun",
    ["weapon_ttt_prop_disguiser"] = "weapon_ttt_prop_hunt_gun",
    ["weapon_ttt_suicide"] = "weapon_ttt_jihad",
    ["freeze_swep"] = "tfa_wintershowl",
    ["weapon_ttt_donconnnon"] = "doncmk2_swep"
}

local reusedPassiveIcons = {}

-- Adding icons
hook.Add("TTTBeginRound", "ShopIconReplacements", function()
    -- Active items
    for _, wep in ipairs(weapons.GetList()) do
        local class = wep.ClassName
        local SWEP = weapons.GetStored(class)

        if icons[class] then
            SWEP.Icon = "vgui/ttt/shop-icon-replacements/Color-Coded Buy Menu Icons/" .. class .. ".png"
        elseif reusedIcons[class] then
            SWEP.Icon = "vgui/ttt/shop-icon-replacements/Color-Coded Buy Menu Icons/" .. reusedIcons[class] .. ".png"
        end
    end

    -- Passive items
    local passiveIDs = {}

    -- Converting passive item ID strings into their actual ID number
    for ID, _ in pairs(icons) do
        if _G[ID] then
            passiveIDs[_G[ID]] = ID
        end
    end

    -- Adding re-used icons to the list of passive IDs as well
    for ID, fileName in pairs(reusedPassiveIcons) do
        if _G[ID] then
            passiveIDs[_G[ID]] = fileName
        end
    end

    -- Applying passive item icons
    for roleID, equipmentTable in pairs(EquipmentItems) do
        for _, equ in ipairs(equipmentTable) do
            if passiveIDs[equ.id] then
                equ.material = "vgui/ttt/shop-icon-replacements/Color-Coded Buy Menu Icons/" .. passiveIDs[equ.id] .. ".png"
            end
        end
    end

    hook.Remove("TTTBeginRound", "ShopIconReplacements")
end)