;;-----------------------------------------------------------------------------
;;   File:      dscr.a51
;;   Contents:  This file contains descriptor data tables.
;;
;; $Archive: /USB/Examples/Fx2lp/bulkloop/dscr.a51 $
;; $Date: 9/01/03 8:51p $
;; $Revision: 3 $
;;
;;
;;-----------------------------------------------------------------------------
;; Copyright 2003, Cypress Semiconductor Corporation
;;-----------------------------------------------------------------------------

DSCR_DEVICE   equ   1   ;; Descriptor type: Device
DSCR_CONFIG   equ   2   ;; Descriptor type: Configuration
DSCR_STRING   equ   3   ;; Descriptor type: String
DSCR_INTRFC   equ   4   ;; Descriptor type: Interface
DSCR_ENDPNT   equ   5   ;; Descriptor type: Endpoint
DSCR_DEVQUAL  equ   6   ;; Descriptor type: Device Qualifier

DSCR_DEVICE_LEN   equ   18
DSCR_CONFIG_LEN   equ    9
DSCR_INTRFC_LEN   equ    9
DSCR_ENDPNT_LEN   equ    7
DSCR_DEVQUAL_LEN  equ   10

ET_CONTROL   equ   0   ;; Endpoint type: Control
ET_ISO       equ   1   ;; Endpoint type: Isochronous
ET_BULK      equ   2   ;; Endpoint type: Bulk
ET_INT       equ   3   ;; Endpoint type: Interrupt

public      DeviceDscr, DeviceQualDscr, HighSpeedConfigDscr, FullSpeedConfigDscr, StringDscr, UserDscr

DSCR   SEGMENT   CODE PAGE

;;-----------------------------------------------------------------------------
;; Global Variables
;;-----------------------------------------------------------------------------
      rseg DSCR ;; locate the descriptor table in on-part memory.

DeviceDscr:   
      db   DSCR_DEVICE_LEN ;; Descriptor length
      db   DSCR_DEVICE     ;; Decriptor type
      dw   0002H      ;; Specification Version (BCD)
      db   00H        ;; Device class
      db   00H        ;; Device sub-class
      db   00H        ;; Device sub-sub-class
      db   64         ;; Maximum packet size
      dw   2a15H      ;; 0x152a VID from Thesycon
      dw   1b84H      ;; 0x841b PID from Thesycon jAER range
      dw   0000H      ;; Product version ID, FW ver 0, Device type 0
      db   1          ;; Manufacturer string index
      db   2          ;; Product string index
      db   3          ;; Serial number string index
      db   1          ;; Number of configurations

DeviceQualDscr:
      db   DSCR_DEVQUAL_LEN ;; Descriptor length
      db   DSCR_DEVQUAL     ;; Decriptor type
      dw   0002H      ;; Specification Version (BCD)
      db   00H        ;; Device class
      db   00H        ;; Device sub-class
      db   00H        ;; Device sub-sub-class
      db   64         ;; Maximum packet size
      db   1          ;; Number of configurations
      db   0          ;; Reserved

HighSpeedConfigDscr:   
      db   DSCR_CONFIG_LEN ;; Descriptor length
      db   DSCR_CONFIG     ;; Descriptor type
      db   (HighSpeedConfigDscrEnd-HighSpeedConfigDscr) mod 256 ;; Total Length (LSB)
      db   (HighSpeedConfigDscrEnd-HighSpeedConfigDscr)  /  256 ;; Total Length (MSB)
      db   1      ;; Number of interfaces
      db   1      ;; Configuration number
      db   0      ;; Configuration string
      db   10000000b ;; Attributes (b7 - buspwr, b6 - selfpwr, b5 - rwu)
      db   200    ;; Power requirement (in 2 mA units)

