# Version 1.4.0 validation

Implementation commit `7588f9a7bf2f9a1e08c2cc2a2b97f5a259c76610` and the original baseline were pushed to the standalone repository. `git ls-remote origin refs/heads/main` independently matched the implementation SHA after push. This document and the completed execution checklist are recorded in a subsequent documentation commit.

## Automated verification

The complete suite passes: **44 tests**, running shipped addon code in `lupa.lua51.LuaRuntime` (Lua 5.1) with pinned `lupa==2.8` on Python 3.12. Every TOC-loaded Lua file compiles and resolves to an existing file. `git diff --check` passes.

Independent review found six lifecycle/ordering regressions in the first implementation. Seven additional tests first reproduced those failures and then passed after fixes. A bounded follow-up review confirmed that all six findings were resolved and the 44-test suite remained green.

## Controlled operation-count comparison

Both versions were run through the same deterministic party/timer/transport harness. The baseline is commit `a4a5f47` (original customized 1.3.0). No real game frames or server throttling were measured.

| Scenario / total across five clients | Baseline | Updated |
| --- | ---: | ---: |
| One roster event per client, 100 blacklist records each: PGS_BL packet sends over 20 seconds | 505 | 205 |
| Same roster scenario: hidden settings refresh calls | 2,000 | 0 |
| Ten unchanged bag events per client in one burst: PGS_KEY packet sends | 50 | 0 |
| Same bag burst, key in the last of 40 simulated slots: complete bag scans | 300 | 5 |

The updated roster count includes one bounded trailing response for requests that arrive inside the response cooldown, so newly reloaded peers cannot be left without data. Packet sends are paced instead of synchronous bursts. Full-list requests and snapshots are deferred entirely while combat or a challenge is active; a focused regression verifies zero bulk traffic and no polling timers while deferred.

## Limits

These results establish Lua behavior and operation counts. Actual freeze duration, visual layout, and this private server's event ordering remain separate in-game checks described in README.md. Older peers may still generate excessive incoming traffic until updated.
