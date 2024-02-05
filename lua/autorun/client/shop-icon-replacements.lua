if engine.ActiveGamemode() ~= "terrortown" then return end
local shopIconsCvar = CreateClientConVar("ttt_shop_icon_replacement", "color-coded buy menu icons", true, false, "The icon replacement pack used for the buy menu")
local shopIconSet = shopIconsCvar:GetString()
-- Get a list of all icons in the pack
local files = file.Find("materials/vgui/ttt/shop-icon-replacements/" .. shopIconSet .. "/*.png", "GAME")
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
    ["weapon_ttt_donconnnon"] = "doncmk2_swep",
    ["ttt_m9k_harpoon"] = "weapon_ttt_hwapoon",
    ["zombies_perk_phdflopper"] = "hoff_perk_phd",
    ["zombies_perk_juggernog"] = "hoff_perk_juggernog",
    ["zombies_perk_staminup"] = "hoff_perk_staminup",
    ["weapon_qua_bomb_station"] = "weapon_ttt_bomb_station",
    ["weapon_ttt_deadringer"] = "weapon_ttt_dead_ringer"
}

local reusedPassiveIcons = {}

-- Adding icons
local function ApplyIcons()
    if shopIconSet == "default buy menu icons" then return end

    -- Turning off the "Custom" icon placed on buy menu icons once if colour coded icons are being used
    -- As they cover the symbol icon this icon set has
    -- As this is only done once on the client, this setting can be turned on again if the user wishes
    if ConVarExists("ttt_bem_marker_custom") and GetConVar("ttt_bem_marker_custom"):GetBool() and shopIconSet == "color-coded buy menu icons" and not file.Exists("ttt/bem-custom-icon-off.txt", "DATA") then
        file.CreateDir("ttt")
        file.Write("ttt/bem-custom-icon-off.txt")
        RunConsoleCommand("ttt_bem_marker_custom", "0")
    end

    -- Active items
    for _, wep in ipairs(weapons.GetList()) do
        local class = wep.ClassName
        local SWEP = weapons.GetStored(class)

        if icons[class] then
            SWEP.Icon = "vgui/ttt/shop-icon-replacements/" .. shopIconSet .. "/" .. class .. ".png"
        elseif reusedIcons[class] and icons[reusedIcons[class]] then
            SWEP.Icon = "vgui/ttt/shop-icon-replacements/" .. shopIconSet .. "/" .. reusedIcons[class] .. ".png"
        end
    end

    if TTT2 then
        -- TTT2 Passive items
        for _, item in ipairs(items.GetList()) do
            local class = item.ClassName
            local ITEM = items.GetStored(class)

            if icons[class] then
                ITEM.material = "vgui/ttt/shop-icon-replacements/" .. shopIconSet .. "/" .. class .. ".png"
            elseif reusedIcons[class] and icons[reusedIcons[class]] then
                ITEM.material = "vgui/ttt/shop-icon-replacements/" .. shopIconSet .. "/" .. reusedIcons[class] .. ".png"
            end
        end
    else
        -- Passive items
        local passiveIDs = {}

        -- Converting passive item ID strings into their actual ID number
        for ID, _ in pairs(icons) do
            -- Steam workshop converts filenames to lowercase so we have to convert them back to all uppercase...
            ID = string.upper(ID)

            if _G[ID] then
                passiveIDs[_G[ID]] = ID
            end
        end

        -- Adding re-used icons to the list of passive IDs as well
        for ID, fileName in pairs(reusedPassiveIcons) do
            -- Steam workshop converts filenames to lowercase so we have to convert them back to all uppercase...
            ID = string.upper(ID)

            if _G[ID] then
                passiveIDs[_G[ID]] = fileName
            end
        end

        -- Applying passive item icons
        for roleID, equipmentTable in pairs(EquipmentItems) do
            for _, equ in ipairs(equipmentTable) do
                if passiveIDs[equ.id] then
                    equ.material = "vgui/ttt/shop-icon-replacements/" .. shopIconSet .. "/" .. passiveIDs[equ.id] .. ".png"
                end
            end
        end
    end
end

hook.Add("InitPostEntity", "ShopIconReplacements", ApplyIcons)

hook.Add("TTTBeginRound", "ShopIconReplacements", function()
    timer.Simple(0, function()
        ApplyIcons()
        hook.Remove("TTTBeginRound", "ShopIconReplacements")
    end)
end)

-- Adding a dropdown menu to the settings tab to switch between icon sets
local _, folders = file.Find("materials/vgui/ttt/shop-icon-replacements/*", "GAME")
local shownMessage = false

local function AddDropdown(parentPanel)
    local dropdown = vgui.Create("DComboBox", parentPanel)
    dropdown:SetConVar("ttt_shop_icon_replacement")
    dropdown:AddChoice("default buy menu icons", "default buy menu icons")

    for _, folder in pairs(folders) do
        dropdown:AddChoice(folder, folder)
    end

    dropdown.OnSelect = function(idx, val, data)
        RunConsoleCommand("ttt_shop_icon_replacement", data)

        if not shownMessage then
            chat.AddText(COLOR_GREEN, "Buy menu icons will change next map!")
            shownMessage = true
        end
    end

    dropdown.Think = dropdown.ConVarStringThink
    parentPanel:Help("Buy Menu Icons: (Changes will take effect next map)")
    parentPanel:AddItem(dropdown)
end

hook.Add("Initialize", "ShopIconReplacementSetting", function()
    -- Custom Roles for TTT adds a hook that allows us to add a setting without assuming the layout of the settings tab
    if isfunction(CRVersion) and CRVersion("1.7.3") then
        hook.Add("TTTSettingsConfigTabFields", "ShopIconReplacementSetting", function(sectionName, parentForm)
            if sectionName == "Interface" then
                AddDropdown(parentForm)
            end
        end)
    else
        -- Else if that mod isn't installed we have to do things manually...
        hook.Add("TTTSettingsTabs", "ShopIconReplacementSetting", function(dtabs)
            -- First we have to travel down the panel hierarchy of the F1 menu
            local tabs = dtabs:GetItems()
            local settingsList

            for _, tab in ipairs(tabs) do
                if tab.Name == "Settings" then
                    settingsList = tab.Panel
                    break
                end
            end

            -- If we failed to find the settings tab, abort adding the dropdown and don't break the F1 menu
            if not settingsList then return end
            local settingsSections = settingsList:GetItems()
            -- Unfortunately there is no unique identifier to each section
            -- E.g. interfaceSettings:GetList() doesn't work, even to just get the child panels of the interface settings list
            -- So we just have to assume interface settings is the first settings section (So this won't work with any mod that heavily edits the F1 settings tab like say, TTT2)
            local interfaceSettings = settingsSections[1]
            AddDropdown(interfaceSettings)
        end)
    end
end)