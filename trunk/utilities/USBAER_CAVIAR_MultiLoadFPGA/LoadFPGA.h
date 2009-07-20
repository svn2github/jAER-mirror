#pragma once
#include "AliasForm.h"
//Recuerda añadir en Propiedades->Vinculador->Entrada->Dependencias adicionales, la librería setupapi.lib
#include <setupapi.h>	//Librería para el Listar el alias de los dispositivos.
#include "Auxiliar.h"

#define My_Device_CLASS_GUID \
	{ 0xff646f80, 0x8def, 0x11d2, { 0x94, 0x49, 0x00, 0x10, 0x5a, 0x07, 0x5f, 0x6b } }


namespace LoadFPGA {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace msclr::interop;
	using namespace System::IO;
	//using namespace System::Math;
	using namespace std;
	using namespace Aux;


	/// <summary>
	/// Resumen de LoadFPGAApp
	///
	/// ADVERTENCIA: si cambia el nombre de esta clase, deberá cambiar la
	///          propiedad 'Nombre de archivos de recursos' de la herramienta de compilación de recursos administrados
	///          asociada con todos los archivos .resx de los que depende esta clase. De lo contrario,
	///          los diseñadores no podrán interactuar correctamente con los
	///          recursos adaptados asociados con este formulario.
	/// </summary>

	
	public ref class LoadFPGAApp : public System::Windows::Forms::Form
	{
	// Variables globales.
	public: String ^DevName;	// Mantiene el nombre del dispositivo para ser leído desde fuera de la clase.
	public: Auxiliar ^Config;

	private: unsigned int fgFramesPerSec; // Variables globales para la visualización de imágenes mediante el FG.
	private: unsigned int fgGreyScale;
	private: unsigned int fgFgSize;
	private: unsigned int fgImgSize;
	private: unsigned int fgHwTimer;
	private: unsigned int fgSwTimer;
	private: HANDLE fgHnd;
	private: bool takePhoto;
	private: int LastGotFocus;	// Para seleccionar el texto únicamente al obtener el foco.
	private: System::Windows::Forms::Label^  lblDevType;
	private: System::Windows::Forms::Button^  btnAlias;
	private: System::Windows::Forms::ComboBox^  cmbDevType;
	private: System::Windows::Forms::Button^  btnSendCommand;
	private: System::Windows::Forms::Button^  btnDownFile;
	private: System::Windows::Forms::Label^  lblSize;
	private: System::Windows::Forms::TextBox^  txtLong;
	private: System::Windows::Forms::Label^  lblCmd;
	private: System::Windows::Forms::TextBox^  txtCmd;
	private: System::Windows::Forms::Label^  lblStart;
	private: System::Windows::Forms::TextBox^  txtStart;
	private: System::Windows::Forms::Button^  btnUpFile;
	private: System::Windows::Forms::Label^  lblDevName;
	private: System::Windows::Forms::Button^  btnLoad;
	private: System::Windows::Forms::GroupBox^  grpFGrabber;
	private: System::Windows::Forms::Button^  btnStart;
	private: System::Windows::Forms::Label^  lblFrameSec;
	private: System::Windows::Forms::Label^  txtFrameSec;
	private: System::Windows::Forms::Label^  txtImgCharge;
	private: System::Windows::Forms::Button^  btnUpdate;
	private: System::Windows::Forms::TextBox^  txtHwTimer;
	private: System::Windows::Forms::Label^  lblHwTimer;
	private: System::Windows::Forms::Label^  lblImgCharge;
	private: System::Windows::Forms::TextBox^  txtfgSize;
	private: System::Windows::Forms::Label^  lblImgSize;
	private: System::Windows::Forms::Label^  lblfgSize;
	private: System::Windows::Forms::TextBox^  txtGreyScale;
	private: System::Windows::Forms::Label^  lblGreyScale;
	private: System::Windows::Forms::TextBox^  txtSwTimer;
	private: System::Windows::Forms::Label^  lblSwTimer;
	private: System::Windows::Forms::PictureBox^  display;
	private: System::Windows::Forms::GroupBox^  grpData;
	private: System::Windows::Forms::TextBox^  txtDataToReceive;
	private: System::Windows::Forms::Label^  lblReadBuffer;
	private: System::Windows::Forms::TextBox^  txtDataToSend;
	private: System::Windows::Forms::Label^  lblSendBuffer;
	private: System::Windows::Forms::Button^  btnReceive;
	private: System::Windows::Forms::Button^  btnSend;
	private: System::Windows::Forms::Label^  lblBytesToSend;
	private: System::Windows::Forms::CheckBox^  chkExtend;
	private: System::Windows::Forms::Label^  lblFgSize;
	private: System::Windows::Forms::TextBox^  txtImgSize;
	private: System::Windows::Forms::OpenFileDialog^  openFileDialog1;
	private: System::Windows::Forms::Button^  btnSave;
	private: System::Windows::Forms::SaveFileDialog^  saveFileDialog1;
	private: System::Windows::Forms::StatusStrip^  Devstatus;
	private: System::Windows::Forms::ToolStripStatusLabel^  lblStatus;
	internal: System::Windows::Forms::ToolStripProgressBar^  StatusBar;
	private: System::Windows::Forms::TextBox^  txtBuffer;
	private: System::Windows::Forms::TextBox^  textBox1;
	private: System::Windows::Forms::Timer^  refreshTimer;
	private: System::Windows::Forms::Timer^  frameTimer;
	private: System::Windows::Forms::CheckBox^  chkColumns;
	private: System::Windows::Forms::ComboBox^  cmbDataLogger;
	private: System::Windows::Forms::ComboBox^  cmbReceiveAs;
	private: System::Windows::Forms::Label^  lblReceiveAs;
	private: System::Windows::Forms::Label^  lblSendAs;
	private: System::Windows::Forms::ComboBox^  cmbSendAs;
	private: System::Windows::Forms::ComboBox^  cmbDevName;
	private: System::Windows::Forms::ComboBox^  cmbDataLogger1;
	private: System::Windows::Forms::ComboBox^  cmbDataLogger2;
	private: System::ComponentModel::IContainer^  components;

	public:
		LoadFPGAApp(void)
		{
			InitializeComponent();
			//
			//TODO: agregar código de constructor aquí
			//
			UpdateDevicesList();
			Config = gcnew Auxiliar;
			cmbDevType->SelectedIndex = 0;
			cmbDataLogger->SelectedIndex = 3;
			cmbDataLogger1->SelectedIndex = 0;
			cmbDataLogger2->SelectedIndex = 0;
			cmbReceiveAs->SelectedIndex = 0;
			cmbSendAs->SelectedIndex = 0;
			
		}
	protected:
		/// <summary>
		/// Limpiar los recursos que se estén utilizando.
		/// </summary>
		~LoadFPGAApp()
		{
			if (components)
			{
				delete components;
			}
		}
	private:
		/// <summary>
		/// Variable del diseñador requerida.
		/// </summary>

#pragma region Windows Form Designer generated code
		/// <summary>
		/// Método necesario para admitir el Diseñador. No se puede modificar
		/// el contenido del método con el editor de código.
		/// </summary>
		void InitializeComponent(void)
		{
			this->components = (gcnew System::ComponentModel::Container());
			this->saveFileDialog1 = (gcnew System::Windows::Forms::SaveFileDialog());
			this->Devstatus = (gcnew System::Windows::Forms::StatusStrip());
			this->StatusBar = (gcnew System::Windows::Forms::ToolStripProgressBar());
			this->lblStatus = (gcnew System::Windows::Forms::ToolStripStatusLabel());
			this->txtBuffer = (gcnew System::Windows::Forms::TextBox());
			this->textBox1 = (gcnew System::Windows::Forms::TextBox());
			this->refreshTimer = (gcnew System::Windows::Forms::Timer(this->components));
			this->frameTimer = (gcnew System::Windows::Forms::Timer(this->components));
			this->lblDevType = (gcnew System::Windows::Forms::Label());
			this->btnAlias = (gcnew System::Windows::Forms::Button());
			this->cmbDevType = (gcnew System::Windows::Forms::ComboBox());
			this->btnSendCommand = (gcnew System::Windows::Forms::Button());
			this->btnDownFile = (gcnew System::Windows::Forms::Button());
			this->lblSize = (gcnew System::Windows::Forms::Label());
			this->txtLong = (gcnew System::Windows::Forms::TextBox());
			this->lblCmd = (gcnew System::Windows::Forms::Label());
			this->txtCmd = (gcnew System::Windows::Forms::TextBox());
			this->lblStart = (gcnew System::Windows::Forms::Label());
			this->txtStart = (gcnew System::Windows::Forms::TextBox());
			this->btnUpFile = (gcnew System::Windows::Forms::Button());
			this->lblDevName = (gcnew System::Windows::Forms::Label());
			this->btnLoad = (gcnew System::Windows::Forms::Button());
			this->grpFGrabber = (gcnew System::Windows::Forms::GroupBox());
			this->btnSave = (gcnew System::Windows::Forms::Button());
			this->lblFgSize = (gcnew System::Windows::Forms::Label());
			this->txtImgSize = (gcnew System::Windows::Forms::TextBox());
			this->btnStart = (gcnew System::Windows::Forms::Button());
			this->lblFrameSec = (gcnew System::Windows::Forms::Label());
			this->txtFrameSec = (gcnew System::Windows::Forms::Label());
			this->txtImgCharge = (gcnew System::Windows::Forms::Label());
			this->btnUpdate = (gcnew System::Windows::Forms::Button());
			this->txtHwTimer = (gcnew System::Windows::Forms::TextBox());
			this->lblHwTimer = (gcnew System::Windows::Forms::Label());
			this->lblImgCharge = (gcnew System::Windows::Forms::Label());
			this->txtfgSize = (gcnew System::Windows::Forms::TextBox());
			this->lblImgSize = (gcnew System::Windows::Forms::Label());
			this->txtGreyScale = (gcnew System::Windows::Forms::TextBox());
			this->lblGreyScale = (gcnew System::Windows::Forms::Label());
			this->txtSwTimer = (gcnew System::Windows::Forms::TextBox());
			this->lblSwTimer = (gcnew System::Windows::Forms::Label());
			this->display = (gcnew System::Windows::Forms::PictureBox());
			this->grpData = (gcnew System::Windows::Forms::GroupBox());
			this->lblSendAs = (gcnew System::Windows::Forms::Label());
			this->cmbSendAs = (gcnew System::Windows::Forms::ComboBox());
			this->lblReceiveAs = (gcnew System::Windows::Forms::Label());
			this->cmbReceiveAs = (gcnew System::Windows::Forms::ComboBox());
			this->chkColumns = (gcnew System::Windows::Forms::CheckBox());
			this->lblSendBuffer = (gcnew System::Windows::Forms::Label());
			this->txtDataToSend = (gcnew System::Windows::Forms::TextBox());
			this->chkExtend = (gcnew System::Windows::Forms::CheckBox());
			this->txtDataToReceive = (gcnew System::Windows::Forms::TextBox());
			this->lblReadBuffer = (gcnew System::Windows::Forms::Label());
			this->btnReceive = (gcnew System::Windows::Forms::Button());
			this->btnSend = (gcnew System::Windows::Forms::Button());
			this->lblBytesToSend = (gcnew System::Windows::Forms::Label());
			this->openFileDialog1 = (gcnew System::Windows::Forms::OpenFileDialog());
			this->cmbDataLogger = (gcnew System::Windows::Forms::ComboBox());
			this->cmbDevName = (gcnew System::Windows::Forms::ComboBox());
			this->cmbDataLogger1 = (gcnew System::Windows::Forms::ComboBox());
			this->cmbDataLogger2 = (gcnew System::Windows::Forms::ComboBox());
			this->Devstatus->SuspendLayout();
			this->grpFGrabber->SuspendLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->display))->BeginInit();
			this->grpData->SuspendLayout();
			this->SuspendLayout();
			// 
			// Devstatus
			// 
			this->Devstatus->AutoSize = false;
			this->Devstatus->BackColor = System::Drawing::SystemColors::Control;
			this->Devstatus->GripStyle = System::Windows::Forms::ToolStripGripStyle::Visible;
			this->Devstatus->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(2) {this->StatusBar, this->lblStatus});
			this->Devstatus->LayoutStyle = System::Windows::Forms::ToolStripLayoutStyle::Flow;
			this->Devstatus->Location = System::Drawing::Point(0, 419);
			this->Devstatus->Name = L"Devstatus";
			this->Devstatus->Size = System::Drawing::Size(428, 26);
			this->Devstatus->SizingGrip = false;
			this->Devstatus->TabIndex = 5;
			this->Devstatus->Text = L"statusStrip1";
			// 
			// StatusBar
			// 
			this->StatusBar->Name = L"StatusBar";
			this->StatusBar->Padding = System::Windows::Forms::Padding(5, 0, 5, 0);
			this->StatusBar->Size = System::Drawing::Size(220, 20);
			this->StatusBar->Style = System::Windows::Forms::ProgressBarStyle::Continuous;
			// 
			// lblStatus
			// 
			this->lblStatus->AutoSize = false;
			this->lblStatus->Font = (gcnew System::Drawing::Font(L"Tahoma", 9, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->lblStatus->Margin = System::Windows::Forms::Padding(0, 6, 0, 2);
			this->lblStatus->Name = L"lblStatus";
			this->lblStatus->Size = System::Drawing::Size(170, 14);
			this->lblStatus->Text = L"Ready";
			this->lblStatus->TextAlign = System::Drawing::ContentAlignment::MiddleLeft;
			// 
			// txtBuffer
			// 
			this->txtBuffer->Location = System::Drawing::Point(6, 19);
			this->txtBuffer->Multiline = true;
			this->txtBuffer->Name = L"txtBuffer";
			this->txtBuffer->Size = System::Drawing::Size(342, 256);
			this->txtBuffer->TabIndex = 8;
			// 
			// textBox1
			// 
			this->textBox1->Location = System::Drawing::Point(6, 19);
			this->textBox1->Multiline = true;
			this->textBox1->Name = L"textBox1";
			this->textBox1->Size = System::Drawing::Size(342, 256);
			this->textBox1->TabIndex = 8;
			// 
			// refreshTimer
			// 
			this->refreshTimer->Tick += gcnew System::EventHandler(this, &LoadFPGAApp::refreshTimer_Tick);
			// 
			// frameTimer
			// 
			this->frameTimer->Interval = 1000;
			this->frameTimer->Tick += gcnew System::EventHandler(this, &LoadFPGAApp::frameTimer_Tick);
			// 
			// lblDevType
			// 
			this->lblDevType->AutoSize = true;
			this->lblDevType->Location = System::Drawing::Point(126, 5);
			this->lblDevType->Name = L"lblDevType";
			this->lblDevType->Size = System::Drawing::Size(68, 13);
			this->lblDevType->TabIndex = 47;
			this->lblDevType->Text = L"Device Type";
			// 
			// btnAlias
			// 
			this->btnAlias->BackColor = System::Drawing::SystemColors::Control;
			this->btnAlias->Location = System::Drawing::Point(334, 15);
			this->btnAlias->Name = L"btnAlias";
			this->btnAlias->Size = System::Drawing::Size(84, 30);
			this->btnAlias->TabIndex = 3;
			this->btnAlias->Text = L"Change Alias";
			this->btnAlias->UseVisualStyleBackColor = false;
			this->btnAlias->Click += gcnew System::EventHandler(this, &LoadFPGAApp::btnAlias_Click);
			// 
			// cmbDevType
			// 
			this->cmbDevType->BackColor = System::Drawing::SystemColors::Control;
			this->cmbDevType->DropDownStyle = System::Windows::Forms::ComboBoxStyle::DropDownList;
			this->cmbDevType->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 8.25F, System::Drawing::FontStyle::Bold, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->cmbDevType->ForeColor = System::Drawing::SystemColors::WindowText;
			this->cmbDevType->FormattingEnabled = true;
			this->cmbDevType->Items->AddRange(gcnew cli::array< System::Object^  >(5) {L"(Generic)", L"Sequencer", L"Mapper", L"Framegrabber", 
				L"Datalogger"});
			this->cmbDevType->Location = System::Drawing::Point(129, 21);
			this->cmbDevType->Name = L"cmbDevType";
			this->cmbDevType->Size = System::Drawing::Size(105, 21);
			this->cmbDevType->TabIndex = 1;
			this->cmbDevType->SelectedIndexChanged += gcnew System::EventHandler(this, &LoadFPGAApp::cmbDevType_SelectedItemChanged);
			// 
			// btnSendCommand
			// 
			this->btnSendCommand->BackColor = System::Drawing::SystemColors::Control;
			this->btnSendCommand->Location = System::Drawing::Point(334, 59);
			this->btnSendCommand->Name = L"btnSendCommand";
			this->btnSendCommand->Size = System::Drawing::Size(84, 30);
			this->btnSendCommand->TabIndex = 6;
			this->btnSendCommand->Text = L"Send Cmd";
			this->btnSendCommand->UseVisualStyleBackColor = false;
			this->btnSendCommand->Click += gcnew System::EventHandler(this, &LoadFPGAApp::btnSendCommand_Click);
			// 
			// btnDownFile
			// 
			this->btnDownFile->BackColor = System::Drawing::SystemColors::Control;
			this->btnDownFile->Location = System::Drawing::Point(334, 102);
			this->btnDownFile->Name = L"btnDownFile";
			this->btnDownFile->Size = System::Drawing::Size(84, 30);
			this->btnDownFile->TabIndex = 10;
			this->btnDownFile->Text = L"Download File";
			this->btnDownFile->UseVisualStyleBackColor = false;
			this->btnDownFile->Click += gcnew System::EventHandler(this, &LoadFPGAApp::btnDownFile_Click);
			// 
			// lblSize
			// 
			this->lblSize->AutoSize = true;
			this->lblSize->Location = System::Drawing::Point(126, 91);
			this->lblSize->Name = L"lblSize";
			this->lblSize->Size = System::Drawing::Size(94, 13);
			this->lblSize->TabIndex = 39;
			this->lblSize->Text = L"Bytes to download";
			// 
			// txtLong
			// 
			this->txtLong->BackColor = System::Drawing::SystemColors::Control;
			this->txtLong->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 9.75F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->txtLong->Location = System::Drawing::Point(129, 106);
			this->txtLong->Name = L"txtLong";
			this->txtLong->Size = System::Drawing::Size(105, 22);
			this->txtLong->TabIndex = 8;
			this->txtLong->Text = L"1024";
			this->txtLong->TextAlign = System::Windows::Forms::HorizontalAlignment::Center;
			this->txtLong->Click += gcnew System::EventHandler(this, &LoadFPGAApp::SelectingText);
			this->txtLong->Leave += gcnew System::EventHandler(this, &LoadFPGAApp::VerifyUnsignedIntValue);
			// 
			// lblCmd
			// 
			this->lblCmd->AutoSize = true;
			this->lblCmd->Location = System::Drawing::Point(4, 50);
			this->lblCmd->Name = L"lblCmd";
			this->lblCmd->Size = System::Drawing::Size(134, 13);
			this->lblCmd->TabIndex = 37;
			this->lblCmd->Text = L"Command   (16 bytes max.)";
			// 
			// txtCmd
			// 
			this->txtCmd->BackColor = System::Drawing::SystemColors::Control;
			this->txtCmd->Location = System::Drawing::Point(9, 65);
			this->txtCmd->Name = L"txtCmd";
			this->txtCmd->Size = System::Drawing::Size(223, 20);
			this->txtCmd->TabIndex = 4;
			this->txtCmd->TextChanged += gcnew System::EventHandler(this, &LoadFPGAApp::txtCmd_TextChanged);
			this->txtCmd->Click += gcnew System::EventHandler(this, &LoadFPGAApp::SelectingText);
			this->txtCmd->KeyPress += gcnew System::Windows::Forms::KeyPressEventHandler(this, &LoadFPGAApp::txtCmd_KeyPress);
			// 
			// lblStart
			// 
			this->lblStart->AutoSize = true;
			this->lblStart->Location = System::Drawing::Point(4, 91);
			this->lblStart->Name = L"lblStart";
			this->lblStart->Size = System::Drawing::Size(112, 13);
			this->lblStart->TabIndex = 35;
			this->lblStart->Text = L"Initial Memory Address";
			// 
			// txtStart
			// 
			this->txtStart->BackColor = System::Drawing::SystemColors::Control;
			this->txtStart->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 9.75F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->txtStart->Location = System::Drawing::Point(9, 106);
			this->txtStart->Name = L"txtStart";
			this->txtStart->Size = System::Drawing::Size(107, 22);
			this->txtStart->TabIndex = 7;
			this->txtStart->Text = L"0";
			this->txtStart->TextAlign = System::Windows::Forms::HorizontalAlignment::Center;
			this->txtStart->Click += gcnew System::EventHandler(this, &LoadFPGAApp::SelectingText);
			this->txtStart->Leave += gcnew System::EventHandler(this, &LoadFPGAApp::VerifyUnsignedIntValue);
			// 
			// btnUpFile
			// 
			this->btnUpFile->BackColor = System::Drawing::SystemColors::Control;
			this->btnUpFile->Location = System::Drawing::Point(243, 102);
			this->btnUpFile->Name = L"btnUpFile";
			this->btnUpFile->Size = System::Drawing::Size(84, 30);
			this->btnUpFile->TabIndex = 9;
			this->btnUpFile->Text = L"Upload File";
			this->btnUpFile->UseVisualStyleBackColor = false;
			this->btnUpFile->Click += gcnew System::EventHandler(this, &LoadFPGAApp::btnUpFile_Click);
			// 
			// lblDevName
			// 
			this->lblDevName->AutoSize = true;
			this->lblDevName->Location = System::Drawing::Point(4, 5);
			this->lblDevName->Name = L"lblDevName";
			this->lblDevName->Size = System::Drawing::Size(72, 13);
			this->lblDevName->TabIndex = 31;
			this->lblDevName->Text = L"Device Name";
			// 
			// btnLoad
			// 
			this->btnLoad->BackColor = System::Drawing::SystemColors::Control;
			this->btnLoad->Location = System::Drawing::Point(243, 15);
			this->btnLoad->Name = L"btnLoad";
			this->btnLoad->Size = System::Drawing::Size(84, 30);
			this->btnLoad->TabIndex = 2;
			this->btnLoad->Text = L"Load Firm";
			this->btnLoad->UseVisualStyleBackColor = false;
			this->btnLoad->Click += gcnew System::EventHandler(this, &LoadFPGAApp::btnLoad_Click);
			// 
			// grpFGrabber
			// 
			this->grpFGrabber->Controls->Add(this->btnSave);
			this->grpFGrabber->Controls->Add(this->lblFgSize);
			this->grpFGrabber->Controls->Add(this->txtImgSize);
			this->grpFGrabber->Controls->Add(this->btnStart);
			this->grpFGrabber->Controls->Add(this->lblFrameSec);
			this->grpFGrabber->Controls->Add(this->txtFrameSec);
			this->grpFGrabber->Controls->Add(this->txtImgCharge);
			this->grpFGrabber->Controls->Add(this->btnUpdate);
			this->grpFGrabber->Controls->Add(this->txtHwTimer);
			this->grpFGrabber->Controls->Add(this->lblHwTimer);
			this->grpFGrabber->Controls->Add(this->lblImgCharge);
			this->grpFGrabber->Controls->Add(this->txtfgSize);
			this->grpFGrabber->Controls->Add(this->lblImgSize);
			this->grpFGrabber->Controls->Add(this->txtGreyScale);
			this->grpFGrabber->Controls->Add(this->lblGreyScale);
			this->grpFGrabber->Controls->Add(this->txtSwTimer);
			this->grpFGrabber->Controls->Add(this->lblSwTimer);
			this->grpFGrabber->Controls->Add(this->display);
			this->grpFGrabber->Location = System::Drawing::Point(4, 132);
			this->grpFGrabber->Name = L"grpFGrabber";
			this->grpFGrabber->Size = System::Drawing::Size(415, 282);
			this->grpFGrabber->TabIndex = 41;
			this->grpFGrabber->TabStop = false;
			this->grpFGrabber->Text = L"Frame Grabber";
			this->grpFGrabber->Visible = false;
			// 
			// btnSave
			// 
			this->btnSave->BackColor = System::Drawing::SystemColors::Control;
			this->btnSave->Enabled = false;
			this->btnSave->Location = System::Drawing::Point(341, 210);
			this->btnSave->Name = L"btnSave";
			this->btnSave->Size = System::Drawing::Size(67, 30);
			this->btnSave->TabIndex = 26;
			this->btnSave->Text = L"Save BMP";
			this->btnSave->UseVisualStyleBackColor = false;
			this->btnSave->Click += gcnew System::EventHandler(this, &LoadFPGAApp::btnSave_Click);
			// 
			// lblFgSize
			// 
			this->lblFgSize->Location = System::Drawing::Point(5, 110);
			this->lblFgSize->Name = L"lblFgSize";
			this->lblFgSize->Size = System::Drawing::Size(67, 19);
			this->lblFgSize->TabIndex = 25;
			this->lblFgSize->Text = L"Fg Size";
			this->lblFgSize->TextAlign = System::Drawing::ContentAlignment::BottomCenter;
			// 
			// txtImgSize
			// 
			this->txtImgSize->BackColor = System::Drawing::SystemColors::Control;
			this->txtImgSize->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 9.75F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->txtImgSize->Location = System::Drawing::Point(6, 88);
			this->txtImgSize->MaxLength = 5;
			this->txtImgSize->Name = L"txtImgSize";
			this->txtImgSize->Size = System::Drawing::Size(67, 22);
			this->txtImgSize->TabIndex = 24;
			this->txtImgSize->Text = L"64";
			this->txtImgSize->TextAlign = System::Windows::Forms::HorizontalAlignment::Center;
			this->txtImgSize->Leave += gcnew System::EventHandler(this, &LoadFPGAApp::VerifyUnsignedIntValue);
			// 
			// btnStart
			// 
			this->btnStart->BackColor = System::Drawing::SystemColors::Control;
			this->btnStart->Location = System::Drawing::Point(342, 246);
			this->btnStart->Name = L"btnStart";
			this->btnStart->Size = System::Drawing::Size(67, 30);
			this->btnStart->TabIndex = 23;
			this->btnStart->Text = L"Start";
			this->btnStart->UseVisualStyleBackColor = false;
			this->btnStart->Click += gcnew System::EventHandler(this, &LoadFPGAApp::btnStart_Click);
			// 
			// lblFrameSec
			// 
			this->lblFrameSec->Location = System::Drawing::Point(342, 158);
			this->lblFrameSec->Name = L"lblFrameSec";
			this->lblFrameSec->Size = System::Drawing::Size(67, 19);
			this->lblFrameSec->TabIndex = 12;
			this->lblFrameSec->Text = L"Frame/sec";
			this->lblFrameSec->TextAlign = System::Drawing::ContentAlignment::BottomCenter;
			// 
			// txtFrameSec
			// 
			this->txtFrameSec->BackColor = System::Drawing::SystemColors::Control;
			this->txtFrameSec->BorderStyle = System::Windows::Forms::BorderStyle::FixedSingle;
			this->txtFrameSec->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 9.75F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->txtFrameSec->Location = System::Drawing::Point(342, 178);
			this->txtFrameSec->Name = L"txtFrameSec";
			this->txtFrameSec->Size = System::Drawing::Size(67, 19);
			this->txtFrameSec->TabIndex = 16;
			this->txtFrameSec->Text = L"0";
			this->txtFrameSec->TextAlign = System::Drawing::ContentAlignment::MiddleCenter;
			// 
			// txtImgCharge
			// 
			this->txtImgCharge->BackColor = System::Drawing::SystemColors::Control;
			this->txtImgCharge->BorderStyle = System::Windows::Forms::BorderStyle::FixedSingle;
			this->txtImgCharge->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 9.75F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->txtImgCharge->Location = System::Drawing::Point(342, 139);
			this->txtImgCharge->Name = L"txtImgCharge";
			this->txtImgCharge->Size = System::Drawing::Size(67, 19);
			this->txtImgCharge->TabIndex = 15;
			this->txtImgCharge->Text = L"0";
			this->txtImgCharge->TextAlign = System::Drawing::ContentAlignment::MiddleCenter;
			// 
			// btnUpdate
			// 
			this->btnUpdate->BackColor = System::Drawing::SystemColors::Control;
			this->btnUpdate->Enabled = false;
			this->btnUpdate->Location = System::Drawing::Point(6, 246);
			this->btnUpdate->Name = L"btnUpdate";
			this->btnUpdate->Size = System::Drawing::Size(67, 30);
			this->btnUpdate->TabIndex = 22;
			this->btnUpdate->Text = L"Update";
			this->btnUpdate->UseVisualStyleBackColor = false;
			this->btnUpdate->Click += gcnew System::EventHandler(this, &LoadFPGAApp::btnUpdate_Click);
			// 
			// txtHwTimer
			// 
			this->txtHwTimer->BackColor = System::Drawing::SystemColors::Control;
			this->txtHwTimer->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 9.75F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->txtHwTimer->Location = System::Drawing::Point(6, 216);
			this->txtHwTimer->MaxLength = 5;
			this->txtHwTimer->Name = L"txtHwTimer";
			this->txtHwTimer->Size = System::Drawing::Size(67, 22);
			this->txtHwTimer->TabIndex = 21;
			this->txtHwTimer->Text = L"100";
			this->txtHwTimer->TextAlign = System::Windows::Forms::HorizontalAlignment::Center;
			this->txtHwTimer->Click += gcnew System::EventHandler(this, &LoadFPGAApp::SelectingText);
			this->txtHwTimer->Leave += gcnew System::EventHandler(this, &LoadFPGAApp::VerifyUnsignedIntValue);
			// 
			// lblHwTimer
			// 
			this->lblHwTimer->Location = System::Drawing::Point(5, 196);
			this->lblHwTimer->Name = L"lblHwTimer";
			this->lblHwTimer->Size = System::Drawing::Size(67, 19);
			this->lblHwTimer->TabIndex = 10;
			this->lblHwTimer->Text = L"Hw Timer";
			this->lblHwTimer->TextAlign = System::Drawing::ContentAlignment::BottomCenter;
			// 
			// lblImgCharge
			// 
			this->lblImgCharge->Location = System::Drawing::Point(342, 121);
			this->lblImgCharge->Name = L"lblImgCharge";
			this->lblImgCharge->Size = System::Drawing::Size(67, 19);
			this->lblImgCharge->TabIndex = 8;
			this->lblImgCharge->Text = L"Img Charge";
			this->lblImgCharge->TextAlign = System::Drawing::ContentAlignment::BottomCenter;
			// 
			// txtfgSize
			// 
			this->txtfgSize->BackColor = System::Drawing::SystemColors::Control;
			this->txtfgSize->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 9.75F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->txtfgSize->Location = System::Drawing::Point(5, 129);
			this->txtfgSize->MaxLength = 5;
			this->txtfgSize->Name = L"txtfgSize";
			this->txtfgSize->Size = System::Drawing::Size(67, 22);
			this->txtfgSize->TabIndex = 20;
			this->txtfgSize->Text = L"64";
			this->txtfgSize->TextAlign = System::Windows::Forms::HorizontalAlignment::Center;
			this->txtfgSize->Click += gcnew System::EventHandler(this, &LoadFPGAApp::SelectingText);
			this->txtfgSize->Leave += gcnew System::EventHandler(this, &LoadFPGAApp::VerifyUnsignedIntValue);
			// 
			// lblImgSize
			// 
			this->lblImgSize->Location = System::Drawing::Point(5, 67);
			this->lblImgSize->Name = L"lblImgSize";
			this->lblImgSize->Size = System::Drawing::Size(67, 19);
			this->lblImgSize->TabIndex = 6;
			this->lblImgSize->Text = L"Image Size";
			this->lblImgSize->TextAlign = System::Drawing::ContentAlignment::BottomCenter;
			// 
			// txtGreyScale
			// 
			this->txtGreyScale->BackColor = System::Drawing::SystemColors::Control;
			this->txtGreyScale->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 9.75F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->txtGreyScale->Location = System::Drawing::Point(6, 44);
			this->txtGreyScale->MaxLength = 5;
			this->txtGreyScale->Name = L"txtGreyScale";
			this->txtGreyScale->Size = System::Drawing::Size(67, 22);
			this->txtGreyScale->TabIndex = 19;
			this->txtGreyScale->Text = L"1";
			this->txtGreyScale->TextAlign = System::Windows::Forms::HorizontalAlignment::Center;
			this->txtGreyScale->Click += gcnew System::EventHandler(this, &LoadFPGAApp::SelectingText);
			this->txtGreyScale->Leave += gcnew System::EventHandler(this, &LoadFPGAApp::VerifyUnsignedIntValue);
			// 
			// lblGreyScale
			// 
			this->lblGreyScale->Location = System::Drawing::Point(5, 24);
			this->lblGreyScale->Name = L"lblGreyScale";
			this->lblGreyScale->Size = System::Drawing::Size(67, 19);
			this->lblGreyScale->TabIndex = 4;
			this->lblGreyScale->Text = L"Gray Scale";
			this->lblGreyScale->TextAlign = System::Drawing::ContentAlignment::BottomCenter;
			// 
			// txtSwTimer
			// 
			this->txtSwTimer->BackColor = System::Drawing::SystemColors::Control;
			this->txtSwTimer->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 9.75F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->txtSwTimer->Location = System::Drawing::Point(6, 173);
			this->txtSwTimer->MaxLength = 5;
			this->txtSwTimer->Name = L"txtSwTimer";
			this->txtSwTimer->Size = System::Drawing::Size(67, 22);
			this->txtSwTimer->TabIndex = 18;
			this->txtSwTimer->Text = L"100";
			this->txtSwTimer->TextAlign = System::Windows::Forms::HorizontalAlignment::Center;
			this->txtSwTimer->Click += gcnew System::EventHandler(this, &LoadFPGAApp::SelectingText);
			this->txtSwTimer->Leave += gcnew System::EventHandler(this, &LoadFPGAApp::VerifyUnsignedIntValue);
			// 
			// lblSwTimer
			// 
			this->lblSwTimer->Location = System::Drawing::Point(5, 153);
			this->lblSwTimer->Name = L"lblSwTimer";
			this->lblSwTimer->Size = System::Drawing::Size(67, 19);
			this->lblSwTimer->TabIndex = 2;
			this->lblSwTimer->Text = L"Sw Timer";
			this->lblSwTimer->TextAlign = System::Drawing::ContentAlignment::BottomCenter;
			// 
			// display
			// 
			this->display->BackColor = System::Drawing::SystemColors::Control;
			this->display->BackgroundImageLayout = System::Windows::Forms::ImageLayout::Center;
			this->display->BorderStyle = System::Windows::Forms::BorderStyle::FixedSingle;
			this->display->Location = System::Drawing::Point(79, 18);
			this->display->Name = L"display";
			this->display->Size = System::Drawing::Size(258, 258);
			this->display->SizeMode = System::Windows::Forms::PictureBoxSizeMode::CenterImage;
			this->display->TabIndex = 1;
			this->display->TabStop = false;
			// 
			// grpData
			// 
			this->grpData->Controls->Add(this->lblSendAs);
			this->grpData->Controls->Add(this->cmbSendAs);
			this->grpData->Controls->Add(this->lblReceiveAs);
			this->grpData->Controls->Add(this->cmbReceiveAs);
			this->grpData->Controls->Add(this->chkColumns);
			this->grpData->Controls->Add(this->lblSendBuffer);
			this->grpData->Controls->Add(this->txtDataToSend);
			this->grpData->Controls->Add(this->chkExtend);
			this->grpData->Controls->Add(this->txtDataToReceive);
			this->grpData->Controls->Add(this->lblReadBuffer);
			this->grpData->Controls->Add(this->btnReceive);
			this->grpData->Controls->Add(this->btnSend);
			this->grpData->Controls->Add(this->lblBytesToSend);
			this->grpData->Location = System::Drawing::Point(4, 132);
			this->grpData->Name = L"grpData";
			this->grpData->Size = System::Drawing::Size(415, 282);
			this->grpData->TabIndex = 42;
			this->grpData->TabStop = false;
			this->grpData->Text = L"Data";
			// 
			// lblSendAs
			// 
			this->lblSendAs->AutoSize = true;
			this->lblSendAs->Location = System::Drawing::Point(97, 22);
			this->lblSendAs->Name = L"lblSendAs";
			this->lblSendAs->Size = System::Drawing::Size(19, 13);
			this->lblSendAs->TabIndex = 31;
			this->lblSendAs->Text = L"As";
			// 
			// cmbSendAs
			// 
			this->cmbSendAs->BackColor = System::Drawing::SystemColors::Control;
			this->cmbSendAs->DropDownStyle = System::Windows::Forms::ComboBoxStyle::DropDownList;
			this->cmbSendAs->FormattingEnabled = true;
			this->cmbSendAs->Items->AddRange(gcnew cli::array< System::Object^  >(2) {L"Bytes", L"Text"});
			this->cmbSendAs->Location = System::Drawing::Point(122, 16);
			this->cmbSendAs->Name = L"cmbSendAs";
			this->cmbSendAs->Size = System::Drawing::Size(106, 21);
			this->cmbSendAs->TabIndex = 30;
			this->cmbSendAs->SelectedIndexChanged += gcnew System::EventHandler(this, &LoadFPGAApp::cmbSendAs_SelectedIndexChanged);
			// 
			// lblReceiveAs
			// 
			this->lblReceiveAs->AutoSize = true;
			this->lblReceiveAs->Location = System::Drawing::Point(97, 157);
			this->lblReceiveAs->Name = L"lblReceiveAs";
			this->lblReceiveAs->Size = System::Drawing::Size(19, 13);
			this->lblReceiveAs->TabIndex = 29;
			this->lblReceiveAs->Text = L"As";
			// 
			// cmbReceiveAs
			// 
			this->cmbReceiveAs->BackColor = System::Drawing::SystemColors::Control;
			this->cmbReceiveAs->DropDownStyle = System::Windows::Forms::ComboBoxStyle::DropDownList;
			this->cmbReceiveAs->FormattingEnabled = true;
			this->cmbReceiveAs->Items->AddRange(gcnew cli::array< System::Object^  >(3) {L"Bytes (unsigned)", L"Bytes (signed)", L"Text"});
			this->cmbReceiveAs->Location = System::Drawing::Point(122, 149);
			this->cmbReceiveAs->Name = L"cmbReceiveAs";
			this->cmbReceiveAs->Size = System::Drawing::Size(106, 21);
			this->cmbReceiveAs->TabIndex = 28;
			// 
			// chkColumns
			// 
			this->chkColumns->AutoSize = true;
			this->chkColumns->Checked = true;
			this->chkColumns->CheckState = System::Windows::Forms::CheckState::Checked;
			this->chkColumns->Location = System::Drawing::Point(239, 153);
			this->chkColumns->Name = L"chkColumns";
			this->chkColumns->Size = System::Drawing::Size(77, 17);
			this->chkColumns->TabIndex = 26;
			this->chkColumns->Text = L"In columns";
			this->chkColumns->UseVisualStyleBackColor = true;
			// 
			// lblSendBuffer
			// 
			this->lblSendBuffer->Font = (gcnew System::Drawing::Font(L"Arial", 7));
			this->lblSendBuffer->Location = System::Drawing::Point(335, 30);
			this->lblSendBuffer->Name = L"lblSendBuffer";
			this->lblSendBuffer->RightToLeft = System::Windows::Forms::RightToLeft::No;
			this->lblSendBuffer->Size = System::Drawing::Size(79, 11);
			this->lblSendBuffer->TabIndex = 24;
			this->lblSendBuffer->Text = L"Sending buffer";
			this->lblSendBuffer->TextAlign = System::Drawing::ContentAlignment::MiddleCenter;
			// 
			// txtDataToSend
			// 
			this->txtDataToSend->BackColor = System::Drawing::SystemColors::Control;
			this->txtDataToSend->Location = System::Drawing::Point(6, 41);
			this->txtDataToSend->Multiline = true;
			this->txtDataToSend->Name = L"txtDataToSend";
			this->txtDataToSend->ScrollBars = System::Windows::Forms::ScrollBars::Vertical;
			this->txtDataToSend->Size = System::Drawing::Size(406, 100);
			this->txtDataToSend->TabIndex = 13;
			this->txtDataToSend->TextChanged += gcnew System::EventHandler(this, &LoadFPGAApp::txtDataToSend_TextChanged);
			this->txtDataToSend->Click += gcnew System::EventHandler(this, &LoadFPGAApp::SelectingText);
			this->txtDataToSend->KeyPress += gcnew System::Windows::Forms::KeyPressEventHandler(this, &LoadFPGAApp::txtDataToSend_KeyPress);
			// 
			// chkExtend
			// 
			this->chkExtend->AutoSize = true;
			this->chkExtend->Checked = true;
			this->chkExtend->CheckState = System::Windows::Forms::CheckState::Checked;
			this->chkExtend->Location = System::Drawing::Point(239, 18);
			this->chkExtend->Name = L"chkExtend";
			this->chkExtend->Size = System::Drawing::Size(59, 17);
			this->chkExtend->TabIndex = 12;
			this->chkExtend->Text = L"Extend";
			this->chkExtend->UseVisualStyleBackColor = true;
			// 
			// txtDataToReceive
			// 
			this->txtDataToReceive->BackColor = System::Drawing::SystemColors::Control;
			this->txtDataToReceive->Location = System::Drawing::Point(8, 178);
			this->txtDataToReceive->Multiline = true;
			this->txtDataToReceive->Name = L"txtDataToReceive";
			this->txtDataToReceive->ReadOnly = true;
			this->txtDataToReceive->ScrollBars = System::Windows::Forms::ScrollBars::Vertical;
			this->txtDataToReceive->Size = System::Drawing::Size(404, 100);
			this->txtDataToReceive->TabIndex = 23;
			this->txtDataToReceive->Click += gcnew System::EventHandler(this, &LoadFPGAApp::SelectingText);
			// 
			// lblReadBuffer
			// 
			this->lblReadBuffer->Font = (gcnew System::Drawing::Font(L"Arial", 7));
			this->lblReadBuffer->Location = System::Drawing::Point(326, 162);
			this->lblReadBuffer->Name = L"lblReadBuffer";
			this->lblReadBuffer->RightToLeft = System::Windows::Forms::RightToLeft::No;
			this->lblReadBuffer->Size = System::Drawing::Size(87, 22);
			this->lblReadBuffer->TabIndex = 25;
			this->lblReadBuffer->Text = L"Reception buffer";
			this->lblReadBuffer->TextAlign = System::Drawing::ContentAlignment::MiddleCenter;
			// 
			// btnReceive
			// 
			this->btnReceive->Location = System::Drawing::Point(13, 149);
			this->btnReceive->Name = L"btnReceive";
			this->btnReceive->Size = System::Drawing::Size(80, 23);
			this->btnReceive->TabIndex = 17;
			this->btnReceive->Text = L"Download";
			this->btnReceive->UseVisualStyleBackColor = true;
			this->btnReceive->Click += gcnew System::EventHandler(this, &LoadFPGAApp::btnReceive_Click);
			// 
			// btnSend
			// 
			this->btnSend->Location = System::Drawing::Point(16, 14);
			this->btnSend->Name = L"btnSend";
			this->btnSend->Size = System::Drawing::Size(77, 23);
			this->btnSend->TabIndex = 14;
			this->btnSend->Text = L"Upload";
			this->btnSend->UseVisualStyleBackColor = true;
			this->btnSend->Click += gcnew System::EventHandler(this, &LoadFPGAApp::btnSend_Click);
			// 
			// lblBytesToSend
			// 
			this->lblBytesToSend->Location = System::Drawing::Point(313, 15);
			this->lblBytesToSend->Name = L"lblBytesToSend";
			this->lblBytesToSend->Size = System::Drawing::Size(95, 18);
			this->lblBytesToSend->TabIndex = 14;
			this->lblBytesToSend->Text = L"- - -";
			this->lblBytesToSend->TextAlign = System::Drawing::ContentAlignment::MiddleLeft;
			// 
			// openFileDialog1
			// 
			this->openFileDialog1->FileName = L"file.bin";
			// 
			// cmbDataLogger
			// 
			this->cmbDataLogger->BackColor = System::Drawing::SystemColors::Control;
			this->cmbDataLogger->DropDownStyle = System::Windows::Forms::ComboBoxStyle::DropDownList;
			this->cmbDataLogger->FormattingEnabled = true;
			this->cmbDataLogger->Items->AddRange(gcnew cli::array< System::Object^  >(5) {L"Capture", L"Erase", L"Play", L"Stop", L"WriteTest"});
			this->cmbDataLogger->Location = System::Drawing::Point(9, 65);
			this->cmbDataLogger->Name = L"cmbDataLogger";
			this->cmbDataLogger->Size = System::Drawing::Size(75, 21);
			this->cmbDataLogger->TabIndex = 5;
			this->cmbDataLogger->SelectedIndexChanged += gcnew System::EventHandler(this, &LoadFPGAApp::cmbDataLogger_SelectedIndexChanged);
			// 
			// cmbDevName
			// 
			this->cmbDevName->BackColor = System::Drawing::SystemColors::Control;
			this->cmbDevName->DropDownStyle = System::Windows::Forms::ComboBoxStyle::DropDownList;
			this->cmbDevName->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 8.25F, System::Drawing::FontStyle::Bold, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->cmbDevName->FormattingEnabled = true;
			this->cmbDevName->Location = System::Drawing::Point(9, 21);
			this->cmbDevName->Name = L"cmbDevName";
			this->cmbDevName->Size = System::Drawing::Size(107, 21);
			this->cmbDevName->Sorted = true;
			this->cmbDevName->TabIndex = 0;
			this->cmbDevName->SelectedIndexChanged += gcnew System::EventHandler(this, &LoadFPGAApp::cmbDevName_SelectedIndexChanged);
			this->cmbDevName->KeyDown += gcnew System::Windows::Forms::KeyEventHandler(this, &LoadFPGAApp::cmbDevName_KeyDown);
			this->cmbDevName->DropDown += gcnew System::EventHandler(this, &LoadFPGAApp::cmbDevName_DropDown);
			// 
			// cmbDataLogger1
			// 
			this->cmbDataLogger1->BackColor = System::Drawing::SystemColors::Control;
			this->cmbDataLogger1->DropDownStyle = System::Windows::Forms::ComboBoxStyle::DropDownList;
			this->cmbDataLogger1->FormattingEnabled = true;
			this->cmbDataLogger1->Items->AddRange(gcnew cli::array< System::Object^  >(4) {L"(nothing)", L"Terminal", L"Sniffer", L"Bypass"});
			this->cmbDataLogger1->Location = System::Drawing::Point(84, 65);
			this->cmbDataLogger1->Name = L"cmbDataLogger1";
			this->cmbDataLogger1->Size = System::Drawing::Size(75, 21);
			this->cmbDataLogger1->TabIndex = 48;
			// 
			// cmbDataLogger2
			// 
			this->cmbDataLogger2->BackColor = System::Drawing::SystemColors::Control;
			this->cmbDataLogger2->DropDownStyle = System::Windows::Forms::ComboBoxStyle::DropDownList;
			this->cmbDataLogger2->FormattingEnabled = true;
			this->cmbDataLogger2->Items->AddRange(gcnew cli::array< System::Object^  >(3) {L"(nothing)", L"Blocked", L"Unblocked"});
			this->cmbDataLogger2->Location = System::Drawing::Point(159, 65);
			this->cmbDataLogger2->Name = L"cmbDataLogger2";
			this->cmbDataLogger2->Size = System::Drawing::Size(75, 21);
			this->cmbDataLogger2->TabIndex = 49;
			// 
			// LoadFPGAApp
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->BackColor = System::Drawing::SystemColors::ControlLight;
			this->ClientSize = System::Drawing::Size(428, 445);
			this->Controls->Add(this->cmbDataLogger2);
			this->Controls->Add(this->cmbDataLogger1);
			this->Controls->Add(this->btnLoad);
			this->Controls->Add(this->cmbDevName);
			this->Controls->Add(this->cmbDataLogger);
			this->Controls->Add(this->lblDevType);
			this->Controls->Add(this->btnAlias);
			this->Controls->Add(this->cmbDevType);
			this->Controls->Add(this->btnSendCommand);
			this->Controls->Add(this->btnDownFile);
			this->Controls->Add(this->lblSize);
			this->Controls->Add(this->txtLong);
			this->Controls->Add(this->lblCmd);
			this->Controls->Add(this->txtCmd);
			this->Controls->Add(this->lblStart);
			this->Controls->Add(this->txtStart);
			this->Controls->Add(this->btnUpFile);
			this->Controls->Add(this->lblDevName);
			this->Controls->Add(this->Devstatus);
			this->Controls->Add(this->grpData);
			this->Controls->Add(this->grpFGrabber);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedDialog;
			this->MaximizeBox = false;
			this->MinimizeBox = false;
			this->Name = L"LoadFPGAApp";
			this->StartPosition = System::Windows::Forms::FormStartPosition::CenterScreen;
			this->Devstatus->ResumeLayout(false);
			this->Devstatus->PerformLayout();
			this->grpFGrabber->ResumeLayout(false);
			this->grpFGrabber->PerformLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->display))->EndInit();
			this->grpData->ResumeLayout(false);
			this->grpData->PerformLayout();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion

