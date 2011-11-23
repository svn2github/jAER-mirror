Area                   Addr        Size     Attributes      Input file
-------------------    --------    -----    -----------     ---------- 
        C$$init		00000000   0040     CODE          crtlpc2k.o


                    Addr      Global Symbol
	    	  ----------     --------------
		00000000        C$$init_start
		00000040        C$$init_end
		00000040        C$$init_length

Area                   Addr        Size     Attributes      Input file
-------------------    --------    -----    -----------     ---------- 
        C$$code		00000100   4230     CODE          crtlpc2k.o


                    Addr      Global Symbol
	    	  ----------     --------------
		000001c4        $a
		00000378        $a
		00000428        $a
		00000454        $a
		00000498        $a
		00000650        $a
		00000674        $a
		0000079c        $a
		0000093c        $a
		00000988        $a
		000009bc        $a
		00000a08        $a
		00000db0        $a
		00000dfc        $a
		00001174        $a
		00001238        $a
		000012d8        $a
		000013c4        $a
		00001460        $a
		00001620        $a
		000018ac        $a
		000019c4        $a
		000021d4        $a
		00002200        $a
		000022d8        $a
		00002310        $a
		00002ab4        $a
		00002ae8        $a
		00002b0c        $a
		00002ba4        $a
		00002cb4        $a
		00002dc4        $a
		00002e68        $a
		00002f0c        $a
		00003068        $a
		00003120        $a
		00003160        $va
		00003168        $va
		00003170        $va
		00003178        $va
		00003180        $va
		0000012c        _cstart
		000001c0        _exit
		00000100        $icc$ROM_ADDR
		00000104        $icc$RAM_ADDR
		00000108        $icc$DATA_SIZE
		00000114        $icc$VENROM_ADDR
		00000118        $icc$VENRAM_ADDR
		0000011c        $icc$VENDATA_SIZE
		0000010c        $icc$URAM_ADDR
		00000110        $icc$UDATA_SIZE
		000001c4        _defInterruptServiceRoutine
		000001c8        _initProcessor
		00000378        _delayUS
		000003ac        _delayMS
		000003e0        _LEDSetState
		00000428        _LEDInit
		00000454        _resetDevice
		00000498        _enterReprogrammingMode
		00000650        _main
		00000674        _mainloopInit
		0000079c        _DVS128ChipInit
		0000093c        _DVS128FetchEventsEnable
		00000988        _DVS128BiasSet
		000009bc        _DVS128BiasGet
		00000a08        _DVS128BiasLoadDefaultSet
		00000db0        _putchar
		00000dfc        _UART0SetBaudRate
		00001174        _UARTInit
		00001238        _UARTShowVersion
		000012d8        _UARTShowUsage
		000013c4        _UARTShowEventDataOptions
		00001460        _parseULong
		000014c0        _UARTParseGetCommand
		00001620        _UARTParseSetCommand
		000018ac        _parseRS232CommandLine
		000019c4        _UARTParseNewChar
		000021d4        __sdepi
		00002200        _sprintf
		00002310        __print
		00002ab4        _printf
		00002ae8        _isdigit
		00002b0c        _atoi
		00002ba4        _ltoa
		00002cb4        _itoa
		00002dc4        _ultoa
		00002e68        _utoa
		00002f0c        _toupper
		00002f3c        _strlen
		00002f58        __ctype
		00003068        _isspace
		000030a0        div32u
		0000308c        mod32u
		00003120        _islower
		00000100        C$$code_start
		00003188        C$$code_end
		00003088        C$$code_length
		00003160        arm_to_ramfunc_branch_veneer__mainloop
		00003168        arm_to_ramfunc_branch_veneer__DVS128BiasFlush
		00003170        arm_to_ramfunc_branch_veneer__DVS128BiasTransmitBiasValue
		00003178        arm_to_ramfunc_branch_veneer__DVS128BiasFlush
		00003180        arm_to_ramfunc_branch_veneer__DVS128BiasFlush

Area                   Addr        Size     Attributes      Input file
-------------------    --------    -----    -----------     ---------- 
         Cidata		40000000   0000     DATA          MainLoop.o


                    Addr      Global Symbol
	    	  ----------     --------------
		40000004        $a
		40000098        $a
		400000e8        $a
		400000e8        $a
		40000c64        $a
		400010e4        $a
		40000000        _TXBufferIndex
		40000004        _transmitSpecialData
		40000098        _swapByteOrderInMemory
		400000e8        _mainloop
		40000c64        _DVS128BiasFlush
		400010e4        _DVS128BiasTransmitBiasValue
		40000000        Cidata_start
		40001180        Cidata_end
		00001180        Cidata_length

