// MultiLoadFPGA.cpp: archivo de proyecto principal.
#include "stdafx.h"
#include <string.h>
#include <stdio.h>
#include <windows.h>
#include <vcclr.h>
#include <msclr/marshal.h>
#include <math.h>
#include <fstream>
#include "MultiLoadFPGA.h"

using namespace MultiLoadFPGA;

[STAThreadAttribute]
int main(array<System::String ^> ^args)
{	

	// Habilitar los efectos visuales de Windows XP antes de crear ningún control
	Application::EnableVisualStyles();
	Application::SetCompatibleTextRenderingDefault(false); 

	
	// Crear la ventana principal y ejecutarla
	Application::Run(gcnew MultiLoadFPGAForm());
	return 0;
}



