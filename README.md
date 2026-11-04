# LAST SIGNAL: SHIFT

A sci-fi pixel-art survival game built with Godot 4.

## Run the prototype

Open this folder in Godot 4.7 and run the project (F6/F5, or the Run Project button).
The main scene is configured as `scenes/main/Main.tscn`. The connected ship areas are
the Cryo Chamber, Main Corridor, and Engineering Room.

Move with **WASD** or the **arrow keys**. Approach the power console in Engineering
and press **E** to read its status. Access the navigation console along the north
wall of the Cryo Chamber to check the ship's navigation status. The HUD shows your
current location, objective, and interaction hint. The game uses a 320x180 logical
viewport upscaled with integer scaling to a resizable 1280x720 window. The connected
rooms sit inside a 3D spacecraft hull, and the orange 3D astronaut follows the
existing 2D movement and collision system.
