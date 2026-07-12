# RHR FreeRAM Registry

**Source of truth for this hack.** Check here before allocating any FreeRAM (including temporary debug bytes). Update this file in the same change that adds or moves an address.

Also see `shared/freeram.asm` (baserom shared defines) and [SMWCentral empty RAM map](https://www.smwcentral.net/?p=memorymap&game=smw&region[]=ram&type=Empty).

On SA-1, `$7Fxxxx` mirrors often live at `$40xxxx` / `$41xxxx`. Prefer the **live SA-1 bus address** used by inserted code.

## Rules

1. Search this registry (and grep `$41` / `$7F` / `!addr` freeram) before picking a new address.
2. Prefer named defines in `shared/freeram.asm` or the owning ASM file — never hardcode a “random free” byte for debug.
3. Document size (bytes) and owner. Multi-byte ranges must not overlap neighbors.
4. Lorom-only / unused clones (`lorom_sprites/`, `!!OliverClone/`, `Luigi_lorom.asm`) are listed only as notes; **SA-1 live** rows are authoritative for RHRv5.

---

## Baserom / shared (`shared/freeram.asm`)

| Address (lorom / SA-1) | Bytes | Name / owner |
|---|---|---|
| `$0DC3\|!addr` | 4 | Sprite scroll fix position |
| `$13E6\|!addr` | 1 | Block duplication |
| `$1487\|!addr` | 4 | Sprite scroll fix displacement |
| `$14BE\|!addr` | 1 | Triangle fix |
| `$15E8\|!addr` | 1 | Goal point reward fix |
| `$1869\|!addr` | 2 | Extended NSTL |
| `$18C5\|!addr` | 5 | Screen scrolling pipes |
| `$18E6\|!addr` | 1 | Skull raft fix |
| `$1923\|!addr` | 1 | Capespin direction |
| `$1DFD\|!addr` | 1 | ON/OFF double-hit fix |
| `$7FA400` / `$409400` | 13 | Objectool level flags |
| `$7FA450` / `$409450` | 16 | Feature toggles bank |
| `$7FA660` / `$40A660` | 300 | Dragon coin save |
| `$7FA960` / `$40A960` | 8 | Dragon coin save buffer |
| `$7FB000` | ~2–1032 | AddMusicK |
| `$7FB400` / `$40A400` | 230+ | Retry system |

Toggle bank offsets: LR scroll, statusbar, spinjump fireball, block dup, capespin dir, springboard, retry indicator (`+0`…`+6`).

---

## SA-1 live: Luigi / player / UberASM (`$41A000+`, `$41B800+`)

### `$41A000`–`$41A03F` (scattered Luigi + UberASM)

| Address | Bytes | Name | Owner |
|---|---|---|---|
| `$41A000` | 4 | mario_exgfx `!freeram` | `tools/uberasmtool/mario_exgfx/settings.asm` |
| `$41A007` | 1 | `!PlayerPosXLow` | `Luigi.asm` |
| `$41A008` | 1 | `!PlayerPosXHigh` | `Luigi.asm` |
| `$41A009` | 1 | `!PlayerSpeedX` | `Luigi.asm` |
| `$41A00A` | 1 | `!PlayerSpeedY` | `Luigi.asm` |
| `$41A00B` | 1 | `!RAM_PalUpdateFlag` | MarioTileDMA / level UberASM |
| `$41A00C` | 1 | `!Spinning` / `!LuigiSpinning` | Luigi + shells/blocks |
| `$41A00E` | 1 | `!LuigiSpeedX` | `Luigi.asm` |
| `$41A00F` | 1 | `!LuigiSpeedY` | `Luigi.asm` |
| `$41A016` | 1 | `!TeleportReady` | Luigi / PlayerCursor |
| `$41A018` | 1 | `!JumpHeld` | Luigi + blocks |
| `$41A019` | 1 | `!TempSpinning` | `Luigi.asm` |
| `$41A01A` | 1 | `!LuigiIndex` | Luigi + Key + patches |
| `$41A01C` | 1 | `!LuigiContact` | GPS Koopa/Spiny blocks |
| `$41A01E` | 1 | `!SpinDirection` | `Luigi.asm` |
| `$41A020` | 1 | `!StareTimer` | `Luigi.asm` |
| `$41A021` | 1 | `!Frozen` | Luigi + shells |
| `$41A022` | 1 | `!FreezeBlockFrozenFlag` / `!FrozenFlag` | freeze UberASM / PlayerCursor |
| `$41A023` | 1 | `!BouncingSpeed` | `Luigi.asm` |
| `$41A024` | 1 | `!PlayerOnlyStomped` | Luigi + KoopaBlock |
| `$41A025` | 1 | `!PlayerPosYLow` | `Luigi.asm` |
| `$41A026` | 1 | `!IsMario` / GFX trigger | Luigi + MarioGFX UberASM |
| `$41A027` | 1 | `!SpriteDirection` | `Luigi.asm` |
| `$41A028` | 1 | `!FramesSinceButtonPressed` | `PressurePlates.asm` |
| `$41A029` | 1 | `!OnPlatform` | `Luigi.asm` |
| `$41A02A` | 1 | `!PreviousState` | `Luigi.asm` |
| `$41A02C` | 1 | `!PlayerPosYHigh` | `PlayerCursor.asm` |
| `$41A02D` | 1 | `!TileIndex` | `PlayerCursor.asm` |
| `$41A034` | 3? | `!RAM_PlayerPalPtr` | MarioTileDMA / level UberASM |

Gaps in this page (verify before use): `$41A00D`, `$41A010`–`$41A015`, `$41A017`, `$41A01B`, `$41A01D`, `$41A01F`, `$41A02B`, `$41A02E`–`$41A033`, `$41A037`+.

> Note: `!!Luigi/Config.asm` describes a packed layout from `$41A000` that **does not match** live `Luigi.asm` hardcodes. Treat `Luigi.asm` as truth until Config is wired in.

> Note: Retry SRAM hijack also references `$41A000` — confirm interaction with mario_exgfx before reclaiming.

### `$41B82E`–`$41B838` (held items + teleport position)

| Address | Bytes | Name | Owner |
|---|---|---|---|
| `$41B82E` | 1 | `!LuigiHeldItemIndex` | Luigi held-item ownership |
| `$41B82F` | 1 | `!MarioHeldItemIndex` | Mario held-item ownership |
| `$41B830` | 1 | `!LuigiXPosLow` | teleport destination X lo |
| `$41B831` | 1 | `!LuigiXPosHigh` | teleport destination X hi |
| `$41B832` | 1 | `!LuigiYPosLow` | teleport destination Y lo |
| `$41B833` | 1 | `!LuigiYPosHigh` | teleport destination Y hi |
| `$41B834` | 1 | `!LandingTimer` | `Luigi.asm` |
| `$41B835` | 1 | `!PreviousXSpeed` | `Luigi.asm` |
| `$41B836` | 1 | `!LandingFrameCounter` | `Luigi.asm` |
| `$41B837` | 1 | `!LandingFrameIndex` | `Luigi.asm` |
| `$41B838` | 1 | `!NumFramesInsideWall` | `Luigi.asm` |
| `$41B839` | 1 | `!HeldInteractionDebug` | held-shell path: `$10` item, `$20` contact, `$30` shell, `$40` spinkill, `$41` bounce |

**Do not use `$41B830`–`$41B833` for debug** — that caused Mario to teleport offscreen on swap.

### Large backup blocks

| Address | Bytes (approx) | Name | Owner |
|---|---|---|---|
| `$41B900` | ~660 (`22×30`) | `!StartRAM` sprite freeze backup | `Luigi.asm`, `Cursor.asm` |
| `$41BB00` | 62 | `!SpriteTablesRAM` slot-swap scratch | `MoveLuigiToFront.asm` |

**Overlap warning:** `$41BB00` sits inside the `$41B900`+~`$294` freeze-backup window. Safe only if freeze backup and front-slot swap never corrupt each other in practice; do not place new long-lived freeram here. Prefer `$41BC00+` for new scratch.

### Custom triggers / other

| Address | Bytes | Name | Owner |
|---|---|---|---|
| `$7FC0FC` / `$41C0FC` | flags | Custom F / pressure-plate triggers | GPS + PressurePlates / Luigi |

---

## Suggested free ranges (SA-1 BW-RAM)

Verify with a fresh grep before claiming:

| Range | Notes |
|---|---|
| `$41B83A`–`$41B8FF` | After Luigi interaction debug, before `!StartRAM` |
| `$41BC00`+ | After freeze backup / slot-swap scratch (prefer over `$41BB00`) |
| `$41A02E`–`$41A033` | Small gaps in Luigi page (confirm unused) |

---

## Changelog

| Date | Change |
|---|---|
| 2026-07-12 | Reserved `$41B839` for held-shell interaction diagnostics. |
| 2026-07-12 | Initial registry after `$41B830` debug overwrite of `!LuigiXPosLow`. |
