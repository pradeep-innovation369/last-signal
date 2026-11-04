# LAST SIGNAL: SHIFT

A sci-fi pixel-art survival game built with Godot 4.

## Run the prototype

Open this folder in Godot 4.7 and run the project (F6/F5, or the Run Project button).
The main scene is configured as `scenes/main/Main.tscn`. The connected ship areas are
the Cryo Chamber, Main Corridor, and Engineering Room.

The title screen's **PLAY** button starts a new Chapter 1 run; **CONTINUE** appears
when a save file exists and restores that run. Ending A and Ending B retain their
current conclusions and lead to a Chapter 2 continuation teaser; Chapter 2 is not
currently playable.

Audio routes through the **Master**, **Music**, and **SFX** buses managed by the
`AudioManager` autoload. The opening title cue is expected at
`assets/audio/title_opening.wav`.

Move with **WASD** or the **arrow keys**. Approach the power console in Engineering
and press **E** to read its status. Access the navigation console along the north
wall of the Cryo Chamber to check the ship's navigation status. The Engineering
north-wall security console reports system status and recorded security events.
Approach crew data terminals and press **E** to recover logs; select **LOGS** in the
HUD to revisit discoveries from the current session.
Use **SAVE GAME** in the HUD to save your position, oxygen, power allocations, and
discovered logs and mission objectives locally; a valid save can be restored with
**CONTINUE** from the title screen. Follow the compact HUD objective panel to progress
through the ship.
The HUD shows your current location, objective, and interaction hint. The game uses
a 320x180 logical viewport upscaled with integer scaling to a resizable 1280x720
window. The connected rooms sit inside a 3D spacecraft hull, and the orange 3D
astronaut follows the existing 2D movement and collision system.
