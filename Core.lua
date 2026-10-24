-- PremadeGroupSort Core
local ADDON_NAME, addon = ...
_G["PremadeGroupSort"] = addon

local L = addon.L

-- SavedVariables defaults
local defaultDB = {
    panelOpen = false,
    dungeonBarOpen = true,
    sortMode = "KEY_DESC",
    onlyMythicPlus = false,
    selectedDungeon = "",
    selectedDungeons = {},
    minKey = 0,
    maxKey = 0,
    needTank = false,
    needHealer = false,
    needDPS = false,
    hasTank = false,
    hasHealer = false,
    fitMyRole = false,
    hideOldGroups = false,
    maxGroupAge = 30,
    blacklist = {},
    whitelist = {},
    autoSavePartyBlacklist = false,
    syncGuildBlacklist = true,
    autoSavePartyWhitelist = false,
    syncGuildWhitelist = false,
    englishKeystoneTitles = true,
    -- Anime Voices & Mascot Art (Voices disabled by default, Art ENABLED by default as requested!)
    soundEnabled = false,
    soundLogin = false,
    soundAFK = false,
    soundGroupStart = false,
    soundBlacklistAlert = false,
    soundAnimeArt = true,
    soundVolumeBoost = 100,
    minimapIcon = true,
    minimapPos = 215,
}

addon.db = {}
addon.partyBlacklist = {}
addon.guildBlacklist = {}
addon.partyWhitelist = {}
addon.guildWhitelist = {}
local metaCache = {}
local metaPool = {}

------------------------------------------------------------------------
-- Anime Audio & Voice System
------------------------------------------------------------------------
addon.AnimeSounds = {
    login = {
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\login_okaeri.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\login_konnichiwa.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\login_yahho.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\login_senpai.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\Hydro Dragon.mp3",
    },
    afk_off = {
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\afk_wake_up.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\afk_doko.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\afk_ready.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\afk_nya.mp3",
    },
    group_start = {
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\Hydro Dragon.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\group_ikuzo.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\group_ganbare.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\group_syukko.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\group_wakuwaku.mp3",
    },
    alert_bl = {
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\alert_blacklist.mp3",
    },
    fun = {
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_nya.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_ara_ara.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_baka.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_ganbatte.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_sugoi.mp3",
        "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_arigato.mp3",
    }
}

