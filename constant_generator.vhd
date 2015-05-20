library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.monte_carlo.all;


entity constant_generator is
GENERIC (
 	STOCK_WIDTH : natural := STOCK_W;
 	T_WIDTH : natural := TIME_W
 );
	port(
		clk: in std_logic;
		stock : in std_logic_vector(STOCK_WIDTH-1 DOWNTO 0);
		vol : in std_logic_vector(STOCK_WIDTH-1 downto 0);
		t : in std_logic_vector(T_WIDTH-1 downto 0);
		u : in std_logic_vector(STOCK_WIDTH-1 downto 0);

		--output
		A : out std_logic_vector (STOCK_WIDTH-1 downto 0);
		B : out std_logic_vector (STOCK_WIDTH-1 downto 0);
		C : out std_logic_vector (STOCK_WIDTH-1 downto 0);
		constantReady : out std_logic
	);
END ENTITY constant_generator;

ARCHITECTURE behavioral OF constant_generator IS

	SIGNAL vol_squared : std_logic_vector(STOCK_WIDTH-1 downto 0);
	SIGNAL half_vol_squared : std_logic_vector(STOCK_WIDTH-1 downto 0);
	SIGNAL u_minus_half_vv : std_logic_vector(STOCK_WIDTH-1 downto 0);
	SIGNAL u_minus_half_vol_sq_t : std_logic_vector(STOCK_WIDTH-1 downto 0);
	SIGNAL exp_u_m_h_vv_t : std_logic_vector (STOCK_WIDTH-1 downto 0);
	SIGNAL t_extended : std_logic_vector (STOCK_WIDTH-1 downto 0);
	SIGNAL sqrt_t : std_logic_vector(STOCK_WIDTH-1 DOWNTO 0);

	SIGNAL before_t_ext : std_logic_vector(STOCK_WIDTH/2-T_WIDTH);
	SIGNAL after_t_ext : std_logic_vector(STOCK_WIDTH/2);

	SIGNAL u_t : std_logic_vector(STOCK_WIDTH-1 downto 0);
	SIGNAL minus_u_t : std_logic_vector(STOCK_WIDTH-1 downto 0);

BEGIN
	before_t_ext <= (others=>'0');
	after_t_ext <= (others=>'0');
	t_extended <= before_t_ext & t & after_t_ext;


	--A = Stock * exp (u-0.5*vol*vol)t
	vol_squared_map : fixedpoint_multiply PORT MAP (clk,vol,vol,vol_squared);
	half_vol_squared_map : vol_squared_over_2 <= vol_squared(STOCK_WIDTH-1) & vol_squared(STOCK_WIDTH-1 downto 1);

	subtract_from_u :process (clk,u,half_vol_squared) is 
		variable u : integer := 0;
		variable half_v_sq: integer;
		variable u_minus_hvsq: integer;		

		BEGIN
		u := to_integer(unsigned(u));
		half_v_sq := to_integer(unsigned(vol_squared_over_2));
		--u - hvsq
		u_minus_hvsq := u - half_v_sq;
		u_minus_half_vv <= std_logic_vector(to_unsigned(u_minus_hvsq,STOCK_WIDTH));

	end process subtract_from_u;

	--now multiply by t
		--extend t first
	u_minus_half_vol_sq_t_map : fixedpoint_multiply PORT MAP (clk,u_minus_half_vv,t_extended,u_minus_half_vol_sq_t);

	--now exp(that)
	exp_a_map : exp_fn PORT MAP (
		clk=>clk, 
		bitVector => u_minus_half_vol_sq_t, 
		outVector=>exp_u_m_h_vv_t
	);

	A_final_map : fixedpoint_multiply PORT MAP (
		clk=>clk,
		data_in1 => exp_u_m_h_vv_t,
		data_in2 => stock,
		data_out => A
		);


	--B = vol * sqrt(t)
	sqrt_t_map : sqrt_fn PORT MAP (
		clk => clk,
		bitVector => t_extended,
		outVector => sqrt_t
		);

	B_map : fixedpoint_multiply PORT MAP (
		clk=>clk,
		data_in1 => vol,
		data_in2 => sqrt_t,
		data_out => B
		);
	
	--C = exp(-u*t)
	u_t_map : fixedpoint_multiply PORT MAP (
		clk =>clk,
		data_in1 => t_extended,
		data_in2 => u,
		data_out => u_t
		);

	not_ut <= not u_t;
	minus_ut_map : process (clk,not_ut) is
		variable result : integer := 0;
		BEGIN
			result := to_integer(unsigned(not_ut)) + 1;
			minus_ut <= std_logic_vector(to_unsigned(result,STOCK_WIDTH));
	end process minus_ut_map;

	C_map : exp_fn PORT MAP (clk,minus_ut,C);

end architecture behavioral;

