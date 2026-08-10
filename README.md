# Valtique

![Valtique Logo](icon.png)

**Version:** v5.2

Bringing Minecraft into an film look — grain, sepia, and outlines
reminiscent of classic celluloid film.

Valtique is a post-processing shaderpack for Iris that
transforms Minecraft's visuals into an film style. It features
widescreen letterbox bars, a faded yellow-brown sepia tone, film grain that
spreads across the whole screen and intensifies toward the edges, subtle
lens distortion reminiscent of vintage cameras, white outlines around every
block, and soft light bloom for highlight reflections. All effects can be
adjusted through the Shader Pack Settings menu — from grain intensity and
letterbox thickness to sepia strength — so the look can be tuned anywhere
from subtle to a full old-film feel.

## Features
- Letterbox bars (cinematic widescreen bars, top & bottom)
- Sepia / faded yellow-brown tone, classic old film color
- Film grain spread across the whole screen, stronger toward the edges
- Subtle lens distortion (chromatic shift) reminiscent of old film cameras
- White outline around every block
- Soft light bloom for light reflections

## Installation
1. Move the `Valtique` file into `.minecraft/shaderpacks/`
2. Select this shaderpack in Iris (Options → Video Settings → Shader Packs)
3. Open "Shader Pack Settings" to adjust each effect via sliders:
   LETTERBOX_SIZE, SEPIA_STRENGTH, GRAIN_STRENGTH, VIGNETTE_STRENGTH,
   DISTORT_STRENGTH, BLOOM_STRENGTH, OUTLINE_STRENGTH

## Compatibility
- Written and verified against official Iris documentation (GLSL 330
  compatibility profile, standard uniforms: colortex0, depthtex0, viewWidth,
  viewHeight, frameTimeCounter, near, far)
- Now includes explicit gbuffers programs (terrain, sky, basic, textured,
  water) to prevent Iris from auto-reconstructing vanilla shaders with
  built-in fog — see Changelog below
- Not yet verified directly on Android translation-layer setups
  (Krypton Wrapper / Turnip / PurpleVK) — please report any visual issues
  or crashes if used on that kind of setup.

## Credit
Zaineedyou

- GitHub: https://github.com/Zaineedyou
- Discord: https://discord.com/users/1133016364857180301
- Website: https://claudia.web.id

## License
This shaderpack's outline detection logic is copied from Complementary
Shaders and is subject to the Complementary Agreement 1.3. See
`COMPLEMENTARY_LICENSE.txt` (included in this pack) for the full text.

All other code in this shaderpack is original work, licensed under
Creative Commons Attribution-NoDerivatives 4.0 International (CC BY-ND 4.0).
See `LICENSE.txt` (included in this pack) for the summary, or
https://creativecommons.org/licenses/by-nd/4.0/ for the full legal code.
