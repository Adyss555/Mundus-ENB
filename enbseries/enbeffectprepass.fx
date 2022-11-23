//========================== V1.0 ===========================//
//                                                           //
//  ███╗   ███╗██╗   ██╗███╗   ██╗██████╗ ██╗   ██╗███████╗  //
//  ████╗ ████║██║   ██║████╗  ██║██╔══██╗██║   ██║██╔════╝  //
//  ██╔████╔██║██║   ██║██╔██╗ ██║██║  ██║██║   ██║███████╗  //
//  ██║╚██╔╝██║██║   ██║██║╚██╗██║██║  ██║██║   ██║╚════██║  //
//  ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██████╔╝╚██████╔╝███████║  //
//  ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝  ╚═════╝ ╚══════╝  //
//                   an ENB preset by Adyss                  //
//===========================================================//

// Load global config
#include "Include/mundusConfig.fxh"

#define SHADOWLIFT  0.01

//===========================================================//
// Textures                                                  //
//===========================================================//
Texture2D   TextureOriginal;     // color R16B16G16A16 64 bit hdr format
Texture2D   TextureColor;        // color which is output of previous technique (except when drawed to temporary render target), R16B16G16A16 64 bit hdr format
Texture2D   TextureDepth;        // scene depth R32F 32 bit hdr format
Texture2D   TextureJitter;       // blue noise
Texture2D   TextureMask;         // alpha channel is mask for skinned objects (less than 1) and amount of sss
Texture2D   TextureNormal;       // Normal maps. Alpha seems to only effect a few selected objects (specular map i guess)

Texture2D   RenderTargetRGBA32;  // R8G8B8A8 32 bit ldr format
Texture2D   RenderTargetRGBA64;  // R16B16G16A16 64 bit ldr format
Texture2D   RenderTargetRGBA64F; // R16B16G16A16F 64 bit hdr format
Texture2D   RenderTargetR16F;    // R16F 16 bit hdr format with red channel only
Texture2D   RenderTargetR32F;    // R32F 32 bit hdr format with red channel only
Texture2D   RenderTargetRGB32F;  // 32 bit hdr format without alpha

//===========================================================//
// Internals                                                 //
//===========================================================//
#include "Include/Shared/Globals.fxh"
#include "Include/Shared/ReforgedUI.fxh"
#include "Include/Shared/Conversions.fxh"
#include "Include/Shared/BlendingModes.fxh"

//===========================================================//
// UI                                                        //
//===========================================================//