// ***********************************************************************
// ***************  FUNCIONES PARA LA GESTIÓN DE DISPOSITIVOS ************
// ***********************************************************************

// Abrir el dispositivo.
public: HANDLE OpenDevice(String ^Str,bool Silence)
	{	String ^ DeviceNameStr;
		LPCWSTR DeviceName;
		HANDLE Hnd;
		
		DeviceNameStr = "\\\\.\\" + Str;
		//DeviceNameStr = "D:\\prueba.bin";
		//Las APIs de .NET no recoge todas las funciones de las API Win32 (en cierto grado es lógico al trabajar como una máquina virtual) como
		//por ejemplo cambiar resolución. De igual forma, parece no haber en la API del .NET Framework una función equivalente a CreateFile 
		//(que se usa para abrir dispositivos) pues la función System::IO::Create de .NET parece funcionar únicamente para la apertura de ficheros.
		// Así pues usaremos CreateFile de la API de Win32.
		// Para emplear convertir String manejado en tipos no manejados, Visual Studio 2008 incorpora marshal_context y marshal_as...
		// visita: http://msdn.microsoft.com/en-us/library/aa719104.aspx#docum_topic3 (sobre todo la tabla).
		// visita: http://msdn.microsoft.com/en-us/library/bb384865.aspx
		marshal_context ^ context = gcnew marshal_context();
		DeviceName = context->marshal_as<LPCWSTR>(DeviceNameStr); // Convertir el String ^ manejado a LPCWSTR
		Hnd = CreateFile(DeviceName, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL,NULL);
		delete context; // DeviceName permanecerá válido sólo mientras permanece el contexto.

		if (Hnd == INVALID_HANDLE_VALUE && !Silence)
			MessageBox::Show("Device Not found", "Error",MessageBoxButtons::OK,MessageBoxIcon::Error);
		return Hnd;
	}

