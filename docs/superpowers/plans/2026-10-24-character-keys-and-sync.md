# Character keys and bounded synchronization implementation plan

> Execute inline with superpowers:executing-plans; verify with Lua 5.1 before committing.

**Goal:** `/keys` and `/pgs keys` print this account's last confirmed keystones; party synchronization must not create repeated work during Mythic+.

**Architecture:** Reuse the existing account-wide SavedVariables. CharacterKeys.lua owns strict, cached inventory observations and character records. Sync.lua owns coalesced scheduling, roster change detection and paced addon messages. Existing UI and legacy message formats remain supported.

**Tech stack:** WoW Legion 7.3.5, Lua 5.1, Python unittest + lupa.lua51 2.8.

**Spec:** The approved plan and freeze investigation in this chat, 2026-10-24.

## Constraints and rulings

- Work in the live addon folder on main in the user-requested standalone repository https://github.com/pelia0/PremadeGroupSort. Preserve the original 40 files in a separate baseline commit. Do not touch unrelated addons or archives. All new documentation, comments, tests and commit messages must be English.
- No NerdPack or unlocker changes. Maintain standalone AGENTS.md with this addon's confirmed compatibility constraints and test command.
- Only characters actually visited with the addon can be observed. Show the observation age; do not invent a private-server weekly reset or erase offline records automatically.
- Unknown/missing inventory data is not proof of no key. Never invent level +2. Do not identify the group's active challenge as the player's owned key.
- Preserve character records across ResetDefaults. Identify by realm + GUID, with full display metadata.
- Reuse wire formats PGS_KEY, PGS_BL, PGS_WL for old peers. Coalesce equivalent requests; defer full list exchange in combat/active challenge and pace queued packets outside it. Manual add/delete messages remain available.
- Hidden panels must not scan bags or rebuild lists. Receive handlers update safety data immediately and coalesce visual work. Remove automatic explicit GC calls after combat/panel hide; manual memory command remains.
- Ruling: the skill's Unix/root scratch scripts are replaced by an addon-local ignored .work/progress.md ledger, because this task's writable workspace is the addon directory. This does not change implementation or review gates.

## Review focus

- Cold bag cache, occupied slots without links, API errors and incomplete tooltip data preserve the last confirmed record.
- Empty observations around keystone slotting/start require confirmation and never overwrite a key during a challenge.
- Stable rosters and unchanged keys produce no repeated exchange; joining peers and legacy requests still receive data.
- Large list snapshots are paced and paused in a challenge; hidden settings stay idle while safety lookups immediately see received entries.
- Character switching, /reload, multiple realms, unknown map IDs, locale fallbacks and reset preserve readable records.

## Tasks

- [x] 1. Create Lua 5.1 behavioral tests executing the installed Core.lua/UI.lua plus any TOC modules, with simulated party transport and deterministic timers. Observe failures for repeated scans/messages, hidden refreshes, forced GC and missing `/keys`.
- [x] 2. Implement CharacterKeys.lua: strict inventory read, bounded retries, confirmed empty state, cache, realm/GUID records and sorted local chat output. Preserve GetPlayerKeystone's first three return values and add snapshot metadata as the fourth.
- [x] 3. Implement Sync.lua: keyed scheduling, actual roster fingerprint, paced messages, per-channel response/request limits, deferred full lists, changed-only key announcements, and on-demand aggregate counters with no unsolicited output.
- [x] 4. Connect events and UI invalidation, defer hidden view work, retain old protocol compatibility and safety checks, remove automatic forced GC, update localization/version/TOC.
- [x] 5. Run the full addon suite, compile every loaded Lua file in Lua 5.1, validate TOC references, compare simulated group traffic, review the diff and get an independent final code review. Fix confirmed findings with focused regressions.
- [ ] 6. Update durable guidance, verify staged diff/checks, commit the feature/fixes, push both commits and independently verify origin/main. Report that live frame-time acceptance remains an in-game check. (Local guidance and validation complete; commit/push is the execution handoff.)
