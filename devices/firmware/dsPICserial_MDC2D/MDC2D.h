#ifndef __MDC2D_H__
#define __MDC2D_H__

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
 
/*! \file MDC2D.h
 * see file MDC2D.c for documentation
 */

//! width (in pixels) of image sensor
#define MDC_WIDTH  20
//! height (in pixels) of image sensor
#define MDC_HEIGHT 20

extern int *lastframe;


extern unsigned char mdc_channels;
//! converting values from 2nd LMC circuit
#define MDC_CHANNELS_LMC2	0b1110
//! converting values from 1st LMC circuit
#define MDC_CHANNELS_LMC1	0b1101
//! converting values from photoreceptor circuit
#define MDC_CHANNELS_RECEP	0b1011
extern unsigned char mdc_master_current;


void mdc_init();
void mdc_write_shiftreg();
void mdc_set_biases(unsigned char biases[]);

extern int mdc_x,mdc_y;

void mdc_goto_x(int x);
void mdc_goto_y(int y);
void mdc_goto_xy(int x,int y);
void mdc_next_pixel();
void mdc_adc_init();
int mdc_adc_get();

#endif /* __MDC2D_H__ */