// Enviar un comando.
public: void SendCommand(HANDLE Hnd, array<unsigned char>^ cmd)
	{	unsigned long nWrite;
		pin_ptr<unsigned char> MyPinPtr; // Pin Pointer para acceder a la clase array desde un tipo no manejado.
		unsigned char *cmdWin32;
		//Para usar el objeto array<unsigned char>^ como un unsigned char * hacemos empleamos un Pin Pointer
		MyPinPtr = &cmd[0];  // Asignamos el pin pointer a la dirección del primer elemento.
		cmdWin32 = MyPinPtr; // Obtenemos la dirección que apunta al primer elemento.
		WriteFile(Hnd, cmdWin32, (unsigned long)64, &nWrite, NULL); //Envío del comando.
	}

// Escribir en el dispositivo
public: void WriteDevice(HANDLE Hnd, array<unsigned char>^ data)
	{	const long sizePacket = 1024; // De cuanto en cuanto vamos a escribir (Debe ser siempre múltiplo de 64)
		unsigned long nWrite;
		pin_ptr<unsigned char> MyPinPtr; // Pin Pointer para acceder a la clase array desde un tipo no manejado.
		unsigned char *bufferWin32;
		
		long leido = 0;
		double tmpdob;
		StatusBar->Value = 0; StatusBar->ProgressBar->Refresh();
		MyPinPtr = &data[0];
		bufferWin32 = MyPinPtr;
		for (int i=0; i<data->Length ;i = i + sizePacket)
		{	if ((data->Length-i)> sizePacket)	// Si podemos enviar un paquete completo.
				WriteFile(Hnd, bufferWin32+i, (unsigned long) sizePacket, &nWrite, NULL);
			else								// Cuando sólo queda por enviar el resto.
			{	// El envío hay que ampliarlo hasta el siguiente múltiplo de 64.
				tmpdob = data->Length-i; tmpdob = System::Math::Ceiling(tmpdob/64)* 64;
				WriteFile(Hnd, bufferWin32+i, (unsigned long) tmpdob, &nWrite, NULL);
			}
			leido = leido + nWrite;
			StatusBar->Value = (i*100)/data->Length; StatusBar->ProgressBar->Refresh();
		}
		StatusBar->Value = 100; StatusBar->ProgressBar->Refresh();
		tmpdob = data->Length; tmpdob = System::Math::Ceiling(tmpdob/64)* 64;
		if (leido!=tmpdob)
			MessageBox::Show(String::Concat("Number of sent and received bytes missmatch. Sent: ",leido.ToString(), ", Received: ",tmpdob.ToString()), "Test",MessageBoxButtons::OK,MessageBoxIcon::Error);
	}

