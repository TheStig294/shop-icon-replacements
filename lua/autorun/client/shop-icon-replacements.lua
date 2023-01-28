if engine.ActiveGamemode() ~= "terrortown" then return end
CreateClientConVar("ttt_icon_replacement_folder", "Color-Coded Icons", true, false)

local folders = {"Color-Coded Icons", "Simplified Icons"}

-- Adding a dropdown menu to the settings tab to switch between icon sets
hook.Add("TTTSettingsTabs", "StigTTTIconsSetting", function(dtabs)
    local items = dtabs:GetItems()
    local settingsDPanelList = items[2].Panel

    for _, item in ipairs(items) do
        if item.name == "Settings" then
            settingsDPanelList = item
            break
        end
    end

    local settingsItems = settingsDPanelList:GetItems()
    local interfaceSettings = settingsItems[1]
    local dropdown = vgui.Create("DComboBox", interfaceSettings)
    dropdown:SetConVar("ttt_icon_replacement_folder")
    dropdown:AddChoice("Default Icons", "Default Icons")

    for _, folder in pairs(folders) do
        dropdown:AddChoice(folder, folder)
    end

    dropdown.OnSelect = function(idx, val, data)
        RunConsoleCommand("ttt_icon_replacement_folder", data)
    end

    dropdown.Think = dropdown.ConVarStringThink
    interfaceSettings:Help("Select buy menu icon set:")
    interfaceSettings:AddItem(dropdown)
end)

-- Get a list of all icons in the pack
local files = file.Find("materials/vgui/ttt/stig-ttt-icons/*.png", "GAME")
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
    ["weapon_ttt_gimnade"] = "weapon_ttt_rmgrenade",
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
            SWEP.Icon = "vgui/ttt/stig-ttt-icons/" .. class .. ".png"
        elseif reusedIcons[class] then
            SWEP.Icon = "vgui/ttt/stig-ttt-icons/" .. reusedIcons[class] .. ".png"
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
                equ.material = "vgui/ttt/stig-ttt-icons/" .. passiveIDs[equ.id] .. ".png"
            end
        end
    end

    hook.Remove("TTTBeginRound", "ShopIconReplacements")
end)