function addon:PlayAnimeSound(category, specificFile, forcePlay)
    if not forcePlay then
        if not addon.db or addon.db.soundEnabled == false then return end
        if category == "login" and addon.db.soundLogin == false then return end
        if category == "afk_off" and addon.db.soundAFK == false then return end
        if category == "group_start" and addon.db.soundGroupStart == false then return end
        if category == "alert_bl" and addon.db.soundBlacklistAlert == false then return end
    end

    local pool = addon.AnimeSounds and addon.AnimeSounds[category]
    if not pool or #pool == 0 then return end

    local fileToPlay = specificFile
    if not fileToPlay then
        if math.randomseed and time then
            math.randomseed(time() + math.floor(GetTime() * 1000))
        end
        local idx = math.random(1, #pool)
        fileToPlay = pool[idx]
    end

    if fileToPlay then
        local boost = (addon.db and addon.db.soundVolumeBoost) or 100
        boost = tonumber(boost) or 100
        if boost < 25 then boost = 25 end
        if boost > 300 then boost = 300 end

        -- Ensure Dialog channel is enabled in game audio settings
        if GetCVar("Sound_EnableDialog") ~= "1" then
            SetCVar("Sound_EnableDialog", "1")
        end

        if boost <= 100 then
            -- 25% to 100%: Direct hardware volume control on Dialog channel
            local vol = boost / 100
            SetCVar("Sound_DialogVolume", string.format("%.2f", vol))
            PlaySoundFile(fileToPlay, "Dialog")
        elseif boost <= 200 then
            -- 125% to 200%: Full Dialog channel + extra Master channel (+6 dB boost)
            SetCVar("Sound_DialogVolume", "1.00")
            PlaySoundFile(fileToPlay, "Dialog")
            PlaySoundFile(fileToPlay, "Master")
        else
            -- 225% to 300%: Full Dialog + Master + SFX channel (+9.5 dB boost)
            SetCVar("Sound_DialogVolume", "1.00")
            PlaySoundFile(fileToPlay, "Dialog")
            PlaySoundFile(fileToPlay, "Master")
            if GetCVar("Sound_EnableSFX") == "1" then
                PlaySoundFile(fileToPlay, "SFX")
            else
                PlaySoundFile(fileToPlay, "Ambience")
            end
        end
    end
end

local lastGroupStartTime = 0
function addon:TriggerGroupStartSound()
    local now = GetTime()
    if now - lastGroupStartTime > 8 then
        lastGroupStartTime = now
        addon:PlayAnimeSound("group_start")
    end
end

local function safeLower(str)
    if not str then return "" end
    if strlower then return strlower(str) end
    return string.lower(str)
end
addon.safeLower = safeLower

------------------------------------------------------------------------
-- Legion Dungeons Data (Icons, Acronyms, Keywords)
------------------------------------------------------------------------
addon.DungeonList = {
    {
        id = "ALL",
        acronym = L["DUNGEON_BAR_ALL"] or "ALL",
        nameRu = "Все подземелья",
        nameEn = "All Dungeons",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\all",
        fallback = "Interface\\Icons\\inv_misc_groupneedmore",
        acronyms = {},
        keywords = {},
    },
    {
        id = "VOTW",
        acronym = "VotW",
        nameRu = "Казематы Стражей",
        nameEn = "Vault of the Wardens",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\votw",
        fallback = "Interface\\LFGFrame\\LFGIcon-VaultoftheWardens",
        acronyms = {"votw", "кзс"},
        keywords = {"каземат", "warden"},
    },
    {
        id = "MOS",
        acronym = "MoS",
        nameRu = "Утроба душ",
        nameEn = "Maw of Souls",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\mos",
        fallback = "Interface\\LFGFrame\\LFGIcon-MawofSouls",
        acronyms = {"mos", "уд"},
        keywords = {"утроб", "maw"},
    },
    {
        id = "DHT",
        acronym = "DHT",
        nameRu = "Чаща Темного Сердца",
        nameEn = "Darkheart Thicket",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\dht",
        fallback = "Interface\\LFGFrame\\LFGIcon-DarkheartThicket",
        acronyms = {"dht", "чтс"},
        keywords = {"чаща", "темного сердца", "darkheart"},
    },
    {
        id = "EOA",
        acronym = "EoA",
        nameRu = "Око Азшары",
        nameEn = "Eye of Azshara",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\eoa",
        fallback = "Interface\\LFGFrame\\LFGIcon-EyeofAzshara",
        acronyms = {"eoa"},
        keywords = {"око", "азшар", "azshara"},
    },
    {
        id = "HOV",
        acronym = "HoV",
        nameRu = "Чертоги Доблести",
        nameEn = "Halls of Valor",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\hov",
        fallback = "Interface\\LFGFrame\\LFGIcon-HallsofValor",
        acronyms = {"hov", "чд"},
        keywords = {"чертог", "доблест", "valor"},
    },
    {
        id = "NL",
        acronym = "NL",
        nameRu = "Логово Нелтариона",
        nameEn = "Neltharion's Lair",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\nl",
        fallback = "Interface\\LFGFrame\\LFGIcon-NeltharionsLair",
        acronyms = {"nl", "нл"},
        keywords = {"нелтарион", "neltharion", "логово"},
    },
    {
        id = "BRH",
        acronym = "BRH",
        nameRu = "Крепость Черной Ладьи",
        nameEn = "Black Rook Hold",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\brh",
        fallback = "Interface\\LFGFrame\\LFGIcon-BlackRookHold",
        acronyms = {"brh", "кчл"},
        keywords = {"ладь", "черной ладьи", "black rook"},
    },
    {
        id = "COS",
        acronym = "CoS",
        nameRu = "Квартал Звезд",
        nameEn = "Court of Stars",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\cos",
        fallback = "Interface\\LFGFrame\\LFGIcon-CourtofStars",
        acronyms = {"cos", "кз"},
        keywords = {"квартал", "court"},
    },
    {
        id = "ARC",
        acronym = "Arc",
        nameRu = "Катакомбы Сурамара",
        nameEn = "The Arcway",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\arc",
        fallback = "Interface\\LFGFrame\\LFGIcon-TheArcway",
        acronyms = {"arc"},
        keywords = {"катакомб", "arcway", "арка", "сурамар"},
    },
    {
        id = "COEN",
        acronym = "CoEN",
        nameRu = "Собор Вечной Ночи",
        nameEn = "Cathedral of Eternal Night",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\coen",
        fallback = "Interface\\LFGFrame\\LFGIcon-CathedralOfEternalNight",
        acronyms = {"coen", "свн"},
        keywords = {"собор", "вечной ночи", "cathedral"},
    },
    {
        id = "LKARA",
        acronym = "L-Kar",
        nameRu = "Возвращение в Каражан: нижний ярус",
        nameEn = "Return to Karazhan: Lower",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\lkara",
        fallback = "Interface\\LFGFrame\\LFGICON-KARAZHAN",
        acronyms = {"lkara", "lk", "нкара", "л-кара", "низ"},
        keywords = {"нижний ярус", "нижний кара", "нижняя кара", "lower", "н кара", "кара низ", "каражан низ"},
    },
    {
        id = "UKARA",
        acronym = "U-Kar",
        nameRu = "Возвращение в Каражан: верхний ярус",
        nameEn = "Return to Karazhan: Upper",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\ukara",
        fallback = "Interface\\LFGFrame\\LFGIcon-ReturntoKarazhan",
        acronyms = {"ukara", "uk", "вкара", "у-кара", "верх"},
        keywords = {"верхний ярус", "верхний кара", "верхняя кара", "upper", "в кара", "кара верх", "каражан верх"},
    },
    {
        id = "SEAT",
        acronym = "Seat",
        nameRu = "Престол Триумвирата",
        nameEn = "Seat of the Triumvirate",
        icon = "Interface\\AddOns\\PremadeGroupSort\\Textures\\seat",
        fallback = "Interface\\LFGFrame\\LFGIcon-SeatoftheTriumvirate",
        acronyms = {"seat"},
        keywords = {"триумвират", "престол", "triumvirate", "трон"},
    },
}

addon.DungeonMap = {}
for _, d in ipairs(addon.DungeonList) do
    addon.DungeonMap[d.id] = d
    addon.DungeonMap[safeLower(d.id)] = d
    addon.DungeonMap[d.nameRu] = d
    addon.DungeonMap[safeLower(d.nameRu)] = d
    addon.DungeonMap[d.nameEn] = d
    addon.DungeonMap[safeLower(d.nameEn)] = d
    addon.DungeonMap[d.acronym] = d
    addon.DungeonMap[safeLower(d.acronym)] = d
end

------------------------------------------------------------------------
-- Initialization & Addon Messaging (Keystones & Blacklist)
------------------------------------------------------------------------
addon.partyKeystones = {}

local function RegisterAddonPrefix()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix("PGS_KEY")
        C_ChatInfo.RegisterAddonMessagePrefix("PGS_BL")
        C_ChatInfo.RegisterAddonMessagePrefix("PGS_WL")
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix("PGS_KEY")
        RegisterAddonMessagePrefix("PGS_BL")
        RegisterAddonMessagePrefix("PGS_WL")
    end
end

function addon:BroadcastKeystone()
    if not IsInGroup() then return end
    local dId, level = addon:GetPlayerKeystone()
    local channel = IsInRaid() and "RAID" or "PARTY"
    local msg
    if dId and level then
        msg = "KEY:" .. dId .. ":" .. tostring(level)
    else
        msg = "KEY:NONE:0"
    end
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage("PGS_KEY", msg, channel)
    else
        pcall(SendAddonMessage, "PGS_KEY", msg, channel)
    end
end

function addon:RequestPartyKeystones()
    if not IsInGroup() then return end
    local channel = IsInRaid() and "RAID" or "PARTY"
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage("PGS_KEY", "REQ", channel)
    else
        pcall(SendAddonMessage, "PGS_KEY", "REQ", channel)
    end
end

------------------------------------------------------------------------
-- Blacklist Core & Party Synchronization
------------------------------------------------------------------------
function addon:SyncNativeIgnoreList()
    if not addon.db or not addon.db.blacklist then return end
    local numIgnores = GetNumIgnores and GetNumIgnores() or 0
    local myChar = UnitName("player") or "Player"
    for i = 1, numIgnores do
        local name = GetIgnoreName(i)
        if name and name ~= "" and name ~= UNKNOWN then
            local shortName = string.match(name, "^([^-]+)") or name
            local key = safeLower(shortName)
            if not addon.db.blacklist[key] then
                addon.db.blacklist[key] = {
                    name = shortName,
                    reason = L["BL_REASON_WOW_IGNORE"],
                    addedBy = myChar,
                    source = "wow_ignore",
                    timestamp = time(),
                }
            end
        end
    end
end

function addon:AddBlacklist(name, reason, addedBy)
    if not name or name == "" then return false end
    local shortName = string.match(name, "^%s*(.-)%s*$")
    shortName = string.match(shortName, "^([^-]+)") or shortName
    if shortName == "" then return false end

    local key = safeLower(shortName)
    local myChar = addedBy or UnitName("player") or "Player"
    local cleanReason = reason and string.match(reason, "^%s*(.-)%s*$")
    if not cleanReason or cleanReason == "" then
        cleanReason = L["BL_DEFAULT_REASON"]
    end

    addon.db.blacklist[key] = {
        name = shortName,
        reason = cleanReason,
        addedBy = myChar,
        source = "manual",
        timestamp = time(),
    }

    if IsInGroup() then
        local channel = IsInRaid() and "RAID" or "PARTY"
        local msg = "BL_ADD:" .. shortName .. ":" .. cleanReason
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage("PGS_BL", msg, channel)
        else
            pcall(SendAddonMessage, "PGS_BL", msg, channel)
        end
    end
    if IsInGuild() and addon.db and addon.db.syncGuildBlacklist then
        local msg = "BL_ADD:" .. shortName .. ":" .. cleanReason
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage("PGS_BL", msg, "GUILD")
        else
            pcall(SendAddonMessage, "PGS_BL", msg, "GUILD")
        end
    end

    if addon.RefreshBlacklistPanel then
        addon:RefreshBlacklistPanel()
    end

    print(string.format("|cffff2020[PGS]|r " .. (L["BL_ADDED_NOTIFY"] or "Added %s to Blacklist."), "|cffffd100" .. shortName .. "|r"))
    return true
end

function addon:RemoveBlacklist(name)
    if not name or name == "" then return false end
    local shortName = string.match(name, "^%s*(.-)%s*$")
    shortName = string.match(shortName, "^([^-]+)") or shortName
    local key = safeLower(shortName)

    if addon.db.blacklist and addon.db.blacklist[key] then
        addon.db.blacklist[key] = nil

        if IsInGroup() then
            local channel = IsInRaid() and "RAID" or "PARTY"
            local msg = "BL_DEL:" .. shortName
            if C_ChatInfo and C_ChatInfo.SendAddonMessage then
                C_ChatInfo.SendAddonMessage("PGS_BL", msg, channel)
            else
                pcall(SendAddonMessage, "PGS_BL", msg, channel)
            end
        end
        if IsInGuild() and addon.db and addon.db.syncGuildBlacklist then
            local msg = "BL_DEL:" .. shortName
            if C_ChatInfo and C_ChatInfo.SendAddonMessage then
                C_ChatInfo.SendAddonMessage("PGS_BL", msg, "GUILD")
            else
                pcall(SendAddonMessage, "PGS_BL", msg, "GUILD")
            end
        end

        if addon.RefreshBlacklistPanel then
            addon:RefreshBlacklistPanel()
        end

        print(string.format("|cff00ff00[PGS]|r " .. (L["BL_REMOVED_NOTIFY"] or "Removed %s from Blacklist."), "|cffffd100" .. shortName .. "|r"))
        return true
    end
    return false
end

------------------------------------------------------------------------
-- Whitelist Management (Account-wide Trusted Players)
------------------------------------------------------------------------
function addon:AddWhitelist(name, note)
    if not name or name == "" then return false end
    local shortName = string.match(name, "^%s*(.-)%s*$")
    shortName = string.match(shortName, "^([^-]+)") or shortName
    if shortName == "" then return false end

    local key = safeLower(shortName)
    local myChar = UnitName("player") or "Player"
    local cleanNote = note and string.match(note, "^%s*(.-)%s*$")
    if not cleanNote or cleanNote == "" then
        cleanNote = L["WL_DEFAULT_NOTE"] or "Trusted player"
    end

    if not addon.db.whitelist then
        addon.db.whitelist = {}
    end

    addon.db.whitelist[key] = {
        name = shortName,
        note = cleanNote,
        addedBy = myChar,
        timestamp = time(),
    }

    if addon.RefreshWhitelistPanel then
        addon:RefreshWhitelistPanel()
    end

    if IsInGroup() then
        local channel = IsInRaid() and "RAID" or "PARTY"
        local msg = "WL_ADD:" .. shortName .. ":" .. cleanNote
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage("PGS_WL", msg, channel)
        else
            pcall(SendAddonMessage, "PGS_WL", msg, channel)
        end
    end
    if IsInGuild() and addon.db and addon.db.syncGuildWhitelist then
        local msg = "WL_ADD:" .. shortName .. ":" .. cleanNote
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage("PGS_WL", msg, "GUILD")
        else
            pcall(SendAddonMessage, "PGS_WL", msg, "GUILD")
        end
    end

    print(string.format("|cff00ff00[PGS]|r " .. (L["WL_ADDED_NOTIFY"] or "Added %s to Whitelist."), "|cffffd100" .. shortName .. "|r"))
    return true
end

function addon:RemoveWhitelist(name)
    if not name or name == "" then return false end
    local shortName = string.match(name, "^%s*(.-)%s*$")
    shortName = string.match(shortName, "^([^-]+)") or shortName
    local key = safeLower(shortName)

    if addon.db.whitelist and addon.db.whitelist[key] then
        addon.db.whitelist[key] = nil

        if IsInGroup() then
            local channel = IsInRaid() and "RAID" or "PARTY"
            local msg = "WL_DEL:" .. shortName
            if C_ChatInfo and C_ChatInfo.SendAddonMessage then
                C_ChatInfo.SendAddonMessage("PGS_WL", msg, channel)
            else
                pcall(SendAddonMessage, "PGS_WL", msg, channel)
            end
        end
        if IsInGuild() and addon.db and addon.db.syncGuildWhitelist then
            local msg = "WL_DEL:" .. shortName
            if C_ChatInfo and C_ChatInfo.SendAddonMessage then
                C_ChatInfo.SendAddonMessage("PGS_WL", msg, "GUILD")
            else
                pcall(SendAddonMessage, "PGS_WL", msg, "GUILD")
            end
        end

        if addon.RefreshWhitelistPanel then
            addon:RefreshWhitelistPanel()
        end

        print(string.format("|cff00ccff[PGS]|r " .. (L["WL_REMOVED_NOTIFY"] or "Removed %s from Whitelist."), "|cffffd100" .. shortName .. "|r"))
        return true
    end
    return false
end

function addon:GetWhitelistInfo(name)
    if not name or name == "" then return nil end
    local shortName = string.match(name, "^([^-]+)") or name
    local key = safeLower(shortName)

    if addon.db and addon.db.whitelist and addon.db.whitelist[key] then
        local entry = addon.db.whitelist[key]
        entry.isWhitelisted = true
        if not entry.name then entry.name = shortName end
        if not entry.note then entry.note = L["WL_DEFAULT_NOTE"] or "Trusted player" end
        return entry
    end
    return nil
end

function addon:IsWhitelisted(name)
    return addon:GetWhitelistInfo(name) ~= nil
end

function addon:GetBlacklistInfo(name)
    if not name or name == "" then return nil end
    local shortName = string.match(name, "^([^-]+)") or name
    local key = safeLower(shortName)

    -- 1. Account Blacklist (Current character + all alts)
    if addon.db and addon.db.blacklist and addon.db.blacklist[key] then
        local entry = addon.db.blacklist[key]
        entry.isBlacklisted = true
        entry.isSelf = true
        if not entry.name then entry.name = shortName end
        if not entry.reason then entry.reason = L["BL_DEFAULT_REASON"] end
        if not entry.addedBy then entry.addedBy = UnitName("player") end
        if not entry.source then entry.source = "manual" end
        return entry
    end

    -- 2. Party members' Blacklists
    if addon.partyBlacklist then
        for memberName, memberBL in pairs(addon.partyBlacklist) do
            if memberBL[key] then
                local entry = memberBL[key]
                entry.isBlacklisted = true
                entry.isSelf = false
                if not entry.name then entry.name = shortName end
                if not entry.reason then entry.reason = L["BL_DEFAULT_REASON"] end
                entry.addedBy = memberName
                entry.source = "party"
                return entry
            end
        end
    end

    -- 3. Guild members' Blacklists
    if addon.guildBlacklist then
        for memberName, memberBL in pairs(addon.guildBlacklist) do
            if memberBL[key] then
                local entry = memberBL[key]
                entry.isBlacklisted = true
                entry.isSelf = false
                if not entry.name then entry.name = shortName end
                if not entry.reason then entry.reason = L["BL_DEFAULT_REASON"] end
                entry.addedBy = memberName
                entry.source = "guild"
                return entry
            end
        end
    end

    return nil
end

function addon:ImportPartyBlacklist()
    if not addon.partyBlacklist and not addon.guildBlacklist then
        print(string.format("|cff00ccff[PGS]|r " .. (L["BL_IMPORT_NO_DATA"] or "No new party blacklist entries to import.")))
        return 0
    end

    if not addon.db.blacklist then
        addon.db.blacklist = {}
    end

    local importedCount = 0
    if addon.partyBlacklist then
        for memberName, memberBL in pairs(addon.partyBlacklist) do
            for key, info in pairs(memberBL) do
                if not addon.db.blacklist[key] then
                    addon.db.blacklist[key] = {
                        name = info.name or key,
                        reason = info.reason or L["BL_DEFAULT_REASON"],
                        addedBy = memberName,
                        source = "party",
                        timestamp = time(),
                    }
                    importedCount = importedCount + 1
                end
            end
        end
    end

    if addon.guildBlacklist then
        for memberName, memberBL in pairs(addon.guildBlacklist) do
            for key, info in pairs(memberBL) do
                if not addon.db.blacklist[key] then
                    addon.db.blacklist[key] = {
                        name = info.name or key,
                        reason = info.reason or L["BL_DEFAULT_REASON"],
                        addedBy = memberName,
                        source = "guild",
                        timestamp = time(),
                    }
                    importedCount = importedCount + 1
                end
            end
        end
    end

    if importedCount > 0 then
        print(string.format("|cff00ff00[PGS]|r " .. (L["BL_IMPORT_SUCCESS"] or "Imported %d entries from party blacklist into your permanent list."), importedCount))
        if addon.RefreshBlacklistPanel then
            addon:RefreshBlacklistPanel()
        end
    else
        print(string.format("|cff00ccff[PGS]|r " .. (L["BL_IMPORT_NO_DATA"] or "No new party blacklist entries to import.")))
    end

    return importedCount
end

function addon:ImportPartyWhitelist()
    if not addon.partyWhitelist and not addon.guildWhitelist then
        print(string.format("|cff00ccff[PGS]|r " .. (L["WL_IMPORT_NO_DATA"] or "No new party whitelist entries to import.")))
        return 0
    end

    if not addon.db.whitelist then
        addon.db.whitelist = {}
    end

    local importedCount = 0
    if addon.partyWhitelist then
        for memberName, memberWL in pairs(addon.partyWhitelist) do
            for key, info in pairs(memberWL) do
                if not addon.db.whitelist[key] then
                    addon.db.whitelist[key] = {
                        name = info.name or key,
                        note = info.note or L["WL_DEFAULT_NOTE"],
                        addedBy = memberName,
                        source = "party",
                        timestamp = time(),
                    }
                    importedCount = importedCount + 1
                end
            end
        end
    end

    if addon.guildWhitelist then
        for memberName, memberWL in pairs(addon.guildWhitelist) do
            for key, info in pairs(memberWL) do
                if not addon.db.whitelist[key] then
                    addon.db.whitelist[key] = {
                        name = info.name or key,
                        note = info.note or L["WL_DEFAULT_NOTE"],
                        addedBy = memberName,
                        source = "guild",
                        timestamp = time(),
                    }
                    importedCount = importedCount + 1
                end
            end
        end
    end

    if importedCount > 0 then
        print(string.format("|cff00ff00[PGS]|r " .. (L["WL_IMPORT_SUCCESS"] or "Imported %d entries from party whitelist into your permanent list."), importedCount))
        if addon.RefreshWhitelistPanel then
            addon:RefreshWhitelistPanel()
        end
    else
        print(string.format("|cff00ccff[PGS]|r " .. (L["WL_IMPORT_NO_DATA"] or "No new party whitelist entries to import.")))
    end

    return importedCount
end

function addon:ResetDefaults()
    for k, v in pairs(defaultDB) do
        if k ~= "blacklist" and k ~= "whitelist" then
            addon.db[k] = v
        end
    end
    print(string.format("|cff00ff00[PGS]|r " .. (L["OPT_RESET_CONFIRM"] or "All PremadeGroupSort settings have been reset to default.")))
    if addon.optionsMainPanel and addon.optionsMainPanel.refresh then
        addon.optionsMainPanel.refresh()
    end
    if addon.RefreshResults then
        addon:RefreshResults()
    end
    if addon.UpdatePanelVisibility then
        addon:UpdatePanelVisibility()
    end
end

function addon:BroadcastBlacklist(targetChannel)
    local channels = {}
    if targetChannel then
        table.insert(channels, targetChannel)
    else
        if IsInGroup() then
            table.insert(channels, IsInRaid() and "RAID" or "PARTY")
        end
        if IsInGuild() and addon.db and addon.db.syncGuildBlacklist then
            table.insert(channels, "GUILD")
        end
    end

    if #channels == 0 then return end

    local entries = {}
    if addon.db and addon.db.blacklist then
        for key, info in pairs(addon.db.blacklist) do
            table.insert(entries, (info.name or key) .. "=" .. (info.reason or ""))
        end
    end

    local function SendToAll(msg)
        for _, ch in ipairs(channels) do
            if C_ChatInfo and C_ChatInfo.SendAddonMessage then
                C_ChatInfo.SendAddonMessage("PGS_BL", msg, ch)
            else
                pcall(SendAddonMessage, "PGS_BL", msg, ch)
            end
        end
    end

    if #entries == 0 then
        SendToAll("BL_DATA:NONE")
        return
    end

    local currentChunk = {}
    local currentLen = 0
    for _, item in ipairs(entries) do
        local itemLen = string.len(item) + 1
        if currentLen + itemLen > 180 and #currentChunk > 0 then
            SendToAll("BL_DATA:" .. table.concat(currentChunk, ";"))
            currentChunk = {}
            currentLen = 0
        end
        table.insert(currentChunk, item)
        currentLen = currentLen + itemLen
    end

    if #currentChunk > 0 then
        SendToAll("BL_DATA:" .. table.concat(currentChunk, ";"))
    end
end

function addon:RequestPartyBlacklist(targetChannel)
    local channels = {}
    if targetChannel then
        table.insert(channels, targetChannel)
    else
        if IsInGroup() then
            table.insert(channels, IsInRaid() and "RAID" or "PARTY")
        end
        if IsInGuild() and addon.db and addon.db.syncGuildBlacklist then
            table.insert(channels, "GUILD")
        end
    end

    for _, ch in ipairs(channels) do
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage("PGS_BL", "REQ_BL", ch)
        else
            pcall(SendAddonMessage, "PGS_BL", "REQ_BL", ch)
        end
    end
end

function addon:BroadcastWhitelist(targetChannel)
    local channels = {}
    if targetChannel then
        table.insert(channels, targetChannel)
    else
        if IsInGroup() then
            table.insert(channels, IsInRaid() and "RAID" or "PARTY")
        end
        if IsInGuild() and addon.db and addon.db.syncGuildWhitelist then
            table.insert(channels, "GUILD")
        end
    end

    if #channels == 0 then return end

    local entries = {}
    if addon.db and addon.db.whitelist then
        for key, info in pairs(addon.db.whitelist) do
            table.insert(entries, (info.name or key) .. "=" .. (info.note or ""))
        end
    end

    local function SendToAll(msg)
        for _, ch in ipairs(channels) do
            if C_ChatInfo and C_ChatInfo.SendAddonMessage then
                C_ChatInfo.SendAddonMessage("PGS_WL", msg, ch)
            else
                pcall(SendAddonMessage, "PGS_WL", msg, ch)
            end
        end
    end

    if #entries == 0 then
        SendToAll("WL_DATA:NONE")
        return
    end

    local currentChunk = {}
    local currentLen = 0
    for _, item in ipairs(entries) do
        local itemLen = string.len(item) + 1
        if currentLen + itemLen > 180 and #currentChunk > 0 then
            SendToAll("WL_DATA:" .. table.concat(currentChunk, ";"))
            currentChunk = {}
            currentLen = 0
        end
        table.insert(currentChunk, item)
        currentLen = currentLen + itemLen
    end

    if #currentChunk > 0 then
        SendToAll("WL_DATA:" .. table.concat(currentChunk, ";"))
    end
end

function addon:RequestPartyWhitelist(targetChannel)
    local channels = {}
    if targetChannel then
        table.insert(channels, targetChannel)
    else
        if IsInGroup() then
            table.insert(channels, IsInRaid() and "RAID" or "PARTY")
        end
        if IsInGuild() and addon.db and addon.db.syncGuildWhitelist then
            table.insert(channels, "GUILD")
        end
    end

    for _, ch in ipairs(channels) do
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage("PGS_WL", "REQ_WL", ch)
        else
            pcall(SendAddonMessage, "PGS_WL", "REQ_WL", ch)
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
eventFrame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("IGNORELIST_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        RegisterAddonPrefix()
        if PremadeGroupSortDB == nil then
            PremadeGroupSortDB = {}
        end
        for k, v in pairs(defaultDB) do
            if PremadeGroupSortDB[k] == nil then
                PremadeGroupSortDB[k] = v
            end
        end
        -- One-time migration to ensure anime sounds are disabled by default, but anime mascot art is ENABLED by default
        if PremadeGroupSortDB.soundDefaultResetV4 == nil then
            PremadeGroupSortDB.soundDefaultResetV4 = true
            PremadeGroupSortDB.soundEnabled = false
            PremadeGroupSortDB.soundLogin = false
            PremadeGroupSortDB.soundAFK = false
            PremadeGroupSortDB.soundGroupStart = false
            PremadeGroupSortDB.soundBlacklistAlert = false
            PremadeGroupSortDB.soundAnimeArt = true
        end
        if PremadeGroupSortDB.soundAnimeArt == nil then
            PremadeGroupSortDB.soundAnimeArt = true
        end
        if PremadeGroupSortDB.soundVolumeBoost == nil then
            PremadeGroupSortDB.soundVolumeBoost = 100
        end
        addon.db = PremadeGroupSortDB
        if addon.db.selectedDungeons == nil then
            addon.db.selectedDungeons = {}
        end
        if addon.db.blacklist == nil then
            addon.db.blacklist = {}
        end
        if addon.db.whitelist == nil then
            addon.db.whitelist = {}
        end
        -- Migration from legacy selectedDungeon if needed
        if addon.db.selectedDungeon and addon.db.selectedDungeon ~= "" and addon.db.selectedDungeon ~= "ALL" then
            for part in string.gmatch(addon.db.selectedDungeon, "[^,]+") do
                local trimPart = string.match(part, "^%s*(.-)%s*$")
                if trimPart and trimPart ~= "" then
                    local dInfo = addon.DungeonMap[trimPart] or addon.DungeonMap[safeLower(trimPart)]
                    local c = dInfo and dInfo.id or trimPart
                    addon.db.selectedDungeons[c] = true
                end
            end
        end
    elseif event == "PLAYER_LOGIN" then
        RegisterAddonPrefix()
        addon:InitializeHooks()
        addon:SyncNativeIgnoreList()
        addon.wasAFK = UnitIsAFK("player") and true or false
        addon.wasInGroup = IsInGroup() and true or false
        addon.hadActiveEntry = (C_LFGList and C_LFGList.HasActiveEntryInfo and C_LFGList.HasActiveEntryInfo()) and true or false
        if C_Timer and C_Timer.After then
            C_Timer.After(2.0, function()
                addon:PlayAnimeSound("login")
            end)
        else
            addon:PlayAnimeSound("login")
        end
        if IsInGroup() then
            addon:BroadcastKeystone()
            addon:RequestPartyKeystones()
            addon:BroadcastBlacklist()
            addon:RequestPartyBlacklist()
        end
        if IsInGuild() and addon.db and addon.db.syncGuildBlacklist then
            addon:BroadcastBlacklist("GUILD")
            addon:RequestPartyBlacklist("GUILD")
        end
    elseif event == "PLAYER_FLAGS_CHANGED" then
        local unit = arg1
        if not unit or unit == "player" then
            local isAFK = UnitIsAFK("player") and true or false
            if addon.wasAFK and not isAFK then
                addon:PlayAnimeSound("afk_off")
            end
            addon.wasAFK = isAFK
        end
    elseif event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
        local hasActive = (C_LFGList and C_LFGList.HasActiveEntryInfo and C_LFGList.HasActiveEntryInfo()) and true or false
        if hasActive and not addon.hadActiveEntry then
            addon:TriggerGroupStartSound()
        end
        addon.hadActiveEntry = hasActive
    elseif event == "PLAYER_GUILD_UPDATE" then
        if IsInGuild() and addon.db and addon.db.syncGuildBlacklist then
            addon:BroadcastBlacklist("GUILD")
            addon:RequestPartyBlacklist("GUILD")
        end
        if IsInGuild() and addon.db and addon.db.syncGuildWhitelist then
            addon:BroadcastWhitelist("GUILD")
            addon:RequestPartyWhitelist("GUILD")
        end
    elseif event == "IGNORELIST_UPDATE" then
        addon:SyncNativeIgnoreList()
        if addon.RefreshBlacklistPanel then
            addon:RefreshBlacklistPanel()
        end
    elseif event == "PLAYER_LEAVING_WORLD" then
        addon.isWorldLoaded = false
        addon:ClearMetaCache()
    elseif event == "PLAYER_ENTERING_WORLD" then
        addon.isWorldLoaded = true
        addon:ClearMetaCache()
    elseif event == "PLAYER_REGEN_ENABLED" then
        collectgarbage("step", 200)
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = arg1, arg2, arg3, arg4
        if prefix and message and sender then
            local senderShort = string.match(sender, "^([^-]+)") or sender
            local myName = UnitName("player")
            if senderShort ~= myName then
                if prefix == "PGS_KEY" then
                    if message == "REQ" then
                        addon:BroadcastKeystone()
                    elseif string.sub(message, 1, 4) == "KEY:" then
                        local dId, levelStr = string.match(message, "^KEY:(%w+):(%d+)$")
                        if dId and levelStr then
                            local level = tonumber(levelStr)
                            if dId == "NONE" or level == 0 then
                                addon.partyKeystones[senderShort] = nil
                            else
                                addon.partyKeystones[senderShort] = {
                                    dId = dId,
                                    level = level,
                                    name = senderShort,
                                }
                            end
                            if addon.RefreshCreationPanel then
                                addon:RefreshCreationPanel()
                            end
                        end
                    end
                elseif prefix == "PGS_BL" then
                    local isGuildMsg = (channel == "GUILD")
                    local targetStore = isGuildMsg and addon.guildBlacklist or addon.partyBlacklist
                    local sourceTag = isGuildMsg and "guild" or "party"

                    if message == "REQ_BL" then
                        addon:BroadcastBlacklist(channel)
                    elseif string.sub(message, 1, 8) == "BL_DATA:" then
                        local dataStr = string.sub(message, 9)
                        if not targetStore[senderShort] then
                            targetStore[senderShort] = {}
                        end
                        if dataStr ~= "NONE" then
                            for item in string.gmatch(dataStr, "[^;]+") do
                                local name, reason = string.match(item, "^([^=]+)=(.*)$")
                                if name and name ~= "" then
                                    local k = safeLower(name)
                                    local cleanReason = (reason and reason ~= "") and reason or L["BL_DEFAULT_REASON"]
                                    targetStore[senderShort][k] = {
                                        name = name,
                                        reason = cleanReason,
                                        owner = senderShort,
                                        source = sourceTag,
                                    }
                                    local autoSave = addon.db and (addon.db.autoSavePartyBlacklist or (isGuildMsg and addon.db.syncGuildBlacklist))
                                    if autoSave then
                                        if not addon.db.blacklist then addon.db.blacklist = {} end
                                        if not addon.db.blacklist[k] then
                                            addon.db.blacklist[k] = {
                                                name = name,
                                                reason = cleanReason,
                                                addedBy = senderShort,
                                                source = sourceTag,
                                                timestamp = time(),
                                            }
                                        end
                                    end
                                end
                            end
                        end
                        if addon.RefreshBlacklistPanel then
                            addon:RefreshBlacklistPanel()
                        end
                        if addon.optionsBLPanel and addon.optionsBLPanel.refresh then
                            addon.optionsBLPanel.refresh()
                        end
                    elseif string.sub(message, 1, 7) == "BL_ADD:" then
                        local name, reason = string.match(message, "^BL_ADD:([^:]+):?(.*)$")
                        if name and name ~= "" then
                            if not targetStore[senderShort] then
                                targetStore[senderShort] = {}
                            end
                            local k = safeLower(name)
                            local cleanReason = (reason and reason ~= "") and reason or L["BL_DEFAULT_REASON"]
                            targetStore[senderShort][k] = {
                                name = name,
                                reason = cleanReason,
                                owner = senderShort,
                                source = sourceTag,
                            }
                            local autoSave = addon.db and (addon.db.autoSavePartyBlacklist or (isGuildMsg and addon.db.syncGuildBlacklist))
                            if autoSave then
                                if not addon.db.blacklist then addon.db.blacklist = {} end
                                if not addon.db.blacklist[k] then
                                    addon.db.blacklist[k] = {
                                        name = name,
                                        reason = cleanReason,
                                        addedBy = senderShort,
                                        source = sourceTag,
                                        timestamp = time(),
                                    }
                                end
                            end
                            if addon.RefreshBlacklistPanel then
                                addon:RefreshBlacklistPanel()
                            end
                            if addon.optionsBLPanel and addon.optionsBLPanel.refresh then
                                addon.optionsBLPanel.refresh()
                            end
                        end
                    elseif string.sub(message, 1, 7) == "BL_DEL:" then
                        local name = string.match(message, "^BL_DEL:(.+)$")
                        if name and targetStore[senderShort] then
                            local k = safeLower(name)
                            targetStore[senderShort][k] = nil
                            if addon.RefreshBlacklistPanel then
                                addon:RefreshBlacklistPanel()
                            end
                            if addon.optionsBLPanel and addon.optionsBLPanel.refresh then
                                addon.optionsBLPanel.refresh()
                            end
                        end
                    end
                elseif prefix == "PGS_WL" then
                    local isGuildMsg = (channel == "GUILD")
                    local targetStore = isGuildMsg and addon.guildWhitelist or addon.partyWhitelist
                    local sourceTag = isGuildMsg and "guild" or "party"

                    if message == "REQ_WL" then
                        addon:BroadcastWhitelist(channel)
                    elseif string.sub(message, 1, 8) == "WL_DATA:" then
                        local dataStr = string.sub(message, 9)
                        if not targetStore[senderShort] then
                            targetStore[senderShort] = {}
                        end
                        if dataStr ~= "NONE" then
                            for item in string.gmatch(dataStr, "[^;]+") do
                                local name, note = string.match(item, "^([^=]+)=(.*)$")
                                if name and name ~= "" then
                                    local k = safeLower(name)
                                    local cleanNote = (note and note ~= "") and note or L["WL_DEFAULT_NOTE"]
                                    targetStore[senderShort][k] = {
                                        name = name,
                                        note = cleanNote,
                                        owner = senderShort,
                                        source = sourceTag,
                                    }
                                    local autoSave = addon.db and (addon.db.autoSavePartyWhitelist or (isGuildMsg and addon.db.syncGuildWhitelist))
                                    if autoSave then
                                        if not addon.db.whitelist then addon.db.whitelist = {} end
                                        if not addon.db.whitelist[k] then
                                            addon.db.whitelist[k] = {
                                                name = name,
                                                note = cleanNote,
                                                addedBy = senderShort,
                                                source = sourceTag,
                                                timestamp = time(),
                                            }
                                        end
                                    end
                                end
                            end
                        end
                        if addon.RefreshWhitelistPanel then
                            addon:RefreshWhitelistPanel()
                        end
                    elseif string.sub(message, 1, 7) == "WL_ADD:" then
                        local name, note = string.match(message, "^WL_ADD:([^:]+):?(.*)$")
                        if name and name ~= "" then
                            if not targetStore[senderShort] then
                                targetStore[senderShort] = {}
                            end
                            local k = safeLower(name)
                            local cleanNote = (note and note ~= "") and note or L["WL_DEFAULT_NOTE"]
                            targetStore[senderShort][k] = {
                                name = name,
                                note = cleanNote,
                                owner = senderShort,
                                source = sourceTag,
                            }
                            local autoSave = addon.db and (addon.db.autoSavePartyWhitelist or (isGuildMsg and addon.db.syncGuildWhitelist))
                            if autoSave then
                                if not addon.db.whitelist then addon.db.whitelist = {} end
                                if not addon.db.whitelist[k] then
                                    addon.db.whitelist[k] = {
                                        name = name,
                                        note = cleanNote,
                                        addedBy = senderShort,
                                        source = sourceTag,
                                        timestamp = time(),
                                    }
                                end
                            end
                            if addon.RefreshWhitelistPanel then
                                addon:RefreshWhitelistPanel()
                            end
                        end
                    elseif string.sub(message, 1, 7) == "WL_DEL:" then
                        local name = string.match(message, "^WL_DEL:(.+)$")
                        if name and targetStore[senderShort] then
                            local k = safeLower(name)
                            targetStore[senderShort][k] = nil
                            if addon.RefreshWhitelistPanel then
                                addon:RefreshWhitelistPanel()
                            end
                        end
                    end
                end
            end
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        local inGroup = IsInGroup() and true or false
        if inGroup and not addon.wasInGroup and UnitIsGroupLeader("player") then
            addon:TriggerGroupStartSound()
        end
        addon.wasInGroup = inGroup

        if not inGroup then
            wipe(addon.partyKeystones)
            wipe(addon.partyBlacklist)
            wipe(addon.partyWhitelist)
        else
            local currentMembers = {}
            local numGroup = GetNumGroupMembers()
            for i = 1, numGroup do
                local unit = IsInRaid() and ("raid" .. i) or (i == numGroup and "player" or "party" .. i)
                local name = UnitName(unit)
                if name then
                    local shortName = string.match(name, "^([^-]+)") or name
                    currentMembers[shortName] = true
                end
            end
            for name in pairs(addon.partyKeystones) do
                if not currentMembers[name] then
                    addon.partyKeystones[name] = nil
                end
            end
            for name in pairs(addon.partyBlacklist) do
                if not currentMembers[name] then
                    addon.partyBlacklist[name] = nil
                end
            end
            for name in pairs(addon.partyWhitelist) do
                if not currentMembers[name] then
                    addon.partyWhitelist[name] = nil
                end
            end
            addon:BroadcastKeystone()
            addon:RequestPartyKeystones()
            addon:BroadcastBlacklist()
            addon:RequestPartyBlacklist()
            addon:BroadcastWhitelist()
            addon:RequestPartyWhitelist()
        end
        if addon.RefreshCreationPanel then
            addon:RefreshCreationPanel()
        end
        if addon.RefreshBlacklistPanel then
            addon:RefreshBlacklistPanel()
        end
    elseif event == "BAG_UPDATE_DELAYED" then
        if IsInGroup() then
            addon:BroadcastKeystone()
        end
        if addon.RefreshCreationPanel then
            addon:RefreshCreationPanel()
        end
    end
end)

-- Slash Commands
SLASH_PREMADEGROUPSORT1 = "/pgs"
SLASH_PREMADEGROUPSORT2 = "/premadegroupsort"
SlashCmdList["PREMADEGROUPSORT"] = function(msg)
    local cmd, arg1, arg2 = string.match(msg or "", "^%s*(%S*)%s*(%S*)%s*(.-)%s*$")
    cmd = safeLower(cmd or "")
    if cmd == "bl" or cmd == "blacklist" or cmd == "чс" then
        local subCmd = safeLower(arg1 or "")
        if subCmd == "add" or subCmd == "+" then
            local name, reason = string.match(arg2 or "", "^%s*(%S+)%s*(.-)%s*$")
            if name and name ~= "" then
                addon:AddBlacklist(name, reason)
            else
                print("|cffff2020[PGS]|r " .. (GetLocale() == "ruRU" and "Использование: /pgs bl add <Имя> [Причина]" or "Usage: /pgs bl add <Name> [Reason]"))
            end
        elseif subCmd == "remove" or subCmd == "rem" or subCmd == "del" or subCmd == "-" then
            local name = string.match(arg2 or "", "^%s*(%S+)%s*$")
            if name and name ~= "" then
                addon:RemoveBlacklist(name)
            else
                print("|cffff2020[PGS]|r " .. (GetLocale() == "ruRU" and "Использование: /pgs bl remove <Имя>" or "Usage: /pgs bl remove <Name>"))
            end
        elseif subCmd == "import" then
            addon:ImportPartyBlacklist()
        else
            if addon.ToggleBlacklistPanel then
                addon:ToggleBlacklistPanel()
            end
        end
    elseif cmd == "wl" or cmd == "whitelist" or cmd == "бс" then
        local subCmd = safeLower(arg1 or "")
        if subCmd == "add" or subCmd == "+" then
            local name, note = string.match(arg2 or "", "^%s*(%S+)%s*(.-)%s*$")
            if name and name ~= "" then
                addon:AddWhitelist(name, note)
            else
                print("|cffff2020[PGS]|r " .. (GetLocale() == "ruRU" and "Использование: /pgs wl add <Имя> [Заметка]" or "Usage: /pgs wl add <Name> [Note]"))
            end
        elseif subCmd == "remove" or subCmd == "rem" or subCmd == "del" or subCmd == "-" then
            local name = string.match(arg2 or "", "^%s*(%S+)%s*$")
            if name and name ~= "" then
                addon:RemoveWhitelist(name)
            else
                print("|cffff2020[PGS]|r " .. (GetLocale() == "ruRU" and "Использование: /pgs wl remove <Имя>" or "Usage: /pgs wl remove <Name>"))
            end
        elseif subCmd == "import" then
            addon:ImportPartyWhitelist()
        else
            if addon.ToggleWhitelistPanel then
                addon:ToggleWhitelistPanel()
            elseif addon.ToggleBlacklistPanel then
                addon:ToggleBlacklistPanel(2)
            end
        end
    elseif cmd == "opt" or cmd == "options" or cmd == "config" or cmd == "настройки" then
        if addon.OpenOptions then
            addon:OpenOptions()
        else
            InterfaceOptionsFrame_OpenToCategory("Premade Group Sort")
            InterfaceOptionsFrame_OpenToCategory("Premade Group Sort")
        end
    elseif cmd == "secret" or cmd == "anime" or cmd == "секрет" then
        if addon.ToggleSecretAnimePanel then
            addon:ToggleSecretAnimePanel()
        end
    elseif cmd == "gc" or cmd == "mem" or cmd == "memory" or cmd == "память" then
        local before, after = addon:PurgeMemory()
        local bMB = string.format("%.2f", before / 1024)
        local aMB = string.format("%.2f", after / 1024)
        local freed = string.format("%.2f", (before - after) / 1024)
        if GetLocale() == "ruRU" then
            print(string.format("|cff00ff00[PGS]|r Память Lua очищена: |cffff8080%s MB|r -> |cff55ff55%s MB|r (освобождено %s MB)", bMB, aMB, freed))
        else
            print(string.format("|cff00ff00[PGS]|r Lua memory purged: |cffff8080%s MB|r -> |cff55ff55%s MB|r (freed %s MB)", bMB, aMB, freed))
        end
    else
        if addon.ToggleMainPanel then
            addon:ToggleMainPanel()
        end
    end
end

------------------------------------------------------------------------
-- Helper: Player Role
------------------------------------------------------------------------
function addon:GetPlayerRole()
    local specIndex = GetSpecialization()
    if specIndex then
        local role = GetSpecializationRole(specIndex)
        if role == "TANK" or role == "HEALER" or role == "DAMAGER" then
            return role
        end
    end
    return "DAMAGER"
end

------------------------------------------------------------------------
-- Helper: Extract Keystone Level & Activity Type
------------------------------------------------------------------------
function addon:ExtractKeyLevel(name, comment, activityName)
    local isMythicKeystone = false
    if activityName then
        local lowerAct = string.lower(activityName)
        if string.find(lowerAct, "эпохальн") and (string.find(lowerAct, "ключ") or string.find(lowerAct, "keystone")) then
            isMythicKeystone = true
        elseif string.find(lowerAct, "mythic keystone") or string.find(lowerAct, "keystone") then
            isMythicKeystone = true
        end
    end

    if not name or name == "" then
        return nil, isMythicKeystone
    end

    -- Clean title: replace common Russian letters that might confuse numbers
    local cleanName = " " .. name .. " "

    -- 1. Explicit key pattern: +number, m+number, mnumber (e.g., +10, + 10, M+15, m8, m 10)
    local key = string.match(cleanName, "[%+mM]%s*(%d+)")
    if not key then
        -- 2. Number followed by plus (e.g., 10+, 15 +)
        key = string.match(cleanName, "(%d+)%s*%+")
    end
    if not key then
        -- 3. "key 10", "KEY 15", "ключ 10", "кл 10"
        key = string.match(cleanName, "[kK][eE][yY]%s*(%d+)") or
              string.match(cleanName, "ключ%s*(%d+)") or
              string.match(cleanName, "Ключ%s*(%d+)") or
              string.match(cleanName, "КЛЮЧ%s*(%d+)") or
              string.match(cleanName, "кл%s*(%d+)") or
              string.match(cleanName, "Кл%s*(%d+)")
    end
    if not key then
        -- 4. Number in brackets: [10], (10), {10}
        key = string.match(cleanName, "[%[%({]%s*(%d+)%s*[%]%)}] ")
    end
    if not key then
        -- 5. Isolated number surrounded by whitespace or punctuation
        for candidate in string.gmatch(cleanName, "[%s%p](%d+)[%s%p]") do
            local num = tonumber(candidate)
            -- Reasonable keystone range in Legion is 2 to 35
            -- Avoid matching item levels like 900, 930, 940, 950 or dungeon sizes (e.g. 5) if other words indicate key
            if num and num >= 2 and num <= 35 and num ~= 5 then
                key = candidate
                break
            elseif num == 5 and (string.find(cleanName, "[dD][hH][tT]") or string.find(cleanName, "[vV][oO][tT][wW]") or isMythicKeystone) then
                key = candidate
                break
            end
        end
    end

    -- 6. Check comment as fallback
    if not key and comment and comment ~= "" then
        key = string.match(comment, "[%+mM]%s*(%d+)") or
              string.match(comment, "(%d+)%s*%+") or
              string.match(comment, "[kK][eE][yY]%s*(%d+)") or
              string.match(comment, "ключ%s*(%d+)") or
              string.match(comment, "Ключ%s*(%d+)") or
              string.match(comment, "КЛЮЧ%s*(%d+)")
    end

    local num = tonumber(key)
    if num and num >= 2 and num <= 35 then
        return num, isMythicKeystone
    end

    return nil, isMythicKeystone
end

------------------------------------------------------------------------
-- Helper: Get Dungeon Info from Activity
------------------------------------------------------------------------
function addon:GetGroupDungeonInfo(activityID)
    if not activityID then return nil, nil, nil end
    local fullName, shortName, categoryID, groupID = C_LFGList.GetActivityInfo(activityID)
    local groupName = nil
    if groupID and groupID > 0 then
        groupName = C_LFGList.GetActivityGroupInfo(groupID)
    end
    return groupID, groupName or shortName or fullName, fullName or ""
end

------------------------------------------------------------------------
-- Cache metadata for a ResultID
------------------------------------------------------------------------
function addon:GetResultMeta(resultID)
    if metaCache[resultID] then
        return metaCache[resultID]
    end

    local id, activityID, name, comment, voiceChat, iLvl, honorLevel, age, numBNetFriends, numCharFriends, numGuildMates, isDelisted, leaderName = C_LFGList.GetSearchResultInfo(resultID)
    if not id or isDelisted or not name then
        return nil
    end

    local groupID, dungeonName, activityName = addon:GetGroupDungeonInfo(activityID)
    local keyLevel, isMythicKeystone = addon:ExtractKeyLevel(name, comment, activityName)
    local memberCounts = C_LFGList.GetSearchResultMemberCounts(resultID)

    local tanks = memberCounts and memberCounts.TANK or 0
    local healers = memberCounts and memberCounts.HEALER or 0
    local damagers = memberCounts and memberCounts.DAMAGER or 0
    local norole = memberCounts and memberCounts.NOROLE or 0
    local totalMembers = tanks + healers + damagers + norole
    local openSlots = math.max(0, 5 - totalMembers)

    local friends = (numBNetFriends or 0) * 100 + (numCharFriends or 0) * 10 + (numGuildMates or 0)

    local meta = table.remove(metaPool) or {}
    meta.resultID = resultID
    meta.activityID = activityID
    meta.groupID = groupID
    meta.dungeonName = dungeonName or ""
    meta.activityName = activityName or ""
    meta.name = name or ""
    meta.comment = comment or ""
    meta.leaderName = leaderName or ""
    meta.keyLevel = keyLevel
    meta.isMythicKeystone = isMythicKeystone
    meta.tanks = tanks
    meta.healers = healers
    meta.damagers = damagers
    meta.totalMembers = totalMembers
    meta.openSlots = openSlots
    meta.iLvl = iLvl or 0
    meta.age = age or 0
    meta.friends = friends
    meta.members = nil

    metaCache[resultID] = meta
    return meta
end

function addon:ClearMetaCache()
    for k, meta in pairs(metaCache) do
        if type(meta) == "table" then
            for f in pairs(meta) do meta[f] = nil end
            metaPool[#metaPool + 1] = meta
        end
        metaCache[k] = nil
    end
end

------------------------------------------------------------------------
-- Helper: Format Group Age into Text & Color
------------------------------------------------------------------------
function addon:FormatGroupAge(ageSec)
    local isRu = (GetLocale() == "ruRU")
    if not ageSec or ageSec < 60 then
        local text = isRu and "[< 1м]" or "[< 1m]"
        return text, "|cff00ff00"
    end

    local totalMins = math.floor(ageSec / 60)
    if totalMins < 60 then
        local text = isRu and string.format("[%dм]", totalMins) or string.format("[%dm]", totalMins)
        local color
        if totalMins < 15 then
            color = "|cff00ff00"
        elseif totalMins < 30 then
            color = "|cff77ff33"
        elseif totalMins < 45 then
            color = "|cffffcc00"
        else
            color = "|cffff8800"
        end
        return text, color
    else
        local hours = math.floor(totalMins / 60)
        local mins = totalMins % 60
        local text
        if isRu then
            text = (mins > 0) and string.format("[%dч %dм]", hours, mins) or string.format("[%dч]", hours)
        else
            text = (mins > 0) and string.format("[%dh %dm]", hours, mins) or string.format("[%dh]", hours)
        end
        return text, "|cffff3333"
    end
end

function addon:GetAgeOptionText(mins)
    mins = tonumber(mins) or 30
    if mins == 15 then
        return L["GROUP_AGE_15M"]
    elseif mins == 30 then
        return L["GROUP_AGE_30M"]
    elseif mins == 45 then
        return L["GROUP_AGE_45M"]
    elseif mins == 60 then
        return L["GROUP_AGE_60M"]
    elseif mins == 90 then
        return L["GROUP_AGE_90M"]
    elseif mins == 120 then
        return L["GROUP_AGE_120M"]
    else
        return string.format(L["GROUP_AGE_LABEL"], tostring(mins) .. (GetLocale() == "ruRU" and " мин" or " min"))
    end
end

------------------------------------------------------------------------
-- Class Color Map & Group Member Composition Helpers
------------------------------------------------------------------------
addon.CLASS_COLORS = {
    WARRIOR     = { r = 0.78, g = 0.61, b = 0.43, hex = "ffc79c6e", nameRu = "Воин" },
    PALADIN     = { r = 0.96, g = 0.55, b = 0.73, hex = "fff58cba", nameRu = "Паладин" },
    HUNTER      = { r = 0.67, g = 0.83, b = 0.45, hex = "ffabd473", nameRu = "Охотник" },
    ROGUE       = { r = 1.00, g = 0.96, b = 0.41, hex = "fffff569", nameRu = "Разбойник" },
    PRIEST      = { r = 1.00, g = 1.00, b = 1.00, hex = "ffffffff", nameRu = "Жрец" },
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23, hex = "ffc41f3b", nameRu = "Рыцарь смерти" },
    SHAMAN      = { r = 0.00, g = 0.44, b = 0.87, hex = "ff0070de", nameRu = "Шаман" },
    MAGE        = { r = 0.25, g = 0.78, b = 0.92, hex = "ff3fc7eb", nameRu = "Маг" },
    WARLOCK     = { r = 0.53, g = 0.53, b = 0.93, hex = "ff8788ee", nameRu = "Чернокнижник" },
    MONK        = { r = 0.00, g = 1.00, b = 0.59, hex = "ff00ff96", nameRu = "Монах" },
    DRUID       = { r = 1.00, g = 0.49, b = 0.04, hex = "ffff7d0a", nameRu = "Друид" },
    DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79, hex = "ffa330c9", nameRu = "Охотник на демонов" },
}

