-- PremadeGroupSort Localization
local ADDON_NAME, addon = ...

local L = {}
addon.L = L

-- Default English strings
L["ADDON_TITLE"] = "Premade Group Sort"
L["HEADER_TITLE"] = "Sort & Filter"
L["RESET_BUTTON"] = "Reset"
L["RESET_TOOLTIP"] = "Reset all filters and sorting to defaults"
L["TOGGLE_BUTTON_TOOLTIP"] = "Toggle Premade Group Sort panel"

-- Dungeon Bar
L["DUNGEON_BAR_TITLE"] = "Dungeons"
L["DUNGEON_BAR_ALL"] = "ALL"
L["TOOLTIP_CLICK_DUNGEON"] = "Click to filter by this dungeon"
L["TOOLTIP_DUNGEON_SELECTED"] = "|cff00ff00[Selected]|r Click again to show all dungeons"
L["TOGGLE_FILTERS_PANEL"] = "Toggle extended filters (roles, keys, sorting)"

-- Dungeon filter
L["FILTER_DUNGEON"] = "Dungeon:"
L["ALL_DUNGEONS"] = "All Dungeons"
L["ONLY_MYTHIC_PLUS"] = "Mythic Keystones (M+) only"
L["ONLY_MYTHIC_PLUS_TOOLTIP"] = "Hide regular mythic (M0), heroic, normal, and quest groups"

-- Key range
L["KEY_LEVEL_HEADER"] = "Keystone Level:"
L["KEY_FROM"] = "Min:"
L["KEY_TO"] = "Max:"
L["KEY_ALL"] = "All"

-- Role filter
L["ROLES_NEEDED_HEADER"] = "Roles Needed:"
L["NEED_TANK"] = "Need Tank"
L["NEED_TANK_TOOLTIP"] = "Only show groups that have NO tank (0/1)"
L["NEED_HEALER"] = "Need Healer"
L["NEED_HEALER_TOOLTIP"] = "Only show groups that have NO healer (0/1)"
L["NEED_DPS"] = "Need DPS"
L["NEED_DPS_TOOLTIP"] = "Only show groups that need DPS (< 3/3)"

L["ROLES_HAVE_HEADER"] = "Roles Present:"
L["HAS_TANK"] = "Has Tank"
L["HAS_TANK_TOOLTIP"] = "Only show groups that already have a tank (1/1)"
L["HAS_HEALER"] = "Has Healer"
L["HAS_HEALER_TOOLTIP"] = "Only show groups that already have a healer (1/1)"

L["FIT_MY_ROLE"] = "Fits my current role"
L["FIT_MY_ROLE_TOOLTIP"] = "Only show groups that have an open slot for your current spec (Tank, Healer, or DPS)"

-- Group age filter
L["HIDE_OLD_GROUPS"] = "Hide old groups (>)"
L["HIDE_OLD_GROUPS_TOOLTIP"] = "Hide groups that have been listed in LFG longer than the selected time limit (filters out abandoned or forgotten listings)"
L["GROUP_AGE_SECTION"] = "Group Age Filter:"
L["GROUP_AGE_LABEL"] = "Older than %s"
L["GROUP_AGE_15M"] = "Older than 15 min"
L["GROUP_AGE_30M"] = "Older than 30 min (rec.)"
L["GROUP_AGE_45M"] = "Older than 45 min"
L["GROUP_AGE_60M"] = "Older than 1 hour"
L["GROUP_AGE_90M"] = "Older than 1.5 hours"
L["GROUP_AGE_120M"] = "Older than 2 hours"
L["TOOLTIP_GROUP_AGE_LABEL"] = "Time in LFG:"

-- Sorting
L["SORT_HEADER"] = "Sort By:"
L["SORT_KEY_DESC"] = "Key Level (High -> Low)"
L["SORT_KEY_ASC"] = "Key Level (Low -> High)"
L["SORT_DUNGEON_ASC"] = "Dungeon Name (A-Z)"
L["SORT_ROLE_TANK"] = "Needs Tank first"
L["SORT_ROLE_HEAL"] = "Needs Healer first"
L["SORT_ROLE_DPS"] = "Needs DPS first"
L["SORT_SLOTS_DESC"] = "Most full groups (4/5 first)"
L["SORT_TIME_DESC"] = "Newest groups first"
L["SORT_ILVL_DESC"] = "Required item level (High -> Low)"
L["SORT_DEFAULT"] = "Blizzard Default"

-- Results status
L["RESULTS_STATUS"] = "Showing: %d / %d"
L["RESULTS_STATUS_NO_FILTER"] = "Total groups: %d"

