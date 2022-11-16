// Original Shader by Sandvich Maker
// Adjustments by Adyss

// Functions
float4 filter4x4(Texture2D tex, float2 uv, float2 pixelsize)
{
    float4 res = 0.0;

    static const float2 offsets[4] =
    {
        float2(-0.5, -0.5),
        float2(0.5, -0.5),
        float2(-0.5, 0.5),
        float2(0.5, 0.5),
    };

    for (int i = 0; i < 4; i++)
    {
        res += tex.Sample(LinearSampler, uv + offsets[i] * pixelsize);
    }

    return res * 0.25;
}

float3 integerHash3(uint3 x)
{
	static const uint K = 1103515245U;  // GLIB C
	x = ((x >> 8U) ^ x.yzx) * K;
	x = ((x >> 8U) ^ x.yzx) * K;
	x = ((x >> 8U) ^ x.yzx) * K;

	return x * rcp(0xffffffffU);
}

float4	PS_RainGeneration(VS_OUTPUT IN, float4 v0 : SV_Position0) : SV_Target
{
    // Find weathers
    int currWeather = findCurrentWeather();
    int prevWeather = findPrevWeather();

    if(!enableRain && (currWeather == 4 || prevWeather == 4))
    return 0;

    float4 res     = 0.0;
    float2 uv      = IN.txcoord.xy;
    float2 center  = round(v0.xy / rainSize) * rainSize;
    float3 rand    = integerHash3(int3(center, Timer.x * 16677216.0));
    float  size    = rainSize * (0.5 + rand.y);
           res.xyz = rand.x > (1.0 - rainChance * 0.001) ? 1.0 : 0.0;
           res    *= saturate(1.0 - length(center - v0.xy) / (size * 0.5));
           res.x  *= clamp(((center - v0.xy) / (size * 0.5)), -1.0, 1.0);
    float4 prev    = filter4x4(RenderTargetRGBA64F, float2(uv.x + (rand.x - 0.5) * rainDispersion * 0.005, uv.y - rainSlide * 0.01 + rainDispersion * (rand.z - 0.5) * 0.01), PixelSize);
           res     = lerp(prev, res, rainFade);
           res.w   = 1.0;
    return res;
}

float4 PS_Copy(VS_OUTPUT IN, float4 v0 : SV_Position0, uniform Texture2D tex) : SV_Target
{
    return tex.Load(int3(v0.xy, 0));
}

float3 PS_DrawRain(VS_OUTPUT IN) : SV_Target
{
    float3 color    = TextureColor.Sample(PointSampler, IN.txcoord.xy);

    if(!enableRain)
    return color;

    float3 rain     = TextureColor.Sample(LinearSampler, IN.txcoord.xy + filter4x4(RenderTargetRGBA64F, IN.txcoord.xy, PixelSize) * rainRange * 10.0);

    // Find weathers
    int currWeather = findCurrentWeather();
    int prevWeather = findPrevWeather();

    // Rain is weather group 4
    if(currWeather == 4)
    {
        color = lerp(color, rain, Weather.z);
    }
    else if(prevWeather == 4)
    {
        color = lerp(rain, color, Weather.z);
    }

    return color;
}

