/*============================================================================
FXAA3 QUALITY - PC
NVIDIA FXAA III.8 by TIMOTHY LOTTES
============================================================================*/
#define FXAA_LINEAR 1
#define FXAA_QUALITY__EDGE_THRESHOLD (0.0)
#define FXAA_QUALITY__EDGE_THRESHOLD_MIN (0.0)
#define FXAA_QUALITY__SUBPIX_CAP (0.75)
#define FXAA_QUALITY__SUBPIX_TRIM (0.125)
#define FXAA_QUALITY__SUBPIX_TRIM_SCALE  (1.0/(1.0 - fxaaSubpixTrim))
#define FXAA_SEARCH_STEPS     16
#define FXAA_SEARCH_THRESHOLD (1.0/4.0)

float4 FXAA(Texture2D Input, float2 pos)
{
    #define FxaaTexTop(t, p)       Input.SampleLevel(t, float2(p.x, p.y),                             0)
    #define FxaaTexOff(t, p, o, r) Input.SampleLevel(t, float2(p.x + (o.x * r.x), p.y + (o.y * r.y)), 0)

    float2 rcpFrame = 1 / float2(ScreenSize.x, ScreenSize.x * ScreenSize.w);

    float lumaN = sqrt(dot(FxaaTexOff(LinearSampler, pos, float2(0, -1), rcpFrame.xy).xyz, float3(0.299, 0.587, 0.114)));
    float lumaW = sqrt(dot(FxaaTexOff(LinearSampler, pos, float2(-1, 0), rcpFrame.xy).xyz, float3(0.299, 0.587, 0.114)));

    float4 rgbyM;
    rgbyM.xyz = FxaaTexTop(LinearSampler, pos).xyz;
    rgbyM.w = sqrt(dot(rgbyM.xyz, float3(0.299, 0.587, 0.114)));
    float lumaE = sqrt(dot(FxaaTexOff(LinearSampler, pos, float2( 1, 0), rcpFrame.xy).xyz, float3(0.299, 0.587, 0.114)));
    float lumaS = sqrt(dot(FxaaTexOff(LinearSampler, pos, float2( 0, 1), rcpFrame.xy).xyz, float3(0.299, 0.587, 0.114)));
    float lumaM = rgbyM.w;

    float rangeMin = min(lumaM, min(min(lumaN, lumaW), min(lumaS, lumaE)));
    float rangeMax = max(lumaM, max(max(lumaN, lumaW), max(lumaS, lumaE)));
    float range = rangeMax - rangeMin;

    if(range < max(fxaaEdgeThreshholdMin, rangeMax * fxaaEdgeThreshhold)) return rgbyM;

    float lumaNW = sqrt(dot(FxaaTexOff(LinearSampler, pos, float2(-1,-1), rcpFrame.xy).xyz, float3(0.299, 0.587, 0.114)));
    float lumaNE = sqrt(dot(FxaaTexOff(LinearSampler, pos, float2( 1,-1), rcpFrame.xy).xyz, float3(0.299, 0.587, 0.114)));
    float lumaSW = sqrt(dot(FxaaTexOff(LinearSampler, pos, float2(-1, 1), rcpFrame.xy).xyz, float3(0.299, 0.587, 0.114)));
    float lumaSE = sqrt(dot(FxaaTexOff(LinearSampler, pos, float2( 1, 1), rcpFrame.xy).xyz, float3(0.299, 0.587, 0.114)));

    float lumaL = (lumaN + lumaW + lumaE + lumaS) * 0.25;
    float rangeL = abs(lumaL - lumaM);
    float blendL = saturate((rangeL / range) - fxaaSubpixTrim) * FXAA_QUALITY__SUBPIX_TRIM_SCALE;
    blendL = min(fxaaSubpixCap, blendL);

    float edgeVert = abs(lumaNW + (-2.0 * lumaN) + lumaNE) + 2.0 * abs(lumaW  + (-2.0 * lumaM) + lumaE ) + abs(lumaSW + (-2.0 * lumaS) + lumaSE);
    float edgeHorz = abs(lumaNW + (-2.0 * lumaW) + lumaSW) + 2.0 * abs(lumaN  + (-2.0 * lumaM) + lumaS ) + abs(lumaNE + (-2.0 * lumaE) + lumaSE);
    bool horzSpan = edgeHorz >= edgeVert;

    float lengthSign = horzSpan ? -rcpFrame.y : -rcpFrame.x;
    if(!horzSpan) lumaN = lumaW;
    if(!horzSpan) lumaS = lumaE;
    float gradientN = abs(lumaN - lumaM);
    float gradientS = abs(lumaS - lumaM);
    lumaN = (lumaN + lumaM) * 0.5;
    lumaS = (lumaS + lumaM) * 0.5;

    bool pairN = gradientN >= gradientS;
    if(!pairN) lumaN = lumaS;
    if(!pairN) gradientN = gradientS;
    if(!pairN) lengthSign *= -1.0;
    float2 posN;
    posN.x = pos.x + (horzSpan ? 0.0 : lengthSign * 0.5);
    posN.y = pos.y + (horzSpan ? lengthSign * 0.5 : 0.0);

    gradientN *= FXAA_SEARCH_THRESHOLD;

    float2 posP = posN;
    float2 offNP = horzSpan ?
    float2(rcpFrame.x, 0.0) :
    float2(0.0f, rcpFrame.y);
    float lumaEndN;
    float lumaEndP;
    bool doneN = false;
    bool doneP = false;
    posN += offNP * (-1.5);
    posP += offNP * ( 1.5);
    for(int i = 0; i < FXAA_SEARCH_STEPS; i++)
    {
        lumaEndN = sqrt(dot(FxaaTexTop(LinearSampler, posN.xy).xyz, float3(0.299, 0.587, 0.114)));
        lumaEndP = sqrt(dot(FxaaTexTop(LinearSampler, posP.xy).xyz, float3(0.299, 0.587, 0.114)));
        bool doneN2 = abs(lumaEndN - lumaN) >= gradientN;
        bool doneP2 = abs(lumaEndP - lumaN) >= gradientN;
        if(doneN2 && !doneN) posN += offNP;
        if(doneP2 && !doneP) posP -= offNP;
        if(doneN2 && doneP2) break;
        doneN = doneN2;
        doneP = doneP2;
        if(!doneN) posN -= offNP * 2.0;
        if(!doneP) posP += offNP * 2.0;
    }

    float dstN = horzSpan ? pos.x - posN.x : pos.y - posN.y;
    float dstP = horzSpan ? posP.x - pos.x : posP.y - pos.y;

    bool directionN = dstN < dstP;
    lumaEndN = directionN ? lumaEndN : lumaEndP;

    if(((lumaM - lumaN) < 0.0) == ((lumaEndN - lumaN) < 0.0))
        lengthSign = 0.0;

    float spanLength = (dstP + dstN);
    dstN = directionN ? dstN : dstP;
    float subPixelOffset = 0.5 + (dstN * (-1.0/spanLength));
    subPixelOffset += blendL * (1.0/8.0);
    subPixelOffset *= lengthSign;
    float3 rgbF = FxaaTexTop(LinearSampler, float2(pos.x + (horzSpan ? 0.0 : subPixelOffset), pos.y + (horzSpan ? subPixelOffset : 0.0))).xyz;

    #if (FXAA_LINEAR == 1)
        lumaL *= lumaL;
    #endif
    float lumaF = dot(rgbF, float3(0.299, 0.587, 0.114)) + (1.0/(65536.0*256.0));
    float lumaB = lerp(lumaF, lumaL, blendL);
    float scale = min(4.0, lumaB/lumaF);
    rgbF *= scale;

    return float4(rgbF, lumaM);
}
