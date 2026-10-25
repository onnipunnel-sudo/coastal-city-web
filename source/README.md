# Coastal City — Android open-world prototype

This is an original, code-generated Godot 4 project with a tropical coastal city, placeholder buildings/windows, palm trees, neon-style panels, a simple player, a drivable pink convertible, and an on-screen control layout inspired by PPSSPP's familiar D-pad + face-button arrangement.

**Important:** This is not GTA Vice City, does not use the reVC engine, and does not contain Rockstar code or GTA assets. It is a small original prototype that can be used as a foundation. It does not yet have realistic licensed character/car meshes, proper traffic AI, missions, weapons, a minimap, save/load, or production-quality graphics. The city and character are created from simple 3D primitives, so it will not look like the reference collage yet.

## Open on an Android phone
1. Install **Godot 4 Android Editor** from the official site: https://godotengine.org/download/android/
2. Extract this ZIP into a folder accessible to the editor.
3. In Godot, import/open the folder containing `project.godot`.
4. Open `main.tscn` and press **Run Project**.

## Controls
- Left side: D-pad to move.
- Right side: **A** interact (near the pink car to enter/exit), **B** jump, **X** sprint, **Y** camera distance toggle.
- Keyboard test: WASD/arrow keys move, Space jump, Shift sprint, E enter/exit car, C toggle camera.
- When driving: the same D-pad controls steer and accelerate/reverse.

## Performance
This is a primitive-based prototype intended for iteration, not a high-end game build. Reduce shadow quality and draw distance on slow devices. An APK export needs Godot's Android export templates and SDK configuration; this ZIP is the editable project source, not a prebuilt APK.

## reVC route
If you specifically want to build on reVC, that is a separate engine porting task and requires a compatible set of legally obtained original game assets. This Godot project is deliberately separate so it can run with custom assets only.