-- Legion Dungeons (English)
L["DUNGEONS"] = {
    [1] = "Black Rook Hold",
    [2] = "Cathedral of Eternal Night",
    [3] = "Court of Stars",
    [4] = "Darkheart Thicket",
    [5] = "Eye of Azshara",
    [6] = "Halls of Valor",
    [7] = "Maw of Souls",
    [8] = "Neltharion's Lair",
    [9] = "Return to Karazhan: Lower",
    [10] = "Return to Karazhan: Upper",
    [11] = "Seat of the Triumvirate",
    [12] = "The Arcway",
    [13] = "Vault of the Wardens",
}

-- Multi-select Tooltips (English)
L["TOOLTIP_CLICK_DUNGEON_SINGLE"] = "Left Click: Filter by this dungeon only"
L["TOOLTIP_SHIFT_CLICK_MULTI"] = "Shift + Left Click: Add/remove from multi-selection"
L["TOOLTIP_MULTI_SELECTED"] = "|cff00ff00[Selected in Multi-Filter]|r Shift-Click to remove"
L["MULTI_DUNGEONS_SELECTED"] = "%d dungeons selected"

-- Quick Keystone Creator (English)
L["QUICK_CREATOR_TITLE"] = "Quick Keystone Setup"
L["QUICK_CREATOR_MY_KEY"] = "My Key"
L["QUICK_CREATOR_NO_KEY"] = "No Key in Bags"
L["QUICK_CREATOR_LEVEL"] = "Key Level:"
L["QUICK_CREATOR_DUNGEON"] = "Dungeon:"
L["QUICK_CREATOR_TAGS"] = "Quick Tags:"
L["QUICK_CREATOR_APPLY"] = "Apply to Listing"
L["QUICK_CREATOR_CLEAR"] = "Clear"
L["PARTY_KEYS_HEADER"] = "Party Keystones:"
L["YOU"] = "You"
L["TAG_CHESTS"] = "[+2/3]"
L["TAG_FAST"] = "[Fast]"
L["TAG_PUSH"] = "[Push]"
L["TAG_WEEKLY"] = "[Weekly]"
L["TAG_CHILL"] = "[Chill]"
L["TAG_EXP"] = "[Big Exp]"

-- Blacklist Protection (English)
L["BL_TITLE"] = "Blacklist Protection"
L["BL_HEADER"] = "Blacklist"
L["BL_BUTTON"] = "Blacklist"
L["BL_BUTTON_TOOLTIP"] = "Open Account & Party Blacklist Manager"
L["BL_BADGE_APPLICANT"] = "[Blacklisted: %s]"
L["BL_BADGE_LEADER"] = "[Leader in Blacklist]"
L["BL_DEFAULT_REASON"] = "Blacklisted player"
L["BL_REASON_WOW_IGNORE"] = "WoW Ignore List"
L["BL_SOURCE_SELF"] = "You / Your Alt"
L["BL_SOURCE_PARTY"] = "Party Member: %s"
L["BL_INVITE_BLOCKED_TOOLTIP"] = "Player is blacklisted! Invite button is blocked to prevent accidental invites."
L["BL_LEADER_BLOCKED_TOOLTIP"] = "The leader of this group is in your blacklist! Reason: %s (Added by: %s)"
L["BL_ADD_TITLE"] = "Add to Blacklist"
L["BL_NAME_HINT"] = "Player Name"
L["BL_REASON_HINT"] = "Reason (Leaver, Toxic, etc.)"
L["BL_ADD_BUTTON"] = "Add"
L["BL_EMPTY_LIST"] = "Blacklist is empty."
L["BL_COUNT_LABEL"] = "Total in Blacklist: %d players"
L["BL_DELETE_TOOLTIP"] = "Click to remove from Blacklist"
L["BL_ADDED_NOTIFY"] = "Added %s to Blacklist."
L["BL_REMOVED_NOTIFY"] = "Removed %s from Blacklist."
L["BL_AUTOSAVE_CHECKBOX"] = "Auto-save party blacklist permanently"
L["BL_AUTOSAVE_TOOLTIP"] = "When enabled, any blacklist entries received from party members will be permanently saved to your account database."
L["BL_IMPORT_BUTTON"] = "Import Party BL"
L["BL_IMPORT_TOOLTIP"] = "Import all blacklist entries from current party members into your permanent account blacklist."
L["BL_IMPORT_SUCCESS"] = "Imported %d entries from party blacklist into your permanent list."
L["BL_IMPORT_NO_DATA"] = "No new party blacklist entries to import."
L["BL_SEARCH_HINT"] = "Search nickname or reason..."
L["BL_COL_NAME"] = "Player"
L["BL_COL_REASON"] = "Reason"
L["BL_COL_SOURCE"] = "Source"
L["BL_COL_DATE"] = "Date Added"
L["BL_FOUND_COUNT"] = "Found: %d of %d"
L["BL_BADGE_IN_BL"] = "In Blacklist"
L["BL_CONFIRM_TITLE"] = "WARNING!"
L["BL_CONFIRM_INVITE_TEXT"] = "Player %s is in Blacklist:\n\"%s\"\n\nAre you sure you want to invite them to the group?"

