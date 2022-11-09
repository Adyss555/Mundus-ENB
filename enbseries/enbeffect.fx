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

//===========================================================//
// Textures                                                  //
//===========================================================//

// Main Buffers
Texture2D TextureColor;         // HDR color
Texture2D TextureOriginal;      // color R16B16G16A16 64 bit hdr format
Texture2D TextureBloom;         // ENB bloom
Texture2D TextureLens;          // ENB lens fx
Texture2D TextureAdaptation;    // ENB adaptation
Texture2D TextureDepth;         // Scene depth
Texture2D TextureAperture;      // This frame aperture 1*1 R32F hdr red channel only . computed in depth of field shader file
Texture2D TexturePalette;       // enbpalette texture, if loaded and enabled in [colorcorrection].

//temporary textures which can be set as render target for techniques via annotations like <string RenderTarget="RenderTargetRGBA32";>
Texture2D RenderTargetRGBA32;   //R8G8B8A8 32 bit ldr format
Texture2D RenderTargetRGBA64;   //R16B16G16A16 64 bit ldr format
Texture2D RenderTargetRGBA64F;  //R16B16G16A16F 64 bit hdr format
Texture2D RenderTargetR16F;     //R16F 16 bit hdr format with red channel only
Texture2D RenderTargetR32F;     //R32F 32 bit hdr format with red channel only
Texture2D RenderTargetRGB32F;   //32 bit hdr format without alpha

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
UI_MESSAGE(1,                      " \x95 Mundus ENB \x95 ")
UI_WHITESPACE(1)
UI_MESSAGE(2,                       "|----- Color -----")
UI_FLOAT_DNI(exposure,              "| Exposure",              -10.0, 10.0, 0.0)
UI_FLOAT_DNI(gamma,                 "| Gamma",                  0.1, 3.0, 1.0)
UI_FLOAT_DNI(contrast,              "| Contrast",               0.0, 1.0, 0.5)
UI_FLOAT_FINE_DNI(colorTempK,       "| Color Temperature",      1000.0, 30000.0, 7000.0, 50.0)
UI_FLOAT_DNI(saturation,            "| Saturation",             0.1, 5.0, 1.0)
UI_FLOAT_DNI(maxWhite,              "| Max White",              0.0, 12.0, 1.0)
UI_FLOAT_DNI(blackPoint,            "| Black Point",           -1.0, 1.0, 0.0)
UI_FLOAT_DNI(whitePoint,            "| White Point",            0.0, 100.0, 1.0)
UI_WHITESPACE(2)
UI_MESSAGE(3,                       "|----- Imagespace -----")
UI_FLOAT(isSatImpact,               "| Saturation Impact",      0.0, 3.0, 1.0)
UI_FLOAT(isMinSat,                  "| Min Saturation",         0.0, 3.0, 0.0)
UI_FLOAT(isMaxSat,                  "| Max Saturation",         0.0, 3.0, 1.0)
UI_FLOAT(isConImpact,               "| Contrast Impact",        0.0, 3.0, 1.0)
UI_FLOAT(isMinCon,                  "| Min Contrast",           0.0, 3.0, 0.0)
UI_FLOAT(isMaxCon,                  "| Max Contrast",           0.0, 3.0, 1.0)
UI_FLOAT(isBriImpact,               "| Brightness Impact",      0.0, 3.0, 1.0)
UI_FLOAT(isMinBri,                  "| Min Brightness",         0.0, 3.0, 0.0)
UI_FLOAT(isMaxBri,                  "| Max Brightness",         0.0, 3.0, 1.0)
UI_WHITESPACE(3)
UI_MESSAGE(4,                       "|----- Bloom -----")
UI_FLOAT_DNI(bloomIntensity,        "| Bloom Intensity",        0.0, 3.0, 0.5)
UI_FLOAT_DNI(softBloomIntensity,    "| Soft Bloom Intensity",   0.0, 3.0, 1.0)
UI_FLOAT_DNI(softBloomMix,          "| Soft Bloom Mixing",      0.0, 1.0, 0.1)
#ifdef DEBUG_MODE
UI_WHITESPACE(4)
UI_MESSAGE(5,                       "|----- Debug -----")
UI_BOOL(showBloom,                  "| Show Bloom",             false)
UI_BOOL(showLens,                   "| Show Lens",              false)
UI_BOOL(enableCurve,                "| Enable Curve",           false)
#endif


