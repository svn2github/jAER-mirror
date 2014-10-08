#
# Generated Makefile - do not edit!
#
# Edit the Makefile in the project folder instead (../Makefile). Each target
# has a -pre and a -post target defined where you can add customized code.
#
# This makefile implements configuration specific macros and targets.


# Include project Makefile
include Makefile

# Environment
SHELL=cmd.exe
# Adding MPLAB X bin directory to path
PATH:=C:/Program Files/Microchip/MPLABX/mplab_ide/mplab_ide/modules/../../bin/:$(PATH)
MKDIR=gnumkdir -p
RM=rm -f 
MV=mv 
CP=cp 

# Macros
CND_CONF=default
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
IMAGE_TYPE=debug
FINAL_IMAGE=dist/${CND_CONF}/${IMAGE_TYPE}/uart_MDC2D.X.${IMAGE_TYPE}.out
else
IMAGE_TYPE=production
FINAL_IMAGE=dist/${CND_CONF}/${IMAGE_TYPE}/uart_MDC2D.X.${IMAGE_TYPE}.out
endif

# Object Directory
OBJECTDIR=build/${CND_CONF}/${IMAGE_TYPE}

# Distribution Directory
DISTDIR=dist/${CND_CONF}/${IMAGE_TYPE}

# Object Files Quoted if spaced
OBJECTFILES_QUOTED_IF_SPACED=${OBJECTDIR}/_ext/1472/DAC.o ${OBJECTDIR}/_ext/1472/MDC2D.o ${OBJECTDIR}/_ext/1472/command.o ${OBJECTDIR}/_ext/1472/filter.o ${OBJECTDIR}/_ext/1472/main.o ${OBJECTDIR}/_ext/1472/message.o ${OBJECTDIR}/_ext/1472/port.o ${OBJECTDIR}/_ext/1472/srinivasan.o ${OBJECTDIR}/_ext/1472/string.o ${OBJECTDIR}/_ext/1472/time.o ${OBJECTDIR}/_ext/1472/uart.o ${OBJECTDIR}/_ext/1472/var.o

# Object Files
OBJECTFILES=${OBJECTDIR}/_ext/1472/DAC.o ${OBJECTDIR}/_ext/1472/MDC2D.o ${OBJECTDIR}/_ext/1472/command.o ${OBJECTDIR}/_ext/1472/filter.o ${OBJECTDIR}/_ext/1472/main.o ${OBJECTDIR}/_ext/1472/message.o ${OBJECTDIR}/_ext/1472/port.o ${OBJECTDIR}/_ext/1472/srinivasan.o ${OBJECTDIR}/_ext/1472/string.o ${OBJECTDIR}/_ext/1472/time.o ${OBJECTDIR}/_ext/1472/uart.o ${OBJECTDIR}/_ext/1472/var.o


CFLAGS=
ASFLAGS=
LDLIBSOPTIONS=

# Path to java used to run MPLAB X when this makefile was created
MP_JAVA_PATH="C:\Program Files\Java\jre6/bin/"
OS_CURRENT="$(shell uname -s)"
############# Tool locations ##########################################
# If you copy a project from one host to another, the path where the  #
# compiler is installed may be different.                             #
# If you open this project with MPLAB X in the new host, this         #
# makefile will be regenerated and the paths will be corrected.       #
#######################################################################
MP_CC="C:\Program Files\Microchip\mplabc30\v3.30c\bin\pic30-gcc.exe"
# MP_BC is not defined
MP_AS="C:\Program Files\Microchip\mplabc30\v3.30c\bin\pic30-as.exe"
MP_LD="C:\Program Files\Microchip\mplabc30\v3.30c\bin\pic30-ld.exe"
MP_AR="C:\Program Files\Microchip\mplabc30\v3.30c\bin\pic30-ar.exe"
DEP_GEN=${MP_JAVA_PATH}java -jar "C:/Program Files/Microchip/MPLABX/mplab_ide/mplab_ide/modules/../../bin/extractobjectdependencies.jar" 
# fixDeps replaces a bunch of sed/cat/printf statements that slow down the build
FIXDEPS=fixDeps
MP_CC_DIR="C:\Program Files\Microchip\mplabc30\v3.30c\bin"
# MP_BC_DIR is not defined
MP_AS_DIR="C:\Program Files\Microchip\mplabc30\v3.30c\bin"
MP_LD_DIR="C:\Program Files\Microchip\mplabc30\v3.30c\bin"
MP_AR_DIR="C:\Program Files\Microchip\mplabc30\v3.30c\bin"
# MP_BC_DIR is not defined

