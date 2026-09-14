**2DFactory** is a Blender-to-Godot sprite workflow designed to simplify the conversion of rendered sprite sheets into ready-to-use Godot 2D and 3D animated sprite assets.

The workflow consists of a **Blender add-on** for rendering and exporting sprite sheets with animation and socket information, and a **Godot plugin** for automatically extracting that data into Godot scenes and SpriteFrames resources.

The goal is to provide a consistent workflow for creating animated 2D and 3D sprite assets while preserving animation, pivot, socket, and texture information from Blender.

---

## Features

### Blender → Godot Workflow

2DFactory allows the Blender add-on to export sprite sheets and their corresponding JSON data directly into a Godot project.

The Godot plugin can then recursively scan the exported files and generate the corresponding Godot assets.

```text
Blender
   │
   ├── Sprite Sheet
   ├── JSON Animation Data
   ├── Normal Map
   ├── Roughness Map
   ├── AO Map
   └── Emission Map
          │
          ▼
     Godot 2DFactory
          │
          ├── SpriteFrames
          ├── AnimatedSprite2D / AnimatedSprite3D
          ├── CanvasTexture / StandardMaterial3D
          └── Socket Nodes
```

For the recommended workflow, configure the Blender add-on to export directly into the Godot project, for example:

```text
res://2DAssets/<SpriteAnimationName>/
```

This allows sprite sheets to be updated from Blender without manually copying the exported files between applications.

---

## Requirements

### Godot

The 2DFactory Godot Plugin requires:

**Godot 4.4 or later**

The plugin uses Godot's `EditorContextMenuPlugin` API, which is available starting from Godot 4.4.

### Blender

The Godot plugin is designed to work with the **2DFactory Blender add-on** and its exported sprite sheet JSON format.

The Blender add-on is responsible for generating the sprite sheets and associated animation, pivot, and socket information consumed by the Godot plugin.

---

## Installation

Copy the `2DFactory` folder into the `addons` directory of your Godot project:

```text
res://
└── addons/
    └── 2DFactory/
```

Then open:

**Project → Project Settings → Plugins**

and enable **2dFactory**.

After enabling the plugin, the 2DFactory options become available from the Godot FileSystem dock.

---

## Blender → Godot Workflow

The recommended workflow is to export the Blender sprite assets directly into the Godot project.

For example:

```text
res://2DAssets/
└── Cat_Run_Gun/
    ├── Cat_Run_Gun.png
    ├── Cat_Run_Gun.json
    ├── Cat_Run_Gun_N.png
    ├── Cat_Run_Gun_R.png
    ├── Cat_Run_Gun_AO.png
    └── Cat_Run_Gun_E.png
```

The JSON file contains the animation and sprite-cell information exported by the Blender add-on.

Depending on the workflow and available maps, the plugin can also use:

| Suffix | Texture           |
| ------ | ----------------- |
| `_N`   | Normal Map        |
| `_R`   | Roughness         |
| `_AO`  | Ambient Occlusion |
| `_E`   | Emission          |

Once the files have been detected by Godot, right-click the appropriate folder in the FileSystem dock and select:

**Create 2D Sprites** or **Create 3D Sprites**

The plugin recursively searches the selected folder and its subfolders for compatible JSON files and their corresponding sprite sheets.

---

# 2D Asset Creation

The **Create 2D Sprites** workflow generates Godot 2D animated sprite assets using:

* `AnimatedSprite2D`
* `SpriteFrames`
* `CanvasTexture` when a normal map is available
* `Node2D` socket nodes
* Optional socket reticles

### Single Sheet Mode

Single Sheet Mode processes each sprite sheet and its corresponding JSON file independently.

For example:

```text
Cat_Attack2/
    Cat_Attack2.png
    Cat_Attack2.json

Cat_Attack3/
    Cat_Attack3.png
    Cat_Attack3.json
```

Each source sheet produces its own:

```text
SpriteFrames.tres
Scene.tscn
```

The generated scene contains an `AnimatedSprite2D` referencing its corresponding `SpriteFrames` resource.

When a `_N` normal map is available, the plugin creates a `CanvasTexture` containing the main sprite sheet and its normal map.

Socket information from the JSON file is also reproduced as `Node2D` nodes in the generated scene.

---

### Separate Sheet Mode

Separate Sheet Mode combines animations from multiple sprite sheets into a single Godot asset.

For example:

```text
res://2DAssets/
├── Cat_Attack2/
│   ├── Cat_Attack2.png
│   └── Cat_Attack2.json
│
├── Cat_Attack3/
│   ├── Cat_Attack3.png
│   └── Cat_Attack3.json
│
└── Cat_Run_Gun/
    ├── Cat_Run_Gun.png
    └── Cat_Run_Gun.json
```

The plugin combines the animations into a single `SpriteFrames` resource and creates a single scene containing one `AnimatedSprite2D`.

Socket information from the individual JSON files is also combined into the generated scene.

This workflow is particularly useful when different animation actions have been exported as separate sprite sheets from Blender but are intended to become a single Godot character asset.

---

# 3D Asset Creation

The **Create 3D Sprites** workflow generates:

* `AnimatedSprite3D`
* `SpriteFrames`
* `StandardMaterial3D`
* PBR texture maps
* `Node3D` socket nodes
* Optional socket reticles