// Leer del dispositivo
public: array<unsigned char>^ ReadDevice(HANDLE Hnd, long bytesNum)
	{	pin_ptr<unsigned char> MyPinPtr; // Pin Pointer para acceder a la clase array desde un tipo no manejado.
		unsigned char *bufferWin32;
		long sizePacket = 1024;
		unsigned long nRead;
		array<unsigned char>^ OutBuffer;

		// Solo para Test (el programa resto del programa debe impedir que no sea múltiplo de 64.
		if ((bytesNum%64)!=0)
			MessageBox::Show("Number of bytes to read must be multiple of 64", "Testing",MessageBoxButtons::OK,MessageBoxIcon::Error);

		Array::Resize(OutBuffer, bytesNum); // Redimensionamos para almacenar los datos a devolver.
		MyPinPtr = &OutBuffer[0];
		bufferWin32 = MyPinPtr;
		StatusBar->Value = 0; StatusBar->ProgressBar->Refresh();
		for (long i=0; i<bytesNum;i+=sizePacket)
		{	if ((bytesNum-i)> sizePacket)	// Si podemos recibir un paquete completo.
				ReadFile(Hnd, bufferWin32+i, (unsigned long) sizePacket, &nRead, NULL);
			else								// Cuando sólo queda por recibir el resto.
				ReadFile(Hnd, bufferWin32+i, (unsigned long) (bytesNum-i), &nRead, NULL);
			StatusBar->Value = (i*100)/bytesNum; StatusBar->ProgressBar->Refresh();
		}
		StatusBar->Value = 100; StatusBar->ProgressBar->Refresh();
		return OutBuffer;
	}

// ************************************************************************
// *********************     EVENTOS     **********************************
// ************************************************************************

public: event System::EventHandler ^ DevNameUpdated; // Creo un evento para avisar a MultiLoadFPGA que actualice el Nombre de la Pestaña.
// Combo Lista de Nombres de Dispositivos (