//===========================================================//
// Functions                                                 //
//===========================================================//


// Arri Log C4
float3 LogC4(float3 HDRLinear)
{
    // Apply the LOG curve (optimized)
    return  (HDRLinear <  -0.0180570)
          ? (HDRLinear - (-0.0180570)) / 0.113597
          : (log2(2231.826309067688 * HDRLinear + 64.0) - 6.0) / 14.0 * 0.9071358748778104 + 0.0928641251221896;
}

// S Curve by Sevence
float3 S_Curve(float3 x, float isContrast)
{
    float  a = saturate(1.0 - (contrast * isContrast * 0.75));  //  0.0 - 1.0
    float  w = maxWhite;     //  1.0 - 11.2
    float  l = blackPoint;   // -1.0 - 1.0
    float  h = whitePoint;   //  1.0 - 100.0
        
    float3 A = 0.5 * ((2 * x - 1) / (a + (1 - a) * abs(2 * x - 1))) + 0.5;
    float3 B = 0.5 * ((2 * w - 1) / (a + (1 - a) * abs(2 * w - 1))) + 0.5;
        
    return max(l + (h - l) * (A / B), 0.001);
}

float3 colorTemperatureToRGB(float temperatureInKelvins)
{
	float3 retColor;

    temperatureInKelvins = clamp(temperatureInKelvins, 1000.0, 40000.0) / 100.0;

    if (temperatureInKelvins <= 66.0)
    {
        retColor.r = 1.0;
        retColor.g = saturate(0.39008157876901960784 * log(temperatureInKelvins) - 0.63184144378862745098);
    }
    else
    {
    	float t = temperatureInKelvins - 60.0;
        retColor.r = saturate(1.29293618606274509804 * pow(t, -0.1332047592));
        retColor.g = saturate(1.12989086089529411765 * pow(t, -0.0755148492));
    }

    if (temperatureInKelvins >= 66.0)
        retColor.b = 1.0;
    else if(temperatureInKelvins <= 19.0)
        retColor.b = 0.0;
    else
        retColor.b = saturate(0.54320678911019607843 * log(temperatureInKelvins - 10.0) - 1.19625408914);

    return retColor;
}

// Apply wb lumapreserving
float3 whiteBalance(float3 color, float luma) 
{
    color /= luma;
    color *= colorTemperatureToRGB(colorTempK);
    return color * luma;
}

//===========================================================//
// Pixel Shaders                                             //
//===========================================================//
float3	PS_Color(VS_OUTPUT IN) : SV_Target
{
    float2  coord   = IN.txcoord.xy;
    float3  color   = TextureColor.Sample(PointSampler,  coord);
    float3  bloom   = TextureBloom.SampleLevel(LinearSampler, coord, 0);
    float3  lens    = TextureLens.Sample(LinearSampler, coord);

            // Mix Bloom

    float3  sBloom  = lens * ENBParams01.x * softBloomIntensity;
    float3  mBloom  = (bloom * ENBParams01.x * bloomIntensity) + (lens * softBloomMix);
            color   = lerp(color, sBloom, softBloomMix);
            color   = BlendScreenHDR(color, mBloom);

            //Debug
    #ifdef DEBUG_MODE
            if(showBloom)
            return bloom;

            if(showLens)
            return lens;
     #endif

    // Get imagespace
    float   isSat   = clamp(Params01[3].x * isSatImpact, isMinSat, isMaxSat);   // 0 == gray scale
    float   isCon   = clamp(Params01[3].z * isConImpact, isMinCon, isMaxCon);   // 0 == no contrast
    float   isBri   = clamp(Params01[3].w * isBriImpact, isMinBri, isMaxBri);   // intensity

            color  *= exp(exposure + isBri);        // Exposure    
            color   = LogC4(color);                 // Tonemap
            color   = pow(color, gamma + isCon);    // Gamma^1
            color   = rgb2ictcp(color);
            color.yz *= (saturation + isSat) * 0.5;
            color   = ictcp2rgb(color);
            color   = whiteBalance(color, GetLuma(color, Rec709));
            color   = S_Curve(color, isCon);
            color   = lerp(color, Params01[5].xyz, Params01[5].w); // Fade effects

    return saturate(color + triDither(color, coord, Timer.x, 8));
}

//===========================================================//
// Techniques                                                //
//===========================================================//
technique11 Draw <string UIName="Mundus";>
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_Color()));
    }
}