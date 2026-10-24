-- PremadeGroupSort UI
local ADDON_NAME, addon = ...
local L = addon.L

local mainPanel = nil
local dungeonBar = nil
local toggleButton = nil
local dungeonButtons = {}
addon.dungeonButtons = dungeonButtons

------------------------------------------------------------------------
-- Helper: Safe Lowercase
------------------------------------------------------------------------
local function safeLower(str)
    if not str then return "" end
    if strlower then return strlower(str) end
    return string.lower(str)
end

------------------------------------------------------------------------
-- Helper: Create Styled Checkbox
------------------------------------------------------------------------
local function CreateCheckBox(parent, name, labelText, tooltipText, x, y, roleTexture, roleCoord)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(22, 22)

    local offset = 26
    if roleTexture and roleCoord then
        local icon = cb:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        icon:SetTexture(roleTexture)
        icon:SetTexCoord(unpack(roleCoord))
        cb.roleIcon = icon
        offset = 48
    end

    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", cb, "LEFT", offset, 0)
    text:SetText(labelText)
    cb.text = text

    if tooltipText then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(labelText, 1, 1, 1)
            GameTooltip:AddLine(tooltipText, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    return cb
end

------------------------------------------------------------------------
-- Helper: Create Preset Button
------------------------------------------------------------------------
local function CreatePresetButton(parent, label, minVal, maxVal, x, y, width)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width or 44, 20)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetText(label)
    btn:SetNormalFontObject("GameFontHighlightSmall")

    btn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.minKey = minVal
        addon.db.maxKey = maxVal
        if parent.minEditBox then parent.minEditBox:SetText(minVal > 0 and tostring(minVal) or "") end
        if parent.maxEditBox then parent.maxEditBox:SetText(maxVal > 0 and tostring(maxVal) or "") end
        addon:RefreshResults()
    end)

    return btn
end

------------------------------------------------------------------------
-- Helper: Create Dungeon Icon Button
------------------------------------------------------------------------
local function CreateDungeonButton(parent, dungeon, x, y)
    local btn = CreateFrame("Button", "PGS_DungeonBtn_" .. dungeon.id, parent)
    btn:SetSize(34, 34)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn.dungeon = dungeon
    btn.dungeonId = dungeon.id

    -- Dark slot background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetColorTexture(0.06, 0.06, 0.09, 0.95)

    -- Icon texture
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    icon:SetTexture(dungeon.icon)
    if not icon:GetTexture() and dungeon.fallback then
        icon:SetTexture(dungeon.fallback)
    end
    icon:SetTexCoord(0, 1, 0, 1)
    btn.icon = icon

    -- Subtle border
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    border:SetTexCoord(0.18, 0.82, 0.18, 0.82)
    btn.border = border

    -- Glowing selection border
    local selBorder = btn:CreateTexture(nil, "OVERLAY")
    selBorder:SetPoint("CENTER", btn, "CENTER", 0, 0)
    selBorder:SetSize(52, 52)
    selBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    selBorder:SetBlendMode("ADD")
    selBorder:SetVertexColor(0.1, 1.0, 0.4, 1.0)
    selBorder:Hide()
    btn.selectedBorder = selBorder

    -- Acronym strip at bottom of button
    local badgeBg = btn:CreateTexture(nil, "OVERLAY")
    badgeBg:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 1, 1)
    badgeBg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    badgeBg:SetHeight(12)
    badgeBg:SetColorTexture(0, 0, 0, 0.78)
    btn.badgeBg = badgeBg

    local badgeText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    badgeText:SetPoint("CENTER", badgeBg, "CENTER", 0, 0)
    badgeText:SetText(dungeon.acronym)
    if dungeon.id == "ALL" then
        badgeText:SetTextColor(1, 0.82, 0)
    else
        badgeText:SetTextColor(1, 1, 1)
    end
    btn.badgeText = badgeText

    -- Mouse highlight
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(btn)
    hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hl:SetBlendMode("ADD")

    -- Pushed state
    local pushed = btn:CreateTexture(nil, "PUSHED")
    pushed:SetAllPoints(btn)
    pushed:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")

    -- Click Handler
    btn:RegisterForClicks("LeftButtonUp")
    btn:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ToggleDungeonSelection(self.dungeonId, IsShiftKeyDown())
    end)

    -- Tooltip Handlers
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local isRu = (GetLocale() == "ruRU")
        local dName = isRu and self.dungeon.nameRu or self.dungeon.nameEn
        GameTooltip:SetText(dName, 1, 0.82, 0)

        local isSelected = addon:IsDungeonSelected(self.dungeonId)
        if self.dungeonId == "ALL" then
            if isSelected then
                GameTooltip:AddLine(L["TOOLTIP_DUNGEON_SELECTED"], 0.2, 1.0, 0.2)
            else
                GameTooltip:AddLine(L["TOOLTIP_CLICK_DUNGEON"], 0.8, 0.8, 0.8)
            end
        else
            if isSelected then
                GameTooltip:AddLine(L["TOOLTIP_MULTI_SELECTED"], 0.2, 1.0, 0.2)
            else
                GameTooltip:AddLine(L["TOOLTIP_CLICK_DUNGEON_SINGLE"], 0.8, 0.8, 0.8)
                GameTooltip:AddLine(L["TOOLTIP_SHIFT_CLICK_MULTI"], 0.6, 0.8, 1.0)
            end
        end

        if self.dungeon.keywords and #self.dungeon.keywords > 0 then
            local kwStr = table.concat(self.dungeon.keywords, ", ")
            GameTooltip:AddLine("|cff777777" .. kwStr .. "|r", 0.6, 0.6, 0.6, true)
        end

        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return btn
end

------------------------------------------------------------------------
-- Update Dungeon Bar Selection Visuals
------------------------------------------------------------------------
function addon:UpdateDungeonBarSelection()
    if not dungeonButtons then return end

    local selCount = addon:GetSelectedDungeonsCount()
    local isAll = (selCount == 0)

    for id, btn in pairs(dungeonButtons) do
        local isThisSelected = false
        if id == "ALL" then
            isThisSelected = isAll
        else
            isThisSelected = addon:IsDungeonSelected(id)
        end

        if isThisSelected then
            if btn.selectedBorder then btn.selectedBorder:Show() end
            btn:SetAlpha(1.0)
            if btn.badgeBg then
                if id == "ALL" then
                    btn.badgeBg:SetColorTexture(0.35, 0.28, 0, 0.9)
                else
                    btn.badgeBg:SetColorTexture(0, 0.38, 0.18, 0.92)
                end
            end
        else
            if btn.selectedBorder then btn.selectedBorder:Hide() end
            if isAll then
                btn:SetAlpha(0.9)
            else
                btn:SetAlpha(0.55)
            end
            if btn.badgeBg then
                btn.badgeBg:SetColorTexture(0, 0, 0, 0.78)
            end
        end
    end
end

------------------------------------------------------------------------
-- Helper: Anchor Main Panel next to DungeonBar or LFGListFrame
------------------------------------------------------------------------
function addon:AnchorMainPanel()
    if not mainPanel then return end
    mainPanel:ClearAllPoints()
    if dungeonBar and dungeonBar:IsShown() then
        mainPanel:SetPoint("TOPLEFT", dungeonBar, "TOPRIGHT", 2, 0)
    else
        mainPanel:SetPoint("TOPLEFT", LFGListFrame, "TOPRIGHT", 2, 0)
    end
end

local function UpdateFiltersBtnText()
    if not dungeonBar or not dungeonBar.filtersBtn then return end
    local isRu = (GetLocale() == "ruRU")
    local filterWord = isRu and "Фильтры" or "Filters"
    if mainPanel and mainPanel:IsShown() then
        dungeonBar.filtersBtn:SetText("<< " .. filterWord)
    else
        dungeonBar.filtersBtn:SetText(filterWord .. " >>")
    end
end

------------------------------------------------------------------------
-- Update Overall Panels Visibility (Only in Dungeons SearchPanel)
------------------------------------------------------------------------
function addon:UpdatePanelVisibility()
    local searchPanel = LFGListFrame and LFGListFrame.SearchPanel
    local entryCreation = LFGListFrame and LFGListFrame.EntryCreation

    -- If EntryCreation is shown: show CreationPanel, hide search panels
    if entryCreation and entryCreation:IsShown() then
        if dungeonBar then dungeonBar:Hide() end
        if mainPanel then mainPanel:Hide() end
        if addon.creationPanel then
            addon.creationPanel:Show()
            addon:RefreshCreationPanel()
        end
        return
    else
        if addon.creationPanel then
            addon.creationPanel:Hide()
        end
    end

    -- If SearchPanel is not shown or user is on CategorySelection / elsewhere, hide panels
    if not searchPanel or not searchPanel:IsShown() then
        if dungeonBar then dungeonBar:Hide() end
        if mainPanel then mainPanel:Hide() end
        return
    end

    -- In 7.3.5, categoryID 2 is Dungeons. If categoryID is set and ~= 2 (e.g. Raids or Quests), do not show
    local catID = searchPanel.categoryID
    if not catID and LFGListFrame then
        if LFGListFrame.CategorySelection and LFGListFrame.CategorySelection.selectedCategory then
            catID = LFGListFrame.CategorySelection.selectedCategory
        end
    end
    if not catID and searchPanel.results and searchPanel.results[1] and C_LFGList and C_LFGList.GetSearchResultInfo and C_LFGList.GetActivityInfo then
        local _, firstAct = C_LFGList.GetSearchResultInfo(searchPanel.results[1])
        if firstAct then
            local _, _, aCat = C_LFGList.GetActivityInfo(firstAct)
            if aCat then catID = aCat end
        end
    end

    if catID and catID ~= 2 then
        if dungeonBar then dungeonBar:Hide() end
        if mainPanel then mainPanel:Hide() end
        return
    end

    -- If user has dungeonBar enabled in settings, show it
    if dungeonBar then
        dungeonBar:SetShown(addon.db.dungeonBarOpen)
    end

    -- If user has extended mainPanel enabled in settings, show it
    if mainPanel then
        mainPanel:SetShown(addon.db.panelOpen)
    end

    addon:AnchorMainPanel()
    UpdateFiltersBtnText()
end

------------------------------------------------------------------------
-- Toggle Main Panel / PVE Group Finder (/pgs)
------------------------------------------------------------------------
function addon:ToggleMainPanel()
    -- If already open on the Dungeons search panel, toggle it closed
    if PVEFrame and PVEFrame:IsShown() and LFGListFrame and LFGListFrame.SearchPanel and LFGListFrame.SearchPanel:IsShown() then
        HideUIPanel(PVEFrame)
        return
    end

    -- Open PVEFrame to Group Finder / LFG List
    PVEFrame_ShowFrame("GroupFinderFrame", "LFGListPVEStub")

    local function OpenDungeonSearchInternal()
        if not LFGListFrame then return end

        -- If user already has an active listing or is viewing applicants, stay on ApplicationViewer
        if C_LFGList and C_LFGList.HasActiveEntryInfo and C_LFGList.HasActiveEntryInfo() then
            if addon.UpdatePanelVisibility then addon:UpdatePanelVisibility() end
            return
        end

        -- If already on SearchPanel, make sure panels are shown
        if LFGListFrame.SearchPanel and LFGListFrame.SearchPanel:IsShown() then
            if addon.dungeonBar then
                addon.db.dungeonBarOpen = true
                addon.dungeonBar:Show()
            end
            if addon.UpdatePanelVisibility then addon:UpdatePanelVisibility() end
            return
        end

        -- If on CategorySelection, select Dungeons (category 2) and click Search immediately!
        if LFGListFrame.CategorySelection then
            local dungeonBtn = nil
            if LFGListFrame.CategorySelection.CategoryButtons then
                for _, b in ipairs(LFGListFrame.CategorySelection.CategoryButtons) do
                    if b.categoryID == 2 then
                        dungeonBtn = b
                        break
                    end
                end
            end
            if dungeonBtn then
                dungeonBtn:Click()
            elseif LFGListCategorySelection_SelectCategory then
                LFGListCategorySelection_SelectCategory(LFGListFrame.CategorySelection, 2, 0)
            end

            if LFGListFrame.CategorySelection.FindGroupButton and LFGListFrame.CategorySelection.FindGroupButton:IsEnabled() then
                LFGListFrame.CategorySelection.FindGroupButton:Click()
            end
        end

        if addon.dungeonBar then
            addon.db.dungeonBarOpen = true
            addon.dungeonBar:Show()
        end
        if addon.UpdatePanelVisibility then
            addon:UpdatePanelVisibility()
        end
    end

    OpenDungeonSearchInternal()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, OpenDungeonSearchInternal)
    end
end


------------------------------------------------------------------------
-- Build Dungeon Bar (Sidebar with Dungeon Icons)
------------------------------------------------------------------------
function addon:CreateDungeonBar()
    if dungeonBar or not LFGListFrame then return end

    dungeonBar = CreateFrame("Frame", "PremadeGroupSort_DungeonBar", LFGListFrame)
    dungeonBar:SetSize(90, 428)
    dungeonBar:SetPoint("TOPLEFT", LFGListFrame, "TOPRIGHT", 2, 0)
    dungeonBar:SetFrameStrata("HIGH")
    dungeonBar:EnableMouse(true)

    -- Backdrop
    dungeonBar:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    dungeonBar:SetBackdropColor(0.08, 0.08, 0.1, 0.95)

    -- Title
    local title = dungeonBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", dungeonBar, "TOP", 0, -10)
    title:SetText("|cff00ccff" .. (L["DUNGEON_BAR_TITLE"] or "Dungeons") .. "|r")

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, dungeonBar, "UIPanelCloseButton")
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", dungeonBar, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        addon.db.dungeonBarOpen = false
        addon:UpdatePanelVisibility()
    end)

    -- 14 Dungeon Buttons (2 columns of 7 rows)
    -- Column 1: x = 8, Column 2: x = 48
    -- Row 0: y = -30, gap = 38
    local dList = addon.DungeonList or {}
    for i = 1, #dList do
        local dungeon = dList[i]
        local zeroIdx = i - 1
        local col = zeroIdx % 2
        local row = math.floor(zeroIdx / 2)

        local x = (col == 0) and 8 or 48
        local y = -30 - (row * 38)

        local btn = CreateDungeonButton(dungeonBar, dungeon, x, y)
        dungeonButtons[dungeon.id] = btn
    end

    -- Separator below dungeon icons
    local sep = dungeonBar:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", dungeonBar, "TOPLEFT", 6, -298)
    sep:SetPoint("TOPRIGHT", dungeonBar, "TOPRIGHT", -6, -298)
    sep:SetColorTexture(0.3, 0.3, 0.35, 0.8)

    -- Toggle Filters Panel Button
    local filtersBtn = CreateFrame("Button", nil, dungeonBar, "UIPanelButtonTemplate")
    filtersBtn:SetSize(76, 22)
    filtersBtn:SetPoint("TOP", dungeonBar, "TOP", 0, -308)
    filtersBtn:SetNormalFontObject("GameFontNormalSmall")
    filtersBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        if not mainPanel then
            addon:CreateMainPanel()
        end
        addon.db.panelOpen = not addon.db.panelOpen
        addon:UpdatePanelVisibility()
    end)
    filtersBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["HEADER_TITLE"], 1, 1, 1)
        GameTooltip:AddLine(L["TOGGLE_FILTERS_PANEL"], nil, nil, nil, true)
        GameTooltip:Show()
    end)
    filtersBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    dungeonBar.filtersBtn = filtersBtn

    -- Reset Button
    local resetBtn = CreateFrame("Button", nil, dungeonBar, "UIPanelButtonTemplate")
    resetBtn:SetSize(76, 20)
    resetBtn:SetPoint("TOP", dungeonBar, "TOP", 0, -334)
    resetBtn:SetText(L["RESET_BUTTON"])
    resetBtn:SetNormalFontObject("GameFontHighlightSmall")
    resetBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ResetFilters()
    end)
    resetBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["RESET_BUTTON"], 1, 1, 1)
        GameTooltip:AddLine(L["RESET_TOOLTIP"], nil, nil, nil, true)
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    dungeonBar.resetBtn = resetBtn

    -- M+ Only Checkbox
    local mPlusCB = CreateCheckBox(dungeonBar, "PGS_Bar_MPlusCB", "M+", L["ONLY_MYTHIC_PLUS_TOOLTIP"], 8, -358)
    mPlusCB:SetScript("OnClick", function(self)
        addon.db.onlyMythicPlus = self:GetChecked()
        if mainPanel and mainPanel.onlyMPlusCB then
            mainPanel.onlyMPlusCB:SetChecked(self:GetChecked())
        end
        addon:RefreshResults()
    end)
    dungeonBar.mPlusCB = mPlusCB

    -- Blacklist / Whitelist Button [ЧС / БС]
    local blBtn = CreateFrame("Button", nil, dungeonBar, "UIPanelButtonTemplate")
    blBtn:SetSize(74, 22)
    blBtn:SetPoint("BOTTOM", dungeonBar, "BOTTOM", 0, 26)
    blBtn:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12:12:0:0|t" .. (L["BL_BUTTON"] or "ЧС") .. "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12:12:0:0|t")
    blBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ToggleBlacklistPanel()
    end)
    blBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["BL_TITLE"] .. " / " .. L["WL_TITLE"], 1, 0.82, 0)
        GameTooltip:AddLine(L["BL_BUTTON_TOOLTIP"], 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine(L["WL_BUTTON_TOOLTIP"], 0.2, 1.0, 0.2, true)
        GameTooltip:Show()
    end)
    blBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    dungeonBar.blBtn = blBtn

    -- Count Status Text
    local statusText = dungeonBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("BOTTOM", dungeonBar, "BOTTOM", 0, 8)
    statusText:SetText("")
    dungeonBar.statusText = statusText

    -- Start hidden until SearchPanel is shown
    dungeonBar:Hide()

    addon.dungeonBar = dungeonBar
    addon:UpdateDungeonBarSelection()
    UpdateFiltersBtnText()
end

