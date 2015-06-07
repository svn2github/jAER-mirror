
	type tCochleaLPScannerConfig is record
		ScannerEnabled_S : std_logic;
		ScannerEar_S     : std_logic;
		ScannerChannel_S : unsigned(5 downto 0);
	end record tCochleaLPScannerConfig;
	