-- Whitelist (English)
L["WL_TITLE"] = "Whitelist Protection"
L["WL_HEADER"] = "Whitelist"
L["WL_BUTTON"] = "Whitelist"
L["WL_BUTTON_TOOLTIP"] = "Open Whitelist Manager"
L["WL_BADGE_APPLICANT"] = "[Whitelisted: %s]"
L["WL_BADGE_LEADER"] = "[Leader in Whitelist]"
L["WL_DEFAULT_NOTE"] = "Trusted player"
L["WL_ADD_TITLE"] = "Add to Whitelist"
L["WL_NOTE_HINT"] = "Note (Top Tank, Good DPS, Pro...)"
L["WL_ADD_BUTTON"] = "Add"
L["WL_EMPTY_LIST"] = "Whitelist is empty."
L["WL_COUNT_LABEL"] = "Total in Whitelist: %d players"
L["WL_DELETE_TOOLTIP"] = "Click to remove from Whitelist"
L["WL_ADDED_NOTIFY"] = "Added %s to Whitelist."
L["WL_REMOVED_NOTIFY"] = "Removed %s from Whitelist."
L["WL_AUTOSAVE_CHECKBOX"] = "Auto-save party whitelist permanently"
L["WL_AUTOSAVE_TOOLTIP"] = "When enabled, any whitelist entries received from party members will be permanently saved to your account database."
L["WL_IMPORT_BUTTON"] = "Import Party WL"
L["WL_IMPORT_TOOLTIP"] = "Import all whitelist entries from current party members into your permanent account whitelist."
L["WL_IMPORT_SUCCESS"] = "Imported %d entries from party whitelist into your permanent list."
L["WL_IMPORT_NO_DATA"] = "No new party whitelist entries to import."
L["WL_SEARCH_HINT"] = "Search nickname or note..."
L["WL_COL_NAME"] = "Player"
L["WL_COL_NOTE"] = "Note"
L["WL_COL_SOURCE"] = "Source"
L["WL_COL_DATE"] = "Date Added"
L["WL_BADGE_IN_WL"] = "Whitelisted"
L["WL_APPLICANT_TOOLTIP"] = "Trusted player from your Whitelist!"
L["TAB_BLACKLIST"] = "Blacklist"
L["TAB_WHITELIST"] = "Whitelist"

-- Interface Options (English)
L["OPT_TITLE"] = "Premade Group Sort"
L["OPT_SUBTITLE"] = "Mythic+ group filters, quick keystone creator & intelligent blacklist protection."
L["OPT_CATEGORY_GENERAL"] = "General Settings"
L["OPT_CATEGORY_BLACKLIST"] = "Blacklist & Sync"
L["OPT_DUNGEON_BAR"] = "Show Legion Dungeons bar in LFG search"
L["OPT_DUNGEON_BAR_DESC"] = "Displays quick 1-click icon bar for all 13 Legion dungeons at the top of LFG search."
L["OPT_MYTHIC_ONLY"] = "Filter Mythic+ (Keystones) only by default"
L["OPT_MYTHIC_ONLY_DESC"] = "Automatically hides normal, heroic, mythic 0 and quest groups when searching."
L["OPT_ENG_TITLES"] = "Use English keystone titles in group creator (+15 DHT)"
L["OPT_ENG_TITLES_DESC"] = "Ensures group listing titles are formed with standard English dungeon names."
L["OPT_AUTOSAVE_PARTY"] = "Auto-save party blacklist permanently"
L["OPT_AUTOSAVE_PARTY_DESC"] = "Automatically saves blacklisted players received from party members to your permanent account database."
L["OPT_SYNC_GUILD"] = "Sync blacklist with guild members (GUILD)"
L["OPT_SYNC_GUILD_DESC"] = "Automatically exchanges blacklist entries with online guild members who have the addon."
L["OPT_AUTOSAVE_PARTY_WL"] = "Auto-save party whitelist permanently"
L["OPT_AUTOSAVE_PARTY_WL_DESC"] = "Automatically saves whitelisted players received from party members to your permanent account database."
L["OPT_SYNC_GUILD_WL"] = "Sync whitelist with guild members (GUILD)"
L["OPT_SYNC_GUILD_WL_DESC"] = "Automatically exchanges whitelist entries with online guild members who have the addon."
L["OPT_SECTION_INFO"] = "Database & Statistics"
L["OPT_STATS_SELF"] = "Personal blacklist entries (Account): %d"
L["OPT_STATS_PARTY"] = "Entries received from current party: %d"
L["OPT_STATS_TOTAL"] = "Total protected players: %d"
L["OPT_SECTION_COMMANDS"] = "Slash Commands"
L["OPT_OPEN_BL_WINDOW"] = "Open Blacklist Window"
L["OPT_OPEN_WL_WINDOW"] = "Open Whitelist Window"
L["OPT_IMPORT_PARTY_NOW"] = "Import Party BL Now"
L["OPT_IMPORT_PARTY_WL_NOW"] = "Import Party WL Now"
L["OPT_RESET_SETTINGS"] = "Reset to Defaults"
L["OPT_RESET_CONFIRM"] = "All PremadeGroupSort settings have been reset to default."