------------------------------------------------------------------------
-- Build Main Panel (Extended Roles, Keys, Sort)
------------------------------------------------------------------------
function addon:CreateMainPanel()
    if mainPanel then return end

    mainPanel = CreateFrame("Frame", "PremadeGroupSort_MainPanel", LFGListFrame)
    mainPanel:SetSize(280, 485)
    mainPanel:SetFrameStrata("HIGH")
    mainPanel:EnableMouse(true)
    addon:AnchorMainPanel()

    -- Backdrop
    mainPanel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    mainPanel:SetBackdropColor(0.08, 0.08, 0.1, 0.95)

    -- Title
    local title = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 14, -12)
    title:SetText("|cff00ccff" .. L["HEADER_TITLE"] .. "|r")

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, mainPanel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainPanel, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        addon.db.panelOpen = false
        addon:UpdatePanelVisibility()
    end)

    -- Reset Button
    local resetBtn = CreateFrame("Button", nil, mainPanel, "UIPanelButtonTemplate")
    resetBtn:SetSize(56, 20)
    resetBtn:SetPoint("RIGHT", closeBtn, "LEFT", 2, 0)
    resetBtn:SetText(L["RESET_BUTTON"])
    resetBtn:SetNormalFontObject("GameFontNormalSmall")
    resetBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ResetFilters()
    end)
    resetBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["RESET_TOOLTIP"], nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    --------------------------------------------------------------------
    -- 1. Dungeon Filter Section
    --------------------------------------------------------------------
    local dSep = mainPanel:CreateTexture(nil, "ARTWORK")
    dSep:SetHeight(1)
    dSep:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 10, -32)
    dSep:SetPoint("TOPRIGHT", mainPanel, "TOPRIGHT", -10, -32)
    dSep:SetColorTexture(0.3, 0.3, 0.35, 0.8)

    local dLabel = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dLabel:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 14, -38)
    dLabel:SetText(L["FILTER_DUNGEON"])

    -- Dungeon Dropdown
    local dDrop = CreateFrame("Frame", "PremadeGroupSort_DungeonDropDown", mainPanel, "UIDropDownMenuTemplate")
    dDrop:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 0, -52)
    UIDropDownMenu_SetWidth(dDrop, 226)
    UIDropDownMenu_JustifyText(dDrop, "LEFT")

    local function DungeonDropDown_OnClick(self)
        UIDropDownMenu_SetSelectedValue(dDrop, self.value)
        addon:SetSelectedDungeon(self.value)
    end

    local function DungeonDropDown_Initialize(self, level)
        local cur = addon.db.selectedDungeon or ""
        local curInfo = addon.DungeonMap[cur] or addon.DungeonMap[safeLower(cur)]
        local curId = curInfo and curInfo.id or cur

        local info = UIDropDownMenu_CreateInfo()
        info.text = L["ALL_DUNGEONS"]
        info.value = ""
        info.func = DungeonDropDown_OnClick
        info.checked = (curId == "" or curId == "ALL")
        UIDropDownMenu_AddButton(info, level)

        local isRu = (GetLocale() == "ruRU")
        local dList = addon.DungeonList or {}
        for i = 1, #dList do
            local d = dList[i]
            if d.id ~= "ALL" then
                info = UIDropDownMenu_CreateInfo()
                info.text = isRu and d.nameRu or d.nameEn
                info.value = d.id
                info.func = DungeonDropDown_OnClick
                info.checked = (curId == d.id)
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end

    UIDropDownMenu_Initialize(dDrop, DungeonDropDown_Initialize)
    mainPanel.dungeonDropDown = dDrop

    -- Only M+ Checkbox
    local onlyMPlusCB = CreateCheckBox(mainPanel, "PGS_OnlyMPlusCB", L["ONLY_MYTHIC_PLUS"], L["ONLY_MYTHIC_PLUS_TOOLTIP"], 10, -84)
    onlyMPlusCB:SetScript("OnClick", function(self)
        addon.db.onlyMythicPlus = self:GetChecked()
        if dungeonBar and dungeonBar.mPlusCB then
            dungeonBar.mPlusCB:SetChecked(self:GetChecked())
        end
        addon:RefreshResults()
    end)
    mainPanel.onlyMPlusCB = onlyMPlusCB

    --------------------------------------------------------------------
    -- 2. Keystone Level Range Section
    --------------------------------------------------------------------
    local kSep = mainPanel:CreateTexture(nil, "ARTWORK")
    kSep:SetHeight(1)
    kSep:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 10, -112)
    kSep:SetPoint("TOPRIGHT", mainPanel, "TOPRIGHT", -10, -112)
    kSep:SetColorTexture(0.3, 0.3, 0.35, 0.8)

    local kLabel = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    kLabel:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 14, -118)
    kLabel:SetText(L["KEY_LEVEL_HEADER"])

    -- Min Key
    local minLabel = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minLabel:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 14, -137)
    minLabel:SetText(L["KEY_FROM"])

    local minBox = CreateFrame("EditBox", "PGS_MinKeyBox", mainPanel, "InputBoxTemplate")
    minBox:SetSize(34, 18)
    minBox:SetPoint("LEFT", minLabel, "RIGHT", 6, 0)
    minBox:SetAutoFocus(false)
    minBox:SetNumeric(true)
    minBox:SetMaxLetters(2)
    minBox:SetScript("OnTextChanged", function(self)
        local val = tonumber(self:GetText()) or 0
        addon.db.minKey = val
        addon:RefreshResults()
    end)
    minBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    mainPanel.minEditBox = minBox

    -- Max Key
    local maxLabel = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    maxLabel:SetPoint("LEFT", minBox, "RIGHT", 14, 0)
    maxLabel:SetText(L["KEY_TO"])

    local maxBox = CreateFrame("EditBox", "PGS_MaxKeyBox", mainPanel, "InputBoxTemplate")
    maxBox:SetSize(34, 18)
    maxBox:SetPoint("LEFT", maxLabel, "RIGHT", 6, 0)
    maxBox:SetAutoFocus(false)
    maxBox:SetNumeric(true)
    maxBox:SetMaxLetters(2)
    maxBox:SetScript("OnTextChanged", function(self)
        local val = tonumber(self:GetText()) or 0
        addon.db.maxKey = val
        addon:RefreshResults()
    end)
    maxBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    mainPanel.maxEditBox = maxBox

    -- Quick Presets Row: [ Все ] [ 2-5 ] [ 6-9 ] [ 10-14 ] [ 15+ ]
    CreatePresetButton(mainPanel, L["KEY_ALL"], 0, 0, 14, -162, 44)
    CreatePresetButton(mainPanel, "2-5", 2, 5, 62, -162, 44)
    CreatePresetButton(mainPanel, "6-9", 6, 9, 110, -162, 44)
    CreatePresetButton(mainPanel, "10-14", 10, 14, 158, -162, 50)
    CreatePresetButton(mainPanel, "15+", 15, 0, 212, -162, 44)

    --------------------------------------------------------------------
    -- 3. Roles Section (Needed & Present)
    --------------------------------------------------------------------
    local rSep = mainPanel:CreateTexture(nil, "ARTWORK")
    rSep:SetHeight(1)
    rSep:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 10, -190)
    rSep:SetPoint("TOPRIGHT", mainPanel, "TOPRIGHT", -10, -190)
    rSep:SetColorTexture(0.3, 0.3, 0.35, 0.8)

    local rNeedLabel = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rNeedLabel:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 14, -196)
    rNeedLabel:SetText(L["ROLES_NEEDED_HEADER"])

    -- Needed: Tank, Healer, DPS
    local tankCoord = { GetTexCoordsForRole("TANK") }
    local healCoord = { GetTexCoordsForRole("HEALER") }
    local dpsCoord  = { GetTexCoordsForRole("DAMAGER") }

    local needTankCB = CreateCheckBox(mainPanel, "PGS_NeedTankCB", L["NEED_TANK"], L["NEED_TANK_TOOLTIP"], 10, -214, "Interface\\LFGFrame\\UI-LFG-ICON-ROLES", tankCoord)
    needTankCB:SetScript("OnClick", function(self)
        addon.db.needTank = self:GetChecked()
        if self:GetChecked() then
            addon.db.hasTank = false
            mainPanel.hasTankCB:SetChecked(false)
        end
        addon:RefreshResults()
    end)
    mainPanel.needTankCB = needTankCB

    local needHealCB = CreateCheckBox(mainPanel, "PGS_NeedHealCB", L["NEED_HEALER"], L["NEED_HEALER_TOOLTIP"], 140, -214, "Interface\\LFGFrame\\UI-LFG-ICON-ROLES", healCoord)
    needHealCB:SetScript("OnClick", function(self)
        addon.db.needHealer = self:GetChecked()
        if self:GetChecked() then
            addon.db.hasHealer = false
            mainPanel.hasHealCB:SetChecked(false)
        end
        addon:RefreshResults()
    end)
    mainPanel.needHealCB = needHealCB

    local needDPSCB = CreateCheckBox(mainPanel, "PGS_NeedDPSCB", L["NEED_DPS"], L["NEED_DPS_TOOLTIP"], 10, -240, "Interface\\LFGFrame\\UI-LFG-ICON-ROLES", dpsCoord)
    needDPSCB:SetScript("OnClick", function(self)
        addon.db.needDPS = self:GetChecked()
        addon:RefreshResults()
    end)
    mainPanel.needDPSCB = needDPSCB

    -- Present: Has Tank, Has Healer
    local hasTankCB = CreateCheckBox(mainPanel, "PGS_HasTankCB", L["HAS_TANK"], L["HAS_TANK_TOOLTIP"], 10, -266, "Interface\\LFGFrame\\UI-LFG-ICON-ROLES", tankCoord)
    hasTankCB:SetScript("OnClick", function(self)
        addon.db.hasTank = self:GetChecked()
        if self:GetChecked() then
            addon.db.needTank = false
            mainPanel.needTankCB:SetChecked(false)
        end
        addon:RefreshResults()
    end)
    mainPanel.hasTankCB = hasTankCB

    local hasHealCB = CreateCheckBox(mainPanel, "PGS_HasHealCB", L["HAS_HEALER"], L["HAS_HEALER_TOOLTIP"], 140, -266, "Interface\\LFGFrame\\UI-LFG-ICON-ROLES", healCoord)
    hasHealCB:SetScript("OnClick", function(self)
        addon.db.hasHealer = self:GetChecked()
        if self:GetChecked() then
            addon.db.needHealer = false
            mainPanel.needHealCB:SetChecked(false)
        end
        addon:RefreshResults()
    end)
    mainPanel.hasHealCB = hasHealCB

    -- Fits My Role
    local fitRoleCB = CreateCheckBox(mainPanel, "PGS_FitRoleCB", L["FIT_MY_ROLE"], L["FIT_MY_ROLE_TOOLTIP"], 10, -292)
    fitRoleCB:SetScript("OnClick", function(self)
        addon.db.fitMyRole = self:GetChecked()
        addon:RefreshResults()
    end)
    mainPanel.fitRoleCB = fitRoleCB

    --------------------------------------------------------------------
    -- 4. Group Age Filter Section (Hide Old/Stale Groups)
    --------------------------------------------------------------------
    local aSep = mainPanel:CreateTexture(nil, "ARTWORK")
    aSep:SetHeight(1)
    aSep:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 10, -318)
    aSep:SetPoint("TOPRIGHT", mainPanel, "TOPRIGHT", -10, -318)
    aSep:SetColorTexture(0.3, 0.3, 0.35, 0.8)

    local hideOldCB = CreateCheckBox(mainPanel, "PGS_HideOldCB", L["HIDE_OLD_GROUPS"], L["HIDE_OLD_GROUPS_TOOLTIP"], 10, -324)
    hideOldCB:SetScript("OnClick", function(self)
        addon.db.hideOldGroups = self:GetChecked()
        if mainPanel.ageDropDown then
            if self:GetChecked() then
                if UIDropDownMenu_EnableDropDown then
                    UIDropDownMenu_EnableDropDown(mainPanel.ageDropDown)
                end
            else
                if UIDropDownMenu_DisableDropDown then
                    UIDropDownMenu_DisableDropDown(mainPanel.ageDropDown)
                end
            end
        end
        addon:RefreshResults()
    end)
    mainPanel.hideOldCB = hideOldCB

    -- Group Age DropDown
    local ageDrop = CreateFrame("Frame", "PremadeGroupSort_AgeDropDown", mainPanel, "UIDropDownMenuTemplate")
    ageDrop:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 0, -348)
    UIDropDownMenu_SetWidth(ageDrop, 226)
    UIDropDownMenu_JustifyText(ageDrop, "LEFT")

    local ageOptions = {
        { mins = 15, text = L["GROUP_AGE_15M"] },
        { mins = 30, text = L["GROUP_AGE_30M"] },
        { mins = 45, text = L["GROUP_AGE_45M"] },
        { mins = 60, text = L["GROUP_AGE_60M"] },
        { mins = 90, text = L["GROUP_AGE_90M"] },
        { mins = 120, text = L["GROUP_AGE_120M"] },
    }

    local function AgeDropDown_OnClick(self)
        UIDropDownMenu_SetSelectedValue(ageDrop, self.value)
        addon.db.maxGroupAge = self.value
        UIDropDownMenu_SetText(ageDrop, self.text)
        if not addon.db.hideOldGroups then
            addon.db.hideOldGroups = true
            if mainPanel.hideOldCB then
                mainPanel.hideOldCB:SetChecked(true)
            end
            if UIDropDownMenu_EnableDropDown then
                UIDropDownMenu_EnableDropDown(ageDrop)
            end
        end
        addon:RefreshResults()
    end

    local function AgeDropDown_Initialize(self, level)
        local curVal = addon.db.maxGroupAge or 30
        for _, opt in ipairs(ageOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.text
            info.value = opt.mins
            info.func = AgeDropDown_OnClick
            info.checked = (curVal == opt.mins)
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(ageDrop, AgeDropDown_Initialize)
    mainPanel.ageDropDown = ageDrop

    --------------------------------------------------------------------
    -- 5. Sorting Section
    --------------------------------------------------------------------
    local sSep = mainPanel:CreateTexture(nil, "ARTWORK")
    sSep:SetHeight(1)
    sSep:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 10, -382)
    sSep:SetPoint("TOPRIGHT", mainPanel, "TOPRIGHT", -10, -382)
    sSep:SetColorTexture(0.3, 0.3, 0.35, 0.8)

    local sLabel = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sLabel:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 14, -388)
    sLabel:SetText(L["SORT_HEADER"])

    -- Sort DropDown
    local sDrop = CreateFrame("Frame", "PremadeGroupSort_SortDropDown", mainPanel, "UIDropDownMenuTemplate")
    sDrop:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 0, -404)
    UIDropDownMenu_SetWidth(sDrop, 226)
    UIDropDownMenu_JustifyText(sDrop, "LEFT")

    local sortOptions = {
        { id = "KEY_DESC", text = L["SORT_KEY_DESC"] },
        { id = "KEY_ASC", text = L["SORT_KEY_ASC"] },
        { id = "DUNGEON_ASC", text = L["SORT_DUNGEON_ASC"] },
        { id = "ROLE_TANK", text = L["SORT_ROLE_TANK"] },
        { id = "ROLE_HEAL", text = L["SORT_ROLE_HEAL"] },
        { id = "ROLE_DPS", text = L["SORT_ROLE_DPS"] },
        { id = "SLOTS_DESC", text = L["SORT_SLOTS_DESC"] },
        { id = "TIME_DESC", text = L["SORT_TIME_DESC"] },
        { id = "ILVL_DESC", text = L["SORT_ILVL_DESC"] },
        { id = "DEFAULT", text = L["SORT_DEFAULT"] },
    }

    local function SortDropDown_OnClick(self)
        UIDropDownMenu_SetSelectedValue(sDrop, self.value)
        addon.db.sortMode = self.value
        UIDropDownMenu_SetText(sDrop, self.text)
        addon:RefreshResults()
    end

    local function SortDropDown_Initialize(self, level)
        for _, opt in ipairs(sortOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.text
            info.value = opt.id
            info.func = SortDropDown_OnClick
            info.checked = (addon.db.sortMode == opt.id)
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(sDrop, SortDropDown_Initialize)
    mainPanel.sortDropDown = sDrop

    --------------------------------------------------------------------
    -- 5. Footer Status Section
    --------------------------------------------------------------------
    local footSep = mainPanel:CreateTexture(nil, "ARTWORK")
    footSep:SetHeight(1)
    footSep:SetPoint("BOTTOMLEFT", mainPanel, "BOTTOMLEFT", 10, 34)
    footSep:SetPoint("BOTTOMRIGHT", mainPanel, "BOTTOMRIGHT", -10, 34)
    footSep:SetColorTexture(0.3, 0.3, 0.35, 0.8)

    local statusText = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("BOTTOMLEFT", mainPanel, "BOTTOMLEFT", 14, 12)
    statusText:SetText(string.format(L["RESULTS_STATUS"], 0, 0))
    mainPanel.statusText = statusText

    -- Whitelist Button [БС] & Blacklist Button [ЧС]
    local wlBtn = CreateFrame("Button", nil, mainPanel, "UIPanelButtonTemplate")
    wlBtn:SetSize(46, 22)
    wlBtn:SetPoint("BOTTOMRIGHT", mainPanel, "BOTTOMRIGHT", -10, 8)
    wlBtn:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12:12:0:0|t" .. (L["WL_BUTTON"] or "БС"))
    wlBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ToggleWhitelistPanel()
    end)
    wlBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["WL_TITLE"] or "Белый список", 1, 0.82, 0)
        GameTooltip:AddLine(L["WL_BUTTON_TOOLTIP"], 0.2, 1.0, 0.2, true)
        GameTooltip:Show()
    end)
    wlBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    mainPanel.wlBtn = wlBtn

    local blBtn = CreateFrame("Button", nil, mainPanel, "UIPanelButtonTemplate")
    blBtn:SetSize(46, 22)
    blBtn:SetPoint("RIGHT", wlBtn, "LEFT", -4, 0)
    blBtn:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12:12:0:0|t" .. (L["BL_BUTTON"] or "ЧС"))
    blBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ToggleBlacklistPanel("blacklist")
    end)
    blBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["BL_TITLE"], 1, 0.82, 0)
        GameTooltip:AddLine(L["BL_BUTTON_TOOLTIP"], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    blBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    mainPanel.blBtn = blBtn

    -- Start hidden until SearchPanel is shown
    mainPanel:Hide()

    mainPanel:HookScript("OnShow", function()
        addon:AnchorMainPanel()
        UpdateFiltersBtnText()
    end)
    mainPanel:HookScript("OnHide", function()
        UpdateFiltersBtnText()
    end)

    addon.mainPanel = mainPanel
    addon:SyncUIWithDB()
end

------------------------------------------------------------------------
-- Update Status Text (Both Panels)
------------------------------------------------------------------------
function addon:UpdateStatusText(filteredCount, rawCount)
    if mainPanel and mainPanel.statusText then
        if filteredCount == rawCount then
            mainPanel.statusText:SetFormattedText(L["RESULTS_STATUS_NO_FILTER"], rawCount)
        else
            mainPanel.statusText:SetFormattedText(L["RESULTS_STATUS"], filteredCount, rawCount)
        end
    end

    if dungeonBar and dungeonBar.statusText then
        dungeonBar.statusText:SetFormattedText("%d / %d", filteredCount, rawCount)
    end
end

------------------------------------------------------------------------
-- Sync UI Controls with Database
------------------------------------------------------------------------
function addon:SyncUIWithDB()
    local db = addon.db

    -- Update Dungeon Bar selection
    addon:UpdateDungeonBarSelection()

    -- DungeonBar M+ checkbox
    if dungeonBar and dungeonBar.mPlusCB then
        dungeonBar.mPlusCB:SetChecked(db.onlyMythicPlus)
    end

    if not mainPanel then return end

    -- Dungeon DropDown text
    if mainPanel.dungeonDropDown then
        local text = L["ALL_DUNGEONS"]
        local selCount = addon:GetSelectedDungeonsCount()
        local isRu = (GetLocale() == "ruRU")
        if selCount == 1 then
            for id, active in pairs(db.selectedDungeons) do
                if active then
                    local dInfo = addon.DungeonMap[id]
                    text = dInfo and (isRu and dInfo.nameRu or dInfo.nameEn) or id
                    break
                end
            end
        elseif selCount > 1 then
            local list = {}
            for id, active in pairs(db.selectedDungeons) do
                if active then
                    local dInfo = addon.DungeonMap[id]
                    table.insert(list, dInfo and dInfo.acronym or id)
                end
            end
            table.sort(list)
            text = table.concat(list, ", ") .. " (" .. tostring(selCount) .. ")"
        end
        UIDropDownMenu_SetText(mainPanel.dungeonDropDown, text)
    end

    -- Checkboxes
    if mainPanel.onlyMPlusCB then mainPanel.onlyMPlusCB:SetChecked(db.onlyMythicPlus) end
    if mainPanel.needTankCB then mainPanel.needTankCB:SetChecked(db.needTank) end
    if mainPanel.needHealCB then mainPanel.needHealCB:SetChecked(db.needHealer) end
    if mainPanel.needDPSCB then mainPanel.needDPSCB:SetChecked(db.needDPS) end
    if mainPanel.hasTankCB then mainPanel.hasTankCB:SetChecked(db.hasTank) end
    if mainPanel.hasHealCB then mainPanel.hasHealCB:SetChecked(db.hasHealer) end
    if mainPanel.fitRoleCB then mainPanel.fitRoleCB:SetChecked(db.fitMyRole) end
    if mainPanel.hideOldCB then mainPanel.hideOldCB:SetChecked(db.hideOldGroups or false) end
    if mainPanel.ageDropDown then
        local ageText = addon:GetAgeOptionText(db.maxGroupAge or 30)
        UIDropDownMenu_SetText(mainPanel.ageDropDown, ageText)
        if db.hideOldGroups then
            if UIDropDownMenu_EnableDropDown then
                UIDropDownMenu_EnableDropDown(mainPanel.ageDropDown)
            end
        else
            if UIDropDownMenu_DisableDropDown then
                UIDropDownMenu_DisableDropDown(mainPanel.ageDropDown)
            end
        end
    end

    -- EditBoxes
    if mainPanel.minEditBox then
        mainPanel.minEditBox:SetText(db.minKey > 0 and tostring(db.minKey) or "")
    end
    if mainPanel.maxEditBox then
        mainPanel.maxEditBox:SetText(db.maxKey > 0 and tostring(db.maxKey) or "")
    end

    -- Sort DropDown text
    if mainPanel.sortDropDown then
        local sortMap = {
            KEY_DESC = L["SORT_KEY_DESC"],
            KEY_ASC = L["SORT_KEY_ASC"],
            DUNGEON_ASC = L["SORT_DUNGEON_ASC"],
            ROLE_TANK = L["SORT_ROLE_TANK"],
            ROLE_HEAL = L["SORT_ROLE_HEAL"],
            ROLE_DPS = L["SORT_ROLE_DPS"],
            SLOTS_DESC = L["SORT_SLOTS_DESC"],
            TIME_DESC = L["SORT_TIME_DESC"],
            ILVL_DESC = L["SORT_ILVL_DESC"],
            DEFAULT = L["SORT_DEFAULT"],
        }
        UIDropDownMenu_SetText(mainPanel.sortDropDown, sortMap[db.sortMode] or L["SORT_KEY_DESC"])
    end
end

------------------------------------------------------------------------
-- Create Toggle Button on LFG Search Panel
------------------------------------------------------------------------
function addon:CreateToggleButton()
    if toggleButton or not LFGListFrame or not LFGListFrame.SearchPanel then return end

    local searchPanel = LFGListFrame.SearchPanel
    local refreshBtn = searchPanel.RefreshButton

    toggleButton = CreateFrame("Button", "PremadeGroupSort_ToggleButton", searchPanel)
    toggleButton:SetSize(28, 28)

    if refreshBtn then
        toggleButton:SetPoint("RIGHT", refreshBtn, "LEFT", -4, 0)
    else
        toggleButton:SetPoint("TOPRIGHT", searchPanel, "TOPRIGHT", -40, -28)
    end

    -- Icon texture (options/filter cog)
    local icon = toggleButton:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(toggleButton)
    icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    toggleButton.icon = icon

    -- Highlight & Pushed
    local highlight = toggleButton:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(toggleButton)
    highlight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    highlight:SetBlendMode("ADD")

    toggleButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    toggleButton:SetScript("OnClick", function(self, button)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        if button == "RightButton" then
            if not mainPanel then addon:CreateMainPanel() end
            addon.db.panelOpen = not addon.db.panelOpen
            addon:UpdatePanelVisibility()
        else
            if not dungeonBar then addon:CreateDungeonBar() end
            addon.db.dungeonBarOpen = not addon.db.dungeonBarOpen
            addon:UpdatePanelVisibility()
        end
    end)

    toggleButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["ADDON_TITLE"], 1, 1, 1)
        local isRu = (GetLocale() == "ruRU")
        if isRu then
            GameTooltip:AddLine("|cffffffffЛевый клик:|r Показать/скрыть панель данжей", 0.9, 0.9, 0.9)
            GameTooltip:AddLine("|cffffffffПравый клик:|r Показать/скрыть расширенные фильтры", 0.9, 0.9, 0.9)
        else
            GameTooltip:AddLine("|cffffffffLeft Click:|r Toggle Dungeon Bar", 0.9, 0.9, 0.9)
            GameTooltip:AddLine("|cffffffffRight Click:|r Toggle Extended Filters", 0.9, 0.9, 0.9)
        end
        GameTooltip:Show()
    end)
    toggleButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    addon.toggleButton = toggleButton
end

local function HideMemberRings(btn)
    if btn and btn.DataDisplay and btn.DataDisplay.Enumerate then
        for i = 1, 5 do
            local icon = btn.DataDisplay.Enumerate["Icon" .. i]
            if icon then
                if icon.PGS_ClassRing then
                    icon.PGS_ClassRing:Hide()
                end
                icon:SetVertexColor(1, 1, 1, 1.0)
            end
        end
    end
end


------------------------------------------------------------------------
-- Visual Enhancements: Keystone Badges, Group Age & Party Member Class Colors
------------------------------------------------------------------------
function addon:EnhanceSearchEntry(button)
    local resultID = button.resultID
    if not resultID then
        if button.PGS_KeyBadge then button.PGS_KeyBadge:Hide() end
        if button.PGS_BLBadge then button.PGS_BLBadge:Hide() end
        if button.PGS_BLBadgeFrame then button.PGS_BLBadgeFrame:Hide() end
        if button.PGS_AgeBadge then button.PGS_AgeBadge:Hide() end
        HideMemberRings(button)
        return
    end

    local meta = addon:GetResultMeta(resultID)
    if not meta then
        if button.PGS_KeyBadge then button.PGS_KeyBadge:Hide() end
        if button.PGS_BLBadge then button.PGS_BLBadge:Hide() end
        if button.PGS_BLBadgeFrame then button.PGS_BLBadgeFrame:Hide() end
        if button.PGS_AgeBadge then button.PGS_AgeBadge:Hide() end
        HideMemberRings(button)
        return
    end

    -- 1. Create Key Badge FontString if not already created
    if not button.PGS_KeyBadge then
        local badge = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        badge:SetPoint("LEFT", button.Name, "RIGHT", 4, 0)
        button.PGS_KeyBadge = badge
    end

    -- Check key level
    if meta.keyLevel then
        local key = meta.keyLevel
        local color
        if key >= 15 then
            color = "|cffff8000" -- Legendary Orange
        elseif key >= 10 then
            color = "|cffa335ee" -- Epic Purple
        elseif key >= 5 then
            color = "|cff0070dd" -- Rare Blue
        else
            color = "|cff1eff00" -- Uncommon Green
        end

        button.PGS_KeyBadge:SetText(color .. "[+" .. key .. "]|r")
        button.PGS_KeyBadge:Show()
    elseif meta.isMythicKeystone then
        button.PGS_KeyBadge:SetText("|cff00ccff[M+]|r")
        button.PGS_KeyBadge:Show()
    else
        button.PGS_KeyBadge:Hide()
    end

    -- 2. Leader Blacklist / Whitelist Indicator
    local leaderName = meta.leaderName
    local blInfo = leaderName and leaderName ~= "" and addon:GetBlacklistInfo(leaderName)
    local wlInfo = (not blInfo) and leaderName and leaderName ~= "" and addon:GetWhitelistInfo(leaderName)

    if blInfo then
        if button.PGS_WLBadge then button.PGS_WLBadge:Hide() end
        if button.PGS_WLBadgeFrame then button.PGS_WLBadgeFrame:Hide() end
        button.PGS_WLInfo = nil

        if not button.PGS_BLBadge then
            local blBadge = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            blBadge:SetPoint("LEFT", button.PGS_KeyBadge, "RIGHT", 4, 0)
            button.PGS_BLBadge = blBadge
        end

        local rText = blInfo.reason or L["BL_DEFAULT_REASON"]
        if string.len(rText) > 16 then
            rText = string.sub(rText, 1, 14) .. ".."
        end
        button.PGS_BLBadge:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:14:14:0:0|t |cffff2020[" .. L["BL_BADGE_LEADER"] .. ": " .. rText .. "]|r")
        button.PGS_BLBadge:Show()

        if not button.PGS_BLBadgeFrame then
            local f = CreateFrame("Frame", nil, button)
            f:SetAllPoints(button.PGS_BLBadge)
            f:EnableMouse(true)
            f:SetScript("OnEnter", function(self)
                if not button.PGS_BLInfo then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local info = button.PGS_BLInfo
                GameTooltip:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16:0:0|t |cffff2020" .. L["BL_BADGE_LEADER"] .. ": " .. (button.PGS_BLLeader or "") .. "|r", 1, 0.2, 0.2)
                GameTooltip:AddLine("|cffffd100" .. (GetLocale() == "ruRU" and "Причина: " or "Reason: ") .. "|r" .. (info.reason or L["BL_DEFAULT_REASON"]), 1, 1, 1, true)
                local sourceStr = info.isSelf and L["BL_SOURCE_SELF"] or string.format(L["BL_SOURCE_PARTY"], info.addedBy or "Unknown")
                GameTooltip:AddLine("|cffffd100" .. (GetLocale() == "ruRU" and "Добавил: " or "Added by: ") .. "|r" .. sourceStr, 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            f:SetScript("OnLeave", function() GameTooltip:Hide() end)
            button.PGS_BLBadgeFrame = f
        end
        button.PGS_BLInfo = blInfo
        button.PGS_BLLeader = leaderName
        button.PGS_BLBadgeFrame:Show()
    elseif wlInfo then
        if button.PGS_BLBadge then button.PGS_BLBadge:Hide() end
        if button.PGS_BLBadgeFrame then button.PGS_BLBadgeFrame:Hide() end
        button.PGS_BLInfo = nil
        button.PGS_BLLeader = nil

        if not button.PGS_WLBadge then
            local wlBadge = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            wlBadge:SetPoint("LEFT", button.PGS_KeyBadge, "RIGHT", 4, 0)
            button.PGS_WLBadge = wlBadge
        end

        local nText = wlInfo.note or L["WL_DEFAULT_NOTE"]
        if string.len(nText) > 16 then
            nText = string.sub(nText, 1, 14) .. ".."
        end
        button.PGS_WLBadge:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:14:14:0:0|t |cff25ff25[" .. L["WL_BADGE_LEADER"] .. ": " .. nText .. "]|r")
        button.PGS_WLBadge:Show()

        if not button.PGS_WLBadgeFrame then
            local wf = CreateFrame("Frame", nil, button)
            wf:SetAllPoints(button.PGS_WLBadge)
            wf:EnableMouse(true)
            wf:SetScript("OnEnter", function(self)
                if not button.PGS_WLInfo then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local info = button.PGS_WLInfo
                GameTooltip:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16:0:0|t |cff25ff25" .. L["WL_BADGE_LEADER"] .. ": " .. (button.PGS_WLLeader or "") .. "|r", 0.2, 1, 0.2)
                GameTooltip:AddLine("|cffffd100" .. (GetLocale() == "ruRU" and "Заметка: " or "Note: ") .. "|r" .. (info.note or L["WL_DEFAULT_NOTE"]), 1, 1, 1, true)
                GameTooltip:Show()
            end)
            wf:SetScript("OnLeave", function() GameTooltip:Hide() end)
            button.PGS_WLBadgeFrame = wf
        end
        button.PGS_WLInfo = wlInfo
        button.PGS_WLLeader = leaderName
        button.PGS_WLBadgeFrame:Show()
    else
        if button.PGS_BLBadge then button.PGS_BLBadge:Hide() end
        if button.PGS_BLBadgeFrame then button.PGS_BLBadgeFrame:Hide() end
        button.PGS_BLInfo = nil
        button.PGS_BLLeader = nil

        if button.PGS_WLBadge then button.PGS_WLBadge:Hide() end
        if button.PGS_WLBadgeFrame then button.PGS_WLBadgeFrame:Hide() end
        button.PGS_WLInfo = nil
        button.PGS_WLLeader = nil
    end

    -- 3. Group Age Indicator (Time in LFG)
    if not button.PGS_AgeBadge then
        local ageBadge = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.PGS_AgeBadge = ageBadge
    end

    if meta.age and meta.age >= 0 then
        local ageText, ageColor = addon:FormatGroupAge(meta.age)
        button.PGS_AgeBadge:SetText(ageColor .. ageText .. "|r")
        button.PGS_AgeBadge:ClearAllPoints()
        if button.PGS_BLBadge and button.PGS_BLBadge:IsShown() then
            button.PGS_AgeBadge:SetPoint("LEFT", button.PGS_BLBadge, "RIGHT", 4, 0)
        elseif button.PGS_WLBadge and button.PGS_WLBadge:IsShown() then
            button.PGS_AgeBadge:SetPoint("LEFT", button.PGS_WLBadge, "RIGHT", 4, 0)
        elseif button.PGS_KeyBadge and button.PGS_KeyBadge:IsShown() then
            button.PGS_AgeBadge:SetPoint("LEFT", button.PGS_KeyBadge, "RIGHT", 4, 0)
        else
            button.PGS_AgeBadge:SetPoint("LEFT", button.Name, "RIGHT", 4, 0)
        end
        button.PGS_AgeBadge:Show()
    else
        button.PGS_AgeBadge:Hide()
    end

    -- 4. Party Member Circles: Ensure standard Blizzard icons and remove custom glows
    HideMemberRings(button)
end

------------------------------------------------------------------------
-- Visual Enhancements: Blacklist Protection on Applicants (ApplicationViewer)
------------------------------------------------------------------------
StaticPopupDialogs["PGS_CONFIRM_INVITE_BLACKLIST"] = {
    text = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16:0:0|t |cffff2020" .. (L["BL_CONFIRM_TITLE"] or "ВНИМАНИЕ!") .. "|r\n\n" ..
           (L["BL_CONFIRM_INVITE_TEXT"] or "Игрок %s находится в чёрном списке:\n\"%s\"\n\nВы уверены, что хотите пригласить его в группу?"),
    button1 = INVITE or "Пригласить",
    button2 = CANCEL or "Отмена",
    OnAccept = function(self, data)
        if data and data.applicantID then
            C_LFGList.InviteApplicant(data.applicantID)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function addon:ShowApplicantBLTooltip(owner, button)
    if not button or not button.PGS_BLInfo then return end
    GameTooltip:SetOwner(owner, "ANCHOR_TOPLEFT")
    local info = button.PGS_BLInfo
    local name = button.PGS_BLMember or ""
    GameTooltip:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16:0:0|t |cffff2020" .. L["BL_HEADER"] .. ": " .. name .. "|r", 1, 0.2, 0.2)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_REASON"] .. ":|r", "|cffffffff" .. (info.reason or L["BL_DEFAULT_REASON"]) .. "|r", 1, 1, 1, 1, 1, 1)
    local byStr = (info.addedBy and info.addedBy ~= "") and info.addedBy or "Alt"
    if info.isSelf then
        GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_SOURCE"] .. ":|r", "|cffaaaaaa" .. L["BL_SOURCE_SELF"] .. " (" .. byStr .. ")|r", 1, 1, 1, 1, 1, 1)
    elseif info.source == "guild" then
        GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_SOURCE"] .. ":|r", "|cff00ff00Гильдия (" .. byStr .. ")|r", 1, 1, 1, 1, 1, 1)
    else
        GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_SOURCE"] .. ":|r", "|cff00ccffГруппа (" .. byStr .. ")|r", 1, 1, 1, 1, 1, 1)
    end
    if info.timestamp and info.timestamp > 0 then
        local fullDate = date("%d.%m.%Y в %H:%M", info.timestamp)
        GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_DATE"] .. ":|r", "|cffffffff" .. fullDate .. "|r", 1, 1, 1, 1, 1, 1)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffff4040" .. L["BL_INVITE_BLOCKED_TOOLTIP"] .. "|r", 1, 0.4, 0.4, true)
    GameTooltip:Show()
