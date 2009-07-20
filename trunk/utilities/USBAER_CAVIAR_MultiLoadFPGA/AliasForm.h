#pragma once

using namespace System;
using namespace System::ComponentModel;
using namespace System::Collections;
using namespace System::Windows::Forms;
using namespace System::Data;
using namespace System::Drawing;


namespace LoadFPGA {

	/// <summary>
	/// Resumen de AliasForm
	///
	/// ADVERTENCIA: si cambia el nombre de esta clase, deberá cambiar la
	///          propiedad 'Nombre de archivos de recursos' de la herramienta de compilación de recursos administrados
	///          asociada con todos los archivos .resx de los que depende esta clase. De lo contrario,
	///          los diseñadores no podrán interactuar correctamente con los
	///          recursos adaptados asociados con este formulario.
	/// </summary>
	public ref class AliasForm : public System::Windows::Forms::Form
	{
	public: String ^DevName;
	public:
		AliasForm(String ^ InitName)
		{
			InitializeComponent();
			//
			//TODO: agregar código de constructor aquí
			//
			txtAlias->Text = InitName;
			DevName = InitName;
		}

	protected:
		/// <summary>
		/// Limpiar los recursos que se estén utilizando.
		/// </summary>
		~AliasForm()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::TextBox^  txtAlias;
	protected: 

	private: System::Windows::Forms::Button^  btnChange;
	private: System::Windows::Forms::Button^  btnCancel;
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
			this->txtAlias = (gcnew System::Windows::Forms::TextBox());
			this->btnChange = (gcnew System::Windows::Forms::Button());
			this->btnCancel = (gcnew System::Windows::Forms::Button());
			this->SuspendLayout();
			// 
			// txtAlias
			// 
			this->txtAlias->Location = System::Drawing::Point(12, 12);
			this->txtAlias->Name = L"txtAlias";
			this->txtAlias->Size = System::Drawing::Size(123, 20);
			this->txtAlias->TabIndex = 0;
			this->txtAlias->TextAlign = System::Windows::Forms::HorizontalAlignment::Center;
			this->txtAlias->TextChanged += gcnew System::EventHandler(this, &AliasForm::txtAlias_TextChanged);
			// 
			// btnChange
			// 
			this->btnChange->DialogResult = System::Windows::Forms::DialogResult::OK;
			this->btnChange->Location = System::Drawing::Point(141, 10);
			this->btnChange->Name = L"btnChange";
			this->btnChange->Size = System::Drawing::Size(75, 23);
			this->btnChange->TabIndex = 1;
			this->btnChange->Text = L"Ch&ange";
			this->btnChange->UseVisualStyleBackColor = true;
			this->btnChange->Click += gcnew System::EventHandler(this, &AliasForm::btnChange_Click);
			// 
			// btnCancel
			// 
			this->btnCancel->DialogResult = System::Windows::Forms::DialogResult::Cancel;
			this->btnCancel->Location = System::Drawing::Point(222, 9);
			this->btnCancel->Name = L"btnCancel";
			this->btnCancel->Size = System::Drawing::Size(75, 23);
			this->btnCancel->TabIndex = 2;
			this->btnCancel->Text = L"&Cancel";
			this->btnCancel->UseVisualStyleBackColor = true;
			// 
			// AliasForm
			// 
			this->AcceptButton = this->btnChange;
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->CancelButton = this->btnCancel;
			this->ClientSize = System::Drawing::Size(307, 42);
			this->ControlBox = false;
			this->Controls->Add(this->btnCancel);
			this->Controls->Add(this->btnChange);
			this->Controls->Add(this->txtAlias);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedToolWindow;
			this->Name = L"AliasForm";
			this->StartPosition = System::Windows::Forms::FormStartPosition::CenterParent;
			this->Text = L"Change Alias";
			this->Load += gcnew System::EventHandler(this, &AliasForm::AliasForm_Load);
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion

private: System::Void AliasForm_Load(System::Object^  sender, System::EventArgs^  e)
	{	txtAlias->SelectAll();
	 }

private: System::Void txtAlias_TextChanged(System::Object^  sender, System::EventArgs^  e)
	 { 	if(txtAlias->Text->Length>28)
			btnChange->Enabled = false;
		else
			btnChange->Enabled = true;
	 }

private: System::Void btnChange_Click(System::Object^  sender, System::EventArgs^  e)
	{	DevName = txtAlias->Text;
	}
};
}
