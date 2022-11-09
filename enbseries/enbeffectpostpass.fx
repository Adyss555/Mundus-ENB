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
Texture2D   TextureOriginal;     //color R10B10G10A2 32 bit ldr format
Texture2D   TextureColor;        //color which is output of previous technique (except when drawed to temporary render target), R10B10G10A2 32 bit ldr format
Texture2D   TextureDepth;        //scene depth R32F 32 bit hdr format

Texture2D   RenderTargetRGBA32;  //R8G8B8A8 32 bit ldr format
Texture2D   RenderTargetRGBA64;  //R16B16G16A16 64 bit ldr format
Texture2D   RenderTargetRGBA64F; //R16B16G16A16F 64 bit hdr format
Texture2D   RenderTargetR16F;    //R16F 16 bit hdr format with red channel only
Texture2D   RenderTargetR32F;    //R32F 32 bit hdr format with red channel only
Texture2D   RenderTargetRGB32F;  //32 bit hdr format without alpha

// Curves
Texture2D curveDay              <string ResourceName="Include/Textures/curveDay.png"; >;
Texture2D curveNight            <string ResourceName="Include/Textures/curveNight.png"; >;
Texture2D curveInterior         <string ResourceName="Include/Textures/curveInterior.png"; >;

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
UI_MESSAGE(2,                     	"|----- Camera Effects -----")
UI_BOOL(enableDistortion,           "| Enable Lens Distortion",   	false)
UI_INT(lensDistortion,              "|  Distortion Amount",       	-100, 100, 0)
UI_WHITESPACE(2)
UI_BOOL(enableVingette,             "| Enable Vingette",          	false)
UI_FLOAT(vingetteIntesity,          "|  Vingette Intesity",        	0.0, 1.0, 0.1)
UI_WHITESPACE(3)
UI_BOOL(enableGrain,                "| Enable Grain",             	false)
UI_INT(grainAmount,                 "|  Grain Amount",            	0, 100, 50)
UI_INT(grainRoughness,              "|  Grain Roughness",          	1, 3, 1)
UI_WHITESPACE(4)
UI_BOOL(enableCA,                   "| Enable Chromatic Aberration",false)
UI_FLOAT(RadialCA,                  "|  Aberration Strength",      	0.0, 2.5, 1.0)
UI_FLOAT(barrelPower,               "|  Aberration Curve",         	0.0, 2.5, 1.0)
UI_WHITESPACE(5)
UI_BOOL(enableLetterbox,            "| Enable Letterbox",	    	false)
UI_FLOAT(hBoxSize,                  "|  Horizontal Size",			-0.5, 0.5, 0.1)
UI_FLOAT(vBoxSize,                  "|  Vertical Size",          	-0.5, 0.5, 0.0)
UI_FLOAT(BoxRotation,               "|  Letterbox Rotation",	    0.0, 6.0, 0.0)
UI_FLOAT3(BoxColor,                 "|  Letterbox Color",         	0.0, 0.0, 0.0)
UI_FLOAT(LetterboxDepth,            "|  Letterbox Distance",      	0.0, 10.0, 0.0)
UI_WHITESPACE(6)
UI_BOOL(enableCAS,                  "| Enable Contrast Adaptive Sharpening", false)
UI_FLOAT(casContrast,               "|  Sharpening Contrast",      	0.0, 1.0, 0.0)
UI_FLOAT(casSharpening,             "|  Sharpening Amount",     	0.0, 1.0, 1.0)

//===========================================================//
// Functions                                                 //
//===========================================================//
#include "Include/Shaders/lensDistortion.fxh"
#include "Include/Shaders/letterbox.fxh"
#include "Include/Shaders/filmGrain.fxh"
#include "Include/Shaders/cas.fxh"
#include "Include/Shaders/Lut.fxh"

#include "Include/Shared/WeatherSeperation.fxh"

//===========================================================//
// Pixel Shaders                                             //
//===========================================================//

// Luckly i only need one of these
Texture2D lutInterior       <string ResourceName="Include/Textures/lutInterior.png"; >;

// default luts
Texture2D defLutDay         <string ResourceName="Include/Textures/defLutDay.png"; >;
Texture2D defLutNight       <string ResourceName="Include/Textures/defLutNight.png"; >;

// Clear
Texture2D w1LutDay          <string ResourceName="Include/Textures/clearLutDay.png"; >;
Texture2D w1LutNight        <string ResourceName="Include/Textures/clearLutNight.png"; >;

// Cloudy
Texture2D w2LutDay          <string ResourceName="Include/Textures/cloudyLutDay.png"; >;
Texture2D w2LutNight        <string ResourceName="Include/Textures/cloudyLutNight.png"; >;

// Overcast
Texture2D w3LutDay          <string ResourceName="Include/Textures/overcastLutDay.png"; >;
Texture2D w3LutNight        <string ResourceName="Include/Textures/overcastLutNight.png"; >;

// Rain
Texture2D w4LutDay          <string ResourceName="Include/Textures/rainLutDay.png"; >;
Texture2D w4LutNight        <string ResourceName="Include/Textures/rainLutNight.png"; >;

// Snow
Texture2D w5LutDay          <string ResourceName="Include/Textures/snowLutDay.png"; >;
Texture2D w5LutNight        <string ResourceName="Include/Textures/snowLutNight.png"; >;

