/*
    Description : PD80 04 Color Isolation for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80


    MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

float smootherstep( float x )
{
    return x * x * x * ( x * ( x * 6.0f - 15.0f ) + 10.0f );
}

float3 colorIso(float3 color)
{
    color.xyz        = saturate( color.xyz ); //Can't work with HDR

    float grey       = GetLuma(color, Rec709);
    float hue        = RGBtoHSV( color.xyz ).x;

    float r          = rcp( hueRange );
    float3 w         = max( 1.0f - abs(( hue - hueMid        ) * r ), 0.0f );
    w.y              = max( 1.0f - abs(( hue + 1.0f - hueMid ) * r ), 0.0f );
    w.z              = max( 1.0f - abs(( hue - 1.0f - hueMid ) * r ), 0.0f );
    float weight     = dot( w.xyz, 1.0f );

    float3 newc      = lerp( grey, color.xyz, smootherstep( weight ) * satLimit );
    color.xyz        = lerp( color.xyz, newc.xyz, fxcolorMix );

    return color;
}
