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

//==================================================//
// Textures                                         //
//==================================================//
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

//==================================================//
// Internals                                        //
//==================================================//
#include "Include/Shared/Globals.fxh"
#include "Include/Shared/ReforgedUI.fxh"
#include "Include/Shared/Conversions.fxh"
#include "Include/Shared/BlendingModes.fxh"

//==================================================//
// UI                                               //
//==================================================//

UI_MESSAGE(1,                   "|----- Sun -----")
UI_BOOL(enableSunGlow,          "| Enable Glow",                false)
UI_FLOAT(glowStrength,          "|  Glow Strength",             0.1, 3.0, 1.0)
UI_FLOAT(glowThreshold,         "|  Glow Threshold",            0.0, 1.0, 0.1)
UI_FLOAT(glowCurve,             "|  Glow Curve",                0.1, 3.0, 1.0)
UI_FLOAT3(glowTint,             "|  Glow Tint",                 0.5, 0.5, 0.5)
UI_FLOAT(sunDarkening,          "|  Darken around Sun",         0.0, 1.0, 0.0)
UI_WHITESPACE(1)
UI_MESSAGE(2,                   "|----- Sharpening -----")
UI_BOOL(enableSharpening,       "| Enable Sharpening",          false)
UI_FLOAT(SharpenigOffset,       "|  Sharpening Offset",         0.2, 2.0, 1.0)
UI_FLOAT(SharpeningStrength,    "|  Sharpening Strength",      	0.2, 3.0, 1.0)
UI_FLOAT(SharpDistance,         "|  Sharpening Fadeout",        0.1, 15.0, 3.0)
UI_BOOL(ignoreSkin,             "|  Ignore Skin",               false)
UI_WHITESPACE(2)
UI_MESSAGE(3,                   "|----- Fog -----")
UI_BOOL(enableFog,              "| Enable Fog",                 false)
#ifdef DEBUG_MODE
UI_BOOL(showFogMask,            "| Show Fog Mask",             false)
#endif
UI_FLOAT(nearFogLayer1,         "|  near Fog Distance",         0.0, 10.0, 0.7)
UI_FLOAT(farFogLayer1,          "|  near Fog Closeup",          0.0, 10.0, 0.0)
UI_FLOAT3(colorFogLayer1,       "|  near Fog Color",            0.3, 0.3, 0.3)
UI_WHITESPACE(3)
UI_FLOAT(nearFogLayer2,         "|  far Fog Distance",          0.0, 10.0, 1.5)
UI_FLOAT(farFogLayer2,          "|  far Fog Closeup",           0.0, 10.0, 0.5)
UI_FLOAT3(colorFogLayer2,       "|  far Fog Color",             0.3, 0.3, 0.3)
UI_WHITESPACE(4)
UI_FLOAT(fogDensity,            "|  Fog Density",               0.0, 50.0, 0.0)

//==================================================//
// Functions                                		//
//==================================================//
#include "Include/Shaders/sharpening.fxh"

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

// Weather Setup
// Clear
#define CLEAR_WEATHERS_START    1
#define CLEAR_WEATHERS_END      8

// Cloudy
#define CLOUDY_WEATHERS_START   9
#define CLOUDY_WEATHERS_END     10

// Overcast
#define OVERCAST_WEATHERS_START 11
#define OVERCAST_WEATHERS_END   12

// Rain
#define RAIN_WEATHERS_START     13
#define RAIN_WEATHERS_END       15

// Snow
#define SNOW_WEATHERS_START     16
#define SNOW_WEATHERS_END       17

// Fog
#define FOG_WEATHERS_START      18
#define FOG_WEATHERS_END        20

// Ash
#define ASH_WEATHERS_START      21
#define ASH_WEATHERS_END        21

static const float IncomingTransitionStep = 0.7;
static const float OutgoingTransitionStep = 0.2;

float WeatherToEffectStrength_SC(float Outgoing, float Incoming, float WeatherTran, float Step)
{
	float2 Weather    = { Outgoing, Incoming };
	float2 Transition = { WeatherTran, 1.0 - WeatherTran };
	
	Transition = saturate(Transition - Step) * rcp(1.0 - Step);
	Transition = lerp(Weather.xy, Weather.yx, Transition);
	
	return (Incoming >= Outgoing) ? Transition.x : Transition.y;
}

float fogWeather()
{
    float  IncomingFog, OutgoingFog;
    float2(IncomingFog, OutgoingFog) = (Weather.xy >= FOG_WEATHERS_START && Weather.xy <= FOG_WEATHERS_END);

    float TransitionStep = (IncomingFog > OutgoingFog) ? IncomingTransitionStep : OutgoingTransitionStep;
    return WeatherToEffectStrength_SC(OutgoingFog, IncomingFog, Weather.z, TransitionStep);
}


//==================================================//
// Pixel Shaders                                    //
//==================================================//
float4	PS_ClearBuffer(VS_OUTPUT IN) : SV_Target
{
    return 0.0;
}

float3	PS_Color(VS_OUTPUT IN) : SV_Target
{
    float2 coord        = IN.txcoord.xy;
    float3 color        = TextureColor.Sample(PointSampler, coord);
    float3 fog          = RenderTargetRGBA64.Sample(LinearSampler, coord);


        #ifdef DEBUG_MODE
            if(showFogMask)
            return fog;
        #endif

        // Blend Fog
           fog         += triDither(fog, coord, Timer.x, 8);
           if(enableFog)
           color        = lerp(BlendScreenHDR(color, colorFogLayer1 * colorFogLayer2), color, exp(-fogDensity * fog * fogWeather()));

        // Sunglow
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

float3	PS_DrawFog(VS_OUTPUT IN, uniform float nearPlane, uniform float farPlane, uniform float3 fogColor) : SV_Target
{
    float2 coord    = IN.txcoord.xy;
    float3 color    = TextureColor.Sample(LinearSampler, coord);
    float  fogPlane = (1 - saturate((getLinearizedDepth(coord) - nearPlane) / (farPlane - nearPlane))) - color;
    return color + (fogColor * fogPlane);
}


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
        SetPixelShader (CompileShader(ps_5_0, PS_DrawFog(nearFogLayer1, farFogLayer1, colorFogLayer1)));
    }
}

technique11 pre2 <string RenderTarget="RenderTargetRGBA64";>
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_DrawFog(nearFogLayer2, farFogLayer2, colorFogLayer2)));
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