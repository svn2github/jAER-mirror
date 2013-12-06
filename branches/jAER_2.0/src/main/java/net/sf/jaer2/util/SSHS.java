package net.sf.jaer2.util;

public final class SSHS {
	public static final SSHS GLOBAL = new SSHS();

	private final SSHSNode root;

	public SSHS() {
		root = new SSHSNode("", null);
	}

	public boolean nodeExists(final String nodePath) {
		SSHS.checkNodePath(nodePath);

		// First node is the root.
		SSHSNode curr = root;
		final String[] searchPaths = nodePath.split("/");

		// Search (or create) viable node iteratively.
		for (int i = 1; i < searchPaths.length; i++) {
			final String nextName = searchPaths[i];
			SSHSNode next = curr.getChild(nextName);

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
		SSHS.checkNodePath(nodePath);

		// First node is the root.
		SSHSNode curr = root;
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

	public void beginTransaction(final String... nodePaths) {
		for (final String nodePath : nodePaths) {
			SSHS.checkNodePath(nodePath);
		}

		for (final String nodePath : nodePaths) {
			getNode(nodePath).transactionLock();
		}
	}

	public void endTransaction(final String... nodePaths) {
		for (final String nodePath : nodePaths) {
			SSHS.checkNodePath(nodePath);
		}

		for (final String nodePath : nodePaths) {
			getNode(nodePath).transactionUnlock();
		}
	}

	private static final String nodePathRegexp = "^/([a-zA-Z\\d\\.:\\$\\(\\)\\[\\]{}]+/)*$";

	private static void checkNodePath(final String nodePath) {
		if (nodePath == null) {
			throw new IllegalArgumentException("Node path cannot be null.");
		}

		if (!nodePath.matches(nodePathRegexp)) {
			throw new IllegalArgumentException("Invalid node path format.");
		}
	}
}