end

function addon:EnhanceApplicantButton(button, id)
    local applicantID = id or button.applicantID
    if not applicantID then
        if button.PGS_BLBorder then button.PGS_BLBorder:Hide() end
        if button.PGS_BLBadgeBtn then button.PGS_BLBadgeBtn:Hide() end
        if button.PGS_BLBadge then button.PGS_BLBadge:Hide() end
        if button.PGS_BLBadgeFrame then button.PGS_BLBadgeFrame:Hide() end
        if button.PGS_WLBorder then button.PGS_WLBorder:Hide() end
        return
    end

    local appID, status, pendingStatus, numMembers = C_LFGList.GetApplicantInfo(applicantID)
    if not appID or not numMembers or numMembers == 0 then
        if button.PGS_BLBorder then button.PGS_BLBorder:Hide() end
        if button.PGS_BLBadgeBtn then button.PGS_BLBadgeBtn:Hide() end
        if button.PGS_BLBadge then button.PGS_BLBadge:Hide() end
        if button.PGS_BLBadgeFrame then button.PGS_BLBadgeFrame:Hide() end
        if button.PGS_WLBorder then button.PGS_WLBorder:Hide() end
        return
    end

    local blacklistedMember = nil
    local blacklistedInfo = nil
    local whitelistedMember = nil
    local whitelistedInfo = nil

    for mIdx = 1, numMembers do
        local name = C_LFGList.GetApplicantMemberInfo(applicantID, mIdx)
        if name then
            local bl = addon:GetBlacklistInfo(name)
            local wl = addon:GetWhitelistInfo(name)

            if bl then
                blacklistedMember = name
                blacklistedInfo = bl
                -- Prefix skull and color name red cleanly in Name column without overlapping Role/ilvl
                if button.Members and button.Members[mIdx] and button.Members[mIdx].Name then
                    local m = button.Members[mIdx]
                    local short = Ambiguate(name, "short")
                    local prefix = (mIdx > 1) and "  " or ""
                    m.Name:SetText(prefix .. "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:13:13:0:0|t |cffff2525" .. short .. "|r")
                end
            elseif wl then
                if not whitelistedMember then
                    whitelistedMember = name
                    whitelistedInfo = wl
                end
                -- Prefix gold star and color name bright emerald green
                if button.Members and button.Members[mIdx] and button.Members[mIdx].Name then
                    local m = button.Members[mIdx]
                    local short = Ambiguate(name, "short")
                    local prefix = (mIdx > 1) and "  " or ""
                    m.Name:SetText(prefix .. "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:13:13:0:0|t |cff25ff25" .. short .. "|r")
                end
            end
        end
    end

    -- Clean up legacy elements if any exist in memory
    if button.PGS_BLBadge then button.PGS_BLBadge:Hide(); button.PGS_BLBadge:SetText("") end
    if button.PGS_BLBadgeFrame then button.PGS_BLBadgeFrame:Hide() end

    if blacklistedInfo then
        -- Prioritize Blacklist over Whitelist for safety
        if button.PGS_WLBorder then button.PGS_WLBorder:Hide() end

        -- 1. Crimson highlight background over whole row
        if not button.PGS_BLBorder then
            local b = button:CreateTexture(nil, "BACKGROUND", nil, 1)
            b:SetAllPoints(button)
            b:SetColorTexture(0.50, 0.05, 0.05, 0.35)
            button.PGS_BLBorder = b
        end
        button.PGS_BLBorder:Show()

        button.PGS_BLInfo = blacklistedInfo
        button.PGS_BLMember = blacklistedMember

        -- 2. Clean Action Button: replace InviteButton with [В ЧС] badge button in Column 4
        local invBtn = (button.InviteButtonSmall and button.InviteButtonSmall:IsShown()) and button.InviteButtonSmall or button.InviteButton

        if status == "applied" and LFGListUtil_IsEntryEmpowered() then
            if invBtn then
                invBtn:Hide()
            end

            local badgeBtn = button.PGS_BLBadgeBtn
            if not badgeBtn then
                badgeBtn = CreateFrame("Button", nil, button)
                badgeBtn:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    tile = false, edgeSize = 1,
                    insets = { left = 1, right = 1, top = 1, bottom = 1 },
                })
                badgeBtn:SetBackdropColor(0.45, 0.08, 0.08, 0.95)
                badgeBtn:SetBackdropBorderColor(0.9, 0.2, 0.2, 0.9)

                local txt = badgeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                txt:SetPoint("CENTER", 0, 0)
                badgeBtn.txt = txt

                badgeBtn:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(0.65, 0.12, 0.12, 1.0)
                    self:SetBackdropBorderColor(1.0, 0.3, 0.3, 1.0)
                    addon:ShowApplicantBLTooltip(self, button)
                end)
                badgeBtn:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0.45, 0.08, 0.08, 0.95)
                    self:SetBackdropBorderColor(0.9, 0.2, 0.2, 0.9)
                    GameTooltip:Hide()
                end)
                badgeBtn:SetScript("OnClick", function(self)
                    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                    local reason = (button.PGS_BLInfo and button.PGS_BLInfo.reason) or L["BL_DEFAULT_REASON"]
                    local dialog = StaticPopup_Show("PGS_CONFIRM_INVITE_BLACKLIST", button.PGS_BLMember or "", reason)
                    if dialog then
                        dialog.data = { applicantID = button.applicantID }
                    end
                end)
                button.PGS_BLBadgeBtn = badgeBtn
            end

            local targetAnchor = invBtn or button.InviteButton
            if targetAnchor then
                badgeBtn:ClearAllPoints()
                badgeBtn:SetAllPoints(targetAnchor)
            else
                badgeBtn:ClearAllPoints()
                if button.DeclineButton then
                    badgeBtn:SetPoint("RIGHT", button.DeclineButton, "LEFT", -2, 0)
                    badgeBtn:SetSize(80, 22)
                else
                    badgeBtn:SetPoint("RIGHT", button, "RIGHT", -28, 0)
                    badgeBtn:SetSize(80, 22)
                end
            end
            badgeBtn.txt:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12:12:0:0|t |cffff2020" .. L["BL_BADGE_IN_BL"] .. "|r")
            badgeBtn:Show()
        else
            -- Status is invited, declined, cancelled etc.
            if button.PGS_BLBadgeBtn then button.PGS_BLBadgeBtn:Hide() end
        end

        -- Trigger anime sound alert (with debounce)
        local now = GetTime()
        if not addon.lastBLAlertTime or (now - addon.lastBLAlertTime > 8) then
            addon.lastBLAlertTime = now
            if addon.PlayAnimeSound then
                addon:PlayAnimeSound("alert_bl")
            end
        end
    else
        if button.PGS_BLBorder then button.PGS_BLBorder:Hide() end
        if button.PGS_BLBadgeBtn then button.PGS_BLBadgeBtn:Hide() end
        button.PGS_BLInfo = nil
        button.PGS_BLMember = nil

        -- Whitelist Emerald Highlight
        if whitelistedInfo then
            if not button.PGS_WLBorder then
                local wb = button:CreateTexture(nil, "BACKGROUND", nil, 1)
                wb:SetAllPoints(button)
                wb:SetColorTexture(0.04, 0.42, 0.16, 0.32)
                button.PGS_WLBorder = wb
            end
            button.PGS_WLBorder:Show()
        else
            if button.PGS_WLBorder then button.PGS_WLBorder:Hide() end
        end

        -- Restore invite button if status is applied
        if status == "applied" and LFGListUtil_IsEntryEmpowered() then
            if button.InviteButton then
                button.InviteButton:Show()
                button.InviteButton:Enable()
                button.InviteButton:SetAlpha(1.0)
            end
            if button.InviteButtonSmall then
                button.InviteButtonSmall:Show()
                button.InviteButtonSmall:Enable()
                button.InviteButtonSmall:SetAlpha(1.0)
            end
        end
    end
end

------------------------------------------------------------------------
-- Quick Keystone Creation Panel (LFGListFrame.EntryCreation)
------------------------------------------------------------------------
local creationPanel = nil
local curCreateDungeon = "MOS"
local curCreateLevel = 15
local curCreateTags = {}
local createDungeonButtons = {}
local createLevelButtons = {}
local createTagButtons = {}

local QUICK_TAGS = {
    { key = "CHESTS", text = L["TAG_CHESTS"] or "[+2/3]" },
    { key = "FAST",   text = L["TAG_FAST"] or "[Fast]" },
    { key = "PUSH",   text = L["TAG_PUSH"] or "[Push]" },
    { key = "WEEKLY", text = L["TAG_WEEKLY"] or "[Weekly]" },
    { key = "CHILL",  text = L["TAG_CHILL"] or "[Chill]" },
    { key = "EXP",    text = L["TAG_EXP"] or "[Big Exp]" },
}

local function GetCreationTagsString()
    local list = {}
    for _, tag in ipairs(QUICK_TAGS) do
        if curCreateTags[tag.key] then
            table.insert(list, tag.text)
        end
    end
    return table.concat(list, " ")
end

local function UpdateCreationVisuals(autoApply)
    if not creationPanel then return end

    -- Update dungeon buttons highlight
    for dId, btn in pairs(createDungeonButtons) do
        if dId == curCreateDungeon then
            if btn.selectedBorder then btn.selectedBorder:Show() end
            btn:SetAlpha(1.0)
            if btn.badgeBg then btn.badgeBg:SetColorTexture(0, 0.45, 0.20, 0.95) end
        else
            if btn.selectedBorder then btn.selectedBorder:Hide() end
            btn:SetAlpha(0.65)
            if btn.badgeBg then btn.badgeBg:SetColorTexture(0, 0, 0, 0.8) end
        end
    end

    -- Update level display
    if creationPanel.levelLabel then
        creationPanel.levelLabel:SetText("|cffffd100+" .. tostring(curCreateLevel) .. "|r")
    end

    -- Update level chips
    for lvl, btn in pairs(createLevelButtons) do
        if lvl == curCreateLevel then
            btn:SetBackdropColor(0, 0.5, 0.2, 0.9)
            btn:SetBackdropBorderColor(0.2, 1.0, 0.3, 1.0)
        else
            btn:SetBackdropColor(0.12, 0.12, 0.16, 0.8)
            btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.6)
        end
    end

    -- Update tag buttons
    for key, btn in pairs(createTagButtons) do
        if curCreateTags[key] then
            btn:SetBackdropColor(0, 0.45, 0.2, 0.9)
            btn:SetBackdropBorderColor(0.2, 1.0, 0.3, 1.0)
            btn.text:SetTextColor(0.3, 1.0, 0.4)
        else
            btn:SetBackdropColor(0.12, 0.12, 0.16, 0.8)
            btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.6)
            btn.text:SetTextColor(0.7, 0.7, 0.7)
        end
    end

    -- Update Title Preview string - ALWAYS in English as requested
    local dInfo = addon.DungeonMap[curCreateDungeon]
    local dName = dInfo and dInfo.nameEn or curCreateDungeon
    local tagsStr = GetCreationTagsString()
    local title = "+" .. tostring(curCreateLevel) .. " " .. dName
    if tagsStr ~= "" then
        title = title .. " " .. tagsStr
    end

    if creationPanel.previewText then
        creationPanel.previewText:SetText(title)
    end

    addon:UpdatePartyKeyButtonSelection()

    if autoApply then
        addon:ApplyQuickCreation(curCreateDungeon, curCreateLevel, tagsStr)
    end
end

function addon:UpdatePartyKeyButtonSelection()
    if not creationPanel or not creationPanel.partyKeyButtons then return end
    for i = 1, 5 do
        local btn = creationPanel.partyKeyButtons[i]
        if btn and btn:IsShown() and btn.dungeonId and btn.keyLevel then
            local isMatch = (btn.dungeonId == curCreateDungeon and btn.keyLevel == curCreateLevel)
            if isMatch then
                btn:SetBackdropColor(0, 0.45, 0.20, 0.95)
                btn:SetBackdropBorderColor(0.2, 1.0, 0.3, 1.0)
                if btn.selectedBorder then btn.selectedBorder:Show() end
                btn.text:SetTextColor(1, 1, 1)
            else
                btn:SetBackdropColor(0.12, 0.12, 0.18, 0.9)
                btn:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8)
                if btn.selectedBorder then btn.selectedBorder:Hide() end
                btn.text:SetTextColor(0.85, 0.85, 0.85)
            end
        end
    end
end

function addon:GetPartyKeystonesList()
    local list = {}
    local myDId, myLevel = addon:GetPlayerKeystone()
    local isRu = (GetLocale() == "ruRU")
    local youText = L["YOU"] or (isRu and "Вы" or "You")

    -- Add player's keystone first
    table.insert(list, {
        isPlayer = true,
        name = youText,
        fullName = UnitName("player"),
        dId = myDId,
        level = myLevel,
    })

    -- Add party members' keystones
    if IsInGroup() and addon.partyKeystones then
        local names = {}
        for name in pairs(addon.partyKeystones) do
            table.insert(names, name)
        end
        table.sort(names)
        for _, name in ipairs(names) do
            local info = addon.partyKeystones[name]
            if info and info.dId and info.level and info.dId ~= "NONE" and info.level > 0 then
                table.insert(list, {
                    isPlayer = false,
                    name = name,
                    fullName = name,
                    dId = info.dId,
                    level = info.level,
                })
            end
        end
    end

    return list
end

function addon:RefreshCreationPanel()
    if not creationPanel then return end
    if not creationPanel:IsShown() then creationPanel.pgsDirty = true; return end
    creationPanel.pgsDirty = nil
    addon.perf.viewRefreshes = addon.perf.viewRefreshes + 1

    if creationPanel.partyLabel then
        if IsInGroup() then
            creationPanel.partyLabel:SetText("|cffffd100" .. L["PARTY_KEYS_HEADER"] .. "|r")
        else
            creationPanel.partyLabel:SetText("|cffffd100" .. L["QUICK_CREATOR_MY_KEY"] .. ":|r")
        end
    end

    local keyList = addon:GetPartyKeystonesList()
    local totalKeys = #keyList
    local keyIcon = "|TInterface\\Icons\\inv_misc_key_14:14:14:0:0|t "
    local isRu = (GetLocale() == "ruRU")

    for i = 1, 5 do
        if creationPanel.partyKeyButtons[i] then
            creationPanel.partyKeyButtons[i]:Hide()
        end
    end

    local startX = 14
    local row1Y = -46
    local row2Y = -72
    local totalW = 302
    local btnH = 24

    for idx, item in ipairs(keyList) do
        if idx <= 5 then
            local btn = creationPanel.partyKeyButtons[idx]
            btn:ClearAllPoints()

            local btnW, posX, posY
            if totalKeys == 1 then
                btnW = totalW
                posX = startX
                posY = row1Y
            elseif totalKeys == 2 then
                btnW = 148
                posX = startX + (idx - 1) * (btnW + 6)
                posY = row1Y
            elseif totalKeys == 3 then
                btnW = 98
                posX = startX + (idx - 1) * (btnW + 4)
                posY = row1Y
            elseif totalKeys == 4 then
                btnW = 148
                local col = (idx - 1) % 2
                local row = math.floor((idx - 1) / 2)
                posX = startX + col * (btnW + 6)
                posY = (row == 0) and row1Y or row2Y
            else -- 5 keys
                if idx <= 3 then
                    btnW = 98
                    posX = startX + (idx - 1) * (btnW + 4)
                    posY = row1Y
                else
                    btnW = 148
                    local col = idx - 4
                    posX = startX + col * (btnW + 6)
                    posY = row2Y
                end
            end

            btn:SetSize(btnW, btnH)
            btn:SetPoint("TOPLEFT", posX, posY)
            btn.dungeonId = item.dId
            btn.keyLevel = item.level
            btn.ownerName = item.name
            btn.ownerFullName = item.fullName

            if item.dId and item.level then
                local dInfo = addon.DungeonMap[item.dId]
                local shortDName = dInfo and dInfo.acronym or item.dId
                local dispName = item.name
                if btnW <= 100 and string.len(dispName) > 7 then
                    dispName = string.sub(dispName, 1, 6) .. "."
                end
                btn.text:SetText(keyIcon .. dispName .. ": +" .. item.level .. " " .. shortDName)
                btn:SetAlpha(1.0)
                btn:Enable()
            else
                local noKeyText = L["QUICK_CREATOR_NO_KEY"] or (isRu and "Нет ключа" or "No Key")
                btn.text:SetText(keyIcon .. item.name .. ": " .. noKeyText)
                btn:SetAlpha(0.55)
                btn:Disable()
            end

            btn:Show()
        end
    end

    addon:UpdatePartyKeyButtonSelection()
    UpdateCreationVisuals(false)
end