.build-conf:  ${BUILD_SUBPROJECTS}
	${MAKE}  -f nbproject/Makefile-default.mk dist/${CND_CONF}/${IMAGE_TYPE}/uart_MDC2D.X.${IMAGE_TYPE}.out

MP_PROCESSOR_OPTION=33FJ128MC804
MP_LINKER_FILE_OPTION=,-Tp33FJ128MC804.gld
# ------------------------------------------------------------------------------------
# Rules for buildStep: assemble
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${OBJECTDIR}/_ext/1472/srinivasan.o: ../srinivasan.s  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/srinivasan.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/srinivasan.o.ok ${OBJECTDIR}/_ext/1472/srinivasan.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/srinivasan.o.d" -t $(SILENT) -c ${MP_AS} $(MP_EXTRA_AS_PRE)  ../srinivasan.s -o ${OBJECTDIR}/_ext/1472/srinivasan.o -omf=elf -p=$(MP_PROCESSOR_OPTION) --defsym=__MPLAB_BUILD=1 --defsym=__MPLAB_DEBUG=1 --defsym=__ICD2RAM=1 --defsym=__DEBUG=1 --defsym=__MPLAB_DEBUGGER_PK3=1 -g  -MD "${OBJECTDIR}/_ext/1472/srinivasan.o.d" -I".."$(MP_EXTRA_AS_POST)
	
else
${OBJECTDIR}/_ext/1472/srinivasan.o: ../srinivasan.s  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/srinivasan.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/srinivasan.o.ok ${OBJECTDIR}/_ext/1472/srinivasan.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/srinivasan.o.d" -t $(SILENT) -c ${MP_AS} $(MP_EXTRA_AS_PRE)  ../srinivasan.s -o ${OBJECTDIR}/_ext/1472/srinivasan.o -omf=elf -p=$(MP_PROCESSOR_OPTION) --defsym=__MPLAB_BUILD=1 -g  -MD "${OBJECTDIR}/_ext/1472/srinivasan.o.d" -I".."$(MP_EXTRA_AS_POST)
	
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: assembleWithPreprocess
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
else
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: compile
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${OBJECTDIR}/_ext/1472/port.o: ../port.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/port.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/port.o.ok ${OBJECTDIR}/_ext/1472/port.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/port.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PK3=1 -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/port.o.d" -o ${OBJECTDIR}/_ext/1472/port.o ../port.c  
	
${OBJECTDIR}/_ext/1472/time.o: ../time.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/time.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/time.o.ok ${OBJECTDIR}/_ext/1472/time.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/time.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PK3=1 -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/time.o.d" -o ${OBJECTDIR}/_ext/1472/time.o ../time.c  
	
${OBJECTDIR}/_ext/1472/MDC2D.o: ../MDC2D.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/MDC2D.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/MDC2D.o.ok ${OBJECTDIR}/_ext/1472/MDC2D.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/MDC2D.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PK3=1 -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/MDC2D.o.d" -o ${OBJECTDIR}/_ext/1472/MDC2D.o ../MDC2D.c  
	
${OBJECTDIR}/_ext/1472/var.o: ../var.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/var.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/var.o.ok ${OBJECTDIR}/_ext/1472/var.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/var.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PK3=1 -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/var.o.d" -o ${OBJECTDIR}/_ext/1472/var.o ../var.c  
	
${OBJECTDIR}/_ext/1472/uart.o: ../uart.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/uart.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/uart.o.ok ${OBJECTDIR}/_ext/1472/uart.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/uart.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PK3=1 -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/uart.o.d" -o ${OBJECTDIR}/_ext/1472/uart.o ../uart.c  
	
