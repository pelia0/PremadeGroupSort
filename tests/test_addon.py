"""Behavioral regressions: execute shipped Lua in Lua 5.1, not translated logic."""
import heapq
import itertools
import unittest
from collections import Counter, deque
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]

SETUP = r'''
_frames={}; SlashCmdList={}; StaticPopupDialogs={}; WorldFrame={}; UIParent={}
COUNTS={slots=0,scans=0,gc=0,options=0}; OUTPUT={}
IN_GROUP=true; IN_GUILD=false; COMBAT=false; ACTIVE=false; SLOTTED=false
REALM='Realm'; GUID='Player-1'; PLAYER='Pellia'; CLASS='PRIEST'
BAGS={}; for i=0,4 do BAGS[i]={slots=8} end
function GetLocale() return 'enUS' end
function strlower(s) return string.lower(s) end
function IsInGroup() return IN_GROUP end
function IsInRaid() return false end
function IsInGuild() return IN_GUILD end
function InCombatLockdown() return COMBAT end
function UnitAffectingCombat() return COMBAT end
function UnitIsGroupLeader() return false end
function GetNumGroupMembers() return 5 end
function GetNumSubgroupMembers() return 4 end
function UnitName(u) if u=='player' then return PLAYER end return MEMBERS[u] end
function UnitGUID(u) if u=='player' then return GUID end return MEMBERS[u] end
function UnitClass() return 'Priest',CLASS end
function GetRealmName() return REALM end
function GetGuildInfo() if IN_GUILD then return 'Guild' end end
function GetTime() return NOW() end
function time() return 1800000000+math.floor(NOW()) end
function date(fmt,t) return os.date(fmt,t) end
function UnitIsAFK() return false end
function GetNumIgnores() return 0 end
function wipe(t) for k in pairs(t) do t[k]=nil end return t end
function RegisterAddonMessagePrefix() end
function hooksecurefunc() end
function print(s) OUTPUT[#OUTPUT+1]=s end
function CreateFrame(kind,name)
 local f={events={}}
 function f:RegisterEvent(e) self.events[e]=true end
 function f:SetScript(k,v) self[k]=v end
 function f:HookScript(k,v) self[k]=v end
 function f:SetOwner() end
 function f:ClearLines() end
 function f:SetBagItem(b,s)
  self.lines=TOOLTIP or {}
  for i,text in ipairs(self.lines) do _G[name..'TextLeft'..i]={GetText=function() return text end} end
 end
 function f:NumLines() return #(self.lines or {}) end
 _frames[#_frames+1]=f
 if name then _G[name]=f end
 return f
end
function GetContainerNumSlots(b)
 if BAG_ERROR then error('bags not ready') end
 return BAGS[b].slots
end
function GetContainerItemLink(b,s)
 COUNTS.slots=COUNTS.slots+1
 return BAGS[b][s] and BAGS[b][s].link
end
function GetContainerItemID(b,s) return BAGS[b][s] and BAGS[b][s].id end
function GetContainerItemInfo(b,s)
 local x=BAGS[b][s]; if x then return 1,1,false,4,false,false,x.link,false,false,x.id end
end
function SendAddonMessage(prefix,msg,ch,target) SEND(prefix,msg,ch,target) end
C_Timer={After=function(delay,fn) AFTER(delay,fn) end}
C_ChallengeMode={
 IsChallengeModeActive=function() return ACTIVE end,
 HasSlottedKeystone=function() return SLOTTED end,
 GetMapInfo=function(id) if id==200 then return 'Halls of Valor' end end,
}
local gc=collectgarbage
collectgarbage=function(opt,arg)
 if opt=='step' or opt=='collect' then COUNTS.gc=COUNTS.gc+1 end
 return gc(opt,arg)
end
function Widget()
 local f={shown=false}
 for _,k in ipairs({'Hide','Show','SetSize','SetPoint','ClearAllPoints','SetAlpha','Enable','Disable',
  'SetBackdropColor','SetBackdropBorderColor','SetText','SetTextColor'}) do f[k]=function() end end
 f.IsShown=function(self) return self.shown end
 f.HookScript=function(self,key,fn) self[key]=fn end
 return f
end
function InstallHiddenCreationPanel()
 local cp=Widget(); cp.partyKeyButtons={}
 for i=1,5 do cp.partyKeyButtons[i]=Widget(); cp.partyKeyButtons[i].text=Widget() end
 for i=1,30 do
  local n=debug.getupvalue(addon.RefreshCreationPanel,i)
  if not n then break end
  if n=='creationPanel' then debug.setupvalue(addon.RefreshCreationPanel,i,cp); break end
 end
 addon.creationPanel=cp
end
'''


