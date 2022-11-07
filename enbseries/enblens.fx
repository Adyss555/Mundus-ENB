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

UI_FLOAT_DNI(bloomIntensity,    " Intensity",               0.1, 3.0, 1.0)
UI_FLOAT(removeSky,             " Mask out Sky",            0.0, 1.0, 0.2)

//===========================================================//
// Functions                                                 //
//===========================================================//
float2 getPixelSize(float texsize)
{
    return (1 / texsize) * float2(1, ScreenSize.z);
}

//===========================================================//
// Pixel Shaders                                             //
//===========================================================//
float3	PS_Prepass(VS_OUTPUT IN, uniform Texture2D InputTex) : SV_Target
{
    float3  color   = InputTex.Sample(LinearSampler, IN.txcoord.xy) * bloomIntensity;
            color   = lerp(color, color * (1 - floor(getLinearizedDepth(IN.txcoord.xy))), removeSky);
    return  clamp(color, 0.0, MAXBLOOM);
}

// https://www.froyok.fr/blog/2021-12-ue4-custom-bloom/
float3  PS_Downsample(VS_OUTPUT IN, uniform Texture2D InputTex, uniform float texsize) : SV_Target
{
    const float2 coords[13] = {
        float2( -1.0f,  1.0f ), float2(  1.0f,  1.0f ),
        float2( -1.0f, -1.0f ), float2(  1.0f, -1.0f ),

        float2(-2.0f, 2.0f), float2( 0.0f, 2.0f), float2( 2.0f, 2.0f),
        float2(-2.0f, 0.0f), float2( 0.0f, 0.0f), float2( 2.0f, 0.0f),
        float2(-2.0f,-2.0f), float2( 0.0f,-2.0f), float2( 2.0f,-2.0f)
    };

    const float weights[13] = {
        // 4 samples
        // (1 / 4) * 0.5f = 0.125f
        0.125f, 0.125f,
        0.125f, 0.125f,

        // 9 samples
        // (1 / 9) * 0.5f
        0.0555555f, 0.0555555f, 0.0555555f,
        0.0555555f, 0.0555555f, 0.0555555f,
        0.0555555f, 0.0555555f, 0.0555555f
    };

    float3 color = 0.0;

    [unroll]
    for( int i = 0; i < 13; i++ )
    {
        float2 currentUV = IN.txcoord.xy + coords[i] * getPixelSize(texsize);
        color += weights[i] * InputTex.Sample(LinearSampler, currentUV);
    }

    return clamp(color, 0.0, MAXBLOOM); 
}

float3  PS_Upsample(VS_OUTPUT IN, uniform Texture2D InputTex, uniform float texsize) : SV_Target
{
    const float2 coords[9] = {
        float2( -1.0f,  1.0f ), float2(  0.0f,  1.0f ), float2(  1.0f,  1.0f ),
        float2( -1.0f,  0.0f ), float2(  0.0f,  0.0f ), float2(  1.0f,  0.0f ),
        float2( -1.0f, -1.0f ), float2(  0.0f, -1.0f ), float2(  1.0f, -1.0f )
    };

    const float weights[9] = {
        0.0625f, 0.125f, 0.0625f,
        0.125f,  0.25f,  0.125f,
        0.0625f, 0.125f, 0.0625f
    };

    float3 color = 0.0;

    [unroll]
    for( int i = 0; i < 9; i++ )
    {
        float2 currentUV = IN.txcoord.xy + coords[i] * getPixelSize(texsize);
        color += weights[i] * InputTex.SampleLevel(LinearSampler, currentUV, 0);
    }

    return clamp(color, 0.0, MAXBLOOM);
}

//===========================================================//
// Techniques                                                //
//===========================================================//
technique11 Blum <string UIName="Soft Bloom"; string RenderTarget="RenderTarget1024";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Prepass(TextureDownsampled))); } }

technique11 Blum1 <string RenderTarget="RenderTarget512";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Downsample(RenderTarget1024, 1024.0))); } }

technique11 Blum2 <string RenderTarget="RenderTarget256";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Downsample(RenderTarget512, 512.0))); } }

technique11 Blum3 <string RenderTarget="RenderTarget128";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Downsample(RenderTarget256, 256.0))); } }

technique11 Blum4 <string RenderTarget="RenderTarget64";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Downsample(RenderTarget128, 128.0))); } }

technique11 Blum5 <string RenderTarget="RenderTarget32";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Downsample(RenderTarget64, 64.0))); } }

technique11 Blum6 <string RenderTarget="RenderTarget16";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Downsample(RenderTarget32, 32.0))); } }

// Up from here
technique11 Blum7 <string RenderTarget="RenderTarget32";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Upsample(RenderTarget16, 16.0))); } }

technique11 Blum8 <string RenderTarget="RenderTarget64";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Upsample(RenderTarget32, 32.0))); } }

technique11 Blum9 <string RenderTarget="RenderTarget128";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Upsample(RenderTarget64, 64.0))); } }

technique11 Blum10 <string RenderTarget="RenderTarget256";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Upsample(RenderTarget128, 128.0))); } }

technique11 Blum11 <string RenderTarget="RenderTarget512";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Upsample(RenderTarget256, 256.0))); } }

technique11 Blum12 <string RenderTarget="RenderTarget1024";>
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Upsample(RenderTarget512, 512.0))); } }

technique11 Blum13
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Upsample(RenderTarget1024, 1024.0))); } }

#ifdef DEBUG_MODE
technique11 debug <string UIName="Show Prepass"; >
{ pass p0 { SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
            SetPixelShader (CompileShader(ps_5_0, PS_Prepass(TextureDownsampled))); } }
#endif