private: System::Void cmbDevName_SelectedIndexChanged(System::Object^  sender, System::EventArgs^  e)
	{	DevName = (String ^) cmbDevName->SelectedItem ;
		DevNameUpdated(this, System::EventArgs::Empty);	// Aquí es donde va a levantarse el evento que he definido.
	}

private: System::Void cmbDevName_DropDown(System::Object^  sender, System::EventArgs^  e)
	{	UpdateDevicesList();
	}
private: System::Void cmbDevName_KeyDown(System::Object^  sender, System::Windows::Forms::KeyEventArgs^  e)
	{	UpdateDevicesList();
	}

// Botón Load Firmware
private: System::Void btnLoad_Click(System::Object^  sender, System::EventArgs^  e)
	{	String ^FileName = "";
		// Elección del Firmware a cargar
		if (Config->AutomatButton)
		{	if (cmbDevType->SelectedItem == "Sequencer")
				FileName = Config->Sequencer;
			else if (cmbDevType->SelectedItem == "Mapper")
				FileName = Config->Mapper;
			else if (cmbDevType->SelectedItem == "Framegrabber")
				FileName = Config->FrameGrabber;
			else if (cmbDevType->SelectedItem == "Datalogger")
				FileName = Config->DataLogger;
			if (FileName != "" && !FileName->Contains("\\"))
				FileName = String::Concat(Config->AppDirectory,"\\",FileName);
		}
		if (!File::Exists(FileName))
		{	if (FileName->Length>0)
				MessageBox::Show(String::Concat("'",FileName,"' not found."),"Error",MessageBoxButtons::OK,MessageBoxIcon::Error);
			openFileDialog1->Filter = "Binary files|*.bin|All files|*.*";
			if (openFileDialog1->ShowDialog() != System::Windows::Forms::DialogResult::OK)
				return;
			FileName = openFileDialog1->FileName;
			if (cmbDevType->SelectedItem == "Sequencer")
				Config->Sequencer = FileName;
			else if (cmbDevType->SelectedItem == "Mapper")
				Config->Mapper = FileName;
			else if (cmbDevType->SelectedItem == "Framegrabber")
				Config->FrameGrabber = FileName;
			else if (cmbDevType->SelectedItem == "Datalogger")
				Config->DataLogger = FileName;
			Config->SaveConfig("setup.ini");
		}
		LoadFirmware(FileName);
	}
		
private: bool LoadFirmware(String ^FileName)
	{	__int64 longitud; //unsigned long 
		HANDLE Hnd;
		array<unsigned char>^ cmd;
		array<unsigned char>^ data;

		Hnd = OpenDevice(DevName,false);
		if (Hnd == INVALID_HANDLE_VALUE)
			return false;
		if (!File::Exists(FileName))
		{	MessageBox::Show(String::Concat("'",FileName,"' not found."),"Error",MessageBoxButtons::OK,MessageBoxIcon::Error);
			return false;
		}
		// Cargando los datos del fichero binario.
		FileStream ^stream = gcnew FileStream(FileName,FileMode::Open,FileAccess::Read);
		BinaryReader ^reader = gcnew BinaryReader(stream);
		Array::Resize(data,(unsigned int) stream->Length);
		reader->Read(data,0,(unsigned int) stream->Length);
		longitud = stream->Length;
		reader->Close();
		stream->Close();

		// Envío del comando de carga del firmware.
		Array::Resize(cmd,64);
		cmd[0]='A'; cmd[1]='T'; cmd[2]='C'; cmd[3]= 0;
		for(int i=4;i<8;i++)
			cmd[i]=(longitud>>(8*(i-4)))&0xff;
		SendCommand(Hnd, cmd);

		// Envío del fichero binario
		WriteDevice(Hnd, data);

		// Cierre del dispositivo
		CloseHandle(Hnd);
		this->Text = String::Concat(L"External LoadFPGA - ", FileName->Substring(FileName->LastIndexOf("\\")+1));
		lblStatus->Text = FileName->Substring(FileName->LastIndexOf("\\")+1);
		return true;
	}

// Botón UploadFile
private: System::Void btnUpFile_Click(System::Object^  sender, System::EventArgs^  e)
	{	HANDLE Hnd;
		unsigned int inicio;
		 __int64 longitud;
		array<unsigned char>^ cmd;
		array<unsigned char>^ data;
		// Apertura del dispositivo.
		Hnd = OpenDevice(DevName,false)  ;
		if (Hnd == INVALID_HANDLE_VALUE) return;

		// Elección del Fichero a subir
		openFileDialog1->Filter = "Binary files|*.bin|All files|*.*";
		if (openFileDialog1->ShowDialog ()!= System::Windows::Forms::DialogResult::OK)
		{	CloseHandle(Hnd);
			return;
		}
		// Cargando los datos del fichero binario.
		FileStream ^stream = gcnew FileStream(openFileDialog1->FileName,FileMode::Open,FileAccess::Read);
		BinaryReader ^reader = gcnew BinaryReader(stream);
		Array::Resize(data,(unsigned int) stream->Length);
		reader->Read(data,0,(unsigned int) stream->Length);
		longitud = stream->Length;
		reader->Close();
		stream->Close();

		// Envío del comando para subir el fichero.
		Array::Resize(cmd,64);
        cmd[0]='A'; cmd[1]='T'; cmd[2]='C'; cmd[3]= 1;   // Comando 1: Grabar RAM
        for(int i=4;i<8;i++)
			cmd[i]=(longitud>>(8*(i-4)))&0xff;
		inicio = Convert::ToInt32(txtStart->Text->ToString());
        if (cmbDevType->SelectedItem=="Mapper") // Bytes que va a recibir la FPGA
        {   for(int i=8;i<12;i++)
                cmd[i]=(inicio>>(8*(i-8)))&0xff;
        }
        else if (cmbDevType->SelectedItem=="Datalogger")
        {  cmd[8]=4; cmd[9]=3; // Comando de habilitación de escritura y establec. de la direccion
           for(int i=10;i<14;i++)
                cmd[i]=(inicio>>(8*(i-8)))&0xff;
        }
		SendCommand(Hnd, cmd);

		// Envío del fichero binario
		WriteDevice(Hnd, data);

		// Cierre del dispositivo
		CloseHandle(fgHnd);
	}
 // Botón DownloadFile
private: System::Void btnDownFile_Click(System::Object^  sender, System::EventArgs^  e)
	{	HANDLE Hnd;
		unsigned int inicio;
		__int64 longitud;
		array<unsigned char>^ cmd;
		array<unsigned char>^ data;

		longitud = Convert::ToInt32(txtLong->Text->ToString());
		if ((longitud%64)!=0)
		{	MessageBox::Show("Number of bytes to read must be multiple of 64", "Error",MessageBoxButtons::OK,MessageBoxIcon::Error);
			return;
		}

		// Elección del fichero donde guardar los datos
		saveFileDialog1->Filter = "Binary files|*.bin|All files|*.*";
		if (saveFileDialog1->ShowDialog() != System::Windows::Forms::DialogResult::OK) return;

		// Apertura del dispositivo.
		Hnd = OpenDevice(DevName,false)  ;
		if (Hnd == INVALID_HANDLE_VALUE) return;

		// Envío del comando para subir el fichero.
		Array::Resize(cmd,64);
        cmd[0]='A'; cmd[1]='T'; cmd[2]='C'; cmd[3]= 2;   // Comando 2: Lectura de la RAM
        for(int i=4;i<8;i++)
			cmd[i]=(longitud>>(8*(i-4)))&0xff; // Nº de bytes que se van a leer
		inicio = Convert::ToInt32(txtStart->Text->ToString());
		if (cmbDevType->SelectedItem=="Mapper") // Comandos que recibirá la FPGA.
        {   for(int i=8;i<12;i++)
                cmd[i]=(inicio>>(8*(i-8)))&0xff;
        }
        else if (cmbDevType->SelectedItem=="Datalogger")
        {  cmd[8]=1; cmd[9]=3; // Comando de configuración y establec. de la direcc
           for(int i=10;i<14;i++)
                cmd[i]=(inicio>>(8*(i-8)))&0xff;
        }
		SendCommand(Hnd, cmd);

		// Lectura del dispositivo
		data = ReadDevice(Hnd, (long) longitud);

		// Cierre del dispositivo.
		CloseHandle(Hnd);

		// Salva de los datos en el fichero.
		FileStream ^stream = gcnew FileStream(saveFileDialog1->FileName, FileMode::Create, FileAccess::Write);
		BinaryWriter ^ writer = gcnew BinaryWriter(stream);
		writer->Write(data);
		writer->Close();
		stream->Close();
	}

// Botón ChangeAlias
private: System::Void btnAlias_Click(System::Object^  sender, System::EventArgs^  e)
	{	HANDLE Hnd;
	 	unsigned char longitud;	//unsigned long 
		array<unsigned char>^ cmd;
		String ^NewAlias;

		// Apertura del dispositivo.
		Hnd = OpenDevice(DevName,false);
		if (Hnd == INVALID_HANDLE_VALUE) return;

		// Crear e invocar la ventana de cambio de Alias.
		AliasForm ^MyAliasForm = gcnew AliasForm(DevName);
		if (MyAliasForm->ShowDialog() != System::Windows::Forms::DialogResult::OK)
		{	CloseHandle(Hnd);
			return;
		}
		// Envío del comando de Cambio de Alias.
		Array::Resize(cmd,64); // Ya está inicializado a 0.
		NewAlias = MyAliasForm->DevName;
		cmd[0]='A'; cmd[1]='T'; cmd[2]='C'; cmd[3]= 3;   // comando 3 escribir descriptor
		longitud = NewAlias->Length;
		for(int i=4;i<8;i++)
			cmd[i]=(longitud>>(8*(i-4)))&0xff;
		cmd[8]= 2*longitud+2;
		cmd[9]= 3; //Desc String
		for (int i=0;i<longitud;i++)
		{	cmd[10+2*i] = (unsigned char) (NewAlias[i]); //convertir wchar_t a unsigned char (si hay caracteres extendidos habrá problemas.
			cmd[11+2*i] = 0;
		}
		SendCommand(Hnd, cmd);

		cmbDevName->Items[cmbDevName->SelectedIndex] = NewAlias;
		MessageBox::Show("Unplug & plug again to take changes","Information",MessageBoxButtons::OK,MessageBoxIcon::Information);
		// Cierre del dispositivo
		CloseHandle(Hnd);
	}

 // Botón SendCommand
private: System::Void btnSendCommand_Click(System::Object^  sender, System::EventArgs^  e)
	{	HANDLE Hnd;
		array<unsigned char>^ cmd;
		array<unsigned char>^ FPGAcmd;

		// Envío de comandos para el dataloger a través de un combobox específico.
		if (cmbDevType->SelectedItem=="Datalogger")
		{	Array::Resize(FPGAcmd,16);
			int i=1;
			if (cmbDataLogger->SelectedItem == "Capture")
				FPGAcmd[0] = 2;
			else if (cmbDataLogger->SelectedItem == "Erase")
				FPGAcmd[0] = 6;
			else if (cmbDataLogger->SelectedItem == "Play")
				FPGAcmd[0] = 3;
			else if (cmbDataLogger->SelectedItem == "WriteTest")
				FPGAcmd[0] = 5;
			else		// Stop;
				FPGAcmd[0] = 1;

			if (cmbDataLogger1->SelectedItem == "Terminal")
			{	FPGAcmd[i++] = 1;
				FPGAcmd[i++] = 1;
			}
			else if (cmbDataLogger1->SelectedItem == "Sniffer")
			{	FPGAcmd[i++] = 1;
				FPGAcmd[i++] = 2;
			}
			else if (cmbDataLogger1->SelectedItem == "Bypass")
			{	FPGAcmd[i++] = 1;
				FPGAcmd[i++] = 3;
			}

			if (cmbDataLogger2->SelectedItem == "Blocked")
			{	FPGAcmd[i++] = 2;
				FPGAcmd[i++] = 1;
			}
			else if (cmbDataLogger2->SelectedItem == "Unblocked")
			{	FPGAcmd[i++] = 2;
				FPGAcmd[i++] = 0;
			}
		}
		else	// Envío del comando indicado en txtCmd.
		{	// Verificar errores
			if (txtCmd->Text->Length == 0)
			{	MessageBox::Show("There is not any command to send.", "Error",MessageBoxButtons::OK,MessageBoxIcon::Error);
				return;
			}
			txtCmd->Text = TakeBytes(txtCmd->Text,FPGAcmd);
			if (txtCmd->Text->Contains("?"))
			{	txtCmd->ForeColor = System::Drawing::Color::Red;
				MessageBox::Show("Command has invalid values", "Error",MessageBoxButtons::OK,MessageBoxIcon::Error);
				return;
			}
			else if (FPGAcmd->Length>64)
			{	if (MessageBox::Show("Command too long, then will be trucated. ¿Continue?","Warning",MessageBoxButtons::YesNo,MessageBoxIcon::Warning) == System::Windows::Forms::DialogResult::No)
					return;
			}
		}

		// Apertura del dispositivo.
		Hnd = OpenDevice(DevName,false)  ;
		if (Hnd == INVALID_HANDLE_VALUE) return;

		// Envío el comando.
		Array::Resize(FPGAcmd,16);			// Array de 64 relleno de 0s.
		Array::Resize(cmd,64);				// Array de 64 relleno de 0s.
		cmd[0]='A'; cmd[1]='T'; cmd[2]='C'; cmd[3]= 2;	// Preparando la cabecera del comando
		for (int i = 0; i < 16; i++)		// Desde el cmd[8] al cmd[8+16] los recibe la FPGA.
			cmd[i+8] = FPGAcmd[i];
		SendCommand(Hnd, cmd);

		// Cierre del dispositivo
		CloseHandle(Hnd);
	}

 // Botón de enviar los datos del buffer.
