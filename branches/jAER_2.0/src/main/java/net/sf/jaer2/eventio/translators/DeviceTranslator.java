package net.sf.jaer2.eventio.translators;

import java.nio.ByteBuffer;

import net.sf.jaer2.eventio.eventpackets.raw.RawEventPacket;

public interface DeviceTranslator {
	public void extractRawEventPacket(final ByteBuffer buffer, final RawEventPacket rawEventPacket);
}
