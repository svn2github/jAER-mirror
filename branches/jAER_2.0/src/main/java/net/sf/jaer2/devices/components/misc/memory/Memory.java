package net.sf.jaer2.devices.components.misc.memory;

import java.io.File;

import javafx.event.EventHandler;
import javafx.scene.control.TextField;
import javafx.scene.input.MouseEvent;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.PairRO;

import com.google.common.collect.ImmutableList;

public abstract class Memory extends Component {
	private static final long serialVersionUID = 1918978964879724132L;

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
		final TextField firmwareFileField = GUISupport.addTextField(rootConfigLayout, null, null);

		GUISupport.addButtonWithMouseClickedHandler(rootConfigLayout, "Select file", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(final MouseEvent mouse) {
					final File loadFirmware = GUISupport.showDialogLoadFile(ImmutableList.of(PairRO.of("BIX", "*.bix"),
						PairRO.of("IIC", "*.iic"), PairRO.of("HEX", "*.hex"), PairRO.of("IMG", "*.img")));

					if ((loadFirmware != null) && GUISupport.checkReadPermissions(loadFirmware)) {
						firmwareFileField.setText(loadFirmware.getAbsolutePath());
						setFirmwareFile(loadFirmware);
					}
				}
			});
	}
}
