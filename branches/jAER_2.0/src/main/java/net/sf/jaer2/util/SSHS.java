package net.sf.jaer2.util;

public final class SSHS {
	public static final SSHS GLOBAL = new SSHS();

	private final SSHSNode root;

	public SSHS() {
		root = new SSHSNode("", null);
	}

	public boolean existsNode(final String nodePath) {
		SSHS.checkAbsoluteNodePath(nodePath);

		// First node is the root.
		SSHSNode curr = root;

		// Optimization: the root node always exists.
		if (nodePath.equals("/")) {
			return (true);
		}

		// Split path up into single components.
		final String[] searchPaths = nodePath.split("/");

		// Search (or create) viable node iteratively.
		for (int i = 1; i < searchPaths.length; i++) {
			final String nextName = searchPaths[i];
			final SSHSNode next = curr.getChild(nextName);

			// If node doesn't exist, return that.
			if (next == null) {
				return (false);
			}

			curr = next;
		}

		// We got to the end, so the node exists.
		return (true);
	}

	public SSHSNode getNode(final String nodePath) {
		SSHS.checkAbsoluteNodePath(nodePath);

		// First node is the root.
		SSHSNode curr = root;

		// Optimization: the root node always exists.
		if (nodePath.equals("/")) {
			return (curr);
		}

		// Split path up into single components.
		final String[] searchPaths = nodePath.split("/");

		// Search (or create) viable node iteratively.
		for (int i = 1; i < searchPaths.length; i++) {
			final String nextName = searchPaths[i];
			SSHSNode next = curr.getChild(nextName);

			// Create next node in path if not existing.
			if (next == null) {
				next = curr.addChild(nextName);
			}

			curr = next;
		}

		// 'curr' now contains the specified node.
		return curr;
	}

	public static boolean existsRelativeNode(final SSHSNode node, final String nodePath) {
		SSHS.checkRelativeNodePath(nodePath);

		// Start with the given node.
		SSHSNode curr = node;
		final String[] searchPaths = nodePath.split("/");

		// Search (or create) viable node iteratively.
		for (final String nextName : searchPaths) {
			final SSHSNode next = curr.getChild(nextName);

			// If node doesn't exist, return that.
			if (next == null) {
				return (false);
			}

			curr = next;
		}

		// We got to the end, so the node exists.
		return (true);
	}

	public static SSHSNode getRelativeNode(final SSHSNode node, final String nodePath) {
		SSHS.checkRelativeNodePath(nodePath);

		// Start with the given node.
		SSHSNode curr = node;
		final String[] searchPaths = nodePath.split("/");

		// Search (or create) viable node iteratively.
		for (final String nextName : searchPaths) {
			SSHSNode next = curr.getChild(nextName);

			// Create next node in path if not existing.
			if (next == null) {
				next = curr.addChild(nextName);
			}

			curr = next;
		}

		// 'curr' now contains the specified node.
		return curr;
	}

	private static final String absoluteNodePathRegexp = "^/([a-zA-Z-_\\d\\.:\\(\\)\\[\\]{}]+/)*$";
	private static final String relativeNodePathRegexp = "^([a-zA-Z-_\\d\\.:\\(\\)\\[\\]{}]+/)+$";

	private static void checkAbsoluteNodePath(final String absolutePath) {
		if ((absolutePath == null) || (absolutePath.length() == 0)) {
			throw new IllegalArgumentException("Node path cannot be null.");
		}

		if (!absolutePath.matches(SSHS.absoluteNodePathRegexp)) {
			throw new IllegalArgumentException("Invalid absolute node path format.");
		}
	}

	private static void checkRelativeNodePath(final String relativePath) {
		if ((relativePath == null) || (relativePath.length() == 0)) {
			throw new IllegalArgumentException("Node path cannot be null.");
		}

		if (!relativePath.matches(SSHS.relativeNodePathRegexp)) {
			throw new IllegalArgumentException("Invalid relative node path format.");
		}
	}
}
