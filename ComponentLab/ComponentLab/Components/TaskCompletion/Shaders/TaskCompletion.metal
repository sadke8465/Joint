#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// MARK: - Shared helpers

/// SwiftUI layer samples arrive premultiplied. Straight (unpremultiplied) colour is
/// what you want for any mixing, so unpremultiply, work, then premultiply back.
static inline half3 straightRGB(half4 premultiplied) {
    return premultiplied.a > 0.001h ? premultiplied.rgb / premultiplied.a : half3(0.0h);
}

static inline half4 premultiply(half3 straight, half alpha) {
    return half4(straight * alpha, alpha);
}

// MARK: - Swell
//
// A radial travelling wave: sin(omega * t - k * r), damped by exp(-decay * t').
// Every pixel computes its own arrival time from its distance to the origin, so the
// choreography is emergent from layout rather than authored on a timeline.

[[ stitchable ]] half4 swell(float2 position,
                             SwiftUI::Layer layer,
                             float2 size,
                             float2 origin,
                             float time,
                             float amplitude,
                             float wavelength,
                             float speed,
                             float decay,
                             float rise,
                             float edgeGain,
                             float crestHighlight)
{
    float2 delta = position - origin;
    float distance = length(delta);

    // Time since the wavefront reached this pixel. Negative means it hasn't arrived.
    float local = time - distance / max(speed, 1.0);
    if (local <= 0.0) {
        return layer.sample(position);
    }

    // Spatial frequency from a wavelength expressed in points (easier to judge than radians).
    float k = 6.28318530718 / max(wavelength, 1.0);
    float phase = k * speed * local;

    // edgeGain claws back some of the exponential decay further from the origin, so the
    // far edge of the card still visibly moves without having to raise amplitude globally.
    float reach = saturate(distance / max(length(size), 1.0));
    float sustain = 1.0 + edgeGain * reach;

    // The packet has to ramp in as well as out. exp(-decay * local) peaks at local = 0 —
    // exactly at the wavefront — so amplitude arrives instantly. sin(0) = 0 keeps position
    // continuous, but the slope jumps from zero to maximum and that crease is clearly
    // visible where the wave crosses an edge. smoothstep gives the front a real taper.
    float onset = smoothstep(0.0, max(rise, 0.0001), local);
    float envelope = amplitude * sustain * onset * exp(-decay * local);
    float displacement = envelope * sin(phase);

    float2 direction = distance > 0.0001 ? delta / distance : float2(0.0);
    half4 sampled = layer.sample(position + direction * displacement);

    if (crestHighlight > 0.0 && sampled.a > 0.001h) {
        // The wave's slope, not its height, is where a real surface catches light.
        float slope = envelope * cos(phase) / max(amplitude, 0.001);
        half3 straight = straightRGB(sampled);
        straight = clamp(straight + half3(half(crestHighlight * slope)), 0.0h, 1.0h);
        return premultiply(straight, sampled.a);
    }

    return sampled;
}

// MARK: - Liquid metal
//
// Treats the layer's alpha channel as a heightfield, derives a surface normal from it,
// and lights that normal with a moving directional light. Because the normals come from
// the glyph edges, the highlight curves around the letterforms instead of sliding over
// them — that is the difference between chrome and a gradient overlay.

[[ stitchable ]] half4 liquidMetal(float2 position,
                                   SwiftUI::Layer layer,
                                   float2 size,
                                   float progress,
                                   float bandWidth,
                                   float bandSoftness,
                                   float bandTilt,
                                   float lightAngle,
                                   float metalness,
                                   float roughness,
                                   float heightScale,
                                   float refraction,
                                   half4 warmTint,
                                   half4 coolTint)
{
    float width = max(size.x, 1.0);

    // Tilted, normalised sweep coordinate.
    float u = (position.x + (position.y - size.y * 0.5) * tan(bandTilt)) / width;

    // Let the band start fully off the leading edge and finish fully off the trailing one.
    float halfBand = max(bandWidth, 0.001);
    float center = progress * (1.0 + 2.0 * halfBand) - halfBand;

    float offset = (u - center) / halfBand;
    float band = exp(-offset * offset * max(bandSoftness, 0.01));

    // Refraction: push samples along the band's gradient so content warps under a
    // moving lens at the leading edge rather than simply changing colour.
    float gradient = -2.0 * offset * band / halfBand;
    float2 refracted = position + float2(gradient * refraction * width * 0.001, 0.0);

    half4 sampled = layer.sample(refracted);
    if (sampled.a <= 0.001h || metalness <= 0.0 || band <= 0.001) {
        return sampled;
    }

    // Alpha as heightfield -> normal, by central difference.
    const float e = 1.0;
    float aL = layer.sample(refracted + float2(-e, 0.0)).a;
    float aR = layer.sample(refracted + float2( e, 0.0)).a;
    float aD = layer.sample(refracted + float2(0.0, -e)).a;
    float aU = layer.sample(refracted + float2(0.0,  e)).a;

    float3 normal = normalize(float3((aL - aR) * heightScale,
                                     (aD - aU) * heightScale,
                                     1.0));

    float3 lightDir = normalize(float3(cos(lightAngle), sin(lightAngle), 0.55));
    float ndotl = dot(normal, lightDir);

    // Broad diffuse-ish ramp between the two tints, plus a tight specular whose
    // sharpness is driven by roughness.
    float ramp = smoothstep(-0.6, 1.0, ndotl);
    half3 metalColor = mix(straightRGB(coolTint), straightRGB(warmTint), half(ramp));

    float specular = pow(saturate(ndotl), mix(90.0, 6.0, saturate(roughness)));
    metalColor = clamp(metalColor + half3(half(specular)), 0.0h, 1.0h);

    half3 base = straightRGB(sampled);
    half mixAmount = half(saturate(band * metalness));
    half3 result = mix(base, metalColor, mixAmount);

    return premultiply(result, sampled.a);
}