function addon:GetClassColor(classFilename)
    if classFilename and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename] then
        local c = RAID_CLASS_COLORS[classFilename]
        local hex = c.colorStr or (addon.CLASS_COLORS[classFilename] and addon.CLASS_COLORS[classFilename].hex) or "ffffffff"
        return c.r, c.g, c.b, hex
    end
    if classFilename and addon.CLASS_COLORS[classFilename] then
        local c = addon.CLASS_COLORS[classFilename]
        return c.r, c.g, c.b, c.hex
    end
    return 1, 1, 1, "ffffffff"
end

function addon:GetSearchResultMembers(resultID)
    if not resultID or not C_LFGList or not C_LFGList.GetSearchResultMemberInfo then
        return nil
    end

    if metaCache[resultID] and metaCache[resultID].members then
        return metaCache[resultID].members
    end

    local memberCounts = C_LFGList.GetSearchResultMemberCounts(resultID)
    local total = 0
    if memberCounts then
        total = (memberCounts.TANK or 0) + (memberCounts.HEALER or 0) + (memberCounts.DAMAGER or 0) + (memberCounts.NOROLE or 0)
    end
    if total <= 0 then
        total = 5
    end

    local members = {}
    for i = 1, math.min(total, 5) do
        local r1, r2, r3, r4 = C_LFGList.GetSearchResultMemberInfo(resultID, i)
        local role, class, classFilename, specName
        if type(r1) == "table" then
            role = r1.role
            class = r1.class
            classFilename = r1.classFileName or r1.classFilename or r1.class
            specName = r1.specName
        else
            role = r1
            class = r2
            classFilename = r3 or r2
            specName = r4
        end

        if role or class or classFilename then
            local cFile = classFilename or class or "UNKNOWN"
            local localizedClass = class
            if (not localizedClass or localizedClass == "" or localizedClass == cFile) and addon.CLASS_COLORS[cFile] then
                if GetLocale() == "ruRU" then
                    localizedClass = addon.CLASS_COLORS[cFile].nameRu
                end
            end
            members[i] = {
                role = role or "NOROLE",
                class = localizedClass or cFile,
                classFilename = cFile,
                specName = specName or "",
            }
        end
    end

    if metaCache[resultID] then
        metaCache[resultID].members = members
    end
    return members
