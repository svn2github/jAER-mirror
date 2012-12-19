/*
 * NativeConvolutionMap.h
 *
 *  Created on: Dec 17, 2012
 *      Author: Dennis
 */

#ifndef NATIVECONVOLUTIONMAP_H_
#define NATIVECONVOLUTIONMAP_H_

class NativeConvolutionMap {
public:
	float ** values;
	float ** kernel;
	int width, height;
	NativeConvolutionMap(int width, int height);

	virtual ~NativeConvolutionMap();
};

#endif /* NATIVECONVOLUTIONMAP_H_ */