private: System::Void btnSend_Click(System::Object^  sender, System::EventArgs^  e)
	{	HANDLE Hnd;
		unsigned int inicio;
		unsigned int longitud;
		double tmpdob;
		array<unsigned char>^ cmd;
		array<unsigned char>^ data;

		// Verificacion de que no está vacío.
		if (txtDataToSend->Text->Length == 0)
		{	MessageBox::Show("Buffer is empty.", "Error",MessageBoxButtons::OK,MessageBoxIcon::Error);
			return;
		} 
		// Interpretación de los datos
		if (cmbSendAs->SelectedItem == "Text")		// Como texto
		{	longitud = Convert::ToInt32(txtDataToSend->Text->Length);
			Array::Resize(data,(unsigned int) longitud);
			// Conversión de String ^ ----> array<wchar_t> ^ ----> array<unsigned char> ^
			data = Array::ConvertAll(txtDataToSend->Text->ToCharArray(), gcnew Converter<wchar_t,unsigned char>(Convert::ToByte));
		}
		else		
		{	if (cmbSendAs->SelectedItem =="Events(ns)") // Interpreta la cadena como secuencia de byte o eventos
				txtDataToSend->Text = TakeDataLoggerEvents(txtDataToSend->Text, data);	//Se hace así pues los objetos String no pueden pasarse por referencia.
			else											   // Interpreta la cadena como secuencia de TimStamp más Evento
				txtDataToSend->Text = TakeBytes(txtDataToSend->Text, data);	//Se hace así pues los objetos String no pueden pasarse por referencia.
			if (txtDataToSend->Text->Contains("?"))			//Si TakeBytes o TakeDataloggerEvents devuelve Errores.
			{	txtDataToSend->ForeColor = System::Drawing::Color::Red; 
				MessageBox::Show("Buffer has invalid values", "Error",MessageBoxButtons::OK,MessageBoxIcon::Error);
				return;
			}
			longitud = data->Length;
		}
		// Verificaciones sobre la longitud del paquete.
		if (longitud%64!=0)
		{	if (!chkExtend->Checked && cmbSendAs->SelectedItem!= "Events(ns)")	// Si no se admite longitudes no múltiplos de 64.
			{	MessageBox::Show("Number of bytes to read must be multiple of 64", "Error", MessageBoxButtons::OK, MessageBoxIcon::Error);
				return;
			}
			else	// Extensión de la longitud
			{	tmpdob = (double) longitud;
				longitud = (unsigned int) System::Math::Ceiling(tmpdob/64)* 64; // Nuevo longitud múltiplo de 64
				Array::Resize(data,longitud);	// Padding del buffer con 0s la nueva longitud.
			}
		}

		// Apertura del dispositivo.
		Hnd = OpenDevice(DevName,false);
		if (Hnd == INVALID_HANDLE_VALUE) return;

		// Envío del comando de escritura en la RAM.
		Array::Resize(cmd,64);
        cmd[0]='A'; cmd[1]='T'; cmd[2]='C'; cmd[3]= 1;   // Comando 1: Grabar RAM
        for(int i=4;i<8;i++)
			cmd[i]=(longitud>>(8*(i-4)))&0xff;
		inicio = Convert::ToInt32(txtStart->Text->ToString());
        if (cmbDevType->SelectedItem=="Mapper")
        {   for(int i=8;i<12;i++)
                cmd[i]=(inicio>>(8*(i-8)))&0xff;
        }
        else if (cmbDevType->SelectedItem=="Datalogger")
        {  cmd[8]=4; cmd[9]=3; // Comando de habilitación de escritura y de establec. de la direcc.
           for(int i=10;i<14;i++)
                cmd[i]=(inicio>>(8*(i-8)))&0xff;
		}
		SendCommand(Hnd, cmd);
		//Envío de los datos.
		WriteDevice(Hnd, data);
		// Cierre del dispositivo
		CloseHandle(Hnd);
	}

 // Botón de recibir datos en el buffer.
private: System::Void btnReceive_Click(System::Object^  sender, System::EventArgs^  e)
	{	HANDLE Hnd;
		unsigned int inicio;
		__int64 longitud;
		array<unsigned char>^ cmd;
		array<unsigned char>^ data;
		
		longitud = Convert::ToInt32(txtLong->Text->ToString());
		if ((longitud%64)!=0)
		{	MessageBox::Show("Number of bytes to read must be multiple of 64", "Error",MessageBoxButtons::OK,MessageBoxIcon::Error);
			return;
		}
		// Apertura del dispositivo.
		Hnd = OpenDevice(DevName,false);

		if (Hnd == INVALID_HANDLE_VALUE) return;
		txtDataToReceive->Text = "";
		// Envío del comando para leer.
		Array::Resize(cmd,64);
        cmd[0]='A'; cmd[1]='T'; cmd[2]='C'; cmd[3]= 2;   // Comando 2: Lectura de la RAM
        for(int i=4;i<8;i++)
			cmd[i]=(longitud>>(8*(i-4)))&0xff; // Nº de bytes que se van a leer
		inicio = Convert::ToInt32(txtStart->Text->ToString());
        // ahora los comandos que recibirá la FPGA (dependen del firmware de la FPGA).
		if (cmbDevType->SelectedItem=="Mapper")
        {   for(int i=8;i<12;i++)
                cmd[i]=(inicio>>(8*(i-8)))&0xff;
        }
        else if (cmbDevType->SelectedItem=="Datalogger")
        {  cmd[8]=1;  cmd[9]=3; // Comando de configuración y de establec. de la direcc
           for(int i=10;i<14;i++)
                cmd[i]=(inicio>>(8*(i-8)))&0xff;
        }
		SendCommand(Hnd, cmd);
		// Lectura del dispositivo
		data = ReadDevice(Hnd, (long) longitud);
		// Cierre del dispositivo.
		CloseHandle(Hnd);

		// **** Mensaje SEA PACIENTE
		Form ^recuadro = gcnew(Form);
		Label ^aviso = gcnew(Label);
		recuadro->StartPosition	= System::Windows::Forms::FormStartPosition::CenterScreen;
		recuadro->ControlBox = false;
		recuadro->TopMost = true;
		recuadro->Controls->Add(aviso);
		recuadro->Height = 65;
		recuadro->Width  = 400;
		aviso->Height = recuadro->Height;
		aviso->Width = recuadro->Width;
		aviso->Text = "Processing data... BE PATIENT!!!";
		aviso->TextAlign = System::Drawing::ContentAlignment::MiddleCenter;
		aviso->ForeColor = System::Drawing::Color::Red;
		aviso->BackColor = System::Drawing::Color::Gray;
		aviso->Font = (gcnew System::Drawing::Font(L"Tahoma", 14, System::Drawing::FontStyle::Bold, System::Drawing::GraphicsUnit::Point,static_cast<System::Byte>(0))); 
		recuadro->Show();
		recuadro->Refresh();

		// Copiando los datos al buffer.
		if (cmbReceiveAs->SelectedItem == "Text") // Si se representa como caracteres
		{	// array<unsigned char> ^ ----> array<wchar_t> ^ ----> Conversión de String ^ 
			array<wchar_t> ^datos = Array::ConvertAll(data, gcnew Converter<unsigned char,wchar_t>(Convert::ToChar));
			txtDataToReceive->Text = gcnew String(datos);
		}
		else	// Si se representa como bytes o eventos
		{	String ^MiddleSep, ^EndSep;

			array<int> ^Intdatos;
			if (chkColumns->Checked)	// Indica que separadores se emplean para formatear el texto.
			{	MiddleSep = Convert::ToString(Convert::ToChar(9));						// Tabulación
				EndSep = String::Concat(Convert::ToChar(13), Convert::ToChar(10));		// Intro.
			}
			else
			{	MiddleSep = " ";
				EndSep = " ";
			}
			Intdatos = Array::ConvertAll(data, gcnew Converter<unsigned char,int>(Convert::ToInt32)); //Convesión a enteros.
			// Para obtener un código más rápido evitaremos en lo posible introducir if dentro en los for.
			
			if (cmbReceiveAs->SelectedItem == "Events(ns)")	// Realizar conversión a TimeStamps.
			{	unsigned __int64 TimeStamp = 0;
				array<unsigned __int64>^ OutDatos;
				int j=0;
				OutDatos->Resize(OutDatos,1572864);	// Redimensionamos al tamaño máximo (así evitamos sucesivas redimensiones, pues sería más lento).
				for (int i=0; i<Intdatos->Length; i+=4)
				{	if (Intdatos[i] == 255 && Intdatos[i+1] == 255 && Intdatos[i+2] == 255 && Intdatos[i+3] == 255)
						break;
					else if (Intdatos[i] == 255 && Intdatos[i+1] == 255)	// Overflow
						TimeStamp = TimeStamp + ((unsigned __int64)Intdatos[i+2]*256 + (unsigned __int64)Intdatos[i+3] + 1) * 65535;
					else
					{	TimeStamp = TimeStamp + Intdatos[i] * 256 + Intdatos[i+1];
						TimeStamp = TimeStamp * 10;
						OutDatos[j++]=TimeStamp;
						OutDatos[j++]=Intdatos[i+2];
						OutDatos[j++]=Intdatos[i+3];
						TimeStamp = 0;
					}
				}
				OutDatos->Resize(OutDatos,j);
				array<String ^>^ MyStrArray = Array::ConvertAll(OutDatos, gcnew Converter<unsigned __int64,String ^>(Convert::ToString)); //Conversión a String.
				for (int i=3; i < MyStrArray->Length; i+=3)
					MyStrArray[i] = String::Concat(EndSep,MyStrArray[i]);
				txtDataToReceive->Text = String::Join(MiddleSep,MyStrArray);
			}
			else	// Por Bytes (con o sin signo).
			{	if (cmbReceiveAs->SelectedItem == "Bytes (signed)")	// Si se representan en negativo, hay que pasarlos a negativo.
				{	for (int i=0; i < Intdatos->Length; i++)
						if (Intdatos[i] >127)	
							Intdatos[i] = Intdatos[i] - 256; // Si debe representarse como negativo.
				}
				array<String ^>^ MyStrArray = Array::ConvertAll(Intdatos, gcnew Converter<int,String ^>(Convert::ToString)); //Conversión a String.
				for (int i=4; i < MyStrArray->Length; i+=4)
					MyStrArray[i] = String::Concat(EndSep,MyStrArray[i]);
				txtDataToReceive->Text = String::Join(" ",MyStrArray);
			}
		}
		txtDataToReceive->SelectionStart = 0;
		txtDataToReceive->SelectionLength = 0;
		delete aviso;
		delete recuadro;
	}

	
// **********************************************************************************************
// **************** FUNCIONES PARA LA VISUALIZACIÓN DE IMÁGENES DEL FRAMEGRABBER ****************
// **********************************************************************************************
//** BOTON DE START/STOP ***
private: System::Void btnStart_Click(System::Object^  sender, System::EventArgs^  e)
	{	if (btnStart->Text == "Start")
		{	fgHnd = OpenDevice(DevName,false); //Abro el dispositivo
			if (fgHnd == INVALID_HANDLE_VALUE) return;
			btnUpdate_Click(this, System::EventArgs::Empty); // Actualizar valores.
			btnStart->Text = "Stop";
			frameTimer->Enabled = true;
			refreshTimer->Enabled = true;
			btnUpdate->Enabled = true;
			btnLoad->Enabled = false;
			btnAlias->Enabled = false;
			cmbDevName->Enabled = false;
			cmbDevType->Enabled = false;  
			btnSave->Enabled = true;
			takePhoto = false;
		}
		else
		{	btnStart->Text = "Start";
			frameTimer->Enabled = false;
			refreshTimer->Enabled = false;
			btnUpdate->Enabled = false;
			btnLoad->Enabled = true;
			btnAlias->Enabled = true;
			cmbDevName->Enabled = true;
			cmbDevType->Enabled = true;
			btnSave->Enabled = false;
			CloseHandle(fgHnd);
		}
	}

 //** BOTON DE UPDATE ***
private: System::Void btnUpdate_Click(System::Object^  sender, System::EventArgs^  e)
	 {	refreshTimer->Enabled = false;		// Para evitar que refresque mientras actualiza.
		fgGreyScale= Convert::ToInt32(txtGreyScale->Text);
		fgImgSize = Convert::ToInt32(txtImgSize->Text);
		fgFgSize = Convert::ToInt32(txtfgSize->Text);
		if (fgImgSize>fgFgSize)
		{	MessageBox::Show("Image size can not be longer than Framegabber Size)", "Warnning",MessageBoxButtons::OK,MessageBoxIcon::Warning);
			fgImgSize = fgFgSize;
			txtImgSize->Text = txtfgSize->Text;
		}
		fgHwTimer = Convert::ToInt32(txtHwTimer->Text);
		refreshTimer->Interval = Convert::ToInt32(txtSwTimer->Text);
		fgFramesPerSec=0;
		frameTimer->Enabled = false;   //Para reiniciar la cuenta.
		frameTimer->Enabled = true;
		refreshTimer->Enabled = true;
	}

 //** TEMPORIZADOR DEL REFRESCO DE LA IMAGEN ***
