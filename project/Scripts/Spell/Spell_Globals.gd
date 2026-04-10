extends Node

enum SpellElement     { FIRE, ICE, LIGHTNING, ARCANE }
enum SpellModifierFloat { CastSpeed, MoveSpeed, Duration, CastForce, Delay }
enum SpellModifierInt   { Split }
enum SpellModifierVec   { Size }
enum SpellModifierBool  { Piercing, Ricochet, EnvironmentPiercing, Trail }
enum SpellPath    { LineOfSight, CurvePath, SigZagLineOfSight, Upwards, Homing, Boomerang }
enum SpellShape   { Orb, AOE, Beam, Explode, Cone, Wall, GravityProjectile, Projectile }
enum SpellCasting { Burst, Continous, SelfInstant, SelfToggle, ChargeUp, SelfHold }
enum SpellEffect  { Scale, MoveSpeed, SlowMo, Levitation, ThrowLook, Poison, Thorns, Invincibilty, Gravity, ThrowRandom, RandomTeleport, TeleportToHit }
enum SpellTrigger { OnHit, OnEnd, OnTimer, OnKill }

const ELEMENT_COLORS: Dictionary = {
	SpellElement.FIRE:      Color(1.0, 0.25, 0.0),
	SpellElement.ICE:       Color(0.2,  0.85, 1.0),
	SpellElement.LIGHTNING: Color(1.0, 0.95, 0.1),
	SpellElement.ARCANE:    Color(0.65, 0.0,  1.0),
}

const SHAPE_SCENES: Dictionary = {
	SpellShape.Orb:               preload("res://Scripts/Spell/Shapes/Shape_Orb.tscn"),
	SpellShape.AOE:               preload("res://Scripts/Spell/Shapes/Shape_AOE.tscn"),
	SpellShape.Beam:              preload("res://Scripts/Spell/Shapes/Shape_Beam.tscn"),
	SpellShape.Explode:           preload("res://Scripts/Spell/Shapes/Shape_Explode.tscn"),
	SpellShape.Cone:              preload("res://Scripts/Spell/Shapes/Shape_Cone.tscn"),
	SpellShape.Wall:              preload("res://Scripts/Spell/Shapes/Shape_Wall.tscn"),
	SpellShape.GravityProjectile: preload("res://Scripts/Spell/Shapes/Shape_GravityProjectile.tscn"),
	SpellShape.Projectile:        preload("res://Scripts/Spell/Shapes/Shape_Projectile.tscn"),
}

const PATH_SCRIPTS: Dictionary = {
	SpellPath.LineOfSight:       preload("res://Scripts/Spell/Paths/path_line_of_sight.gd"),
	SpellPath.CurvePath:         preload("res://Scripts/Spell/Paths/path_curve_path.gd"),
	SpellPath.SigZagLineOfSight: preload("res://Scripts/Spell/Paths/path_zig_zag_line_of_sight.gd"),
	SpellPath.Upwards:           preload("res://Scripts/Spell/Paths/path_upwards.gd"),
	SpellPath.Homing:            preload("res://Scripts/Spell/Paths/path_homing.gd"),
	SpellPath.Boomerang:         preload("res://Scripts/Spell/Paths/path_boomerang.gd"),
}

# Flat list of every modifier with its spell-array type/value and graph widget metadata.
# Used to populate the combined Modifier row in the graph node.
const MODIFIER_ITEMS: Array = [
	{"label": "Cast Speed",   "spell_type": "mod_float", "spell_value": 0, "widget_type": "float", "default": 1.0},
	{"label": "Move Speed",   "spell_type": "mod_float", "spell_value": 1, "widget_type": "float", "default": 1.0},
	{"label": "Duration",     "spell_type": "mod_float", "spell_value": 2, "widget_type": "float", "default": 1.0},
	{"label": "Cast Force",   "spell_type": "mod_float", "spell_value": 3, "widget_type": "float", "default": 1.0},
	{"label": "Delay",        "spell_type": "mod_float", "spell_value": 4, "widget_type": "float", "default": 2.0},
	{"label": "Size",         "spell_type": "mod_vec",   "spell_value": 0, "widget_type": "vec",   "default": 1.0},
	{"label": "Piercing",     "spell_type": "mod_bool",  "spell_value": 0, "widget_type": "bool",  "default": false},
	{"label": "Ricochet",     "spell_type": "mod_bool",  "spell_value": 1, "widget_type": "bool",  "default": false},
	{"label": "Env Piercing", "spell_type": "mod_bool",  "spell_value": 2, "widget_type": "bool",  "default": false},
	{"label": "Split",        "spell_type": "mod_int",   "spell_value": 0, "widget_type": "int",   "default": 2},
	{"label": "Trail",        "spell_type": "mod_bool",  "spell_value": 3, "widget_type": "bool",  "default": false},
]

