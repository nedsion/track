getgenv().Key = "TRUONG-DANG-DUONG"
getgenv().URL = "http://192.168.1.5:2323" -- Your API

repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players
repeat task.wait() until game.Players.LocalPlayer

local GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local request = http_request or request or syn.request or false
local PlayerControl, CommF

if not request then
    return LocalPlayer:Kick("Exploit not supported!")
end

local function url_encode(str)
    return str and string.gsub(str, " ", "%%20") or ""
end

local function mqs(data, prefix)
    prefix = prefix or ""
    local qs = ""
    for k, v in pairs(data) do
        if typeof(v) == "boolean" then
            v = v == true and "true" or "false"
        end
        if typeof(prefix) == "string" then
            qs = qs .. prefix .. string.lower(tostring(string.gsub(k, " ", ""))) .. "=" .. tostring(v) .. "&"
        end
    end
    return qs:sub(1, #qs - 1)
end

local urls = {
    "https://dvctool.xyz/api/upload_trackstat.php?",
    getgenv().URL .. "/api/v1/check_account_rss?",
}

local function sendRequest(data, prefix)
    local qs = mqs(data, prefix)
    for _, url in ipairs(urls) do
        -- url_encode
        url = url_encode(url .. qs)
        request({
            Url = url,
            Method = "GET",
            Headers = {["Content-Type"] = "application/x-www-form-urlencoded"},
        })
    end
end

-- Anime Defender Specific Functions
local function handleAnimeDefender()
    PlayerControl = PlayerControl or require(ReplicatedFirst.Classes.PlayerControl)

    local function GetData()
        return PlayerControl.AllPlayerControls[LocalPlayer].Inventory
    end

    local function GetUnitData()
        local Data = ReplicatedStorage.Remotes.GetInventory:InvokeServer()
        return Data.Units, Data.EquippedUnits
    end

    local function parseAnimeDefenderData(data)
        local Units, EquippedUnits = GetUnitData()
        local equippedUnitTypes = {}

        for _, uuid in ipairs(EquippedUnits) do
            local unit = Units[uuid]
            if unit then
                table.insert(equippedUnitTypes, unit.Type)
            end
        end

        local equippedUnitsString = table.concat(equippedUnitTypes, ", ")
        return {
            Key = getgenv().Key,
            Username = LocalPlayer.Name,
            Level = data.Level,
            Gem = data.Currencies.Gems,
            Gold = data.Currencies.Gold,
            ["Risky Dice"] = data.Items["Risky Dice"] or 0,
            ["Trait Crystal"] = data.Items["Trait Crystal"] or 0,
            ["Frost Bind"] = data.Items["Frost Bind"] or 0,
            Unit = url_encode(equippedUnitsString),
            Timestamp = tick(),
        }
    end

    local data = parseAnimeDefenderData(GetData())
    sendRequest(data)
end

-- Blox Fruits Specific Functions
local function handleBloxFruits()
    CommF = ReplicatedStorage.Remotes:FindFirstChild("CommF_")
    print(CommF)

    local function checkItem(itemName)
        local inventoryUpdateFunc = require(LocalPlayer.PlayerGui.Main.UIController.Inventory).UpdateRender
        for i, v in next, getupvalues(inventoryUpdateFunc) do
            if i == 4 then
                for _, item in pairs(v) do
                    if item.details.Type ~= "Blox Fruit" and item.details.Name == itemName then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function initializeChecklist()
        return {
            Key = getgenv().Key,
            Username = LocalPlayer.Name,
            godHuman = false,
            cursedDualKatana = false,
            soulGuitar = false,
            superhuman = false,
            dragonTalon = false,
            electricClaw = false,
            sharkmanKarate = false,
            deathStep = false,
            valkyrieHelm = false,
            mirrorFractal = false,
            sea = "",
            level = "",
            race = "",
            fragments = "",
            beli = "",
            currentDevilFruit = "",
            devilFruitInventory = "",
            awakenedSkills = "",
        }
    end

    local seaMapping = {
        [7449423635] = "3",
        [4442272183] = "2",
        [2753915549] = "1",
    }

    local checklist = initializeChecklist()

    if CommF:InvokeServer("BuyGodhuman", true) == 1 then
        checklist.godHuman = true
    end
    if CommF:InvokeServer("BuySuperhuman", true) == 1 then
        checklist.superhuman = true
    end
    if CommF:InvokeServer("BuyDeathStep", true) == 1 then
        checklist.deathStep = true
    end
    if CommF:InvokeServer("BuySharkmanKarate", true) == 1 then
        checklist.sharkmanKarate = true
    end
    if CommF:InvokeServer("BuyElectricClaw", true) == 1 then
        checklist.electricClaw = true
    end
    if CommF:InvokeServer("BuyDragonTalon", true) == 1 then
        checklist.dragonTalon = true
    end
    if checkItem("Cursed Dual Katana") then
        checklist.cursedDualKatana = true
    end
    if checkItem("Soul Guitar") then
        checklist.soulGuitar = true
    end
    if checkItem("Valkyrie Helm") then
        checklist.valkyrieHelm = true
    end
    if checkItem("Mirror Fractal") then
        checklist.mirrorFractal = true
    end

    checklist.sea = seaMapping[game.PlaceId]
    checklist.level = LocalPlayer.Data.Level.Value
    checklist.beli = LocalPlayer.Data.Beli.Value
    checklist.fragments = LocalPlayer.Data.Fragments.Value
    checklist.currentDevilFruit = LocalPlayer.Data.DevilFruit.Value:gsub("-(.*)", "")
    checklist.race = LocalPlayer.Data.Race.Value

    for _, fruit in pairs(CommF:InvokeServer("getInventoryFruits")) do
        if fruit.Price >= 1000000 then
            checklist.devilFruitInventory = checklist.devilFruitInventory .. fruit.Name:gsub("-(.*)", "") .. ", "
        end
    end

    local function getAwakenedAbilities()
        return CommF:InvokeServer("getAwakenedAbilities")
    end

    pcall(function()
        for _, skill in pairs(getAwakenedAbilities()) do
            if skill.Awakened then
                checklist.awakenedSkills = checklist.awakenedSkills .. skill.Key .. ", "
            end
        end
    end)

    print(HttpService:JSONEncode(checklist))
    sendRequest(checklist, "bf-")
end

-- Main Function to Handle Game-Specific Logic
local function Action()
    if GameName:match("Anime Defender") then
        handleAnimeDefender()
    elseif GameName:match("Blox Fruits") then
        handleBloxFruits()
    end
end

while true do
    Action()
    task.wait(120)
end
