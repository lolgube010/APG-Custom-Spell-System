extends Node

# element
enum SpellElement { FIRE, ICE, LIGHTNING, ARCANE }
#spell modifiers that are vectors
enum SpellModifierVec { Size }
#spell modifiers that are floats
enum SpellModifierFloat { CastSpeed, MoveSpeed, Duration, CastForce, Delay }
#spell modifiers that are integeers
enum SpellModifierInt { Split }
#spell modifiers that are boolean
enum SpellModifierBool { Piercing, Ricochet, EnvironmentPiercing, Trail }
#changes the path of the spell takes when moving
enum SpellPath { LineOfSight, CurvePath, SigZagLineOfSight, Upwards, Homing, Boomerang}
#decides what shape the spell will take
enum SpellShape { Orb, AOE, Beam, Explode, Cone, Wall, GravityProjectile, Projectile }
#decides how the spell is cast
enum SpellCasting { Burst, Continous, SelfInstant, SelfToggle, ChargeUp, SelfHold }
#decides the effect the spell will have when hitting a target
enum SpellEffect { Scale, MoveSpeed, SlowMo, Levitation, ThrowLook, Poison, Thorns, Invincibilty, Gravity, ThrowRandom }
#types of amplifications for nodes
enum SpellAmplification { Half, Double, Quad, Ten }
#a trigger for when a spell will spawn another spell
enum SpellTrigger { OnHit, OnEnd, OnTimer, OnKill }

const ELEMENT_COLORS: Dictionary = {
	SpellElement.FIRE:      Color(1.0, 0.25, 0.0),
	SpellElement.ICE:       Color(0.2,  0.85, 1.0),
	SpellElement.LIGHTNING: Color(1.0, 0.95, 0.1),
	SpellElement.ARCANE:    Color(0.65, 0.0,  1.0),
}

const SHAPE_SCENES: Dictionary = {
	SpellShape.Orb:               preload("res://Scripts/Spell_Stuff/Shapes/Shape_Orb.tscn"),
	SpellShape.AOE:               preload("res://Scripts/Spell_Stuff/Shapes/Shape_AOE.tscn"),
	SpellShape.Beam:              preload("res://Scripts/Spell_Stuff/Shapes/Shape_Beam.tscn"),
	SpellShape.Explode:           preload("res://Scripts/Spell_Stuff/Shapes/Shape_Explode.tscn"),
	SpellShape.Cone:              preload("res://Scripts/Spell_Stuff/Shapes/Shape_Cone.tscn"),
	SpellShape.Wall:              preload("res://Scripts/Spell_Stuff/Shapes/Shape_Wall.tscn"),
	SpellShape.GravityProjectile: preload("res://Scripts/Spell_Stuff/Shapes/Shape_GravityProjectile.tscn"),
	SpellShape.Projectile:        preload("res://Scripts/Spell_Stuff/Shapes/Shape_Projectile.tscn"),
}

const PATH_SCRIPTS: Dictionary = {
	SpellPath.LineOfSight:       preload("res://Scripts/Spell_Stuff/Paths/path_line_of_sight.gd"),
	SpellPath.CurvePath:         preload("res://Scripts/Spell_Stuff/Paths/path_curve_path.gd"),
	SpellPath.SigZagLineOfSight: preload("res://Scripts/Spell_Stuff/Paths/path_zig_zag_line_of_sight.gd"),
	SpellPath.Upwards:           preload("res://Scripts/Spell_Stuff/Paths/path_upwards.gd"),
	SpellPath.Homing:            preload("res://Scripts/Spell_Stuff/Paths/path_homing.gd"),
	SpellPath.Boomerang:         preload("res://Scripts/Spell_Stuff/Paths/path_boomerang.gd"),
}

# Maps SpellEffect integer value → {type, default} for graph node input widgets.
# Integer keys are used because enum values can't be const dict keys in other files.
# Order matches SpellEffect enum: Scale=0 MoveSpeed=1 SlowMo=2 Levitation=3 ThrowLook=4
#                                 Poison=5 Thorns=6 Invincibilty=7 Gravity=8 ThrowRandom=9
# Flat list of every modifier, each with its spell-array type/value and widget metadata.
# Used to populate the single combined Modifier row in the graph node.
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

const EFFECT_INPUT_TYPES: Dictionary = {
	0: {"type": "vec",   "default": 2.0},
	1: {"type": "float", "default": 2.0},
	2: {"type": "float", "default": 0.3},
	3: {"type": "float", "default": 3.0},
	4: {"type": "float", "default": 20.0},
	5: {"type": "float", "default": 5.0},
	6: {"type": "float", "default": 0.5},
	7: {"type": "none",  "default": 0.0},
	8: {"type": "float", "default": 500.0},
	9: {"type": "float", "default": 20.0},
}

const TRIGGER_INPUT_TYPES: Dictionary = {
	0: {"type": "none",  "default": 0.0},  # OnHit
	1: {"type": "none",  "default": 0.0},  # OnEnd
	2: {"type": "float", "default": 1.0},  # OnTimer — interval in seconds
	3: {"type": "none",  "default": 0.0},  # OnKill
}

const EFFECT_SCRIPTS: Dictionary = {
	SpellEffect.Scale:        preload("res://Scripts/Spell_Stuff/Effects/effect_scale.gd"),
	SpellEffect.MoveSpeed:    preload("res://Scripts/Spell_Stuff/Effects/effect_move_speed.gd"),
	SpellEffect.SlowMo:       preload("res://Scripts/Spell_Stuff/Effects/effect_slow_mo.gd"),
	SpellEffect.Levitation:   preload("res://Scripts/Spell_Stuff/Effects/effect_levitation.gd"),
	SpellEffect.ThrowLook:    preload("res://Scripts/Spell_Stuff/Effects/effect_throw_look.gd"),
	SpellEffect.Poison:       preload("res://Scripts/Spell_Stuff/Effects/effect_poison.gd"),
	SpellEffect.Thorns:       preload("res://Scripts/Spell_Stuff/Effects/effect_thorns.gd"),
	SpellEffect.Invincibilty: preload("res://Scripts/Spell_Stuff/Effects/effect_invincibility.gd"),
	SpellEffect.Gravity:      preload("res://Scripts/Spell_Stuff/Effects/effect_gravity.gd"),
	SpellEffect.ThrowRandom:  preload("res://Scripts/Spell_Stuff/Effects/effect_throw_random.gd"),
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