-- Anime Audio & Mascot Art (English)
L["OPT_CATEGORY_ANIME"] = "Anime Voices & Mascot Art"
L["OPT_SOUND_ENABLE"] = "Enable Anime Voices"
L["OPT_SOUND_ENABLE_DESC"] = "Play cute anime voice lines and audio effects on key game events."
L["OPT_SOUND_LOGIN"] = "Character Login Greeting"
L["OPT_SOUND_LOGIN_DESC"] = "Play welcoming anime voice lines when logging onto character / entering world."
L["OPT_SOUND_AFK"] = "Return from AFK"
L["OPT_SOUND_AFK_DESC"] = "Play cute voice lines when returning from AFK status."
L["OPT_SOUND_GROUP"] = "Group Formation / Listing"
L["OPT_SOUND_GROUP_DESC"] = "Play an anime line or Hydro Dragon when starting group recruitment."
L["OPT_SOUND_BL"] = "Blacklist Applicant Warning"
L["OPT_SOUND_BL_DESC"] = "Play voice warning when a blacklisted applicant applies to your group."
L["OPT_ANIME_ART"] = "Show Catgirl Mascot Art"
L["OPT_ANIME_ART_DESC"] = "Display the anime catgirl artwork in settings and blacklist windows."
L["OPT_SOUND_TEST"] = "Test"
L["OPT_SOUND_TEST_TOOLTIP"] = "Click to play an audio sample from this category."
L["OPT_SOUND_BOOST"] = "Sound Volume Boost"
L["OPT_SOUND_BOOST_DESC"] = "Boost the playback volume of anime voice lines and songs independently from game sounds."
L["OPT_SOUNDBOARD_SUBPANEL"] = "Anime Soundboard"
L["OPT_SOUNDBOARD_TITLE"] = "Anime Voice Lines & Soundboard"
L["OPT_SOUNDBOARD_DESC"] = "Test and enjoy all anime voice lines, catgirl sounds, and Hydro Dragon."
L["OPT_SECRET_BUTTON"] = "Secret Button (DO NOT PRESS!)"
L["OPT_SECRET_DESC"] = "Are you sure? Inside lies secret anime voices and catgirl mascot settings..."
L["OPT_SECRET_TITLE"] = "Secret Menu: Anime Voices & Catgirl Mascot"
L["OPT_MINIMAP_ICON"] = "Show Minimap Button"
L["OPT_MINIMAP_ICON_DESC"] = "Displays a convenient circular button near the minimap for 1-click access."
L["BL_CHAT_HINT"] = "Tip: Right-click player name in chat or unit frame -> 'Add to BL (PGS)'"

