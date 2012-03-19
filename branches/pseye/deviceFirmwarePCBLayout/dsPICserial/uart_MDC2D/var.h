#ifndef VAR_H
#define VAR_H

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
 
/*! \file var.h
 * see var.c for documentation 
 */


//! for entries in #var_table
typedef struct {
	const char *var_name;
	int var_value;
} var_table_entry;

extern var_table_entry var_table[];

int var_get(char *);
int var_set(char *,int);

#endif
