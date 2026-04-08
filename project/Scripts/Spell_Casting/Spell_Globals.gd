extends Node

# element
enum SpellElement { FIRE, ICE, LIGHTNING, ARCANE }
#spell modifiers that are vectors
enum SpellModifierVec { Size }
#spell modifiers that are floats
enum SpellModifierFloat { CastSpeed, MoveSpeed, Duration, CastForce }
#spell modifiers that are integeers
enum SpellModifierInt { Split }
#spell modifiers that are boolean
enum SpellModifierBool { Piercing, Ricochet, EnvironmentPiercing }
#changes the path of the spell takes when moving
enum SpellPath { LineOfSight, CurvePath, SigZagLineOfSight, Upwards, Homing, Boomerang}
#decides what shape the spell will take
enum SpellShape { Orb, AOE, Beam, Explode, Cone, Wall, Deployable, GravityProjectile, Trail }
#decides how the spell is cast
enum SpellCasting { Burst, Continous, SelfInstant, SelfToggle, ChargeUp, Delayed}
#decides the effect the spell will have when hitting a target
enum SpellEffect { Scale, MoveSpeed, SlowMo, Levitation, Throw, Poison, Thorns, Invincibilty}
#types of amplifications for nodes
enum SpellAmplification { Half, Double, Quad, Ten }
#a trigger for when a spell will spawn another spell
enum SpellTrigger { OnHit, OnEnd, OnTimer, OnCast, OnKill }

const SHAPE_SCENES: Dictionary = {
	SpellShape.Orb: preload("res://Scripts/Spell_Stuff/Shape_Orb.tscn"),
}

const PATH_SCRIPTS: Dictionary = {
	SpellPath.LineOfSight:       preload("res://Scripts/Spell_Stuff/Paths/path_line_of_sight.gd"),
	SpellPath.CurvePath:         preload("res://Scripts/Spell_Stuff/Paths/path_curve_path.gd"),
	SpellPath.SigZagLineOfSight: preload("res://Scripts/Spell_Stuff/Paths/path_zig_zag_line_of_sight.gd"),
	SpellPath.Upwards:           preload("res://Scripts/Spell_Stuff/Paths/path_upwards.gd"),
	SpellPath.Homing:            preload("res://Scripts/Spell_Stuff/Paths/path_homing.gd"),
	SpellPath.Boomerang:         preload("res://Scripts/Spell_Stuff/Paths/path_boomerang.gd"),
}

var attribute_configs = [
	{"name": "Element", "enum": SpellElement, "color": Color.RED, "id": "element"},
	{"name": "Modif (Vec)", "enum": SpellModifierVec, "color": Color.CYAN, "id": "mod_vec"},
	{"name": "Modif (Float)", "enum": SpellModifierFloat, "color": Color.AZURE, "id": "mod_float"},
	{"name": "Modif (Bool)", "enum": SpellModifierBool, "color": Color.AQUA, "id": "mod_bool"},
	{"name": "Modif (Int)", "enum": SpellModifierInt, "color": Color.AQUAMARINE, "id": "mod_bool"},
	{"name": "Path", "enum": SpellPath, "color": Color.YELLOW, "id": "path"},
	{"name": "Shape", "enum": SpellShape, "color": Color.ORANGE, "id": "shape"},
	{"name": "Casting", "enum": SpellCasting, "color": Color.GREEN, "id": "casting"},
	{"name": "Effect", "enum": SpellEffect, "color": Color.PURPLE, "id": "effect"},
	{"name": "Amplification", "enum": SpellAmplification, "color": Color.PINK, "id": "amplification"},
	{"name": "Trigger", "enum": SpellTrigger, "color": Color.WHITE, "id": "trigger"}
]
