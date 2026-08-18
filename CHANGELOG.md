## Changelog

**v5.4.1**
- Fixed `HALATION_ENABLED` not appearing in Shader Pack Settings. The boolean macro is now defined identically in both the low-resolution prefilter and final application pass, as required by Iris/OptiFine option scanning.
- Tuned defaults toward a natural old CRT: subtle scanline roll, small edge convergence, restrained horizontal VHS instability, soft halation, and short highlight-only phosphor persistence.
- Set film scratch and dust defaults to off so the base look is an aged TV tube rather than damaged film stock.

**v5.4**
- Replaced the previous bloom stage with low-resolution **Halation**, using a warm highlight bleed with adjustable strength, radius, threshold, and warmth.
- Added **VHS Signal Mode** with horizontal jitter and head-switching noise by default; tape dropout and vertical-hold slip are enabled when `POTATO_MODE` is turned off.
- Added **CRT Color Convergence** and an animated **Interlaced Scanline Roll** to the tube-screen look.
- Added quarter-resolution **Phosphor Persistence** for a short-lived afterimage on bright moving highlights. The history buffer is retained across frames without compute shaders.
- Added `POTATO_MODE`, enabled by default. It uses a one-tap halation path and disables procedural scratch/dust loops plus the heavier VHS variants, targeting mobile launchers and low-end hardware.
- Reorganized Shader Pack Settings into Performance, CRT Look, VHS Signal, Halation, Phosphor, Film Damage, Outline, and Fog categories.
- Validated all fragment/vertex programs, full-quality and Potato configurations, Fog, and Outline linking with GLSL 330 compatibility validation.

**v5.2**
- Renamed the shaderpack from "Cinematic Old Film Shader" / CinematicFog to
  Valtique.
- Added a License section: the outline detection logic (copied from
  Complementary Shaders) is credited and marked as subject to the
  Complementary Agreement 1.3, with the full license text to be placed
  in COMPLEMENTARY_LICENSE.txt. All other code remains original work.

**v5.1**
- Ported the remaining pieces of Complementary Unbound's worldOutline that
  were previously skipped: OUTLINE_SCALED mode (adaptive outline thickness
  based on distance and FOV, using gbufferProjection and aspectRatio,
  instead of a fixed pixel size) and temporal dither (using noisetex +
  golden ratio + frameCounter, exactly as in the source) to reduce visible
  banding when scaled mode is on. Both are off by default, matching the
  reference pack's defaults. This makes the outline implementation a
  complete 1:1 port rather than a partial one (previously only the
  default fixed-thickness mode and core formula were ported; Distant
  Horizons/Voxy fade remains skipped since this pack doesn't support
  those mods).

**v5.0**
- Organized all Shader Pack Settings into categorized sub-screens using
  Iris's official `screen`/`screen.<name>` directives, instead of one long
  flat list: **Film Look** (letterbox, sepia, grain, distortion, CRT,
  bloom), **Film Damage** (scratches, dust), **Outline** (enable,
  thickness, intensity), **Fog** (enable, density, border fog strength).

**v4.9**
- Replaced the outline algorithm entirely with a 1:1 port of Complementary
  Unbound's worldOutline.glsl (a well-known, widely-used public shaderpack),
  instead of the Tricked Shaders version used previously. Key differences:
  uses inverse linear depth (1.0/depth) for the neighbor samples, a
  "slope" calculation that normalizes the depth gradient by distance
  (linearZ0²), and a smooth clamped outline value (0.0-1.0) rather than a
  binary on/off trigger — this should produce a cleaner, more precise
  edge without the widening issues from previous attempts. Simplified
  from the original by removing Distant Horizons/Voxy fade and the
  optional "scaled" mode, but the core formula (slope/threshold/outline)
  is unchanged from the source.

**v4.8**
- Fixed outline appearing 2x thicker than intended ("double-triggering").
  Per an independent code analysis report: v4.7's use of abs() when
  comparing depth differences caused the outline to trigger on BOTH sides
  of an edge — the front object's side AND the background surface behind
  it — making the line noticeably thicker than a real single-pixel
  contour. The original reference code intentionally omits abs(), only
  triggering when a neighboring sample is farther away than the center
  point, so only the front-facing object's edge lights up. Removed abs()
  while keeping the max()-of-4-samples approach for precision.

