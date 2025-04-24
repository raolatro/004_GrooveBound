Enemy 1 Sprite Sheets:

walk:
- Path: enemy1/walk/enemy1_walk.png
- 6x4 grid (6 frames per direction, 4 directions: down, up, left, right)
- Each tile 64x64 pixels
- Each row is a direction (row 1: down, row 2: up, row 3: left, row 4: right)

death:
- Path: enemy1/death/enemy1_death.png
- 11x4 grid (11 frames per direction, 4 directions)
- Each tile 64x64 pixels
- Each row is a direction (row 1: down, row 2: up, row 3: left, row 4: right)

Usage:
- Use the row according to the direction the enemy is facing/moving.
- Play all frames of the death animation before removing the enemy from the game.
