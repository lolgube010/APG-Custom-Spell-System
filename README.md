# strange-hands-godot

Strange hands, made in Godot 4.6.1

## New Dev Setup

### 1. Install Godot 4.6.1

Download **Godot 4.6.1 stable** (standard version, not .NET) from the [official site](https://godotengine.org/download).

Install it to:
```
C:\Program Files\Godot_v4.6.1\Godot_v4.6.1-stable_win64.exe
```

> This path is already configured in `.vscode/settings.json`. If you install elsewhere, update the `godotTools.editorPath.godot4` setting to match.

### 2. Install Visual Studio Code

Download from [code.visualstudio.com](https://code.visualstudio.com).

### 3. Install the Godot Tools extension

Install [Godot Tools](https://marketplace.visualstudio.com/items?itemName=geequlim.godot-tools) (`geequlim.godot-tools`) in VS Code.

### 4. Clone and open the project

```bash
git clone <repo-url>
cd strange-hands-godot
```

Open the `project/` folder in Godot (not the repo root).

### 5. Optional: Install Claude Code

This repo uses [Claude Code](https://claude.ai/code) for AI-assisted development. Install it globally via npm:

```bash
npm install -g @anthropic-ai/claude-code
```

# Team
@apg-alousseni