**v4.7**
- Attempted fix for outline spreading beyond a single block's actual edge.
  Root cause was that comparing an AVERAGE of the 4 diagonal depth samples
  against the center point can dilute a genuinely sharp edge (one very
  different sample averaged with three similar ones), making the
  "detected edge zone" wider than the real block boundary. Changed to
  comparing the MAXIMUM difference among the 4 samples instead — this is
  stricter and should only trigger where a sample is genuinely far off
  from center, rather than on the softened average.

**v4.6**
- Fixed the actual reported bug: outline widening beyond a single block's
  edge (not a near/far distance issue — that was a different problem
  mixed up in the previous fix). Root cause: OUTLINE_THICKNESS=3.0 meant
  the neighbor samples were offset 3 pixels away from center, making the
  detected "near edge" zone noticeably wider than the actual block
  boundary. Lowered default to 1.0 (tightest, most precise sampling) so
  the outline hugs the actual edge instead of spreading across it.

**v4.5**
- Reverted the edge-detection algorithm back to the diagonal-sample
  approach (Tricked Shaders), per user preference — Sobel wasn't wanted.
  Kept the actual bug fix from v4.4 (comparing a relative depth
  difference instead of an absolute one, so the outline works consistently
  at both close and far distances) but applied it to the diagonal
  algorithm instead of switching techniques. OUTLINE_THICKNESS default
  restored to 3.0.

**v4.4**
- Fixed outline appearing as a solid wall in the far distance while
  completely missing nearby blocks (including grass right in front of the
  player). Root cause: the Sobel gradient is computed from linearized
  depth, which grows very fast (non-linearly) with distance, while the
  threshold was only growing quadratically — so at far distances the
  gradient always exceeded the threshold (outline triggers everywhere,
  looking like a wall), and at close range the gradient was tiny and
  almost never exceeded it (no outline on nearby blocks at all).
  Fix: divide the gradient by the center depth first (making it a relative
  gradient) before comparing against a fixed threshold — this keeps the
  scale consistent regardless of distance from the camera.

**v4.3**
- Replaced the outline algorithm again — this time with the Sobel
  operator, the standard industry technique for edge detection (used
  widely in Godot, Unity, Bevy engine outline/edge-detect implementations).
  The previous diagonal-average approach (copied from Tricked Shaders) was
  detecting edges a few pixels off from the actual block boundary. Sobel
  uses an 8-sample weighted kernel (Gx/Gy gradient) which is mathematically
  more precise for locating exactly where a sharp depth change occurs.
  Default OUTLINE_THICKNESS lowered from 3.0 to 1.0 to match Sobel's
  tighter, more precise sampling pattern.

**v4.2**
- Fixed a severe checkerboard/line artifact across the whole screen (and
  a huge FPS drop to ~3). Root cause: outline was reading depth from a
  half-resolution downsampled buffer (colortex1), storing raw NDC depth
  in the alpha channel. Depth values are extremely precision-sensitive,
  and packing raw depth into a color buffer's alpha channel at reduced
  resolution likely hit a low-precision buffer format on this device/
  driver, causing severe banding.
  Fix: outline no longer uses downsampling at all — it reads depthtex0
  directly at full resolution, exactly like the reference shader's
  original code. Only bloom (which doesn't need per-pixel depth
  precision) still uses the downsampled colortex1 buffer.

**v4.1**
- Replaced the outline math with a verbatim copy of the reference
  shaderpack's actual formula, instead of a reimplementation. The bug:
  my version linearized each depth sample individually then averaged
  them; the reference linearizes the AVERAGE of the raw depth samples
  instead — `linearize(average(raw))` is not the same as
  `average(linearize(raw))` since linearize is a non-linear function.
  Also the reference's linearize formula itself was different
  (`near / (1 - D)` vs the near/far perspective formula used before).
  This mismatch was likely why shadowed/dark areas showed a flat gray
  wall instead of a subtle edge line.