private: System::Void refreshTimer_Tick(System::Object^  sender, System::EventArgs^  e)
	 {	array<unsigned char> ^ cmd;
		array<unsigned char> ^ managedBuffer;
		unsigned long nRead;
		unsigned long bufferSize;
		unsigned char *buffer;

		unsigned long acumulaeventos = 0; 	// Para el cálculo de la carga de la imagen.
		unsigned char MyImage[256*256*3];

		refreshTimer->Enabled = false;	// Contabilizará desde que finaliza el tratamiento hasta el siguiente.

		bufferSize = fgFgSize*fgFgSize;	// Suelen ser framegrabes de 64x64 -> 4096 bytes a leer.
		// Envío del comando de lectura.
		Array::Resize(cmd, 64);			// Redimensiona el Array hasta 64 rellenando con 0s.
        cmd[0]='A'; cmd[1]='T'; cmd[2]='C'; cmd[3]= 2;  // Comando 2: Lectura de la RAM
		for(int i=4;i<8;i++)
			cmd[i]=(bufferSize>>(8*(i-4)))&0xff;		// Nº de bytes que se van a leer
		unsigned long integratTimer = fgHwTimer*100000;
		for(int i=8;i<12;i++)					// Tiempo de integración que empleará el FG (FGs 'especiales')
			cmd[i]=(integratTimer>>(8*(i-8)))&0xff;
		SendCommand(fgHnd, cmd); //Envío del comando.

		// Lectura de la imagen. (
		// buffer = (unsigned char *) malloc(sizeof(bufferSize)); // Esto da error en .NET -> Pasando del array del hoy al array de ayer.
		Array::Resize(managedBuffer, bufferSize); // Reserva espacio para almacenar los datos a devolver.
		pin_ptr<unsigned char> MyPinPtr = &managedBuffer[0]; // Pin Pointer para acceder a la clase array desde un tipo no manejado.
		buffer = MyPinPtr;
		ReadFile(fgHnd, buffer, bufferSize, &nRead, NULL); // Lectura de la imagen
		
/*		Tarea 1: Redimensionar la imagen del buffer a 256x256 que es el tamaño del PictureBox.
			Podríamos usar: display->SizeMode = System::Windows::Forms::PictureBoxSizeMode::Zoom;
			Pero este Zoom interpola haciendo media (se ve muy mal) -> Interpolaremos a mano.
		Tarea 2: Pasar a escala de grises.
			Pódríamos usar Format8bppIndexed directamente pero éste emplea paleta de colores.
				display->Image = gcnew Bitmap(64,64,64,System::Drawing::Imaging::PixelFormat::Format8bppIndexed,(IntPtr)img);
			Lo ideal sería Format16bppGreyScale, pero aunque está definido ¡¡Se les ha olvidado a los de Microsoft implementarlo!!
			Usaremos Format24bppRgb asignando el mismo valor al RGB para obtener el gris. */		

		// Interpolación: Para extender la imagen, a varios píxeles del PictureBox le corresponden el mismo pixel de la imagen.
		for (int i=0;i<256;i++)
		{	unsigned int ii, jj, kk;
			unsigned int valorPixel;
			unsigned int scale = 256/fgImgSize;
			ii = i / scale; 
			for (int j=0;j<256;j++)
			{	jj = j / scale;
				valorPixel = buffer[64*ii+jj]*fgGreyScale;
				kk = 256*3*i+3*j;
				MyImage[kk] = MyImage[kk+1]= MyImage[kk+2]= valorPixel; // Mismo valor a los 3 componenes para crear gama de grises
				acumulaeventos=acumulaeventos + valorPixel;
			}
		}
		display->Image = gcnew Bitmap(256,256,256*3,System::Drawing::Imaging::PixelFormat::Format24bppRgb ,(IntPtr)MyImage);
		if (takePhoto)		// Si fotografías fuera mete algo de basura al liberarse la mem al salir del procedimiento.
		{	saveFileDialog1->Filter = "Bitmap files|*.bmp|All files|*.*";
			if (saveFileDialog1->ShowDialog() == System::Windows::Forms::DialogResult::OK)
				display->Image->Save(saveFileDialog1->FileName);
			takePhoto = false;
		}
		display->Refresh();
		fgFramesPerSec++;	// Cálculo de la tasa de frames
		txtImgCharge->Text = Convert::ToString((unsigned char)((acumulaeventos*100)/(256*256*255))); //Cáculo de la carga de la imagen

		refreshTimer->Enabled = true;
	}

	//*** TEMPORIZADOR PARA EL CÁLCULO DE LA TASA DE REFRESCO ***
private: System::Void frameTimer_Tick(System::Object^  sender, System::EventArgs^  e)
	{	txtFrameSec->Text = Convert::ToString(fgFramesPerSec);
		fgFramesPerSec=0;
	}
	// Botón para la toma de una instantánea.
private: System::Void btnSave_Click(System::Object^  sender, System::EventArgs^  e)
	{	takePhoto = true;
	}

// ***************************************************************************************
// **************** FUNCIONES RELACIONADAS CON LA APARIENCIA DEL PROGRAMA ****************
// ***************************************************************************************

private: System::Void cmbDevType_SelectedItemChanged(System::Object^  sender, System::EventArgs^  e)
	{	String ^FileName = "";
		if (cmbDevType->SelectedItem == "(Generic)")
		{	FileName = "";
			this->grpData->Visible = true;			this->grpFGrabber->Visible = false;
			this->txtCmd->Enabled = true;			this->btnSendCommand->Enabled = true;
			this->cmbDataLogger->Visible = false;
			this->cmbDataLogger1->Visible = false;	this->cmbDataLogger2->Visible = false;
			this->btnUpFile->Enabled = true;		this->btnDownFile->Enabled = true;
			this->txtStart->Enabled = true;			this->txtLong->Enabled = true;
			this->btnSend->Enabled = true;			this->cmbSendAs->Enabled = true;
			this->chkExtend->Enabled = true;
			this->btnReceive->Enabled = true;	    this->cmbReceiveAs->Enabled = true;
			this->chkColumns->Enabled = true;
			if (cmbReceiveAs->Items->Count > 3)
			{	if (cmbReceiveAs->SelectedIndex > 2) cmbReceiveAs->SelectedIndex = 1;
				cmbReceiveAs->Items->RemoveAt(3);
			}
			if (cmbSendAs->Items->Count > 2)
			{	if (cmbSendAs->SelectedIndex > 1) cmbSendAs->SelectedIndex = 1;
				cmbSendAs->Items->RemoveAt(2);
			}
		}
		else if (cmbDevType->SelectedItem == "Sequencer")
		{	FileName = Config->Sequencer;
			this->grpData->Visible = true;			this->grpFGrabber->Visible = false;
			this->txtCmd->Enabled = false;			this->btnSendCommand->Enabled = false;
			this->cmbDataLogger->Visible = false;
			this->cmbDataLogger1->Visible = false;	this->cmbDataLogger2->Visible = false;
			this->btnUpFile->Enabled = true;		this->btnDownFile->Enabled = false;
			this->txtStart->Enabled = false;		this->txtLong->Enabled = false;
			this->btnSend->Enabled = true;			this->cmbSendAs->Enabled = true;
			this->chkExtend->Enabled = true;
			this->btnReceive->Enabled = false;	    this->cmbReceiveAs->Enabled = false;
			this->chkColumns->Enabled = false;
			//txtCmd->Width = 225;
			if (cmbReceiveAs->Items->Count > 3)
			{	if (cmbReceiveAs->SelectedIndex > 2) cmbReceiveAs->SelectedIndex = 1;
				cmbReceiveAs->Items->RemoveAt(3);
			}
			if (cmbSendAs->Items->Count > 2)
			{	if (cmbSendAs->SelectedIndex > 1) cmbSendAs->SelectedIndex = 1;
				cmbSendAs->Items->RemoveAt(2);
			}
		}
		else if (cmbDevType->SelectedItem == "Mapper")
		{	FileName = Config->Mapper;
			this->grpData->Visible = true;			this->grpFGrabber->Visible = false;
			this->txtCmd->Enabled = true;			this->btnSendCommand->Enabled = true;
			this->cmbDataLogger->Visible = false;
			this->cmbDataLogger1->Visible = false;	this->cmbDataLogger2->Visible = false;
			this->btnUpFile->Enabled = true;		this->btnDownFile->Enabled = true;
			this->txtStart->Enabled = true;			this->txtLong->Enabled = true;
			this->btnSend->Enabled = true;			this->cmbSendAs->Enabled = true;
			this->chkExtend->Enabled = true;
			this->btnReceive->Enabled = true;	    this->cmbReceiveAs->Enabled = true;
			this->chkColumns->Enabled = true;
			//txtCmd->Width = 225;
			if (cmbReceiveAs->Items->Count > 3)
			{	if (cmbReceiveAs->SelectedIndex > 2) cmbReceiveAs->SelectedIndex = 1;
				cmbReceiveAs->Items->RemoveAt(3);				
			}
			if (cmbSendAs->Items->Count > 2)
			{	if (cmbSendAs->SelectedIndex > 1) cmbSendAs->SelectedIndex = 1;
				cmbSendAs->Items->RemoveAt(2);
			}
		}
		else if (cmbDevType->SelectedItem == "Datalogger")
		{	FileName = Config->DataLogger;
			this->grpData->Visible = true;			this->grpFGrabber->Visible = false;
			this->txtCmd->Enabled = true;			this->btnSendCommand->Enabled = true;
			this->cmbDataLogger->Visible = true;
			this->cmbDataLogger1->Visible = true;	this->cmbDataLogger2->Visible = true;
			this->btnUpFile->Enabled = true;		this->btnDownFile->Enabled = true;
			this->txtStart->Enabled = true;			this->txtLong->Enabled = true;
			this->btnSend->Enabled = true;			this->cmbSendAs->Enabled = true;
			this->chkExtend->Enabled = true;
			this->btnReceive->Enabled = true;	    this->cmbReceiveAs->Enabled = true;
			this->chkColumns->Enabled = true;
			//txtCmd->Width = 137;
			if (cmbReceiveAs->Items->Count < 4)
			{	cmbReceiveAs->Items->Add("Events(ns)");
				cmbReceiveAs->SelectedItem = "Events(ns)";
			}
			if (cmbSendAs->Items->Count < 3)
			{	cmbSendAs->Items->Add("Events(ns)");
				cmbSendAs->SelectedItem = "Events(ns)";
			}
		}
		else if (cmbDevType->SelectedItem == "Framegrabber")
		{	FileName = Config->FrameGrabber;
			this->grpData->Visible = false;			this->grpFGrabber->Visible = true;
			this->txtCmd->Enabled = false;			this->btnSendCommand->Enabled = false;
			this->cmbDataLogger->Visible = false;
			this->cmbDataLogger1->Visible = false;	this->cmbDataLogger2->Visible = false;
			this->btnUpFile->Enabled = false;		this->btnDownFile->Enabled = false;
			this->txtStart->Enabled = false;		this->txtLong->Enabled = false;
			this->btnSend->Enabled = false;			this->cmbSendAs->Enabled = false;
			this->chkExtend->Enabled = false;
			this->btnReceive->Enabled = false;	    this->cmbReceiveAs->Enabled = false;
			this->chkColumns->Enabled = false;
			//txtCmd->Width = 225;
			if (cmbReceiveAs->Items->Count > 3)
			{	if (cmbReceiveAs->SelectedIndex > 2) cmbReceiveAs->SelectedIndex = 1;
				cmbReceiveAs->Items->RemoveAt(3);				
			}
			if (cmbSendAs->Items->Count > 2)
			{	if (cmbSendAs->SelectedIndex > 1) cmbSendAs->SelectedIndex = 1;
				cmbSendAs->Items->RemoveAt(2);
			}
		}
		else
		{	FileName = "";
			MessageBox::Show("Unknown device type", "Error",MessageBoxButtons::OK,MessageBoxIcon::Error);
			this->grpData->Visible = 1;
			this->grpFGrabber->Visible = 0;
		}
		if (Config->AutomatCombo && cmbDevType->SelectedItem !="(Generic)")
		{	if (FileName != "" && !FileName->Contains("\\"))
				FileName = String::Concat(Config->AppDirectory,"\\",FileName);
			if (!File::Exists(FileName))
			{	if (FileName->Length>0)
					MessageBox::Show(String::Concat("'",FileName,"' not found."),"Error",MessageBoxButtons::OK,MessageBoxIcon::Error);
				openFileDialog1->Filter = "Binary files|*.bin|All files|*.*";
				if (openFileDialog1->ShowDialog() != System::Windows::Forms::DialogResult::OK)
					return;
				FileName = openFileDialog1->FileName;
				if (cmbDevType->SelectedItem == "Sequencer")
					Config->Sequencer = FileName;
				else if (cmbDevType->SelectedItem == "Mapper")
					Config->Mapper = FileName;
				else if (cmbDevType->SelectedItem == "Framegrabber")
					Config->FrameGrabber = FileName;
				else if (cmbDevType->SelectedItem == "Datalogger")
					Config->DataLogger = FileName;
				Config->SaveConfig("setup.ini");				
			}
			LoadFirmware(FileName);
		}
	 }

// Función compartida por todos los controles TextBox para seleccionar el texto al obtener el foco.
private: System::Void SelectingText(System::Object^  sender, System::EventArgs^  e)
	{	TextBox ^MyTextBox = (TextBox ^) sender;
		if (sender->GetHashCode() != LastGotFocus)
			MyTextBox->SelectAll();
		LastGotFocus = sender->GetHashCode();
	}

// **************************************************************************************
// **************** FUNCIONES RELACIONADAS CON EL TRATAMIENTO DE CADENAS ****************
// **************************************************************************************
 // Impide la adición de caracteres inválidos.
private: System::Void txtDataToSend_KeyPress(System::Object^  sender, System::Windows::Forms::KeyPressEventArgs^  e)
	{	int CursorPos;
		if (cmbSendAs->SelectedItem != "Text")
		{	 // Teclas válidas
			if (!Char::IsDigit(e->KeyChar) && e->KeyChar != L' ' && e->KeyChar!= L'-' && e->KeyChar != 13 && e->KeyChar != 8 && e->KeyChar != 3 && e->KeyChar != 22)
			{	e->Handled = true; // Cancela la pulsación de la tecla.
				return;
			}
			// Teclas válidas condicionadas a la anterior
			CursorPos = txtDataToSend->SelectionStart-1;//-txtDataToSend->SelectionLength-1;
			if (CursorPos<0)
			{	if (e->KeyChar == L' ' || e->KeyChar == 13)
					e->Handled = true;
				return;	
			}	
			if ((e->KeyChar == L' ' || e->KeyChar == 13) && !Char::IsDigit(txtDataToSend->Text[CursorPos])) // Espacio o Intro si el anterior es dígito.
				e->Handled = true;
			if (e->KeyChar == L'-' && txtDataToSend->Text[CursorPos]!= L' ' && txtDataToSend->Text[CursorPos]!= 13) // '-' Si el anterior es espacio o intro.
				e->Handled = true;
		}
	}
	// Impide la adición de caracteres inválidos
