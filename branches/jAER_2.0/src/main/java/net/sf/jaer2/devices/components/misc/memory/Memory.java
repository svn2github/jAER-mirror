package net.sf.jaer2.devices.components.misc.memory;

import java.io.File;
import java.util.List;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.event.EventHandler;
import javafx.scene.control.TextField;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.util.Files;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.PairRO;

import com.google.common.collect.ImmutableList;

public abstract class Memory extends Component {
	private static final long serialVersionUID = 1918978964879724132L;

	private static final List<String> binaryExtensions = ImmutableList.of("*.bix", "*.iic", "*.hex", "*.img");

	private final int sizeKB;
	private File firmwareFile;

	public Memory(final String memName, final int memSizeKB) {
		super(memName);

		sizeKB = memSizeKB;
	}

	public int getSize() {
		return sizeKB;
	}

	public File getFirmwareFile() {
		return firmwareFile;
	}

	public void setFirmwareFile(final File firmwareFile) {
		this.firmwareFile = firmwareFile;
	}

	@Override
	protected void buildConfigGUI() {
		final HBox fileBox = new HBox(5);
		rootConfigLayout.getChildren().add(fileBox);

		GUISupport.addLabel(fileBox, "Select firmware file",
			"Select a compatible firmware file to upload to device ROM.", null, null);

		final TextField firmwareFileField = GUISupport.addTextField(fileBox, null, null);

		firmwareFileField.textProperty().addListener(new ChangeListener<String>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends String> val, final String oldVal, final String newVal) {
				if (newVal == null) {
					return;
				}

				// Check that the typed in file is valid, if not, color the
				// field background red.
				final File loadFirmware = new File(newVal);

				if (!Files.checkReadPermissions(loadFirmware) || !Files.checkExtensions(loadFirmware, Memory.binaryExtensions)) {
					firmwareFileField.setStyle("-fx-background-color: #FF575A");
					return;
				}

				firmwareFileField.setStyle("");
				setFirmwareFile(loadFirmware);
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(fileBox, "Select file", true, null, new EventHandler<MouseEvent>() {
			@Override
			public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
				final File loadFirmware = GUISupport.showDialogLoadFile(ImmutableList.of(PairRO.of("Binary",
					Memory.binaryExtensions)));

				if (loadFirmware == null) {
					return;
				}

				firmwareFileField.setText(loadFirmware.getAbsolutePath());
				setFirmwareFile(loadFirmware);
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(rootConfigLayout, "Flash!", true, "/images/icons/Transfer.png",
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent arg0) {
					if (getFirmwareFile() == null) {
						GUISupport.showDialogError("No file selected!");
						return;
					}

					// TODO: add programmer upload.
				}
			});
	}
}
