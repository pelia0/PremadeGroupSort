-- Event-driven scheduling and bounded legacy-compatible party communication.
local _, addon = ...
local tasks, queue, queued = {}, {}, {}
local broadcasts, requests = {}, {}
local deferredLists, deferredRequests = {}, {}
local groupEpoch = 0
local nextSend = 0
local rosterSignature, guildSignature
addon.perf = {sent = 0, received = 0, bagScans = 0, viewRefreshes = 0}

function addon:ScheduleTask(key, delay, callback)
    if tasks[key] then return end
    local token = {}
    tasks[key] = token
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, function()
            if tasks[key] ~= token then return end
            tasks[key] = nil
            callback()
        end)
    else
        tasks[key] = nil
        callback()
    end
end

function addon:ResumeDeferredSync()
    if self:IsBulkSyncBlocked() then return end
    local lists, asks = deferredLists, deferredRequests
    deferredLists, deferredRequests = {}, {}
    for _, item in pairs(lists) do self:ScheduleListSync(item.prefix, item.channel) end
    for _, item in pairs(asks) do self:RequestListSync(item.prefix, item.channel) end
    if #queue > 0 then self:ScheduleTask("send", 0.25, function() self:PumpMessages() end) end
end

function addon:IsBulkSyncBlocked()
    if InCombatLockdown and InCombatLockdown() then return true end
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive then
        local ok, active = pcall(C_ChallengeMode.IsChallengeModeActive)
        if not ok or active then return true end
    end
    return false
end

local function validChannel(channel)
    if channel == "GUILD" then return IsInGuild() end
    if channel == "RAID" then return IsInRaid() end
    return channel == "PARTY" and IsInGroup() and not IsInRaid()
end

local function validMessage(item)
    if item.cancelled or not validChannel(item.channel) then return false end
    if item.channel ~= "GUILD" then return item.epoch == groupEpoch end
    if item.prefix == "PGS_BL" then return addon.db.syncGuildBlacklist end
    if item.prefix == "PGS_WL" then return addon.db.syncGuildWhitelist end
    return true
end

local function pump()
    local chosen
    for i, item in ipairs(queue) do
        if not validMessage(item) then
            item.cancelled = true
        elseif not item.bulk or not addon:IsBulkSyncBlocked() then
            chosen = i
            break
        end
    end
    if chosen then
        local item = table.remove(queue, chosen)
        if queued[item.key] == item then queued[item.key] = nil end
        local send = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
        if send then
            local ok, result = pcall(send, item.prefix, item.message, item.channel)
            if ok and result ~= false then addon.perf.sent = addon.perf.sent + 1 end
        end
        nextSend = GetTime() + 0.25
    end
    for i = #queue, 1, -1 do
        if queue[i].cancelled then
            if queued[queue[i].key] == queue[i] then queued[queue[i].key] = nil end
            table.remove(queue, i)
        end
    end
    local blocked = addon:IsBulkSyncBlocked()
    for _, item in ipairs(queue) do
        if not item.bulk or not blocked then
            addon:ScheduleTask("send", 0.25, pump)
            break
        end
    end
end

function addon:PumpMessages() pump() end