end

------------------------------------------------------------------------
-- Memory Purge & Optimization
------------------------------------------------------------------------
function addon:PurgeMemory()
    local before = collectgarbage("count")
    addon:ClearMetaCache()
    collectgarbage("collect")
    local after = collectgarbage("count")
    return before, after
end

------------------------------------------------------------------------
-- Helper: Matches Dungeon by ID, Name or Keywords
------------------------------------------------------------------------
function addon:MatchesDungeon(meta, selected)
    if not selected or selected == "" or selected == "ALL" then
        return true
    end

    local dInfo = addon.DungeonMap[selected] or addon.DungeonMap[safeLower(selected)]
    if not dInfo or dInfo.id == "ALL" then
        return true
    end

    local dName = safeLower(meta.dungeonName)
    local aName = safeLower(meta.activityName)
    local gName = safeLower(meta.name)
    local cName = safeLower(meta.comment)

    -- 1. Check exact dungeon name against activity group or activity name
    if dInfo.nameRu and dInfo.nameRu ~= "" then
        local lRu = safeLower(dInfo.nameRu)
        if string.find(dName, lRu, 1, true) or string.find(aName, lRu, 1, true) then
            return true
        end
    end
    if dInfo.nameEn and dInfo.nameEn ~= "" then
        local lEn = safeLower(dInfo.nameEn)
        if string.find(dName, lEn, 1, true) or string.find(aName, lEn, 1, true) then
            return true
        end
    end

    -- 2. Check substring keywords in group title, dungeon name, activity, comment
    if dInfo.keywords then
        for _, kw in ipairs(dInfo.keywords) do
            local lkw = safeLower(kw)
            if string.find(dName, lkw, 1, true) or
               string.find(aName, lkw, 1, true) or
               string.find(gName, lkw, 1, true) or
               string.find(cName, lkw, 1, true) then
                return true
            end
        end
    end

    -- 3. Check token/acronym matches (word boundary safe) in group title and comment
    if dInfo.acronyms and #dInfo.acronyms > 0 then
        local paddedG = " " .. gName .. " "
        local paddedC = " " .. cName .. " "
        for _, ac in ipairs(dInfo.acronyms) do
            local lac = safeLower(ac)
            local pattern = "[%s%p]" .. lac .. "[%s%p]"
            if string.find(paddedG, pattern) or string.find(paddedC, pattern) then
                return true
            end
        end
    end

    -- 4. Fallback: Substring matching against selected string
    local lSelected = safeLower(selected)
    return string.find(dName, lSelected, 1, true) or
           string.find(aName, lSelected, 1, true) or
           string.find(gName, lSelected, 1, true)
