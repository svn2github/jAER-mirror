/*
 * packetContainer.h
 *
 *  Created on: May 25, 2015
 *      Author: llongi
 */

#ifndef LIBCAER_EVENTS_PACKETCONTAINER_H_
#define LIBCAER_EVENTS_PACKETCONTAINER_H_

#include "common.h"

struct caer_event_packet_container {
	uint32_t eventTypes; // Number of different event packets contained.
	caerEventPacketHeader eventPackets[];
}__attribute__((__packed__));

// Keep several packets of multiple types together, for easy time-based association.
typedef struct caer_event_packet_container *caerEventPacketContainer;


static inline uint32_t caerEventPacketContainerGetEventTypes(caerEventPacketContainer header) {
	return (le32toh(header->eventTypes));
}

static inline void caerEventPacketContainerSetEventTypes(caerEventPacketContainer header, uint32_t eventTypes) {
	header->eventTypes = htole32(eventTypes);
}

static inline caerEventPacketContainer caerEventPacketContainerAllocate(uint32_t eventTypes) {
	size_t eventPacketContainerSize = eventTypes * sizeof(caerEventPacketContainer);

	caerEventPacketContainer packetContainer = malloc(eventPacketContainerSize);
	if (packetContainer == NULL) {
#if !defined(LIBCAER_LOG_NONE)
		caerLog(LOG_CRITICAL, "Event Packet Container",
			"Failed to allocate %zu bytes of memory for Event Packet Container, containing %"
			PRIu32 " packet types. Error: %d.", eventPacketContainerSize, eventTypes, errno);
#endif
		return (NULL);
	}

	// Zero out event memory (all events invalid).
	memset(packetContainer, 0, eventPacketContainerSize);

	// Fill in header fields.
	caerEventPacketContainerSetEventTypes(packetContainer, eventTypes);

	return (packetContainer);
}

static inline void *caerEventPacketContainerGetEventPacket(caerEventPacketContainer header, uint32_t n) {
	// Check that we're not out of bounds.
	if (n >= caerEventPacketContainerGetEventTypes(header)) {
#if !defined(LIBCAER_LOG_NONE)
		caerLog(LOG_CRITICAL, "Event Packet Container",
			"Called caerEventPacketContainerGetEventPacket() with invalid event packet offset %" PRIu32 ", while maximum allowed value is %" PRIu32 ".",
			n, caerEventPacketContainerGetEventTypes(header));
#endif
		return (NULL);
	}

	// Return a pointer to the specified event packet.
	return (header->eventPackets[n]);
}

static inline void caerEventPacketContainerSetEventPacket(caerEventPacketContainer header, uint32_t n,
	caerEventPacketHeader packetHeader) {
	// Check that we're not out of bounds.
	if (n >= caerEventPacketContainerGetEventTypes(header)) {
#if !defined(LIBCAER_LOG_NONE)
		caerLog(LOG_CRITICAL, "Event Packet Container",
			"Called caerEventPacketContainerSetEventPacket() with invalid event packet offset %" PRIu32 ", while maximum allowed value is %" PRIu32 ".",
			n, caerEventPacketContainerGetEventTypes(header));
#endif
		return;
	}

	// Store the given event packet.
	header->eventPackets[n] = packetHeader;
}

#endif /* LIBCAER_EVENTS_PACKETCONTAINER_H_ */
