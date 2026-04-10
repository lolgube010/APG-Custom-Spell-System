# Strange Hands — Custom Spell System

A Godot 4.6 demo where you can visually design customized spells trough a node graph, then cast them in real time as 3D projectiles.

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

Spells compile to a data array at edit time and are interpreted at runtime, so there's no code needed to make a new spell.

The flow for spells is generally
Casting --> Shape --> Path, with elements, modifiers, and effects being able to be appended on the end. Triggers in the chain act as a sort of "reset" and any nodes following it will count as a new spell. 
There's some exceptions with ex. the self casting spells, which go Casting --> Effect usually.
There's a lot of things that haven't been tested and there's not a lot of safeguards right now, fyi! So just follow this flow and you'll be good. :]

## Team
@momo / Mohammed Osman / lolgube010 / Code  
@apg-alousseni / Guidance, Mentor
