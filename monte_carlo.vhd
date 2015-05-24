----------------------------------------------------------------------------- 
library IEEE; 
use IEEE.std_logic_1164.all; 
use ieee.numeric_std.all;    -- for UNSIGNED
--Additional standard or custom libraries go here 
 
package monte_carlo is 
 
	constant STOCK_W: natural := 16;
	constant N_NUMBER : natural := 1024*1024;
	constant N_PAR : natural := 8;
	constant log2_N_NUMBER : natural := 20; --equal to log2(N_NUMBER)
	constant TIME_W : natural := 4;

	COMPONENT project392 is 
		GENERIC (
			STOCK_WIDTH : natural := STOCK_W;
			T_WIDTH : natural := TIME_W
	);
 	PORT( 
		--Inputs 
			 clk : in std_logic; 
			 start : in std_logic; 
			 stock_price : in std_logic_vector (STOCK_WIDTH -1 downto 0);  -- from 0 to 63
			 strike_price :  in std_logic_vector (STOCK_WIDTH -1 downto 0);  --from 0 to 63
			 t : in std_logic_vector(T_WIDTH-1 downto 0); --from 0 to 15 days'
			 vol : in std_logic_vector(STOCK_WIDTH-1 DOWNTO 0);
			 u : in std_logic_vector(STOCK_WIDTH-1 downto 0);

			 --Outputs 
			 --premium_led is the width that will map entirely to the LEDs 
			 premium_led : out std_logic_vector (7*(STOCK_WIDTH/4) -1 downto 0);
			 --stock_out_led : out std_logic_vector (STOCK_WIDTH*2 - 1 downto 0)
			 ready : out std_logic;
			 progress_led : out std_logic_vector(9 downto 0);

			 reset : in std_logic
	); 
	end COMPONENT project392; 

	COMPONENT top_fpga is
		GENERIC (
			STOCK_WIDTH : natural := STOCK_W;
			NUM_ITERATIONS : natural := N_NUMBER;
			NUM_PARALLEL : natural := N_PAR;
			log_iterations : integer := log2_N_NUMBER;
			T_WIDTH : natural := TIME_W
		 );
		 PORT ( 
			 --Inputs 
			 clk : in std_logic; 
			 start : in std_logic; 
			 stock_price : in std_logic_vector (STOCK_WIDTH -1 downto 0);  -- from 0 to 63 or 31
			 strike_price :  in std_logic_vector (STOCK_WIDTH -1 downto 0);  --from 0 to 63 or 31
			 t : in std_logic_vector(T_WIDTH-1 downto 0); --from 0 to 15 days;
			 u : in std_logic_vector(STOCK_WIDTH-1 DOWNTO 0); -- rate-free interest rate
			 vol : in std_logic_vector(STOCK_WIDTH-1 DOWNTO 0);
			 
			 --Outputs 
			 premium : out std_logic_vector (STOCK_WIDTH -1 downto 0);  --32 bits long
			 stock_out : out std_logic_vector (STOCK_WIDTH - 1 downto 0); --32 bits long
			 ready : out std_logic;
			 progress_led : out std_logic_vector(9 downto 0); --to display the progress of the operation
		 	 reset : in std_logic

		 ); 

	end COMPONENT top_fpga;

	COMPONENT constant_generator is
		GENERIC (
			STOCK_WIDTH : natural := STOCK_W;
			T_WIDTH : natural := TIME_W
		);
		PORT (
			clk: in std_logic;
			stock : in std_logic_vector(STOCK_WIDTH-1 DOWNTO 0);
			vol : in std_logic_vector(STOCK_WIDTH-1 downto 0);
			t : in std_logic_vector(T_WIDTH-1 downto 0);
			u : in std_logic_vector(STOCK_WIDTH-1 downto 0);

			--output
			A : out std_logic_vector (STOCK_WIDTH-1 downto 0);
			B : out std_logic_vector (STOCK_WIDTH-1 downto 0);
			C : out std_logic_vector (STOCK_WIDTH-1 downto 0);
			constantReady : out std_logic;

			reset : in std_logic
		);
	END COMPONENT constant_generator;

	COMPONENT random_fn is
		GENERIC (
	 		STOCK_WIDTH : natural := STOCK_W
		);
		PORT (
			clk : in std_logic;
			data_in : in std_logic_vector(STOCK_WIDTH-1 downto 0);
			data_out : out std_logic_vector(STOCK_WIDTH-1 downto 0)
		);
	end COMPONENT random_fn;

	COMPONENT pricer is 
		GENERIC (
		 	STOCK_WIDTH : natural := STOCK_W
		 );
		PORT(
			clk: in std_logic;
			Strike : in std_logic_vector(STOCK_WIDTH-1 downto 0);
			A : in std_logic_vector(STOCK_WIDTH-1 downto 0);
			B : in std_logic_vector(STOCK_WIDTH-1 downto 0);
			C : in std_logic_vector(STOCK_WIDTH-1 downto 0);
			constants_ready : in std_logic;

			data_out : out std_logic_vector(STOCK_WIDTH-1 downto 0);
			pricer_ready : out std_logic;
			
			reset : in std_logic
		);
	end COMPONENT pricer;

	COMPONENT leddcd is
	    PORT(
	        data_in         :in std_logic_vector (3 downto 0);
	        segments_out    :out std_logic_vector (6 downto 0)
	    );
	end COMPONENT leddcd;

	COMPONENT exp_fn is 
		PORT( 
			 --Inputs 
			 clk : in std_logic; 
			 bitVector : in std_logic_vector (15 downto 0); --16 bits
			 
			 --Outputs 
			 outVector : out std_logic_vector (15 downto 0)
		 ); 
	end COMPONENT exp_fn;

	COMPONENT sqrt_fn is 
		PORT( 
		 	--Inputs (is unsigned)
			clk : in std_logic; 
			bitVector : in std_logic_vector (7 downto 0); --8 bits
	 	
	 		--Outputs (is fixed point)
			outVector : out std_logic_vector (15 downto 0) --OUT OF 16 BITS
 		); 
	end COMPONENT sqrt_fn;

	COMPONENT fixedpoint_multiply is
		GENERIC (
 			STOCK_WIDTH : natural := STOCK_W
 		);
		PORT(
			clk : in std_logic;
			data_in1 : in std_logic_vector(STOCK_WIDTH-1 downto 0);
			data_in2 : in std_logic_vector(STOCK_WIDTH-1 downto 0);
			data_out : out std_logic_vector(STOCK_WIDTH-1 downto 0)
		);
	END COMPONENT fixedpoint_multiply;

	COMPONENT random_gaussian is 
		PORT (
			clk : in std_logic;
			reset : in std_logic;
			random : out std_logic_vector(11 downto 0);
			ready : out std_logic
		);
	END COMPONENT random_gaussian;

	COMPONENT fulladder_n is
  		GENERIC (
    		n : integer
  		);
  		PORT (
		    cin   : in std_logic;
		    x     : in std_logic_vector(n-1 downto 0);
		    y     : in std_logic_vector(n-1 downto 0);
		    cout  : out std_logic;
		    z     : out std_logic_vector(n-1 downto 0)
  		);
	end COMPONENT fulladder_n;

 --Other constants, types, subroutines, COMPONENTs go here 
 