UI_MESSAGE(1,                   "|----- Sun -----")
UI_BOOL(enableSunGlow,          "| Enable Glow",                    false)
UI_FLOAT(glowStrength,          "|  Glow Strength",                 0.1, 3.0, 1.0)
UI_FLOAT(glowThreshold,         "|  Glow Threshold",                0.0, 1.0, 0.1)
UI_FLOAT(glowCurve,             "|  Glow Curve",                    0.1, 3.0, 1.0)
UI_FLOAT3(glowTint,             "|  Glow Tint",                     0.5, 0.5, 0.5)
UI_FLOAT(sunDarkening,          "|  Darken around Sun",             0.0, 1.0, 0.0)
UI_WHITESPACE(1)
UI_MESSAGE(2,                   "|----- Sharpening -----")
UI_BOOL(enableSharpening,       "| Enable Sharpening",              false)
UI_FLOAT(SharpenigOffset,       "|  Sharpening Offset",             0.2, 2.0, 1.0)
UI_FLOAT(SharpeningStrength,    "|  Sharpening Strength",      	    0.2, 3.0, 1.0)
UI_FLOAT(SharpDistance,         "|  Sharpening Fadeout",            0.1, 15.0, 3.0)
UI_BOOL(ignoreSkin,             "|  Ignore Skin",                   false)
UI_WHITESPACE(2)
UI_MESSAGE(3,                   "|----- Weather Fog -----")
UI_BOOL(enableFog,              "| Enable Fog",                     false)
UI_BOOL(showFogMask,            "| Show Fog Mask",                  false)
UI_MESSAGE(4,                   "| Tweak each weather below")
UI_WHITESPACE(3)
UI_MESSAGE(5,                   "|--- Clear Weather Fog ---")
UI_FLOAT_DN(w1fogDensity,       "| Clear Fog Density",              0.0, 100.0, 0.0)
UI_FLOAT_DN(w1l1nearFog,        "| Clear near Fog Distance",        0.0, 10.0, 0.2)
UI_FLOAT_DN(w1l1farFog,         "| Clear near Fog Closeup",         0.0, 10.0, 0.0)
UI_FLOAT3_DN(w1l1fogCol,        "| Clear near Fog Color",           0.3, 0.3, 0.3)
UI_FLOAT_DN(w1l2nearFog,        "| Clear far Fog Distance",         0.0, 10.0, 1.0)
UI_FLOAT_DN(w1l2farFog,         "| Clear far Fog Closeup",          0.0, 10.0, 0.3)
UI_FLOAT3_DN(w1l2fogCol,        "| Clear far Fog Color",            0.3, 0.3, 0.3)
UI_WHITESPACE(6)
UI_MESSAGE(6,                   "|--- Cloudy Weather Fog ---")
UI_FLOAT_DN(w2fogDensity,       "| Cloudy Fog Density",             0.0, 100.0, 0.0)
UI_FLOAT_DN(w2l1nearFog,        "| Cloudy near Fog Distance",       0.0, 10.0, 0.2)
UI_FLOAT_DN(w2l1farFog,         "| Cloudy near Fog Closeup",        0.0, 10.0, 0.0)
UI_FLOAT3_DN(w2l1fogCol,        "| Cloudy near Fog Color",          0.3, 0.3, 0.3)
UI_FLOAT_DN(w2l2nearFog,        "| Cloudy far Fog Distance",        0.0, 10.0, 1.0)
UI_FLOAT_DN(w2l2farFog,         "| Cloudy far Fog Closeup",         0.0, 10.0, 0.3)
UI_FLOAT3_DN(w2l2fogCol,        "| Cloudy far Fog Color",           0.3, 0.3, 0.3)
UI_WHITESPACE(9)
UI_MESSAGE(7,                   "|--- Overcast Weather Fog ---")
UI_FLOAT_DN(w3fogDensity,       "| Overcast Fog Density",           0.0, 100.0, 0.0)
UI_FLOAT_DN(w3l1nearFog,        "| Overcast near Fog Distance",     0.0, 10.0, 0.2)
UI_FLOAT_DN(w3l1farFog,         "| Overcast near Fog Closeup",      0.0, 10.0, 0.0)
UI_FLOAT3_DN(w3l1fogCol,        "| Overcast near Fog Color",        0.3, 0.3, 0.3)
UI_FLOAT_DN(w3l2nearFog,        "| Overcast far Fog Distance",      0.0, 10.0, 1.0)
UI_FLOAT_DN(w3l2farFog,         "| Overcast far Fog Closeup",       0.0, 10.0, 0.3)
UI_FLOAT3_DN(w3l2fogCol,        "| Overcast far Fog Color",         0.3, 0.3, 0.3)
UI_WHITESPACE(12)
UI_MESSAGE(8,                   "|--- Rain Weather Fog ---")
UI_FLOAT_DN(w4fogDensity,       "| Rain Fog Density",               0.0, 100.0, 0.0)
UI_FLOAT_DN(w4l1nearFog,        "| Rain near Fog Distance",         0.0, 10.0, 0.2)
UI_FLOAT_DN(w4l1farFog,         "| Rain near Fog Closeup",          0.0, 10.0, 0.0)
UI_FLOAT3_DN(w4l1fogCol,        "| Rain near Fog Color",            0.3, 0.3, 0.3)
UI_FLOAT_DN(w4l2nearFog,        "| Rain far Fog Distance",          0.0, 10.0, 1.0)
UI_FLOAT_DN(w4l2farFog,         "| Rain far Fog Closeup",           0.0, 10.0, 0.3)
UI_FLOAT3_DN(w4l2fogCol,        "| Rain far Fog Color",             0.3, 0.3, 0.3)
UI_WHITESPACE(15)
UI_MESSAGE(9,                   "|--- Snow Weather Fog ---")
UI_FLOAT_DN(w5fogDensity,       "| Snow Fog Density",               0.0, 100.0, 0.0)
UI_FLOAT_DN(w5l1nearFog,        "| Snow near Fog Distance",         0.0, 10.0, 0.2)
UI_FLOAT_DN(w5l1farFog,         "| Snow near Fog Closeup",          0.0, 10.0, 0.0)
UI_FLOAT3_DN(w5l1fogCol,        "| Snow near Fog Color",            0.3, 0.3, 0.3)
UI_FLOAT_DN(w5l2nearFog,        "| Snow far Fog Distance",          0.0, 10.0, 1.0)
UI_FLOAT_DN(w5l2farFog,         "| Snow far Fog Closeup",           0.0, 10.0, 0.3)
UI_FLOAT3_DN(w5l2fogCol,        "| Snow far Fog Color",             0.3, 0.3, 0.3)
UI_WHITESPACE(18)
UI_MESSAGE(10,                  "|--- Foggy Weather Fog ---")
UI_FLOAT_DN(w6fogDensity,       "| Foggy Fog Density",              0.0, 100.0, 0.0)
UI_FLOAT_DN(w6l1nearFog,        "| Foggy near Fog Distance",        0.0, 10.0, 0.2)
UI_FLOAT_DN(w6l1farFog,         "| Foggy near Fog Closeup",         0.0, 10.0, 0.0)
UI_FLOAT3_DN(w6l1fogCol,        "| Foggy near Fog Color",           0.3, 0.3, 0.3)
UI_FLOAT_DN(w6l2nearFog,        "| Foggy far Fog Distance",         0.0, 10.0, 1.0)
UI_FLOAT_DN(w6l2farFog,         "| Foggy far Fog Closeup",          0.0, 10.0, 0.3)
UI_FLOAT3_DN(w6l2fogCol,        "| Foggy far Fog Color",            0.3, 0.3, 0.3)
UI_WHITESPACE(21)
UI_MESSAGE(11,                  "|--- Ash Weather Fog ---")
UI_FLOAT_DN(w7fogDensity,       "| Ash Fog Density",                0.0, 100.0, 0.0)
UI_FLOAT_DN(w7l1nearFog,        "| Ash near Fog Distance",          0.0, 10.0, 0.2)
UI_FLOAT_DN(w7l1farFog,         "| Ash near Fog Closeup",           0.0, 10.0, 0.0)
UI_FLOAT3_DN(w7l1fogCol,        "| Ash near Fog Color",             0.3, 0.3, 0.3)
UI_FLOAT_DN(w7l2nearFog,        "| Ash far Fog Distance",           0.0, 10.0, 1.0)
UI_FLOAT_DN(w7l2farFog,         "| Ash far Fog Closeup",            0.0, 10.0, 0.3)
UI_FLOAT3_DN(w7l2fogCol,        "| Ash far Fog Color",              0.3, 0.3, 0.3)
UI_WHITESPACE(24)
UI_MESSAGE(12,                  "|--- Blackreach Weather Fog ---")
UI_FLOAT_DN(w8fogDensity,       "| Blackreach Fog Density",         0.0, 100.0, 0.0)
UI_FLOAT_DN(w8l1nearFog,        "| Blackreach near Fog Distance",   0.0, 10.0, 0.2)
UI_FLOAT_DN(w8l1farFog,         "| Blackreach near Fog Closeup",    0.0, 10.0, 0.0)
UI_FLOAT3_DN(w8l1fogCol,        "| Blackreach near Fog Color",      0.3, 0.3, 0.3)
UI_FLOAT_DN(w8l2nearFog,        "| Blackreach far Fog Distance",    0.0, 10.0, 1.0)
UI_FLOAT_DN(w8l2farFog,         "| Blackreach far Fog Closeup",     0.0, 10.0, 0.3)
UI_FLOAT3_DN(w8l2fogCol,        "| Blackreach far Fog Color",       0.3, 0.3, 0.3)
UI_WHITESPACE(27)
UI_MESSAGE(13,                  "|--- Interior Fog ---")
UI_FLOAT(w9fogDensity,          "| Interior Fog Density",           0.0, 100.0, 0.0)
UI_FLOAT(w9l1nearFog,           "| Interior near Fog Distance",     0.0, 10.0, 0.2)
UI_FLOAT(w9l1farFog,            "| Interior near Fog Closeup",      0.0, 10.0, 0.0)
UI_FLOAT3(w9l1fogCol,           "| Interior near Fog Color",        0.3, 0.3, 0.3)
UI_FLOAT(w9l2nearFog,           "| Interior far Fog Distance",      0.0, 10.0, 1.0)
UI_FLOAT(w9l2farFog,            "| Interior far Fog Closeup",       0.0, 10.0, 0.3)
UI_FLOAT3(w9l2fogCol,           "| Interior far Fog Color",         0.3, 0.3, 0.3)

