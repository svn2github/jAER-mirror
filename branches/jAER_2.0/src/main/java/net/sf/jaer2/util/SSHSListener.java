package net.sf.jaer2.util;

public interface SSHSListener {
	public static enum NodeEvents {
		CHILD_NODE_ADDED;
	}

	public void nodeChanged(SSHSNode node, NodeEvents event, SSHSNode changeNode);

	public static enum AttributeEvents {
		ATTRIBUTE_ADDED,
		ATTRIBUTE_MODIFIED;
	}

	public <V> void attributeChanged(SSHSNode node, AttributeEvents event, String changeKey, Class<V> changeType,
		V changeValue);
}
