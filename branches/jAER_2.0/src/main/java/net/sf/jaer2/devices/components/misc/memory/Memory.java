package net.sf.jaer2.devices.components.misc.memory;

import javafx.scene.layout.Pane;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.config.ConfigBase;

public abstract class Memory implements Component {
	public Memory(final String name, final int size) {

	}

	@Override
	public String getName() {
		// TODO Auto-generated method stub
		return null;
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
