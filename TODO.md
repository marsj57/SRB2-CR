# TODO List
At the time of writing 4/6/2024 12:00 PM, these are some of the things I think are necessary for INITIAL release.
Looking to mimic the playstyle of Custom Robo as much as possible with some variation.

## MAPS
Excluding the current basic arena map, 3+ maps feels like like healthy variety.
A map is needed to showcase both Electric and Fire hazards.
- [ ] Map 01
- [ ] Map 02
- [ ] Map 03
- [ ] Map 04 (Optional)
- [ ] Map 05 (Optional)

## ART ASSETS
For HUD and mid-flight Bullet sprites:
- [ ] Various gun weapon graphics and few angle sprites.
- [ ] Various bomb weapon graphics and few angle sprites.
- [ ] Various pod weapon graphics and few angle sprites.

- [ ] Dedicated Menu BG graphic? (Undecided)
- [ ] Additional FX effects for bullet debris explosions / mid-flight travel.

- [ ] Sprite graphic for when player is in CRPS_ACTION state and spawning into the game. Ref: Sonic Battle (GBA) character marker for when a character respawns into the fight after death.

## CODE
- [ ] Leg Parts (Optional)
  - Allow abilities to be tied to parts instead of character skins.

- [ ] Finish code for the remaining Bomb and Pod weapons.
- [ ] Fix stun gun functionality.

- [ ] Add countering
  - If you're in the middle of weapon firing, getting hit with someone will cause all other bullets to dissapate.

- [ ] Restructure knockback code. Give a knockback function to all weapons (weapon.knockfunc).
- Specifically for bomb and pod weapons:
  - B (Burst)- Blows opponent sideways slowly, blast lingers
  - C (Cyclone)- Blows opponent slowly upwards
  - D (Destroy)- Blows opponent diagonally upwards, blast lingers
  - F (Flipper)- Blows opponent sideways
  - G (Gazer)- Blows opponent upwards
  - H (Horizon)- Blows opponent slowly sideways
  - K (Knockdown)- Will always knock opponent down
  - P (Pillar)- Blows opponent upwards, blast lingers
  - S (Stun)- Immobilizes target
  - T (Traction)- Pulls opponent towards you
  - X (Explosion)- Blows opponent diagonally high in the air

- [ ] Make the Custom Robo CRPS_ACTION state do something!
- [ ] Mimic the way Sonic Battle GBA does (re)spawning for players.
- [ ] Create different death thinker code. Current death thinker code reused from SRB2 Rollout Knockout.

- [ ] If currently targeting a player in range, have a button that switches to another target player in a game with 3+ people.

- [ ] Finalize how menu will look.

# Future considerations
- [ ] Additional weapons.
- [ ] Bot functionality?
- [ ] Weapon unlocks?