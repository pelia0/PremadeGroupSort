# PremadeGroupSort

A customized World of Warcraft **Legion 7.3.5** addon for Mythic+ group search, group creation, party keystones, and account/party blacklist protection.

## Install

Place this repository in `World of Warcraft/Interface/AddOns/PremadeGroupSort`, then restart the client or reload the UI. The folder must directly contain `PremadeGroupSort.toc`, `Core.lua`, and the other addon files.

This is a standalone repository. The surrounding AddOns collection is not required. Existing `PremadeGroupSortDB` settings are retained.

## Commands

| Command | Behavior |
| --- | --- |
| `/keys` | Print the last confirmed keystone for each recorded character in your local chat. |
| `/pgs keys` | The same account keystone list. |
| `/pgs` | Toggle the group-search filter panel. |
| `/pgs options` | Open addon settings. |
| `/pgs bl` / `/pgs wl` | Open blacklist / whitelist management. |
| `/pgs perf` | Print aggregate counters for sent/received messages, inventory scans, visible view refreshes, and queued messages. |
| `/pgs gc` | Explicitly request a full Lua garbage-collection cycle. This may cause a pause. |

## Character keystone records

Log in to each character with this addon enabled to record its key. Records are shared through account-wide SavedVariables and survive logout, UI reload, and resetting addon settings. Separate WoW account SavedVariables are not synchronized.

`/keys` refreshes the current character's inventory and prints that character first, then other characters by descending key level. Each row includes the realm and the age of the last confirmed observation. Links are clickable when an inventory link is available. Characters without a key and characters with unconfirmed inventory are shown explicitly.

Offline characters cannot be inspected. Their records may be outdated, including after a server reset; log in to refresh them. The addon does not guess private-server reset times or delete offline records automatically.

Inventory scans are cached and coalesced. A missing item link, unavailable bag API, or incomplete tooltip does not erase the last confirmed key or invent a level. An empty inventory requires a second observation. No-key observations while a key is slotted or a challenge is active stay unconfirmed. A party's active challenge is never recorded as the player's owned key.

## Synchronization and performance

Version 1.4.0 keeps the existing PGS_KEY, PGS_BL, and PGS_WL wire formats while bounding work:

- Unchanged key observations do not repeatedly broadcast. UI and peer-message handling read the cached key.
- A stable roster does not repeatedly request or broadcast complete lists.
- Outgoing packets share a queue paced at one packet every 250 milliseconds per client.
- Full blacklist/whitelist snapshots and their requests wait until both combat and the active challenge have ended. Lifecycle events resume them; no periodic polling runs while they wait.
- Manual add/delete updates remain available during a run. Received safety data is applied immediately; visual refreshes are coalesced, and hidden panels rebuild when opened.
- Leaving/replacing a group invalidates pending group traffic. Disabling guild synchronization prevents its pending packets from being sent.
- Combat end and panel hide no longer force global Lua garbage collection.

Older copies of the addon can still send excessive traffic. Install the update on all affected party members for the complete benefit.

`/pgs perf` is an on-demand diagnostic, not a live frame-time profiler. Compare its counters before and after a reproducible scenario. It never prints automatically.

## Tests

Python 3.12 is the verified runtime. Install the pinned isolated test dependency and run:

```powershell
python -m pip install -r tests/requirements.txt
python -m unittest discover -s tests -v
```

The suite executes the shipped Lua in Lua 5.1 with controlled WoW API, frame, transport, and timer boundaries. It covers account persistence, uncertain inventory, legacy tooltips, chat commands, cached reads, party changes, queued traffic, challenge/combat deferral, and hidden UI refreshes. It also compiles every TOC-loaded Lua file.

## In-game acceptance

1. Reload, run `/keys` on two characters, reload again, and verify both records, levels, timestamps, and current-character ordering.
2. Run a key with two or more updated addon users. Compare `/pgs perf` before and after loot, trash fights, and the final boss. Verify that no full list transfer occurs during the run.
3. Check key changes, legacy peers, joining/leaving a group, and manual blacklist add/remove. Open the hidden settings afterward and verify that the displayed data is current.
4. Check that group-search filtering, group creation, blacklist invite protection, and existing settings still behave as expected.

Simulation verifies behavior and operation counts. Freeze duration and visual correctness still require this check in the actual private-server client.