${OBJECTDIR}/_ext/1472/main.o: ../main.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/main.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/main.o.ok ${OBJECTDIR}/_ext/1472/main.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/main.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PK3=1 -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/main.o.d" -o ${OBJECTDIR}/_ext/1472/main.o ../main.c  
	
${OBJECTDIR}/_ext/1472/command.o: ../command.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/command.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/command.o.ok ${OBJECTDIR}/_ext/1472/command.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/command.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PK3=1 -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/command.o.d" -o ${OBJECTDIR}/_ext/1472/command.o ../command.c  
	
${OBJECTDIR}/_ext/1472/filter.o: ../filter.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/filter.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/filter.o.ok ${OBJECTDIR}/_ext/1472/filter.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/filter.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PK3=1 -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/filter.o.d" -o ${OBJECTDIR}/_ext/1472/filter.o ../filter.c  
	
${OBJECTDIR}/_ext/1472/string.o: ../string.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/string.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/string.o.ok ${OBJECTDIR}/_ext/1472/string.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/string.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PK3=1 -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/string.o.d" -o ${OBJECTDIR}/_ext/1472/string.o ../string.c  
	
${OBJECTDIR}/_ext/1472/DAC.o: ../DAC.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/DAC.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/DAC.o.ok ${OBJECTDIR}/_ext/1472/DAC.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/DAC.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PK3=1 -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/DAC.o.d" -o ${OBJECTDIR}/_ext/1472/DAC.o ../DAC.c  
	
${OBJECTDIR}/_ext/1472/message.o: ../message.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/message.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/message.o.ok ${OBJECTDIR}/_ext/1472/message.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/message.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE) -g -D__DEBUG -D__MPLAB_DEBUGGER_PK3=1 -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/message.o.d" -o ${OBJECTDIR}/_ext/1472/message.o ../message.c  
	
else
${OBJECTDIR}/_ext/1472/port.o: ../port.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/port.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/port.o.ok ${OBJECTDIR}/_ext/1472/port.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/port.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE)  -g -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/port.o.d" -o ${OBJECTDIR}/_ext/1472/port.o ../port.c  
	
${OBJECTDIR}/_ext/1472/time.o: ../time.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/time.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/time.o.ok ${OBJECTDIR}/_ext/1472/time.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/time.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE)  -g -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/time.o.d" -o ${OBJECTDIR}/_ext/1472/time.o ../time.c  
	
${OBJECTDIR}/_ext/1472/MDC2D.o: ../MDC2D.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/MDC2D.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/MDC2D.o.ok ${OBJECTDIR}/_ext/1472/MDC2D.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/MDC2D.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE)  -g -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/MDC2D.o.d" -o ${OBJECTDIR}/_ext/1472/MDC2D.o ../MDC2D.c  
	
${OBJECTDIR}/_ext/1472/var.o: ../var.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/var.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/var.o.ok ${OBJECTDIR}/_ext/1472/var.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/var.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE)  -g -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/var.o.d" -o ${OBJECTDIR}/_ext/1472/var.o ../var.c  
	
${OBJECTDIR}/_ext/1472/uart.o: ../uart.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/uart.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/uart.o.ok ${OBJECTDIR}/_ext/1472/uart.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/uart.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE)  -g -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/uart.o.d" -o ${OBJECTDIR}/_ext/1472/uart.o ../uart.c  
	
${OBJECTDIR}/_ext/1472/main.o: ../main.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/main.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/main.o.ok ${OBJECTDIR}/_ext/1472/main.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/main.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE)  -g -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/main.o.d" -o ${OBJECTDIR}/_ext/1472/main.o ../main.c  
	
${OBJECTDIR}/_ext/1472/command.o: ../command.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/command.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/command.o.ok ${OBJECTDIR}/_ext/1472/command.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/command.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE)  -g -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/command.o.d" -o ${OBJECTDIR}/_ext/1472/command.o ../command.c  
	
