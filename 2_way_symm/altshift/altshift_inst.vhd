	component altshift is
		port (
			aclr     : in  std_logic                     := 'X';             -- aclr
			clken    : in  std_logic                     := 'X';             -- clken
			clock    : in  std_logic                     := 'X';             -- clock
			shiftin  : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- shiftin
			shiftout : out std_logic_vector(7 downto 0);                     -- shiftout
			taps     : out std_logic_vector(15 downto 0)                     -- taps
		);
	end component altshift;

	u0 : component altshift
		port map (
			aclr     => CONNECTED_TO_aclr,     --  altshift_taps_input.aclr
			clken    => CONNECTED_TO_clken,    --                     .clken
			clock    => CONNECTED_TO_clock,    --                     .clock
			shiftin  => CONNECTED_TO_shiftin,  --                     .shiftin
			shiftout => CONNECTED_TO_shiftout, -- altshift_taps_output.shiftout
			taps     => CONNECTED_TO_taps      --                     .taps
		);

