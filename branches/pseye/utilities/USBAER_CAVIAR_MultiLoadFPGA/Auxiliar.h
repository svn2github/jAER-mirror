#pragma once

namespace Aux {

using namespace System;
using namespace System::ComponentModel;
using namespace System::Collections;
using namespace System::Windows::Forms;
using namespace System::Data;
using namespace System::Drawing;
using namespace System::IO;

public ref class Auxiliar
{	private: static bool Initialized = false;
	public: static bool AutomatCombo;
	public: static bool AutomatButton;
	public: static String ^Sequencer;
	public: static String ^Mapper;
	public: static String ^FrameGrabber;
	public: static String ^DataLogger;
	public: static String ^AppDirectory="";

	public:	Auxiliar(void)
	{	if (!Initialized)
		{	AppDirectory = System::Environment::CurrentDirectory;
			LoadConfig("setup.ini");
			Initialized = true;
		}
	}
	protected: ~Auxiliar()
	{
	}
	public: static bool LoadConfig(String ^ConfigFile)
	{	String^ SetupLine;
		String^ FullName = "";
		StreamReader^ MyFile;

		if (ConfigFile->Contains("\\"))
			FullName = ConfigFile;
		else
			FullName = String::Concat(AppDirectory,"\\",ConfigFile);
		if (!File::Exists(FullName))
		return false;
		MyFile = gcnew StreamReader(FullName);
		while (MyFile->Peek() >= 0)	// Si quedan líneas de configuración.
		{	SetupLine = MyFile->ReadLine();
			if (SetupLine->Length>0)
			{	if (System::String::Compare(SetupLine->Substring(0,1),"%")!=0)	// Si no es un comentario.
				{	if (!SetupLine->Contains("="))								// Si no hay dos campos separados por '='
						MessageBox::Show(String::Concat("wrong configuration line '",SetupLine,"'"), "Warning",MessageBoxButtons::OK,MessageBoxIcon::Warning);
					else
					{	array<String ^> ^ Values = SetupLine->Split('=');
						if (String::Compare(Values[0],"load_automat_when_device_type")==0)	// Configuración para cargar automát. el firm al seleccionar el tipo de dispositivo.
						{	if(String::Compare(Values[1],"yes")==0)
								AutomatCombo=true;
							else
								AutomatCombo=false;
						}
						else if (String::Compare(Values[0],"load_automat_when_push_button")==0)	// Configuración para cargar automát. el firm al seleccionar el tipo de dispositivo.
						{	if(String::Compare(Values[1],"yes")==0)
								AutomatButton=true;
							else
								AutomatButton=false;
						}
						else if (String::Compare(Values[0],"firmware_sequencer")==0)	// Ruta del firmware Sequencer
							Sequencer = Values[1];
						else if (String::Compare(Values[0],"firmware_mapper")==0)	// Ruta del firmware Sequencer
							Mapper = Values[1];
						else if (String::Compare(Values[0],"firmware_framegrabber")==0)	// Ruta del firmware Sequencer
							FrameGrabber = Values[1];
						else if (String::Compare(Values[0],"firmware_datalogger")==0)	// Ruta del firmware Sequencer
							DataLogger = Values[1];
						else
							MessageBox::Show(String::Concat("wrong configuration line '",SetupLine,"'"), "Warning",MessageBoxButtons::OK,MessageBoxIcon::Warning);
					}
				}
			}
		}
		MyFile->Close();
		return true;
	}

	public: static bool SaveConfig(String ^ConfigFile)
	{	String^ FullName = "";
		StreamWriter^ MyFile;
		FileStream^ fs;

		if (ConfigFile->Contains("\\"))
			FullName = ConfigFile;
		else
			FullName = String::Concat(AppDirectory,"\\",ConfigFile);
		fs = gcnew FileStream(FullName,FileMode::Create,FileAccess::Write,FileShare::None);
		MyFile = gcnew StreamWriter(fs);
		MyFile->WriteLine("% Use'%' at beginning of the line to add coments.");
		MyFile->WriteLine("");
		MyFile->WriteLine("% Load firmware automaticaly when another device type is selected.");
		if (AutomatCombo)
			MyFile->WriteLine("load_automat_when_device_type=yes");
		else
			MyFile->WriteLine("load_automat_when_device_type=no");
		MyFile->WriteLine("");
		MyFile->WriteLine("% Load firmware automaticaly when 'Load Firm' is pushed.");
		if (AutomatButton)
			MyFile->WriteLine("load_automat_when_push_button=yes");
		else
			MyFile->WriteLine("load_automat_when_push_button=no");
		MyFile->WriteLine("");
		MyFile->WriteLine("% firmwares path");
		MyFile->WriteLine(String::Concat("firmware_sequencer=",Sequencer));
		MyFile->WriteLine(String::Concat("firmware_mapper=",Mapper));
		MyFile->WriteLine(String::Concat("firmware_framegrabber=",FrameGrabber));
		MyFile->WriteLine(String::Concat("firmware_datalogger=",DataLogger));
		MyFile->Close();
		return true;
	}
};
}


/*public: static int MySharedData; 
	public: int MyMember;
	private: static String ^m_myPropertyData;
	public: int MyInstanceMember()
	{	return MySharedData;
	}
	public: static String ^MySharedProperty(void)
	{	get
		{	return m_myPropertyData;
		}
		set
		{	m_myPropertyData = value;
		}
	}
	public: static string MySharedFunction()
	{	return "I am shared function.";
	}

class class1
{
   static  void Main()
 
   {   
      ClsDemo.MySharedData = 100;  
      
      // Create an object of the ClsDemo class.
      ClsDemo objDemo1 = new ClsDemo(); 
      
      // Create a second object of the ClsDemo class.
      ClsDemo objDemo2 = new ClsDemo(); 

      //Initialize MyMember for the objDemo1 object.
      objDemo1.MyMember = 120; 
      
      Console.WriteLine("SharedData accessed by the first instance of ClsDemo {0}",objDemo1.MyInstanceMember());
      Console.WriteLine("SharedData accessed by the second instance of ClsDemo {0}",objDemo2.MyInstanceMember());
      Console.WriteLine("UnSharedData accessed by the first instance of ClsDemo {0}",objDemo1.MyMember);
      Console.WriteLine("UnSharedData accessed by the second instance of ClsDemo {0}",objDemo2.MyMember);

      // Access the shared property.
      ClsDemo.MySharedProperty = "I am shared property.";
      Console.WriteLine(ClsDemo.MySharedProperty);
   
      // Access the shared function.
      Console.WriteLine(ClsDemo.MySharedFunction());

      Console.WriteLine("Press the ENTER key...");
      Console.ReadLine();
   }
}*/