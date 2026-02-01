	component dsp is
		port (
			ay      : in  std_logic_vector(17 downto 0) := (others => 'X'); -- ay
			by      : in  std_logic_vector(17 downto 0) := (others => 'X'); -- by
			ax      : in  std_logic_vector(17 downto 0) := (others => 'X'); -- ax
			bx      : in  std_logic_vector(17 downto 0) := (others => 'X'); -- bx
			resulta : out std_logic_vector(36 downto 0);                    -- resulta
			resultb : out std_logic_vector(36 downto 0);                    -- resultb
			clk     : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- clk
			ena     : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- ena
			aclr    : in  std_logic_vector(1 downto 0)  := (others => 'X')  -- aclr
		);
	end component dsp;

	u0 : component dsp
		port map (
			ay      => CONNECTED_TO_ay,      --      ay.ay
			by      => CONNECTED_TO_by,      --      by.by
			ax      => CONNECTED_TO_ax,      --      ax.ax
			bx      => CONNECTED_TO_bx,      --      bx.bx
			resulta => CONNECTED_TO_resulta, -- resulta.resulta
			resultb => CONNECTED_TO_resultb, -- resultb.resultb
			clk     => CONNECTED_TO_clk,     --     clk.clk
			ena     => CONNECTED_TO_ena,     --     ena.ena
			aclr    => CONNECTED_TO_aclr     --    aclr.aclr
		);