//===========================================================//
// Functions                                                 //
//===========================================================//
#include "Include/Shaders/sharpening.fxh"

// Per weather setup
#include "Include/Shared/WeatherSeperation.fxh"
#include "Include/Shaders/WeatherData/fogData.fxh"

float2 getSun()
{
    float3 Sundir       = SunDirection.xyz / SunDirection.w;
    float2 Suncoord     = Sundir.xy / Sundir.z;
           Suncoord     = Suncoord * float2(0.48, ScreenSize.z * 0.48) + 0.5;
           Suncoord.y   = 1.0 - Suncoord.y;
    return Suncoord;
}

float getGlow(float2 uv, float2 pos)
{
    return 1.0 / (length(uv - pos) * 16.0 + 1.0);
}

// Output is 1 if looking directly at the sun. As soon as you move away from it, it gets lower. If the sun is not on the screen the output is 0;
float getSunvisibility()
{
    return saturate(lerp(1, 0, distance(getSun(), float2(0.5, 0.5))));
}

//===========================================================//
// Pixel Shaders                                             //
//===========================================================//
float4	PS_ClearBuffer(VS_OUTPUT IN) : SV_Target
{
    return 0.0;
}

float3	PS_Color(VS_OUTPUT IN) : SV_Target
{
    float2 coord        = IN.txcoord.xy;
    float3 color        = TextureColor.Sample(PointSampler, coord);
    float4 albedo       = TextureMask.Sample(PointSampler, coord);

    // Lighting tweaks
    // I noticed trees glowing and the sky full white with this buffer. So i reduced it
    float  specular     = TextureNormal.Sample(PointSampler, coord).a;
    float  highspec     = floor(specular);
           specular    -= highspec;


    float  mid          = sqrt(GetLuma(color, Rec709));
    float  shadows      = saturate(max3(color));
           shadows      = (1 - shadows);
           shadows     *= shadows;
           shadows     *= shadows;
           color        = lerp(color, lerp(color, max(color, albedo.rgb), shadows), SHADOWLIFT);

           //color       += min(specular, shadows) / (1 + color);

    // Sample fog and Blend
    int    currWeather  = findCurrentWeather();
    int    prevWeather  = findPrevWeather();

    float3 fog          = RenderTargetRGBA64.Sample(LinearSampler, coord); // Sample combined fog planes
    float3 fogColor     = weatherLerp(fogData, colorFogLayer1, currWeather, prevWeather) * weatherLerp(fogData, colorFogLayer2, currWeather, prevWeather);

    if(showFogMask) return fog;

            // Dither a bit. Since we can have two fog colors there can be banding
           fog         += triDither(fog, coord, Timer.x, 8);

           if(enableFog)
           color        = lerp(BlendScreenHDR(color, fogColor), color, exp(-weatherLerp(fogData, fogDensity, currWeather, prevWeather) * fog));

    // Sunglow Shader
    float2 sunPos       = getSun();
    float3 sunOpacity   = TextureColor.Sample(LinearSampler, sunPos);
    float  sunVis       = getSunvisibility();
    float  sunLuma      = max3(sunOpacity);
           sunOpacity   = max(0, sunLuma - glowThreshold);
           sunOpacity  /= max(sunLuma, 0.0001);
    float3 glow         = getGlow(float2(coord.x, coord.y * ScreenSize.w), float2(sunPos.x, sunPos.y * ScreenSize.w));
           glow         = pow(glow, glowCurve);
           glow        += triDither(glow, coord, Timer.x, 8); //clean up a bit

           if(enableSunGlow && !EInteriorFactor && SunDirection.z > 0.0)
           {
                color *= lerp(1, (1 - sunDarkening), sunVis * (sunVis * sunDarkening) - glow);
                color  = BlendScreenHDR(color, (glow * sunOpacity * glowStrength * glowTint));
           }

    return color;
}

