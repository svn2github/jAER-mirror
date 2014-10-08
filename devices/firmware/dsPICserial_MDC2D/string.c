/*
 * Copyright June 13, 2011 Andreas Steiner, Inst. of Neuroinformatics, UNI-ETH Zurich
 * This file is part of uart_MDC2D.

 * uart_MDC2D is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * uart_MDC2D is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with uart_MDC2D.  If not, see <http://www.gnu.org/licenses/>.
 */
 
 
/*! \file string.c
 * some utility string handling functions
 */

#include "string.h"

#define STRCMPI_MASK ~(0x20)
//! compare strings 
//  \return zero if strings are equal
int strcmpi(const char *x,const char *y)
{
	while(*x && *y)
	{
		if (((*x)&STRCMPI_MASK) != ((*y)&STRCMPI_MASK))
			return 1;
		x++; y++;
	}
	if (*x || *y)
		return 1;
	return 0;
}

char hex_buf[8];

#define IH(A) (((A)<0xA)?((A)+'0'):((A)-0xA+'A'))
/*! convert 16bit value to hexadecimal ASCII code
 *  \param i 16bit word to convert
 *  \return pointer to a static buffer containing four ASCII
 *     symbols representing the value in hexadecimal code;
 *     \c null terminated
 */
char *itoh(int i)
{
	hex_buf[0]= IH((i>>12)&0xf);
	hex_buf[1]= IH((i>> 8)&0xf);
	hex_buf[2]= IH((i>> 4)&0xf);
	hex_buf[3]= IH( i     &0xf);
	hex_buf[4]= 0;
	return hex_buf;
}

/*! converts a hexadecimal ASCII code to its unsigned int value
 *  \param str pointer to \c null terminated buffer containing
 *     the ASCII hexadecimal representation (case insensitive)
 *  \return unsigned integer value
 */
int   htoi(const char *str)
{
	int j=0,i=0;
	while(str[j] != 0)
	{
		i<<=4;
		if (str[j]>='0' && str[j]<='9')
			i+= str[j]-'0';
		if (str[j]>='a' && str[j]<='f')
			i+= str[j]-'a' + 0x0a;
		if (str[j]>='A' && str[j]<='F')
			i+= str[j]-'A' + 0x0a;
		j++;
	}
	return i;
}

/*! returns the length of a string in characters
 *  \param str must be \c null terminated
 */
int strlen(const char *str)
{
	int i;
	for(i=0; str[i]!=0; i++);
	return i;
}


