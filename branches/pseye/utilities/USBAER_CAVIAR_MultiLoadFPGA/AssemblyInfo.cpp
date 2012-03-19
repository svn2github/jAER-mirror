#include "stdafx.h"

using namespace System;
using namespace System::Reflection;
using namespace System::Runtime::CompilerServices;
using namespace System::Runtime::InteropServices;
using namespace System::Security::Permissions;

//
// La información general sobre un ensamblado se controla mediante el siguiente
// conjunto de atributos. Cambie estos atributos para modificar la información
// asociada con un ensamblado.
//
[assembly:AssemblyTitleAttribute("MultiLoadFPGA")];
[assembly:AssemblyDescriptionAttribute("")];
[assembly:AssemblyConfigurationAttribute("")];
[assembly:AssemblyCompanyAttribute("Dpto Arquitectura y Tecnología de Computadores")];
[assembly:AssemblyProductAttribute("MultiLoadFPGA")];
[assembly:AssemblyCopyrightAttribute("Copyright (c) Ninguna 2009")];
[assembly:AssemblyTrademarkAttribute("")];
[assembly:AssemblyCultureAttribute("")];

//
// La información de versión de un ensamblado consta de los cuatro valores siguientes:
//
//      Versión principal
//      Versión secundaria
//      Número de versión de compilación
//      Revisión
//
// Puede especificar todos los valores o usar los valores predeterminados de número de versión de compilación y de revisión
// mediante el asterisco ('*'), como se muestra a continuación:

[assembly:AssemblyVersionAttribute("0.9.5.*")];

[assembly:ComVisible(false)];

[assembly:CLSCompliantAttribute(true)];

[assembly:SecurityPermission(SecurityAction::RequestMinimum, UnmanagedCode = true)];
