package net.sf.jaer2.devices.components.misc;

import javafx.scene.layout.Pane;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.config.ConfigBase;

public class InvenSense6050 implements Component {
	public InvenSense6050(final int i2cAddress) {
		// TODO Auto-generated constructor stub
	}

	@Override
	public String getName() {
		return "InvenSense6050";
	}

	@Override
	public Pane getConfigGUI() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public void setProgrammer(final Controller programmer) {
		// TODO Auto-generated method stub
	}

	@Override
	public void addSetting(final ConfigBase setting, final int address) {
		// TODO Auto-generated method stub
	}
}
