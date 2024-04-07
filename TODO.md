# TODO List
At the time of writing 4/6/2024 12:00 PM, these are some of the things I think are necessary for INITIAL release.
Looking to mimic the playstyle of Custom Robo as much as possible with some variation.

## MAPS
Excluding the current basic arena map, 3+ maps feels like like healthy variety.
A map is requested to showcase Electric, Fire, and Conveyor belt hazards.
- [ ] Map 01
- [ ] Map 02
- [ ] Map 03
- [ ] Map 04 (Optional)
- [ ] Map 05 (Optional)

## ART ASSETS
HUD Specific
- [ ] HUD graphic(s) for "full" HUD option.
  - At the time of writing, there's one specific hud graphic that I would like to recreate, or something similar, match the Custom Robo motif and to display appropriate player stats on screen.
  - Look in the Graphics/HUD/directory for CRHUDBG as an example. This was my attempt. This is too big on a 320x200 screen resolution.
  - I have something more compact shown by default. However, I am looking to have something more graphically compact.

- [ ] HUD graphics for each weapon.
  - Not displayed on character.
  - One frame graphic to "display" weapon.

Mid-flight bullet, and explosion sprites:
- [ ] Few angle sprites for the following weapons.
  - Dragon gun
  - Splash gun
  - Future "Fist" Melee weapon?
- [ ] Few angle sprites for bomb weapons.
- [ ] Few angle sprites for pod weapons.

- [ ] Dedicated Menu BG graphic? (Undecided)
- [ ] Additional FX effects for bullet debris explosions / mid-flight travel.

- [ ] Sprite graphic for when player is in CRPS_ACTION state and spawning into the game. Ref: Sonic Battle (GBA) character marker for when a character respawns into the fight after death.

## CODE
- [ ] Find solution to equipping parts only on spawn and not mid-game.
  - Look for available vanilla solutions (Re: Timer?) before resorting to variable creation.

- [ ] Leg Parts (Optional)
  - Allow abilities to be tied to parts instead of character skins.

- [ ] Finish code for the remaining Bomb and Pod weapons.
- [ ] Fix stun gun functionality.

- [ ] Add countering
  - If you're in the middle of weapon firing, getting hit with someone will cause all other bullets to dissapate.

- [ ] Restructure and/or overhaul DamageMobj code.
  - I don't like my code in it's current state and would like to rewrite it. Moreover, see below.
  
- [ ] Give a knockback function to all weapons (weapon.knockfunc).
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
  - Mimic the way Sonic Battle GBA does (re)spawning for players.
  - Add Kart death explosion flare upon spawn.
  
- [ ] Create different death thinker code. Current death thinker code reused from SRB2 Rollout Knockout.
  - The death anim from upcoming game, [Void Souls](https://store.steampowered.com/app/2736690/Void_Sols/?curator_clanid=28641392), looks awesome to replicate.

- [ ] If currently targeting a player in range, have a button that switches to another target player in a game with 3+ people.

- [ ] Finalize how menu will look.
  - Menu functionally works, need to make it look nice.

# Future considerations
- [ ] Additional weapons.
- [ ] Bot functionality?
- [ ] Weapon unlocks?