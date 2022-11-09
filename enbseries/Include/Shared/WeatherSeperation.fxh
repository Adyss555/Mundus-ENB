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
// Weather Seperation file for NLA weathers                  //
// Setup by Adyss                                            //
//===========================================================//

// Set Number of indexed Weathers. Starts at 1
#define NUM_WEATHERS            8

// Clear
// Weather 1
#define CLEAR_WEATHERS_START    1
#define CLEAR_WEATHERS_END      8

// Cloudy
// Weather 2
#define CLOUDY_WEATHERS_START   9
#define CLOUDY_WEATHERS_END     10

// Overcast
// Weather 3
#define OVERCAST_WEATHERS_START 11
#define OVERCAST_WEATHERS_END   12

// Rain
// Weather 4
#define RAIN_WEATHERS_START     13
#define RAIN_WEATHERS_END       15

// Snow
// Weather 5
#define SNOW_WEATHERS_START     16
#define SNOW_WEATHERS_END       17

// Fog
// Weather 6
#define FOG_WEATHERS_START      18
#define FOG_WEATHERS_END        20

// Ash
// Weather 7
#define ASH_WEATHERS_START      21
#define ASH_WEATHERS_END        21

// Blackreach
// Weather 8
#define BREACH_WEATHERS_START   22
#define BREACH_WEATHERS_END     22

// Returns Number of current weather group
int findCurrentWeather()
{
    int weatherNum = 0;

    // Clear
    if(Weather.x >= CLEAR_WEATHERS_START && Weather.x <= CLEAR_WEATHERS_END)
        weatherNum = 1;

    // Cloudy
    if(Weather.x >= CLOUDY_WEATHERS_START && Weather.x <= CLOUDY_WEATHERS_END)
        weatherNum = 2;

    // Overcast
    if(Weather.x >= OVERCAST_WEATHERS_START && Weather.x <= OVERCAST_WEATHERS_END)
        weatherNum = 3;

    // Rain
    if(Weather.x >= RAIN_WEATHERS_START && Weather.x <= RAIN_WEATHERS_END)
        weatherNum = 4;

    // Snow
    if(Weather.x >= SNOW_WEATHERS_START && Weather.x <= SNOW_WEATHERS_END)
        weatherNum = 5;

    // Fog
    if(Weather.x >= FOG_WEATHERS_START && Weather.x <= FOG_WEATHERS_END)
        weatherNum = 6;

    // Ash
    if(Weather.x >= ASH_WEATHERS_START && Weather.x <= ASH_WEATHERS_END)
        weatherNum = 7;

    // Blackreach
    if(Weather.x >= BREACH_WEATHERS_START && Weather.x <= BREACH_WEATHERS_END)
        weatherNum = 8;

    // Interior
    if(EInteriorFactor)
        weatherNum = 9;

    return weatherNum;
}

// Returns Number of next weather group
int findNextWeather()
{
    int weatherNum = 0;

    // Clear
    if(Weather.y >= CLEAR_WEATHERS_START && Weather.y <= CLEAR_WEATHERS_END)
        weatherNum = 1;

    // Cloudy
    if(Weather.y >= CLOUDY_WEATHERS_START && Weather.y <= CLOUDY_WEATHERS_END)
        weatherNum = 2;

    // Overcast
    if(Weather.y >= OVERCAST_WEATHERS_START && Weather.y <= OVERCAST_WEATHERS_END)
        weatherNum = 3;

    // Rain
    if(Weather.y >= RAIN_WEATHERS_START && Weather.y <= RAIN_WEATHERS_END)
        weatherNum = 4;

    // Snow
    if(Weather.y >= SNOW_WEATHERS_START && Weather.y <= SNOW_WEATHERS_END)
        weatherNum = 5;

    // Fog
    if(Weather.y >= FOG_WEATHERS_START && Weather.y <= FOG_WEATHERS_END)
        weatherNum = 6;

    // Ash
    if(Weather.y >= ASH_WEATHERS_START && Weather.y <= ASH_WEATHERS_END)
        weatherNum = 7;

    // Blackreach
    if(Weather.y >= BREACH_WEATHERS_START && Weather.y <= BREACH_WEATHERS_END)
        weatherNum = 8;

    // Interior
    if(EInteriorFactor)
        weatherNum = 9;

    return weatherNum;
}

// ty Trey <3
#define weatherLerp(array, val, current, next) \
    lerp(array##[next].##val, \
         array##[current].##val, \
         Weather.z)

// Less performant but fine if you only need one value
#define weatherLerpAuto(array, val) \
    lerp(array##[findNextWeather()].##val, \
         array##[findCurrentWeather()].##val, \
         Weather.z)