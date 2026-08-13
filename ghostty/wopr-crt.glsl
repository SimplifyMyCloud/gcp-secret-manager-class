// wopr-crt.glsl — subtle green-phosphor CRT effect for Ghostty.
// Shadertoy-style entry point; iChannel0 is the rendered terminal.
// Static (no time-based flicker) => projector- and photosensitivity-safe.
// Tune the four *_STRENGTH constants to taste.

const float CURVATURE_STRENGTH = 0.06;  // barrel distortion; 0.0 = flat screen
const float SCANLINE_STRENGTH  = 0.12;  // 0.0–0.3; darkness of scanlines
const float GLOW_STRENGTH      = 0.06;  // horizontal phosphor smear/bloom
const float VIGNETTE_STRENGTH  = 0.25;  // corner darkening

vec2 curve(vec2 uv) {
    uv = uv * 2.0 - 1.0;                 // -1..1
    vec2 offset = abs(uv.yx) / vec2(4.0, 4.0);
    uv = uv + uv * offset * offset * CURVATURE_STRENGTH * 4.0;
    return uv * 0.5 + 0.5;               // back to 0..1
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    // screen curvature
    uv = curve(uv);

    // anything pushed off the tube by the curve becomes black bezel
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // base terminal image
    vec3 col = texture(iChannel0, uv).rgb;

    // horizontal phosphor glow (sample neighbours, add a little back)
    vec3 glow = texture(iChannel0, uv + vec2(0.0016, 0.0)).rgb
              + texture(iChannel0, uv - vec2(0.0016, 0.0)).rgb;
    col += glow * GLOW_STRENGTH;

    // scanlines locked to physical pixel rows
    float scan = sin(uv.y * iResolution.y * 3.14159265);
    col *= 1.0 - SCANLINE_STRENGTH * (scan * 0.5 + 0.5);

    // faint vertical aperture-grille shimmer
    float grille = 0.96 + 0.04 * sin(uv.x * iResolution.x * 3.14159265 * 0.5);
    col *= grille;

    // vignette
    vec2 vd = uv - 0.5;
    float vig = 1.0 - dot(vd, vd) * VIGNETTE_STRENGTH * 4.0;
    col *= clamp(vig, 0.0, 1.0);

    // nudge everything a hair toward green phosphor
    col.g *= 1.03;

    fragColor = vec4(col, 1.0);
}
