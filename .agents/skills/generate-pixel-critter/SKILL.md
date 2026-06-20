---
name: generate-pixel-critter
description: Design and draw a side-view pixel-art spritesheet of a specified animal on a grid of 32x32 cells. Outputs a structured pixel character-grid text file and a crisp lossless PNG spritesheet. Then integrates it into the game's critter config.
---

# Generate Pixel Critter (Spritesheet)

Use this skill when you need to design and create a multi-frame 32x32 pixel-art animal spritesheet for the game's ambient critter system, compile it to a lossless PNG spritesheet, and register it in the Bevy asset configs.

## Inputs

- **`animal`** (Required): The name of the animal to draw (e.g., `deer`, `hedgehog`, `owl`, `squirrel`).
- **`palette_theme`** (Optional): A theme for the color palette (e.g., `mysterious forest`, `autumn warm`, `winter frost`). Defaults to matching the active set (`mysterious_forest`).

---

## Design Principles for Spritesheets

### 1. Spatial Constraints & Grid Layout

- **Cell Size**: Each individual frame is exactly 32x32 pixels.
- **Spritesheet Layout**: The final spritesheet contains multiple rows of animations, each representing a different animation state:
    - **Always Required**:
        - `idle` animation (loops).
        - `walk` animation (loops).
        - `flee` animation (loops).
        - `spook` animation (one-shot flinch, loops: false).
        - `sniff` animation (curious watch loop, loops: true).
        - `alert` animation (one-shot perk/rear-up, loops: false).
- **Sheet Dimensions**: The compiled spritesheet dimensions (columns and rows) should cover all required frames in a grid.
- **Ground Alignment**: The feet of ground-walking animals must be anchored to the **bottom edge of each 32x32 cell** (usually local row 31, 0-indexed) in every frame. This matches the collision shape and prevents critters from sinking or floating.
- **Center Alignment**: The animal must be horizontally centered within each 32x32 frame.

### 2. Perspective & Orientation

- **Profile (Side-View)**: Critters move horizontally in a 2D plane. Draw the animal from a pure side-view profile.
- **Facing Right**: The spritesheet should have the animal facing **Right**. Bevy's KCC will automatically mirror it horizontally when moving left.

### 3. Palette Design

- **Limit Colors**: Use a tight, cohesive palette of **4 to 8 colors** (plus transparent background).
- **Tone Mapping**:
    1. `.` (Transparent background)
    2. `x` (Dark Outline: highly recommended for readability. Use dark brown, dark purple, or near-black).
    3. `b` (Primary Body color: the dominant midtone fur/skin color).
    4. `s` (Shadow color: a cool, dark variant for underbellies and background legs).
    5. `h` (Highlight color: a warm, light variant for top of the head, back, etc.).
    6. `a` (Accent color: secondary fur patches, tails, or belly).
    7. `e` (Eye color: usually a single bright or dark pixel positioned legibly).

### 4. Anatomy & Silhouette Guidelines

To ensure each critter is instantly recognizable, follow strict anatomical blueprint guidelines:

- **Head vs. Body Proportions**:
    - **Rabbit / Squirrel / Hedgehog**: Large head relative to body (ratio 1:1.5 to 1:2). Large ears (long vertical strips for rabbits; tiny rounded triangles for squirrels; none or spikes for hedgehogs).
    - **Fox / Deer**: Distinctly smaller head relative to body (ratio 1:3 or 1:4). Slender snout/muzzle.
- **Silhouette Landmarks**:
    - Always articulate recognizable features like tails, ears, and neck slopes.
    - **Fox**: Long snout, pointed triangular ears, and a huge bushy tail spanning at least 8-10 pixels horizontally.
    - **Deer**: Long elegant neck (6-8 pixels high), large antlers if male, small upturned tail.
    - **Squirrel**: Massive s-curved bushy tail curled up over its back (12-14 pixels high).
- **Anatomy Block-Out**: Before drawing, partition the 32x32 cell vertically:
    - **Upper 30% (Rows 0-9)**: Ears, antlers, high tails, or candy held aloft.
    - **Middle 40% (Rows 10-22)**: Head, neck, and main body torso.
    - **Lower 30% (Rows 23-31)**: Legs, feet, and ground-anchors.

### 5. Leg Calibration & Gait Motion

Improper leg proportions and rigid limbs ruin pixel-art animation. Apply these formulas:

- **Leg-to-Body Length Formulas**:
    - **Short-Legged / Waddlers** (Rabbit, Squirrel, Fox, Hedgehog, Soot Sprite):
        - Leg length must be between **2 to 5 pixels** from bottom of body torso to bottom of foot (row 31).
        - _Warning_: Legs longer than 5 pixels make them look like giant insects or spiders.
    - **Long-Legged / Runners** (Deer, Wolf):
        - Leg length must be between **8 to 12 pixels** from bottom of body torso to bottom of hoof/foot (row 31).
        - _Warning_: Legs shorter than 8 pixels make long-legged animals look stubby, like pigs.
- **Joint Articulation**:
    - **Front Legs**: Bend forward at the knee/elbow (joint points right or forward when lifting).
    - **Back Legs**: Have a prominent backwards-facing joint (hock) pointing left (backward) when bending.
- **Depth & Shading (Foreground vs. Background)**:
    - Background limbs must be colored in the shadow/backtone color `s` (a darker shade of the outline/body color) and placed 1 pixel higher to simulate perspective.
    - Foreground limbs must use outline color `x` and main body color `b`.