**v4.0**
- Performance optimization: bloom and outline are now processed at half
  resolution (colortex1, using Iris's official size.buffer directive),
  then blended back at full resolution. This significantly reduces the
  number of texture samples per frame for these two effects (which are
  the most expensive parts of the shader — bloom alone was 9 samples per
  pixel) while keeping the visual result very close to the full-res
  version, since both effects rely on blurring/averaging nearby pixels
  rather than needing per-pixel precision.
- This required splitting composite into 3 passes instead of 1, because
  Iris requires that a single program can only render to buffers of
  identical size — colortex0 (full resolution) and colortex1 (half
  resolution) can't be written to in the same pass.

**v3.2**
- Fixed outline causing a bright white overexposed look instead of a
  subtle edge line. The previous version used `mix(color, vec3(1.0),
  edge * opacity)`, which fully overwrites the color with solid white —
  but the actual reference shader code multiplies the original color by
  a brightness factor (`color *= OUTLINE_BRIGHTNESS`), keeping the block's
  texture and color visible, just brighter at edges. Rewrote to match
  this exactly. Also added an OUTLINE_ENABLED toggle, off by default —
  the reference pack also ships with outline disabled by default.

**v3.1**
- Replaced the outline algorithm entirely with a different, proven-working
  approach copied from a reference shaderpack (Tricked Shaders' outline.glsl):
  samples 4 diagonal points instead of 4 orthogonal ones, averages them,
  and compares against the center depth using a threshold that scales
  QUADRATICALLY with distance (not linearly like the previous attempt).
  Split the old single OUTLINE_STRENGTH into three separate options:
  OUTLINE_THRESHOLD (edge detection sensitivity), OUTLINE_THICKNESS (how
  far apart the sample points are), and OUTLINE_OPACITY (how visible the
  outline is once detected).

**v3.0**
- Fixed the sun/moon appearing huge and blurry whenever FOG_ENABLED was
  turned on. Root cause: sky objects (sun/moon/stars) were falling back to
  gbuffers_textured, which has fog applied — but sky objects render at a
  distance that isn't representative for normal fog distance math, so the
  fog calculation produced extreme values that blew up the sun into a big
  blurry white circle. Added a dedicated gbuffers_skytextured program with
  no fog logic at all, so sun/moon/stars render normally regardless of the
  fog setting.

**v2.9**
- Confirmed: fog fix from v2.8 works correctly (verified in-game, no more
  white wall covering the screen). The white-wall issue reported earlier
  was actually the outline bug, not fog.
- Ported the fixed outline function from the 1.20.1 rebuild (relative
  depth-difference comparison instead of absolute) — outline is back and
  should no longer cover most of the screen.
- Split dust spot strength into its own DUST_STRENGTH slider, separate
  from SCRATCH_STRENGTH (previously dust was hardcoded to 70% of scratch
  strength with no independent control).

**v2.8**
- Removed the block outline effect entirely (per user request) — it still
  had visual issues (covering almost the whole screen instead of just
  edges) that were only properly root-caused and fixed on the 1.20.1
  rebuild. Rather than guess at a fix here, it's removed until it can be
  brought over properly.
- Replaced the old FOG_PUSHBACK approach (pushing vanilla fogColor mixing
  further out based on distance) with the same depth-based custom fog
  approach proven working on the 1.20.1 rebuild: FOG_ENABLED toggle
  (off by default) + FOG_DENSITY slider, using the official Iris fog
  tutorial formula instead of a hand-rolled distance heuristic.

**v2.7**
- Compared directly against a working reference shaderpack (Tricked
  Shaders) that the user confirmed has a working Shader Pack Settings
  menu on this exact device/mod setup. Found the actual difference:
  the working pack declares all its options with `#define NAME value //
  [list]`, not `const float NAME = value; // [list]`. Converted every
  option in this pack (LETTERBOX_SIZE, GRAIN_STRENGTH, DISTORT_STRENGTH,
  BLOOM_STRENGTH, SEPIA_STRENGTH, OUTLINE_STRENGTH, SCRATCH_STRENGTH,
  CRT_STRENGTH, BORDER_FOG_STRENGTH, FOG_PUSHBACK_TERRAIN/_ITEM/_ENTITY)
  from const to #define to match the proven-working pattern.
- Also removed spaces around `=` in the `sliders` directive in
  shaders.properties (`sliders=...` instead of `sliders = ...`), matching
  the reference pack's exact formatting.

**v2.6**
- Log confirmed v2.5 loaded successfully with no GLSL compile errors
  ("Shaders Reloaded!"), yet Shader Pack Settings remained empty. Found
  two things that could interfere with Iris's option scanner: (1) an
  extra "-- 0.0 = ..." text fragment after a value list on
  BORDER_FOG_STRENGTH, which isn't part of the documented format, and
  (2) the same const name (FOG_PUSHBACK) was declared identically in
  three different .fsh files. Per Iris docs this rule is documented for
  #define macros, not const, but renamed them to unique per-file names
  (FOG_PUSHBACK_TERRAIN/_ITEM/_ENTITY) to rule it out as a cause.
- If the settings screen is still empty after this, the cause is likely
  outside the shader files themselves (e.g. a mod interaction specific to
  this heavily modded Fabric setup) rather than a GLSL issue, since the
  pack compiles and runs without errors.

**v2.5**
- Added manual custom fog to gbuffers_terrain, gbuffers_textured, and
  gbuffers_textured_lit, using the vanilla fogColor uniform but with a
  FOG_PUSHBACK multiplier (default 1.4x) on the far distance. This pushes
  where fog starts appearing further out, so it hugs closer to the actual
  render distance edge instead of feeling like it starts halfway through
  your view.
- Known limitation: this only affects rendered terrain/entities/items.
  The sky/void color seen behind unrendered chunks (gbuffers_skybasic) is
  a separate buffer and isn't affected by this fog pushback — per the
  Minecraft Wiki, that background is literally the OpenGL clear color set
  to FogColor, which happens before any shader runs and can't be "pushed
  back" the same way.

**v2.4**
- IMPORTANT FINDING: per the official Minecraft Wiki, fog is always
  rendered in every biome/dimension, and the sky below the horizon is
  literally the OpenGL clear color set to the same value as the FogColor
  uniform — this happens before any fragment shader runs. This means the
  border/distance fog cannot be fully removed by shader code alone,
  including by this pack's gbuffers programs. This is a known limitation
  shared by other shaderpacks (Bliss, Photon have open issues about this).
- Fixed dust spots barely appearing (spawn chance was too low: 30% chance
  every ~1.25s). Increased to 60% chance, bigger radius, one more spot.
- Reduced grain noise speed (was updating so fast it looked like it was
  "flowing" downward — an optical illusion from high-speed random noise,
  not an actual bug in scratch positioning)

**v2.3**
- Fixed sepia formula: previous version converted color to grayscale
  (luma) first, then tinted it — this stripped ALL original saturation,
  making grass look dull gray-yellow instead of a warm film tone. Now uses
  a proper sepia color matrix mixed with the original color, so greens
  and other hues stay recognizable while still getting the old-film tint.

**v2.2**
- Corrected the border fog approach entirely after checking real reference
  shaderpacks (Tricked Shaders, Derivative). Border fog is NOT an automatic
  vanilla/Iris feature — it's something each shaderpack builds manually if
  it wants that aesthetic. Previous versions mistakenly tried to intercept
  vanilla fog uniforms; this pack now implements its own optional border
  fog function (BORDER_FOG_STRENGTH), default set to 0.0 (fully off).
  With it off, distant unloaded chunks show the sky/void color directly,
  with no white/gray haze added by this shader.
- Sepia is now fully independent from any fog logic (pure color grading
  across the whole frame, as it should have been from the start)

**v2.1**
- Added explicit override for vanilla border fog (the fog that hides the
  render distance edge) using Iris's official fogColor/fogDensity/fogStart/
  fogEnd uniforms. Border fog is a game-level feature that blends before
  composite runs, so it can't be fully removed — this override replaces the
  bright vanilla fog color with a dark sepia tone so it blends into the
  film aesthetic instead of standing out as a bright white wall.
- Adjusted letterbox size, scratch strength/speed for better balance

**v2.0**
- Fixed persistent gray fog that appeared regardless of in-game fog
  settings. Root cause: Iris auto-reconstructs vanilla shaders (with
  built-in exponential fog) for any gbuffers category not explicitly
  provided by the pack. Added gbuffers_skybasic, gbuffers_basic,
  gbuffers_textured, and gbuffers_water to cover sky, particles, and
  underwater rendering.
- Removed cinematic fog effect entirely per user request
- Straightened film scratches (previously had random curvature)
- Made dust spots perfectly round (previously irregular ellipses)
- Adjusted letterbox size and scratch speed/strength for a more balanced look

**v1.0**
- Initial release: letterbox, sepia, grain, lens distortion, block outline,
  bloom, film scratches/dust, CRT dot mask
