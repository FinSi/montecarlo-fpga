----------------------------------------------------------------------------- 
library IEEE; 
 
use IEEE.std_logic_1164.all; 
--Additional standard or custom libraries go here 
 
package monte_carlo is 
 
	constant STOCK_W: natural := 32;

	COMPONENT project392 is 
		GENERIC ( STOCK_WIDTH : natural := STOCK_W);
	 	port( 
			--Inputs 
				 clk : in std_logic; 
				 start : in std_logic; 
				 stock_price : in std_logic_vector (STOCK_WIDTH -1 downto 0);  -- from 0 to 63
				 strike_price :  in std_logic_vector (STOCK_WIDTH -1 downto 0);  --from 0 to 63
				 t : in std_logic_vector(3 downto 0); --from 0 to 15 days
				 
				 --Outputs 
				 --premium_led is the width that will map entirely to the LEDs 
				 premium_led : out std_logic_vector (7*(STOCK_WIDTH/4) -1 downto 0);
				 --stock_out_led : out std_logic_vector (STOCK_WIDTH*2 - 1 downto 0)
				 ready : out std_logic
		); 
	end COMPONENT project392; 

	COMPONENT top_fpga is
	GENERIC (
 	STOCK_WIDTH : natural := STOCK_W
 );
		port( 
			 --Inputs 
			 clk : in std_logic; 
			 start : in std_logic; 
			 stock_price : in std_logic_vector (STOCK_WIDTH -1 downto 0);  -- from 0 to 63
			 strike_price :  in std_logic_vector (STOCK_WIDTH -1 downto 0);  --from 0 to 63
			 t : in std_logic_vector(3 downto 0); --from 0 to 15 days
			 
			 --Outputs 
			 premium : out std_logic_vector (STOCK_WIDTH -1 downto 0); 
			 stock_out : out std_logic_vector (STOCK_WIDTH - 1 downto 0);
			 ready : out std_logic
		 ); 
	end component top_fpga;

	component random_fn is
	GENERIC (
 	STOCK_WIDTH : natural := STOCK_W
 );
		port(
			data_in : in std_logic_vector(STOCK_WIDTH-1 downto 0);
			data_out : out std_logic_vector(STOCK_WIDTH-1 downto 0)
		);
	end component random_fn;

	COMPONENT leddcd is
    port(
            data_in         :in std_logic_vector (3 downto 0);
            segments_out    :out std_logic_vector (6 downto 0)
        );
	end COMPONENT leddcd;
 
 --Other constants, types, subroutines, components go here 
 
end package monte_carlo; 
 
package body monte_carlo is 
 
--Subroutine declarations go here 
-- you will not have any need for it now, this package is only for defining -
-- some useful constants 
 
end package body monte_carlo; 
--------------------------------------------------