package ch.unizh.ini.devices.components.aer;

import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.config.pots.IPot;
import net.sf.jaer2.devices.config.pots.Masterbias;
import net.sf.jaer2.devices.config.pots.Pot;
import net.sf.jaer2.eventio.eventpackets.EventPacketContainer;
import net.sf.jaer2.eventio.eventpackets.raw.RawEventPacket;
import net.sf.jaer2.eventio.events.Event;
import net.sf.jaer2.eventio.translators.Translator;

import com.google.common.collect.ImmutableList;

public class CochleaAMS1c extends AERChip implements Translator {
	private static final long serialVersionUID = -2933845194421958981L;

	public CochleaAMS1c() {
		this("CochleaAMS1c");
	}

	public CochleaAMS1c(final String componentName) {
		super(componentName);

		// Masterbias needs to be added first!
		addSetting(new Masterbias("Masterbias", "."), AERChip.MASTERBIAS_ADDRESS);

		// BufferBias BufferIPot ???

		addSetting(new IPot("VAGC", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 0);
		addSetting(new IPot("Curstartbpf", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 1);
		addSetting(new IPot("DacBufferNb", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 2);
		addSetting(new IPot("Vbp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 3);
		addSetting(new IPot("Ibias20OpAmp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 4);
		addSetting(new IPot("Vioff", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 5);
		addSetting(new IPot("Vsetio", ".", Pot.Type.CASCODE, Pot.Sex.P, 0), 6);
		addSetting(new IPot("Vdc1", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 7);
		addSetting(new IPot("NeuronRp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 8);
		addSetting(new IPot("Vclbtgate", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 9);
		addSetting(new IPot("N.C.", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 10);
		addSetting(new IPot("Vbias2", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 11);
		addSetting(new IPot("Ibias10OpAmp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 12);
		addSetting(new IPot("Vthbpf2", ".", Pot.Type.CASCODE, Pot.Sex.P, 0), 13);
		addSetting(new IPot("Follbias", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 14);
		addSetting(new IPot("pdbiasTX", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 15);
		addSetting(new IPot("Vrefract", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 16);
		addSetting(new IPot("VbampP", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 17);
		addSetting(new IPot("Vcascode", ".", Pot.Type.CASCODE, Pot.Sex.N, 0), 18);
		addSetting(new IPot("Vbpf2", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 19);
		addSetting(new IPot("Ibias10OTA", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 20);
		addSetting(new IPot("Vthbpf1", ".", Pot.Type.CASCODE, Pot.Sex.P, 0), 21);
		addSetting(new IPot("Curstart", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 22);
		addSetting(new IPot("Vbias1", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 23);
		addSetting(new IPot("NeuronVleak", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 24);
		addSetting(new IPot("Vioffbpfn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 25);
		addSetting(new IPot("Vcasbpf", ".", Pot.Type.CASCODE, Pot.Sex.P, 0), 26);
		addSetting(new IPot("Vdc2", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 27);
		addSetting(new IPot("Vterm", ".", Pot.Type.CASCODE, Pot.Sex.N, 0), 28);
		addSetting(new IPot("Vclbtcasc", ".", Pot.Type.CASCODE, Pot.Sex.P, 0), 29);
		addSetting(new IPot("reqpuTX", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 30);
		addSetting(new IPot("Vbpf1", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 31);
	}

	@Override
	public int getSizeX() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public int getSizeY() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public int getNumCellTypes() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public ImmutableList<Class<? extends Event>> getEventTypes() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public void extractEventPacketContainer(final RawEventPacket rawEventPacket,
		final EventPacketContainer eventPacketContainer) {
		// TODO Auto-generated method stub
	}

	@Override
	public void reconstructRawEventPacket(final EventPacketContainer eventPacketContainer,
		final RawEventPacket rawEventPacket) {
		// TODO Auto-generated method stub
	}
}
