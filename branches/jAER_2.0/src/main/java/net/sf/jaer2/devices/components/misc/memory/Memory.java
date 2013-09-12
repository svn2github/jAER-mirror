package net.sf.jaer2.devices.components.misc.memory;

import javafx.scene.layout.Pane;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.config.ConfigBase;

public abstract class Memory implements Component {
	private final String name;
	private final int sizeKB;

	public Memory(final String memName, final int memSizeKB) {
		name = memName;
		sizeKB = memSizeKB;
	}

	@Override
	public String getName() {
		return name;
	}

	public int getSize() {
		return sizeKB;
	}

	@Override
	public void setProgrammer(final Controller programmer) {
		// TODO Auto-generated method stub
	}

	@Override
	public Pane getConfigGUI() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public void addSetting(final ConfigBase setting, final int address) {
		// TODO Auto-generated method stub
	}
}
