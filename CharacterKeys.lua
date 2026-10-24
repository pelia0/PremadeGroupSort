-- Account-wide last confirmed keystones. Only inventory observations establish ownership.
local _, addon = ...
local L = addon.L
local compatibleItems = {[138019] = true, [151086] = true, [158923] = true}
local tooltip = CreateFrame("GameTooltip", "PremadeGroupSort_KeyTooltip", nil, "GameTooltipTemplate")
tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local function identity()
    local name, realm = UnitName("player")
    realm = realm and realm ~= "" and realm or GetRealmName()
    local guid = UnitGUID("player")
    if not name or not realm or not guid then return end
    local _, class = UnitClass("player")
    return realm .. ":" .. guid, name, realm, class
end

local function mapDetails(mapID, dId)
    dId = dId or addon.ChallengeMapToDungeon[mapID]
    local dungeon = dId and addon.DungeonMap[dId]
    local name = dungeon and dungeon.nameEn
    local function readName(getter)
        if type(getter) ~= "function" then return end
        local ok, value = pcall(getter, mapID)
        if ok and type(value) == "string" then
            name = value
            local known = addon.DungeonMap[value] or addon.DungeonMap[addon.safeLower(value)]
            if known then dId = known.id end
        end
    end
    if not name and C_ChallengeMode then
        readName(C_ChallengeMode.GetMapInfo)
        -- Keep compatibility with servers backporting the later API name.
        if not dId then readName(C_ChallengeMode.GetMapUIInfo) end
    end
    return dId, name or string.format(L["KEYS_UNKNOWN_DUNGEON"], mapID or 0)
end

local function readInventory()
    if addon.isWorldLoaded == false then return {status = "unknown"} end
    local incomplete = false
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        if type(slots) ~= "number" or slots < 0 or (bag == 0 and slots == 0) then
            return {status = "unknown"}
        end
        for slot = 1, slots do
            local link = GetContainerItemLink(bag, slot)
            local itemID = GetContainerItemID(bag, slot)
            if not link then
                local texture = GetContainerItemInfo and GetContainerItemInfo(bag, slot)
                if itemID or texture then incomplete = true end
            else
                local mapID, level = link:match("keystone:(%d+):(%d+)")
                mapID, level = tonumber(mapID), tonumber(level)
                if mapID and mapID > 0 and level and level >= 2 then
                    local dId, name = mapDetails(mapID)
                    return {status = "key", mapID = mapID, dId = dId, level = level, dungeonName = name, link = link}
                end
                local lowerLink = addon.safeLower(link)
                if compatibleItems[itemID] or link:find("|Hkeystone:", 1, true)
                    or lowerLink:find("mythic keystone", 1, true)
                    or (lowerLink:find("эпохальн", 1, true) and lowerLink:find("ключ", 1, true)) then
                    -- Some private servers expose the Legion item link plus tooltip instead.
                    tooltip:ClearLines()
                    tooltip:SetBagItem(bag, slot)
                    local dId
                    for i = 1, tooltip:NumLines() do
                        local line = _G["PremadeGroupSort_KeyTooltipTextLeft" .. i]
                        local text = line and line:GetText()
                        if text then
                            level = level or tonumber(text:match("%+(%d+)") or text:match("[lL]evel[^%d]*(%d+)")
                                or text:match("[уУ]ровень[^%d]*(%d+)") or text:match("%((%d+)%)"))
                            for _, d in ipairs(addon.DungeonList) do
                                if d.id ~= "ALL" and (text:find(d.nameEn, 1, true) or text:find(d.nameRu, 1, true)) then
                                    dId = d.id
                                    break
                                end
                            end
                        end
                    end
                    if dId and level and level >= 2 then
                        for id, dungeon in pairs(addon.ChallengeMapToDungeon) do
                            if dungeon == dId then mapID = id; break end
                        end
                        local _, name = mapDetails(mapID, dId)
                        return {status = "key", mapID = mapID, dId = dId, level = level, dungeonName = name, link = link}
                    end
                    incomplete = true
                end
            end
        end
    end
    if incomplete then return {status = "unknown"} end
    -- The receptacle and an active run may temporarily hide the owner's inventory item.
    if C_ChallengeMode then
        if C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() then return {status = "unknown"} end
        if C_ChallengeMode.HasSlottedKeystone and C_ChallengeMode.HasSlottedKeystone() then return {status = "unknown"} end
    end
    return {status = "none"}
end

function addon:InitializeCharacterKeys()
    if type(self.db.characterKeys) ~= "table" then self.db.characterKeys = {} end
    self.keystoneSnapshot = nil
    self.emptyKeystoneAt = nil
    self.keystoneAnnouncementPending = nil
end

