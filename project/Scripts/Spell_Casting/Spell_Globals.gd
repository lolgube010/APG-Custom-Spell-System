extends Node

enum SpellElement { FIRE, ICE, LIGHTNING, ARCANE }
enum SpellModifierVec { Size }
enum SpellModifierFloat { CastSpeed, MoveSpeed, Duration, CastForce }
enum SpellPath { LineOfSight, CurvePath, SigZagLineOfSight, Upwards, OnPlayer, }
enum SpellShape { Orb, AOE, Beam, Explode }
enum SpellCasting { Burst, Continous, Self}
enum SpellEffect { Scale, MoveSpeed, SlowMo, Levitation, Throw, Poison }
enum SpellAmplification { Half, Double, Quad, Ten }
enum SpellTrigger { OnHit, OnEnd, OnTimer, OnCast, OnKill }

var attribute_configs = [
	{"name": "Element", "enum": SpellElement, "color": Color.RED, "id": "element"},
	{"name": "Modif (Vec)", "enum": SpellModifierVec, "color": Color.CYAN, "id": "mod_vec"},
	{"name": "Modif (Float)", "enum": SpellModifierFloat, "color": Color.AZURE, "id": "mod_float"},
	{"name": "Path", "enum": SpellPath, "color": Color.YELLOW, "id": "path"},
	{"name": "Shape", "enum": SpellShape, "color": Color.ORANGE, "id": "shape"},
	{"name": "Casting", "enum": SpellCasting, "color": Color.GREEN, "id": "casting"},
	{"name": "Effect", "enum": SpellEffect, "color": Color.PURPLE, "id": "effect"},
	{"name": "Amplification", "enum": SpellAmplification, "color": Color.PINK, "id": "amplification"},
	{"name": "Trigger", "enum": SpellTrigger, "color": Color.WHITE, "id": "trigger"}
]