# Maps SpellEffect enum value (int key) → {type, default} for graph node input widgets.
# Integer keys because enum values are not compile-time constants outside this file.
const EFFECT_INPUT_TYPES: Dictionary = {
	SpellEffect.Scale:          {"type": "vec",   "default": 2.0},
	SpellEffect.MoveSpeed:      {"type": "float", "default": 2.0},
	SpellEffect.SlowMo:         {"type": "float", "default": 0.3},
	SpellEffect.Levitation:     {"type": "float", "default": 3.0},
	SpellEffect.ThrowLook:      {"type": "float", "default": 20.0},
	SpellEffect.Poison:         {"type": "float", "default": 5.0},
	SpellEffect.Thorns:         {"type": "float", "default": 0.5},
	SpellEffect.Invincibilty:   {"type": "none",  "default": 0.0},
	SpellEffect.Gravity:        {"type": "float", "default": 500.0},
	SpellEffect.ThrowRandom:    {"type": "float", "default": 20.0},
	SpellEffect.RandomTeleport: {"type": "float", "default": 10.0},
	SpellEffect.TeleportToHit:  {"type": "none",  "default": 0.0},
}

const DEFAULT_EFFECT_DURATION: float = 5.0

const TRIGGER_INPUT_TYPES: Dictionary = {
	SpellTrigger.OnHit:   {"type": "none",  "default": 0.0},
	SpellTrigger.OnEnd:   {"type": "none",  "default": 0.0},
	SpellTrigger.OnTimer: {"type": "float", "default": 1.0},
	SpellTrigger.OnKill:  {"type": "none",  "default": 0.0},
}

const EFFECT_SCRIPTS: Dictionary = {
	SpellEffect.Scale:          preload("res://Scripts/Spell/Effects/effect_scale.gd"),
	SpellEffect.MoveSpeed:      preload("res://Scripts/Spell/Effects/effect_move_speed.gd"),
	SpellEffect.SlowMo:         preload("res://Scripts/Spell/Effects/effect_slow_mo.gd"),
	SpellEffect.Levitation:     preload("res://Scripts/Spell/Effects/effect_levitation.gd"),
	SpellEffect.ThrowLook:      preload("res://Scripts/Spell/Effects/effect_throw_look.gd"),
	SpellEffect.Poison:         preload("res://Scripts/Spell/Effects/effect_poison.gd"),
	SpellEffect.Gravity:        preload("res://Scripts/Spell/Effects/effect_gravity.gd"),
	SpellEffect.ThrowRandom:    preload("res://Scripts/Spell/Effects/effect_throw_random.gd"),
	SpellEffect.RandomTeleport: preload("res://Scripts/Spell/Effects/effect_random_teleport.gd"),
	SpellEffect.TeleportToHit:  preload("res://Scripts/Spell/Effects/effect_teleport_to_hit.gd"),
}

var attribute_configs = [
	{"name": "Element",  "enum": SpellElement,  "color": Color.RED,              "id": "element",  "input_type": "none"},
	{"name": "Modifier", "enum": null,          "color": Color(0.6, 0.85, 1.0),  "id": "modifier", "input_type": "modifier"},
	{"name": "Path",     "enum": SpellPath,     "color": Color.YELLOW,           "id": "path",     "input_type": "none"},
	{"name": "Shape",    "enum": SpellShape,    "color": Color.ORANGE,           "id": "shape",    "input_type": "none"},
	{"name": "Casting",  "enum": SpellCasting,  "color": Color.GREEN,            "id": "casting",  "input_type": "none"},
	{"name": "Effect",   "enum": SpellEffect,   "color": Color.PURPLE,           "id": "effect",   "input_type": "dynamic", "value_input_types": EFFECT_INPUT_TYPES},
	{"name": "Trigger",  "enum": SpellTrigger,  "color": Color.WHITE,            "id": "trigger",  "input_type": "dynamic", "value_input_types": TRIGGER_INPUT_TYPES},
]