function addon:RefreshCharacterKeystone(attempt, announce)
    attempt = attempt or 0
    if announce then self.keystoneAnnouncementPending = true end
    if self.perf then self.perf.bagScans = self.perf.bagScans + 1 end
    local ok, snapshot = pcall(readInventory)
    if not ok then snapshot = {status = "unknown"} end
    if snapshot.status == "none" then
        local now = GetTime()
        if not self.emptyKeystoneAt then self.emptyKeystoneAt = now end
        if now - self.emptyKeystoneAt < 0.5 then snapshot.status = "unknown" end
    else
        self.emptyKeystoneAt = nil
    end
    local previous = self.keystoneSnapshot
    self.keystoneSnapshot = snapshot
    local id, name, realm, class = identity()
    if id and self.db.characterKeys then
        local record = self.db.characterKeys[id]
        if type(record) ~= "table" then record = {}; self.db.characterKeys[id] = record end
        record.name, record.realm, record.class = name, realm, class
        record.unconfirmed = snapshot.status == "unknown" or nil
        if snapshot.status ~= "unknown" then
            record.status = snapshot.status
            record.mapID, record.dId, record.level = snapshot.mapID, snapshot.dId, snapshot.level
            record.dungeonName, record.link = snapshot.dungeonName, snapshot.link
            record.checkedAt = time()
        elseif not record.status then
            record.status = "unknown"
        end
    end
    if snapshot.status == "unknown" and attempt < 3 then
        self:ScheduleTask("owned-key", 0.5 * (attempt + 1), function()
            self:RefreshCharacterKeystone(attempt + 1, announce)
        end)
    elseif self.keystoneAnnouncementPending and snapshot.status ~= "unknown" then
        self.keystoneAnnouncementPending = nil
        self:BroadcastKeystone()
    end
    if not previous or previous.status ~= snapshot.status or previous.mapID ~= snapshot.mapID or previous.level ~= snapshot.level then
        if self.RefreshCreationPanel then self:RefreshCreationPanel() end
    end
    return snapshot
end

function addon:ScheduleKeystoneUpdate(delay)
    self.keystoneAnnouncementPending = true
    self:ScheduleTask("owned-key", delay or 0.25, function()
        self:RefreshCharacterKeystone(0, true)
    end)
end

function addon:GetKeystoneSnapshot()
    return self.keystoneSnapshot or {status = "unknown"}
end

function addon:GetCharacterKeyRows()
    local current = identity()
    local rows = {}
    for id, record in pairs(self.db.characterKeys or {}) do
        if type(record) == "table" and type(record.name) == "string" and type(record.realm) == "string" then
            local row = {}
            for k, v in pairs(record) do row[k] = v end
            row.isCurrent = id == current
            rows[#rows + 1] = row
        end
    end
    table.sort(rows, function(a, b)
        if a.isCurrent ~= b.isCurrent then return a.isCurrent end
        local al = a.status == "key" and tonumber(a.level) or 0
        local bl = b.status == "key" and tonumber(b.level) or 0
        al, bl = al or 0, bl or 0
        if al ~= bl then return al > bl end
        return a.name .. "-" .. a.realm < b.name .. "-" .. b.realm
    end)
    return rows
end

local function ageText(checkedAt)
    if type(checkedAt) ~= "number" then return L["KEYS_UNCONFIRMED"] end
    local seconds = math.max(0, time() - checkedAt)
    if seconds >= 86400 then return string.format(L["KEYS_AGE_DAYS"], math.floor(seconds / 86400)) end
    if seconds >= 3600 then return string.format(L["KEYS_AGE_HOURS"], math.floor(seconds / 3600)) end
    return string.format(L["KEYS_AGE_MINUTES"], math.floor(seconds / 60))
end

function addon:ShowCharacterKeys()
    self:RefreshCharacterKeystone()
    local rows = self:GetCharacterKeyRows()
    print("|cff00ccff[PGS]|r " .. L["KEYS_HEADER"])
    for _, row in ipairs(rows) do
        local text = row.status == "none" and L["KEYS_NONE"] or L["KEYS_UNCONFIRMED"]
        if row.status == "key" and tonumber(row.level) then
            local dungeon = row.dId and self.DungeonMap[row.dId]
            text = (dungeon and dungeon.acronym or row.dungeonName or "?") .. " +" .. row.level
            if type(row.link) == "string" and row.link:find("|H", 1, true) then
                text = row.link:gsub("|h%[.-%]|h", function() return "|h[" .. text .. "]|h" end, 1)
            end
        end
        local suffix = ageText(row.checkedAt)
        if row.isCurrent then suffix = L["KEYS_CURRENT"] .. "; " .. suffix end
        if row.unconfirmed then suffix = suffix .. "; " .. L["KEYS_UNCONFIRMED"] end
        print(string.format("  %s-%s — %s |cff999999[%s]|r", row.name, row.realm, text, suffix))
    end
    if #rows == 0 then print(L["KEYS_EMPTY"]) end
    print("|cff999999" .. L["KEYS_VISIT_HINT"] .. "|r")
end

addon.characterKeysLoaded = true