- **Gait Animation (Walk/Run cycles)**:
    - **Body Bobbing**: The main torso MUST bob up and down by 1 to 2 pixels in sync with the gait. High-bob during leg contraction, low-bob during leg extension. A static torso makes legs look detached.
    - **Ground Foot Landing**: At least one active leg must land solidly on **row 31** in every frame of the gait to anchor the critter.

---

## Workflow

### Step 1: Design the Character Grid

Draft the animal spritesheet using a text file where each frame is defined using a `# FRAME <row>,<col>` coordinate header followed by its 32x32 pixel grid.

Create a file named `<animal>.txt` in the scratch directory: `<appDataDir>/brain/<conversation-id>/scratch/<animal>.txt`.

```text
# PALETTE
. : transparent
x : #2e222f (Outline)
b : #ef7d57 (Body Brown)
s : #a7f070 (Spikes/Shadows)
h : #ffcd75 (Highlight Yellow)
d : #b13e53 (Underbelly Dark Red)
w : #ffffff (Eye White)

# ANIMATION: idle (Row 0, 4 frames)
# FRAME 0,0
................................
................................
................................
................................
................................
................................
................................
...................sss..........
..................sssssss........
................ssssssssss.......
..............sssssssssssss......
.............sxbxbxbxbxbxbxs.....
............sbbbbbbbbbbbbbbxs....
...........sbbbbbbwbbbbbbbbdxs...
...........sddddddddddddddddxs...
............xdddxddddddxdddx.....
.............xxx..xxxx..xxx......
................................
................................
................................
[Ensure 32 lines of 32 chars per frame]

# FRAME 0,1
[idle Frame 1 grid...]

# FRAME 0,2
[idle Frame 2 grid...]

# FRAME 0,3
[idle Frame 3 grid...]

# ANIMATION: run (Row 1, 8 frames)
# FRAME 1,0
[run Frame 0 grid...]

# FRAME 1,1
[run Frame 1 grid...]

...

# FRAME 1,7
[run Frame 7 grid...]

# ANIMATION: walk (Row 2, 8 frames)
# FRAME 2,0
[walk Frame 0 grid...]

# FRAME 2,1
[walk Frame 1 grid...]

...

# FRAME 2,7
[walk Frame 7 grid...]
```

### Step 2: Compile the Asset

Run the `grid_to_assets.py` script to parse all coordinates, stitch the frames together into a 256x96 spritesheet image, and scale it:

```bash
python3 .agents/skills/generate-pixel-critter/scripts/grid_to_assets.py \
  "<appDataDir>/brain/<conversation-id>/scratch/<animal>.txt" \
  "<appDataDir>/brain/<conversation-id>/scratch/<animal>" \
  8
```

### Step 3: Integrate into the Game Crate

1. Move the finished `1x` PNG spritesheet to the critter assets directory:
    - Target: `assets/sets/mysterious_forest/critter/<animal>.png`
2. Open `assets/sets/mysterious_forest/critter.ron`.
3. Add a new entry to the `kinds` array. Configure its sheet layout and assign animations using Bevy's `grid(row, col)` addressing scheme:
    ```ron
    (
        kind: "<animal>",
        sheet: (
            path: "sets/mysterious_forest/critter/<animal>.png",
            tile_size: (32, 32),
            columns: 8,
            rows: 6,
            offset: (0, 0),
            inset: (0, 0),
            scale: 3.0,
            anchor: (0.0, -0.5),
            animations: [
                (name: idle,  at: grid(0, 0), count: 4, advance: time(250),      loops: true),
                (name: flee,  at: grid(1, 0), count: 8, advance: distance(10.0), loops: true),
                (name: walk,  at: grid(2, 0), count: 8, advance: distance(8.0),  loops: true),
                // Add curious/spook animations if awareness is configured:
                (name: sniff, at: grid(3, 0), count: 5, advance: time(220),      loops: true),
                (name: alert, at: grid(4, 0), count: 5, advance: time(90),       loops: false),
                (name: spook, at: grid(5, 0), count: 4, advance: time(75),       loops: false),
            ],
        ),
        population: (
            target_count: 1,
            spawn_x_range: (-2000.0, 2000.0),
            edge_spawn_margin: 64.0,
            despawn_margin: 256.0,
            spawn_cooldown_range: (1.0, 3.0),
        ),
        front_band_weight: 0.5,
        wander: (
            walk_speed: 15.0,
            idle_duration_range: (2.0, 5.0),
            walk_duration_range: (1.0, 3.0),
            turn_chance_per_decision: 0.3,
            bounds_padding: 16.0,
        ),
        // Temperament-based awareness: comfort, panic, spring dynamics, and spook thresholds
        // are derived from standard personality traits (e.g. bold, skittish, curious).
        awareness: (
            radius: 120.0,
            temperament: (
                archetype: playful, // e.g. shy, skittish, bold, playful
            ),
        ),
        grass_influence: (
            strength: 0.4,
        ),
    )
    ```

### Step 4: Stop Immediately

Once Step 3 is finished, the agent must immediately stop and report completion to the user. Do NOT perform any further activity:

- Do NOT run `cargo check`, `cargo test`, `cargo clippy`, or any other validation commands.
- Do NOT ask to commit changes or run any git-related actions.
- Do NOT run any other commands. Just stop and present the completion.