-- Russian Localization
if GetLocale() == "ruRU" then
    L["ADDON_TITLE"] = "Сортировка Премейд Групп"
    L["HEADER_TITLE"] = "Сортировка и Фильтр"
    L["RESET_BUTTON"] = "Сброс"
    L["RESET_TOOLTIP"] = "Сбросить все фильтры и сортировку по умолчанию"
    L["TOGGLE_BUTTON_TOOLTIP"] = "Открыть/закрыть панель сортировки и фильтра групп"

    -- Dungeon Bar
    L["DUNGEON_BAR_TITLE"] = "Данжи"
    L["DUNGEON_BAR_ALL"] = "ВСЕ"
    L["TOOLTIP_CLICK_DUNGEON"] = "Клик: показать только этот данж"
    L["TOOLTIP_DUNGEON_SELECTED"] = "|cff00ff00[Выбран]|r Клик для показа всех данжей"
    L["TOGGLE_FILTERS_PANEL"] = "Расширенные фильтры (роли, ключи, сортировка)"

    -- Dungeon filter
    L["FILTER_DUNGEON"] = "Подземелье:"
    L["ALL_DUNGEONS"] = "Все подземелья"
    L["ONLY_MYTHIC_PLUS"] = "Только эпохальные ключи (M+)"
    L["ONLY_MYTHIC_PLUS_TOOLTIP"] = "Скрыть обычные, героические, мифик 0 группы и квесты"

    -- Key range
    L["KEY_LEVEL_HEADER"] = "Уровень ключа:"
    L["KEY_FROM"] = "От:"
    L["KEY_TO"] = "До:"
    L["KEY_ALL"] = "Все"

    -- Role filter
    L["ROLES_NEEDED_HEADER"] = "Требуется в группу:"
    L["NEED_TANK"] = "Нужен Танк"
    L["NEED_TANK_TOOLTIP"] = "Показывать только группы, где НЕТ танка (0/1)"
    L["NEED_HEALER"] = "Нужен Хил"
    L["NEED_HEALER_TOOLTIP"] = "Показывать только группы, где НЕТ хила (0/1)"
    L["NEED_DPS"] = "Нужен ДД"
    L["NEED_DPS_TOOLTIP"] = "Показывать только группы, где нужны бойцы (менее 3/3)"

    L["ROLES_HAVE_HEADER"] = "Уже есть в группе:"
    L["HAS_TANK"] = "Есть Танк"
    L["HAS_TANK_TOOLTIP"] = "Показывать группы, где уже есть танк (1/1)"
    L["HAS_HEALER"] = "Есть Хил"
    L["HAS_HEALER_TOOLTIP"] = "Показывать группы, где уже есть хил (1/1)"

    L["FIT_MY_ROLE"] = "Подходит моей роли"
    L["FIT_MY_ROLE_TOOLTIP"] = "Показывать только группы со свободным местом для вашей текущей роли (Танк, Хил или ДД)"

    -- Group age filter
    L["HIDE_OLD_GROUPS"] = "Скрыть старые группы (>)"
    L["HIDE_OLD_GROUPS_TOOLTIP"] = "Скрывать группы, которые висят в поиске дольше указанного времени (помогает отсеять забытые и неактивные сборы)"
    L["GROUP_AGE_SECTION"] = "Возраст группы:"
    L["GROUP_AGE_LABEL"] = "Старше %s"
    L["GROUP_AGE_15M"] = "Старше 15 минут"
    L["GROUP_AGE_30M"] = "Старше 30 минут (рек.)"
    L["GROUP_AGE_45M"] = "Старше 45 минут"
    L["GROUP_AGE_60M"] = "Старше 1 часа"
    L["GROUP_AGE_90M"] = "Старше 1.5 часов"
    L["GROUP_AGE_120M"] = "Старше 2 часов"
    L["TOOLTIP_GROUP_AGE_LABEL"] = "Время в поиске:"

    -- Sorting
    L["SORT_HEADER"] = "Сортировка:"
    L["SORT_KEY_DESC"] = "Уровень ключа (убыв. 15 -> 2)"
    L["SORT_KEY_ASC"] = "Уровень ключа (возр. 2 -> 15)"
    L["SORT_DUNGEON_ASC"] = "По названию данжа (А-Я)"
    L["SORT_ROLE_TANK"] = "Сначала где нужен Танк"
    L["SORT_ROLE_HEAL"] = "Сначала где нужен Хил"
    L["SORT_ROLE_DPS"] = "Сначала где нужен ДД"
    L["SORT_SLOTS_DESC"] = "Почти собранные (4/5 первыми)"
    L["SORT_TIME_DESC"] = "Самые свежие группы"
    L["SORT_ILVL_DESC"] = "Требуемый ilvl (убыв.)"
    L["SORT_DEFAULT"] = "По умолчанию Blizzard"

    -- Results status
    L["RESULTS_STATUS"] = "Показано: %d из %d групп"
    L["RESULTS_STATUS_NO_FILTER"] = "Всего групп: %d"

    -- Legion Dungeons (Russian)
    L["DUNGEONS"] = {
        [1] = "Крепость Черной Ладьи",
        [2] = "Собор Вечной Ночи",
        [3] = "Квартал Звезд",
        [4] = "Чаща Темного Сердца",
        [5] = "Око Азшары",
        [6] = "Чертоги Доблести",
        [7] = "Утроба душ",
        [8] = "Логово Нелтариона",
        [9] = "Возвращение в Каражан: нижний ярус",
        [10] = "Возвращение в Каражан: верхний ярус",
        [11] = "Престол Триумвирата",
        [12] = "Катакомбы Сурамара",
        [13] = "Казематы Стражей",
    }

    -- Multi-select Tooltips (Russian)
    L["TOOLTIP_CLICK_DUNGEON_SINGLE"] = "ЛКМ: Фильтровать только этот данж"
    L["TOOLTIP_SHIFT_CLICK_MULTI"] = "Shift + ЛКМ: Добавить/убрать из мульти-выбора"
    L["TOOLTIP_MULTI_SELECTED"] = "|cff00ff00[Выбрано в мульти-фильтре]|r Shift+Клик чтобы убрать"
    L["MULTI_DUNGEONS_SELECTED"] = "Выбрано данжей: %d"

    -- Quick Keystone Creator (Russian)
    L["QUICK_CREATOR_TITLE"] = "Быстрый сбор ключа"
    L["QUICK_CREATOR_MY_KEY"] = "Мой ключ"
    L["QUICK_CREATOR_NO_KEY"] = "Ключ не найден в сумках"
    L["QUICK_CREATOR_LEVEL"] = "Уровень ключа:"
    L["QUICK_CREATOR_DUNGEON"] = "Подземелье:"
    L["QUICK_CREATOR_TAGS"] = "Быстрые теги:"
    L["QUICK_CREATOR_APPLY"] = "Применить к названию"
    L["QUICK_CREATOR_CLEAR"] = "Очистить"
    L["PARTY_KEYS_HEADER"] = "Ключи группы:"
    L["YOU"] = "Вы"
    L["TAG_CHESTS"] = "[+2/3]"
    L["TAG_FAST"] = "[Фаст]"
    L["TAG_PUSH"] = "[Пуш]"
    L["TAG_WEEKLY"] = "[Викли]"
    L["TAG_CHILL"] = "[Чилл]"
    L["TAG_EXP"] = "[Опыт]"

    -- Blacklist Protection (Russian)
    L["BL_TITLE"] = "Защита Чёрного Списка"
    L["BL_HEADER"] = "Чёрный список"
    L["BL_BUTTON"] = "ЧС"
    L["BL_BUTTON_TOOLTIP"] = "Открыть управление Чёрным списком (аккаунт и группа)"
    L["BL_BADGE_APPLICANT"] = "[В ЧС: %s]"
    L["BL_BADGE_LEADER"] = "[Лидер в ЧС]"
    L["BL_DEFAULT_REASON"] = "Игрок в ЧС"
    L["BL_REASON_WOW_IGNORE"] = "Игнор-лист WoW"
    L["BL_SOURCE_SELF"] = "Вы / Ваш альт"
    L["BL_SOURCE_PARTY"] = "Сопартиец: %s"
    L["BL_INVITE_BLOCKED_TOOLTIP"] = "Игрок находится в Чёрном списке! Кнопка «Пригласить» заблокирована аддоном для защиты от случайного инвайта."
    L["BL_LEADER_BLOCKED_TOOLTIP"] = "Лидер этой группы находится в вашем Чёрном списке! Причина: %s (Добавил: %s)"
    L["BL_ADD_TITLE"] = "Добавить в ЧС"
    L["BL_NAME_HINT"] = "Имя игрока"
    L["BL_REASON_HINT"] = "Причина (Ливер, Токсик...)"
    L["BL_ADD_BUTTON"] = "Добавить"
    L["BL_EMPTY_LIST"] = "Чёрный список пуст."
    L["BL_COUNT_LABEL"] = "Всего в ЧС: %d игроков"
    L["BL_DELETE_TOOLTIP"] = "Клик: удалить из Чёрного списка"
    L["BL_ADDED_NOTIFY"] = "Игрок %s добавлен в Чёрный список."
    L["BL_REMOVED_NOTIFY"] = "Игрок %s удален из Чёрного списка."
    L["BL_AUTOSAVE_CHECKBOX"] = "Авто-сохранять ЧС группы навсегда"
    L["BL_AUTOSAVE_TOOLTIP"] = "Если включено, записи из ЧС участников группы будут автоматически и навсегда сохраняться в вашу базу аккаунта."
    L["BL_IMPORT_BUTTON"] = "Импорт ЧС группы"
    L["BL_IMPORT_TOOLTIP"] = "Скопировать все записи участников текущей группы в ваш постоянный ЧС аккаунта."
    L["BL_IMPORT_SUCCESS"] = "Импортировано %d записей из ЧС группы в ваш постоянный список."
    L["BL_IMPORT_NO_DATA"] = "Нет новых записей из группы для импорта."
    L["BL_SEARCH_HINT"] = "Поиск по нику или причине..."
    L["BL_COL_NAME"] = "Игрок"
    L["BL_COL_REASON"] = "Причина"
    L["BL_COL_SOURCE"] = "Источник"
    L["BL_COL_DATE"] = "Дата добавления"
    L["BL_FOUND_COUNT"] = "Найдено: %d из %d"
    L["BL_BADGE_IN_BL"] = "В ЧС"
    L["BL_CONFIRM_TITLE"] = "ВНИМАНИЕ!"
    L["BL_CONFIRM_INVITE_TEXT"] = "Игрок %s находится в чёрном списке:\n\"%s\"\n\nВы уверены, что хотите пригласить его в группу?"

    -- Whitelist (Russian)
    L["WL_TITLE"] = "Белый список игроков"
    L["WL_HEADER"] = "Белый список"
    L["WL_BUTTON"] = "БС"
    L["WL_BUTTON_TOOLTIP"] = "Открыть управление Белым списком проверенных игроков"
    L["WL_BADGE_APPLICANT"] = "[Белый список: %s]"
    L["WL_BADGE_LEADER"] = "[Лидер в Белом списке]"
    L["WL_DEFAULT_NOTE"] = "Проверенный игрок"
    L["WL_ADD_TITLE"] = "Добавить в Белый список"
    L["WL_NOTE_HINT"] = "Заметка (Топ танк, Хороший хил, Пушер...)"
    L["WL_ADD_BUTTON"] = "Добавить"
    L["WL_EMPTY_LIST"] = "Белый список пуст."
    L["WL_COUNT_LABEL"] = "Всего в Белом списке: %d игроков"
    L["WL_DELETE_TOOLTIP"] = "Клик: удалить из Белого списка"
    L["WL_ADDED_NOTIFY"] = "Игрок %s добавлен в Белый список."
    L["WL_REMOVED_NOTIFY"] = "Игрок %s удален из Белого списка."
    L["WL_AUTOSAVE_CHECKBOX"] = "Авто-сохранять БС группы в базу аккаунта"
    L["WL_AUTOSAVE_TOOLTIP"] = "При включении любые проверенные игроки, полученные от группы, будут автоматически сохранены в ваш постоянный белый список аккаунта."
    L["WL_IMPORT_BUTTON"] = "Импорт БС группы"
    L["WL_IMPORT_TOOLTIP"] = "Скопировать всех проверенных игроков участников группы в ваш постоянный белый список аккаунта."
    L["WL_IMPORT_SUCCESS"] = "Импортировано %d записей из БС группы в ваш постоянный белый список."
    L["WL_IMPORT_NO_DATA"] = "Нет новых записей из группы для импорта в Белый список."
    L["WL_SEARCH_HINT"] = "Поиск по нику или заметке..."
    L["WL_COL_NAME"] = "Игрок"
    L["WL_COL_NOTE"] = "Заметка"
    L["WL_COL_SOURCE"] = "Источник"
    L["WL_COL_DATE"] = "Дата добавления"
    L["WL_BADGE_IN_WL"] = "Белый список"
    L["WL_APPLICANT_TOOLTIP"] = "Проверенный игрок из вашего Белого списка!"
    L["TAB_BLACKLIST"] = "Чёрный список"
    L["TAB_WHITELIST"] = "Белый список"

    -- Interface Options (Russian)
    L["OPT_TITLE"] = "Сортировка Премейд Групп"
    L["OPT_SUBTITLE"] = "Фильтры M+, быстрый сбор ключей и умная защита от руинеров."
    L["OPT_CATEGORY_GENERAL"] = "Основные настройки"
    L["OPT_CATEGORY_BLACKLIST"] = "Чёрный список и Синхронизация"
    L["OPT_DUNGEON_BAR"] = "Отображать панель 13 данжей в поиске групп"
    L["OPT_DUNGEON_BAR_DESC"] = "Показывает удобные иконки подземелий Легиона над списком премейдов."
    L["OPT_MYTHIC_ONLY"] = "Искать только эпохальные ключи (M+) по умолчанию"
    L["OPT_MYTHIC_ONLY_DESC"] = "Автоматически скрывает обычные подземелья, мифик 0 и квесты."
    L["OPT_ENG_TITLES"] = "Названия ключей на английском (+15 DHT)"
    L["OPT_ENG_TITLES_DESC"] = "Использует английские имена подземелий в листинге для международного поиска."
    L["OPT_AUTOSAVE_PARTY"] = "Авто-сохранять ЧС группы в базу аккаунта"
    L["OPT_AUTOSAVE_PARTY_DESC"] = "Автоматически сохраняет нарушителей от сопартийцев в ваш личный ЧС аккаунта."
    L["OPT_SYNC_GUILD"] = "Синхронизировать ЧС с гильдией (GUILD)"
    L["OPT_SYNC_GUILD_DESC"] = "Автоматически обменивается базой ЧС со всеми согильдийцами с аддоном онлайн."
    L["OPT_AUTOSAVE_PARTY_WL"] = "Авто-сохранять БС группы в базу аккаунта"
    L["OPT_AUTOSAVE_PARTY_WL_DESC"] = "Автоматически сохраняет проверенных игроков от сопартийцев в ваш личный белый список аккаунта."
    L["OPT_SYNC_GUILD_WL"] = "Синхронизировать БС с гильдией (GUILD)"
    L["OPT_SYNC_GUILD_WL_DESC"] = "Автоматически обменивается базой проверенных игроков (БС) с согильдийцами с аддоном онлайн."
    L["OPT_SECTION_INFO"] = "Статистика базы данных"
    L["OPT_STATS_SELF"] = "Записей в личном ЧС (аккаунт): %d"
    L["OPT_STATS_PARTY"] = "Получено от текущей группы: %d"
    L["OPT_STATS_TOTAL"] = "Всего нарушителей под защитой: %d"
    L["OPT_SECTION_COMMANDS"] = "Команды чата"
    L["OPT_OPEN_BL_WINDOW"] = "Открыть окно Чёрного Списка"
    L["OPT_OPEN_WL_WINDOW"] = "Открыть окно Белого Списка"
    L["OPT_IMPORT_PARTY_NOW"] = "Импорт ЧС группы сейчас"
    L["OPT_IMPORT_PARTY_WL_NOW"] = "Импорт БС группы сейчас"
    L["OPT_RESET_SETTINGS"] = "Сброс настроек"
    L["OPT_RESET_CONFIRM"] = "Все настройки PremadeGroupSort сброшены по умолчанию."

    -- Anime Audio & Mascot Art (Russian)
    L["OPT_CATEGORY_ANIME"] = "Аниме озвучка и оформление"
    L["OPT_SOUND_ENABLE"] = "Включить аниме озвучку"
    L["OPT_SOUND_ENABLE_DESC"] = "Воспроизводить забавные японские аниме-фразы и звуки при ключевых событиях."
    L["OPT_SOUND_LOGIN"] = "Приветствие при входе на персонажа"
    L["OPT_SOUND_LOGIN_DESC"] = "Воспроизводить фразу приветствия при входе в мир / на персонажа."
    L["OPT_SOUND_AFK"] = "Выход из статуса АФК"
    L["OPT_SOUND_AFK_DESC"] = "Воспроизводить забавную реплику, когда вы возвращаетесь к игре из АФК."
    L["OPT_SOUND_GROUP"] = "Начало сбора группы (Hydro Dragon)"
    L["OPT_SOUND_GROUP_DESC"] = "Воспроизводить аниме фразу или Hydro Dragon при создании группы в поиске."
    L["OPT_SOUND_BL"] = "Предупреждение о ЧС в заявках"
    L["OPT_SOUND_BL_DESC"] = "Воспроизводить предупреждение, если в группу подал заявку игрок из ЧС."
    L["OPT_ANIME_ART"] = "Показывать арт аниме кошкодевочки"
    L["OPT_ANIME_ART_DESC"] = "Отображать красивый арт кошкодевочки-геймера в меню настроек и окне ЧС."
    L["OPT_SOUND_TEST"] = "Тест"
    L["OPT_SOUND_TEST_TOOLTIP"] = "Нажмите, чтобы прослушать пример звука из этой категории."
    L["OPT_SOUND_BOOST"] = "Усиление громкости звуков"
    L["OPT_SOUND_BOOST_DESC"] = "Дополнительно усиливает громкость аниме-реплик и песен аддона без изменения общей громкости звуков игры."
    L["OPT_SOUNDBOARD_SUBPANEL"] = "Аниме Озвучка"
    L["OPT_SOUNDBOARD_TITLE"] = "Аниме реплики и саундборд"
    L["OPT_SOUNDBOARD_DESC"] = "Прослушивание всех аниме реплик, фраз кошкодевочки и легендарного Hydro Dragon."
    L["OPT_SECRET_BUTTON"] = "Секретная кнопка (НЕ НАЖИМАТЬ!)"
    L["OPT_SECRET_DESC"] = "Вы точно уверены? Внутри скрыты настройки аниме-озвучки и кошкодевочки..."
    L["OPT_SECRET_TITLE"] = "Секретное меню: Аниме озвучка и кошкодевочка"
    L["OPT_MINIMAP_ICON"] = "Отображать иконку у миникарты"
    L["OPT_MINIMAP_ICON_DESC"] = "Показывает удобную круглую кнопку аддона возле миникарты."
    L["BL_CHAT_HINT"] = "Подсказка: ПКМ по нику в чате или фрейму игрока -> «В ЧС (PGS)»"
end