end

------------------------------------------------------------------------
-- Filter Matching Logic
------------------------------------------------------------------------
function addon:PassesFilters(resultID)
    local meta = addon:GetResultMeta(resultID)
    if not meta then
        return false
    end

    local db = addon.db

    -- Filter: Only Mythic+ Keystones
    if db.onlyMythicPlus then
        if not meta.isMythicKeystone and not meta.keyLevel then
            return false
        end
        local lowerAct = string.lower(meta.activityName)
        if not string.find(lowerAct, "эпохальн") and not string.find(lowerAct, "mythic") then
            return false
        end
    end

    -- Filter: Selected Dungeon(s) (supports multi-selection via Shift-click)
    local selCount = addon:GetSelectedDungeonsCount()
    if selCount > 0 then
        local matchedAny = false
        for dId, active in pairs(db.selectedDungeons) do
            if active and addon:MatchesDungeon(meta, dId) then
                matchedAny = true
                break
            end
        end
        if not matchedAny then
            return false
        end
    end

    -- Filter: Min Key Level
    if db.minKey and db.minKey > 0 then
        if not meta.keyLevel or meta.keyLevel < db.minKey then
            return false
        end
    end

    -- Filter: Max Key Level
    if db.maxKey and db.maxKey > 0 then
        if not meta.keyLevel or meta.keyLevel > db.maxKey then
            return false
        end
    end

    -- Filter: Roles Needed
    if db.needTank and meta.tanks > 0 then
        return false
    end
    if db.needHealer and meta.healers > 0 then
        return false
    end
    if db.needDPS and meta.damagers >= 3 then
        return false
    end

    -- Filter: Roles Present
    if db.hasTank and meta.tanks == 0 then
        return false
    end
    if db.hasHealer and meta.healers == 0 then
        return false
    end

    -- Filter: Fits My Current Role
    if db.fitMyRole then
        local myRole = addon:GetPlayerRole()
        if myRole == "TANK" and meta.tanks >= 1 then
            return false
        elseif myRole == "HEALER" and meta.healers >= 1 then
            return false
        elseif myRole == "DAMAGER" and meta.damagers >= 3 then
            return false
        end
        if meta.totalMembers >= 5 then
            return false
        end
    end

    -- Filter: Hide Old Groups (Age in LFG)
    if db.hideOldGroups and db.maxGroupAge and db.maxGroupAge > 0 then
        local maxAgeSec = db.maxGroupAge * 60
        if meta.age and meta.age > maxAgeSec then
            return false
        end
    end

    return true
