/* 
 * File:   PSEyeConstants.h
 * Author: mlk11
 *
 * Mapping used for PS Eye parameters
 * 
 * Created on 27 December 2011, 17:38
 */

#pragma once

#ifndef PSEYE_CONSTANTS_H
#define	PSEYE_CONSTANTS_H

// camera instance type
typedef void *PSEyeInstance;

// camera colour modes
enum PSEyeColourMode
{
    /* NOT IMPLEMENTED YET
    MONO_PROCESSED,
    COLOUR_PROCESSED,
    */ 
    MONO_RAW,
    COLOUR_RAW,
    BAYER_RAW
};

// camera resolutions
enum PSEyeResolution
{
    QVGA,
    VGA
};

// camera parameters
enum PSEyeParameter
{
    // camera sensor parameters
    AUTO_GAIN,			// [false, true]
    GAIN,			// [0, 79]
    AUTO_EXPOSURE,		// [false, true]
    EXPOSURE,                   // [0, 511]
    AUTO_WHITEBALANCE,          // [false, true]
    WHITEBALANCE_RED,		// [0, 255]
    WHITEBALANCE_GREEN,         // [0, 255]
    WHITEBALANCE_BLUE           // [0, 255]
    
    /* NOT IMPLEMENTED YET
    // camera linear transform parameters (valid for MONO_PROCESSED, COLOUR_PROCESSED modes)
    HFLIP,			// [false, true]
    VFLIP,			// [false, true]
    HKEYSTONE,			// [-500, 500]
    VKEYSTONE,			// [-500, 500]
    XOFFSET,			// [-500, 500]
    YOFFSET,			// [-500, 500]
    ROTATION,			// [-500, 500]
    ZOOM,			// [-500, 500]
                
    // camera non-linear transform parameters (valid for MONO_PROCESSED, COLOUR_PROCESSED modes)
    LENSCORRECTION1,		// [-500, 500]
    LENSCORRECTION2,		// [-500, 500]
    LENSCORRECTION3,		// [-500, 500]
    LENSBRIGHTNESS		// [-500, 500]
    */
};

struct PSEyeExtents {
    static const int MAX_GAIN = 79;
    static const int MIN_GAIN = 0;
    
    static const int MAX_EXPOSURE = 511; 
    static const int MIN_EXPOSURE = 0;
    
    static const int MAX_WHITEBALANCE_RED = 255;
    static const int MAX_WHITEBALANCE_GREEN = 255;
    static const int MAX_WHITEBALANCE_BLUE = 255;
    
    static const int MIN_WHITEBALANCE_RED = 0;
    static const int MIN_WHITEBALANCE_GREEN = 0;
    static const int MIN_WHITEBALANCE_BLUE = 0;            
};

#endif	/* PSEYE_CONSTANTS_H */

