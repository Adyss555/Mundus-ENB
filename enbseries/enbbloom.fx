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
//                Mundus Bloom Suite by Adyss                //
//===========================================================//

// Load global config
#include "Include/mundusConfig.fxh"

//===========================================================//
// Textures                                                  //
//===========================================================//
Texture2D   TextureDepth;
Texture2D   TextureColor;
Texture2D   TextureDownsampled;  //color R16B16G16A16 64 bit or R11G11B10 32 bit hdr format. 1024*1024 size
Texture2D   RenderTarget1024;    //R16B16G16A16F 64 bit hdr format, 1024*1024 size
Texture2D   RenderTarget512;     //R16B16G16A16F 64 bit hdr format, 512*512 size
Texture2D   RenderTarget256;     //R16B16G16A16F 64 bit hdr format, 256*256 size
Texture2D   RenderTarget128;     //R16B16G16A16F 64 bit hdr format, 128*128 size
Texture2D   RenderTarget64;      //R16B16G16A16F 64 bit hdr format, 64*64 size
Texture2D   RenderTarget32;      //R16B16G16A16F 64 bit hdr format, 32*32 size
Texture2D   RenderTarget16;      //R16B16G16A16F 64 bit hdr format, 16*16 size

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

#define MAXBLOOM 16384.0

UI_BOOL(bloomQuality,           " High Quality",            false)
UI_FLOAT_DNI(bloomIntensity,    " Intensity",               0.1, 3.0, 1.0)
UI_FLOAT_DNI(bloomSensitivity,  " Sensitivity",             0.1, 3.0, 1.0)
UI_FLOAT_DNI(bloomSaturation,   " Saturation",              0.1, 2.5, 1.0)
UI_FLOAT_DNI(bloomShape,        " Size",                    0.0, 3.0, 1.0)
UI_FLOAT(removeSky,             " Mask out Sky",            0.0, 1.0, 0.2)

//===========================================================//
// Functions                                                 //
//===========================================================//
float2 getPixelSize(float texsize)
{
    return (1 / texsize) * float2(1, ScreenSize.z);
}

// Box Blur
float4 simpleBlur(Texture2D inputTex, float2 coord, float2 pixelsize)
{
    float4 Blur = 0.0;

    static const float2 Offsets[4]=
    {
        float2(0.5, 0.5),
        float2(0.5, -0.5),
        float2(-0.5, 0.5),
        float2(-0.5, -0.5)
    };

    for (int i = 0; i < 4; i++)
    {
        Blur += inputTex.Sample(LinearSampler, coord + Offsets[i] * pixelsize);
    }

    return Blur * 0.25;
}

//===========================================================//
// Pixel Shaders                                             //
//===========================================================//
float3	PS_Prepass(VS_OUTPUT IN, uniform Texture2D InputTex) : SV_Target
{
    float3  color   = InputTex.Sample(LinearSampler, IN.txcoord.xy) * bloomIntensity;
            color   = lerp(color, max3(color), bloomSensitivity * 0.2);
            color   = pow(color, bloomSensitivity);
            color   = lerp(GetLuma(color, Rec709), color, bloomSaturation);
            color   = lerp(color, color * (1 - floor(getLinearizedDepth(IN.txcoord.xy))), removeSky);
    return  clamp(color, 0.0, MAXBLOOM);
}

float3  PS_BlurH(VS_OUTPUT IN, uniform Texture2D InputTex, uniform float texsize) : SV_Target
{
    int     samples     = bloomQuality ? 11 : 9; // Weird numbers i know but they work best
    int     mid         = bloomQuality ? 3 : 2;
    int     upper       = (samples - 1) * 0.5;
    int     lower       = -upper;
    float2  pixelSize   = getPixelSize(texsize);
    float   kernelSum   = 0.0;
    float3  color;
    for (int x = lower; x <= upper; x++)
    {
        float weight = mid - sqrt(abs(x));
        kernelSum   += weight;
        color       += InputTex.SampleLevel(LinearSampler, IN.txcoord.xy + float2(pixelSize.x * x, 0.0), 0.0) * weight;
    }
    return color / kernelSum;
}

