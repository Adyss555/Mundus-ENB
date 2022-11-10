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
// Per Weather Lut Setup

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

// Luckly i only need one of these
Texture2D lutInterior       <string ResourceName="Include/Textures/lutInterior.png"; >;

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

