#pragma once
#include "LoadFPGA.h"
#include "SetupForm.h"

using namespace System;
using namespace System::ComponentModel;
using namespace System::Collections;
using namespace System::Windows::Forms;
using namespace System::Data;
using namespace System::Drawing;
using namespace LoadFPGA;

namespace MultiLoadFPGA {

	/// <summary>
	/// Resumen de MultiLoadFPGAForm
	///
	/// ADVERTENCIA: si cambia el nombre de esta clase, deberá cambiar la
	///          propiedad 'Nombre de archivos de recursos' de la herramienta de compilación de recursos administrados
	///          asociada con todos los archivos .resx de los que depende esta clase. De lo contrario,
	///          los diseñadores no podrán interactuar correctamente con los
	///          recursos adaptados asociados con este formulario.
	/// </summary>
	public ref class MultiLoadFPGAForm : public System::Windows::Forms::Form
	{
	public: Collections::ArrayList ^ ListDevs;

	public:
		MultiLoadFPGAForm(void)
		{
			InitializeComponent();
			//
			//TODO: agregar código de constructor aquí
			//
			ListDevs = gcnew Collections::ArrayList();
			
		}

	protected:
		/// <summary>
		/// Limpiar los recursos que se estén utilizando.
		/// </summary>
		~MultiLoadFPGAForm()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::Button^  btnNew;
	protected: 

	private: System::Windows::Forms::TabControl^  tabGlobal;
	private: System::Windows::Forms::Button^  btnDelDevice;
	private: System::Windows::Forms::Button^  btnExtDevice;

	private: System::Windows::Forms::Button^  btnSetup;

	protected: 

	private:
		/// <summary>
		/// Variable del diseñador requerida.
		/// </summary>
		System::ComponentModel::Container ^components;

#pragma region Windows Form Designer generated code
		/// <summary>
		/// Método necesario para admitir el Diseñador. No se puede modificar
		/// el contenido del método con el editor de código.
		/// </summary>
		void InitializeComponent(void)
		{
			this->btnNew = (gcnew System::Windows::Forms::Button());
			this->tabGlobal = (gcnew System::Windows::Forms::TabControl());
			this->btnDelDevice = (gcnew System::Windows::Forms::Button());
			this->btnExtDevice = (gcnew System::Windows::Forms::Button());
			this->btnSetup = (gcnew System::Windows::Forms::Button());
			this->SuspendLayout();
			// 
			// btnNew
			// 
			this->btnNew->Location = System::Drawing::Point(342, 476);
			this->btnNew->Name = L"btnNew";
			this->btnNew->Size = System::Drawing::Size(83, 25);
			this->btnNew->TabIndex = 0;
			this->btnNew->Text = L"New Device";
			this->btnNew->UseVisualStyleBackColor = true;
			this->btnNew->Click += gcnew System::EventHandler(this, &MultiLoadFPGAForm::btnNew_Click);
			// 
			// tabGlobal
			// 
			this->tabGlobal->Location = System::Drawing::Point(1, 1);
			this->tabGlobal->Name = L"tabGlobal";
			this->tabGlobal->SelectedIndex = 0;
			this->tabGlobal->Size = System::Drawing::Size(434, 471);
			this->tabGlobal->TabIndex = 1;
			// 
			// btnDelDevice
			// 
			this->btnDelDevice->Location = System::Drawing::Point(164, 476);
			this->btnDelDevice->Name = L"btnDelDevice";
			this->btnDelDevice->Size = System::Drawing::Size(83, 25);
			this->btnDelDevice->TabIndex = 2;
			this->btnDelDevice->Text = L"Delete Device";
			this->btnDelDevice->UseVisualStyleBackColor = true;
			this->btnDelDevice->Click += gcnew System::EventHandler(this, &MultiLoadFPGAForm::btnDelDevice_Click);
			// 
			// btnExtDevice
			// 
			this->btnExtDevice->Location = System::Drawing::Point(253, 476);
			this->btnExtDevice->Name = L"btnExtDevice";
			this->btnExtDevice->Size = System::Drawing::Size(83, 25);
			this->btnExtDevice->TabIndex = 3;
			this->btnExtDevice->Text = L"Ext. Device";
			this->btnExtDevice->UseVisualStyleBackColor = true;
			this->btnExtDevice->Click += gcnew System::EventHandler(this, &MultiLoadFPGAForm::btnExtDevice_Click);
			// 
			// btnSetup
			// 
			this->btnSetup->Location = System::Drawing::Point(12, 476);
			this->btnSetup->Name = L"btnSetup";
			this->btnSetup->Size = System::Drawing::Size(83, 25);
			this->btnSetup->TabIndex = 4;
			this->btnSetup->Text = L"Setup";
			this->btnSetup->UseVisualStyleBackColor = true;
			this->btnSetup->Click += gcnew System::EventHandler(this, &MultiLoadFPGAForm::btnSetup_Click);
			// 
			// MultiLoadFPGAForm
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(437, 506);
			this->Controls->Add(this->btnSetup);
			this->Controls->Add(this->btnExtDevice);
			this->Controls->Add(this->btnDelDevice);
			this->Controls->Add(this->btnNew);
			this->Controls->Add(this->tabGlobal);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::Fixed3D;
			this->MaximizeBox = false;
			this->MinimizeBox = false;
			this->Name = L"MultiLoadFPGAForm";
			this->Text = L"MultiLoad FPGA v0.9.5 Beta";
			this->Load += gcnew System::EventHandler(this, &MultiLoadFPGAForm::MultiLoadFPGAForm_Load);
			this->ResumeLayout(false);

		}
#pragma endregion

private: System::Void btnNew_Click(System::Object^  sender, System::EventArgs^  e)
	{	LoadFPGA::LoadFPGAApp ^MyDevice;
		TabPage ^MyTabPage;
		
		if (ListDevs->Count == 10)
		{	MessageBox::Show("I think 10 devices are sufficient.", "Information",MessageBoxButtons::OK,MessageBoxIcon::Information);
			return;
		}
		MyTabPage = gcnew TabPage();
		tabGlobal->TabPages->Add(MyTabPage);

		MyTabPage->BackColor =  System::Drawing::SystemColors::ControlLight;
		MyDevice = gcnew LoadFPGA::LoadFPGAApp(); // Creo una instancia de LoadFPGAApp;
		MyDevice->DevNameUpdated += gcnew System::EventHandler(this, &MultiLoadFPGA::MultiLoadFPGAForm::UpdatingTabName); // Me suscribo al evento
		//this->btnDownFile->Click += gcnew System::EventHandler (this, &LoadFPGAApp::btnDownFile_Click);
		ListDevs->Add(MyDevice);
		int NumControls = MyDevice->Controls->Count;
		for (int i = 0; i < NumControls; i++)
		{	MyTabPage->Controls->Add(MyDevice->Controls[0]); //A medida que los añades desaparecen de la clase.
		}
		MyTabPage->Text = MyDevice->DevName;
		tabGlobal->SelectedTab = MyTabPage;
	}
// Función que se ejecutará cuando el evento ocurra.
private: void UpdatingTabName (Object^  sender, System::EventArgs^  e) // Estos parámetros los define siempre EventHandler.
	{	LoadFPGAApp ^MyDevice = (LoadFPGAApp ^) ListDevs[tabGlobal->SelectedIndex];
		tabGlobal->SelectedTab->Text = MyDevice->DevName;
	}
private: System::Void MultiLoadFPGAForm_Load(System::Object^  sender, System::EventArgs^  e)
	{	btnNew_Click(this, System::EventArgs::Empty);
	}

private: System::Void btnDelDevice_Click(System::Object^  sender, System::EventArgs^  e)
	{	if (ListDevs->Count == 1)
		 {	MessageBox::Show("Last device can not be deleted.", "Information",MessageBoxButtons::OK,MessageBoxIcon::Information);
			return;
		 }
		int curTab = tabGlobal->SelectedIndex;
		ListDevs->RemoveAt(tabGlobal->SelectedIndex);
		delete tabGlobal->SelectedTab;
	}

private: System::Void btnSetup_Click(System::Object^  sender, System::EventArgs^  e)
	{	SetupForm ^MySetupForm = gcnew SetupForm;
		MySetupForm->ShowDialog();
	}
private: System::Void btnExtDevice_Click(System::Object^  sender, System::EventArgs^  e)
	{	LoadFPGA::LoadFPGAApp ^MyDevice;
		MyDevice = gcnew LoadFPGA::LoadFPGAApp(); // Creo una instancia de LoadFPGAApp;
		MyDevice->Text = String::Concat("External ",this->Text->Substring(5));
		MyDevice->Show();
		
	}};
}
