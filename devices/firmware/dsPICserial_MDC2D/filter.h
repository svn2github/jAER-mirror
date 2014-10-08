
#ifndef __FILTER_H__
#define __FILTER_H__

/*
 * Copyright November 25, 2011 Andreas Steiner, Inst. of Neuroinformatics, UNI-ETH Zurich
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

/*!\file filter.h
 * some simple filter functions
 */

/**
 * @brief resets the FPN reference image to zero
 */

void FPN_reset();

/**
 * @brief set FPN reference image; call this function with pixel data of an
 *        uniform frame to determine deviations from the mean
 *
 * @param frame reference frame (array of MDC_WIDTH*MDC_HEIGHT of 10bit word values)
 */

void FPN_set(const int *frame);

/**
 * @brief removes FPN from image using previously determined differences (see
 *        #FPN_set)
 *
 * @param frame containing FPN (array of MDC_WIDTH*MDC_HEIGHT of 10bit word values)
 */

void FPN_remove(int *frame);

#endif /* __FILTER_H__ */
