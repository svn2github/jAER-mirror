package ch.unizh.ini.devices.components.aer;

import java.nio.ByteBuffer;

import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.config.pots.IPot;
import net.sf.jaer2.devices.config.pots.Masterbias;
import net.sf.jaer2.devices.config.pots.Pot;
import net.sf.jaer2.eventio.eventpackets.raw.RawEventPacket;
import net.sf.jaer2.eventio.events.EarEvent;
import net.sf.jaer2.eventio.events.Event;
import net.sf.jaer2.eventio.events.SampleEvent;
import net.sf.jaer2.eventio.events.SpecialEvent;
import net.sf.jaer2.eventio.translators.DeviceTranslator;
import net.sf.jaer2.util.SSHSNode;

import com.google.common.collect.ImmutableList;

public class CochleaAMS1c extends AERChip {
	public CochleaAMS1c(final SSHSNode componentConfigNode) {
		this("CochleaAMS1c", componentConfigNode);
	}

	public CochleaAMS1c(final String componentName, final SSHSNode componentConfigNode) {
		super(componentName, componentConfigNode);

		// Masterbias needs to be added first!
		final Masterbias masterbias = new Masterbias("Masterbias", "Masterbias for on-chip bias generator.",
			componentConfigNode);
		addSetting(masterbias);

		// BufferBias BufferIPot ???

		addSetting(new IPot("VAGC", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Curstartbpf", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("DacBufferNb", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vbp", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Ibias20OpAmp", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vioff", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vsetio", ".", componentConfigNode, masterbias, Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("Vdc1", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("NeuronRp", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vclbtgate", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("N.C.", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vbias2", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Ibias10OpAmp", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vthbpf2", ".", componentConfigNode, masterbias, Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("Follbias", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("pdbiasTX", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vrefract", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("VbampP", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vcascode", ".", componentConfigNode, masterbias, Pot.Type.CASCODE, Pot.Sex.N));
		addSetting(new IPot("Vbpf2", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Ibias10OTA", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vthbpf1", ".", componentConfigNode, masterbias, Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("Curstart", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vbias1", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("NeuronVleak", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vioffbpfn", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new IPot("Vcasbpf", ".", componentConfigNode, masterbias, Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("Vdc2", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vterm", ".", componentConfigNode, masterbias, Pot.Type.CASCODE, Pot.Sex.N));
		addSetting(new IPot("Vclbtcasc", ".", componentConfigNode, masterbias, Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new IPot("reqpuTX", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new IPot("Vbpf1", ".", componentConfigNode, masterbias, Pot.Type.NORMAL, Pot.Sex.P));
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

	public static final class Translator implements DeviceTranslator {
		@Override
		public ImmutableList<Class<? extends Event>> getEventTypes() {
			return ImmutableList.<Class<? extends Event>> of(EarEvent.class, SampleEvent.class, SpecialEvent.class);
		}

		@Override
		public void extractRawEventPacket(ByteBuffer buffer, RawEventPacket rawEventPacket) {
			// TODO Auto-generated method stub
		}
	}
}