float3	PS_DrawFog(VS_OUTPUT IN, uniform int layerNum) : SV_Target
{
    if(!enableFog) return 0;

    // Setup
    float2 coord    = IN.txcoord.xy;
    float3 color    = TextureColor.Sample(LinearSampler, coord); // In this case prev fog
    float  nearPlane, farPlane;
    float3 fogColor;

    // Find weathers
    int currWeather = findCurrentWeather();
    int prevWeather = findPrevWeather();

    if(layerNum == 1)
    {
        nearPlane   = weatherLerp(fogData, nearFogLayer1,  currWeather, prevWeather);
        farPlane    = weatherLerp(fogData, farFogLayer1,   currWeather, prevWeather);
        fogColor    = weatherLerp(fogData, colorFogLayer1, currWeather, prevWeather);
    }
    else
    {
        nearPlane   = weatherLerp(fogData, nearFogLayer2,  currWeather, prevWeather);
        farPlane    = weatherLerp(fogData, farFogLayer2,   currWeather, prevWeather);
        fogColor    = weatherLerp(fogData, colorFogLayer2, currWeather, prevWeather);
    }

    // Calc Fog. Remove prev plane for spereration
    float  fogPlane = (1 - saturate((getLinearizedDepth(coord) - nearPlane) / (farPlane - nearPlane))) - color;

    // Add to prev Fog
    return color + (fogColor * fogPlane);
}

//===========================================================//
// Techniques                                                //
//===========================================================//
technique11 pre <string UIName="Mundus Prepass";>
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_ClearBuffer()));
    }
}

technique11 pre1
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_DrawFog(1)));
    }
}

technique11 pre2 <string RenderTarget="RenderTargetRGBA64";>
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_DrawFog(2)));
    }
}

technique11 pre3
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_Sharpening()));
    }
}

technique11 pre4
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_Color()));
    }
}