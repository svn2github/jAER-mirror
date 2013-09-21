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
		final Masterbias masterbias = new Masterbias("Masterbias", "Masterbias for on-chip bias generator.");
		addSetting(masterbias);

		// BufferBias BufferIPot ???

		addSetting(new IPot("VAGC", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Curstartbpf", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("DacBufferNb", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vbp", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Ibias20OpAmp", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vioff", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vsetio", ".", masterbias, Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("Vdc1", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("NeuronRp", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vclbtgate", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("N.C.", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vbias2", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Ibias10OpAmp", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vthbpf2", ".", masterbias, Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("Follbias", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("pdbiasTX", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vrefract", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("VbampP", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vcascode", ".", masterbias, Pot.Type.CASCODE, Pot.Sex.N));
		addSetting(new IPot("Vbpf2", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Ibias10OTA", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vthbpf1", ".", masterbias, Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("Curstart", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vbias1", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("NeuronVleak", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vioffbpfn", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vcasbpf", ".", masterbias, Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("Vdc2", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vterm", ".", masterbias, Pot.Type.CASCODE, Pot.Sex.N));
		addSetting(new IPot("Vclbtcasc", ".", masterbias, Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("reqpuTX", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vbpf1", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
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