// Fog
Texture2D w6LutDay          <string ResourceName="Include/Textures/fogLutDay.png"; >;
Texture2D w6LutNight        <string ResourceName="Include/Textures/fogLutNight.png"; >;

// Ash
Texture2D w7LutDay          <string ResourceName="Include/Textures/ashLutDay.png"; >;
Texture2D w7LutNight        <string ResourceName="Include/Textures/ashLutNight.png"; >;

// Blackreach
Texture2D w8LutDay          <string ResourceName="Include/Textures/blackreachLutDay.png"; >;
Texture2D w8LutNight        <string ResourceName="Include/Textures/blackreachLutNight.png"; >;

// Clear, Cloudy, Overcast, Rain, Snow, Fog, Ash, Blackreach
float3 applyLutByWeather(float3 color, int weatherIndex)
{
    // Setting it static should speed it up a little
    float2 lutSize = float2(1024.0, 32.0); 

    [branch] switch(weatherIndex)
    {
        case 0: // default lut for weathers out of index
        return lerp(Lut(color, defLutNight, lutSize), Lut(color, defLutDay, lutSize), ENightDayFactor);

        case 1: // Clear weather
        return lerp(Lut(color, w1LutNight, lutSize), Lut(color, w1LutDay, lutSize), ENightDayFactor);

        case 2: // Cloudy weather
        return lerp(Lut(color, w2LutNight, lutSize), Lut(color, w2LutDay, lutSize), ENightDayFactor);

        case 3: // Overcast weather
        return lerp(Lut(color, w3LutNight, lutSize), Lut(color, w3LutDay, lutSize), ENightDayFactor);

        case 4: // Rain weather
        return lerp(Lut(color, w4LutNight, lutSize), Lut(color, w4LutDay, lutSize), ENightDayFactor);

        case 5: // Snow weather
        return lerp(Lut(color, w5LutNight, lutSize), Lut(color, w5LutDay, lutSize), ENightDayFactor);

        case 6: // Fog weather
        return lerp(Lut(color, w6LutNight, lutSize), Lut(color, w6LutDay, lutSize), ENightDayFactor);

        case 7: // Ash weather
        return lerp(Lut(color, w7LutNight, lutSize), Lut(color, w7LutDay, lutSize), ENightDayFactor);

        case 8: // Blackreach weather
        return lerp(Lut(color, w8LutNight, lutSize), Lut(color, w8LutDay, lutSize), ENightDayFactor);

        case 9: // Interiors
        return Lut(color, lutInterior, lutSize);
    }
}

float3 PS_WeatherLut(VS_OUTPUT IN) : SV_Target
{
    float3 color	= TextureColor.Sample(PointSampler, IN.txcoord.xy);

    // Find weathers
    int currWeather = findCurrentWeather();
    int nextWeather = findNextWeather();

    if(currWeather == nextWeather)
    {
        color = applyLutByWeather(color, currWeather);
    }
    else
    {
        color = lerp(applyLutByWeather(color, nextWeather), applyLutByWeather(color, currWeather), Weather.z);
    }

    return color;
}

float4 PS_PostFX(VS_OUTPUT IN, float4 v0 : SV_Position0) : SV_Target
{
    float2 coord	= IN.txcoord.xy;
    float4 Color	= TextureColor.Sample(PointSampler, coord);

    // Grain
    if(enableGrain)
    Color.rgb = GrainPass(coord, Color);

    // Vingette
    if(enableVingette)
    Color   *= pow(16.0 * coord.x * coord.y * (1.0 - coord.x) * (1.0 - coord.y), vingetteIntesity); // fast and simpel

    //Letterboxes
    if(enableLetterbox)
    Color.rgb = applyLetterbox(Color, getLinearizedDepth(coord), coord);

    return Color;
}

float3 PS_LensDistortion(VS_OUTPUT IN) : SV_Target
{
    return enableDistortion ? LensDist(IN.txcoord.xy) : TextureColor.Sample(PointSampler, IN.txcoord.xy);
}

float3 PS_LensCABlur(VS_OUTPUT IN) : SV_Target
{
    return enableCA ? SampleBlurredImage(TextureColor.Sample(LinearSampler, IN.txcoord.xy), IN.txcoord.xy) : TextureColor.Sample(PointSampler, IN.txcoord.xy);
}

float3 PS_LensCA(VS_OUTPUT IN) : SV_Target
{
    return enableCA ? LensCA(IN.txcoord.xy) : TextureColor.Sample(PointSampler, IN.txcoord.xy);
}

float3 PS_CAS(VS_OUTPUT IN) : SV_Target
{
	return enableCAS ? CASsharpening(IN.txcoord.xy) : TextureColor.Sample(PointSampler, IN.txcoord.xy);
}

//===========================================================//
// Techniques                                                //
//===========================================================//

technique11 post <string UIName="Mundus Postpass";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
		SetPixelShader (CompileShader(ps_5_0, PS_WeatherLut()));
	}
}

technique11 post1
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
		SetPixelShader (CompileShader(ps_5_0, PS_CAS()));
	}
}

technique11 post2
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
		SetPixelShader (CompileShader(ps_5_0, PS_LensDistortion()));
	}
}

technique11 post3
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
		SetPixelShader (CompileShader(ps_5_0, PS_LensCABlur()));
	}
}

technique11 post4
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
		SetPixelShader (CompileShader(ps_5_0, PS_LensCA()));
	}
}

technique11 post5
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
		SetPixelShader (CompileShader(ps_5_0, PS_PostFX()));
	}
}