function addon:QueueAddonMessage(prefix, message, channel, bulk, entry)
    if not validChannel(channel) or type(message) ~= "string" or #message > 250 then return end
    local key = prefix .. ":" .. channel .. ":" .. message
    if queued[key] and validMessage(queued[key]) then return end
    local item = {key = key, prefix = prefix, message = message, channel = channel, bulk = bulk, epoch = groupEpoch, entry = entry}
    queued[key] = item
    queue[#queue + 1] = item
    self:ScheduleTask("send", math.max(0.25, nextSend - GetTime()), pump)
end

function addon:QueueListDelta(prefix, message, channel)
    local entry = message:match("^[^:]+:([^:]+)")
    entry = entry and addon.safeLower(entry)
    -- A pre-edit snapshot must never resurrect a later deleted entry after a run.
    for _, item in ipairs(queue) do
        if item.prefix == prefix and item.channel == channel
            and ((item.bulk and not item.message:find("^REQ_")) or (entry and item.entry == entry)) then
            item.cancelled = true
            if queued[item.key] == item then queued[item.key] = nil end
        end
    end
    broadcasts[prefix .. ":" .. channel] = nil
    self:QueueAddonMessage(prefix, message, channel, false, entry)
    self:ScheduleListSync(prefix, channel)
end

local function channels(target, guildOption)
    if target then return validChannel(target) and {target} or {} end
    local result = {}
    if IsInGroup() then result[#result + 1] = IsInRaid() and "RAID" or "PARTY" end
    if IsInGuild() and addon.db[guildOption] then result[#result + 1] = "GUILD" end
    return result
end

local function listOption(prefix)
    if prefix == "PGS_BL" then return "blacklist", "syncGuildBlacklist", "BL_DATA:", "REQ_BL" end
    return "whitelist", "syncGuildWhitelist", "WL_DATA:", "REQ_WL"
end

local function fitUtf8(text, bytes)
    if #text <= bytes then return text end
    local last = bytes
    while last > 0 do
        local nextByte = text:byte(last + 1)
        if not nextByte or nextByte < 128 or nextByte > 191 then break end
        last = last - 1
    end
    return text:sub(1, math.max(0, last))
end

function addon:ScheduleListSync(prefix, target)
    local store, option, header = listOption(prefix)
    for _, channel in ipairs(channels(target, option)) do
        local key = prefix .. ":" .. channel
        -- Debounce an entire snapshot, not individual chunks or request senders.
        self:ScheduleTask("snapshot:" .. key, 0.5, function()
            if not validChannel(channel) then return end
            if channel == "GUILD" and not self.db[option] then return end
            if self:IsBulkSyncBlocked() then
                deferredLists[key] = {prefix = prefix, channel = channel}
                return
            end
            if broadcasts[key] and GetTime() - broadcasts[key] < 10 then
                self:ScheduleTask("snapshot:" .. key, 10 - (GetTime() - broadcasts[key]), function()
                    self:ScheduleListSync(prefix, channel)
                end)
                return
            end
            broadcasts[key] = GetTime()
            local chunk, length = {}, 0
            local function flush()
                if #chunk > 0 then self:QueueAddonMessage(prefix, header .. table.concat(chunk, ";"), channel, true) end
                chunk, length = {}, 0
            end
            local count = 0
            for name, info in pairs(self.db[store] or {}) do
                if type(info) == "table" then
                    local entryName = tostring(info.name or name):gsub("[;=]", "")
                    local note = tostring(info.reason or info.note or ""):gsub(";", ",")
                    -- Keep each UTF-8 entry within one legacy packet; never truncate mid-character.
                    local item = entryName .. "=" .. fitUtf8(note, 180 - #entryName - 1)
                    if #item <= 180 then
                        if length + #item + 1 > 180 then flush() end
                        chunk[#chunk + 1] = item
                        length = length + #item + 1
                        count = count + 1
                    end
                end
            end
            flush()
            if count == 0 then self:QueueAddonMessage(prefix, header .. "NONE", channel, true) end
        end)
    end
end

function addon:RequestListSync(prefix, target)
    local _, option, _, message = listOption(prefix)
    for _, channel in ipairs(channels(target, option)) do
        local key = prefix .. ":" .. channel
        if not requests[key] or GetTime() - requests[key] >= 10 then
            if self:IsBulkSyncBlocked() then
                deferredRequests[key] = {prefix = prefix, channel = channel}
            else
                requests[key] = GetTime()
                self:QueueAddonMessage(prefix, message, channel, true)
            end
        end
    end
end

function addon:BroadcastCachedKeystone(force)
    if not IsInGroup() then return end
    local dId, level, _, snapshot = self:GetPlayerKeystone()
    if not snapshot or snapshot.status == "unknown" then return end
    if snapshot.status == "key" and not dId then return end
    local channel = IsInRaid() and "RAID" or "PARTY"
    local message = dId and ("KEY:" .. dId .. ":" .. level) or "KEY:NONE:0"
    self.lastKeyBroadcast = self.lastKeyBroadcast or {}
    local previous = self.lastKeyBroadcast[channel]
    if previous and previous.message == message then
        if not force then return end
        if GetTime() - previous.at < 2 then
            local epoch = groupEpoch
            self:ScheduleTask("key-reply:" .. channel, 2 - (GetTime() - previous.at), function()
                if epoch == groupEpoch then self:BroadcastCachedKeystone(true) end
            end)
            return
        end
    end
    self.lastKeyBroadcast[channel] = {message = message, at = GetTime()}
    self:QueueAddonMessage("PGS_KEY", message, channel)
end

function addon:RequestCachedKeystones()
    if not IsInGroup() then return end
    local channel = IsInRaid() and "RAID" or "PARTY"
    local key = "PGS_KEY:" .. channel
    if requests[key] and GetTime() - requests[key] < 2 then return end
    requests[key] = GetTime()
    self:QueueAddonMessage("PGS_KEY", "REQ", channel)
end

function addon:GroupRosterChanged()
    local members = {}
    if IsInGroup() then
        for i = 1, GetNumGroupMembers() do
            local unit = IsInRaid() and ("raid" .. i) or (i == GetNumGroupMembers() and "player" or "party" .. i)
            members[#members + 1] = UnitGUID(unit) or UnitName(unit) or unit
        end
    end
    table.sort(members)
    local signature = (IsInRaid() and "RAID:" or "PARTY:") .. table.concat(members, ";")
    if signature == rosterSignature then return false end
    rosterSignature = signature
    groupEpoch = groupEpoch + 1
    for key in pairs(broadcasts) do if not key:find(":GUILD$") then broadcasts[key] = nil end end
    for key in pairs(requests) do if not key:find(":GUILD$") then requests[key] = nil end end
    for key in pairs(deferredLists) do if not key:find(":GUILD$") then deferredLists[key] = nil end end
    for key in pairs(deferredRequests) do if not key:find(":GUILD$") then deferredRequests[key] = nil end end
    for key in pairs(tasks) do
        if (key:find("^snapshot:") or key:find("^request:") or key:find("^key-reply:"))
            and not key:find(":GUILD$") then tasks[key] = nil end
    end
    self.lastKeyBroadcast = nil
    return true
end

function addon:SyncGroup()
    self:BroadcastCachedKeystone(true)
    self:RequestCachedKeystones()
    self:BroadcastBlacklist()
    self:RequestPartyBlacklist()
    self:BroadcastWhitelist()
    self:RequestPartyWhitelist()
end

function addon:SyncGuild()
    local signature = IsInGuild() and ((GetGuildInfo and GetGuildInfo("player")) or "guild") or ""
    if signature == guildSignature then return end
    guildSignature = signature
    if signature == "" then return end
    for _, prefix in ipairs({"PGS_BL", "PGS_WL"}) do
        local _, option = listOption(prefix)
        if self.db[option] then self:ScheduleListSync(prefix, "GUILD"); self:RequestListSync(prefix, "GUILD") end
    end
end

function addon:ScheduleRemoteViews()
    self:ScheduleTask("remote-views", 0.25, function()
        if self.RefreshCreationPanel then self:RefreshCreationPanel() end
        if self.RefreshBlacklistPanel then self:RefreshBlacklistPanel() end
        local panel = self.optionsBLPanel
        if panel then
            panel.pgsDirty = true
            if panel.IsShown and panel:IsShown() and panel.refresh then panel.refresh() end
        end
    end)
end

function addon:PrintPerformance()
    local p = self.perf
    print(string.format("[PGS] Sent: %d; received: %d; bag scans: %d; view refreshes: %d; queued: %d",
        p.sent, p.received, p.bagScans, p.viewRefreshes, #queue))
end

addon.syncLoaded = true
