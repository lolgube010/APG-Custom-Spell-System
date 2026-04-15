# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Strange Hands** — a Godot 4.6 game featuring a node-graph-based custom spell creation and casting system. Players visually design spells in a graph editor, which are compiled into recipes and executed as 3D projectiles.

## Running the Project

Open the project in **Godot 4.6+**. The main scene is `project/MainScene.tscn`. Press Play in the Godot editor to run. There is no CLI build system — Godot handles all compilation internally (C# via Mono, GDScript natively).

CI/CD for automated builds uses `.github/workflows/build-and-publish-demo.yml`.

## In-Game Controls

- **TAB** — toggle the spell graph editor (blocked while SelfHold is active)
- **LMB** — cast the spell (triggers wand animation)
- Wand animation emits `spell_cast()` signal at a specific keyframe, which fires the actual spell spawn

## Architecture

### Directory Structure

```
project/Scripts/
    UI/             — SpellCreation.gd, Spell_Library.gd, graph_node.gd, spell_ref_node.gd, start_node.gd
    Spell/          — Spell_Base.gd, Spell_Casting.gd, Spell_Factory.gd, Spell_Globals.gd, wand_mesh.gd
    Spell/Effects/  — effect_base.gd + all effect scripts
    Spell/Paths/    — path_base.gd + all path scripts
    Spell/Shapes/   — shape_base.gd + all shape scripts
    Spell/Modifiers/— Trail_Component.gd
    World/          — training_dummy.gd
project/Data/       — graph_layout_debug.json, spell_library.json  (persisted graph/library state)
project/Scenes/     — .tscn files for GraphNodes, SpellCreation, TrainingDummy
```

### Data Flow

```
SpellCreation.gd (graph UI)
    → emits spell_data_created(Array) on any graph change
Spell_Casting.gd (casting controller)
    → on spell_cast() / spell_stop() signals from wand_mesh.gd
    → delegates all object creation to SpellFactory
SpellFactory (spell assembler)
    → _apply_modifiers → _attach_components → spawn into scene
SpellBase (Node3D in world)
    → child shape nodes handle collision
    → child path nodes handle movement
    → destroys itself after lifetime (default 5s)
```

### Spell Array Format

Spell recipes are sequential arrays of dicts. Each node in the graph contributes one entry when the wire passes through its port:
```gdscript
{"type": "casting",   "value": 0}
{"type": "mod_float", "value": 1, "amount": 2.0}   # value = SpellModifierFloat enum index
{"type": "mod_int",   "value": 0, "amount": 2}     # value = SpellModifierInt enum index
{"type": "mod_vec",   "value": 0, "amount": {"x":2,"y":2,"z":2}}
{"type": "mod_bool",  "value": 0, "amount": true}
{"type": "shape",     "value": 0}
{"type": "path",      "value": 0}
{"type": "element",   "value": 2}
{"type": "effect",    "value": 3}
{"type": "trigger",   "value": 0, "child_spell": [...]}  # child_spell embedded at compile time
{"type": "spell_ref", "name": "Spell_1"}
```

**Trigger splitting:** `compile_spell()` calls `_split_at_triggers()` which finds the first trigger entry, embeds everything after it as `child_spell` in the trigger dict, then recurses for nested triggers. `_flatten_spell_array()` re-linearizes for graph reconstruction.

### Spell Globals (`Spell/Spell_Globals.gd`, autoloaded as `SpellGlobals`)

Single source of truth. Contains:
- All enums: `SpellElement`, `SpellModifierFloat`, `SpellModifierVec`, `SpellModifierInt`, `SpellModifierBool`, `SpellPath`, `SpellShape`, `SpellCasting`, `SpellEffect`, `SpellTrigger`
- `SHAPE_SCENES` — dict mapping `SpellShape` enum → preloaded `.tscn`
- `PATH_SCRIPTS` — dict mapping `SpellPath` enum → preloaded `.gd` (applied via `Node.new()` + `set_script()`)
- `EFFECT_SCRIPTS` — dict mapping `SpellEffect` enum → preloaded `.gd`
- `ELEMENT_COLORS` — dict mapping `SpellElement` enum → `Color`
- `MODIFIER_ITEMS: Array` — flat list used to populate the Modifier row in the graph node. Each entry: `label`, `spell_type`, `spell_value`, `widget_type`, `default`. Current modifiers: CastSpeed, MoveSpeed, Duration, CastForce, Delay, Size, Piercing, Ricochet, EnvPiercing, Split, Trail.
- `EFFECT_INPUT_TYPES: Dictionary` — maps effect enum int → `{type, default}` for the Effect row widget
- `TRIGGER_INPUT_TYPES: Dictionary` — maps trigger enum int → `{type, default}` (OnTimer has a float amount input)
- `DEFAULT_EFFECT_DURATION: float` — 5.0
- `attribute_configs` — 7-entry array driving the graph node UI (order: Element, Modifier, Path, Shape, Casting, Effect, Trigger). Each entry: `name`, `enum`, `color`, `id`, `input_type`. `input_type` can be `"none"`, `"float"`, `"int"`, `"bool"`, `"vec"`, `"dynamic"` (rebuilds widget per dropdown, used for Effect and Trigger rows; requires `value_input_types` key), or `"modifier"` (uses MODIFIER_ITEMS).

**Important:** Enum values from SpellGlobals cannot be used as `const` dict keys in OTHER files — they are not compile-time constants there. Use `match` statements instead, or define the dict inside SpellGlobals itself where the enums are compile-time.

### Spell Creation (`project/Scripts/UI/`)

- `Spell_Creation.gd` — manages `GraphEdit` UI, calls `compile_spell()` on any change, saves/loads JSON. Also manages the spell library panel (top-right) with Load/Delete per entry. Panel height is dynamic via `_update_panel_size(spell_count)` clamped between `PANEL_MIN_H` and `PANEL_MAX_H`.
- `graph_node.gd` — each node has 7 rows (one per `attribute_configs` entry). Each row is a `PanelContainer` wrapping an `HBoxContainer` with: Label + OptionButton dropdown + optional input widget. `highlight_port(i, on)` sets amber background on the row's PanelContainer. `OptionButton.select()` does NOT emit `item_selected` in Godot 4 — `set_dropdown_states` must explicitly call `_update_dynamic_widget` for dynamic/modifier rows.
- `spell_ref_node.gd` / `Scenes/spell_ref_node.tscn` — a GraphNode with a single slot (teal color) and a dropdown populated from `SpellLibrary`. Detected in `compile_spell()` via `has_method("get_selected_spell_name")`. `get_dropdown_states()`/`set_dropdown_states()` use the spell name string for save/load compatibility.
- `Spell_Library.gd` (autoloaded as `SpellLibrary`) — manages `spell_library.json`. `save_spell(array)` auto-names as `Spell_N`, returns name. `delete_spell(name)`, `get_spell(name)`, `get_all_names()`. Emits `library_changed` signal so spell_ref_node dropdowns auto-refresh.
- `start_node.gd` — protected graph entry point; compilation walks outgoing wires from here

`compile_spell()` walks the graph sequentially from StartNode, calls `get_data_for_port(port_index)` on each visited node (or `get_selected_spell_name()` for SpellRefNodes), then passes through `_split_at_triggers()`.

**Graph reconstruction** (`_load_spell_to_graph`): clears graph, calls `_flatten_spell_array` (re-linearizes trigger child_spell arrays), creates a graph node per entry using `_type_to_port()` (maps type string → slot index) and `_entry_to_row_state()` (builds set_dropdown_states dict), then wires them. Node spacing uses `node.size.x + 30.0` to avoid overlapping.

### Spell Casting (`project/Scripts/Spell/Spell_Casting.gd`)

Key members:
- `our_spell_array` — raw compiled array (may contain spell_ref entries)
- `_flat_spell_array` — pre-flattened via `SpellFactory.flatten_spell_refs()`; rebuilt whenever `our_spell_array` changes
- `_mod_lookup: Dictionary` — `"type_strN" → component dict`; O(1) modifier lookups
- `_effect_lookup: Dictionary` — `effect_value int → component dict`; O(1) effect lookups
- `_factory: SpellFactory` — owned child node; all spell object assembly delegated here

Key methods:
- `_on_spell_creation_spell_data_created()` — always rebuilds `_flat_spell_array`, `_mod_lookup`, `_effect_lookup`, and `current_casting_type`. Sets `current_casting_type` from the **first** casting entry only (`current_casting_type == -1` guard prevents spell_ref casting entries from overwriting top-level type).
- `_on_spell_cast()` — dispatches by casting type. Self types (SelfInstant/SelfToggle/SelfHold) call `_apply_self_effects()` AND `_fire_shape_for_self_cast()` if a shape is present.
- `_schedule_spell(transform, charge_multiplier)` — async; awaits Delay modifier if present, then spawns split fan via `_factory.spawn()`.
- `_begin_charge()` — async; awaits charge duration, cancels if `_charge_cancelled`.
- `_apply_self_effects(is_toggle)` — for SelfInstant/SelfToggle; reads only "effect" entries. SelfToggle uses `has(effect_value)` alone as the "on" state.
- `_apply_hold_effects()` / `_on_spell_stop()` — for SelfHold; effects live while mouse is held.
- `_respawn_dead_effects(effects)` — re-fires one-shot effects that freed themselves while still tracked. Shared by `_on_hold_repeat_timeout` and `_on_toggle_repeat_timeout`.
- `_fire_shape_for_self_cast()` — fires a projectile when Self casting type is combined with a shape. Reads `_get_shape_firing_type()` (second casting entry in `_flat_spell_array`) to pick Burst/Continuous/ChargeUp behavior.
- `is_hold_casting() -> bool` — used by `main_scene.gd` to block the graph editor from opening during SelfHold.
- `_find_mod(type_str, value) -> Dictionary` — O(1) lookup via `_mod_lookup`.

Casting types implemented: `Burst`, `Continous`, `SelfInstant`, `SelfToggle`, `ChargeUp`, `SelfHold`

`Delay` is a `SpellModifierFloat`. `_schedule_spell` awaits its value before spawning — transform is captured at schedule time.

`Split` (`mod_int`, value 0) fires `split_count` projectiles in a fan. Each is rotated by `SPLIT_ANGLE_STEP_DEG * t` around Y and offset by `SPLIT_POS_OFFSET * t` along camera-right, centred around t=0.

`CastSpeed` (`mod_float`, value 0) sets `wand.cast_speed` (animation speed) and `fire_rate_timer.wait_time = BASE_FIRE_RATE / cast_speed`.

### Spell Factory (`project/Scripts/Spell/Spell_Factory.gd`)

`SpellFactory` (`class_name SpellFactory`, extends Node) — owned by `Spell_Casting`; handles all spell object assembly and spawning. `player_root` is set after instantiation.

Key methods:
- `spawn(spell_array, spawn_transform, charge_multiplier, is_child, hit_body) -> Node3D` — the main entry. Calls `flatten_spell_refs()`, then `_apply_modifiers` + `_attach_components`. If `is_child`, calls `_apply_child_effects()` before the shape guard. Sets `global_transform` and `scale` after `add_child`. Returns `null` if no shape was attached.
  - **Continuous child spells:** if `is_child` and the child array contains a `Continous` casting entry, calls `_run_continuous_child()` instead of normal spawn (repeats the shape at the hit point for `CONTINUOUS_DURATION` seconds).
- `make_effect_node(ev, component, dur) -> Node` — creates an effect node, sets `target = player_root`, `caster = player_root`, `duration`, and amount fields before returning (caller does `add_child`).
- `flatten_spell_refs(arr) -> Array` — static; inlines `spell_ref` entries from SpellLibrary and recursively flattens `child_spell` arrays.
- `array_has_shape(arr) -> bool` — static helper.
- `_apply_child_effects(arr, hit_transform, hit_body)` — applies effect entries from a child spell array. Uses `node.get("target_self") == true` to decide whether the effect targets the caster or the `hit_body`. Sets `hit_position` before `add_child` for effects that need the world-space hit point (e.g. TeleportToHit).

**Effect targeting:** `EffectBase` now has `target: Node3D` (the entity being affected — may be `hit_body` for non-self effects) and `caster: Node3D` (always the player). Effects with `var target_self: bool = true` always target the caster regardless of `hit_body`.

### Spell Objects (`project/Scripts/Spell/`)

**`Spell_Base.gd`** (`class_name SpellBase`, extends Node3D)
- Stats: `damage`, `speed`, `lifetime` (5s default), `element`, `scale_mult`, `cast_force`, `is_piercing`, `does_ricochet`, `is_environment_piercing`, `has_trail`
- Trigger system: `trigger_type: int`, `timer_trigger_interval: float`, `child_spell_array: Array`, `spawn_child: Callable`. `fire_trigger(type, xform)` checks type/array/callable validity then calls `spawn_child.call(child_spell_array, xform)`. Called by `_ready()` (OnEnd) and by shape scripts (OnHit) before destroying.
- `end_spell(xform)` — guarded by `_ended` flag to prevent double-fire; fires OnEnd trigger, then `queue_free()`.

**`ShapeBase`** (`shape_base.gd`, extends Area3D, child of SpellBase)
- Base class for all shapes. `_ready()`: resolves `parent_spell`, connects `body_entered`, calls `_apply_element_color()`.
- All shape hit handlers call `body.take_damage(parent_spell.damage)` via duck-typing (`has_method("take_damage")`).
- `_do_ricochet()` — ray-cast for surface normal, reflect the parent spell's basis, 0.1s cooldown flag. Override point: `shape_projectile` overrides to reflect its tracked `_velocity` vector instead.
- `_cast_ricochet_ray(dir)` — shared helper used by ricochet overrides.

**`shape_orb.gd`** (extends ShapeBase)
- Collision routing: StaticBody3D + `does_ricochet` → `_do_ricochet()`; StaticBody3D + `is_environment_piercing` → pass through; StaticBody3D otherwise → `end_spell()`; non-static + `is_piercing` → damage but continue; non-static otherwise → damage + `end_spell()`.
- Does NOT move — movement is the path's job.

**`shape_beam.gd`** (extends ShapeBase)
- Overrides `_apply_element_color()` to also set `dup.emission = color`.
- `_hit_transform(body)` — projects `body.global_position` onto the beam axis (dot product), clamped 0..`BEAM_LENGTH`. Critical for OnHit trigger positioning at the correct point on the beam.

**`shape_explode.gd`** (extends ShapeBase) — grows from scale 0 over `GROW_DURATION`, then calls `get_overlapping_bodies()` at full size.

**`shape_cone.gd`** (extends ShapeBase) — programmatic CylinderMesh cone; dot-product filter limits hits to `CONE_HALF_ANGLE_COS` arc.

**`shape_aoe.gd`** (extends ShapeBase) — snaps to ground each physics frame; tracks `_hit_bodies` to hit each enemy once.

**`shape_wall.gd`** (extends ShapeBase) — snaps to ground on spawn, pins in place (top_level), tracks `_hit_bodies`; does not destroy on hit.

**`shape_projectile.gd`** (extends ShapeBase) — self-propelled projectile with arc gravity. Lazy-initializes `_velocity` from the spell's `-Z` axis × `speed × cast_force` on the first physics tick. Applies `GRAVITY` each frame and performs a CCD sweep ray to catch collisions at high speed. Overrides `_do_ricochet()` to reflect `_velocity` instead of the spell's facing.

**`shape_gravity_projectile.gd`** (extends ShapeBase) — gravity well: pulls all nearby bodies toward it each physics frame using `apply_central_force` (RigidBody3D) or direct `velocity` manipulation (CharacterBody3D). Has a `SPAWN_GRACE` period to avoid immediately affecting the caster's own collision. On body exit, zeros the horizontal velocity of CharacterBody3D so the player doesn't drift.

**`Trail_Component.gd`** (`Spell/Modifiers/Trail_Component.gd`, extends Node) — attached to SpellBase when `has_trail = true`. Implements an object pool (size 10) of trail orbs to avoid GC pressure: each slot is a `MeshInstance3D` + `Area3D` pair that is repositioned and reset rather than freed. Orbs are `top_level` children so they stay in world space. Each orb fades and shrinks via Tween, and its Area3D can fire OnHit triggers.

**Path scripts** (`Spell/Paths/`, all extend `PathBase`)
- `PathBase` — holds `parent_spell: SpellBase`, resolves in `_ready()`
- `path_line_of_sight` — straight forward along -Z
- `path_curve_path` — arcs left or right (randomly chosen at spawn)
- `path_zig_zag_line_of_sight` — triangular wave side-to-side
- `path_upwards` — straight up
- `path_homing` — steers toward nearest node in `"enemies"` group
- `path_boomerang` — flies outward for `parent_spell.lifetime * OUTWARD_FRACTION`, returns to spawn point, destroys spell

**Direction init timing:** Path scripts that capture `forward`/`right` from the spell's transform must do so lazily in `_physics_process` (using an `initialized` flag), NOT in `_ready()` — because `_ready()` fires before `new_spell.global_transform = spawn_transform` is set. Same applies to `shape_projectile.gd`.

**Effect scripts** (`Spell/Effects/`, all extend `EffectBase`)
- `EffectBase` — base class; holds `target: Node3D` (the affected entity), `caster: Node3D` (always the player), `duration` (-1 = permanent), `real_time_duration: bool`, `is_one_shot: bool`. `_ready()` starts a cleanup timer unless `is_one_shot = true`. Subclasses apply their effect then call `super()` in `_ready()`, and override `remove_effect()` to reverse. Callers always call `queue_free()` after `remove_effect()`. Subclasses must NOT call `queue_free()` inside their `remove_effect()` override.
- `SlowMo` — sets `real_time_duration = true` before `super()` so its timer ignores the slowed time scale.
- `ThrowLook` / `ThrowRandom` — set `is_one_shot = true`; apply velocity in `_ready()` then call `queue_free()` directly.
- `RandomTeleport` — one-shot; moves `target.global_position` to a random point within radius `amount`. Uses `sqrt(randf())` for uniform distribution.
- `TeleportToHit` — one-shot; moves `caster.global_position` to `hit_position` (set by SpellFactory before `add_child`). Has `target_self = true`. Canonical usage: `Orb → LineOfSight → OnHit → TeleportToHit`.
- All effect scripts use `var amount: float` or `var amount_vec: Vector3` (set via `node.set("amount", value)` from SpellFactory before `add_child`).
- Implemented: `MoveSpeed`, `SlowMo`, `Gravity`, `Levitation`, `ThrowLook`, `ThrowRandom`, `Scale`, `Poison`, `RandomTeleport`, `TeleportToHit`
- Stubbed: `Thorns`, `Invincibility`

**C# interop note:** `CharacterBody3D.velocity` is snake_case in GDScript even though C# spells it `Velocity`. Same for `Vector3` components (`x/y/z` not `X/Y/Z`). Custom C# properties (`WalkSpeed`, `SprintSpeed`, `Gravity.Weight`) keep their PascalCase.

### Training Dummies (`project/Scripts/World/training_dummy.gd`)

- `CharacterBody3D` added to `"enemies"` group in `_ready()` so path_homing targets them
- `take_damage(amount)` — reduces HP, flashes mesh orange, spawns a floating `Label3D` damage number
- `_on_death()` — resets HP to MAX_HP (dummies respawn in place)
- 5 dummies placed in MainScene spread for testing piercing and AoE

### Addon: Player Controller

`project/addons/player_controller/` — C# `PlayerController : CharacterBody3D`. Key accessible properties from GDScript: `WalkSpeed`, `SprintSpeed`, `Gravity.Weight`, `velocity`. The wand mesh lives under `Head/CameraSmooth/Camera3D/WandMesh`.

### Addon: Maaack's Game Template

`project/addons/maaacks_game_template/` — provides main menu, pause screen, options, scene loading, music/UI sound autoloads. Treat as a black box unless modifying menus.