function addon:CreateCreationPanel()
    if creationPanel or not LFGListFrame then return end

    creationPanel = CreateFrame("Frame", "PremadeGroupSort_CreationPanel", LFGListFrame)
    creationPanel:SetSize(330, 428)
    creationPanel:SetPoint("TOPLEFT", LFGListFrame, "TOPRIGHT", 2, 0)
    creationPanel:SetFrameStrata("HIGH")
    creationPanel:EnableMouse(true)
    creationPanel:Hide()
    addon.creationPanel = creationPanel

    creationPanel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    creationPanel:SetBackdropColor(0.08, 0.08, 0.12, 0.96)
    creationPanel:SetBackdropBorderColor(0.85, 0.70, 0.20, 0.85)

    -- Header Title
    local title = creationPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("|cffffd100" .. L["QUICK_CREATOR_TITLE"] .. "|r")

    -- Close Button [X]
    local closeBtn = CreateFrame("Button", nil, creationPanel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        creationPanel:Hide()
    end)

    -- Blacklist [ЧС] & Whitelist [БС] Buttons
    local wlBtn = CreateFrame("Button", nil, creationPanel, "UIPanelButtonTemplate")
    wlBtn:SetSize(48, 20)
    wlBtn:SetPoint("TOPRIGHT", -32, -6)
    wlBtn:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12:12:0:0|t " .. (L["WL_BUTTON"] or "БС"))
    wlBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ToggleWhitelistPanel()
    end)
    wlBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["WL_TITLE"] or "Белый список", 1, 0.82, 0)
        GameTooltip:AddLine(L["WL_BUTTON_TOOLTIP"] or "Открыть управление Белым списком", 0.2, 1.0, 0.2, true)
        GameTooltip:Show()
    end)
    wlBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    creationPanel.wlBtn = wlBtn

    local blBtn = CreateFrame("Button", nil, creationPanel, "UIPanelButtonTemplate")
    blBtn:SetSize(48, 20)
    blBtn:SetPoint("RIGHT", wlBtn, "LEFT", -4, 0)
    blBtn:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12:12:0:0|t " .. (L["BL_BUTTON"] or "ЧС"))
    blBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ToggleBlacklistPanel("blacklist")
    end)
    blBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["BL_TITLE"], 1, 0.82, 0)
        GameTooltip:AddLine(L["BL_BUTTON_TOOLTIP"], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    blBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    creationPanel.blBtn = blBtn

    -- Section: Party Keystones Header
    local partyLabel = creationPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    partyLabel:SetPoint("TOPLEFT", 14, -30)
    partyLabel:SetText("|cffffd100" .. L["PARTY_KEYS_HEADER"] .. "|r")
    creationPanel.partyLabel = partyLabel

    -- Up to 5 party keystone buttons (pre-created, dynamically positioned in RefreshCreationPanel)
    creationPanel.partyKeyButtons = {}
    for i = 1, 5 do
        local btn = CreateFrame("Button", nil, creationPanel)
        btn:SetSize(148, 24)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        btn:SetBackdropColor(0.12, 0.12, 0.18, 0.9)
        btn:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8)

        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        txt:SetPoint("CENTER", 0, 0)
        btn.text = txt

        -- Glowing selected border
        local sBorder = btn:CreateTexture(nil, "OVERLAY")
        sBorder:SetPoint("TOPLEFT", -2, 2)
        sBorder:SetPoint("BOTTOMRIGHT", 2, -2)
        sBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        sBorder:SetBlendMode("ADD")
        sBorder:SetVertexColor(0.2, 1.0, 0.3, 1.0)
        sBorder:Hide()
        btn.selectedBorder = sBorder

        btn:SetScript("OnClick", function(self)
            if self.dungeonId and self.keyLevel then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                curCreateDungeon = self.dungeonId
                curCreateLevel = self.keyLevel
                addon.selectedPartyKeyOwner = self.ownerName
                UpdateCreationVisuals(true)
            end
        end)

        btn:SetScript("OnEnter", function(self)
            if not self.dungeonId then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local isRu = (GetLocale() == "ruRU")
            local dInfo = addon.DungeonMap[self.dungeonId]
            local dName = dInfo and (isRu and dInfo.nameRu or dInfo.nameEn) or self.dungeonId
            local dNameEn = dInfo and dInfo.nameEn or self.dungeonId

            local titleText = "|TInterface\\Icons\\inv_misc_key_14:14:14:0:0|t " .. (self.ownerFullName or self.ownerName) .. ": +" .. tostring(self.keyLevel) .. " " .. dName
            GameTooltip:SetText(titleText, 1, 0.82, 0)
            if dName ~= dNameEn then
                GameTooltip:AddLine(dNameEn, 0.7, 0.7, 0.7)
            end
            local clickText = isRu and "|cff33ff33Клик:|r Выбрать этот ключ для создания группы" or "|cff33ff33Click:|r Select this keystone for group listing"
            GameTooltip:AddLine(clickText, 0.3, 1, 0.3)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        creationPanel.partyKeyButtons[i] = btn
    end
    creationPanel.btnMyKey = creationPanel.partyKeyButtons[1]

    -- Section 1: Dungeons (13 Legion Dungeons, Large 58x36px Icons!)
    local dLabel = creationPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dLabel:SetPoint("TOPLEFT", 14, -100)
    dLabel:SetText("|cffffd100" .. L["QUICK_CREATOR_DUNGEON"] .. "|r")

    local startX = 14
    local startY = -116
    local btnW = 58
    local btnH = 36
    local spaceX = 3
    local spaceY = 3

    local dCount = 0
    for _, d in ipairs(addon.DungeonList) do
        if d.id ~= "ALL" then
            local col = dCount % 5
            local row = math.floor(dCount / 5)
            local posX = startX + col * (btnW + spaceX)
            local posY = startY - row * (btnH + spaceY)

            local dBtn = CreateFrame("Button", nil, creationPanel)
            dBtn:SetSize(btnW, btnH)
            dBtn:SetPoint("TOPLEFT", posX, posY)
            dBtn.dungeonId = d.id
            dBtn.dungeon = d

            -- Texture icon (large and clear)
            local tex = dBtn:CreateTexture(nil, "BACKGROUND")
            tex:SetAllPoints(dBtn)
            tex:SetTexture(d.icon)
            tex:SetTexCoord(0.04, 0.96, 0.08, 0.92)

            -- Border frame
            local border = dBtn:CreateTexture(nil, "BORDER")
            border:SetAllPoints(dBtn)
            border:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
            border:SetTexCoord(0, 1, 0, 1)
            border:SetVertexColor(0.4, 0.4, 0.4, 0.8)

            -- Acronym badge plate
            local badgeBg = dBtn:CreateTexture(nil, "ARTWORK")
            badgeBg:SetPoint("BOTTOMLEFT", 0, 0)
            badgeBg:SetPoint("BOTTOMRIGHT", 0, 0)
            badgeBg:SetHeight(13)
            badgeBg:SetColorTexture(0, 0, 0, 0.78)
            dBtn.badgeBg = badgeBg

            local badgeText = dBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            badgeText:SetPoint("CENTER", badgeBg, "CENTER", 0, 0)
            badgeText:SetText(d.acronym)
            badgeText:SetTextColor(1, 1, 1)

            -- Glowing selected border
            local sBorder = dBtn:CreateTexture(nil, "OVERLAY")
            sBorder:SetPoint("TOPLEFT", -2, 2)
            sBorder:SetPoint("BOTTOMRIGHT", 2, -2)
            sBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            sBorder:SetBlendMode("ADD")
            sBorder:SetVertexColor(0.1, 1.0, 0.3, 1.0)
            sBorder:Hide()
            dBtn.selectedBorder = sBorder

            dBtn:SetScript("OnClick", function(self)
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                curCreateDungeon = self.dungeonId
                UpdateCreationVisuals(true)
            end)

            dBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local isRu = (GetLocale() == "ruRU")
                local dNamePrimary = isRu and self.dungeon.nameRu or self.dungeon.nameEn
                local dNameSecondary = isRu and self.dungeon.nameEn or self.dungeon.nameRu
                GameTooltip:SetText(dNamePrimary, 1, 0.82, 0)
                GameTooltip:AddLine(dNameSecondary, 0.7, 0.7, 0.7)
                GameTooltip:AddLine("|cff33ff33Клик:|r Выбрать " .. self.dungeon.nameEn .. " для названия группы", 0.3, 1, 0.3)
                GameTooltip:Show()
            end)
            dBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            createDungeonButtons[d.id] = dBtn
            dCount = dCount + 1
        end
    end

    -- Section 2: Keystone Level
    local lvlLabel = creationPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lvlLabel:SetPoint("TOPLEFT", 14, -236)
    lvlLabel:SetText("|cffffd100" .. L["QUICK_CREATOR_LEVEL"] .. "|r")

    -- Stepper [-] [ +15 ] [+]
    local btnMinus = CreateFrame("Button", nil, creationPanel, "UIPanelButtonTemplate")
    btnMinus:SetSize(30, 22)
    btnMinus:SetPoint("TOPLEFT", 14, -250)
    btnMinus:SetText("-")
    btnMinus:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        if curCreateLevel > 2 then
            curCreateLevel = curCreateLevel - 1
            UpdateCreationVisuals(true)
        end
    end)

    local levelText = creationPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    levelText:SetPoint("LEFT", btnMinus, "RIGHT", 6, 0)
    levelText:SetWidth(50)
    levelText:SetJustifyH("CENTER")
    levelText:SetText("|cffffd100+15|r")
    creationPanel.levelLabel = levelText

    local btnPlus = CreateFrame("Button", nil, creationPanel, "UIPanelButtonTemplate")
    btnPlus:SetSize(30, 22)
    btnPlus:SetPoint("LEFT", levelText, "RIGHT", 6, 0)
    btnPlus:SetText("+")
    btnPlus:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        if curCreateLevel < 35 then
            curCreateLevel = curCreateLevel + 1
            UpdateCreationVisuals(true)
        end
    end)

    -- Level Chips Presets (1 row of 7 popular presets: +2, +5, +7, +10, +12, +15, +20)
    local presetLevels = { 2, 5, 7, 10, 12, 15, 20 }
    local chipW = 38
    local chipH = 20
    local chipStartX = 14
    local chipStartY = -276
    local chipGap = 6

    for cIdx, lvl in ipairs(presetLevels) do
        local posX = chipStartX + (cIdx - 1) * (chipW + chipGap)

        local cBtn = CreateFrame("Button", nil, creationPanel)
        cBtn:SetSize(chipW, chipH)
        cBtn:SetPoint("TOPLEFT", posX, chipStartY)
        cBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        cBtn:SetBackdropColor(0.12, 0.12, 0.16, 0.8)
        cBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.6)

        local txt = cBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        txt:SetPoint("CENTER", 0, 0)
        txt:SetText("+" .. lvl)

        cBtn.level = lvl
        cBtn:SetScript("OnClick", function(self)
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            curCreateLevel = self.level
            UpdateCreationVisuals(true)
        end)

        createLevelButtons[lvl] = cBtn
    end

    -- Section 3: Quick Tags (2 rows of 3 buttons, width 96px)
    local tagLabel = creationPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tagLabel:SetPoint("TOPLEFT", 14, -302)
    tagLabel:SetText("|cffffd100" .. L["QUICK_CREATOR_TAGS"] .. "|r")

    local tagW = 96
    local tagH = 20
    local tagStartX = 14
    local tagStartY = -316
    local spaceTagY = 3

    for idx, tag in ipairs(QUICK_TAGS) do
        local col = (idx - 1) % 3
        local row = math.floor((idx - 1) / 3)
        local posX = tagStartX + col * (tagW + 7)
        local posY = tagStartY - row * (tagH + spaceTagY)

        local tBtn = CreateFrame("Button", nil, creationPanel)
        tBtn:SetSize(tagW, tagH)
        tBtn:SetPoint("TOPLEFT", posX, posY)
        tBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        tBtn:SetBackdropColor(0.12, 0.12, 0.16, 0.8)
        tBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.6)

        local txt = tBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        txt:SetPoint("CENTER", 0, 0)
        txt:SetText(tag.text)
        tBtn.text = txt
        tBtn.tagKey = tag.key

        tBtn:SetScript("OnClick", function(self)
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            if curCreateTags[self.tagKey] then
                curCreateTags[self.tagKey] = nil
            else
                curCreateTags[self.tagKey] = true
            end
            UpdateCreationVisuals(true)
        end)

        createTagButtons[tag.key] = tBtn
    end

    -- Section 4: Live Title Preview Box (302px wide)
    local previewBox = CreateFrame("Frame", nil, creationPanel)
    previewBox:SetSize(302, 24)
    previewBox:SetPoint("TOPLEFT", 14, -366)
    previewBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    previewBox:SetBackdropColor(0, 0, 0, 0.85)
    previewBox:SetBackdropBorderColor(0.6, 0.5, 0.2, 0.9)

    local pText = previewBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pText:SetPoint("LEFT", 8, 0)
    pText:SetPoint("RIGHT", -8, 0)
    pText:SetJustifyH("LEFT")
    pText:SetText("+15")
    creationPanel.previewText = pText

    -- Section 5: Action Buttons (Apply & Clear, total 302px)
    local btnApply = CreateFrame("Button", nil, creationPanel, "UIPanelButtonTemplate")
    btnApply:SetSize(196, 26)
    btnApply:SetPoint("TOPLEFT", 14, -396)
    btnApply:SetText(L["QUICK_CREATOR_APPLY"])
    btnApply:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ApplyQuickCreation(curCreateDungeon, curCreateLevel, GetCreationTagsString())
        if addon.TriggerGroupStartSound then
            addon:TriggerGroupStartSound()
        end
    end)

    local btnClear = CreateFrame("Button", nil, creationPanel, "UIPanelButtonTemplate")
    btnClear:SetSize(100, 26)
    btnClear:SetPoint("LEFT", btnApply, "RIGHT", 6, 0)
    btnClear:SetText(L["QUICK_CREATOR_CLEAR"])
    btnClear:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        wipe(curCreateTags)
        curCreateLevel = 15
        UpdateCreationVisuals(true)
    end)

    UpdateCreationVisuals(false)
end

------------------------------------------------------------------------
-- Blacklist Management Panel & Table Pooling
------------------------------------------------------------------------
local blPanel = nil
local blEntryPool = {}

local function AllocBLEntry()
    local e = table.remove(blEntryPool)
    if not e then e = {} end
    return e
end

local function RecycleBLEntries(list)
    if not list then return end
    for i = 1, #list do
        local e = list[i]
        if type(e) == "table" then
            for k in pairs(e) do e[k] = nil end
            blEntryPool[#blEntryPool + 1] = e
        end
        list[i] = nil
    end
end

function addon:CreateBlacklistPanel()
    if blPanel then return end

    blPanel = CreateFrame("Frame", "PremadeGroupSort_BlacklistPanel", UIParent)
    blPanel:SetSize(580, 520)
    blPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    blPanel:SetFrameStrata("DIALOG")
    blPanel:EnableMouse(true)
    blPanel:SetMovable(true)
    blPanel:RegisterForDrag("LeftButton")
    blPanel:SetScript("OnDragStart", blPanel.StartMoving)
    blPanel:SetScript("OnDragStop", blPanel.StopMovingOrSizing)
    blPanel:Hide()
    addon.blPanel = blPanel
    tinsert(UISpecialFrames, "PremadeGroupSort_BlacklistPanel")

    blPanel.currentTab = "blacklist" -- "blacklist" or "whitelist"

    blPanel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    blPanel:SetBackdropColor(0.08, 0.08, 0.12, 0.98)

    -- Anime Catgirl Mascot Art Watermark (Full-frame background)
    local blMascot = blPanel:CreateTexture("PGS_BL_MascotArt", "BACKGROUND", nil, 1)
    blMascot:SetPoint("TOPLEFT", blPanel, "TOPLEFT", 6, -6)
    blMascot:SetPoint("BOTTOMRIGHT", blPanel, "BOTTOMRIGHT", -6, 6)
    blMascot:SetTexture("Interface\\AddOns\\PremadeGroupSort\\Textures\\anime_catgirl.tga")
    blMascot:SetAlpha(0.20)
    addon.blMascotArt = blMascot
    if addon.db and addon.db.soundAnimeArt == false then
        blMascot:Hide()
    end

    -- Header Title
    local title = blPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 16, -14)
    title:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16:0:0|t |cffffd100" .. L["BL_TITLE"] .. "|r")
    blPanel.titleText = title

    -- Tabs: Blacklist vs Whitelist (top right next to close button)
    local tabBL = CreateFrame("Button", nil, blPanel, "UIPanelButtonTemplate")
    tabBL:SetSize(110, 22)
    tabBL:SetPoint("TOPRIGHT", -150, -10)
    tabBL:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:13:13:0:0|t " .. (L["TAB_BLACKLIST"] or "Чёрный список"))
    blPanel.tabBL = tabBL

    local tabWL = CreateFrame("Button", nil, blPanel, "UIPanelButtonTemplate")
    tabWL:SetSize(110, 22)
    tabWL:SetPoint("LEFT", tabBL, "RIGHT", 4, 0)
    tabWL:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:13:13:0:0|t " .. (L["TAB_WHITELIST"] or "Белый список"))
    blPanel.tabWL = tabWL

    local function SetActiveTab(tabName)
        blPanel.currentTab = tabName
        if tabName == "whitelist" then
            title:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16:0:0|t |cff25ff25" .. (L["WL_TITLE"] or "Белый список (Whitelist)") .. "|r")
            tabBL:Enable()
            tabWL:Disable()
            if blPanel.addLabel then blPanel.addLabel:SetText("|cff25ff25" .. (L["WL_ADD_TITLE"] or "Добавить в Белый список") .. ":|r") end
            if blPanel.reasonHint then blPanel.reasonHint:SetText(L["WL_NOTE_HINT"] or "Заметка (Топ танк, Хороший дпс...)") end
            if blPanel.autoSaveCheck then
                blPanel.autoSaveCheck:Show()
                if blPanel.autoSaveCheck.label then
                    blPanel.autoSaveCheck.label:SetText(L["WL_AUTOSAVE_CHECKBOX"])
                end
            end
            if blPanel.importBtn then
                blPanel.importBtn:Show()
                blPanel.importBtn:SetText(L["WL_IMPORT_BUTTON"])
            end
            if blPanel.hdrSource then blPanel.hdrSource:Show() end
            if blPanel.hdrReason and blPanel.hdrReason.label then
                blPanel.hdrReason.baseText = L["WL_COL_NOTE"] or "Заметка"
                blPanel.hdrReason.label:SetText("|cffffd100" .. blPanel.hdrReason.baseText .. "|r")
                blPanel.hdrReason:SetWidth(170)
            end
        else
            title:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16:0:0|t |cffffd100" .. L["BL_TITLE"] .. "|r")
            tabBL:Disable()
            tabWL:Enable()
            if blPanel.addLabel then blPanel.addLabel:SetText("|cffffd100" .. L["BL_ADD_TITLE"] .. ":|r") end
            if blPanel.reasonHint then blPanel.reasonHint:SetText(L["BL_REASON_HINT"] or "Причина (Ливер, Токсик...)") end
            if blPanel.autoSaveCheck then
                blPanel.autoSaveCheck:Show()
                if blPanel.autoSaveCheck.label then
                    blPanel.autoSaveCheck.label:SetText(L["BL_AUTOSAVE_CHECKBOX"])
                end
            end
            if blPanel.importBtn then
                blPanel.importBtn:Show()
                blPanel.importBtn:SetText(L["BL_IMPORT_BUTTON"])
            end
            if blPanel.hdrSource then blPanel.hdrSource:Show() end
            if blPanel.hdrReason and blPanel.hdrReason.label then
                blPanel.hdrReason.baseText = L["BL_COL_REASON"] or "Причина"
                blPanel.hdrReason.label:SetText("|cffffd100" .. blPanel.hdrReason.baseText .. "|r")
                blPanel.hdrReason:SetWidth(170)
            end
        end
        addon:RefreshBlacklistPanel()
    end
    blPanel.SetActiveTab = SetActiveTab

    tabBL:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        SetActiveTab("blacklist")
    end)
    tabWL:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        SetActiveTab("whitelist")
    end)

    -- Close Button [X]
    local closeBtn = CreateFrame("Button", nil, blPanel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        blPanel:Hide()
    end)

    -- Add New Player Section
    local addLabel = blPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    addLabel:SetPoint("TOPLEFT", 16, -34)
    addLabel:SetText("|cffffd100" .. L["BL_ADD_TITLE"] .. ":|r")
    blPanel.addLabel = addLabel

    -- Name Input Box
    local nameBox = CreateFrame("EditBox", "PGS_BL_NameInput", blPanel, "InputBoxTemplate")
    nameBox:SetSize(120, 20)
    nameBox:SetPoint("TOPLEFT", 16, -52)
    nameBox:SetAutoFocus(false)
    nameBox:SetText("")
    blPanel.nameBox = nameBox

    local nameHint = nameBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    nameHint:SetPoint("LEFT", 4, 0)
    nameHint:SetText(L["BL_NAME_HINT"])
    nameBox.hint = nameHint

    nameBox:SetScript("OnTextChanged", function(self)
        if self:GetText() == "" then
            nameHint:Show()
        else
            nameHint:Hide()
        end
    end)

    -- Reason / Note Input Box
    local reasonBox = CreateFrame("EditBox", "PGS_BL_ReasonInput", blPanel, "InputBoxTemplate")
    reasonBox:SetSize(315, 20)
    reasonBox:SetPoint("LEFT", nameBox, "RIGHT", 8, 0)
    reasonBox:SetAutoFocus(false)
    reasonBox:SetText("")
    blPanel.reasonBox = reasonBox

    local reasonHint = reasonBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    reasonHint:SetPoint("LEFT", 4, 0)
    reasonHint:SetText(L["BL_REASON_HINT"])
    blPanel.reasonHint = reasonHint

    reasonBox:SetScript("OnTextChanged", function(self)
        if self:GetText() == "" then
            reasonHint:Show()
        else
            reasonHint:Hide()
        end
    end)

    reasonBox:SetScript("OnEnterPressed", function()
        if blPanel.addBtn then
            blPanel.addBtn:Click()
        end
    end)
    nameBox:SetScript("OnEnterPressed", function()
        reasonBox:SetFocus()
    end)

    -- Add Button
    local addBtn = CreateFrame("Button", nil, blPanel, "UIPanelButtonTemplate")
    addBtn:SetSize(86, 22)
    addBtn:SetPoint("LEFT", reasonBox, "RIGHT", 8, 0)
    addBtn:SetText(L["BL_ADD_BUTTON"])
    addBtn:SetScript("OnClick", function()
        local n = nameBox:GetText()
        local r = reasonBox:GetText()
        if n and n ~= "" then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            if blPanel.currentTab == "whitelist" then
                addon:AddWhitelist(n, r)
            else
                addon:AddBlacklist(n, r)
            end
            nameBox:SetText("")
            reasonBox:SetText("")
            nameBox:ClearFocus()
            reasonBox:ClearFocus()
        end
    end)
    blPanel.addBtn = addBtn

    -- Chat Quick Hint
    local chatHint = blPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    chatHint:SetPoint("TOPLEFT", 16, -76)
    chatHint:SetText("|cff888888" .. L["BL_CHAT_HINT"] .. "|r")

    -- Separator 1
    local sep1 = blPanel:CreateTexture(nil, "ARTWORK")
    sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT", 14, -92)
    sep1:SetPoint("TOPRIGHT", -14, -92)
    sep1:SetColorTexture(0.35, 0.35, 0.4, 0.8)

    -- AutoSave Checkbox
    local autoSaveCheck = CreateFrame("CheckButton", "PGS_BL_AutoSaveCheck", blPanel, "UICheckButtonTemplate")
    autoSaveCheck:SetSize(24, 24)
    autoSaveCheck:SetPoint("TOPLEFT", 14, -97)
    local autoSaveLabel = autoSaveCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    autoSaveLabel:SetPoint("LEFT", autoSaveCheck, "RIGHT", 4, 0)
    autoSaveLabel:SetText(L["BL_AUTOSAVE_CHECKBOX"])
    autoSaveCheck.label = autoSaveLabel

    autoSaveCheck:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        if addon.db then
            if blPanel.currentTab == "whitelist" then
                addon.db.autoSavePartyWhitelist = self:GetChecked() and true or false
            else
                addon.db.autoSavePartyBlacklist = self:GetChecked() and true or false
            end
        end
    end)
    autoSaveCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if blPanel.currentTab == "whitelist" then
            GameTooltip:AddLine(L["WL_AUTOSAVE_CHECKBOX"], 1, 1, 1)
            GameTooltip:AddLine(L["WL_AUTOSAVE_TOOLTIP"], 0.8, 0.8, 0.8, true)
        else
            GameTooltip:AddLine(L["BL_AUTOSAVE_CHECKBOX"], 1, 1, 1)
            GameTooltip:AddLine(L["BL_AUTOSAVE_TOOLTIP"], 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)
    autoSaveCheck:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    blPanel.autoSaveCheck = autoSaveCheck

    -- Import Button
    local importBtn = CreateFrame("Button", "PGS_BL_ImportBtn", blPanel, "UIPanelButtonTemplate")
    importBtn:SetSize(180, 24)
    importBtn:SetPoint("TOPLEFT", 16, -125)
    importBtn:SetText(L["BL_IMPORT_BUTTON"])
    importBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        if blPanel.currentTab == "whitelist" then
            addon:ImportPartyWhitelist()
        else
            addon:ImportPartyBlacklist()
        end
    end)
    importBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if blPanel.currentTab == "whitelist" then
            GameTooltip:AddLine(L["WL_IMPORT_BUTTON"], 1, 1, 1)
            GameTooltip:AddLine(L["WL_IMPORT_TOOLTIP"], 0.8, 0.8, 0.8, true)
        else
            GameTooltip:AddLine(L["BL_IMPORT_BUTTON"], 1, 1, 1)
            GameTooltip:AddLine(L["BL_IMPORT_TOOLTIP"], 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)
    importBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    blPanel.importBtn = importBtn

    -- Search Box (Real-time filter by nickname / reason)
    local searchBox = CreateFrame("EditBox", "PGS_BL_SearchInput", blPanel, "InputBoxTemplate")
    searchBox:SetSize(220, 20)
    searchBox:SetPoint("TOPRIGHT", blPanel, "TOPRIGHT", -32, -127)
    searchBox:SetAutoFocus(false)
    searchBox:SetText("")
    blPanel.searchBox = searchBox

    local searchHint = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchHint:SetPoint("LEFT", 4, 0)
    searchHint:SetText("|TInterface\\Common\\UI-Searchbox-Icon:12:12:0:0|t " .. L["BL_SEARCH_HINT"])
    searchBox.hint = searchHint

    local clearSearchBtn = CreateFrame("Button", nil, searchBox)
    clearSearchBtn:SetSize(14, 14)
    clearSearchBtn:SetPoint("RIGHT", -2, 0)
    local clearTxt = clearSearchBtn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    clearTxt:SetPoint("CENTER", 0, 0)
    clearTxt:SetText("|cffaaaaaa[x]|r")
    clearSearchBtn:Hide()
    clearSearchBtn:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
    end)
    searchBox.clearBtn = clearSearchBtn

    searchBox:SetScript("OnTextChanged", function(self)
        local txt = self:GetText()
        if txt == "" then
            searchHint:Show()
            clearSearchBtn:Hide()
        else
            searchHint:Hide()
            clearSearchBtn:Show()
        end
        addon:RefreshBlacklistPanel()
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    -- Separator 2
    local sep2 = blPanel:CreateTexture(nil, "ARTWORK")
    sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT", 14, -155)
    sep2:SetPoint("TOPRIGHT", -14, -155)
    sep2:SetColorTexture(0.35, 0.35, 0.4, 0.8)

    -- Count Text
    local countText = blPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countText:SetPoint("TOPLEFT", 16, -160)
    countText:SetText(string.format(L["BL_COUNT_LABEL"], 0))
    blPanel.countText = countText

    -- Table Column Header Bar
    local colHeader = CreateFrame("Frame", nil, blPanel)
    colHeader:SetSize(524, 20)
    colHeader:SetPoint("TOPLEFT", 14, -178)
    colHeader:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    colHeader:SetBackdropColor(0.12, 0.12, 0.18, 0.95)
    colHeader:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.7)
    blPanel.colHeader = colHeader

    blPanel.sortField = "name"
    blPanel.sortAsc = true

    local function CreateSortHeader(text, width, point, relFrame, relPoint, x, field)
        local btn = CreateFrame("Button", nil, colHeader)
        btn:SetSize(width, 18)
        if relFrame then
            btn:SetPoint(point, relFrame, relPoint, x, 0)
        else
            btn:SetPoint(point, x, 0)
        end
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", 2, 0)
        label:SetJustifyH("LEFT")
        label:SetText("|cffffd100" .. text .. "|r")
        btn.label = label
        btn.baseText = text
        btn.field = field

        if field then
            btn:SetScript("OnClick", function()
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                if blPanel.sortField == field then
                    blPanel.sortAsc = not blPanel.sortAsc
                else
                    blPanel.sortField = field
                    blPanel.sortAsc = true
                end
                addon:RefreshBlacklistPanel()
            end)
            btn:SetScript("OnEnter", function()
                label:SetText("|cffffff00" .. btn.baseText .. "|r")
            end)
            btn:SetScript("OnLeave", function()
                addon:UpdateSortHeaders()
            end)
        end
        return btn
    end

    blPanel.hdrName = CreateSortHeader(L["BL_COL_NAME"], 110, "LEFT", nil, nil, 22, "name")
    blPanel.hdrReason = CreateSortHeader(L["BL_COL_REASON"], 170, "LEFT", blPanel.hdrName, "RIGHT", 6, "reason")
    blPanel.hdrSource = CreateSortHeader(L["BL_COL_SOURCE"], 95, "LEFT", blPanel.hdrReason, "RIGHT", 6, nil)
    blPanel.hdrDate = CreateSortHeader(L["BL_COL_DATE"], 75, "LEFT", blPanel.hdrSource, "RIGHT", 6, "date")

    -- Scroll Frame (FauxScrollFrameTemplate handles standard scrollbar, wheel & slider)
    local scrollFrame = CreateFrame("ScrollFrame", "PremadeGroupSort_BLScroll", blPanel, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 14, -202)
    scrollFrame:SetPoint("BOTTOMRIGHT", -36, 14)
    blPanel.scrollFrame = scrollFrame

    -- Container for fixed visible rows (prevents any out-of-bounds rendering)
    local rowContainer = CreateFrame("Frame", "PremadeGroupSort_BLRowContainer", blPanel)
    rowContainer:SetPoint("TOPLEFT", 14, -202)
    rowContainer:SetPoint("BOTTOMRIGHT", -36, 14)
    rowContainer:SetClipsChildren(true)
    blPanel.rowContainer = rowContainer

    local NUM_ROWS = 12
    local ROW_HEIGHT = 25
    blPanel.NUM_ROWS = NUM_ROWS
    blPanel.ROW_HEIGHT = ROW_HEIGHT
    blPanel.rows = {}

    for i = 1, NUM_ROWS do
        local row = CreateFrame("Frame", nil, rowContainer)
        row:SetSize(524, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, - (i - 1) * ROW_HEIGHT)

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(row)
        row.bg = bg

        local skull = row:CreateTexture(nil, "ARTWORK")
        skull:SetSize(14, 14)
        skull:SetPoint("LEFT", 4, 0)
        skull:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
        row.skull = skull

        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameText:SetPoint("LEFT", skull, "RIGHT", 4, 0)
        nameText:SetWidth(110)
        nameText:SetJustifyH("LEFT")
        row.nameText = nameText

        local reasonText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        reasonText:SetPoint("LEFT", nameText, "RIGHT", 6, 0)
        reasonText:SetWidth(170)
        reasonText:SetJustifyH("LEFT")
        row.reasonText = reasonText

        local sourceText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        sourceText:SetPoint("LEFT", reasonText, "RIGHT", 6, 0)
        sourceText:SetWidth(95)
        sourceText:SetJustifyH("LEFT")
        row.sourceText = sourceText

        local dateText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        dateText:SetPoint("LEFT", sourceText, "RIGHT", 6, 0)
        dateText:SetWidth(75)
        dateText:SetJustifyH("CENTER")
        row.dateText = dateText

        local delBtn = CreateFrame("Button", nil, row)
        delBtn:SetSize(24, 18)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        local delTxt = delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        delTxt:SetPoint("CENTER", 0, 0)
        delTxt:SetText("|cffff2020[X]|r")
        delBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if blPanel.currentTab == "whitelist" then
                GameTooltip:SetText(L["WL_DELETE_TOOLTIP"], 1, 0.2, 0.2)
            else
                GameTooltip:SetText(L["BL_DELETE_TOOLTIP"], 1, 0.2, 0.2)
            end
            GameTooltip:Show()
        end)
        delBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        delBtn:SetScript("OnClick", function(self)
            if row.entryName then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                if blPanel.currentTab == "whitelist" then
                    addon:RemoveWhitelist(row.entryName)
                else
                    addon:RemoveBlacklist(row.entryName)
                end
            end
        end)
        row.delBtn = delBtn

        row:EnableMouse(true)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(self, delta)
            addon:ScrollBlacklist(delta)
        end)

        row:SetScript("OnEnter", function(self)
            if not self.item then return end
            local item = self.item
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if blPanel.currentTab == "whitelist" then
                GameTooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16:0:0|t |cff25ff25" .. (item.name or "") .. "|r", 0.2, 1, 0.2)
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine("|cffffd100" .. L["WL_COL_NOTE"] .. ":|r", "|cffffffff" .. (item.reason or "") .. "|r", 1, 1, 1, 1, 1, 1)
            else
                GameTooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16:0:0|t |cffff2020" .. (item.name or "") .. "|r", 1, 0.2, 0.2)
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_REASON"] .. ":|r", "|cffffffff" .. (item.reason or "") .. "|r", 1, 1, 1, 1, 1, 1)
                local byStr = (item.addedBy and item.addedBy ~= "") and item.addedBy or "Alt"
                if item.isSelf then
                    GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_SOURCE"] .. ":|r", "|cffaaaaaa" .. L["BL_SOURCE_SELF"] .. " (" .. byStr .. ")|r", 1, 1, 1, 1, 1, 1)
                elseif item.source == "guild" then
                    GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_SOURCE"] .. ":|r", "|cff00ff00Гильдия (" .. byStr .. ")|r", 1, 1, 1, 1, 1, 1)
                else
                    GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_SOURCE"] .. ":|r", "|cff00ccffГруппа (" .. byStr .. ")|r", 1, 1, 1, 1, 1, 1)
                end
            end
            if item.timestamp and item.timestamp > 0 then
                local fullDate = date("%d.%m.%Y в %H:%M", item.timestamp)
                GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_DATE"] .. ":|r", "|cffffffff" .. fullDate .. "|r", 1, 1, 1, 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        blPanel.rows[i] = row
    end

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function()
            GameTooltip:Hide()
            addon:UpdateBlacklistRows()
        end)
    end)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        addon:ScrollBlacklist(delta)
    end)

    blPanel:EnableMouseWheel(true)
    blPanel:SetScript("OnMouseWheel", function(self, delta)
        addon:ScrollBlacklist(delta)
    end)

    blPanel:SetScript("OnHide", function()
        GameTooltip:Hide()
    end)

    SetActiveTab("blacklist")
