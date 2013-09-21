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
		addSetting(new Masterbias("Masterbias", "Masterbias for on-chip bias generator."));

		// BufferBias BufferIPot ???

		addSetting(new IPot("VAGC", ".", Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Curstartbpf", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("DacBufferNb", ".", Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vbp", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Ibias20OpAmp", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vioff", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vsetio", ".", Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("Vdc1", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("NeuronRp", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vclbtgate", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("N.C.", ".", Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vbias2", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Ibias10OpAmp", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vthbpf2", ".", Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("Follbias", ".", Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("pdbiasTX", ".", Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vrefract", ".", Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("VbampP", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vcascode", ".", Pot.Type.CASCODE, Pot.Sex.N));
		addSetting(new IPot("Vbpf2", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Ibias10OTA", ".", Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vthbpf1", ".", Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("Curstart", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vbias1", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("NeuronVleak", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vioffbpfn", ".", Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vcasbpf", ".", Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("Vdc2", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vterm", ".", Pot.Type.CASCODE, Pot.Sex.N));
		addSetting(new IPot("Vclbtcasc", ".", Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("reqpuTX", ".", Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vbpf1", ".", Pot.Type.NORMAL, Pot.Sex.P));
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
