# The Hollow Mine

An original 16-bit-style side-scrolling platformer for **Godot 4.7**. Guide Wick, a young
miner with a brass helmet lamp, through an abandoned gothic mineshaft to the daylight exit.

All art, sound and music are generated procedurally by scripts in `tools/`; nothing is downloaded.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | Arrow keys / A, D | D-pad / left stick |
| Jump (hold for higher) | Space / Z / K / W / Up | A |
| Drop through wooden planks | Down + Jump | Down + A |
| Pause | Esc / P | Start |
| Menu select / confirm | Up/Down, Enter / Space / Z | D-pad, A |

## Rules

- **Stomp enemies** by landing on them from above. Touching an enemy from the side or below costs a heart.
- Consecutive stomps without landing score 100, 200, 400, 800, 1600.
- You have **3 hearts** and **3 lives**. Pits are instant death; losing a life respawns you at the last checkpoint.
- **Checkpoints** are spirit-lantern posts. Touch one to light it, set your respawn point and refill your hearts.
- Hazards: iron spikes, falling stalactites (they shake before dropping), bottomless pits.
- Collect ember-ore gems (+50). Hearts restore health (+500 if already full).
- Reach the glowing exit gate at the far right for **Stage Clear**, which awards a time bonus, a lives bonus and +5000 for collecting every gem.

### Enemies

- **Rustback**: a slow dome-shelled crawler that patrols and turns at walls and ledges.
- **Shalehop**: a crystal-backed slate creature that crouches, then hops toward you. It won't jump into pits.
- **Gloomwing**: a moth-like flyer with a glowing abdomen that swoops down when you pass beneath it.

## Running

**From the Godot editor:** open Godot 4.7 → *Import* → pick this folder's `project.godot` →
*Import & Edit* → press **F5** (Run Project). The main scene is `scenes/title.tscn`.
To jump straight into the level, open `scenes/game.tscn` and press **F6** (Run Current Scene).

**From the command line:**

```
Godot_v4.7.2-stable_win64_console.exe --path "C:\Users\blake\OneDrive\Desktop\Claude Apps\ClintGame"
```

## Project layout

```
project.godot          384x216 internal resolution, integer-scaled, nearest filtering, pixel snap, HDR 2D
scenes/                title.tscn, game.tscn (stage), player.tscn
scripts/               game_state.gd (autoload "Game"), player.gd, level.gd (builder + auto-tiling),
                       level_layout.gd (the stage design), parallax.gd, atmosphere.gd (lighting/glow/dust),
                       entities/ (enemies, hazards, pickups, props), ui/ (HUD, menus, results)
tools/                 procedural asset generators + autotest.gd (scripted tests)
assets/                generated PNGs and WAVs
```

## Regenerating assets

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/gen_art.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . --import
```

## Automated tests

Scenarios live in `tools/autotest.gd` and run headless:

```
Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . res://scenes/game.tscn -- --autotest=enemies
```

Available scenarios: `player`, `level`, `enemies` (stomp vs. side/below contact, spikes, rocks, lives),
`routes` (plank climb and both lift crossings with scripted inputs), `ui` (pause, game over),
`clear` (stage clear and replay), `bot` (end-to-end playthrough bot; add `--god` to ignore enemies),
and `title` (run with `res://scenes/title.tscn`).