class Party:
    def __init__(self, count=1):
        self.now = 100.0
        self.order = itertools.count()
        self.tasks = []
        self.wire = deque()
        self.sent = []
        self.clients = [Client(self, i) for i in range(count)]

    def deliver(self):
        while self.wire:
            source, prefix, message, channel, target = self.wire.popleft()
            for peer in self.clients:
                if peer is not source and (not target or target == peer.name):
                    peer.fire('CHAT_MSG_ADDON', prefix, message, channel, source.name)

    def advance(self, seconds):
        until = self.now + seconds
        steps = 0
        self.deliver()
        while self.tasks and self.tasks[0][0] <= until:
            at, _, callback = heapq.heappop(self.tasks)
            self.now = at
            callback()
            self.deliver()
            steps += 1
            if steps > 20000:
                raise AssertionError('timer/message loop')
        self.now = until


class Client:
    def __init__(self, party, index):
        self.party = party
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.g = self.lua.globals()
        self.name = 'Pellia' if not index else f'Alt{index}'
        self.g.NOW = lambda: party.now
        self.g.AFTER = lambda delay, fn: heapq.heappush(
            party.tasks, (party.now + delay, next(party.order), fn))

        def send(prefix, message, channel, target=None):
            party.sent.append((party.now, self.name, prefix, message, channel, target))
            party.wire.append((self, prefix, message, channel, target))

        self.g.SEND = send
        self.lua.execute(SETUP)
        self.g.PLAYER = self.name
        self.g.GUID = f'Player-{index+1}'
        self.g.MEMBERS = self.lua.table_from({f'party{i}': f'Member{i}' for i in range(1, 5)})
        self.addon = self.lua.table()
        self.g.addon = self.addon
        self.frames = []
        for line in (ROOT / 'PremadeGroupSort.toc').read_text(encoding='utf-8-sig').splitlines():
            name = line.strip()
            if not name.endswith('.lua'):
                continue
            before = len(self.g._frames)
            self.lua.execute((ROOT / name).read_text(encoding='utf-8-sig'), 'PremadeGroupSort', self.addon)
            if name != 'UI.lua':
                self.frames.extend(self.g._frames[j] for j in range(before+1, len(self.g._frames)+1))
        self.fire('ADDON_LOADED', 'PremadeGroupSort')
        self.addon.isWorldLoaded = True
        self.addon.wasInGroup = True
        self.lua.execute('InstallHiddenCreationPanel()')

    def fire(self, event, *args):
        for frame in self.frames:
            if frame.events[event] and frame.OnEvent:
                frame.OnEvent(frame, event, *args)

    def run(self, source):
        return self.lua.execute(source)

    def key(self, level=12, map_id=200):
        self.g.BAGS[0][1] = self.lua.table_from(
            {'id': 138019, 'link': f'|Hkeystone:{map_id}:{level}:0:0:0|h[Keystone]|h'})

    def require(self, method):
        if self.lua.eval('type')(self.addon[method]) != 'function':
            raise AssertionError(f'Missing production behavior: addon:{method}')
        return lambda *args: self.addon[method](self.addon, *args)


