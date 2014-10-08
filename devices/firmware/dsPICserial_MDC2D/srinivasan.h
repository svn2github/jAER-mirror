
#ifndef __SRINIVASAN_H__
#define __SRINIVASAN_H__

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
 
/*!\file srinivasan.h
 * see the file srinivasan.s inline documentation or the report mentioned
 * in README.txt for explanations on the algorithm
 */

/**
 * @brief calculates \c dx/2, \c dy/2 using a simplified version of
 *        Srinivasan's interpolating optical flow algorithm
 *
 * @param frame1 last frame captured (array of 20x20 of 10bit word values)
 * @param frame2 current frame captured (array of 20x20 of 10bit word values)
 *
 * @param dx_half where to store the \c dx/2 value (format Q15)
 *        ((unsigned int) dx4_ret) == 0xFFFF indicates an error
 *
 * @param shiftacc by how many bits to shift the accumulator in order to prevent
 *        overflow when transferring value into 16bit registers; increase this
 *        value if you get "overflow errors" -- a high value will reduce the
 *        precision
 *
 * @param dy_half where to store the \c dy/2 value (format Q15)
 *        in case of an error, ((unsigned int) dy4_ret) indicates
 *        the error source
 *         - 0x01 : overflow of dx (e.g. dx>2)
 *         - 0x02 : overflow of dy (e.g. dy>2)
 *         - 0x03,0x04 : singular matrix decomposition (exceptional)
 *         - 0x12..0x16 : internal overflow (see srinivasan.s)
 */

void srinivasan2D_16bit(const int *frame1,const int *frame2,
						int *dx_half,int *dy_half,
						int shiftacc);


#endif /* __SRINIVASAN_H__ */