Area                   Addr        Size     Attributes      Input file
-------------------    --------    -----    -----------     ---------- 
         Cudata		40001180   c220     NOINIT          EDVS128_2106.o


                    Addr      Global Symbol
	    	  ----------     --------------
		40001180        _ledState
		40001184        _hexLookupTable
		40001194        _eDVSDataFormat
		40001198        _dataForTransmission
		400011a8        _nextTimer1000msValue
		400011ac        _nextTimer100msValue
		400011b0        _nextTimer10msValue
		400011b4        _nextTimer2msValue
		400011b8        _nextTimer1msValue
		400011bc        _currentTimerValue
		400011c0        _eventCounterOff
		400011c4        _eventCounterOn
		400011c8        _eventCounterTotal
		400011cc        _TXBuffer
		400012cc        _transmitEventRateEnable
		400012d0        _eventBufferReadPointer
		400012d4        _eventBufferWritePointer
		400012d8        _eventBufferT
		400092d8        _eventBufferA
		4000d2d8        _p
		4000d2dc        _y
		4000d2e0        _x
		4000d2e4        _newEvent
		4000d2e8        _enableEventSending
		4000d2ec        _biasMatrix
		4000d31c        _commandLinePointer
		4000d320        _commandLine
		40001180        Cudata_start
		4000d3a0        Cudata_end
		0000c220        Cudata_length

Area                   Addr        Size     Attributes      Input file
-------------------    --------    -----    -----------     ---------- 
    .debug_info		00000000   0edd     CODE          EDVS128_2106.o


                    Addr      Global Symbol
	    	  ----------     --------------
		00000000        .debug_info_start
		00000edd        .debug_info_end
		00000edd        .debug_info_length

Area                   Addr        Size     Attributes      Input file
-------------------    --------    -----    -----------     ---------- 
  .debug_abbrev		00000000   0180     CODE          EDVS128_2106.o


                    Addr      Global Symbol
	    	  ----------     --------------
		00000000        .debug_abbrev_start
		00000180        .debug_abbrev_end
		00000180        .debug_abbrev_length

Area                   Addr        Size     Attributes      Input file
-------------------    --------    -----    -----------     ---------- 
    .debug_line		00000000   099e     CODE          EDVS128_2106.o


                    Addr      Global Symbol
	    	  ----------     --------------
		00000000        .debug_line_start
		0000099e        .debug_line_end
		0000099e        .debug_line_length

Area                   Addr        Size     Attributes      Input file
-------------------    --------    -----    -----------     ---------- 
      .shstrtab		00000000   006e    CODE          (null)


                    Addr      Global Symbol
	    	  ----------     --------------
		00000000        .shstrtab_start
		0000005f        .shstrtab_end
		0000005f        .shstrtab_length

Area                   Addr        Size     Attributes      Input file
-------------------    --------    -----    -----------     ---------- 
        .strtab		00000000   110a    CODE          (null)


                    Addr      Global Symbol
	    	  ----------     --------------
		00000000        .strtab_start
		00000d51        .strtab_end
		00000d51        .strtab_length

Area                   Addr        Size     Attributes      Input file
-------------------    --------    -----    -----------     ---------- 
        .symtab		00000000   1b00    CODE          (null)


                    Addr      Global Symbol
	    	  ----------     --------------
		00000000        .symtab_start
		00001840        .symtab_end
		00001840        .symtab_length

Area                   Addr        Size     Attributes      Input file
-------------------    --------    -----    -----------     ---------- 
 $VennerSection		4000d3a0   0000     DATA          (null)


                    Addr      Global Symbol
	    	  ----------     --------------
		4000d3a0        $va
		4000d3a8        $va
		4000d3b0        $va
		4000d3b8        $va
		4000d3c0        $va
		4000d3a0        ramfunc_to_arm_branch_veneer__UARTParseNewChar
		4000d3a8        ramfunc_to_arm_branch_veneer__LEDSetState
		4000d3b0        ramfunc_to_arm_branch_veneer__sprintf
		4000d3b8        ramfunc_to_arm_branch_veneer__sprintf
		4000d3c0        ramfunc_to_arm_branch_veneer__sprintf
		4000d3a0        $VennerSection_start
		4000d3c8        $VennerSection_end
		00000028        $VennerSection_length


[129 symbols]