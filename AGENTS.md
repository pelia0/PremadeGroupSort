# PremadeGroupSort

- This addon has its own repository: `https://github.com/pelia0/PremadeGroupSort`. Commit and push completed changes here, normally to `main`; do not stage it in the parent AddOns collection.
- All new documentation, comments, test names, and commit messages must be English. Keep existing localized UI strings intact.
- Target World of Warcraft Legion 7.3.5 and Lua 5.1. Do not depend on modern Retail container/Mythic+ APIs. Private-server item and tooltip variants already supported by this addon must remain covered.
- Preserve customized behavior and unrelated files. Inspect `git status` before edits; do not rewrite history or reset user changes.
- Run `python -m pip install -r tests/requirements.txt` when test dependencies are absent, then `python -m unittest discover -s tests -v` from this directory. Tests must execute shipped Lua via `lupa.lua51.LuaRuntime` and validate every TOC-loaded Lua file.
- Every bug fix needs a focused behavioral regression. Keep lifecycle/party tests on the real handlers and a deterministic transport/timer simulation; do not replace the behavior being tested with mocks.
- Only a character's inventory establishes its owned keystone. The active group's challenge is not proof of ownership. Missing/errored/uncached data and incomplete tooltip levels are unknown, never an invented +2 or confirmed absence. Preserve last confirmed records.
- `PremadeGroupSortDB.characterKeys` is account-wide and keyed by realm plus GUID. Preserve it across settings reset. Offline records are last known observations, not current server state; do not assume an official-server weekly reset schedule.
- Keep `GetPlayerKeystone()`'s first three results compatible; the fourth result is snapshot metadata. Reads by UI/message handlers must use the cache, not rescan bags.
- Legion can reject newly added Lua files listed by the TOC until a full client restart even after `/reload` (confirmed in FrameXML.log). Keep slash aliases in Core.lua, gate dependent events/UI on completed module-load markers, and test partial loading with either/both modules absent. Installation instructions must explicitly require a full restart when adding files.
- Keep PGS_KEY/PGS_BL/PGS_WL legacy message compatibility. Coalesce inventory events and equivalent sync requests, fingerprint actual rosters, pace outgoing traffic, and defer full lists during combat/active challenges without polling timers.
- Never let old group queues or pre-edit snapshots leak into a new group or resurrect removed entries. Data used for blacklist safety updates immediately; hidden UI rebuilding stays lazy.
- Never force automatic global Lua garbage collection on combat end or panel hide. `/pgs gc` is an explicit manual command. `/pgs perf` prints aggregate session counters only when requested.
- Before committing, run the complete addon suite and `git diff --check`, inspect the staged tree, and independently verify the pushed remote commit. Passing simulation tests does not establish live frame-time acceptance.
