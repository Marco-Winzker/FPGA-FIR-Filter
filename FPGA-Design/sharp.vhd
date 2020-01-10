-- sharp.vhd
--
-- top level
--
-- FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
-- (c) Marco Winzker, Hochschule Bonn-Rhein-Sieg, 10.01.2020

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sharp is
  port (clk       : in  std_logic;                      -- input clock 74.25 MHz, video 720p
        reset_n   : in  std_logic;                      -- reset (invoked during configuration)
        enable_in : in  std_logic_vector(2 downto 0);   -- three slide switches
        -- video in
        vs_in     : in  std_logic;                      -- vertical sync
        hs_in     : in  std_logic;                      -- horizontal sync
        de_in     : in  std_logic;                      -- data enable is '1' for valid pixel
        r_in      : in  std_logic_vector(7 downto 0);   -- red component of pixel
        g_in      : in  std_logic_vector(7 downto 0);   -- green component of pixel
        b_in      : in  std_logic_vector(7 downto 0);   -- blue component of pixel
        -- video out
        vs_out    : out std_logic;                      -- corresponding to video-in
        hs_out    : out std_logic;
        de_out    : out std_logic;
        r_out     : out std_logic_vector(7 downto 0);
        g_out     : out std_logic_vector(7 downto 0);
        b_out     : out std_logic_vector(7 downto 0);
        --
        clk_o     : out std_logic;                      -- output clock (do not modify)
        led       : out std_logic_vector(2 downto 0));  -- not supported by remote lab
end sharp;

architecture behave of sharp is

    -- input FFs
    signal reset             		: std_logic;
	signal enable            		: std_logic_vector(2 downto 0);
    signal vs_0, hs_0, de_0			: std_logic;
    signal r_0, g_0, b_0     		: integer range 0 to 255;
    -- output of signal processing
    signal vs_1, hs_1, de_1  		: std_logic;
    signal r_1, g_1, b_1     		: integer range 0 to 255;

begin
	
process
begin	
   wait until rising_edge(clk);
   
   -- input FFs for control
    reset <= not reset_n;
	enable <= enable_in;
	 -- input FFs for video signal
    vs_0  <= vs_in;
    hs_0  <= hs_in;
    de_0  <= de_in;
    r_0   <= to_integer(unsigned(r_in)); 
    g_0   <= to_integer(unsigned(g_in));
    b_0   <= to_integer(unsigned(b_in));	 
	
end process;

r_slice: entity work.sharp_slice 
    port map (  clk      => clk,
                reset    => reset,
                de_in    => de_0,
                data_in  => r_0,
                data_out => r_1);

g_slice: entity work.sharp_slice 
    port map (  clk      => clk,
                reset    => reset,
                de_in    => de_0,
                data_in  => g_0,
                data_out => g_1);

b_slice: entity work.sharp_slice 
    port map (  clk      => clk,
                reset    => reset,
                de_in    => de_0,
                data_in  => b_0,
                data_out => b_1);

control: entity work.sharp_control
    generic map (delay => 6) 
    port map (  clk      => clk,
                reset    => reset,
                vs_in    => vs_0,
                hs_in    => hs_0,
                de_in    => de_0,
                vs_out   => vs_1,
                hs_out   => hs_1,
                de_out   => de_1);

    
process
begin
  wait until rising_edge(clk);
  
        
    -- output FFs 
    vs_out  <= vs_1;
    hs_out  <= hs_1;
    de_out  <= de_1;
--	if (de_1 = '1') then
        r_out   <= std_logic_vector(to_unsigned(r_1,8));
        g_out   <= std_logic_vector(to_unsigned(g_1,8));
        b_out   <= std_logic_vector(to_unsigned(b_1,8));
--	else
--		r_out   <= "00000000";
--		g_out   <= "00000000";
--		b_out   <= "00000000";
--	end if;
end process;

clk_o <= clk;
led   <= "000";

end behave;