end

function addon:ScrollBlacklist(delta)
    if not blPanel or not blPanel.scrollFrame then return end
    local scrollBar = _G["PremadeGroupSort_BLScrollScrollBar"] or blPanel.scrollFrame.ScrollBar
    if not scrollBar then return end
    local cur = scrollBar:GetValue()
    local minV, maxV = scrollBar:GetMinMaxValues()
    if delta > 0 then
        scrollBar:SetValue(math.max(minV, cur - 25))
    else
        scrollBar:SetValue(math.min(maxV, cur + 25))
    end
end

function addon:UpdateBlacklistRows()
    if not blPanel or not blPanel.rows then return end
    local entries = blPanel.displayEntries or {}
    local offset = FauxScrollFrame_GetOffset(blPanel.scrollFrame)
    local numRows = blPanel.NUM_ROWS or 12
    local isWL = (blPanel.currentTab == "whitelist")

    for i = 1, numRows do
        local row = blPanel.rows[i]
        local idx = offset + i
        local item = entries[idx]
        if item then
            row.item = item
            row.entryName = item.name

            if (idx % 2) == 1 then
                row.bg:SetColorTexture(0.12, 0.12, 0.16, 0.6)
            else
                row.bg:SetColorTexture(0.07, 0.07, 0.10, 0.6)
            end

            if isWL then
                row.skull:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
                row.nameText:SetText("|cff25ff25" .. item.name .. "|r")
                row.reasonText:SetWidth(170)
                row.sourceText:Show()

                local rDisp = item.reason or ""
                if string.len(rDisp) > 32 then
                    rDisp = string.sub(rDisp, 1, 30) .. ".."
                end
                row.reasonText:SetText("|cff80ff80[" .. rDisp .. "]|r")

                if item.isSelf then
                    local byStr = (item.addedBy and item.addedBy ~= "") and item.addedBy or "Alt"
                    row.sourceText:SetText("|cffaaaaaa(" .. byStr .. ")|r")
                    row.delBtn:Show()
                elseif item.source == "guild" then
                    row.sourceText:SetText("|cff00ff00(" .. (item.addedBy or "Guild") .. ")|r")
                    row.delBtn:Hide()
                else
                    row.sourceText:SetText("|cff00ccff(" .. (item.addedBy or "Party") .. ")|r")
                    row.delBtn:Hide()
                end
            else
                row.skull:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
                row.nameText:SetText(item.name)
                row.sourceText:Show()
                row.reasonText:SetWidth(170)

                local rDisp = item.reason or ""
                if string.len(rDisp) > 32 then
                    rDisp = string.sub(rDisp, 1, 30) .. ".."
                end
                row.reasonText:SetText("|cffff8080[" .. rDisp .. "]|r")

                if item.isSelf then
                    local byStr = (item.addedBy and item.addedBy ~= "") and item.addedBy or "Alt"
                    row.sourceText:SetText("|cffaaaaaa(" .. byStr .. ")|r")
                    row.delBtn:Show()
                elseif item.source == "guild" then
                    row.sourceText:SetText("|cff00ff00(" .. (item.addedBy or "Guild") .. ")|r")
                    row.delBtn:Hide()
                else
                    row.sourceText:SetText("|cff00ccff(" .. (item.addedBy or "Party") .. ")|r")
                    row.delBtn:Hide()
                end
            end

            local dStr = "-"
            if item.timestamp and item.timestamp > 0 then
                dStr = date("%d.%m.%y", item.timestamp)
            end
            row.dateText:SetText("|cffaaaaaa" .. dStr .. "|r")

            row:Show()
        else
            row.item = nil
            row.entryName = nil
            row:Hide()
        end
    end
end

function addon:UpdateSortHeaders()
    if not blPanel or not blPanel.hdrName then return end
    local headers = {
        { btn = blPanel.hdrName, field = "name" },
        { btn = blPanel.hdrReason, field = "reason" },
        { btn = blPanel.hdrDate, field = "date" },
    }
    for _, h in ipairs(headers) do
        if h.btn then
            local arrow = ""
            if blPanel.sortField == h.field then
                arrow = blPanel.sortAsc and " [^]" or " [v]"
            end
            h.btn.label:SetText("|cffffd100" .. h.btn.baseText .. arrow .. "|r")
        end
    end
end

function addon:ToggleBlacklistPanel(forceTab)
    if not blPanel then
        addon:CreateBlacklistPanel()
    end
    if blPanel:IsShown() and (not forceTab or blPanel.currentTab == forceTab) then
        blPanel:Hide()
    else
        blPanel:Show()
        if forceTab and blPanel.SetActiveTab then
            blPanel.SetActiveTab(forceTab)
        else
            addon:RefreshBlacklistPanel()
        end
    end
end

function addon:ToggleWhitelistPanel()
    addon:ToggleBlacklistPanel("whitelist")
end

function addon:RefreshWhitelistPanel()
    addon:RefreshBlacklistPanel()
end

function addon:RefreshBlacklistPanel()
    if not blPanel or not blPanel:IsShown() then return end

    if blPanel.rawEntries then
        RecycleBLEntries(blPanel.rawEntries)
    else
        blPanel.rawEntries = {}
    end
    local entries = blPanel.rawEntries

    if blPanel.displayEntries then
        RecycleBLEntries(blPanel.displayEntries)
    else
        blPanel.displayEntries = {}
    end
    local displayEntries = blPanel.displayEntries

    local selfCount = 0
    local partyCount = 0
    local guildCount = 0

    if blPanel.currentTab == "whitelist" then
        -- Load Whitelist entries
        -- 1. Account / Self entries
        if addon.db and addon.db.whitelist then
            for key, info in pairs(addon.db.whitelist) do
                local e = AllocBLEntry()
                e.key = key
                e.name = info.name or key
                e.reason = info.note or L["WL_DEFAULT_NOTE"]
                e.addedBy = info.addedBy or UnitName("player")
                e.isSelf = true
                e.source = "whitelist"
                e.timestamp = info.timestamp or 0
                table.insert(entries, e)
                selfCount = selfCount + 1
            end
        end

        -- 2. Party members' whitelist entries
        if addon.partyWhitelist then
            for memberName, memberWL in pairs(addon.partyWhitelist) do
                for key, info in pairs(memberWL) do
                    if not (addon.db.whitelist and addon.db.whitelist[key]) then
                        local e = AllocBLEntry()
                        e.key = key
                        e.name = info.name or key
                        e.reason = info.note or L["WL_DEFAULT_NOTE"]
                        e.addedBy = memberName
                        e.isSelf = false
                        e.source = "party"
                        e.timestamp = info.timestamp or 0
                        table.insert(entries, e)
                        partyCount = partyCount + 1
                    end
                end
            end
        end

        -- 3. Guild members' whitelist entries
        if addon.guildWhitelist then
            for memberName, memberWL in pairs(addon.guildWhitelist) do
                for key, info in pairs(memberWL) do
                    if not (addon.db.whitelist and addon.db.whitelist[key]) then
                        local alreadyInList = false
                        for _, e in ipairs(entries) do
                            if e.key == key then alreadyInList = true; break end
                        end
                        if not alreadyInList then
                            local e = AllocBLEntry()
                            e.key = key
                            e.name = info.name or key
                            e.reason = info.note or L["WL_DEFAULT_NOTE"]
                            e.addedBy = memberName
                            e.isSelf = false
                            e.source = "guild"
                            e.timestamp = info.timestamp or 0
                            table.insert(entries, e)
                            guildCount = guildCount + 1
                        end
                    end
                end
            end
        end
    else
        -- Load Blacklist entries
        -- 1. Account / Self entries
        if addon.db and addon.db.blacklist then
            for key, info in pairs(addon.db.blacklist) do
                local e = AllocBLEntry()
                e.key = key
                e.name = info.name or key
                e.reason = info.reason or L["BL_DEFAULT_REASON"]
                e.addedBy = info.addedBy or UnitName("player")
                e.isSelf = true
                e.source = info.source or "manual"
                e.timestamp = info.timestamp or 0
                table.insert(entries, e)
                selfCount = selfCount + 1
            end
        end

        -- 2. Party members' entries
        if addon.partyBlacklist then
            for memberName, memberBL in pairs(addon.partyBlacklist) do
                for key, info in pairs(memberBL) do
                    if not (addon.db.blacklist and addon.db.blacklist[key]) then
                        local e = AllocBLEntry()
                        e.key = key
                        e.name = info.name or key
                        e.reason = info.reason or L["BL_DEFAULT_REASON"]
                        e.addedBy = memberName
                        e.isSelf = false
                        e.source = "party"
                        e.timestamp = info.timestamp or 0
                        table.insert(entries, e)
                        partyCount = partyCount + 1
                    end
                end
            end
        end

        -- 3. Guild members' entries
        if addon.guildBlacklist then
            for memberName, memberBL in pairs(addon.guildBlacklist) do
                for key, info in pairs(memberBL) do
                    if not (addon.db.blacklist and addon.db.blacklist[key]) then
                        local alreadyInList = false
                        for _, e in ipairs(entries) do
                            if e.key == key then alreadyInList = true; break end
                        end
                        if not alreadyInList then
                            local e = AllocBLEntry()
                            e.key = key
                            e.name = info.name or key
                            e.reason = info.reason or L["BL_DEFAULT_REASON"]
                            e.addedBy = memberName
                            e.isSelf = false
                            e.source = "guild"
                            e.timestamp = info.timestamp or 0
                            table.insert(entries, e)
                            guildCount = guildCount + 1
                        end
                    end
                end
            end
        end
    end

    -- Real-time Search Filtering (search by nickname or reason/note)
    local searchFilter = safeLower(blPanel.searchBox and blPanel.searchBox:GetText() or "")
    for _, item in ipairs(entries) do
        if searchFilter == "" then
            table.insert(displayEntries, item)
        else
            local matchName = string.find(safeLower(item.name or ""), searchFilter, 1, true)
            local matchReason = string.find(safeLower(item.reason or ""), searchFilter, 1, true)
            if matchName or matchReason then
                table.insert(displayEntries, item)
            end
        end
    end

    -- Sorting
    local sortField = blPanel.sortField or "name"
    local sortAsc = (blPanel.sortAsc ~= false)

    table.sort(displayEntries, function(a, b)
        if sortField == "date" then
            local tsA = a.timestamp or 0
            local tsB = b.timestamp or 0
            if tsA ~= tsB then
                if sortAsc then return tsA < tsB else return tsA > tsB end
            end
        elseif sortField == "reason" then
            local rA = safeLower(a.reason or "")
            local rB = safeLower(b.reason or "")
            if rA ~= rB then
                if sortAsc then return rA < rB else return rA > rB end
            end
        else -- name
            if a.isSelf ~= b.isSelf then
                return a.isSelf
            end
            local nA = safeLower(a.name or "")
            local nB = safeLower(b.name or "")
            if nA ~= nB then
                if sortAsc then return nA < nB else return nA > nB end
            end
        end
        return (a.name or "") < (b.name or "")
    end)

    local total = #entries
    local visibleCount = #displayEntries

    if blPanel.currentTab == "whitelist" then
        if searchFilter ~= "" then
            blPanel.countText:SetText(string.format(L["BL_FOUND_COUNT"], visibleCount, total))
        else
            local extraStr = ""
            if partyCount > 0 and guildCount > 0 then
                extraStr = " |cff888888(" .. selfCount .. " + " .. partyCount .. " пати + " .. guildCount .. " гильдия)|r"
            elseif partyCount > 0 then
                extraStr = " |cff888888(" .. selfCount .. " + " .. partyCount .. " " .. (GetLocale() == "ruRU" and "от группы" or "from party") .. ")|r"
            elseif guildCount > 0 then
                extraStr = " |cff888888(" .. selfCount .. " + " .. guildCount .. " " .. (GetLocale() == "ruRU" and "от гильдии" or "from guild") .. ")|r"
            end
            blPanel.countText:SetText(string.format(L["WL_COUNT_LABEL"], total) .. extraStr)
        end
    else
        if searchFilter ~= "" then
            blPanel.countText:SetText(string.format(L["BL_FOUND_COUNT"], visibleCount, total))
        else
            local extraStr = ""
            if partyCount > 0 and guildCount > 0 then
                extraStr = " |cff888888(" .. selfCount .. " + " .. partyCount .. " пати + " .. guildCount .. " гильдия)|r"
            elseif partyCount > 0 then
                extraStr = " |cff888888(" .. selfCount .. " + " .. partyCount .. " " .. (GetLocale() == "ruRU" and "от группы" or "from party") .. ")|r"
            elseif guildCount > 0 then
                extraStr = " |cff888888(" .. selfCount .. " + " .. guildCount .. " " .. (GetLocale() == "ruRU" and "от гильдии" or "from guild") .. ")|r"
            end
            blPanel.countText:SetText(string.format(L["BL_COUNT_LABEL"], total) .. extraStr)
        end
    end

    if blPanel.autoSaveCheck then
        if blPanel.currentTab == "whitelist" then
            blPanel.autoSaveCheck:SetChecked(addon.db and addon.db.autoSavePartyWhitelist and true or false)
        else
            blPanel.autoSaveCheck:SetChecked(addon.db and addon.db.autoSavePartyBlacklist and true or false)
        end
    end
    if blPanel.importBtn then
        local totalExt = partyCount + guildCount
        local baseBtnText = (blPanel.currentTab == "whitelist") and L["WL_IMPORT_BUTTON"] or L["BL_IMPORT_BUTTON"]
        if totalExt > 0 then
            blPanel.importBtn:SetText(baseBtnText .. " (" .. totalExt .. ")")
        else
            blPanel.importBtn:SetText(baseBtnText)
        end
    end

    addon:UpdateSortHeaders()

    if visibleCount == 0 then
        if not blPanel.emptyText then
            local empty = blPanel.rowContainer:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            empty:SetPoint("CENTER", blPanel.rowContainer, "CENTER", 0, 0)
            blPanel.emptyText = empty
        end
        if searchFilter ~= "" then
            blPanel.emptyText:SetText(GetLocale() == "ruRU" and "Ничего не найдено по запросу." or "No matching players found.")
        else
            if blPanel.currentTab == "whitelist" then
                blPanel.emptyText:SetText(L["WL_EMPTY_LIST"])
            else
                blPanel.emptyText:SetText(L["BL_EMPTY_LIST"])
            end
        end
        blPanel.emptyText:Show()
    else
        if blPanel.emptyText then blPanel.emptyText:Hide() end
    end

    FauxScrollFrame_Update(blPanel.scrollFrame, visibleCount, blPanel.NUM_ROWS, blPanel.ROW_HEIGHT)
    addon:UpdateBlacklistRows()
end

