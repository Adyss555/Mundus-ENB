// Basic Sharpening by Adyss
// This also removes outlines to fight aliasing and ignores Skin

float3 PS_Sharpening(VS_OUTPUT IN) : SV_Target
{
    float2 coord   = IN.txcoord.xy;
    float2 North   = float2(coord.x, coord.y + PixelSize.y * SharpenigOffset);
    float2 South   = float2(coord.x, coord.y - PixelSize.y * SharpenigOffset);
    float2 West    = float2(coord.x + PixelSize.x * SharpenigOffset, coord.y);
    float2 East    = float2(coord.x - PixelSize.x * SharpenigOffset, coord.y);

    float3 Color   = TextureOriginal.Sample(PointSampler, coord.xy);

    float3 Sharp   = TextureOriginal.Sample(LinearSampler, North);
           Sharp  += TextureOriginal.Sample(LinearSampler, South);
           Sharp  += TextureOriginal.Sample(LinearSampler, West);
           Sharp  += TextureOriginal.Sample(LinearSampler, East); // PointSampler looks sharper but youll have to fight aliasing
           Sharp  *= 0.25;

    float  Skin           = floor(1 - TextureMask.Sample(LinearSampler, coord).a);
    float  SharpeningMask = getEdges(TextureDepth, coord, PixelSize); // Remove Depth Edges from Sharpening to prevent aliasing
           SharpeningMask = 1 - pow(SharpeningMask, 0.45) * 1 - smoothstep(0.0, SharpDistance * 0.025, getLinearizedDepth(coord));

           if(ignoreSkin)
           SharpeningMask = SharpeningMask * (1 - Skin);

    float  SharpLuma = dot(Color - Sharp, SharpeningStrength * 0.3333);
           SharpLuma = max(SharpLuma / (1 + Color), 0); // Instead of Clamping it

    return enableSharpening ? Color + SharpLuma * SharpeningMask : Color;
}
