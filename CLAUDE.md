# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Strange Hands** — a Godot 4.6 game featuring a node-graph-based custom spell creation and casting system. Players visually design spells in a graph editor, which are compiled into recipes and executed as 3D projectiles.

## Running the Project

Open the project in **Godot 4.6+**. The main scene is `project/MainScene.tscn`. Press Play in the Godot editor to run. There is no CLI build system — Godot handles all compilation internally (C# via Mono, GDScript natively).

CI/CD for automated builds uses `.github/workflows/build-and-publish-demo.yml`.

## In-Game Controls

- **TAB** — toggle the spell graph editor
- **LMB** — cast the spell (triggers wand animation)
- Wand animation emits `spell_cast()` signal at a specific keyframe, which fires the actual spell spawn

## Architecture

### Data Flow

```
SpellCreation.gd (graph UI)
    → emits spell_data_created(Array) on any graph change
SpellCasting.gd (spell interpreter)
    → on spell_cast() / spell_stop() signals from wand_mesh.gd
    → _schedule_spell(transform) handles delay, then calls _spawn_spell_object()
SpellBase (Node3D in world)
    → child shape nodes (shape_orb.gd, shape_beam.gd, etc.) handle collision
    → child path nodes (PathBase subclasses) handle movement
    → destroys itself after lifetime (default 5s)
```

### Spell Array Format

Spell recipes are sequential arrays of dicts. Each node in the graph contributes one entry when the wire passes through its port:
```gdscript
{"type": "casting",   "value": 0}            # enum index
{"type": "mod_float", "value": 1, "amount": 2.0}  # value = which stat, amount = multiplier
{"type": "mod_vec",   "value": 0, "amount": {"x":2,"y":2,"z":2}}
{"type": "shape",     "value": 0}
{"type": "path",      "value": 0}
{"type": "element",   "value": 2}
{"type": "effect",    "value": 3}
{"type": "trigger",   "value": 0, "child_spell": [...]}  # child_spell embedded at compile time
{"type": "spell_ref", "name": "Spell_1"}     # references a saved spell by name
```

**Trigger splitting:** `compile_spell()` calls `_split_at_triggers()` which finds the first trigger entry, embeds everything after it as `child_spell` in the trigger dict, then recurses for nested triggers. This makes the array non-linear. `_flatten_spell_array()` re-linearizes for graph reconstruction.

Persisted graph layout: `project/Scripts/Data/graph_layout_debug.json`

### Spell Globals (`Spell_Casting/Spell_Globals.gd`, autoloaded as `SpellGlobals`)

Single source of truth. Contains:
- All enums: `SpellElement`, `SpellModifierFloat`, `SpellModifierVec`, `SpellModifierInt`, `SpellModifierBool`, `SpellPath`, `SpellShape`, `SpellCasting`, `SpellEffect`, `SpellTrigger`
- `SHAPE_SCENES` — dict mapping `SpellShape` enum → preloaded `.tscn`
- `PATH_SCRIPTS` — dict mapping `SpellPath` enum → preloaded `.gd` script (applied via `Node.new()` + `set_script()`, no .tscn needed)
- `EFFECT_SCRIPTS` — dict mapping `SpellEffect` enum → preloaded `.gd` script
- `ELEMENT_COLORS` — dict mapping `SpellElement` enum → `Color`
- `MODIFIER_ITEMS: Array` — flat list of all modifiers (CastSpeed, MoveSpeed, Duration, CastForce, Delay, Size, Piercing, Ricochet, EnvPiercing, Split), each with `label`, `spell_type`, `spell_value`, `widget_type`, `default`. Used to populate the single combined Modifier row.
- `EFFECT_INPUT_TYPES: Dictionary` — maps effect enum int → `{type, default}` for the dynamic Effect row widget
- `attribute_configs` — 7-entry array driving the graph node UI. Each entry: `name`, `enum`, `color`, `id`, `input_type`. `input_type` can be `"none"`, `"float"`, `"int"`, `"bool"`, `"vec"`, `"dynamic"` (rebuilds widget per dropdown), or `"modifier"` (uses MODIFIER_ITEMS)

**Important:** Enum values from SpellGlobals cannot be used as `const` dict keys in OTHER files — they are not compile-time constants there. Use `match` statements instead, or define the dict inside SpellGlobals itself where the enums are compile-time.

### Spell Creation (`project/Scripts/Spell_Creation/`)

- `Spell_Creation.gd` — manages `GraphEdit` UI, calls `compile_spell()` on any change, saves/loads JSON. Also manages the spell library panel (top-right) with Load/Delete per entry. Panel height is dynamic via `_update_panel_size(spell_count)` clamped between `PANEL_MIN_H` and `PANEL_MAX_H`.
- `graph_node.gd` — each node has 7 rows (one per `attribute_configs` entry). Each row is a `PanelContainer` wrapping an `HBoxContainer` with: Label + OptionButton dropdown + optional input widget. Widget type depends on `input_type`: `"float"`/`"int"` → SpinBox, `"bool"` → CheckBox + ON/OFF label, `"vec"` → 3× SpinBox, `"dynamic"` → HBoxContainer rebuilt on dropdown change (Effect row), `"modifier"` → HBoxContainer rebuilt on dropdown change (uses MODIFIER_ITEMS). `highlight_port(i, on)` sets amber background on the row's PanelContainer. `OptionButton.select()` does NOT emit `item_selected` in Godot 4 — `set_dropdown_states` must explicitly call `_update_dynamic_widget` for dynamic/modifier rows.
- `spell_ref_node.gd` / `Scenes/spell_ref_node.tscn` — a GraphNode with a single slot (teal color) and a dropdown populated from `SpellLibrary`. Detected in `compile_spell()` via `has_method("get_selected_spell_name")`. Emits `{"type": "spell_ref", "name": "Spell_N"}`. `get_dropdown_states()`/`set_dropdown_states()` use the spell name string for save/load compatibility.
- `SpellLibrary.gd` (autoloaded as `SpellLibrary`) — manages `spell_library.json`. `save_spell(array)` auto-names as `Spell_N`, returns name. `delete_spell(name)`, `get_spell(name)`, `get_all_names()`. Emits `library_changed` signal so spell_ref_node dropdowns auto-refresh.
- `start_node.gd` — protected graph entry point; compilation walks outgoing wires from here

`compile_spell()` walks the graph sequentially from StartNode, calls `get_data_for_port(port_index)` on each visited node (or `get_selected_spell_name()` for SpellRefNodes), then passes through `_split_at_triggers()`.

**Graph reconstruction** (`_load_spell_to_graph`): clears graph, calls `_flatten_spell_array` (re-linearizes trigger child_spell arrays), creates a graph node per entry using `_type_to_port()` (maps type string → slot index) and `_entry_to_row_state()` (builds set_dropdown_states dict), then wires them. Node spacing uses `node.size.x + 30.0` (not a fixed pixel offset) to avoid overlapping.

### Spell Casting (`project/Scripts/Spell_Casting/Spell_Casting.gd`)

Key members:
- `our_spell_array` — raw compiled array (may contain spell_ref entries)
- `_flat_spell_array` — flattened version with spell_refs inlined; rebuilt whenever `our_spell_array` changes. Used for all runtime decisions (casting type, shape presence, self-cast firing).

Key methods:
- `_on_spell_creation_spell_data_created()` — always updates `our_spell_array` and `_flat_spell_array` even when array is empty (guards against stale data from disconnected graph). Sets `current_casting_type` from the **first** casting entry only (`and current_casting_type == -1` guard prevents spell_ref casting entries from overwriting top-level type).
- `_on_spell_cast()` — dispatches by casting type. Self types (SelfInstant/SelfToggle/SelfHold) call `_apply_self_effects()` AND `_fire_shape_for_self_cast()` if a shape is present.
- `_schedule_spell(transform)` — async; awaits Delay modifier if present, then spawns.
- `_begin_charge()` — async; awaits charge duration, cancels if `_charge_cancelled`.
- `_spawn_spell_object(transform, charge_multiplier, spell_array?)` — modifier first pass (mod_float/mod_int/mod_vec/mod_bool → SpellBase stats), then component pass (shape/path/element), then `new_spell.scale = new_spell.scale_mult`. Accepts optional `spell_array` override for trigger child spawning. Guards with `has_shape` — if no shape attached, frees SpellBase and returns null. Sets `is_child_spell = not spell_array.is_empty()` to distinguish child vs top-level spawns. Child spells call `_apply_child_spell_effects(spell_array, spawn_transform)` after spawning.
- `_apply_self_effects(is_toggle)` — for SelfInstant/SelfToggle; reads only "effect" entries. SelfToggle uses `has(effect_value)` alone as the "on" state to avoid one-shot effects re-triggering on every cast.
- `_apply_hold_effects()` / `_on_spell_stop()` — for SelfHold; effects live while mouse is held.
- `_apply_child_spell_effects(arr, hit_transform)` — applies ALL effect entries from a child spell array to the player. No self-cast-type guard (child spells never have a top-level casting node). Sets `node.set("hit_position", hit_transform.origin)` before `add_child` for effects that need the world-space hit point (e.g. TeleportToHit).
- `_apply_modifiers(arr, spell)` — first pass over a spell array; writes mod_float/mod_vec/mod_bool values onto the SpellBase stat fields. Uses `int(component["value"])` before match to handle JSON float values correctly.
- `_attach_components(arr, spell) -> bool` — second pass; instantiates shape scenes, path scripts, sets element/trigger. Returns true if at least one shape was attached.
- `_make_effect_node(ev, component, dur) -> Node` — creates an effect node, sets script/player_root/duration/amount before returning it (caller does `add_child`).
- `_find_mod(type_str, value) -> Dictionary` — scans `_flat_spell_array` for the first entry matching type and int value. Used by `_get_duration_mult`, `_get_cast_delay`, `_get_split_count`.
- `_respawn_dead_effects(effects)` — re-fires any one-shot effects (e.g. ThrowLook) that freed themselves while still tracked. Shared by `_on_hold_repeat_timeout` and `_on_toggle_repeat_timeout`.
- `_fire_shape_for_self_cast()` — fires a projectile when a Self casting type is combined with a shape. Reads `_get_shape_firing_type()` (second casting entry in `_flat_spell_array`) to pick Burst/Continuous/ChargeUp behavior.
- `_array_has_shape(arr)` — returns true if any entry in arr has type "shape".

Casting types implemented: `Burst`, `Continous`, `SelfInstant`, `SelfToggle`, `ChargeUp`, `SelfHold`

`Delay` is a `SpellModifierFloat` (not a casting type). `_schedule_spell` awaits its value before spawning — transform is captured at schedule time.

`Split` (`mod_int`, value 0) fires `split_count` projectiles in a fan. Each is rotated by `SPLIT_ANGLE_STEP_DEG * t` around Y and offset by `SPLIT_POS_OFFSET * t` along the camera-right axis, centred around t=0.

`CastSpeed` (`mod_float`, value 0) sets `wand.cast_speed` (animation speed) and `fire_rate_timer.wait_time = BASE_FIRE_RATE / cast_speed`.

`_apply_effect_amount(node, component)` — uses `node.set("amount", value)` or `node.set("amount_vec", Vector3(...))` to set effect parameters before `add_child`, supporting the `var amount` pattern in effect scripts.

### Spell Objects (`project/Scripts/Spell_Stuff/`)

**`Spell_Base.gd`** (`class_name SpellBase`, extends Node3D)
- Stats: `damage`, `speed`, `lifetime` (5s default, self-destructs via `_ready()` timer), `element`, `scale_mult`, `is_piercing`, `does_ricochet`, `is_environment_piercing`, `has_trail`
- Trigger system: `trigger_type: int`, `timer_trigger_interval: float`, `child_spell_array: Array`, `spawn_child: Callable`. `fire_trigger(type, xform)` checks type/array/callable validity then calls `spawn_child.call(child_spell_array, xform)`. Called by `_ready()` (OnEnd) and by shape scripts (OnHit) before destroying.
- `end_spell(xform)` — guarded by `_ended` flag to prevent double-fire; fires OnEnd trigger, then `queue_free()`.

**`ShapeBase`** (`shape_base.gd`, extends Area3D, child of SpellBase)
- Base class for all shapes. `_ready()`: resolves `parent_spell`, connects `body_entered`, calls `_apply_element_color()`.
- All shape hit handlers call `body.take_damage(parent_spell.damage)` via duck-typing (`has_method("take_damage")`) — applies to all non-StaticBody3D hits across every shape type.
- `_do_ricochet()` — ray-cast for surface normal, reflect the parent spell's basis, 0.1s cooldown flag.

**`shape_orb.gd`** (extends ShapeBase)
- Collision routing: StaticBody3D + `does_ricochet` → `_do_ricochet()`; StaticBody3D + `is_environment_piercing` → pass through; StaticBody3D otherwise → `end_spell()`; non-static + `is_piercing` → damage but continue; non-static otherwise → damage + `end_spell()`.
- On `_ready()`: reads `parent_spell.element`, duplicates mesh material, sets `albedo_color`.
- Does NOT move — movement is the path's job.

**`shape_beam.gd`** (extends ShapeBase)
- Overrides `_apply_element_color()` to also set `dup.emission = color` so the beam glows with element colour.
- Overrides `_on_body_entered()` — uses `_hit_transform(body)` to fire triggers at the correct point on the beam axis rather than the wand origin.
- `_hit_transform(body)` — projects `body.global_position` onto the beam axis (dot product), clamped 0..`BEAM_LENGTH`, returns a `Transform3D` at that world point. Critical for OnHit trigger positioning.

**`shape_explode.gd`** (extends ShapeBase) — grows from scale 0 over `GROW_DURATION`, then calls `get_overlapping_bodies()` at full size. Disconnects `body_entered` in `_ready()`.

**`shape_cone.gd`** (extends ShapeBase) — programmatic CylinderMesh cone; dot-product filter limits hits to `CONE_HALF_ANGLE_COS` arc.

**`shape_aoe.gd`** (extends ShapeBase) — snaps to ground each physics frame; tracks `_hit_bodies` to hit each enemy once.

**`shape_wall.gd`** (extends ShapeBase) — snaps to ground on spawn, pins in place (top_level), tracks `_hit_bodies`; does not destroy on hit.

**Path scripts** (`Spell_Stuff/Paths/`, all extend `PathBase`)
- `PathBase` (`path_base.gd`) — base class; holds `parent_spell: SpellBase`, resolves it in `_ready()`
- `path_line_of_sight` — straight forward along -Z
- `path_curve_path` — arcs left or right (randomly chosen at spawn)
- `path_zig_zag_line_of_sight` — triangular wave side-to-side
- `path_upwards` — straight up
- `path_homing` — steers toward nearest node in `"enemies"` group
- `path_boomerang` — flies outward for `parent_spell.lifetime * OUTWARD_FRACTION`, returns to spawn point, destroys spell. Reads forward direction live each frame during outward phase (so ricochet rotations are respected)

**Direction init timing:** Path scripts that need to capture `forward`/`right` from the spell's transform must do so lazily in `_physics_process` (using an `initialized` flag), NOT in `_ready()` — because `_ready()` fires before `new_spell.global_transform = spawn_transform` is set in Spell_Casting.

**Effect scripts** (`Spell_Stuff/Effects/`, all extend `EffectBase`)
- `EffectBase` (`effect_base.gd`) — base class; holds `player_root`, `duration` (5s default; -1 = permanent), `real_time_duration: bool` (false by default). `_ready()` starts cleanup timer via `get_tree().create_timer(duration, true, false, real_time_duration)`. Subclasses apply their effect then call `super()` in `_ready()`, and override `remove_effect()` to reverse. `remove_effect()` base impl is a no-op — **callers always call `queue_free()` after it**. Subclasses must not call `queue_free()` inside their `remove_effect()` override.
- `SlowMo` — sets `real_time_duration = true` before `super()` so its timer ignores the slowed time scale.
- `ThrowLook` / `ThrowRandom` — one-shot effects; set `player_root.velocity` in `_ready()` then `queue_free()` directly (no timer). ThrowLook uses camera -Z direction; ThrowRandom uses a random horizontal+upward direction.
- `RandomTeleport` — one-shot; moves `player_root.global_position` to a random point within radius `amount`. Uses `sqrt(randf())` for uniform distribution inside the circle.
- `TeleportToHit` — one-shot; moves `player_root.global_position` to `hit_position` (set via `node.set("hit_position", ...)` by Spell_Casting before `add_child`). Canonical usage: `Orb → LineOfSight → OnHit → TeleportToHit` — the OnHit trigger fires the child spell at the impact point, which then applies TeleportToHit as an effect.
- All effect scripts use `var amount: float` or `var amount_vec: Vector3` (set via `node.set("amount", value)` from Spell_Casting before `add_child`) rather than constants, so values are editable from the graph.
- Implemented: `MoveSpeed`, `SlowMo`, `Gravity`, `Levitation`, `ThrowLook`, `ThrowRandom`, `Scale` (scales `MeshInstance3D` child), `Poison` (async tick loop calling `player_root.HealthSystem.TakeDamage(amount)`), `RandomTeleport`, `TeleportToHit`
- Stubbed: `Thorns`, `Invincibility`

**C# interop note:** `CharacterBody3D.velocity` is snake_case in GDScript even though C# spells it `Velocity`. Same for `Vector3` components (`x/y/z` not `X/Y/Z`). Custom C# properties (`WalkSpeed`, `SprintSpeed`, `Gravity.Weight`) keep their PascalCase.

### Training Dummies (`project/Scripts/training_dummy.gd`, `project/Scripts/TrainingDummy.tscn`)

- `CharacterBody3D` (not StaticBody3D — shapes treat CharacterBody3D as a hittable enemy)
- Added to `"enemies"` group in `_ready()` so path_homing targets them
- `take_damage(amount)` — reduces HP, flashes mesh orange, calls `_spawn_damage_label(amount)`
- `_spawn_damage_label(amount)` — creates a `Label3D` with billboard mode, positions it above the dummy, animates upward float + fade via `Tween`, then removes it
- `_on_death()` — resets HP to MAX_HP (dummies respawn in place rather than disappearing)
- 5 dummies placed in MainScene: Dummy_Left(-3,0,-5), Dummy_Center(0,0,-5), Dummy_Right(3,0,-5), Dummy_PierceLine1(0,0,-3), Dummy_PierceLine2(1,0,-7) — spread for testing piercing and AoE

### Addon: Player Controller

`project/addons/player_controller/` — C# `PlayerController : CharacterBody3D`. Key accessible properties from GDScript: `WalkSpeed`, `SprintSpeed`, `Gravity.Weight`, `velocity`. The wand mesh lives as a child under `Head/CameraSmooth/Camera3D/WandMesh` and communicates via signals.

### Addon: Maaack's Game Template

`project/addons/maaacks_game_template/` — provides main menu, pause screen, options, scene loading, music/UI sound autoloads. Treat as a black box unless modifying menus.
