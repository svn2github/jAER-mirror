//-----------------------------------------------------------------------------
// F32x_USB_Descriptor.c
//-----------------------------------------------------------------------------
// Copyright 2005 Silicon Laboratories, Inc.
// http://www.silabs.com
//
// Program Description:
//
// Source file for USB firmware. Includes descriptor data.
//
//
// How To Test:    See Readme.txt
//
//
// FID:            32X000021
// Target:         C8051F32x
// Tool chain:     Keil C51 7.50 / Keil EVAL C51
//                 Silicon Laboratories IDE version 2.6
// Command Line:   See Readme.txt
// Project Name:   F32x_USB_Interrupt
//
//
// Release 1.3
//    -All changes by GP
//    -22 NOV 2005
//    -Changed revision number to match project revision
//     No content changes to this file
//    -Modified file to fit new formatting guidelines
//    -Changed file name from USB_DESCRIPTOR.c
//
// Release 1.0
//    -Initial Revision (DM)
//    -22 NOV 2002
//

//-----------------------------------------------------------------------------
// Includes
//-----------------------------------------------------------------------------

#include "F32x_USB_Register.h"
#include "F32x_USB_Main.h"
#include "F32x_USB_Descriptor.h"

//-----------------------------------------------------------------------------
// Descriptor Declarations
//-----------------------------------------------------------------------------

const device_descriptor DeviceDesc =
{
   18,                  // bLength
   0x01,                // bDescriptorType
   0x1001,              // bcdUSB
   0x00,                // bDeviceClass
   0x00,                // bDeviceSubClass
   0x00,                // bDeviceProtocol
   EP0_PACKET_SIZE,     // bMaxPacketSize0
   0x4705,              // idVendor 0x4705
   0x6087,              // idProduct 0x8750
   0x0000,              // bcdDevice
   0x01,                // iManufacturer
   0x02,                // iProduct
   0x00,                // iSerialNumber
   0x01                 // bNumConfigurations
}; //end of DeviceDesc

const configuration_descriptor ConfigDesc =
{
   0x09,                // Length
   0x02,                // Type
   0x2000,              // Totallength
   0x01,                // NumInterfaces
   0x01,                // bConfigurationValue
   0x00,                // iConfiguration
   0x80,                // bmAttributes
   0x7f                 // MaxPower; high power, powers servo motors directly
}; //end of ConfigDesc

const interface_descriptor InterfaceDesc =
{
   0x09,                // bLength
   0x04,                // bDescriptorType
   0x00,                // bInterfaceNumber
   0x00,                // bAlternateSetting
   0x02,                // bNumEndpoints
   0x00,                // bInterfaceClass
   0x00,                // bInterfaceSubClass
   0x00,                // bInterfaceProcotol
   0x00                 // iInterface
}; //end of InterfaceDesc

const endpoint_descriptor Endpoint1Desc =
{
   0x07,                // bLength
   0x05,                // bDescriptorType
   0x81,                // bEndpointAddress
//   0x03,                // bmAttributes
   0x02,                // bmAttributes (Bulk)

   EP1_PACKET_SIZE_LE,  // MaxPacketSize (LITTLE ENDIAN)
   0x05 // 10                   // bInterval //' Ignored for full-speed bulk endpoints.
}; //end of Endpoint1Desc

const endpoint_descriptor Endpoint2Desc =
{
   0x07,                // bLength
   0x05,                // bDescriptorType
   0x02,                // bEndpointAddress
//   0x03,                // bmAttributes
   0x02,                // bmAttributes (Bulk)
   EP2_PACKET_SIZE_LE,  // MaxPacketSize (LITTLE ENDIAN)
   0x05 //    10                   // bInterval //' Ignored for full-speed bulk endpoints.
}; //end of Endpoint2Desc

#define STR0LEN 4

code const BYTE String0Desc[STR0LEN] =
{
   STR0LEN, 0x03, 0x09, 0x04
}; //end of String0Desc

#define STR1LEN sizeof("INI/Delbruck")*2

code const BYTE String1Desc[STR1LEN] =
{
   STR1LEN, 0x03,
   'I', 0,
   'N', 0,
   'I', 0,
   '/', 0,
   'D', 0,
   'e', 0,
   'l', 0,
   'b', 0,
   'r', 0,
   'u', 0,
   'c', 0,
   'k', 0,
  }; //end of String1Desc

#define STR2LEN sizeof("C8051F320 Servo Controller")*2

code const BYTE String2Desc[STR2LEN] =
{
   STR2LEN, 0x03,
   'C', 0,
   '8', 0,
   '0', 0,
   '5', 0,
   '1', 0,
   'F', 0,
   '3', 0,
   '2', 0,
   '0', 0,
   ' ', 0,
   'S', 0,
   'e', 0,
   'r', 0,
   'v', 0,
   'o', 0,
   ' ', 0,
   'C', 0,
   'o', 0,
   'n', 0,
   't', 0,
   'r', 0,
   'o', 0,
   'l', 0,
   'l', 0,
   'e', 0,
   'r', 0,
}; //end of String2Desc

BYTE* const StringDescTable[] =
{
   String0Desc,
   String1Desc,
   String2Desc
};

//-----------------------------------------------------------------------------
// End Of File
//-----------------------------------------------------------------------------