${OBJECTDIR}/_ext/1472/filter.o: ../filter.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/filter.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/filter.o.ok ${OBJECTDIR}/_ext/1472/filter.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/filter.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE)  -g -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/filter.o.d" -o ${OBJECTDIR}/_ext/1472/filter.o ../filter.c  
	
${OBJECTDIR}/_ext/1472/string.o: ../string.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/string.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/string.o.ok ${OBJECTDIR}/_ext/1472/string.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/string.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE)  -g -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/string.o.d" -o ${OBJECTDIR}/_ext/1472/string.o ../string.c  
	
${OBJECTDIR}/_ext/1472/DAC.o: ../DAC.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/DAC.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/DAC.o.ok ${OBJECTDIR}/_ext/1472/DAC.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/DAC.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE)  -g -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/DAC.o.d" -o ${OBJECTDIR}/_ext/1472/DAC.o ../DAC.c  
	
${OBJECTDIR}/_ext/1472/message.o: ../message.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} ${OBJECTDIR}/_ext/1472 
	@${RM} ${OBJECTDIR}/_ext/1472/message.o.d 
	@${RM} ${OBJECTDIR}/_ext/1472/message.o.ok ${OBJECTDIR}/_ext/1472/message.o.err 
	@${FIXDEPS} "${OBJECTDIR}/_ext/1472/message.o.d" $(SILENT) -c ${MP_CC} $(MP_EXTRA_CC_PRE)  -g -omf=elf -x c -c -mcpu=$(MP_PROCESSOR_OPTION) -Wall -I".." -MMD -MF "${OBJECTDIR}/_ext/1472/message.o.d" -o ${OBJECTDIR}/_ext/1472/message.o ../message.c  
	
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: link
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
dist/${CND_CONF}/${IMAGE_TYPE}/uart_MDC2D.X.${IMAGE_TYPE}.out: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} dist/${CND_CONF}/${IMAGE_TYPE} 
	${MP_CC} $(MP_EXTRA_LD_PRE)  -omf=elf -mcpu=$(MP_PROCESSOR_OPTION)  -D__DEBUG -D__MPLAB_DEBUGGER_PK3=1 -o dist/${CND_CONF}/${IMAGE_TYPE}/uart_MDC2D.X.${IMAGE_TYPE}.out ${OBJECTFILES_QUOTED_IF_SPACED}        -Wl,--defsym=__MPLAB_BUILD=1,-L"..",-Map="${DISTDIR}/uart_MDC2D.X.${IMAGE_TYPE}.map",--report-mem$(MP_EXTRA_LD_POST)$(MP_LINKER_FILE_OPTION),--defsym=__MPLAB_DEBUG=1,--defsym=__ICD2RAM=1,--defsym=__DEBUG=1,--defsym=__MPLAB_DEBUGGER_PK3=1
else
dist/${CND_CONF}/${IMAGE_TYPE}/uart_MDC2D.X.${IMAGE_TYPE}.out: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} dist/${CND_CONF}/${IMAGE_TYPE} 
	${MP_CC} $(MP_EXTRA_LD_PRE)  -omf=elf -mcpu=$(MP_PROCESSOR_OPTION)  -o dist/${CND_CONF}/${IMAGE_TYPE}/uart_MDC2D.X.${IMAGE_TYPE}.out ${OBJECTFILES_QUOTED_IF_SPACED}        -Wl,--defsym=__MPLAB_BUILD=1,-L"..",-Map="${DISTDIR}/uart_MDC2D.X.${IMAGE_TYPE}.map",--report-mem$(MP_EXTRA_LD_POST)$(MP_LINKER_FILE_OPTION)
	${MP_CC_DIR}\\pic30-bin2hex dist/${CND_CONF}/${IMAGE_TYPE}/uart_MDC2D.X.${IMAGE_TYPE}.out -omf=elf
endif


# Subprojects
.build-subprojects:

# Clean Targets
.clean-conf:
	${RM} -r build/default
	${RM} -r dist/default

# Enable dependency checking
.dep.inc: .depcheck-impl

DEPFILES=$(wildcard $(addsuffix .d, ${OBJECTFILES}))
ifneq (${DEPFILES},)
include ${DEPFILES}
endif
