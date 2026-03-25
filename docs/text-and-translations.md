# Text and Translations

## Overview

All in-game text is managed through Godot's built-in localisation system. The source of truth is a CSV file which Godot compiles into binary `.translation` files on import.

## File locations

| File | Purpose | Tracked in git |
|------|---------|----------------|
| `project/addons/maaacks_game_template/base/translations/menus_translations.csv` | Source text for all UI strings | Yes |
| `project/addons/maaacks_game_template/base/translations/menus_translations.csv.import` | Godot import config for the CSV | Yes |
| `project/addons/maaacks_game_template/base/translations/*.translation` | Compiled binary translation files | No (generated) |

## Adding or editing text

1. Open `menus_translations.csv` in a spreadsheet editor or text editor.
2. The first column (`keys`) is the translation key used in scenes and scripts.
3. Each subsequent column is a locale code (`en`, `fr`, etc.).
4. Add a new row for new strings, or edit an existing cell to update a translation.
5. Save the CSV and return to the Godot editor — it will reimport automatically and regenerate the `.translation` files.

## Adding a new language

1. Add a new column to `menus_translations.csv` with the locale code as the header (e.g. `de` for German).
2. Fill in translations for each key in that column.
3. Save and reimport in Godot.
4. The new `.translation` file (e.g. `menus_translations.de.translation`) will be generated automatically.
5. Add the locale to the project if needed: **Project → Project Settings → Localisation → Translations**.

## Using translation keys in scenes and scripts

In a scene, set any `text` property to a translation key and enable **Localise** on the node, or use the `tr()` function in GDScript:

```gdscript
label.text = tr("New Game")
```

Keys are defined in the `keys` column of the CSV.

## Generated files and first-open errors

The compiled `.translation` files are excluded from git (see `.gitignore`). On a fresh clone, Godot will generate them automatically the first time the project is opened in the editor. Until the import completes you may see errors like:

```
ERROR: Cannot open file 'res://addons/maaacks_game_template/base/translations/menus_translations.en.translation'.
```

These are expected and will not reappear after the initial import.
