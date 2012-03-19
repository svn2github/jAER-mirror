#pragma once
#include "Auxiliar.h"

using namespace System;
using namespace System::ComponentModel;
using namespace System::Collections;
using namespace System::Windows::Forms;
using namespace System::Data;
using namespace System::Drawing;
using namespace System::IO;
using namespace Aux;

namespace LoadFPGA {

	/// <summary>
	/// Resumen de SetupForm
	///
	/// ADVERTENCIA: si cambia el nombre de esta clase, deberá cambiar la
	///          propiedad 'Nombre de archivos de recursos' de la herramienta de compilación de recursos administrados
	///          asociada con todos los archivos .resx de los que depende esta clase. De lo contrario,
	///          los diseñadores no podrán interactuar correctamente con los
	///          recursos adaptados asociados con este formulario.
	/// </summary>
	public ref class SetupForm : public System::Windows::Forms::Form
	{
	public: Auxiliar ^Config;
	public:
		SetupForm(void)
		{
			InitializeComponent();
			//
			//TODO: agregar código de constructor aquí
			//
			Config = gcnew Auxiliar;
		}

	protected:
		/// <summary>
		/// Limpiar los recursos que se estén utilizando.
		/// </summary>
		~SetupForm()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::CheckBox^  chkAutomatCombo;
	private: System::Windows::Forms::Label^  lblDataLogger;
	private: System::Windows::Forms::TextBox^  txtDataLogger;
	private: System::Windows::Forms::Label^  lblFrameGrabber;
	private: System::Windows::Forms::TextBox^  txtFrameGrabber;
	private: System::Windows::Forms::Label^  lblMapper;
	private: System::Windows::Forms::TextBox^  txtMapper;
	private: System::Windows::Forms::Label^  lblSequencer;
	private: System::Windows::Forms::TextBox^  txtSequencer;
	private: System::Windows::Forms::CheckBox^  chkAutomatButton;
	private: System::Windows::Forms::Button^  btnSequencer;
	private: System::Windows::Forms::Button^  btnMapper;
	private: System::Windows::Forms::Button^  btnFrameGrabber;
	private: System::Windows::Forms::Button^  btnDataLogger;
	private: System::Windows::Forms::OpenFileDialog^  openFileDialog1;
	private: System::Windows::Forms::GroupBox^  grpButtons;
	private: System::Windows::Forms::Button^  btnSave;
	private: System::Windows::Forms::Button^  btlLoad;
	private: System::Windows::Forms::Button^  btnCancel;
	private: System::Windows::Forms::Button^  btnOk;
	private: System::Windows::Forms::SaveFileDialog^  saveFileDialog1;
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
			this->chkAutomatCombo = (gcnew System::Windows::Forms::CheckBox());
			this->lblDataLogger = (gcnew System::Windows::Forms::Label());
			this->txtDataLogger = (gcnew System::Windows::Forms::TextBox());
			this->lblFrameGrabber = (gcnew System::Windows::Forms::Label());
			this->txtFrameGrabber = (gcnew System::Windows::Forms::TextBox());
			this->lblMapper = (gcnew System::Windows::Forms::Label());
			this->txtMapper = (gcnew System::Windows::Forms::TextBox());
			this->lblSequencer = (gcnew System::Windows::Forms::Label());
			this->txtSequencer = (gcnew System::Windows::Forms::TextBox());
			this->chkAutomatButton = (gcnew System::Windows::Forms::CheckBox());
			this->btnSequencer = (gcnew System::Windows::Forms::Button());
			this->btnMapper = (gcnew System::Windows::Forms::Button());
			this->btnFrameGrabber = (gcnew System::Windows::Forms::Button());
			this->btnDataLogger = (gcnew System::Windows::Forms::Button());
			this->openFileDialog1 = (gcnew System::Windows::Forms::OpenFileDialog());
			this->grpButtons = (gcnew System::Windows::Forms::GroupBox());
			this->btnSave = (gcnew System::Windows::Forms::Button());
			this->btlLoad = (gcnew System::Windows::Forms::Button());
			this->btnCancel = (gcnew System::Windows::Forms::Button());
			this->btnOk = (gcnew System::Windows::Forms::Button());
			this->saveFileDialog1 = (gcnew System::Windows::Forms::SaveFileDialog());
			this->grpButtons->SuspendLayout();
			this->SuspendLayout();
			// 
			// chkAutomatCombo
			// 
			this->chkAutomatCombo->AutoSize = true;
			this->chkAutomatCombo->Location = System::Drawing::Point(18, 12);
			this->chkAutomatCombo->Name = L"chkAutomatCombo";
			this->chkAutomatCombo->Size = System::Drawing::Size(336, 17);
			this->chkAutomatCombo->TabIndex = 28;
			this->chkAutomatCombo->Text = L"Load firmware automaticaly when another device type is selected.";
			this->chkAutomatCombo->UseVisualStyleBackColor = true;
			// 
			// lblDataLogger
			// 
			this->lblDataLogger->BorderStyle = System::Windows::Forms::BorderStyle::Fixed3D;
			this->lblDataLogger->Location = System::Drawing::Point(18, 141);
			this->lblDataLogger->Name = L"lblDataLogger";
			this->lblDataLogger->Size = System::Drawing::Size(100, 20);
			this->lblDataLogger->TabIndex = 26;
			this->lblDataLogger->Text = L"DataLogger";
			this->lblDataLogger->TextAlign = System::Drawing::ContentAlignment::MiddleLeft;
			// 
			// txtDataLogger
			// 
			this->txtDataLogger->Location = System::Drawing::Point(120, 141);
			this->txtDataLogger->Name = L"txtDataLogger";
			this->txtDataLogger->Size = System::Drawing::Size(250, 20);
			this->txtDataLogger->TabIndex = 25;
			// 
			// lblFrameGrabber
			// 
			this->lblFrameGrabber->BorderStyle = System::Windows::Forms::BorderStyle::Fixed3D;
			this->lblFrameGrabber->Location = System::Drawing::Point(18, 115);
			this->lblFrameGrabber->Name = L"lblFrameGrabber";
			this->lblFrameGrabber->Size = System::Drawing::Size(100, 20);
			this->lblFrameGrabber->TabIndex = 24;
			this->lblFrameGrabber->Text = L"FrameGrabber";
			this->lblFrameGrabber->TextAlign = System::Drawing::ContentAlignment::MiddleLeft;
			// 
			// txtFrameGrabber
			// 
			this->txtFrameGrabber->Location = System::Drawing::Point(120, 115);
			this->txtFrameGrabber->Name = L"txtFrameGrabber";
			this->txtFrameGrabber->Size = System::Drawing::Size(250, 20);
			this->txtFrameGrabber->TabIndex = 23;
			// 
			// lblMapper
			// 
			this->lblMapper->BorderStyle = System::Windows::Forms::BorderStyle::Fixed3D;
			this->lblMapper->Location = System::Drawing::Point(18, 89);
			this->lblMapper->Name = L"lblMapper";
			this->lblMapper->Size = System::Drawing::Size(100, 20);
			this->lblMapper->TabIndex = 22;
			this->lblMapper->Text = L"Mapper";
			this->lblMapper->TextAlign = System::Drawing::ContentAlignment::MiddleLeft;
			// 
			// txtMapper
			// 
			this->txtMapper->Location = System::Drawing::Point(120, 89);
			this->txtMapper->Name = L"txtMapper";
			this->txtMapper->Size = System::Drawing::Size(250, 20);
			this->txtMapper->TabIndex = 21;
			// 
			// lblSequencer
			// 
			this->lblSequencer->BorderStyle = System::Windows::Forms::BorderStyle::Fixed3D;
			this->lblSequencer->Location = System::Drawing::Point(18, 63);
			this->lblSequencer->Name = L"lblSequencer";
			this->lblSequencer->Size = System::Drawing::Size(100, 20);
			this->lblSequencer->TabIndex = 20;
			this->lblSequencer->Text = L"Sequencer";
			this->lblSequencer->TextAlign = System::Drawing::ContentAlignment::MiddleLeft;
			// 
			// txtSequencer
			// 
			this->txtSequencer->Location = System::Drawing::Point(120, 63);
			this->txtSequencer->Name = L"txtSequencer";
			this->txtSequencer->Size = System::Drawing::Size(250, 20);
			this->txtSequencer->TabIndex = 19;
			// 
			// chkAutomatButton
			// 
			this->chkAutomatButton->AutoSize = true;
			this->chkAutomatButton->Location = System::Drawing::Point(18, 35);
			this->chkAutomatButton->Name = L"chkAutomatButton";
			this->chkAutomatButton->Size = System::Drawing::Size(287, 17);
			this->chkAutomatButton->TabIndex = 29;
			this->chkAutomatButton->Text = L"Load firmware automaticaly when \'Load Firm\' is pushed.";
			this->chkAutomatButton->UseVisualStyleBackColor = true;
			// 
			// btnSequencer
			// 
			this->btnSequencer->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 8.25F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->btnSequencer->Location = System::Drawing::Point(376, 63);
			this->btnSequencer->Name = L"btnSequencer";
			this->btnSequencer->Size = System::Drawing::Size(31, 20);
			this->btnSequencer->TabIndex = 30;
			this->btnSequencer->Text = L"...";
			this->btnSequencer->TextAlign = System::Drawing::ContentAlignment::TopCenter;
			this->btnSequencer->UseVisualStyleBackColor = true;
			this->btnSequencer->Click += gcnew System::EventHandler(this, &SetupForm::btnSequencer_Click);
			// 
			// btnMapper
			// 
			this->btnMapper->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 8.25F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->btnMapper->Location = System::Drawing::Point(376, 89);
			this->btnMapper->Name = L"btnMapper";
			this->btnMapper->Size = System::Drawing::Size(31, 20);
			this->btnMapper->TabIndex = 31;
			this->btnMapper->Text = L"...";
			this->btnMapper->TextAlign = System::Drawing::ContentAlignment::TopCenter;
			this->btnMapper->UseVisualStyleBackColor = true;
			this->btnMapper->Click += gcnew System::EventHandler(this, &SetupForm::btnMapper_Click);
			// 
			// btnFrameGrabber
			// 
			this->btnFrameGrabber->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 8.25F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->btnFrameGrabber->Location = System::Drawing::Point(376, 115);
			this->btnFrameGrabber->Name = L"btnFrameGrabber";
			this->btnFrameGrabber->Size = System::Drawing::Size(31, 20);
			this->btnFrameGrabber->TabIndex = 32;
			this->btnFrameGrabber->Text = L"...";
			this->btnFrameGrabber->TextAlign = System::Drawing::ContentAlignment::TopCenter;
			this->btnFrameGrabber->UseVisualStyleBackColor = true;
			this->btnFrameGrabber->Click += gcnew System::EventHandler(this, &SetupForm::btnFrameGrabber_Click);
			// 
			// btnDataLogger
			// 
			this->btnDataLogger->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 8.25F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->btnDataLogger->Location = System::Drawing::Point(376, 141);
			this->btnDataLogger->Name = L"btnDataLogger";
			this->btnDataLogger->Size = System::Drawing::Size(31, 20);
			this->btnDataLogger->TabIndex = 33;
			this->btnDataLogger->Text = L"...";
			this->btnDataLogger->TextAlign = System::Drawing::ContentAlignment::TopCenter;
			this->btnDataLogger->UseVisualStyleBackColor = true;
			this->btnDataLogger->Click += gcnew System::EventHandler(this, &SetupForm::btnDataLogger_Click);
			// 
			// openFileDialog1
			// 
			this->openFileDialog1->FileName = L"openFileDialog1";
			// 
			// grpButtons
			// 
			this->grpButtons->Controls->Add(this->btnSave);
			this->grpButtons->Controls->Add(this->btlLoad);
			this->grpButtons->Controls->Add(this->btnCancel);
			this->grpButtons->Controls->Add(this->btnOk);
			this->grpButtons->Location = System::Drawing::Point(71, 168);
			this->grpButtons->Name = L"grpButtons";
			this->grpButtons->Size = System::Drawing::Size(336, 47);
			this->grpButtons->TabIndex = 37;
			this->grpButtons->TabStop = false;
			// 
			// btnSave
			// 
			this->btnSave->Location = System::Drawing::Point(8, 16);
			this->btnSave->Name = L"btnSave";
			this->btnSave->Size = System::Drawing::Size(75, 23);
			this->btnSave->TabIndex = 40;
			this->btnSave->Text = L"Save Config";
			this->btnSave->UseVisualStyleBackColor = true;
			this->btnSave->Click += gcnew System::EventHandler(this, &SetupForm::btnSave_Click);
			// 
			// btlLoad
			// 
			this->btlLoad->Location = System::Drawing::Point(89, 16);
			this->btlLoad->Name = L"btlLoad";
			this->btlLoad->Size = System::Drawing::Size(75, 23);
			this->btlLoad->TabIndex = 39;
			this->btlLoad->Text = L"Load Config";
			this->btlLoad->UseVisualStyleBackColor = true;
			this->btlLoad->Click += gcnew System::EventHandler(this, &SetupForm::btlLoad_Click);
			// 
			// btnCancel
			// 
			this->btnCancel->DialogResult = System::Windows::Forms::DialogResult::Cancel;
			this->btnCancel->Location = System::Drawing::Point(170, 16);
			this->btnCancel->Name = L"btnCancel";
			this->btnCancel->Size = System::Drawing::Size(75, 23);
			this->btnCancel->TabIndex = 38;
			this->btnCancel->Text = L"Cancel";
			this->btnCancel->UseVisualStyleBackColor = true;
			// 
			// btnOk
			// 
			this->btnOk->DialogResult = System::Windows::Forms::DialogResult::OK;
			this->btnOk->Location = System::Drawing::Point(251, 16);
			this->btnOk->Name = L"btnOk";
			this->btnOk->Size = System::Drawing::Size(75, 23);
			this->btnOk->TabIndex = 37;
			this->btnOk->Text = L"OK";
			this->btnOk->UseVisualStyleBackColor = true;
			this->btnOk->Click += gcnew System::EventHandler(this, &SetupForm::btnOk_Click);
			// 
			// SetupForm
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(429, 227);
			this->ControlBox = false;
			this->Controls->Add(this->grpButtons);
			this->Controls->Add(this->btnDataLogger);
			this->Controls->Add(this->btnFrameGrabber);
			this->Controls->Add(this->btnMapper);
			this->Controls->Add(this->btnSequencer);
			this->Controls->Add(this->chkAutomatButton);
			this->Controls->Add(this->chkAutomatCombo);
			this->Controls->Add(this->lblDataLogger);
			this->Controls->Add(this->txtDataLogger);
			this->Controls->Add(this->lblFrameGrabber);
			this->Controls->Add(this->txtFrameGrabber);
			this->Controls->Add(this->lblMapper);
			this->Controls->Add(this->txtMapper);
			this->Controls->Add(this->lblSequencer);
			this->Controls->Add(this->txtSequencer);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedDialog;
			this->Name = L"SetupForm";
			this->StartPosition = System::Windows::Forms::FormStartPosition::CenterParent;
			this->Text = L"SetupForm";
			this->Load += gcnew System::EventHandler(this, &SetupForm::SetupForm_Load);
			this->grpButtons->ResumeLayout(false);
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
private: System::Void SetupForm_Load(System::Object^  sender, System::EventArgs^  e)
	{	chkAutomatCombo->Checked = Config->AutomatCombo;
		chkAutomatButton->Checked = Config->AutomatButton;
		txtSequencer->Text = Config->Sequencer;
		txtMapper->Text = Config->Mapper;
		txtFrameGrabber->Text = Config->FrameGrabber;
		txtDataLogger->Text = Config->DataLogger;
	}
private: System::Void btnOk_Click(System::Object^  sender, System::EventArgs^  e)
	{	MySave("setup.ini");
	}
private: System::Void btnSequencer_Click(System::Object^  sender, System::EventArgs^  e)
	{	openFileDialog1->Filter = "Binary files|*.bin|All files|*.*";
		if (openFileDialog1->ShowDialog() == System::Windows::Forms::DialogResult::OK)
			txtSequencer->Text = openFileDialog1->FileName;
	}
private: System::Void btnMapper_Click(System::Object^  sender, System::EventArgs^  e)
	{ 	openFileDialog1->Filter = "Binary files|*.bin|All files|*.*";
		if (openFileDialog1->ShowDialog() == System::Windows::Forms::DialogResult::OK)
			txtMapper->Text = openFileDialog1->FileName;
	}

private: System::Void btnFrameGrabber_Click(System::Object^  sender, System::EventArgs^  e)
	{ 	openFileDialog1->Filter = "Binary files|*.bin|All files|*.*";
		if (openFileDialog1->ShowDialog() == System::Windows::Forms::DialogResult::OK)
			txtFrameGrabber->Text = openFileDialog1->FileName;
	}
private: System::Void btnDataLogger_Click(System::Object^  sender, System::EventArgs^  e)
	{ 	openFileDialog1->Filter = "Binary files|*.bin|All files|*.*";
		if (openFileDialog1->ShowDialog() == System::Windows::Forms::DialogResult::OK)
			txtDataLogger->Text = openFileDialog1->FileName;
	}

private: System::Void btlLoad_Click(System::Object^  sender, System::EventArgs^  e)
	{ 	openFileDialog1->Filter = "Config files|*.cfg";
		if (openFileDialog1->ShowDialog() == System::Windows::Forms::DialogResult::OK)
		{	Config->LoadConfig(openFileDialog1->FileName);
			chkAutomatCombo->Checked = Config->AutomatCombo;
			chkAutomatButton->Checked = Config->AutomatButton;
			txtSequencer->Text = Config->Sequencer;
			txtMapper->Text = Config->Mapper;
			txtFrameGrabber->Text = Config->FrameGrabber;
			txtDataLogger->Text = Config->DataLogger;
		}
	}
private: System::Void btnSave_Click(System::Object^  sender, System::EventArgs^  e)
	{	saveFileDialog1->Filter = "Config files|*.cfg";
		if (saveFileDialog1->ShowDialog() == System::Windows::Forms::DialogResult::OK)
			MySave(saveFileDialog1->FileName);
	}
 void MySave(String ^File)
	{	Config->AutomatCombo = chkAutomatCombo->Checked;
		Config->AutomatButton = chkAutomatButton->Checked;
		Config->Sequencer = txtSequencer->Text;
		Config->Mapper = txtMapper->Text;
		Config->FrameGrabber = txtFrameGrabber->Text;
		Config->DataLogger = txtDataLogger->Text;
		Config->SaveConfig(File);
	}

void MyLoad(String ^File)
	{	
	}
};
}