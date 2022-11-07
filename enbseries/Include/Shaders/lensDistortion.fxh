// Radial CA by Barrel Distortion
// Original code by kingeric1992
// Fisheye Lens Distortion by Marty McFly

float2 Distortion( float2 coord, float curve)
{
    float  Radius = length(coord);
    return pow(2 * Radius, curve) * coord / Radius * RadialCA * 0.01 * 0.1;
}

//.rgb == color, .a == offset
float4 Spectrum[7] =
{
    float4(1.0, 0.0, 0.0,  1.0),//red
    float4(1.0, 0.5, 0.0,  0.7),//orange
    float4(1.0, 1.0, 0.0,  0.3),//yellow
    float4(0.0, 1.0, 0.0,  0.0),//green
    float4(0.0, 0.0, 1.0, -0.6),//blue
    float4(0.3, 0.0, 0.5, -0.8),//indigo
    float4(0.1, 0.0, 0.2, -1.0) //purple
};

float3 LensDist(float2 texcoord)
{
    float4 coord=0.0;
    coord.xy=texcoord;
    coord.w=0.0;
    float2 center;

    center.x = coord.x-0.5;
    center.y = coord.y-0.5;
    float LensZoom = 1.0 / 0.5 + (lensDistortion * (lensDistortion > 0.0 ? -0.0025 : -0.00075));

    float r2 = (texcoord.x-0.5) * (texcoord.x-0.5) + (texcoord.y-0.5) * (texcoord.y-0.5);
    float f = 0;

    f = 1 + r2 * lensDistortion * (lensDistortion > 0.0 ? 0.003 : 0.0015);

    float x = f*LensZoom*(coord.x-0.5)+0.5;
    float y = f*LensZoom*(coord.y-0.5)+0.5;
    float2 Coords = f*LensZoom*(center.xy*0.5)+0.5;

    return TextureColor.Sample(LinearSampler,Coords);
}

float3 SampleBlurredImage(float3 Original, float2 coord)
{
    float2 pixelSize = float2(1, ScreenSize.z);
    float2 Offset    = (coord - 0.5) * pixelSize;       //length to center
           Offset    = Distortion(Offset, barrelPower) / pixelSize * RadialCA * 0.1;
    float  weight[11]= {0.082607, 0.080977, 0.076276, 0.069041, 0.060049, 0.050187, 0.040306, 0.031105, 0.023066, 0.016436, 0.011254};
    float3 CA        = Original * weight[0];

    for(int i=1; i<11; i++)
    {
        CA += TextureColor.Sample(LinearSampler, coord + Offset * i) * weight[i];
        CA += TextureColor.Sample(LinearSampler, coord - Offset * i) * weight[i];
    }

    return CA;
}

float3 LensCA(float2 coord) : SV_Target
{
    float3 Original = TextureColor.Sample(PointSampler, coord);
    float2 pixelSize = float2(1, ScreenSize.z);
    float2 Offset    = (coord - 0.5) * pixelSize;       //length to center
           Offset    = Distortion(Offset, barrelPower) / pixelSize;
    float3 Color;

    for(int i=0; i<7; i++)
    {
        Color.rgb = max(Color.rgb, TextureColor.Sample(LinearSampler, coord - Offset * Spectrum[i].a).rgb * Spectrum[i].rgb);
    }

    return Color;
}