class AddonTests(unittest.TestCase):
    def test_loaded_files_compile_in_lua51_and_exist(self):
        lua = LuaRuntime()
        self.assertEqual(lua.eval('_VERSION'), 'Lua 5.1')
        for line in (ROOT / 'PremadeGroupSort.toc').read_text(encoding='utf-8-sig').splitlines():
            if line.strip().endswith('.lua'):
                lua.compile((ROOT / line.strip()).read_text(encoding='utf-8-sig'))

    def test_unchanged_bag_burst_does_not_rebroadcast_or_rescan_per_event(self):
        p = Party(); c = p.clients[0]; c.key()
        c.fire('PLAYER_ENTERING_WORLD'); p.advance(4); p.sent.clear()
        c.g.COUNTS.slots = 0
        for _ in range(20): c.fire('BAG_UPDATE_DELAYED')
        p.advance(4)
        self.assertEqual(len(p.sent), 0, 'an unchanged key must not generate packets')
        self.assertLessEqual(c.g.COUNTS.slots, 40, 'coalesce inventory events into one scan')

    def test_peer_key_does_not_scan_hidden_local_panel(self):
        c = Party().clients[0]
        c.fire('CHAT_MSG_ADDON', 'PGS_KEY', 'KEY:HOV:12', 'PARTY', 'Friend')
        c.party.advance(1)
        self.assertEqual(c.g.COUNTS.slots, 0)
        self.assertEqual(c.addon.partyKeystones.Friend.level, 12)

    def test_full_lists_are_deferred_during_challenge(self):
        p = Party(5)
        for c in p.clients:
            c.g.ACTIVE = True
            c.fire('GROUP_ROSTER_UPDATE')
        p.advance(3)
        self.assertFalse(any(x[2] in ('PGS_BL','PGS_WL') for x in p.sent))

    def test_stable_roster_does_not_repeat_requests(self):
        p = Party(3)
        for c in p.clients: c.fire('GROUP_ROSTER_UPDATE')
        p.advance(15); p.sent.clear()
        for _ in range(10):
            for c in p.clients: c.fire('GROUP_ROSTER_UPDATE')
        p.advance(15)
        self.assertEqual(p.sent, [])

    def test_bulk_packets_are_paced_and_repeated_requests_coalesced(self):
        p = Party(); c = p.clients[0]
        c.run("for i=1,100 do addon.db.blacklist['bad'..i]={name='Bad'..i,reason='Reason123456789'} end")
        for _ in range(10): c.fire('CHAT_MSG_ADDON','PGS_BL','REQ_BL','PARTY','Friend')
        self.assertEqual(p.sent, [], 'the receive handler must not send a snapshot synchronously')
        p.advance(1)
        self.assertLessEqual(len(p.sent), 5)
        p.advance(20)
        self.assertLess(len(p.sent), 30, 'one full snapshot, not ten')
        self.assertTrue(c.addon.db.blacklist.bad100)

    def test_received_blacklist_updates_safety_without_hidden_settings_refresh(self):
        c = Party().clients[0]
        c.run('addon.optionsBLPanel={IsShown=function() return false end, refresh=function() COUNTS.options=COUNTS.options+1 end}')
        for _ in range(10): c.fire('CHAT_MSG_ADDON','PGS_BL','BL_DATA:Bad=Leaver','PARTY','Friend')
        c.party.advance(1)
        self.assertTrue(c.addon.GetBlacklistInfo(c.addon,'Bad'))
        self.assertEqual(c.g.COUNTS.options, 0)

    def test_visible_remote_views_are_coalesced(self):
        c = Party().clients[0]
        c.run('addon.optionsBLPanel={IsShown=function() return true end, refresh=function() COUNTS.options=COUNTS.options+1 end}')
        for _ in range(10): c.fire('CHAT_MSG_ADDON','PGS_BL','BL_DATA:Bad=Leaver','PARTY','Friend')
        c.party.advance(1)
        self.assertEqual(c.g.COUNTS.options, 1)

    def test_combat_end_does_not_force_global_gc(self):
        c = Party().clients[0]
        for _ in range(10): c.fire('PLAYER_REGEN_ENABLED')
        self.assertEqual(c.g.COUNTS.gc, 0)

    def test_two_visited_characters_survive_reload_and_reset(self):
        c = Party().clients[0]; c.g.IN_GROUP = False; c.key()
        refresh = c.require('RefreshCharacterKeystone'); refresh()
        c.g.PLAYER = 'Alt'; c.g.GUID = 'Player-alt'; c.key(9,198); refresh()
        rows = c.require('GetCharacterKeyRows')()
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[1].name, 'Alt')
        c.addon.ResetDefaults(c.addon)
        self.assertEqual(len(c.require('GetCharacterKeyRows')()), 2)
        saved = c.g.PremadeGroupSortDB
        c.fire('ADDON_LOADED','PremadeGroupSort')
        self.assertEqual(len(c.require('GetCharacterKeyRows')()), 2)
        self.assertTrue(saved.characterKeys)

    def test_unknown_inventory_preserves_last_confirmed_key(self):
        c = Party().clients[0]; c.key(); refresh = c.require('RefreshCharacterKeystone'); refresh()
        c.run('BAGS[0][1]={id=138019}')
        result = refresh()
        self.assertEqual(result.status, 'unknown')
        row = c.require('GetCharacterKeyRows')()[1]
        self.assertEqual(row.level, 12)
        self.assertTrue(row.unconfirmed)

    def test_tooltip_without_level_never_fabricates_plus_two(self):
        c = Party().clients[0]
        c.run("BAGS[0][1]={id=138019,link='|Hitem:138019:0|h[Mythic Keystone]|h'}; TOOLTIP={'Halls of Valor'}")
        c.require('RefreshCharacterKeystone')()
        result = c.addon.GetPlayerKeystone(c.addon)
        self.assertIsNone(result[1])

    def test_legacy_item_tooltip_recovers_real_level(self):
        c = Party().clients[0]
        c.run("BAGS[0][1]={id=138019,link='|Hitem:138019:0|h[Mythic Keystone]|h'}; TOOLTIP={'Halls of Valor','Level 17'}")
        c.require('RefreshCharacterKeystone')()
        result = c.addon.GetPlayerKeystone(c.addon)
        self.assertEqual(result[:2], ('HOV',17))

    def test_empty_bags_require_confirmation_and_clear_only_current_character(self):
        c = Party().clients[0]; c.key(); refresh = c.require('RefreshCharacterKeystone'); refresh()
        c.run('BAGS[0][1]=nil')
        self.assertEqual(refresh().status, 'unknown')
        c.party.advance(1)
        self.assertEqual(c.require('GetCharacterKeyRows')()[1].status, 'none')

    def test_missing_backpack_or_throwing_api_cannot_erase_key(self):
        for script in ('BAGS[0].slots=0','BAG_ERROR=true'):
            with self.subTest(script=script):
                c = Party().clients[0]; c.key(); refresh = c.require('RefreshCharacterKeystone'); refresh()
                c.run(script); self.assertEqual(refresh().status,'unknown')
                c.party.advance(5)
                self.assertEqual(c.require('GetCharacterKeyRows')()[1].level,12)

    def test_no_key_during_active_challenge_preserves_owned_record(self):
        c = Party().clients[0]; c.key(); refresh = c.require('RefreshCharacterKeystone'); refresh()
        c.run('BAGS[0][1]=nil; ACTIVE=true')
        refresh(); c.party.advance(5)
        self.assertEqual(c.require('GetCharacterKeyRows')()[1].level,12)

    def test_unknown_map_is_logged_without_requiring_modern_api(self):
        c = Party().clients[0]; c.key(19,999)
        c.require('RefreshCharacterKeystone')()
        row = c.require('GetCharacterKeyRows')()[1]
        self.assertEqual((row.mapID,row.level),(999,19))

    def test_same_name_on_two_realms_is_not_merged(self):
        c = Party().clients[0]; c.key(); refresh=c.require('RefreshCharacterKeystone'); refresh()
        c.g.REALM='Other'; c.g.GUID='Player-other'; refresh()
        self.assertEqual(len(c.require('GetCharacterKeyRows')()),2)

    def test_keys_commands_print_local_records_and_do_not_send_to_party(self):
        p=Party(); c=p.clients[0]; c.key()
        c.require('RefreshCharacterKeystone')()
        self.assertEqual(c.g.SLASH_PGSKEYS1,'/keys')
        c.g.SlashCmdList.PGSKEYS('')
        first='\n'.join(c.g.OUTPUT.values())
        self.assertIn('Pellia',first); self.assertIn('+12',first)
        c.g.OUTPUT=c.lua.table(); c.g.SlashCmdList.PREMADEGROUPSORT('keys')
        self.assertIn('+12','\n'.join(c.g.OUTPUT.values()))
        self.assertEqual(p.sent,[])

    def test_failed_send_does_not_break_receive_or_timer_loop(self):
        p=Party(); c=p.clients[0]
        c.run("function SendAddonMessage() error('backend unavailable') end")
        c.fire('CHAT_MSG_ADDON','PGS_BL','REQ_BL','PARTY','Friend')
        p.advance(5)
        self.assertEqual(p.sent,[])

    def test_active_challenge_keeps_deferred_sync_without_polling_timers(self):
        p=Party(); c=p.clients[0]; c.g.ACTIVE=True
        c.fire('GROUP_ROSTER_UPDATE'); p.advance(5)
        self.assertEqual(len(p.tasks),0, 'defer bulk work until lifecycle events, not polling')
        c.g.ACTIVE=False; c.fire('CHALLENGE_MODE_COMPLETED'); p.advance(4)
        self.assertTrue(any(x[2]=='PGS_BL' for x in p.sent))

    def test_new_group_receives_lists_even_within_previous_group_cooldown(self):
        p=Party(); c=p.clients[0]
        c.fire('GROUP_ROSTER_UPDATE'); p.advance(3); p.sent.clear()
        c.g.MEMBERS.party1='NewMember'
        c.fire('GROUP_ROSTER_UPDATE'); p.advance(4)
        self.assertTrue(any(x[2]=='PGS_BL' and x[3].startswith('BL_DATA:') for x in p.sent))

    def test_disabling_guild_sync_cancels_pending_snapshot(self):
        p=Party(); c=p.clients[0]; c.g.IN_GUILD=True
        c.addon.BroadcastBlacklist(c.addon,'GUILD')
        c.addon.db.syncGuildBlacklist=False
        p.advance(4)
        self.assertFalse(any(x[4]=='GUILD' for x in p.sent))

    def test_existing_private_server_item_ids_keep_tooltip_compatibility(self):
        for item_id in (151086,158923):
            with self.subTest(item_id=item_id):
                c=Party().clients[0]
                c.run(f"BAGS[0][1]={{id={item_id},link='|Hitem:{item_id}:0|h[Mythic Keystone]|h'}}; TOOLTIP={{'Halls of Valor','Level 17'}}")
                c.require('RefreshCharacterKeystone')()
                self.assertEqual(c.addon.GetPlayerKeystone(c.addon)[:2],('HOV',17))

    def test_changed_key_is_announced_once_and_receivers_observe_new_level(self):
        p=Party(3)
        for c in p.clients:
            c.key(); c.fire('PLAYER_ENTERING_WORLD')
        p.advance(4); p.sent.clear()
        c=p.clients[0]; c.key(16)
        for _ in range(10): c.fire('BAG_UPDATE_DELAYED')
        p.advance(4)
        keys=[x for x in p.sent if x[2]=='PGS_KEY']
        self.assertEqual(len(keys),1)
        self.assertEqual(p.clients[1].addon.partyKeystones.Pellia.level,16)

    def test_legacy_peer_request_receives_cached_key_without_inventory_scan(self):
        p=Party(); c=p.clients[0]; c.key(); c.require('RefreshCharacterKeystone')()
        c.g.COUNTS.slots=0
        c.fire('CHAT_MSG_ADDON','PGS_KEY','REQ','PARTY','OldPeer'); p.advance(1)
        self.assertEqual(c.g.COUNTS.slots,0)
        self.assertTrue(any(x[3]=='KEY:HOV:12' for x in p.sent))

    def test_unknown_observation_never_announces_no_key(self):
        p=Party(); c=p.clients[0]; c.key(); c.require('RefreshCharacterKeystone')()
        c.run('BAGS[0][1]={id=138019}')
        c.fire('BAG_UPDATE_DELAYED'); p.advance(5)
        self.assertFalse(any(x[3]=='KEY:NONE:0' for x in p.sent))

    def test_realm_guid_identity_survives_character_rename(self):
        c=Party().clients[0]; c.key(); refresh=c.require('RefreshCharacterKeystone'); refresh()
        c.g.PLAYER='Renamed'; refresh()
        rows=c.require('GetCharacterKeyRows')()
        self.assertEqual(len(rows),1); self.assertEqual(rows[1].name,'Renamed')

    def test_custom_chat_api_and_long_notes_keep_packets_bounded(self):
        p=Party(); c=p.clients[0]
        c.run('C_ChatInfo={SendAddonMessage=SendAddonMessage}; addon.db.blacklist.bad={name="Bad",reason=string.rep("x",400)}')
        c.addon.BroadcastBlacklist(c.addon); p.advance(3)
        packets=[x[3] for x in p.sent]
        self.assertTrue(packets)
        self.assertTrue(all(len(x.encode('utf-8'))<=250 for x in packets))

    def test_unknown_locale_uses_english_keys_strings(self):
        c=Party().clients[0]; c.key()
        c.run("function GetLocale() return 'ukUA' end")
        c.require('ShowCharacterKeys')()
        self.assertIn('last known keystones','\n'.join(c.g.OUTPUT.values()))

    def test_old_group_queue_cannot_send_into_a_new_group(self):
        p=Party(); c=p.clients[0]
        c.require('QueueAddonMessage')('PGS_KEY','KEY:HOV:8','PARTY')
        c.fire('GROUP_ROSTER_UPDATE'); p.advance(3)
        self.assertFalse(any(x[3]=='KEY:HOV:8' for x in p.sent))

    def test_deletion_during_run_cannot_be_undone_by_a_queued_snapshot(self):
        p=Party(); c=p.clients[0]
        c.run("addon.db.blacklist.bad={name='Bad',reason='Reason'}")
        c.addon.BroadcastBlacklist(c.addon); p.advance(0.5)
        c.g.ACTIVE=True
        c.addon.RemoveBlacklist(c.addon,'Bad'); p.advance(1)
        self.assertTrue(any(x[3]=='BL_DEL:Bad' for x in p.sent))
        p.sent.clear(); c.g.ACTIVE=False
        c.fire('CHALLENGE_MODE_COMPLETED'); p.advance(5)
        self.assertFalse(any('Bad=Reason' in x[3] for x in p.sent))

    def test_multiple_small_deltas_keep_sending_during_active_run(self):
        p=Party(); c=p.clients[0]; c.g.ACTIVE=True
        for name in ('One','Two','Three'): c.addon.AddBlacklist(c.addon,name,'Reason')
        p.advance(3)
        self.assertEqual(len([x for x in p.sent if x[3].startswith('BL_ADD:')]),3)
        self.assertEqual(len(p.tasks),0)

    def test_empty_peer_snapshot_removes_only_that_senders_old_entries(self):
        c=Party().clients[0]
        c.fire('CHAT_MSG_ADDON','PGS_BL','BL_DATA:Old=Reason','PARTY','Friend')
        c.fire('CHAT_MSG_ADDON','PGS_BL','BL_DATA:Other=Reason','PARTY','OtherFriend')
        c.fire('CHAT_MSG_ADDON','PGS_BL','BL_DATA:NONE','PARTY','Friend')
        self.assertIsNone(c.addon.GetBlacklistInfo(c.addon,'Old'))
        self.assertTrue(c.addon.GetBlacklistInfo(c.addon,'Other'))

    def test_real_settings_refresh_is_lazy_and_rebuilds_on_show(self):
        c=Party().clients[0]
        source=(ROOT/'UI.lua').read_text(encoding='utf-8-sig')
        start=source.index('    blSubPanel.refresh = function()')
        end=source.index('    InterfaceOptions_AddCategory(blSubPanel)',start)
        # Execute the shipped closure, with only frame/font APIs replaced.
        c.run('''addon.optionsBLPanel=Widget(); local p=addon.optionsBLPanel
            p.NUM_ROWS=10; p.ROW_HEIGHT=20; p.shown=false
            addon.db.blacklist.bad={name='Bad',reason='Reason'}''')
        c.run('''local blSubPanel=addon.optionsBLPanel; local statsTxt=nil; local blSubScroll={}
            local function AllocBLEntry() COUNTS.options=COUNTS.options+1; return {} end
            local function RecycleBLEntries(t) wipe(t) end
            local function UpdateSubBlacklistRows() end
            function FauxScrollFrame_Update() end
            '''+source[start:end])
        c.addon.optionsBLPanel.refresh()
        self.assertEqual(c.g.COUNTS.options,0)
        c.addon.optionsBLPanel.shown=True
        c.addon.optionsBLPanel.refresh()
        self.assertEqual(c.addon.optionsBLPanel.rawEntries[1].name,'Bad')

    def test_saved_records_load_in_a_fresh_lua_runtime(self):
        c=Party().clients[0]; c.key(13); c.require('RefreshCharacterKeystone')()
        records=[]
        for key,row in c.addon.db.characterKeys.items(): records.append((key,dict(row.items())))
        fresh=Party().clients[0]
        fresh.addon.db.characterKeys=fresh.lua.table()
        for key,row in records: fresh.addon.db.characterKeys[key]=fresh.lua.table_from(row)
        fresh.fire('ADDON_LOADED','PremadeGroupSort')
        rows=fresh.require('GetCharacterKeyRows')()
        self.assertEqual(len(rows),1); self.assertEqual(rows[1].level,13)

    def test_local_log_order_current_then_descending_keys_then_empty(self):
        c=Party().clients[0]
        c.run('''addon.db.characterKeys={
            ['Realm:Player-1']={name='Pellia',realm='Realm',status='key',level=3},
            b={name='B',realm='Realm',status='key',level=20},
            a={name='A',realm='Realm',status='key',level=12},
            d={name='D',realm='Realm',status='none'}}''')
        rows=c.require('GetCharacterKeyRows')()
        self.assertEqual([rows[i].name for i in range(1,5)],['Pellia','B','A','D'])

    def test_latest_add_delete_add_state_reaches_peer_during_run(self):
        p=Party(2); c=p.clients[0]
        for peer in p.clients: peer.g.ACTIVE=True
        c.addon.AddBlacklist(c.addon,'Bad','Reason')
        c.addon.RemoveBlacklist(c.addon,'Bad')
        c.addon.AddBlacklist(c.addon,'Bad','Reason')
        p.advance(2)
        self.assertTrue(p.clients[1].addon.GetBlacklistInfo(p.clients[1].addon,'Bad'))

    def test_rapid_roster_changes_keep_the_new_groups_key_and_request(self):
        p=Party(); c=p.clients[0]; c.key(); c.require('RefreshCharacterKeystone')()
        c.fire('GROUP_ROSTER_UPDATE'); c.g.MEMBERS.party1='Replacement'
        c.fire('GROUP_ROSTER_UPDATE'); p.advance(3)
        payloads=[x[3] for x in p.sent if x[2]=='PGS_KEY']
        self.assertIn('KEY:HOV:12',payloads); self.assertIn('REQ',payloads)

    def test_successful_inventory_retry_refreshes_visible_creation_panel(self):
        p=Party(); c=p.clients[0]; c.addon.creationPanel.shown=True
        c.run('BAGS[0][1]={id=138019}')
        c.fire('BAG_UPDATE_DELAYED'); p.advance(0.3)
        before=c.addon.perf.viewRefreshes
        c.key(); p.advance(0.6)
        self.assertGreater(c.addon.perf.viewRefreshes,before)

    def test_peer_reload_request_gets_one_trailing_list_response(self):
        p=Party(); c=p.clients[0]
        c.addon.BroadcastBlacklist(c.addon); p.advance(2); p.sent.clear()
        for _ in range(5): c.fire('CHAT_MSG_ADDON','PGS_BL','REQ_BL','PARTY','Reloaded')
        p.advance(15)
        replies=[x for x in p.sent if x[2]=='PGS_BL' and x[3].startswith('BL_DATA:')]
        self.assertEqual(len(replies),1)

    def test_peer_reload_request_gets_a_trailing_key_response(self):
        p=Party(); c=p.clients[0]; c.key(); c.require('RefreshCharacterKeystone')()
        c.addon.BroadcastKeystone(c.addon); p.advance(0.3); p.sent.clear()
        c.fire('CHAT_MSG_ADDON','PGS_KEY','REQ','PARTY','Reloaded')
        p.advance(3)
        self.assertTrue(any(x[3]=='KEY:HOV:12' for x in p.sent))

    def test_pending_local_retry_keeps_later_bag_event_announcement(self):
        p=Party(2); c=p.clients[0]; c.key()
        c.fire('PLAYER_ENTERING_WORLD'); p.advance(3); p.sent.clear()
        c.run('BAGS[0][1]={id=138019}')
        c.require('ShowCharacterKeys')()
        c.key(20); c.fire('BAG_UPDATE_DELAYED'); p.advance(3)
        self.assertEqual(p.clients[1].addon.partyKeystones.Pellia.level,20)

    def test_private_map_alias_can_use_guarded_backported_map_name(self):
        c=Party().clients[0]; c.key(17,999)
        c.run("C_ChallengeMode.GetMapInfo=nil; C_ChallengeMode.GetMapUIInfo=function() return 'Halls of Valor' end")
        c.require('RefreshCharacterKeystone')()
        self.assertEqual(c.addon.GetPlayerKeystone(c.addon)[:2],('HOV',17))


if __name__ == '__main__':
    unittest.main(verbosity=2)