------------------------------------------------------------------------
-- Blizzard Interface Options Panels
------------------------------------------------------------------------
function addon:CreateInterfaceOptions()
    if addon.optionsInitialized then return end
    addon.optionsInitialized = true

    --------------------------------------------------------------------
    -- 1. Main Options Panel: "Premade Group Sort"
    --------------------------------------------------------------------
    local mainPanel = CreateFrame("Frame", "PremadeGroupSort_Options_Main", UIParent)
    mainPanel.name = "Premade Group Sort"
    addon.optionsMainPanel = mainPanel

    -- Full High-Quality Mascot Background Watermark (1024x1024 master asset spanning full panel)
    local mainBgMascot = mainPanel:CreateTexture("PremadeGroupSort_Opt_MainBgArt", "BACKGROUND", nil, -1)
    mainBgMascot:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 0, 0)
    mainBgMascot:SetPoint("BOTTOMRIGHT", mainPanel, "BOTTOMRIGHT", 0, 0)
    mainBgMascot:SetTexture("Interface\\AddOns\\PremadeGroupSort\\Textures\\anime_catgirl.tga")
    mainBgMascot:SetAlpha(0.20)
    mainPanel.mascotBg = mainBgMascot
    if addon.db and addon.db.soundAnimeArt == false then
        mainBgMascot:Hide()
    end

    -- Header Title
    local title = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00ccff" .. L["OPT_TITLE"] .. "|r |cff888888v1.3.0|r")

    -- Subtitle
    local sub = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetText(L["OPT_SUBTITLE"])

    -- Section 1: General Settings (Left Column)
    local sec1 = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sec1:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -12)
    sec1:SetText("|cffffd100" .. L["OPT_CATEGORY_GENERAL"] .. "|r")

    local sep1 = mainPanel:CreateTexture(nil, "ARTWORK")
    sep1:SetSize(320, 1)
    sep1:SetPoint("TOPLEFT", sec1, "BOTTOMLEFT", 0, -4)
    sep1:SetColorTexture(0.35, 0.35, 0.4, 0.6)

    -- Checkbox: Dungeon Bar
    local cbDungeonBar = CreateFrame("CheckButton", "PGS_Opt_DungeonBar", mainPanel, "UICheckButtonTemplate")
    cbDungeonBar:SetPoint("TOPLEFT", sep1, "BOTTOMLEFT", 0, -4)
    local cbDungeonBarLabel = cbDungeonBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbDungeonBarLabel:SetPoint("LEFT", cbDungeonBar, "RIGHT", 4, 0)
    cbDungeonBarLabel:SetText(L["OPT_DUNGEON_BAR"])
    cbDungeonBar.tooltipText = L["OPT_DUNGEON_BAR_DESC"]
    cbDungeonBar:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.dungeonBarOpen = self:GetChecked() and true or false
        if addon.UpdatePanelVisibility then addon:UpdatePanelVisibility() end
    end)
    mainPanel.cbDungeonBar = cbDungeonBar

    -- Checkbox: Mythic Only
    local cbMythicOnly = CreateFrame("CheckButton", "PGS_Opt_MythicOnly", mainPanel, "UICheckButtonTemplate")
    cbMythicOnly:SetPoint("TOPLEFT", cbDungeonBar, "BOTTOMLEFT", 0, -2)
    local cbMythicOnlyLabel = cbMythicOnly:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbMythicOnlyLabel:SetPoint("LEFT", cbMythicOnly, "RIGHT", 4, 0)
    cbMythicOnlyLabel:SetText(L["OPT_MYTHIC_ONLY"])
    cbMythicOnly.tooltipText = L["OPT_MYTHIC_ONLY_DESC"]
    cbMythicOnly:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.onlyMythicPlus = self:GetChecked() and true or false
        if addon.RefreshResults then addon:RefreshResults() end
    end)
    mainPanel.cbMythicOnly = cbMythicOnly

    -- Checkbox: English Titles
    local cbEngTitles = CreateFrame("CheckButton", "PGS_Opt_EngTitles", mainPanel, "UICheckButtonTemplate")
    cbEngTitles:SetPoint("TOPLEFT", cbMythicOnly, "BOTTOMLEFT", 0, -2)
    local cbEngTitlesLabel = cbEngTitles:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbEngTitlesLabel:SetPoint("LEFT", cbEngTitles, "RIGHT", 4, 0)
    cbEngTitlesLabel:SetText(L["OPT_ENG_TITLES"])
    cbEngTitles.tooltipText = L["OPT_ENG_TITLES_DESC"]
    cbEngTitles:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.englishKeystoneTitles = self:GetChecked() and true or false
    end)
    mainPanel.cbEngTitles = cbEngTitles

    -- Checkbox: Minimap Button
    local cbMinimap = CreateFrame("CheckButton", "PGS_Opt_Minimap", mainPanel, "UICheckButtonTemplate")
    cbMinimap:SetPoint("TOPLEFT", cbEngTitles, "BOTTOMLEFT", 0, -2)
    local cbMinimapLabel = cbMinimap:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbMinimapLabel:SetPoint("LEFT", cbMinimap, "RIGHT", 4, 0)
    cbMinimapLabel:SetText(L["OPT_MINIMAP_ICON"])
    cbMinimap.tooltipText = L["OPT_MINIMAP_ICON_DESC"]
    cbMinimap:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.minimapIcon = self:GetChecked() and true or false
        if addon.minimapBtn then
            addon.minimapBtn:SetShown(addon.db.minimapIcon)
        end
    end)
    mainPanel.cbMinimap = cbMinimap

    -- Section 2: Blacklist, Whitelist & Sync (Left Column)
    local sec2 = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sec2:SetPoint("TOPLEFT", cbMinimap, "BOTTOMLEFT", 0, -10)
    sec2:SetText("|cffffd100" .. (GetLocale() == "ruRU" and "Чёрный / Белый список и Синхронизация" or "Blacklist / Whitelist & Sync") .. "|r")

    local sep2 = mainPanel:CreateTexture(nil, "ARTWORK")
    sep2:SetSize(320, 1)
    sep2:SetPoint("TOPLEFT", sec2, "BOTTOMLEFT", 0, -4)
    sep2:SetColorTexture(0.35, 0.35, 0.4, 0.6)

    -- Checkbox: Auto-save party BL
    local cbAutoSave = CreateFrame("CheckButton", "PGS_Opt_AutoSave", mainPanel, "UICheckButtonTemplate")
    cbAutoSave:SetPoint("TOPLEFT", sep2, "BOTTOMLEFT", 0, -4)
    local cbAutoSaveLabel = cbAutoSave:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbAutoSaveLabel:SetPoint("LEFT", cbAutoSave, "RIGHT", 4, 0)
    cbAutoSaveLabel:SetText(L["OPT_AUTOSAVE_PARTY"])
    cbAutoSave.tooltipText = L["OPT_AUTOSAVE_PARTY_DESC"]
    cbAutoSave:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.autoSavePartyBlacklist = self:GetChecked() and true or false
    end)
    mainPanel.cbAutoSave = cbAutoSave

    -- Checkbox: Guild Sync
    local cbSyncGuild = CreateFrame("CheckButton", "PGS_Opt_SyncGuild", mainPanel, "UICheckButtonTemplate")
    cbSyncGuild:SetPoint("TOPLEFT", cbAutoSave, "BOTTOMLEFT", 0, -2)
    local cbSyncGuildLabel = cbSyncGuild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbSyncGuildLabel:SetPoint("LEFT", cbSyncGuild, "RIGHT", 4, 0)
    cbSyncGuildLabel:SetText(L["OPT_SYNC_GUILD"])
    cbSyncGuild.tooltipText = L["OPT_SYNC_GUILD_DESC"]
    cbSyncGuild:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.syncGuildBlacklist = self:GetChecked() and true or false
        if addon.db.syncGuildBlacklist and IsInGuild() then
            addon:BroadcastBlacklist()
        end
    end)
    mainPanel.cbSyncGuild = cbSyncGuild

    -- Checkbox: Auto-save party WL
    local cbAutoSaveWL = CreateFrame("CheckButton", "PGS_Opt_AutoSaveWL", mainPanel, "UICheckButtonTemplate")
    cbAutoSaveWL:SetPoint("TOPLEFT", cbSyncGuild, "BOTTOMLEFT", 0, -2)
    local cbAutoSaveWLLabel = cbAutoSaveWL:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbAutoSaveWLLabel:SetPoint("LEFT", cbAutoSaveWL, "RIGHT", 4, 0)
    cbAutoSaveWLLabel:SetText(L["OPT_AUTOSAVE_PARTY_WL"])
    cbAutoSaveWL.tooltipText = L["OPT_AUTOSAVE_PARTY_WL_DESC"]
    cbAutoSaveWL:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.autoSavePartyWhitelist = self:GetChecked() and true or false
    end)
    mainPanel.cbAutoSaveWL = cbAutoSaveWL

    -- Checkbox: Guild Sync WL
    local cbSyncGuildWL = CreateFrame("CheckButton", "PGS_Opt_SyncGuildWL", mainPanel, "UICheckButtonTemplate")
    cbSyncGuildWL:SetPoint("TOPLEFT", cbAutoSaveWL, "BOTTOMLEFT", 0, -2)
    local cbSyncGuildWLLabel = cbSyncGuildWL:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbSyncGuildWLLabel:SetPoint("LEFT", cbSyncGuildWL, "RIGHT", 4, 0)
    cbSyncGuildWLLabel:SetText(L["OPT_SYNC_GUILD_WL"])
    cbSyncGuildWL.tooltipText = L["OPT_SYNC_GUILD_WL_DESC"]
    cbSyncGuildWL:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.syncGuildWhitelist = self:GetChecked() and true or false
        if addon.db.syncGuildWhitelist and IsInGuild() then
            addon:BroadcastWhitelist()
        end
    end)
    mainPanel.cbSyncGuildWL = cbSyncGuildWL

    -- Action Buttons (Width 152 to fit two side-by-side or stacked nicely)
    local btnOpenBL = CreateFrame("Button", nil, mainPanel, "UIPanelButtonTemplate")
    btnOpenBL:SetSize(152, 22)
    btnOpenBL:SetPoint("TOPLEFT", cbSyncGuildWL, "BOTTOMLEFT", 0, -6)
    btnOpenBL:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:14:14:0:0|t " .. (GetLocale() == "ruRU" and "Чёрный Список" or "Blacklist"))
    btnOpenBL:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ToggleBlacklistPanel("blacklist")
    end)

    local btnOpenWL = CreateFrame("Button", nil, mainPanel, "UIPanelButtonTemplate")
    btnOpenWL:SetSize(152, 22)
    btnOpenWL:SetPoint("LEFT", btnOpenBL, "RIGHT", 6, 0)
    btnOpenWL:SetText("|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0|t " .. (GetLocale() == "ruRU" and "Белый Список" or "Whitelist"))
    btnOpenWL:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ToggleWhitelistPanel()
    end)

    local btnImportBL = CreateFrame("Button", nil, mainPanel, "UIPanelButtonTemplate")
    btnImportBL:SetSize(152, 22)
    btnImportBL:SetPoint("TOPLEFT", btnOpenBL, "BOTTOMLEFT", 0, -4)
    btnImportBL:SetText("|TInterface\\Buttons\\UI-PlusButton-Up:14:14:0:0|t " .. (GetLocale() == "ruRU" and "Импорт ЧС" or "Import BL"))
    btnImportBL:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ImportPartyBlacklist()
    end)

    local btnImportWL = CreateFrame("Button", nil, mainPanel, "UIPanelButtonTemplate")
    btnImportWL:SetSize(152, 22)
    btnImportWL:SetPoint("LEFT", btnImportBL, "RIGHT", 6, 0)
    btnImportWL:SetText("|TInterface\\Buttons\\UI-PlusButton-Up:14:14:0:0|t " .. (GetLocale() == "ruRU" and "Импорт БС" or "Import WL"))
    btnImportWL:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ImportPartyWhitelist()
    end)

    -- Secret Button (Blizzard star icon, NO emoji, 100% no red question mark!)
    local btnSecret = CreateFrame("Button", "PGS_Opt_SecretBtn", mainPanel, "UIPanelButtonTemplate")
    btnSecret:SetSize(310, 24)
    btnSecret:SetPoint("TOPLEFT", btnImportBL, "BOTTOMLEFT", 0, -6)
    btnSecret:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:14:14:0:0|t |cffff80df[ " .. L["OPT_SECRET_BUTTON"] .. " ]|r")
    btnSecret:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ToggleSecretAnimePanel()
    end)
    btnSecret:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["OPT_SECRET_BUTTON"], 1, 0.5, 0.85)
        GameTooltip:AddLine(L["OPT_SECRET_DESC"], 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    btnSecret:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Section 3: Commands & Reset (Left Column)
    local sec3 = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sec3:SetPoint("TOPLEFT", btnSecret, "BOTTOMLEFT", 0, -10)
    sec3:SetText("|cffffd100" .. L["OPT_SECTION_COMMANDS"] .. "|r")

    local sep3 = mainPanel:CreateTexture(nil, "ARTWORK")
    sep3:SetSize(320, 1)
    sep3:SetPoint("TOPLEFT", sec3, "BOTTOMLEFT", 0, -4)
    sep3:SetColorTexture(0.35, 0.35, 0.4, 0.6)

    -- Laser-aligned 2-column command listing (zero wobble, perfect vertical columns)
    local cmdCol1 = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cmdCol1:SetPoint("TOPLEFT", sep3, "BOTTOMLEFT", 2, -6)
    cmdCol1:SetWidth(155)
    cmdCol1:SetJustifyH("LEFT")
    cmdCol1:SetText(
        "|cff00ccff/pgs|r - " .. (GetLocale() == "ruRU" and "Поиск групп (LFG)" or "LFG Search") .. "\n" ..
        "|cff00ccff/pgs bl|r - " .. (GetLocale() == "ruRU" and "Чёрный список" or "Blacklist") .. "\n" ..
        "|cff00ccff/pgs wl|r - " .. (GetLocale() == "ruRU" and "Белый список" or "Whitelist") .. "\n" ..
        "|cff00ccff/pgs secret|r - " .. (GetLocale() == "ruRU" and "Секретное меню" or "Secret menu")
    )

    local cmdCol2 = mainPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cmdCol2:SetPoint("TOPLEFT", sep3, "BOTTOMLEFT", 165, -6)
    cmdCol2:SetWidth(155)
    cmdCol2:SetJustifyH("LEFT")
    cmdCol2:SetText(
        "|cff00ccff/pgs opt|r - " .. (GetLocale() == "ruRU" and "Настройки" or "Options") .. "\n" ..
        "|cff00ccff/pgs bl add <Имя>|r\n" ..
        "|cff00ccff/pgs wl add <Имя>|r\n" ..
        "|cff00ccff/pgs bl import|r"
    )

    -- Reset Defaults Button (anchored directly relative to sep3 with safe offset, zero overlap!)
    local btnReset = CreateFrame("Button", nil, mainPanel, "UIPanelButtonTemplate")
    btnReset:SetSize(160, 22)
    btnReset:SetPoint("TOPLEFT", sep3, "BOTTOMLEFT", 0, -68)
    btnReset:SetText(L["OPT_RESET_SETTINGS"])
    btnReset:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ResetDefaults()
    end)

    --------------------------------------------------------------------
    -- Right Column: Quick Access Card
    --------------------------------------------------------------------
    local infoCard = CreateFrame("Frame", nil, mainPanel)
    infoCard:SetSize(235, 310)
    infoCard:SetPoint("TOPRIGHT", mainPanel, "TOPRIGHT", -16, -16)
    infoCard:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    infoCard:SetBackdropColor(0.06, 0.05, 0.10, 0.90)
    infoCard:SetBackdropBorderColor(0.5, 0.4, 0.6, 0.7)

    local infoTitle = infoCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoTitle:SetPoint("TOPLEFT", 12, -12)
    infoTitle:SetText("|TInterface\\Buttons\\UI-OptionsButton:14:14:0:0|t |cff00ccff" .. (GetLocale() == "ruRU" and "Быстрый доступ" or "Quick Access") .. "|r")

    local cardSep = infoCard:CreateTexture(nil, "ARTWORK")
    cardSep:SetHeight(1)
    cardSep:SetPoint("TOPLEFT", 10, -28)
    cardSep:SetPoint("TOPRIGHT", -10, -28)
    cardSep:SetColorTexture(0.4, 0.35, 0.5, 0.5)

    local infoText = infoCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoText:SetPoint("TOPLEFT", 12, -34)
    infoText:SetJustifyH("LEFT")
    infoText:SetWidth(215)
    if GetLocale() == "ruRU" then
        infoText:SetText(
            "|cffffd100Иконка миникарты:|r\n" ..
            "  • |cffffffffЛКМ:|r Настройки аддона\n" ..
            "  • |cffffffffПКМ:|r Чёрный список\n" ..
            "  • |cffffffffShift+ПКМ:|r Белый список\n" ..
            "  • |cffffffffShift+ЛКМ:|r Секретное меню\n" ..
            "  • |cff888888Перетаскивание по кругу|r\n\n" ..
            "|cffffd100Быстрый ЧС / БС:|r\n" ..
            "  • |cffffffffПКМ по игроку|r -> В ЧС (PGS)\n" ..
            "  • |cffffffffПКМ по игроку|r -> В БС (PGS)\n\n" ..
            "|cffffd100Защита PremadeGroupSort:|r\n" ..
            "  • Фильтрация руинеров в поиске\n" ..
            "  • Подсветка проверенных (Белый список)\n" ..
            "  • Защита от инвайта ливеров в пати\n" ..
            "  • Авто-обмен базой с гильдией"
        )
    else
        infoText:SetText(
            "|cffffd100Minimap Button:|r\n" ..
            "  • |cffffffffLeft-Click:|r Addon Settings\n" ..
            "  • |cffffffffRight-Click:|r Blacklist\n" ..
            "  • |cffffffffShift+R-Click:|r Whitelist\n" ..
            "  • |cffffffffShift+L-Click:|r Secret Menu\n" ..
            "  • |cff888888Drag to move around map|r\n\n" ..
            "|cffffd100Quick BL / WL:|r\n" ..
            "  • |cffffffffRight-Click player|r -> Add to BL (PGS)\n" ..
            "  • |cffffffffRight-Click player|r -> Add to WL (PGS)\n\n" ..
            "|cffffd100PremadeGroupSort Protection:|r\n" ..
            "  • Smart group filtering & badges\n" ..
            "  • Whitelist badges for trusted players\n" ..
            "  • Blacklist protection on invites\n" ..
            "  • Account & Guild sync"
        )
    end

    mainPanel.refresh = function()
        if addon.db then
            cbDungeonBar:SetChecked(addon.db.dungeonBarOpen ~= false)
            cbMythicOnly:SetChecked(addon.db.onlyMythicPlus == true)
            cbEngTitles:SetChecked(addon.db.englishKeystoneTitles ~= false)
            cbMinimap:SetChecked(addon.db.minimapIcon ~= false)
            cbAutoSave:SetChecked(addon.db.autoSavePartyBlacklist == true)
            cbSyncGuild:SetChecked(addon.db.syncGuildBlacklist == true)
            cbAutoSaveWL:SetChecked(addon.db.autoSavePartyWhitelist == true)
            cbSyncGuildWL:SetChecked(addon.db.syncGuildWhitelist == true)
            if mainPanel.mascotBg then
                mainPanel.mascotBg:SetShown(addon.db.soundAnimeArt ~= false)
            end
        end
    end
    mainPanel.default = function()
        addon:ResetDefaults()
    end

    InterfaceOptions_AddCategory(mainPanel)

    --------------------------------------------------------------------
    -- 2. Subpanel: "Чёрный список" (Blacklist)
    --------------------------------------------------------------------
    local blSubPanel = CreateFrame("Frame", "PremadeGroupSort_Options_Blacklist", UIParent)
    blSubPanel.name = (GetLocale() == "ruRU" and "Чёрный список" or "Blacklist")
    blSubPanel.parent = mainPanel.name
    addon.optionsBLPanel = blSubPanel

    local blTitle = blSubPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    blTitle:SetPoint("TOPLEFT", 16, -16)
    blTitle:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:18:18:0:0|t |cffffd100" .. L["BL_TITLE"] .. "|r")

    local blSubDesc = blSubPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    blSubDesc:SetPoint("TOPLEFT", blTitle, "BOTTOMLEFT", 0, -6)
    blSubDesc:SetText(GetLocale() == "ruRU" and "Список нежелательных игроков (аккаунт, альты, сопартийцы и гильдия)." or "List of blacklisted players across account, alts, party and guild.")

    -- Stats summary box
    local statsBox = CreateFrame("Frame", nil, blSubPanel)
    statsBox:SetSize(580, 50)
    statsBox:SetPoint("TOPLEFT", blSubDesc, "BOTTOMLEFT", 0, -10)
    statsBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    statsBox:SetBackdropColor(0.08, 0.08, 0.12, 0.8)
    statsBox:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.6)

    local statsTxt = statsBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statsTxt:SetPoint("LEFT", 10, 0)
    statsTxt:SetJustifyH("LEFT")
    blSubPanel.statsTxt = statsTxt

    -- Subpanel Action buttons
    local subOpenBtn = CreateFrame("Button", nil, blSubPanel, "UIPanelButtonTemplate")
    subOpenBtn:SetSize(220, 24)
    subOpenBtn:SetPoint("TOPLEFT", statsBox, "BOTTOMLEFT", 0, -10)
    subOpenBtn:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:14:14:0:0|t " .. L["OPT_OPEN_BL_WINDOW"])
    subOpenBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ToggleBlacklistPanel()
    end)

    local subImportBtn = CreateFrame("Button", nil, blSubPanel, "UIPanelButtonTemplate")
    subImportBtn:SetSize(200, 24)
    subImportBtn:SetPoint("LEFT", subOpenBtn, "RIGHT", 8, 0)
    subImportBtn:SetText("|TInterface\\Buttons\\UI-PlusButton-Up:14:14:0:0|t " .. L["OPT_IMPORT_PARTY_NOW"])
    subImportBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon:ImportPartyBlacklist()
        if blSubPanel.refresh then blSubPanel.refresh() end
    end)

    -- Subpanel Table Header Bar
    local subHeader = CreateFrame("Frame", nil, blSubPanel)
    subHeader:SetSize(524, 18)
    subHeader:SetPoint("TOPLEFT", subOpenBtn, "BOTTOMLEFT", 0, -10)

    local subHdrName = subHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subHdrName:SetPoint("LEFT", 22, 0)
    subHdrName:SetWidth(110)
    subHdrName:SetJustifyH("LEFT")
    subHdrName:SetText("|cffffd100" .. L["BL_COL_NAME"] .. "|r")

    local subHdrReason = subHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subHdrReason:SetPoint("LEFT", subHdrName, "RIGHT", 6, 0)
    subHdrReason:SetWidth(170)
    subHdrReason:SetJustifyH("LEFT")
    subHdrReason:SetText("|cffffd100" .. L["BL_COL_REASON"] .. "|r")

    local subHdrSource = subHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subHdrSource:SetPoint("LEFT", subHdrReason, "RIGHT", 6, 0)
    subHdrSource:SetWidth(95)
    subHdrSource:SetJustifyH("LEFT")
    subHdrSource:SetText("|cffffd100" .. L["BL_COL_SOURCE"] .. "|r")

    local subHdrDate = subHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subHdrDate:SetPoint("LEFT", subHdrSource, "RIGHT", 6, 0)
    subHdrDate:SetWidth(75)
    subHdrDate:SetJustifyH("CENTER")
    subHdrDate:SetText("|cffffd100" .. L["BL_COL_DATE"] .. "|r")

    -- Scrollable list inside subpanel (Virtual Scrolling)
    local blSubScroll = CreateFrame("ScrollFrame", "PremadeGroupSort_Opt_BLScroll", blSubPanel, "FauxScrollFrameTemplate")
    blSubScroll:SetPoint("TOPLEFT", subHeader, "BOTTOMLEFT", 0, -4)
    blSubScroll:SetPoint("BOTTOMRIGHT", -36, 16)
    blSubPanel.scrollFrame = blSubScroll

    local subRowContainer = CreateFrame("Frame", "PremadeGroupSort_Opt_BLRowContainer", blSubPanel)
    subRowContainer:SetPoint("TOPLEFT", subHeader, "BOTTOMLEFT", 0, -4)
    subRowContainer:SetPoint("BOTTOMRIGHT", -36, 16)
    subRowContainer:SetClipsChildren(true)
    blSubPanel.rowContainer = subRowContainer

    local SUB_NUM_ROWS = 11
    local SUB_ROW_HEIGHT = 24
    blSubPanel.NUM_ROWS = SUB_NUM_ROWS
    blSubPanel.ROW_HEIGHT = SUB_ROW_HEIGHT
    blSubPanel.rows = {}

    local function ScrollSubBlacklist(delta)
        if not blSubScroll then return end
        local scrollBar = _G["PremadeGroupSort_Opt_BLScrollScrollBar"] or blSubScroll.ScrollBar
        if not scrollBar then return end
        local cur = scrollBar:GetValue()
        local minV, maxV = scrollBar:GetMinMaxValues()
        if delta > 0 then
            scrollBar:SetValue(math.max(minV, cur - 24))
        else
            scrollBar:SetValue(math.min(maxV, cur + 24))
        end
    end

    local function UpdateSubBlacklistRows()
        if not blSubPanel or not blSubPanel.rows then return end
        local entries = blSubPanel.entries or {}
        local offset = FauxScrollFrame_GetOffset(blSubScroll)
        local numRows = blSubPanel.NUM_ROWS or 11

        for i = 1, numRows do
            local row = blSubPanel.rows[i]
            local idx = offset + i
            local item = entries[idx]
            if item then
                row.item = item
                row.entryName = item.name

                if (idx % 2) == 1 then
                    row.bg:SetColorTexture(0.12, 0.12, 0.16, 0.6)
                else
                    row.bg:SetColorTexture(0.07, 0.07, 0.10, 0.6)
                end

                row.nameTxt:SetText(item.name)

                local rDisp = item.reason or ""
                if string.len(rDisp) > 32 then
                    rDisp = string.sub(rDisp, 1, 30) .. ".."
                end
                row.rTxt:SetText("|cffff8080[" .. rDisp .. "]|r")

                if item.isSelf then
                    row.sTxt:SetText("|cffaaaaaa(" .. (item.addedBy or "Alt") .. ")|r")
                    row.delBtn:Show()
                elseif item.source == "guild" then
                    row.sTxt:SetText("|cff00ff00(" .. (item.addedBy or "Guild") .. ")|r")
                    row.delBtn:Hide()
                else
                    row.sTxt:SetText("|cff00ccff(" .. (item.addedBy or "Party") .. ")|r")
                    row.delBtn:Hide()
                end

                local dStr = "-"
                if item.timestamp and item.timestamp > 0 then
                    dStr = date("%d.%m.%y", item.timestamp)
                end
                row.dateTxt:SetText("|cffaaaaaa" .. dStr .. "|r")

                row:Show()
            else
                row.item = nil
                row.entryName = nil
                row:Hide()
            end
        end
    end

    for i = 1, SUB_NUM_ROWS do
        local row = CreateFrame("Frame", nil, subRowContainer)
        row:SetSize(524, SUB_ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, - (i - 1) * SUB_ROW_HEIGHT)

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(row)
        row.bg = bg

        local skull = row:CreateTexture(nil, "ARTWORK")
        skull:SetSize(14, 14)
        skull:SetPoint("LEFT", 4, 0)
        skull:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
        row.skull = skull

        local nameTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameTxt:SetPoint("LEFT", skull, "RIGHT", 4, 0)
        nameTxt:SetWidth(110)
        nameTxt:SetJustifyH("LEFT")
        row.nameTxt = nameTxt

        local rTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rTxt:SetPoint("LEFT", nameTxt, "RIGHT", 6, 0)
        rTxt:SetWidth(170)
        rTxt:SetJustifyH("LEFT")
        row.rTxt = rTxt

        local sTxt = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        sTxt:SetPoint("LEFT", rTxt, "RIGHT", 6, 0)
        sTxt:SetWidth(95)
        sTxt:SetJustifyH("LEFT")
        row.sTxt = sTxt

        local dateTxt = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        dateTxt:SetPoint("LEFT", sTxt, "RIGHT", 6, 0)
        dateTxt:SetWidth(75)
        dateTxt:SetJustifyH("CENTER")
        row.dateTxt = dateTxt

        local delBtn = CreateFrame("Button", nil, row)
        delBtn:SetSize(24, 18)
        delBtn:SetPoint("RIGHT", -4, 0)
        local delTxt = delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        delTxt:SetPoint("CENTER", 0, 0)
        delTxt:SetText("|cffff2020[X]|r")
        delBtn:SetScript("OnClick", function()
            if row.entryName then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                addon:RemoveBlacklist(row.entryName)
                if blSubPanel.refresh then blSubPanel.refresh() end
            end
        end)
        row.delBtn = delBtn

        row:EnableMouse(true)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(self, delta)
            ScrollSubBlacklist(delta)
        end)

        row:SetScript("OnEnter", function(self)
            if not self.item then return end
            local item = self.item
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16:0:0|t |cffff2020" .. (item.name or "") .. "|r", 1, 0.2, 0.2)
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_REASON"] .. ":|r", "|cffffffff" .. (item.reason or "") .. "|r", 1, 1, 1, 1, 1, 1)
            local byStr = (item.addedBy and item.addedBy ~= "") and item.addedBy or "Alt"
            if item.isSelf then
                GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_SOURCE"] .. ":|r", "|cffaaaaaa" .. L["BL_SOURCE_SELF"] .. " (" .. byStr .. ")|r", 1, 1, 1, 1, 1, 1)
            elseif item.source == "guild" then
                GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_SOURCE"] .. ":|r", "|cff00ff00Гильдия (" .. byStr .. ")|r", 1, 1, 1, 1, 1, 1)
            else
                GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_SOURCE"] .. ":|r", "|cff00ccffГруппа (" .. byStr .. ")|r", 1, 1, 1, 1, 1, 1)
            end
            if item.timestamp and item.timestamp > 0 then
                local fullDate = date("%d.%m.%Y в %H:%M", item.timestamp)
                GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_DATE"] .. ":|r", "|cffffffff" .. fullDate .. "|r", 1, 1, 1, 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        blSubPanel.rows[i] = row
    end

    blSubScroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, SUB_ROW_HEIGHT, function()
            GameTooltip:Hide()
            UpdateSubBlacklistRows()
        end)
    end)
    blSubScroll:EnableMouseWheel(true)
    blSubScroll:SetScript("OnMouseWheel", function(self, delta) ScrollSubBlacklist(delta) end)
    blSubPanel:EnableMouseWheel(true)
    blSubPanel:SetScript("OnMouseWheel", function(self, delta) ScrollSubBlacklist(delta) end)

    blSubPanel.refresh = function()
        if not blSubPanel:IsShown() then blSubPanel.pgsDirty = true; return end
        blSubPanel.pgsDirty = nil
        addon.perf.viewRefreshes = addon.perf.viewRefreshes + 1
        if blSubPanel.rawEntries then
            RecycleBLEntries(blSubPanel.rawEntries)
        else
            blSubPanel.rawEntries = {}
        end
        local entries = blSubPanel.rawEntries
        blSubPanel.entries = entries

        local selfCount = 0
        local partyCount = 0
        if addon.db and addon.db.blacklist then
            for key, info in pairs(addon.db.blacklist) do
                local e = AllocBLEntry()
                e.key = key
                e.name = info.name or key
                e.reason = info.reason or L["BL_DEFAULT_REASON"]
                e.addedBy = info.addedBy or UnitName("player")
                e.isSelf = true
                e.source = info.source or "manual"
                e.timestamp = info.timestamp or 0
                table.insert(entries, e)
                selfCount = selfCount + 1
            end
        end
        if addon.partyBlacklist then
            for memberName, memberBL in pairs(addon.partyBlacklist) do
                for key, info in pairs(memberBL) do
                    if not (addon.db.blacklist and addon.db.blacklist[key]) then
                        local e = AllocBLEntry()
                        e.key = key
                        e.name = info.name or key
                        e.reason = info.reason or L["BL_DEFAULT_REASON"]
                        e.addedBy = memberName
                        e.isSelf = false
                        e.source = "party"
                        e.timestamp = info.timestamp or 0
                        table.insert(entries, e)
                        partyCount = partyCount + 1
                    end
                end
            end
        end

        local seen = {}
        for _, entry in ipairs(entries) do seen[entry.key] = true end
        local guildCount = 0
        if addon.guildBlacklist then
            for memberName, memberBL in pairs(addon.guildBlacklist) do
                for key, info in pairs(memberBL) do
                    if not (addon.db.blacklist and addon.db.blacklist[key]) then
                        if not seen[key] then
                            seen[key] = true
                            local e = AllocBLEntry()
                            e.key = key
                            e.name = info.name or key
                            e.reason = info.reason or L["BL_DEFAULT_REASON"]
                            e.addedBy = memberName
                            e.isSelf = false
                            e.source = "guild"
                            e.timestamp = info.timestamp or 0
                            table.insert(entries, e)
                            guildCount = guildCount + 1
                        end
                    end
                end
            end
        end

        local total = #entries
        if statsTxt then
            local breakdown = string.format(L["OPT_STATS_SELF"], selfCount) .. "   |   " .. string.format(L["OPT_STATS_PARTY"], partyCount)
            if guildCount > 0 then
                breakdown = breakdown .. "   |   " .. (GetLocale() == "ruRU" and ("От гильдии: " .. guildCount) or ("From guild: " .. guildCount))
            end
            statsTxt:SetText(
                breakdown .. "\n" ..
                "|cffffd100" .. string.format(L["OPT_STATS_TOTAL"], total) .. "|r"
            )
        end

        table.sort(entries, function(a, b)
            if a.isSelf ~= b.isSelf then return a.isSelf end
            return (a.name or "") < (b.name or "")
        end)

        FauxScrollFrame_Update(blSubScroll, total, blSubPanel.NUM_ROWS, blSubPanel.ROW_HEIGHT)
        UpdateSubBlacklistRows()
    end

    blSubPanel:HookScript("OnShow", function() blSubPanel.refresh() end)
    InterfaceOptions_AddCategory(blSubPanel)

    --------------------------------------------------------------------
    -- 3. Subpanel: "Аниме Озвучка" (Anime Soundboard)
    --------------------------------------------------------------------
    local soundSubPanel = CreateFrame("Frame", "PremadeGroupSort_Options_Soundboard", UIParent)
    soundSubPanel.name = L["OPT_SOUNDBOARD_SUBPANEL"]
    soundSubPanel.parent = mainPanel.name
    addon.optionsSoundPanel = soundSubPanel

    local sbTitle = soundSubPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sbTitle:SetPoint("TOPLEFT", 16, -16)
    sbTitle:SetText("|TInterface\\AddOns\\PremadeGroupSort\\Textures\\anime_catgirl.tga:22:22:0:0|t |cffff80cc" .. L["OPT_SOUNDBOARD_TITLE"] .. "|r")

    local sbSub = soundSubPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sbSub:SetPoint("TOPLEFT", sbTitle, "BOTTOMLEFT", 0, -6)
    sbSub:SetText(L["OPT_SOUNDBOARD_DESC"])

    -- Big Featured Button: Hydro Dragon
    local btnHydro = CreateFrame("Button", nil, soundSubPanel, "UIPanelButtonTemplate")
    btnHydro:SetSize(300, 32)
    btnHydro:SetPoint("TOPLEFT", sbSub, "BOTTOMLEFT", 0, -12)
    btnHydro:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16:0:0|t |cff00ffffHydro Dragon|r (Neuvillette/Furina Meme)")
    btnHydro:SetScript("OnClick", function()
        addon:PlayAnimeSound("group_start", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\Hydro Dragon.mp3", true)
    end)

    -- Sound Volume Booster Slider in SubPanel
    local optVolSlider = CreateFrame("Slider", "PGS_Opt_SoundVolumeSlider", soundSubPanel, "OptionsSliderTemplate")
    optVolSlider:SetWidth(170)
    optVolSlider:SetHeight(16)
    optVolSlider:SetPoint("LEFT", btnHydro, "RIGHT", 30, -4)
    optVolSlider:SetMinMaxValues(25, 300)
    optVolSlider:SetValueStep(25)
    if optVolSlider.SetObeyStepOnDrag then
        optVolSlider:SetObeyStepOnDrag(true)
    end
    local optVolSliderText = _G["PGS_Opt_SoundVolumeSliderText"]
    local optVolSliderLow = _G["PGS_Opt_SoundVolumeSliderLow"]
    local optVolSliderHigh = _G["PGS_Opt_SoundVolumeSliderHigh"]
    if optVolSliderLow then optVolSliderLow:SetText("25%") end
    if optVolSliderHigh then optVolSliderHigh:SetText("300%") end
    local function updateOptVolText(val)
        if optVolSliderText then
            optVolSliderText:SetText(string.format("%s: |cff00ff00%d%%|r", L["OPT_SOUND_BOOST"], val))
        end
    end
    optVolSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor((value + 12.5) / 25) * 25
        if rounded < 25 then rounded = 25 end
        if rounded > 300 then rounded = 300 end
        if addon.db then addon.db.soundVolumeBoost = rounded end
        updateOptVolText(rounded)
    end)
    optVolSlider:SetScript("OnMouseUp", function()
        addon:PlayAnimeSound("login", nil, true)
    end)
    soundSubPanel.refresh = function()
        local boost = (addon.db and addon.db.soundVolumeBoost) or 100
        optVolSlider:SetValue(boost)
        updateOptVolText(boost)
    end

    -- Category 1: Login Greetings
    local catLogin = soundSubPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    catLogin:SetPoint("TOPLEFT", btnHydro, "BOTTOMLEFT", 0, -14)
    catLogin:SetText("|cffffd1001. " .. L["OPT_SOUND_LOGIN"] .. ":|r")

    local loginBtns = {
        {"Okaeri~ (Nyaa)", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\login_okaeri.mp3"},
        {"Konnichiwa!", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\login_konnichiwa.mp3"},
        {"Yahho~! (Let's go)", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\login_yahho.mp3"},
        {"Senpai!", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\login_senpai.mp3"},
    }
    for i, item in ipairs(loginBtns) do
        local b = CreateFrame("Button", nil, soundSubPanel, "UIPanelButtonTemplate")
        b:SetSize(138, 22)
        local col = (i - 1) % 4
        b:SetPoint("TOPLEFT", catLogin, "BOTTOMLEFT", col * 144, -4)
        b:SetText("> " .. item[1])
        b:SetScript("OnClick", function()
            addon:PlayAnimeSound("login", item[2], true)
        end)
    end

    -- Category 2: AFK Return
    local catAFK = soundSubPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    catAFK:SetPoint("TOPLEFT", catLogin, "BOTTOMLEFT", 0, -36)
    catAFK:SetText("|cffffd1002. " .. L["OPT_SOUND_AFK"] .. ":|r")

    local afkBtns = {
        {"Wake up! (Okita)", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\afk_wake_up.mp3"},
        {"Where were you?", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\afk_doko.mp3"},
        {"Ready! (Fwaa~)", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\afk_ready.mp3"},
        {"Break over! (Nya)", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\afk_nya.mp3"},
    }
    for i, item in ipairs(afkBtns) do
        local b = CreateFrame("Button", nil, soundSubPanel, "UIPanelButtonTemplate")
        b:SetSize(138, 22)
        local col = (i - 1) % 4
        b:SetPoint("TOPLEFT", catAFK, "BOTTOMLEFT", col * 144, -4)
        b:SetText("> " .. item[1])
        b:SetScript("OnClick", function()
            addon:PlayAnimeSound("afk_off", item[2], true)
        end)
    end

    -- Category 3: Group Recruitment / Formation
    local catGroup = soundSubPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    catGroup:SetPoint("TOPLEFT", catAFK, "BOTTOMLEFT", 0, -36)
    catGroup:SetText("|cffffd1003. " .. L["OPT_SOUND_GROUP"] .. ":|r")

    local groupBtns = {
        {"Ikuzo! (Recruit)", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\group_ikuzo.mp3"},
        {"Ganbare! (Let's go)", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\group_ganbare.mp3"},
        {"Syukko! (Ready)", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\group_syukko.mp3"},
        {"Wakuwaku! (Excited)", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\group_wakuwaku.mp3"},
    }
    for i, item in ipairs(groupBtns) do
        local b = CreateFrame("Button", nil, soundSubPanel, "UIPanelButtonTemplate")
        b:SetSize(138, 22)
        local col = (i - 1) % 4
        b:SetPoint("TOPLEFT", catGroup, "BOTTOMLEFT", col * 144, -4)
        b:SetText("> " .. item[1])
        b:SetScript("OnClick", function()
            addon:PlayAnimeSound("group_start", item[2], true)
        end)
    end

    -- Category 4: Warnings & Fun Lines
    local catFun = soundSubPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    catFun:SetPoint("TOPLEFT", catGroup, "BOTTOMLEFT", 0, -36)
    catFun:SetText("|cffffd1004. " .. (GetLocale() == "ruRU" and "Предупреждения и милые фразы" or "Alerts & Cute Voice Lines") .. ":|r")

    local funBtns = {
        {"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:14:14:0:0|t " .. (GetLocale() == "ruRU" and "ЧС Внимание!" or "BL Alert!"), "Interface\\AddOns\\PremadeGroupSort\\Sounds\\alert_blacklist.mp3"},
        {"Nyaan! Nyaa~", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_nya.mp3"},
        {"Ara Ara~", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_ara_ara.mp3"},
        {"Baka~! (Hentai)", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_baka.mp3"},
        {"Ganbatte! (Fight)", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_ganbatte.mp3"},
        {"Sugoi! (Master)", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_sugoi.mp3"},
        {"Arigatou! (Love)", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_arigato.mp3"},
    }
    for i, item in ipairs(funBtns) do
        local b = CreateFrame("Button", nil, soundSubPanel, "UIPanelButtonTemplate")
        b:SetSize(138, 22)
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        b:SetPoint("TOPLEFT", catFun, "BOTTOMLEFT", col * 144, -4 - (row * 26))
        b:SetText(item[1])
        b:SetScript("OnClick", function()
            addon:PlayAnimeSound("fun", item[2], true)
        end)
    end

    InterfaceOptions_AddCategory(soundSubPanel)
end

function addon:OpenOptions()
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
        InterfaceOptionsFrame:Hide()
    else
        InterfaceOptionsFrame_OpenToCategory("Premade Group Sort")
        InterfaceOptionsFrame_OpenToCategory("Premade Group Sort")
    end
end

------------------------------------------------------------------------
-- Secret Anime Voice & Mascot Frame
------------------------------------------------------------------------
local secretFrame = nil

function addon:CreateSecretAnimePanel()
    if secretFrame then return end

    secretFrame = CreateFrame("Frame", "PremadeGroupSort_SecretAnimeFrame", UIParent)
    secretFrame:SetSize(580, 545)
    secretFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    secretFrame:SetFrameStrata("DIALOG")
    secretFrame:EnableMouse(true)
    secretFrame:SetMovable(true)
    secretFrame:RegisterForDrag("LeftButton")
    secretFrame:SetScript("OnDragStart", secretFrame.StartMoving)
    secretFrame:SetScript("OnDragStop", secretFrame.StopMovingOrSizing)
    secretFrame:Hide()
    addon.secretFrame = secretFrame
    tinsert(UISpecialFrames, "PremadeGroupSort_SecretAnimeFrame")

    secretFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    secretFrame:SetBackdropColor(0.10, 0.06, 0.14, 0.98)

    -- Anime Catgirl Mascot Art Watermark (Full-frame background)
    local mascotArt = secretFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
    mascotArt:SetPoint("TOPLEFT", secretFrame, "TOPLEFT", 6, -6)
    mascotArt:SetPoint("BOTTOMRIGHT", secretFrame, "BOTTOMRIGHT", -6, 6)
    mascotArt:SetTexture("Interface\\AddOns\\PremadeGroupSort\\Textures\\anime_catgirl.tga")
    mascotArt:SetAlpha(0.20)
    secretFrame.mascotArt = mascotArt
    if addon.db and addon.db.soundAnimeArt == false then
        mascotArt:Hide()
    end

    -- Header Title
    local title = secretFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 16, -14)
    title:SetText("|TInterface\\AddOns\\PremadeGroupSort\\Textures\\anime_catgirl.tga:20:20:0:0|t |cffff80df" .. L["OPT_SECRET_TITLE"] .. "|r")

    -- Close Button [X]
    local closeBtn = CreateFrame("Button", nil, secretFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        secretFrame:Hide()
    end)

    local subTitle = secretFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subTitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subTitle:SetText("|cffaaaaaa" .. L["OPT_SOUND_ENABLE_DESC"] .. "|r")

    -- Separator 1
    local sep1 = secretFrame:CreateTexture(nil, "ARTWORK")
    sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT", 14, -48)
    sep1:SetPoint("TOPRIGHT", -14, -48)
    sep1:SetColorTexture(0.55, 0.25, 0.45, 0.6)

    -- Master Sound Checkbox
    local cbSoundEnable = CreateFrame("CheckButton", "PGS_Secret_SoundEnable", secretFrame, "UICheckButtonTemplate")
    cbSoundEnable:SetPoint("TOPLEFT", sep1, "BOTTOMLEFT", 0, -6)
    local cbSoundEnableLabel = cbSoundEnable:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbSoundEnableLabel:SetPoint("LEFT", cbSoundEnable, "RIGHT", 4, 0)
    cbSoundEnableLabel:SetText(L["OPT_SOUND_ENABLE"])
    cbSoundEnable.tooltipText = L["OPT_SOUND_ENABLE_DESC"]
    cbSoundEnable:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.soundEnabled = self:GetChecked() and true or false
    end)
    secretFrame.cbSoundEnable = cbSoundEnable

    -- Checkbox: Login Voice + Test Button
    local cbSoundLogin = CreateFrame("CheckButton", "PGS_Secret_SoundLogin", secretFrame, "UICheckButtonTemplate")
    cbSoundLogin:SetPoint("TOPLEFT", cbSoundEnable, "BOTTOMLEFT", 0, -4)
    local cbSoundLoginLabel = cbSoundLogin:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cbSoundLoginLabel:SetPoint("LEFT", cbSoundLogin, "RIGHT", 4, 0)
    cbSoundLoginLabel:SetText(L["OPT_SOUND_LOGIN"])
    cbSoundLogin.tooltipText = L["OPT_SOUND_LOGIN_DESC"]
    cbSoundLogin:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.soundLogin = self:GetChecked() and true or false
    end)
    secretFrame.cbSoundLogin = cbSoundLogin

    local btnTestLogin = CreateFrame("Button", nil, secretFrame, "UIPanelButtonTemplate")
    btnTestLogin:SetSize(52, 18)
    btnTestLogin:SetPoint("LEFT", cbSoundLoginLabel, "RIGHT", 8, 0)
    btnTestLogin:SetText("> " .. L["OPT_SOUND_TEST"])
    btnTestLogin:SetScript("OnClick", function()
        addon:PlayAnimeSound("login", nil, true)
    end)

    -- Checkbox: AFK Exit Voice + Test Button
    local cbSoundAFK = CreateFrame("CheckButton", "PGS_Secret_SoundAFK", secretFrame, "UICheckButtonTemplate")
    cbSoundAFK:SetPoint("TOPLEFT", cbSoundLogin, "BOTTOMLEFT", 0, -4)
    local cbSoundAFKLabel = cbSoundAFK:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cbSoundAFKLabel:SetPoint("LEFT", cbSoundAFK, "RIGHT", 4, 0)
    cbSoundAFKLabel:SetText(L["OPT_SOUND_AFK"])
    cbSoundAFK.tooltipText = L["OPT_SOUND_AFK_DESC"]
    cbSoundAFK:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.soundAFK = self:GetChecked() and true or false
    end)
    secretFrame.cbSoundAFK = cbSoundAFK

    local btnTestAFK = CreateFrame("Button", nil, secretFrame, "UIPanelButtonTemplate")
    btnTestAFK:SetSize(52, 18)
    btnTestAFK:SetPoint("LEFT", cbSoundAFKLabel, "RIGHT", 8, 0)
    btnTestAFK:SetText("> " .. L["OPT_SOUND_TEST"])
    btnTestAFK:SetScript("OnClick", function()
        addon:PlayAnimeSound("afk_off", nil, true)
    end)

    -- Checkbox: Group Start (Hydro Dragon) + Test Button
    local cbSoundGroup = CreateFrame("CheckButton", "PGS_Secret_SoundGroup", secretFrame, "UICheckButtonTemplate")
    cbSoundGroup:SetPoint("TOPLEFT", cbSoundAFK, "BOTTOMLEFT", 0, -4)
    local cbSoundGroupLabel = cbSoundGroup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cbSoundGroupLabel:SetPoint("LEFT", cbSoundGroup, "RIGHT", 4, 0)
    cbSoundGroupLabel:SetText(L["OPT_SOUND_GROUP"])
    cbSoundGroup.tooltipText = L["OPT_SOUND_GROUP_DESC"]
    cbSoundGroup:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.soundGroupStart = self:GetChecked() and true or false
    end)
    secretFrame.cbSoundGroup = cbSoundGroup

    local btnTestGroup = CreateFrame("Button", nil, secretFrame, "UIPanelButtonTemplate")
    btnTestGroup:SetSize(52, 18)
    btnTestGroup:SetPoint("LEFT", cbSoundGroupLabel, "RIGHT", 8, 0)
    btnTestGroup:SetText("> " .. L["OPT_SOUND_TEST"])
    btnTestGroup:SetScript("OnClick", function()
        addon:PlayAnimeSound("group_start", nil, true)
    end)

    -- Checkbox: Blacklist Applicant Warning + Test Button
    local cbSoundBL = CreateFrame("CheckButton", "PGS_Secret_SoundBL", secretFrame, "UICheckButtonTemplate")
    cbSoundBL:SetPoint("TOPLEFT", cbSoundGroup, "BOTTOMLEFT", 0, -4)
    local cbSoundBLLabel = cbSoundBL:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cbSoundBLLabel:SetPoint("LEFT", cbSoundBL, "RIGHT", 4, 0)
    cbSoundBLLabel:SetText(L["OPT_SOUND_BL"])
    cbSoundBLLabel.tooltipText = L["OPT_SOUND_BL_DESC"]
    cbSoundBL:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.soundBlacklistAlert = self:GetChecked() and true or false
    end)
    secretFrame.cbSoundBL = cbSoundBL

    local btnTestBL = CreateFrame("Button", nil, secretFrame, "UIPanelButtonTemplate")
    btnTestBL:SetSize(52, 18)
    btnTestBL:SetPoint("LEFT", cbSoundBLLabel, "RIGHT", 8, 0)
    btnTestBL:SetText("> " .. L["OPT_SOUND_TEST"])
    btnTestBL:SetScript("OnClick", function()
        addon:PlayAnimeSound("alert_bl", nil, true)
    end)

    -- Checkbox: Show Catgirl Mascot Art
    local cbAnimeArt = CreateFrame("CheckButton", "PGS_Secret_AnimeArt", secretFrame, "UICheckButtonTemplate")
    cbAnimeArt:SetPoint("TOPLEFT", cbSoundBL, "BOTTOMLEFT", 0, -4)
    local cbAnimeArtLabel = cbAnimeArt:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cbAnimeArtLabel:SetPoint("LEFT", cbAnimeArt, "RIGHT", 4, 0)
    cbAnimeArtLabel:SetText(L["OPT_ANIME_ART"])
    cbAnimeArt.tooltipText = L["OPT_ANIME_ART_DESC"]
    cbAnimeArt:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        addon.db.soundAnimeArt = self:GetChecked() and true or false
        if addon.optionsMainPanel and addon.optionsMainPanel.mascotBg then
            addon.optionsMainPanel.mascotBg:SetShown(addon.db.soundAnimeArt)
        end
        if addon.blMascotArt then
            addon.blMascotArt:SetShown(addon.db.soundAnimeArt)
        end
        if secretFrame and secretFrame.mascotArt then
            secretFrame.mascotArt:SetShown(addon.db.soundAnimeArt)
        end
    end)
    secretFrame.cbAnimeArt = cbAnimeArt

    -- Featured Button: Hydro Dragon
    local btnHydro = CreateFrame("Button", nil, secretFrame, "UIPanelButtonTemplate")
    btnHydro:SetSize(340, 24)
    btnHydro:SetPoint("TOPLEFT", cbAnimeArt, "BOTTOMLEFT", 0, -6)
    btnHydro:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:14:14:0:0|t |cff00ffffHydro Dragon|r (Neuvillette/Furina Meme)")
    btnHydro:SetScript("OnClick", function()
        addon:PlayAnimeSound("group_start", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\Hydro Dragon.mp3", true)
    end)

    -- Sound Volume Booster Slider (Increases ONLY anime sounds and songs)
    local volumeSlider = CreateFrame("Slider", "PGS_Secret_VolumeSlider", secretFrame, "OptionsSliderTemplate")
    volumeSlider:SetWidth(230)
    volumeSlider:SetHeight(17)
    volumeSlider:SetPoint("TOPLEFT", btnHydro, "BOTTOMLEFT", 6, -24)
    volumeSlider:SetMinMaxValues(25, 300)
    volumeSlider:SetValueStep(25)
    if volumeSlider.SetObeyStepOnDrag then
        volumeSlider:SetObeyStepOnDrag(true)
    end

    local sliderText = _G["PGS_Secret_VolumeSliderText"]
    local sliderLow = _G["PGS_Secret_VolumeSliderLow"]
    local sliderHigh = _G["PGS_Secret_VolumeSliderHigh"]

    if sliderText then
        sliderText:ClearAllPoints()
        sliderText:SetPoint("BOTTOMLEFT", volumeSlider, "TOPLEFT", 0, 4)
    end
    if sliderLow then
        sliderLow:ClearAllPoints()
        sliderLow:SetPoint("TOPLEFT", volumeSlider, "BOTTOMLEFT", 0, -3)
        sliderLow:SetText("25% (x0.25)")
    end
    if sliderHigh then
        sliderHigh:ClearAllPoints()
        sliderHigh:SetPoint("TOPRIGHT", volumeSlider, "BOTTOMRIGHT", 0, -3)
        sliderHigh:SetText("300% (x3.0)")
    end

    local function updateVolumeText(val)
        if sliderText then
            sliderText:SetText(string.format("%s: |cff00ff00%d%%|r (x%.2f)", L["OPT_SOUND_BOOST"], val, val / 100))
        end
    end

    volumeSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor((value + 12.5) / 25) * 25
        if rounded < 25 then rounded = 25 end
        if rounded > 300 then rounded = 300 end
        if addon.db then
            addon.db.soundVolumeBoost = rounded
        end
        updateVolumeText(rounded)
    end)

    volumeSlider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["OPT_SOUND_BOOST"], 1, 0.8, 0)
        GameTooltip:AddLine(L["OPT_SOUND_BOOST_DESC"], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    volumeSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local btnTestBoost = CreateFrame("Button", nil, secretFrame, "UIPanelButtonTemplate")
    btnTestBoost:SetSize(62, 20)
    btnTestBoost:SetPoint("LEFT", volumeSlider, "RIGHT", 16, 0)
    btnTestBoost:SetText("> " .. L["OPT_SOUND_TEST"])
    btnTestBoost:SetScript("OnClick", function()
        addon:PlayAnimeSound("login", nil, true)
    end)

    -- Separator 2 (placed cleanly below Volume Slider labels)
    local sep2 = secretFrame:CreateTexture(nil, "ARTWORK")
    sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT", 14, -358)
    sep2:SetPoint("TOPRIGHT", -14, -358)
    sep2:SetColorTexture(0.55, 0.25, 0.45, 0.6)

    -- Soundboard Section Header
    local sbHeader = secretFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sbHeader:SetPoint("TOPLEFT", sep2, "BOTTOMLEFT", 2, -8)
    sbHeader:SetText("|cffffd100" .. L["OPT_SOUNDBOARD_TITLE"] .. " (21):|r")

    -- 20 Compact Soundboard Buttons (4 columns x 5 rows)
    local allSounds = {
        -- Row 1: Login
        { "> Okaeri~", "login", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\login_okaeri.mp3" },
        { "> Konnichiwa", "login", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\login_konnichiwa.mp3" },
        { "> Yahho~!", "login", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\login_yahho.mp3" },
        { "> Senpai!", "login", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\login_senpai.mp3" },
        -- Row 2: AFK
        { "> Wake up!", "afk_off", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\afk_wake_up.mp3" },
        { "> Doko?", "afk_off", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\afk_doko.mp3" },
        { "> Ready!", "afk_off", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\afk_ready.mp3" },
        { "> Break over!", "afk_off", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\afk_nya.mp3" },
        -- Row 3: Group
        { "> Ikuzo!", "group_start", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\group_ikuzo.mp3" },
        { "> Ganbare!", "group_start", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\group_ganbare.mp3" },
        { "> Syukko!", "group_start", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\group_syukko.mp3" },
        { "> Wakuwaku!", "group_start", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\group_wakuwaku.mp3" },
        -- Row 4: Cute / Fun
        { "> Nyaan! Nyaa", "fun", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_nya.mp3" },
        { "> Ara Ara~", "fun", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_ara_ara.mp3" },
        { "> Baka~!", "fun", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_baka.mp3" },
        { "> Ganbatte!", "fun", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_ganbatte.mp3" },
        -- Row 5: Alerts & Extras
        { "> Sugoi!", "fun", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_sugoi.mp3" },
        { "> Arigatou!", "fun", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\fun_arigato.mp3" },
        { "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12:12:0:0|t " .. (GetLocale() == "ruRU" and "ЧС Тревога" or "BL Alert"), "alert_bl", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\alert_blacklist.mp3" },
        { "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12:12:0:0|t Hydro Meme", "group_start", "Interface\\AddOns\\PremadeGroupSort\\Sounds\\Hydro Dragon.mp3" },
    }

    for i, s in ipairs(allSounds) do
        local b = CreateFrame("Button", nil, secretFrame, "UIPanelButtonTemplate")
        b:SetSize(132, 22)
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        b:SetPoint("TOPLEFT", sbHeader, "BOTTOMLEFT", col * 138, -6 - (row * 24))
        b:SetText(s[1])
        b:SetScript("OnClick", function()
            addon:PlayAnimeSound(s[2], s[3], true)
        end)
    end

    secretFrame.refresh = function()
        if addon.db then
            cbSoundEnable:SetChecked(addon.db.soundEnabled == true)
            cbSoundLogin:SetChecked(addon.db.soundLogin == true)
            cbSoundAFK:SetChecked(addon.db.soundAFK == true)
            cbSoundGroup:SetChecked(addon.db.soundGroupStart == true)
            cbSoundBL:SetChecked(addon.db.soundBlacklistAlert == true)
            cbAnimeArt:SetChecked(addon.db.soundAnimeArt == true)
            local boost = (addon.db and addon.db.soundVolumeBoost) or 100
            volumeSlider:SetValue(boost)
            updateVolumeText(boost)
            if secretFrame.mascotArt then
                secretFrame.mascotArt:SetShown(addon.db.soundAnimeArt ~= false)
            end
        end
    end
end

function addon:ToggleSecretAnimePanel()
    if not secretFrame then
        addon:CreateSecretAnimePanel()
    end
    if secretFrame:IsShown() then
        secretFrame:Hide()
    else
        secretFrame:Show()
        if secretFrame.refresh then
            secretFrame.refresh()
        end
    end
end

------------------------------------------------------------------------
-- Minimap Button
------------------------------------------------------------------------
local minimapBtn = nil

function addon:CreateMinimapButton()
    if minimapBtn then return end

    minimapBtn = CreateFrame("Button", "PremadeGroupSort_MinimapButton", Minimap)
    minimapBtn:SetSize(31, 31)
    minimapBtn:SetFrameStrata("MEDIUM")
    minimapBtn:SetFrameLevel(8)
    minimapBtn:EnableMouse(true)
    minimapBtn:SetMovable(true)
    minimapBtn:RegisterForDrag("LeftButton")

    -- Background Texture
    local bg = minimapBtn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("TOPLEFT", 7, -5)

    -- Custom Catgirl Icon on ARTWORK layer (above background)
    local icon = minimapBtn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexture("Interface\\AddOns\\PremadeGroupSort\\Textures\\anime_catgirl.tga")
    minimapBtn.icon = icon

    -- Circular Minimap Border on OVERLAY layer
    local border = minimapBtn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Highlight Texture with ADD blend mode (glow without black background)
    minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local hl = minimapBtn:GetHighlightTexture()
    if hl then
        hl:SetBlendMode("ADD")
        hl:ClearAllPoints()
        hl:SetPoint("CENTER", 0, 0)
        hl:SetSize(31, 31)
    end

    local function RepositionMinimapButton()
        local pos = (addon.db and addon.db.minimapPos) or 215
        local angle = math.rad(pos)
        local x = math.cos(angle) * 80
        local y = math.sin(angle) * 80
        minimapBtn:ClearAllPoints()
        minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    minimapBtn:SetScript("OnDragStart", function(self)
        self.isDragging = true
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local deg = math.deg(math.atan2(cy - my, cx - mx))
            if deg < 0 then deg = deg + 360 end
            if addon.db then addon.db.minimapPos = deg end
            RepositionMinimapButton()
        end)
    end)

    minimapBtn:SetScript("OnDragStop", function(self)
        self.isDragging = false
        self:SetScript("OnUpdate", nil)
    end)

    minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    minimapBtn:SetScript("OnClick", function(self, button)
        if self.isDragging then return end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        if button == "LeftButton" then
            if IsShiftKeyDown() then
                if addon.ToggleSecretAnimePanel then
                    addon:ToggleSecretAnimePanel()
                end
            else
                addon:OpenOptions()
            end
        elseif button == "RightButton" then
            if IsShiftKeyDown() then
                if addon.ToggleWhitelistPanel then
                    addon:ToggleWhitelistPanel()
                end
            elseif IsAltKeyDown() then
                if addon.ToggleMainPanel then
                    addon:ToggleMainPanel()
                end
            else
                if addon.ToggleBlacklistPanel then
                    addon:ToggleBlacklistPanel("blacklist")
                end
            end
        end
    end)

    minimapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|TInterface\\AddOns\\PremadeGroupSort\\Textures\\anime_catgirl.tga:16:16:0:0|t |cff00ccffPremade Group Sort|r", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("|cffffffff" .. (GetLocale() == "ruRU" and "ЛКМ:" or "Left-Click:") .. "|r", (GetLocale() == "ruRU" and "Настройки аддона" or "Addon Settings"), 1, 0.82, 0, 1, 1, 1)
        GameTooltip:AddDoubleLine("|cffffffff" .. (GetLocale() == "ruRU" and "ПКМ:" or "Right-Click:") .. "|r", (GetLocale() == "ruRU" and "Чёрный список" or "Blacklist Manager"), 1, 0.82, 0, 1, 0.4, 0.4)
        GameTooltip:AddDoubleLine("|cffffffff" .. (GetLocale() == "ruRU" and "Shift+ПКМ:" or "Shift+Right-Click:") .. "|r", (GetLocale() == "ruRU" and "Белый список" or "Whitelist Manager"), 1, 0.82, 0, 0.4, 1, 0.4)
        GameTooltip:AddDoubleLine("|cffffffff" .. (GetLocale() == "ruRU" and "Shift+ЛКМ:" or "Shift+Left-Click:") .. "|r", (GetLocale() == "ruRU" and "Секретное меню" or "Secret Anime Menu"), 1, 0.82, 0, 1, 0.5, 0.85)
        GameTooltip:AddDoubleLine("|cffffffff" .. (GetLocale() == "ruRU" and "Alt+ПКМ:" or "Alt+Right-Click:") .. "|r", (GetLocale() == "ruRU" and "Поиск групп (LFG)" or "Toggle LFG Search"), 1, 0.82, 0, 0.5, 0.85, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff888888" .. (GetLocale() == "ruRU" and "Перетащите мышкой для перемещения" or "Drag to move around minimap") .. "|r", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)

    minimapBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    addon.minimapBtn = minimapBtn
    RepositionMinimapButton()
    minimapBtn:SetShown(addon.db and addon.db.minimapIcon ~= false)
end

------------------------------------------------------------------------
-- Quick Blacklist Hooks (Chat Shift+Click, Alt+Click, UnitPopupMenus)
------------------------------------------------------------------------
function addon:InitializeChatHooks()
    if addon.chatHooksInitialized then return end
    addon.chatHooksInitialized = true

    -- Hook chat links: Shift+Click into Blacklist input, Alt+Click anywhere
    hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
        if link and string.sub(link, 1, 6) == "player" then
            local rawName = string.match(link, "player:([^:]+)")
            if rawName and rawName ~= "" then
                rawName = string.gsub(rawName, "%-[^|]+", "")
                -- Shift+Click: if panel is open, paste name and focus reason
                if IsShiftKeyDown() and addon.blPanel and addon.blPanel:IsShown() then
                    if addon.blPanel.nameBox then
                        addon.blPanel.nameBox:SetText(rawName)
                        if addon.blPanel.reasonBox then
                            addon.blPanel.reasonBox:SetFocus()
                        end
                    end
                -- Alt+Click: open Blacklist panel anytime and fill name
                elseif IsAltKeyDown() and not IsControlKeyDown() then
                    if not (addon.blPanel and addon.blPanel:IsShown()) then
                        addon:ToggleBlacklistPanel("blacklist")
                    else
                        if addon.blPanel.SetActiveTab then addon.blPanel.SetActiveTab("blacklist") end
                    end
                    if addon.blPanel and addon.blPanel.nameBox then
                        addon.blPanel.nameBox:SetText(rawName)
                        if addon.blPanel.reasonBox then
                            addon.blPanel.reasonBox:SetFocus()
                        end
                    end
                -- Ctrl+Click: open Whitelist panel anytime and fill name
                elseif IsControlKeyDown() and not IsAltKeyDown() then
                    if not (addon.blPanel and addon.blPanel:IsShown()) then
                        addon:ToggleWhitelistPanel()
                    else
                        if addon.blPanel.SetActiveTab then addon.blPanel.SetActiveTab("whitelist") end
                    end
                    if addon.blPanel and addon.blPanel.nameBox then
                        addon.blPanel.nameBox:SetText(rawName)
                        if addon.blPanel.reasonBox then
                            addon.blPanel.reasonBox:SetFocus()
                        end
                    end
                end
            end
        end
    end)

    -- Hook Blizzard UnitPopupMenus (Right-click menu on player)
    if UnitPopupButtons and UnitPopupMenus then
        local function GetPopupTargetName()
            local dropdownFrame = UIDROPDOWNMENU_INIT_MENU
            if not dropdownFrame then return nil end
            local name = nil
            local unit = dropdownFrame.unit
            if unit and UnitExists(unit) then
                name = GetUnitName(unit, true)
            end
            if not name or name == "" then
                name = dropdownFrame.name
            end
            if not name or name == "" then
                name = dropdownFrame.chatTarget
            end
            if not name or name == "" then
                local server = dropdownFrame.server
                if server and server ~= "" and dropdownFrame.name then
                    name = dropdownFrame.name .. "-" .. server
                end
            end
            if (not name or name == "") and dropdownFrame.bnetIDAccount then
                local accountInfo = C_BattleNet and C_BattleNet.GetAccountInfoByID and C_BattleNet.GetAccountInfoByID(dropdownFrame.bnetIDAccount)
                if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.characterName then
                    name = accountInfo.gameAccountInfo.characterName
                end
            end
            if name and name ~= "" then
                return string.gsub(name, "%-[^|]+", "")
            end
            return nil
        end

        local function HandlePGSMenuClick(targetTab)
            local name = GetPopupTargetName()
            if not name or name == "" then return end
            if not (addon.blPanel and addon.blPanel:IsShown()) then
                addon:ToggleBlacklistPanel(targetTab)
            else
                if addon.blPanel.SetActiveTab then
                    addon.blPanel.SetActiveTab(targetTab)
                end
            end
            if addon.blPanel and addon.blPanel.nameBox then
                addon.blPanel.nameBox:SetText(name)
                if addon.blPanel.reasonBox then
                    addon.blPanel.reasonBox:SetFocus()
                end
            end
        end

        UnitPopupButtons["PGS_ADD_BLACKLIST"] = {
            text = "|cffff4040" .. (GetLocale() == "ruRU" and "В Чёрный список (PGS)" or "Add to Blacklist (PGS)") .. "|r",
            dist = 0,
            func = function() HandlePGSMenuClick("blacklist") end,
        }
        UnitPopupButtons["PGS_ADD_WHITELIST"] = {
            text = "|cff25ff25" .. (GetLocale() == "ruRU" and "В Белый список (PGS)" or "Add to Whitelist (PGS)") .. "|r",
            dist = 0,
            func = function() HandlePGSMenuClick("whitelist") end,
        }

        local popupTargetMenus = {
            "PLAYER",
            "PARTY",
            "RAID_PLAYER",
            "RAID",
            "TARGET",
            "FOCUS",
            "CHAT_ROSTER",
            "FRIEND",
            "FRIEND_OFFLINE",
            "BN_FRIEND",
            "GUILD",
            "GUILD_OFFLINE",
            "COMMUNITIES_GUILD_MEMBER",
        }

        local function AddButtonsToMenu(which)
            if not UnitPopupMenus[which] then return end
            -- Remove any previous insertions to prevent duplicate buttons
            for i = #UnitPopupMenus[which], 1, -1 do
                local val = UnitPopupMenus[which][i]
                if val == "PGS_ADD_BLACKLIST" or val == "PGS_ADD_WHITELIST" then
                    table.remove(UnitPopupMenus[which], i)
                end
            end
            -- Place right before CANCEL if present, else at the end
            local cancelIdx = nil
            for i, val in ipairs(UnitPopupMenus[which]) do
                if val == "CANCEL" then
                    cancelIdx = i
                    break
                end
            end
            if cancelIdx then
                table.insert(UnitPopupMenus[which], cancelIdx, "PGS_ADD_BLACKLIST")
                table.insert(UnitPopupMenus[which], cancelIdx + 1, "PGS_ADD_WHITELIST")
            else
                table.insert(UnitPopupMenus[which], "PGS_ADD_BLACKLIST")
                table.insert(UnitPopupMenus[which], "PGS_ADD_WHITELIST")
            end
        end

        for _, menuKey in ipairs(popupTargetMenus) do
            AddButtonsToMenu(menuKey)
        end

        -- In WoW 7.3.5 UnitPopup_OnClick executes the button's func or handles custom actions
        hooksecurefunc("UnitPopup_OnClick", function(self)
            local buttonVal = self.value
            if buttonVal == "PGS_ADD_BLACKLIST" then
                HandlePGSMenuClick("blacklist")
            elseif buttonVal == "PGS_ADD_WHITELIST" then
                HandlePGSMenuClick("whitelist")
            end
        end)
    end
end

------------------------------------------------------------------------
-- Initialize UI on Frame Show
------------------------------------------------------------------------
local function TryInitUI()
    if not addon:IsRuntimeReady() then return end
    if addon.uiInitialized then return end
    if LFGListFrame and LFGListFrame.SearchPanel then
        addon.uiInitialized = true
        addon:CreateToggleButton()
        addon:CreateDungeonBar()
        addon:CreateMainPanel()
        addon:CreateCreationPanel()
        addon:CreateBlacklistPanel()
        addon:CreateInterfaceOptions()

        -- Hook entry updates for badges and Blacklist
        if LFGListSearchEntry_Update then
            hooksecurefunc("LFGListSearchEntry_Update", function(btn)
                addon:EnhanceSearchEntry(btn)
            end)
        end

        -- Hook search entry mouseover tooltip to show time in LFG & Party Composition
        if LFGListSearchEntry_OnEnter then
            hooksecurefunc("LFGListSearchEntry_OnEnter", function(btn)
                if btn and btn.resultID then
                    local meta = addon:GetResultMeta(btn.resultID)
                    if meta and meta.age then
                        local ageText, ageColor = addon:FormatGroupAge(meta.age)
                        GameTooltip:AddDoubleLine(L["TOOLTIP_GROUP_AGE_LABEL"], ageColor .. ageText .. "|r", 1, 0.82, 0)
                    end

                    -- Group Composition Breakdown
                    local members = addon:GetSearchResultMembers(btn.resultID)
                    if members and #members > 0 then
                        GameTooltip:AddLine(" ")
                        local isRu = (GetLocale() == "ruRU")
                        GameTooltip:AddLine("|cffffd100" .. (isRu and "Состав группы" or "Group Composition") .. " (" .. #members .. "/5):|r")
                        for _, m in ipairs(members) do
                            local roleStr = ""
                            if m.role == "TANK" then
                                roleStr = "|cff00ccff[Танк]|r "
                            elseif m.role == "HEALER" then
                                roleStr = "|cff00ff00[Хил]|r "
                            elseif m.role == "DAMAGER" then
                                roleStr = "|cffff4040[ДД]|r "
                            else
                                roleStr = "|cffaaaaaa[-]|r "
                            end
                            local _, _, _, cHex = addon:GetClassColor(m.classFilename)
                            local cName = m.class
                            if m.specName and m.specName ~= "" then
                                cName = cName .. " (" .. m.specName .. ")"
                            end
                            GameTooltip:AddLine("  " .. roleStr .. "|c" .. cHex .. cName .. "|r")
                        end
                        if #members < 5 then
                            local freeSlots = 5 - #members
                            local freeStr = isRu and ("  |cff888888[Свободно: " .. freeSlots .. (freeSlots == 1 and " слот]" or " слота]") .. "|r") or ("  |cff888888[Open: " .. freeSlots .. (freeSlots == 1 and " slot]" or " slots]") .. "|r")
                            GameTooltip:AddLine(freeStr)
                        end
                    end
                    GameTooltip:Show()
                end
            end)
        end

        -- Hook applicant updates for Blacklist protection
        if LFGListApplicationViewer_UpdateApplicant then
            hooksecurefunc("LFGListApplicationViewer_UpdateApplicant", function(btn, id)
                addon:EnhanceApplicantButton(btn, id)
            end)
        end

        -- Hook applicant member mouseover tooltip for rich Blacklist info
        if LFGListApplicantMember_OnEnter then
            hooksecurefunc("LFGListApplicantMember_OnEnter", function(member)
                local applicantID = member:GetParent() and member:GetParent().applicantID
                local memberIdx = member.memberIdx
                if not applicantID or not memberIdx then return end
                local name = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)
                if name then
                    local bl = addon:GetBlacklistInfo(name)
                    if bl then
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16:0:0|t |cffff2020" .. L["BL_HEADER"] .. ": " .. name .. "|r", 1, 0.2, 0.2)
                        GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_REASON"] .. ":|r", "|cffffffff" .. (bl.reason or L["BL_DEFAULT_REASON"]) .. "|r", 1, 1, 1, 1, 1, 1)
                        local byStr = (bl.addedBy and bl.addedBy ~= "") and bl.addedBy or "Alt"
                        if bl.isSelf then
                            GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_SOURCE"] .. ":|r", "|cffaaaaaa" .. L["BL_SOURCE_SELF"] .. " (" .. byStr .. ")|r", 1, 1, 1, 1, 1, 1)
                        elseif bl.source == "guild" then
                            GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_SOURCE"] .. ":|r", "|cff00ff00Гильдия (" .. byStr .. ")|r", 1, 1, 1, 1, 1, 1)
                        else
                            GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_SOURCE"] .. ":|r", "|cff00ccffГруппа (" .. byStr .. ")|r", 1, 1, 1, 1, 1, 1)
                        end
                        if bl.timestamp and bl.timestamp > 0 then
                            local fullDate = date("%d.%m.%Y в %H:%M", bl.timestamp)
                            GameTooltip:AddDoubleLine("|cffffd100" .. L["BL_COL_DATE"] .. ":|r", "|cffffffff" .. fullDate .. "|r", 1, 1, 1, 1, 1, 1)
                        end
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("|cffff4040" .. L["BL_INVITE_BLOCKED_TOOLTIP"] .. "|r", 1, 0.4, 0.4, true)
                        GameTooltip:Show()
                    end
                end
            end)
        end

        -- Hook SearchPanel show/hide so panels only appear when viewing dungeon search results
        LFGListFrame.SearchPanel:HookScript("OnShow", function()
            addon:UpdatePanelVisibility()
        end)
        LFGListFrame.SearchPanel:HookScript("OnHide", function()
            addon:UpdatePanelVisibility()
        end)

        -- Update panel visibility on CategorySelection show
        if LFGListFrame.CategorySelection then
            LFGListFrame.CategorySelection:HookScript("OnShow", function(self)
                addon:UpdatePanelVisibility()
            end)
        end

        if LFGListFrame.EntryCreation then
            LFGListFrame.EntryCreation:HookScript("OnShow", function()
                addon:UpdatePanelVisibility()
            end)
            LFGListFrame.EntryCreation:HookScript("OnHide", function()
                addon:UpdatePanelVisibility()
            end)
        end

        if LFGListFrame.ApplicationViewer then
            LFGListFrame.ApplicationViewer:HookScript("OnShow", function()
                addon:UpdatePanelVisibility()
            end)
        end

        LFGListFrame:HookScript("OnHide", function()
            addon:UpdatePanelVisibility()
        end)

        if LFGListSearchPanel_DoSearch then
            hooksecurefunc("LFGListSearchPanel_DoSearch", function(self, categoryID)
                addon:UpdatePanelVisibility()
            end)
        end

        addon:UpdatePanelVisibility()
    end
end

local uiInitFrame = CreateFrame("Frame")
uiInitFrame:RegisterEvent("ADDON_LOADED")
uiInitFrame:RegisterEvent("PLAYER_LOGIN")

uiInitFrame:SetScript("OnEvent", function(self, event, arg1)
    if not addon:IsRuntimeReady() then return end
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            addon:CreateInterfaceOptions()
        end
        if arg1 == ADDON_NAME or arg1 == "Blizzard_LookingForGroupUI" or arg1 == "Blizzard_LFGList" then
            TryInitUI()
        end
    elseif event == "PLAYER_LOGIN" then
        addon:CreateInterfaceOptions()
        TryInitUI()
        addon:CreateMinimapButton()
        addon:InitializeChatHooks()
        if PVEFrame then
            PVEFrame:HookScript("OnShow", TryInitUI)
        end
    end
end)
