# Strange Hands — Custom Spell System

A Godot 4.6 game where you design spells visually in a node graph, then cast them in real time as 3D projectiles.

<video src="https://github.com/user-attachments/assets/9b61177c-6328-40e8-b00e-4c77da344ec9" controls width="100%"></video>

## How It Works

Open the spell editor with **TAB**, wire together nodes to build a spell, and fire it with **LMB**.

Each spell is a chain of nodes:

| Node type | What it does |
|-----------|-------------|
| **Element** | Sets the spell's color and identity (Fire, Ice, Lightning, Arcane) |
| **Shape** | The hitbox — Orb, Beam, AOE, Cone, Wall, Explode, Projectile, Gravity Projectile |
| **Path** | How it moves — Line of Sight, Homing, Boomerang, Curve, Zig-Zag, Upwards |
| **Casting** | When it fires — Burst, Continuous, Charge Up, Self (Instant / Toggle / Hold) |
| **Modifier** | Tweaks stats — damage, speed, size, cast force, delay, split, ricochet, piercing |
| **Effect** | Applies a buff/debuff to the player — slow-mo, levitation, teleport, poison, etc. |
| **Trigger** | Fires a child spell on an event — On Hit, On Kill, On End, On Timer |

Spells compile to a data array at edit time and are interpreted at runtime — no code needed to make a new spell.

## Team

@momo (lolgube010)  
@apg-alousseni
