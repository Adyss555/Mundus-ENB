// Curve Lookup Shader by Adyss
// This shader applys a texture backed contrast curve to your image
// Kinda works like a lut but only for contrast
// Expects LDR input

float3 curveLookup(float3 Color, Texture2D CurveTexture)
{
    float  LookupSize = 512;
    float  Padding    = 0.5 / LookupSize;
           Color.r    = CurveTexture.Sample(LinearSampler, float2(lerp(Padding, 1 - Padding, Color.r), 0.5));
           Color.g    = CurveTexture.Sample(LinearSampler, float2(lerp(Padding, 1 - Padding, Color.g), 0.5));
           Color.b    = CurveTexture.Sample(LinearSampler, float2(lerp(Padding, 1 - Padding, Color.b), 0.5));
    return Color;
}