end package monte_carlo; 
 
package body monte_carlo is 
 
--Subroutine declarations go here 
-- you will not have any need for it now, this package is only for defining -
-- some useful constants 

function log2(i: natural) return integer is
	variable temp: integer := i;
	variable ret_val: integer:= 0;
	begin
		while temp > 1 loop
			ret_val := ret_val+1;
			temp := temp/2;
		end loop;
		return ret_val;
end function log2;


--Credit: http://vhdlguru.blogspot.com/2010/03/vhdl-function-for-finding-square-root.html
-- Credit given to Vipin from VHDL Guru
-- unsigned sqrt computation

function  sqrt  ( d : UNSIGNED ) return UNSIGNED is
	variable a : unsigned(31 downto 0):=d;  --original input.
	variable q : unsigned(15 downto 0):=(others => '0');  --result.
	variable left,right,r : unsigned(17 downto 0):=(others => '0');  --input to adder/sub.r-remainder.
	variable i : integer:=0;

	begin
		for i in 0 to 15 loop
			right(0):='1';
			right(1):=r(17);
			right(17 downto 2):=q;
			left(1 downto 0):=a(31 downto 30);
			left(17 downto 2):=r(15 downto 0);
			a(31 downto 2):=a(29 downto 0);  --shifting by 2 bit.
			if ( r(17) = '1') then
				r := left + right;
			else
				r := left - right;
			end if;
			q(15 downto 1) := q(14 downto 0);
			q(0) := not r(17);
		end loop; 
		
		return q;

end sqrt;

end package body monte_carlo; 
--------------------------------------------------