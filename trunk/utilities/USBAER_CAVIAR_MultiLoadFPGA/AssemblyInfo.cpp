#include "stdafx.h"

using namespace System;
using namespace System::Reflection;
using namespace System::Runtime::CompilerServices;
using namespace System::Runtime::InteropServices;
using namespace System::Security::Permissions;

//
// La informaci�n general sobre un ensamblado se controla mediante el siguiente
// conjunto de atributos. Cambie estos atributos para modificar la informaci�n
// asociada con un ensamblado.
//
[assembly:AssemblyTitleAttribute("MultiLoadFPGA")];
[assembly:AssemblyDescriptionAttribute("")];
[assembly:AssemblyConfigurationAttribute("")];
[assembly:AssemblyCompanyAttribute("Dpto Arquitectura y Tecnolog�a de Computadores")];
[assembly:AssemblyProductAttribute("MultiLoadFPGA")];
[assembly:AssemblyCopyrightAttribute("Copyright (c) Ninguna 2009")];
[assembly:AssemblyTrademarkAttribute("")];
[assembly:AssemblyCultureAttribute("")];

//
// La informaci�n de versi�n de un ensamblado consta de los cuatro valores siguientes:
//
//      Versi�n principal
//      Versi�n secundaria
//      N�mero de versi�n de compilaci�n
//      Revisi�n
//
// Puede especificar todos los valores o usar los valores predeterminados de n�mero de versi�n de compilaci�n y de revisi�n
// mediante el asterisco ('*'), como se muestra a continuaci�n:

[assembly:AssemblyVersionAttribute("0.9.5.*")];

[assembly:ComVisible(false)];

[assembly:CLSCompliantAttribute(true)];

[assembly:SecurityPermission(SecurityAction::RequestMinimum, UnmanagedCode = true)];