### Single Sheet Mode

For Single Sheet Mode, the plugin can use the additional PBR texture maps associated with the sprite sheet.

The generated `AnimatedSprite3D` uses a `StandardMaterial3D` as its Material Override:

```text
StandardMaterial3D
├── Albedo      → Main Sprite Sheet
├── Normal      → _N
├── Roughness   → _R
├── AO          → _AO
└── Emission    → _E
```

This allows the generated 3D sprite to utilize additional texture information for PBR-based rendering.

---

### Separate Sheet Mode

Separate Sheet Mode combines animations from multiple source sprite sheets into one `SpriteFrames` resource.

Because the generated `AnimatedSprite3D` uses a single material override while the animations may originate from different sprite sheets, additional PBR texture maps are not applied in this mode.

Therefore, Separate Sheet Mode for 3D assets uses the main sprite sheet images only.

---

# Pivot and Socket Handling

2DFactory automatically handles sprite pivot and socket positioning through its controller script.

Users do not need to manually configure the pivot or sprite offset for every animation frame.

During scene creation, the generated `AnimatedSprite2D` or `AnimatedSprite3D` is automatically connected to the 2DFactory controller. The controller uses the pivot and socket information from the corresponding JSON file and updates their positions according to the currently played animation frame.

The controller is included in:

```text
res://addons/2DFactory/anim_controller/
```

### Scene Location

The controller locates the corresponding JSON file based on the location of the generated scene.

Therefore, generated scenes should remain in their original location. Moving a generated scene to another folder can prevent the controller from locating the associated JSON data.

The controller can also be copied or modified for more advanced animation systems and custom game-specific behavior.

---

# Socket Z Ordering

For 2D assets, 2DFactory can convert socket Z translation information exported from Blender into Godot Z-index modifications.

When **3D Z** mode is used in the Blender add-on, sockets can dynamically move in front of or behind other 2D sprites.

This can be useful for objects such as:

* Weapons
* Equipment
* Character attachments
* Effects
* Other objects attached to a character

The behavior can be configured through the Animated Sprites project settings:

* **Socket Ordering Modification**
* **Pixel per Z-index Threshold**
* **Maximum Z-index Modification**

---

# Updating Existing Assets

2DFactory supports updating previously generated assets.

When a sprite sheet is updated in Blender, export the updated files using the **same file names and locations** as the existing files. After Godot detects the updated files, execute the same 2DFactory context-menu workflow again.

For reliable synchronization, avoid changing the names or locations of:

* Sprite sheets
* JSON files
* Generated scenes
* Asset folders

The generated `AnimatedSprite2D` or `AnimatedSprite3D` node should also retain its original name, as the plugin uses this name when identifying the existing node during updates.

If additional customization is required, users can rename or modify the parent scene/node while keeping the generated AnimatedSprite node name unchanged.

---

# Project Settings

2DFactory provides configurable project settings under:

**Project → Project Settings → 2d_factory**

The settings include:

### General

* Sprite Creation Menu
* Maximum Recursive Scan Depth

### Sprite Sheet Import

* Apply Texture Settings
* Main Compression
* Normal Map Compression
* Roughness Map Compression
* AO Map Compression
* Emission Map Compression

### Animated Sprites

* Texture Filter 2D
* Texture Filter 3D
* Separate Sheet Output Name
* Create Socket Reticle
* Socket Ordering Modification
* Pixel per Z-index Threshold
* Maximum Z-index Modification

These settings allow users to customize the generated sprite assets and texture import behavior without modifying the plugin source code.

---

# Recommended Project Structure

A recommended Godot project structure is:

```text
res://
├── addons/
│   └── 2DFactory/
│
├── 2DAssets/
│   ├── Character_A/
│   │   ├── Character_A.png
│   │   ├── Character_A.json
│   │   └── ...
│   │
│   └── Character_B/
│       ├── Character_B.png
│       ├── Character_B.json
│       └── ...
│
└── ...
```

Keeping the Blender output inside the Godot project makes it easier to update sprite sheets and regenerate the corresponding Godot assets.

---

# Workflow Summary

The complete workflow can be summarized as:

```text
┌─────────────────────┐
│      Blender        │
│   2DFactory Add-on  │
└──────────┬──────────┘
           │
           │ Export
           ▼
┌─────────────────────┐
│    Godot Project    │
│                     │
│ Sprite Sheet + JSON │
│ Optional PBR Maps   │
└──────────┬──────────┘
           │
           │ 2DFactory Godot Plugin
           ▼
┌─────────────────────────────┐
│       Generated Assets      │
│                             │
│ AnimatedSprite2D / 3D       │
│ SpriteFrames                │
│ CanvasTexture / Material    │
│ Socket Nodes                │
│ Controller                  │
└─────────────────────────────┘
```

---

# Documentation

For a complete description of the installation process, extraction workflows, Single Sheet and Separate Sheet modes, project settings, pivot and socket handling, and generated asset structure, see the full [2DFactory documentation](https://drive.google.com/file/d/19TgMfQLxBtxRZ8nAS0gEnZV491SWhs1_/view?usp=drive_link).

---

# License

See the repository license for information regarding the use, modification, and redistribution of 2DFactory.