end

------------------------------------------------------------------------
-- Sorting Comparator
------------------------------------------------------------------------
function addon:CompareResults(id1, id2)
    local m1 = addon:GetResultMeta(id1)
    local m2 = addon:GetResultMeta(id2)

    if not m1 and not m2 then return false end
    if not m1 then return false end
    if not m2 then return true end

    -- Friends always take priority (standard WoW behavior)
    if m1.friends ~= m2.friends then
        return m1.friends > m2.friends
    end

    local mode = addon.db.sortMode or "KEY_DESC"

    if mode == "KEY_DESC" then
        -- Higher keystone level first
        local k1 = m1.keyLevel or -1
        local k2 = m2.keyLevel or -1
        if k1 ~= k2 then
            return k1 > k2
        end
        -- If same key, prefer fewer open slots (almost full)
        if m1.totalMembers ~= m2.totalMembers then
            return m1.totalMembers > m2.totalMembers
        end

    elseif mode == "KEY_ASC" then
        -- Lower keystone level first (but groups without keys at the very end)
        local k1 = m1.keyLevel or 999
        local k2 = m2.keyLevel or 999
        if k1 ~= k2 then
            return k1 < k2
        end

    elseif mode == "DUNGEON_ASC" then
        -- Dungeon name A-Z, then higher key level within dungeon
        if m1.dungeonName ~= m2.dungeonName then
            return m1.dungeonName < m2.dungeonName
        end
        local k1 = m1.keyLevel or -1
        local k2 = m2.keyLevel or -1
        if k1 ~= k2 then
            return k1 > k2
        end

    elseif mode == "ROLE_TANK" then
        -- Needs Tank (tanks == 0) first
        local needTank1 = (m1.tanks == 0) and 1 or 0
        local needTank2 = (m2.tanks == 0) and 1 or 0
        if needTank1 ~= needTank2 then
            return needTank1 > needTank2
        end
        local k1 = m1.keyLevel or -1
        local k2 = m2.keyLevel or -1
        if k1 ~= k2 then
            return k1 > k2
        end

    elseif mode == "ROLE_HEAL" then
        -- Needs Healer (healers == 0) first
        local needHeal1 = (m1.healers == 0) and 1 or 0
        local needHeal2 = (m2.healers == 0) and 1 or 0
        if needHeal1 ~= needHeal2 then
            return needHeal1 > needHeal2
        end
        local k1 = m1.keyLevel or -1
        local k2 = m2.keyLevel or -1
        if k1 ~= k2 then
            return k1 > k2
        end

    elseif mode == "ROLE_DPS" then
        -- Needs DPS (damagers < 3) first
        local needDPS1 = (m1.damagers < 3) and 1 or 0
        local needDPS2 = (m2.damagers < 3) and 1 or 0
        if needDPS1 ~= needDPS2 then
            return needDPS1 > needDPS2
        end
        local k1 = m1.keyLevel or -1
        local k2 = m2.keyLevel or -1
        if k1 ~= k2 then
            return k1 > k2
        end

    elseif mode == "SLOTS_DESC" then
        -- Most full groups first (4/5 before 3/5 before 2/5)
        if m1.totalMembers ~= m2.totalMembers then
            return m1.totalMembers > m2.totalMembers
        end

    elseif mode == "TIME_DESC" then
        -- Newest groups first (smaller age in seconds)
        if m1.age ~= m2.age then
            return m1.age < m2.age
        end

    elseif mode == "ILVL_DESC" then
        -- Required item level descending
        if m1.iLvl ~= m2.iLvl then
            return m1.iLvl > m2.iLvl
        end
    end

    -- Fallback: Sort by result ID
    return id1 < id2