float3  PS_BlurV(VS_OUTPUT IN, uniform Texture2D InputTex, uniform float texsize) : SV_Target
{
    int     samples     = bloomQuality ? 11 : 9;
    int     mid         = bloomQuality ? 3 : 2;
    int     upper       = (samples - 1) * 0.5;
    int     lower       = -upper;
    int     max         = 0;
    float2  pixelSize   = getPixelSize(texsize);
    float   kernelSum   = 0.0;

    float3  color;
    for (int y = lower; y <= upper; y++)
    {
        float weight = mid - sqrt(abs(y));
        kernelSum   += weight;
        color       += InputTex.SampleLevel(LinearSampler, IN.txcoord.xy + float2(0.0, pixelSize.y * y), 0.0) * weight;
    }
    return color / kernelSum;
}

float3  PS_BloomMix(VS_OUTPUT IN) : SV_Target
{
    float2 coord     = IN.txcoord.xy;
    float  weightSum = 0.0;
    int    maxlevel  = 6;
    float  weight[7];

    [unroll]
    for (int i=0; i <= maxlevel; i++) 
    {
        weight[i]   = pow(i + 1, bloomShape);
        weightSum  += weight[i];
    }

    float3 bloom  = 0;
           bloom += simpleBlur(RenderTarget1024, coord, getPixelSize(1024)) * weight[0];
           bloom += simpleBlur(RenderTarget512,  coord, getPixelSize(512))  * weight[1];
           bloom += simpleBlur(RenderTarget256,  coord, getPixelSize(256))  * weight[2];
           bloom += simpleBlur(RenderTarget128,  coord, getPixelSize(128))  * weight[3];
           bloom += simpleBlur(RenderTarget64,   coord, getPixelSize(64))   * weight[4];
           bloom += simpleBlur(RenderTarget32,   coord, getPixelSize(32))   * weight[5];
           bloom += simpleBlur(RenderTarget16,   coord, getPixelSize(16))   * weight[6];
    return clamp(bloom * 0.143, 0.0, MAXBLOOM); // Normalize  1/7 = 0.1428571428571429
}

//===========================================================//
// Techniques                                                //
//===========================================================//
technique11 normal <string UIName="Natural Bloom"; string RenderTarget="RenderTarget1024";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Prepass(TextureDownsampled))); } }

technique11 normal1
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurH(RenderTarget1024, 1024.0))); } }

technique11 normal2 <string RenderTarget="RenderTarget1024";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurV(TextureColor, 1024.0))); } }

technique11 normal3
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurH(RenderTarget1024, 512.0))); } }

technique11 normal4 <string RenderTarget="RenderTarget512";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurV(TextureColor, 512.0))); } }

technique11 normal5
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurH(RenderTarget512, 256.0))); } }

technique11 normal6 <string RenderTarget="RenderTarget256";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurV(TextureColor, 256.0))); } }

technique11 normal7
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurH(RenderTarget256, 128.0))); } }

technique11 normal8 <string RenderTarget="RenderTarget128";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurV(TextureColor, 128.0))); } }

technique11 normal9
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurH(RenderTarget128, 64.0))); } }

technique11 normal10 <string RenderTarget="RenderTarget64";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurV(TextureColor, 64.0))); } }

technique11 normal11
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurH(RenderTarget64, 32.0))); } }

technique11 normal12 <string RenderTarget="RenderTarget32";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurV(TextureColor, 32.0))); } }

technique11 normal13
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurH(RenderTarget32, 16.0))); } }

technique11 normal14 <string RenderTarget="RenderTarget16";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BlurV(TextureColor, 16.0))); } }

technique11 normal15
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_BloomMix())); } }

#ifdef DEBUG_MODE
technique11 debug <string UIName="Show Prepass"; >
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Prepass(TextureDownsampled))); } }
#endif