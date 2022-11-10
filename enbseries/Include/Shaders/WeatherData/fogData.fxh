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
// Per Weather Fog settings

// Struct of all posible Fog settings 
struct fogSettings
{
    float  nearFogLayer1, farFogLayer1, nearFogLayer2, farFogLayer2, fogDensity;
    float3 colorFogLayer1, colorFogLayer2;
};

// Default hardcoded settings 
fogSettings defaultFog()
{
    fogSettings fog;

    // near Fog
    fog.nearFogLayer1   = 0.2;
    fog.farFogLayer1    = 0.0;
    fog.colorFogLayer1  = float3(0.1, 0.1, 0.1);

    // far Fog
    fog.nearFogLayer2   = 1.0;
    fog.farFogLayer2    = 0.3;
    fog.colorFogLayer2  = float3(0.1, 0.1, 0.1);

    // Overall density
    fog.fogDensity      = 1.0;

    return fog;
}

// Map the UI variables to weathers
fogSettings clearFog()
{
    fogSettings fog;

    // near Fog
    fog.nearFogLayer1   = w1l1nearFog;
    fog.farFogLayer1    = w1l1farFog;
    fog.colorFogLayer1  = w1l1fogCol;

    // far Fog
    fog.nearFogLayer2   = w1l2nearFog;
    fog.farFogLayer2    = w1l2farFog;
    fog.colorFogLayer2  = w1l2fogCol;

    // Overall density
    fog.fogDensity      = w1fogDensity;

    return fog;
}

fogSettings cloudyFog()
{
    fogSettings fog;

    // near Fog
    fog.nearFogLayer1   = w2l1nearFog;
    fog.farFogLayer1    = w2l1farFog;
    fog.colorFogLayer1  = w2l1fogCol;

    // far Fog
    fog.nearFogLayer2   = w2l2nearFog;
    fog.farFogLayer2    = w2l2farFog;
    fog.colorFogLayer2  = w2l2fogCol;

    // Overall density
    fog.fogDensity      = w2fogDensity;

    return fog;
}

fogSettings overcastFog()
{
    fogSettings fog;

    // near Fog
    fog.nearFogLayer1   = w3l1nearFog;
    fog.farFogLayer1    = w3l1farFog;
    fog.colorFogLayer1  = w3l1fogCol;

    // far Fog
    fog.nearFogLayer2   = w3l2nearFog;
    fog.farFogLayer2    = w3l2farFog;
    fog.colorFogLayer2  = w3l2fogCol;

    // Overall density
    fog.fogDensity      = w3fogDensity;

    return fog;
}

fogSettings rainFog()
{
    fogSettings fog;

    // near Fog
    fog.nearFogLayer1   = w4l1nearFog;
    fog.farFogLayer1    = w4l1farFog;
    fog.colorFogLayer1  = w4l1fogCol;

    // far Fog
    fog.nearFogLayer2   = w4l2nearFog;
    fog.farFogLayer2    = w4l2farFog;
    fog.colorFogLayer2  = w4l2fogCol;

    // Overall density
    fog.fogDensity      = w4fogDensity;

    return fog;
}

fogSettings snowFog()
{
    fogSettings fog;

    // near Fog
    fog.nearFogLayer1   = w5l1nearFog;
    fog.farFogLayer1    = w5l1farFog;
    fog.colorFogLayer1  = w5l1fogCol;

    // far Fog
    fog.nearFogLayer2   = w5l2nearFog;
    fog.farFogLayer2    = w5l2farFog;
    fog.colorFogLayer2  = w5l2fogCol;

    // Overall density
    fog.fogDensity      = w5fogDensity;

    return fog;
}

fogSettings fogFog() // oof that name
{
    fogSettings fog;

    // near Fog
    fog.nearFogLayer1   = w6l1nearFog;
    fog.farFogLayer1    = w6l1farFog;
    fog.colorFogLayer1  = w6l1fogCol;

    // far Fog
    fog.nearFogLayer2   = w6l2nearFog;
    fog.farFogLayer2    = w6l2farFog;
    fog.colorFogLayer2  = w6l2fogCol;

    // Overall density
    fog.fogDensity      = w6fogDensity;

    return fog;
}

fogSettings ashFog()
{
    fogSettings fog;

    // near Fog
    fog.nearFogLayer1   = w7l1nearFog;
    fog.farFogLayer1    = w7l1farFog;
    fog.colorFogLayer1  = w7l1fogCol;

    // far Fog
    fog.nearFogLayer2   = w7l2nearFog;
    fog.farFogLayer2    = w7l2farFog;
    fog.colorFogLayer2  = w7l2fogCol;

    // Overall density
    fog.fogDensity      = w7fogDensity;

    return fog;
}

fogSettings blackreachFog()
{
    fogSettings fog;

    // near Fog
    fog.nearFogLayer1   = w8l1nearFog;
    fog.farFogLayer1    = w8l1farFog;
    fog.colorFogLayer1  = w8l1fogCol;

    // far Fog
    fog.nearFogLayer2   = w8l2nearFog;
    fog.farFogLayer2    = w8l2farFog;
    fog.colorFogLayer2  = w8l2fogCol;

    // Overall density
    fog.fogDensity      = w8fogDensity;

    return fog;
}

fogSettings interiorFog()
{
    fogSettings fog;

    // near Fog
    fog.nearFogLayer1   = w9l1nearFog;
    fog.farFogLayer1    = w9l1farFog;
    fog.colorFogLayer1  = w9l1fogCol;

    // far Fog
    fog.nearFogLayer2   = w9l2nearFog;
    fog.farFogLayer2    = w9l2farFog;
    fog.colorFogLayer2  = w9l2fogCol;

    // Overall density
    fog.fogDensity      = w9fogDensity;

    return fog;
}

// Array of datasets for fog
// Order of weathers: 
// Clear, Cloudy, Overcast, Rain, Snow, Fog, Ash, Blackreach
static const fogSettings fogData[NUM_WEATHERS + 2] = // +2 for 0 as default and 9 as Interior
{
    defaultFog(),  // Weather 0 (out of index)
    clearFog(),
    cloudyFog(),
    overcastFog(),
    rainFog(),
    snowFog(),
    fogFog(),
    ashFog(),
    blackreachFog(),
    interiorFog()
};