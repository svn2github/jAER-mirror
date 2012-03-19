/* 
 * File:   main.cpp
 * Author: mlk11
 *
 * Created on 29 December 2011, 12:24
 */

#include "src/server.h"

/*
 * 
 */
int main(int argc, char** argv) {
    PSEyeServer server = PSEyeServer();
    server.run();
    return 0;
}