end

------------------------------------------------------------------------
-- Core Filter & Sort Application
------------------------------------------------------------------------
function addon:ApplyFiltersAndSort(panel)
    if not panel or not panel.results then return end
    if addon.isWorldLoaded == false then return end

    -- Check active search category (Category 2 = Dungeons in Legion 7.3.5)
    local categoryID = panel.categoryID
    if not categoryID and LFGListFrame then
        if LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.categoryID then
            categoryID = LFGListFrame.SearchPanel.categoryID
        elseif LFGListFrame.CategorySelection and LFGListFrame.CategorySelection.selectedCategory then
            categoryID = LFGListFrame.CategorySelection.selectedCategory
        end
    end

    -- If category is not set, infer category from first result's activityID
    if not categoryID and panel.results and panel.results[1] and C_LFGList and C_LFGList.GetSearchResultInfo and C_LFGList.GetActivityInfo then
        local _, firstActivityID = C_LFGList.GetSearchResultInfo(panel.results[1])
        if firstActivityID then
            local _, _, actCatID = C_LFGList.GetActivityInfo(firstActivityID)
            if actCatID then
                categoryID = actCatID
            end
        end
    end

    -- If searching Raids, Quests, Custom or other categories (categoryID ~= 2),
    -- DO NOT filter, sort, or modify panel.results!
    if categoryID and categoryID ~= 2 then
        panel.rawResults = nil
        panel.freshSearch = false
        if addon.UpdateStatusText then
            addon:UpdateStatusText(#panel.results, #panel.results)
        end
        return
    end

    -- Save raw unfiltered results if first time or fresh search
    if not panel.rawResults or panel.freshSearch then
        panel.rawResults = {}
        for i = 1, #panel.results do
            panel.rawResults[i] = panel.results[i]
        end
        panel.freshSearch = false
    end

    local raw = panel.rawResults
    local filtered = {}

    for i = 1, #raw do
        local id = raw[i]
        if addon:PassesFilters(id) then
            filtered[#filtered + 1] = id
        end
    end

    -- Sort the filtered results if not using Blizzard default
    if addon.db.sortMode ~= "DEFAULT" then
        table.sort(filtered, function(a, b)
            return addon:CompareResults(a, b)
        end)
    end

    panel.results = filtered
    panel.totalResults = #filtered

    -- Update status text in UI if available
    if addon.UpdateStatusText then
        addon:UpdateStatusText(#filtered, #raw)
    end
end

------------------------------------------------------------------------
-- Hooks
------------------------------------------------------------------------
function addon:InitializeHooks()
    if addon.hooksInitialized then return end
    addon.hooksInitialized = true

    -- Hook LFGListSearchPanel_UpdateResultList
    if LFGListSearchPanel_UpdateResultList then
        hooksecurefunc("LFGListSearchPanel_UpdateResultList", function(self)
            self.freshSearch = true
            addon:ClearMetaCache()
            addon:ApplyFiltersAndSort(self)
        end)
    end

    -- Hook Search Box clear or text change
    if LFGListFrame and LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.SearchBox then
        LFGListFrame.SearchPanel.SearchBox:HookScript("OnTextChanged", function()
            addon:ClearMetaCache()
        end)
    end

    -- Hook LFG group listing creation
    if C_LFGList and C_LFGList.CreateListing then
        hooksecurefunc(C_LFGList, "CreateListing", function()
            addon:TriggerGroupStartSound()
        end)
    end
    if LFGListFrame and LFGListFrame.EntryCreation and LFGListFrame.EntryCreation.ListGroupButton then
        LFGListFrame.EntryCreation.ListGroupButton:HookScript("OnClick", function()
            addon:TriggerGroupStartSound()
        end)
    end
end

------------------------------------------------------------------------
-- Public Trigger to Re-filter & Update View
------------------------------------------------------------------------
function addon:RefreshResults()
    if not LFGListFrame or not LFGListFrame.SearchPanel or not LFGListFrame.SearchPanel:IsShown() then
        return
    end

    local panel = LFGListFrame.SearchPanel
    addon:ApplyFiltersAndSort(panel)
    if LFGListSearchPanel_UpdateResults then
        LFGListSearchPanel_UpdateResults(panel)
    end
end

------------------------------------------------------------------------
-- Multi-Selection Helper Functions
------------------------------------------------------------------------
function addon:GetSelectedDungeonsCount()
    local db = addon.db
    if not db or not db.selectedDungeons then return 0 end
    local count = 0
    for id, active in pairs(db.selectedDungeons) do
        if active and id ~= "ALL" and id ~= "" then
            count = count + 1
        end
    end
    return count
end

function addon:IsDungeonSelected(dungeonId)
    local db = addon.db
    if not db or not db.selectedDungeons then return (dungeonId == "ALL") end
    local selCount = addon:GetSelectedDungeonsCount()
    if not dungeonId or dungeonId == "" or dungeonId == "ALL" then
        return (selCount == 0)
    end
    local dInfo = addon.DungeonMap[dungeonId] or addon.DungeonMap[safeLower(dungeonId)]
    local canonical = dInfo and dInfo.id or dungeonId
    return (db.selectedDungeons[canonical] == true)
end

function addon:ToggleDungeonSelection(dungeonIdOrName, isShift)
    local db = addon.db
    if not db.selectedDungeons then
        db.selectedDungeons = {}
    end

    if not dungeonIdOrName or dungeonIdOrName == "" or dungeonIdOrName == "ALL" then
        -- Clear all selections -> ALL
        wipe(db.selectedDungeons)
        db.selectedDungeon = ""
    else
        local dInfo = addon.DungeonMap[dungeonIdOrName] or addon.DungeonMap[safeLower(dungeonIdOrName)]
        local canonical = dInfo and dInfo.id or dungeonIdOrName

        if isShift then
            -- Multi-selection toggle
            if db.selectedDungeons[canonical] then
                db.selectedDungeons[canonical] = nil
            else
                db.selectedDungeons[canonical] = true
            end
            local count = addon:GetSelectedDungeonsCount()
            if count == 0 then
                db.selectedDungeon = ""
            elseif count == 1 then
                for k, v in pairs(db.selectedDungeons) do
                    if v then db.selectedDungeon = k break end
                end
            else
                local list = {}
                for k, v in pairs(db.selectedDungeons) do
                    if v then table.insert(list, k) end
                end
                table.sort(list)
                db.selectedDungeon = table.concat(list, ",")
            end
        else
            -- Single-selection:
            -- If canonical was the only selected, toggle it off to ALL
            local count = addon:GetSelectedDungeonsCount()
            if count == 1 and db.selectedDungeons[canonical] then
                wipe(db.selectedDungeons)
                db.selectedDungeon = ""
            else
                wipe(db.selectedDungeons)
                db.selectedDungeons[canonical] = true
                db.selectedDungeon = canonical
            end
        end
    end

    if addon.UpdateDungeonBarSelection then
        addon:UpdateDungeonBarSelection()
    end
    if addon.SyncUIWithDB then
        addon:SyncUIWithDB()
    end
    addon:RefreshResults()
end

function addon:SetSelectedDungeon(dungeonIdOrName)
    addon:ToggleDungeonSelection(dungeonIdOrName, false)
end

function addon:ResetFilters()
    local db = addon.db
    db.sortMode = "KEY_DESC"
    db.onlyMythicPlus = false
    db.selectedDungeon = ""
    if db.selectedDungeons then
        wipe(db.selectedDungeons)
    else
        db.selectedDungeons = {}
    end
    db.minKey = 0
    db.maxKey = 0
    db.needTank = false
    db.needHealer = false
    db.needDPS = false
    db.hasTank = false
    db.hasHealer = false
    db.fitMyRole = false
    db.hideOldGroups = false
    db.maxGroupAge = 30

    if addon.UpdateDungeonBarSelection then
        addon:UpdateDungeonBarSelection()
    end
    if addon.SyncUIWithDB then
        addon:SyncUIWithDB()
    end
    addon:RefreshResults()
end

------------------------------------------------------------------------
-- Challenge Map IDs & Keystone Bag Scanning (Legion 7.3.5)
------------------------------------------------------------------------
addon.ChallengeMapToDungeon = {
    [197] = "EOA",
    [198] = "DHT",
    [199] = "BRH",
    [200] = "HOV",
    [206] = "NL",
    [207] = "VOTW",
    [208] = "MOS",
    [210] = "COS",
    [227] = "LKARA",
    [234] = "UKARA",
    [239] = "COEN",
    [233] = "ARC",
    [247] = "SEAT",
}

local scanTooltip = CreateFrame("GameTooltip", "PremadeGroupSort_ScanTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

function addon:GetPlayerKeystone()
    -- 1. Scan player bags (0 to 4) for actual Mythic Keystone item
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                -- Check for standard Legion keystone link: |Hkeystone:mapID:level:...|h
                local mapIDStr, levelStr = string.match(link, "keystone:(%d+):(%d+)")
                if mapIDStr and levelStr then
                    local mapID = tonumber(mapIDStr)
                    local level = tonumber(levelStr)
                    if mapID and level then
                        local dId = addon.ChallengeMapToDungeon[mapID]
                        if not dId and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
                            local mName = C_ChallengeMode.GetMapUIInfo(mapID)
                            if mName then
                                local d = addon.DungeonMap[mName] or addon.DungeonMap[safeLower(mName)]
                                dId = d and d.id
                            end
                        end
                        if dId then
                            local dInfo = addon.DungeonMap[dId]
                            return dId, level, dInfo and dInfo.nameEn or dId
                        end
                    end
                end

                -- Also check if item is a keystone by itemID or name
                local itemID = GetContainerItemID(bag, slot)
                local isKeystoneItem = (itemID == 138019 or itemID == 158923 or itemID == 151086)
                if not isKeystoneItem then
                    local lowerLink = safeLower(link)
                    if string.find(lowerLink, "эпохальн") and string.find(lowerLink, "ключ") then
                        isKeystoneItem = true
                    elseif string.find(lowerLink, "mythic keystone") or string.find(lowerLink, "keystone") then
                        isKeystoneItem = true
                    end
                end

                if isKeystoneItem then
                    scanTooltip:ClearLines()
                    scanTooltip:SetBagItem(bag, slot)
                    local level = nil
                    local foundDungeonId = nil

                    for i = 1, scanTooltip:NumLines() do
                        local line = _G["PremadeGroupSort_ScanTooltipTextLeft" .. i]
                        local text = line and line:GetText()
                        if text and text ~= "" then
                            if not level then
                                local lvl = string.match(text, "%((%d+)%)") or
                                            string.match(text, "%+(%d+)") or
                                            string.match(text, "[уУ]ровень[^%d]*(%d+)") or
                                            string.match(text, "[lL]evel[^%d]*(%d+)")
                                if lvl then
                                    level = tonumber(lvl)
                                end
                            end

                            if not foundDungeonId then
                                for _, d in ipairs(addon.DungeonList) do
                                    if d.id ~= "ALL" then
                                        if string.find(text, d.nameRu, 1, true) or string.find(text, d.nameEn, 1, true) then
                                            foundDungeonId = d.id
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end

                    if foundDungeonId and level then
                        local dInfo = addon.DungeonMap[foundDungeonId]
                        return foundDungeonId, level, dInfo and dInfo.nameEn or foundDungeonId
                    elseif foundDungeonId then
                        local dInfo = addon.DungeonMap[foundDungeonId]
                        return foundDungeonId, 2, dInfo and dInfo.nameEn or foundDungeonId
                    end
                end
            end
        end
    end

    -- If no keystone found in bags, do not return dummy server data
    return nil, nil, nil
end

------------------------------------------------------------------------
-- LFG Mythic+ Activity Matching & Quick Creation
------------------------------------------------------------------------
local dungeonActivityCache = {}

function addon:GetDungeonActivity(dungeonId)
    if not dungeonId or dungeonId == "" or dungeonId == "ALL" then return nil, nil end
    if dungeonActivityCache[dungeonId] then
        return dungeonActivityCache[dungeonId].activityID, dungeonActivityCache[dungeonId].groupID
    end

    if C_LFGList and C_LFGList.GetAvailableActivities then
        local activities = C_LFGList.GetAvailableActivities(2) -- Category 2 = Dungeons
        if activities then
            local targetD = addon.DungeonMap[dungeonId] or addon.DungeonMap[safeLower(dungeonId or "")]
            local targetAcronym = targetD and targetD.id or dungeonId

            local keystoneActID, keystoneGroupID = nil, nil
            local firstMythicActID, firstMythicGroupID = nil, nil
            local secondMythicActID, secondMythicGroupID = nil, nil
            local fallbackActID, fallbackGroupID = nil, nil

            for _, actID in ipairs(activities) do
                local fullName, shortName, categoryID, groupID, minItemLevel, filters, minLevel, maxPlayers, displayType, orderIndex, useHonorLevel, showQuickJoinToast, isMythicPlusActivity = C_LFGList.GetActivityInfo(actID)
                if fullName and fullName ~= "" then
                    local lowerFull = safeLower(fullName)
                    local lowerShort = shortName and safeLower(shortName) or ""
                    local mockMeta = {
                        name = fullName,
                        comment = "",
                        dungeonName = shortName or fullName,
                        activityName = fullName,
                        groupID = groupID
                    }
                    if addon:MatchesDungeon(mockMeta, targetAcronym) then
                        -- Check for explicit Mythic+ / Keystone indicators
                        local isKeystone = (isMythicPlusActivity == true)
                            or string.find(lowerFull, "ключ")
                            or string.find(lowerFull, "keystone")
                            or string.find(lowerFull, "%+")
                            or string.find(lowerFull, "мифик%s*%+")
                            or string.find(lowerFull, "schlüssel")
                            or string.find(lowerFull, "clé")
                            or string.find(lowerFull, "cle")
                            or string.find(lowerFull, "piedra")
                            or string.find(lowerShort, "ключ")
                            or string.find(lowerShort, "keystone")
                            or string.find(lowerShort, "%+")

                        if isKeystone then
                            keystoneActID = actID
                            keystoneGroupID = groupID
                            break -- Priority 1: found exact Mythic+ keystone activity!
                        end

                        local isMythic = string.find(lowerFull, "эпохальн")
                            or string.find(lowerFull, "mythic")
                            or string.find(lowerFull, "mythisch")
                            or string.find(lowerFull, "мифик")
                            or string.find(lowerShort, "эпохальн")
                            or string.find(lowerShort, "mythic")

                        if isMythic then
                            if not firstMythicActID then
                                firstMythicActID = actID
                                firstMythicGroupID = groupID
                            else
                                secondMythicActID = actID
                                secondMythicGroupID = groupID
                            end
                        else
                            if not fallbackActID then
                                fallbackActID = actID
                                fallbackGroupID = groupID
                            end
                        end
                    end
                end
            end

            local chosenActID = keystoneActID or secondMythicActID or firstMythicActID or fallbackActID
            local chosenGroupID = keystoneGroupID or secondMythicGroupID or firstMythicGroupID or fallbackGroupID

            if chosenActID then
                dungeonActivityCache[dungeonId] = { activityID = chosenActID, groupID = chosenGroupID }
                return chosenActID, chosenGroupID
            end
        end
    end
    return nil, nil
end

function addon:ApplyQuickCreation(dungeonId, level, tagsStr)
    if not LFGListFrame or not LFGListFrame.EntryCreation then return end
    local entryCreation = LFGListFrame.EntryCreation

    -- 1. Select the matching Activity in LFG
    local actID, groupID = addon:GetDungeonActivity(dungeonId)
    if actID then
        if LFGListEntryCreation_Select then
            pcall(LFGListEntryCreation_Select, entryCreation, nil, 2, groupID, actID)
        end
        if entryCreation.selectedActivity ~= actID then
            entryCreation.selectedActivity = actID
            entryCreation.selectedGroup = groupID
            entryCreation.selectedCategory = 2
            if LFGListEntryCreation_UpdateValidState then
                pcall(LFGListEntryCreation_UpdateValidState, entryCreation)
            end
        end
    end

    -- 2. Build Title string (in English unless player disabled englishKeystoneTitles)
    local dInfo = addon.DungeonMap[dungeonId] or addon.DungeonMap[safeLower(dungeonId or "")]
    local dName = dInfo and dInfo.nameEn or (dungeonId or "")
    if addon.db and addon.db.englishKeystoneTitles == false and GetLocale() == "ruRU" then
        dName = dInfo and dInfo.nameRu or dName
    end

    local title = ""
    if level and level > 0 then
        title = "+" .. tostring(level) .. " " .. dName
    else
        title = dName
    end

    if tagsStr and tagsStr ~= "" then
        title = title .. " " .. tagsStr
    end

    -- 3. Set text in native edit box (player can freely edit it afterwards)
    if entryCreation.Name then
        entryCreation.Name:SetText(title)
        entryCreation.Name:SetFocus()
        if entryCreation.Name.HighlightText then
            entryCreation.Name:HighlightText()
        end
    end
end