;; Interface Descriptor
      db   DSCR_INTRFC_LEN ;; Descriptor length
      db   DSCR_INTRFC     ;; Descriptor type
      db   0               ;; Zero-based index of this interface
      db   0               ;; Alternate setting
      db   1               ;; Number of end points 
      db   0FFH            ;; Interface class
      db   00H             ;; Interface sub class
      db   00H             ;; Interface sub sub class
      db   00H             ;; Interface descriptor string index

;; Endpoint Descriptor EP2 IN - data from device to host
      db   DSCR_ENDPNT_LEN ;; Descriptor length
      db   DSCR_ENDPNT     ;; Descriptor type
      db   82H             ;; Endpoint number, and direction 
      db   ET_BULK         ;; Endpoint type
      db   00H             ;; Maximum packet size (LSB)
      db   02H             ;; Maximum packet size (MSB), 512 bytes total
      db   00H             ;; Polling interval
HighSpeedConfigDscrEnd:   

FullSpeedConfigDscr:   
      db   DSCR_CONFIG_LEN ;; Descriptor length
      db   DSCR_CONFIG     ;; Descriptor type
      db   (FullSpeedConfigDscrEnd-FullSpeedConfigDscr) mod 256 ;; Total Length (LSB)
      db   (FullSpeedConfigDscrEnd-FullSpeedConfigDscr)  /  256 ;; Total Length (MSB)
      db   1      ;; Number of interfaces
      db   1      ;; Configuration number
      db   0      ;; Configuration string
      db   10000000b ;; Attributes (b7 - buspwr, b6 - selfpwr, b5 - rwu)
      db   200    ;; Power requirement (in 2 mA units)

;; Interface Descriptor
      db   DSCR_INTRFC_LEN ;; Descriptor length
      db   DSCR_INTRFC     ;; Descriptor type
      db   0               ;; Zero-based index of this interface
      db   0               ;; Alternate setting
      db   1               ;; Number of end points 
      db   0FFH            ;; Interface class
      db   00H             ;; Interface sub class
      db   00H             ;; Interface sub sub class
      db   00H             ;; Interface descriptor string index

;; Endpoint Descriptor EP2 IN - data from device to host
      db   DSCR_ENDPNT_LEN ;; Descriptor length
      db   DSCR_ENDPNT     ;; Descriptor type
      db   82H             ;; Endpoint number, and direction
      db   ET_BULK         ;; Endpoint type
      db   40H             ;; Maximum packet size (LSB)
      db   00H             ;; Maximum packet size (MSB), 64 bytes total
      db   00H             ;; Polling interval
FullSpeedConfigDscrEnd:   

StringDscr:

StringDscr0:   
      db   StringDscr0End-StringDscr0 ;; String descriptor length
      db   DSCR_STRING
      db   09H, 04H
StringDscr0End:

StringDscr1:   
      db   StringDscr1End-StringDscr1 ;; String descriptor length
      db   DSCR_STRING
      db   'I',00
      db   'N',00
      db   'I',00
StringDscr1End:

StringDscr2:   
      db   StringDscr2End-StringDscr2 ;; String descriptor length
      db   DSCR_STRING
      db   'D',00
      db   'A',00
      db   'V',00
      db   'i',00
      db   'S',00
      db   ' ',00
      db   'F',00
      db   'X',00
      db   '2',00
StringDscr2End:

StringDscr3:   
      db   StringDscr3End-StringDscr3 ;; String descriptor length
      db   DSCR_STRING
      db   '0',00
      db   '0',00
      db   '0',00
      db   '0',00
      db   '0',00
      db   '0',00
      db   '0',00
      db   '0',00
StringDscr3End:

MSOSDscr:   
      db   MSOSDscrEnd-MSOSDscr ;; MS OS descriptor length
      db   DSCR_STRING
      db   0x4D,00
      db   0x53,00
      db   0x46,00
      db   0x54,00
      db   0x31,00
      db   0x30,00
      db   0x30,00
      db   0xAF,00
MSOSDscrEnd:

UserDscr:      
      dw   0000H
      end