private: System::Void txtCmd_KeyPress(System::Object^  sender, System::Windows::Forms::KeyPressEventArgs^  e)
	{	int CursorPos;
		// Teclas válidas
		if (!Char::IsDigit(e->KeyChar) && e->KeyChar != L' ' && e->KeyChar!= L'-' && e->KeyChar != 13 && e->KeyChar != 8 && e->KeyChar != 3 && e->KeyChar != 22)
		{	e->Handled = true; 
			return;
		}
		// Teclas válidas condicionadas a la anterior
		CursorPos = txtCmd->SelectionStart-1;
		if (CursorPos<0)
		{	if (e->KeyChar == L' ' || e->KeyChar == 13)
				e->Handled = true;
			return;	
		}
		if ((e->KeyChar == L' ' || e->KeyChar == 13) && !Char::IsDigit(txtCmd->Text[CursorPos])) // Espacio o Intro si el anterior es dígito.
			e->Handled = true;
		if (e->KeyChar == L'-' && txtCmd->Text[CursorPos]!= L' ' && txtCmd->Text[CursorPos]!= 13) // '-' Si el anterior es espacio o intro.
			e->Handled = true;
	}
	// Actualiza el contador de bytes o valores introducidos en el textbox.
private: System::Void txtDataToSend_TextChanged(System::Object^  sender, System::EventArgs^  e)
	{	int NumValues = 0;
		txtDataToSend->ForeColor = System::Drawing::SystemColors::WindowText;
		// Interpreta la cadena como secuencia de  o eventos
		if (cmbSendAs->SelectedItem == "Text")
		{	lblBytesToSend->Text = String::Concat(txtDataToSend->Text->Length.ToString(), " Chars");
			return;
		}
		else if (txtDataToSend->Text->Length > 0)
		{	array<wchar_t> ^ Separators={L' ',13,10,L';',L',', 9};
			array<String ^> ^ Values = txtDataToSend->Text->Split(Separators);
			for (int i=0; i< Values->Length; i++)	// Lo hacemos así pues podría haber, por ejemplo, varios espacios entre valores.
				if (Values[i]!="")
					NumValues++;
		}
		if (cmbSendAs->SelectedItem == "Events(ns)")
		{	NumValues = (int) (NumValues / 3);
			lblBytesToSend->Text = String::Concat(NumValues.ToString(), " Events");
		} 
		else						// Si se interpretan como bytes.
			lblBytesToSend->Text = String::Concat(NumValues.ToString(), " Bytes");
	}

private: System::Void txtCmd_TextChanged(System::Object^  sender, System::EventArgs^  e)
	{	txtCmd->ForeColor = System::Drawing::SystemColors::WindowText;
	}


private: System::Void cmbDataLogger_SelectedIndexChanged(System::Object^  sender, System::EventArgs^  e)
	{	if (cmbDataLogger->SelectedItem == "(Custom)")
			txtCmd->Enabled = true;
		else
			txtCmd->Enabled = false;
	 }
private: System::Void cmbSendAs_SelectedIndexChanged(System::Object^  sender, System::EventArgs^  e)
	{	if (cmbSendAs->SelectedItem == "Events(ns)")
			chkExtend->Visible = false;
		else
			chkExtend->Visible = true;
		 txtDataToSend_TextChanged(this,System::EventArgs::Empty);
	}

// Funciones auxilares para el tratamiento y conversión de cadenas.
// Devuelve una cadena marcando con un '?' aquellos valores que son mayores al tamaño de un byte.
private: String ^ TakeBytes (String ^ OldString, array<unsigned char> ^% OutValues) //Paso de OutValues por referencia (Los String ^ solo pueden por copia)
	{	int MyIntValue;
		int TamOutValues = 0;
		String ^ NewString = "";
		//array<unsigned char> ^OutValues = gcnew array<unsigned char>(100);
		Array::Resize(OutValues, 0);
		OldString = OldString->Replace("?","");	// Eliminamos todos los "?" por si los hubiera para reevaluar los valores.
		if (OldString->Length == 0) return NewString;	// Si la OldStringena queda vacía no hay tratamiento.
		array<wchar_t> ^ Separators={L' ', 13, L';', L','}; //Separadores admitidos (Nota 13+10 = Intro)
		array<String ^> ^ tmpVal = OldString->Split(Separators); // Obtenemos un array de String con todos los valores.
		Array::Resize(OutValues,tmpVal->Length);	// Inicialmente suponemos que todos los valores son válidos.
		String ^Separador = " ";
		for (int i=0; i < tmpVal->Length; i++)
		{	if (tmpVal[i] != "")			// Varios separadores juntos provocarían valores vacíos (también soluciona los intros)
			{	if (tmpVal[i][0] == 10)		// NewLine
				{	Separador = String::Concat(Convert::ToChar(13), Convert::ToChar(10));	// Intro.
					tmpVal[i] = tmpVal[i]->Substring(1);
				}
				if (tmpVal[i] != "")
				{	try							// Lo siguiente podría hacerse con una máscara pero así nos aseguramos que es un número.
					{	MyIntValue = Convert::ToInt32(tmpVal[i]);	// Hago una conversión controlada por try.
						if (MyIntValue > 255 || MyIntValue < -128)	// Error: No es de tamaño byte (con y sin signo)
							NewString = String::Concat(NewString,Separador,tmpVal[i],"?"); 
						else											// Si es de tamaño byte
						{	OutValues[TamOutValues++] = (unsigned char) MyIntValue;
							NewString = String::Concat(NewString,Separador,tmpVal[i]);	// Lo Añado a la lista de valores.
						} 
					}
					catch(Exception ^ e)							// Si el valor no es convertible (porque tiene cualquier cosa)->"?"
					{	Console::Write(e->Message);
						NewString = String::Concat(NewString,Separador,tmpVal[i],"?"); // Este caso se da si la conversión a entero produce error.
					}
					Separador = " ";
				}
			}
		}
		if (NewString->Length > 0)
			NewString = NewString->Substring(1);// Quita el primer espacio.
		Array::Resize(OutValues,TamOutValues);
		return NewString;					// Devuleve la nueva cadena.
	}

 private: String ^ TakeDataLoggerEvents (String ^ OldString, array<unsigned char> ^% OutValues) //Paso de OutValues por referencia (Los String ^ solo pueden por copia)
	{	int TamOutValues = 0;
		String ^ NewString = "";
		//array<unsigned char> ^OutValues = gcnew array<unsigned char>(100);
		Array::Resize(OutValues, 0);
		OldString = OldString->Replace("?","");	// Eliminamos todos los "?" por si los hubiera para reevaluar los valores.
		if (OldString->Length == 0) return NewString;	// Si la OldString queda vacía, no hay tratamiento.
		array<wchar_t> ^ Separators={L' ', 13,L';', L',',9}; //Separadores admitidos (Nota 13+10 = Intro)
		array<String ^> ^ tmpVal = OldString->Split(Separators); // Obtenemos un array de String con todos los valores.
		Array::Resize(OutValues,0);
		int j = 0;
		String ^ Separador = " ";
		for (int i=0; i < tmpVal->Length; i++)
		{	if (tmpVal[i] != "")			// Varios separadores juntos provocarían valores vacíos (también soluciona los intros)
			{	if (tmpVal[i][0] == 10)		// NewLine
				{	Separador = String::Concat(Convert::ToChar(13), Convert::ToChar(10));	// Intro.
					tmpVal[i] = tmpVal[i]->Substring(1);
				}
				if (tmpVal[i] != "")
				{	try							// Lo siguiente podría hacerse con una máscara pero así nos aseguramos que es un número.
					{	if (j%3 == 0)			// Tratamiento de un TimeStamp.
						{	__int64 Cociente64, Resto64;
							int Cociente, Resto;
							// EL cociente indica los overflows + 1		Recordenos:     FFFF     Overflow
							// EL resto indica el TimeStamp                          TimeStamp    Event
							// Puesto que la resolución es de 10ns, eliminamos dividimos entre 10
							Cociente64 = Convert::ToUInt64(tmpVal[i]) / 10;
							if (Cociente64 > 4294901759)
							{	Array::Resize(OutValues,OutValues->Length+1);
								OutValues[OutValues->Length-1] = 0;
								NewString = String::Concat(NewString,Separador,tmpVal[i],"?"); 
							}
							else
							{	Cociente64 = System::Math::DivRem(Cociente64,65535, Resto64);
								if (Cociente64 > 0)		// Hay overflow.
								{	Cociente64 = Cociente64 - 1;	// Pues si Overflow = 0 --> 1 desbordamiento.
									Cociente = System::Math::DivRem((int)Cociente64,256,Resto);
									Array::Resize(OutValues,OutValues->Length+4);
									OutValues[OutValues->Length-4] = 255;	// La marca de OverFlow.
									OutValues[OutValues->Length-3] = 255;
									OutValues[OutValues->Length-2] = (unsigned char) Cociente; 
									OutValues[OutValues->Length-1] = (unsigned char) Resto;
								}
								Cociente = System::Math::DivRem( (int)Resto64,256,Resto);
								Array::Resize(OutValues,OutValues->Length+2);
								OutValues[OutValues->Length-2] = (unsigned char) Cociente;
								OutValues[OutValues->Length-1] = (unsigned char) Resto; 
								NewString = String::Concat(NewString,Separador,tmpVal[i]);	// Lo Añado a la lista de valores.
							}
						}
						else
						{	int MyIntValue = Convert::ToInt32(tmpVal[i]);	// Hago una conversión controlada por try.
							if (MyIntValue > 255 || MyIntValue < -128)	// Error: No es de tamaño byte (con y sin signo)
							{	Array::Resize(OutValues,OutValues->Length+1);
								OutValues[OutValues->Length-1] = 0;
								NewString = String::Concat(NewString,Separador,tmpVal[i],"?"); 
							}
							else											// Si es de tamaño byte
							{	Array::Resize(OutValues,OutValues->Length+1);
								OutValues[OutValues->Length-1] = (unsigned char) MyIntValue;
								NewString = String::Concat(NewString,Separador,tmpVal[i]);	// Lo Añado a la lista de valores.
							}
						}
						Separador = " ";
						j++;
					}
					catch(Exception ^ e)							// Si el valor no es convertible (porque tiene cualquier cosa)->"?"
					{	Console::Write(e->Message);
						NewString = String::Concat(NewString," ",tmpVal[i],"?"); // Este caso se da si la conversión a entero produce error.
						Array::Resize(OutValues,OutValues->Length+1);
						OutValues[OutValues->Length-1] = 0;
					}
				}
			}	
		}
		if (OutValues->Length%4 != 0)	// Si hay un evento que no está escrito completamente,lo eliminamos.
		{	Array::Resize(OutValues, (int) System::Math::Floor((double)(OutValues->Length/4))* 4);
			MessageBox::Show("last event is not complete, then will be ignored", "Warning",MessageBoxButtons::OK,MessageBoxIcon::Warning);
		}
		Array::Resize(OutValues,OutValues->Length+4);  // Añadir la marca de OverFlow.
		OutValues[OutValues->Length-4] = 255;	
		OutValues[OutValues->Length-3] = 255;
		OutValues[OutValues->Length-2] = 255; 
		OutValues[OutValues->Length-1] = 255;
		if (NewString->Length > 0)
			NewString = NewString->Substring(1);// Quita el primer espacio.
		return NewString;					// Devuelve la nueva cadena.
	}

public: void VerifyUnsignedIntValue(System::Object^  sender, System::EventArgs^  e)
	{	TextBox ^ MyTextBox = (TextBox ^) sender;
		try
		{	int Val = Convert::ToInt32(MyTextBox->Text);	// Provoca excepción si rebasa los límtes de Int32.
			if (Val < 0)
				throw;										// Provoca una exceción si es negativo;
		}
		catch (Exception ^excep)
		{	MessageBox::Show("This value is out of range", "Error",MessageBoxButtons::OK,MessageBoxIcon::Error);
			Console::WriteLine(excep->Message);
			MyTextBox->Focus();
			MyTextBox->SelectAll(); 
		}
	}

// Función auxiliar para detectar los dispositivos USB-AER conectados.
private: void UpdateDevicesList(void)
	{	HANDLE Hnd;
		unsigned char Num = 0;
		wchar_t Buffer[100];	// Aunque SetupDiGetDeviceRegistryProperty quiere un puntero a Byte, devuelve wide char.
		String ^ BufferStr;		// Para convertir el Buffer 
		GUID ClassGuid = My_Device_CLASS_GUID;	// Nuestro GUID de clase de instalación de dispositivos.
		SP_DEVINFO_DATA infoDev;

		//FindDevForm ^MyFindDevForm= gcnew FindDevForm();
		Hnd=SetupDiGetClassDevs(&ClassGuid,NULL,NULL , DIGCF_PRESENT ); //Obtener manejador de la clase
		if(Hnd==INVALID_HANDLE_VALUE)
		{	printf("No class device found\n");
			return;
		}
		infoDev.cbSize=sizeof(infoDev);
		String ^ PrevDevName = (String ^) cmbDevName->SelectedItem;
		cmbDevName->Items->Clear();
		while(SetupDiEnumDeviceInfo(Hnd,Num,&infoDev))
		{	if(SetupDiGetDeviceRegistryProperty(Hnd,&infoDev,SPDRP_LOCATION_INFORMATION,NULL,(PBYTE)Buffer,100,NULL))
			{	// Conversión de wchar_t a String ^
				BufferStr = marshal_as<String^>(Buffer);	// Este marshal no requiere contexto: http://msdn.microsoft.com/en-us/library/bb384865.aspx
				cmbDevName->Items->Add(BufferStr);
			}
			Num++;
		}
		if (cmbDevName->Items->Count == 0)
		{	cmbDevName->Items->Add("(None)");
			cmbDevName->SelectedIndex= 0;
		}
		else
		{	cmbDevName->SelectedIndex= 0;
			for (int i = 0;i < cmbDevName->Items->Count; i++)
			{	if (PrevDevName == (String ^)cmbDevName->Items[i])
				{	cmbDevName->SelectedIndex = i;
					break;
				}
			}
		}
	}

private: System::Void LoadFPGAApp_Load(System::Object^  sender, System::EventArgs^  e) {
		 }
};
}