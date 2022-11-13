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



//===========================================================//
// Textures                                                  //
//===========================================================//
Texture2D			TextureOriginal; //color R10B10G10A2 32 bit ldr format
Texture2D			TextureColor;    //color which is output of previous technique (except when drawed to temporary render target), R10B10G10A2 32 bit ldr format
Texture2D			TextureDepth;    //scene depth R32F 32 bit hdr format
Texture2D			TextureMask;     //mask of underwater area of screen
// .x seems like a transiton when you go into water
// .y 0 as soon as the view touches water 1 if youre fully underwater. No transition
// .z same as .y?
// .w 1 if view underwater

Texture2D			RenderTargetRGBA32;  //R8G8B8A8 32 bit ldr format
Texture2D			RenderTargetRGBA64;  //R16B16G16A16 64 bit ldr format
Texture2D			RenderTargetRGBA64F; //R16B16G16A16F 64 bit hdr format
Texture2D			RenderTargetR16F;    //R16F 16 bit hdr format with red channel only
Texture2D			RenderTargetR32F;    //R32F 32 bit hdr format with red channel only
Texture2D			RenderTargetRGB32F;  //32 bit hdr format without alpha

//===========================================================//
// Internals                                                 //
//===========================================================//
#include "Include/Shared/Globals.fxh"
#include "Include/Shared/ReforgedUI.fxh"
#include "Include/Shared/Conversions.fxh"
#include "Include/Shared/BlendingModes.fxh"

float4	TintColor; //xyz - tint color; w - tint amount

//===========================================================//
// UI                                                        //
//===========================================================//



//===========================================================//
// Functions                                                 //
//===========================================================//


//===========================================================//
// Pixel Shaders                                             //
//===========================================================//
float3	PS_Color(VS_OUTPUT IN) : SV_Target
{
	float2 coord    = IN.txcoord.xy;


	float3 color    = TextureColor.Sample(PointSampler, coord);
	float4 mask     = TextureMask.Sample(PointSampler, coord);


	return 	mask.x;
}

//===========================================================//
// Techniques                                                //
//===========================================================//
