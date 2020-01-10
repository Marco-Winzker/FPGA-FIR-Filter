-- sharp_slice.vhd
--
-- FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
-- (c) Marco Winzker, Hochschule Bonn-Rhein-Sieg, 10.01.2020

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sharp_slice is
  port ( clk       : in  std_logic;
         reset     : in  std_logic;
         de_in     : in  std_logic;
         data_in   : in  integer range 0 to 255;
         data_out  : out integer range 0 to 255);
end sharp_slice;

architecture behave of sharp_slice is

  type filter_array is array (0 to 6) of integer range 0 to 255;
  signal v_tap   : filter_array;
  signal h_tap   : filter_array;
  signal v_out   : integer range 0 to 255;

begin

v_tap(0) <= data_in;

g: for i in 0 to 5 generate 
  mem: entity work.sharp_linemem
    port map (  clk      => clk,
                reset    => reset,
                write_en => de_in,
                data_in  => v_tap(i),
                data_out => v_tap(i+1));
   end generate;

	
ver_filt: entity work.sharp_arith
    port map (  clk      => clk,
                reset    => reset,
                tap_m3   => v_tap(0),
                tap_m2   => v_tap(1),
                tap_m1   => v_tap(2),
                tap_00   => v_tap(3),
                tap_p1   => v_tap(4),
                tap_p2   => v_tap(5),
                tap_p3   => v_tap(6),
                data_out => v_out);
	
process
begin
  wait until rising_edge(clk);
  h_tap(0) <= v_out;
  for i in 0 to 5 loop
    h_tap(i+1) <= h_tap(i);
  end loop;
end process;   

hor_filt: entity work.sharp_arith
    port map (  clk      => clk,
                reset    => reset,
                tap_m3   => h_tap(0),
                tap_m2   => h_tap(1),
                tap_m1   => h_tap(2),
                tap_00   => h_tap(3),
                tap_p1   => h_tap(4),
                tap_p2   => h_tap(5),
                tap_p3   => h_tap(6),
                data_out => data_out);
	
end behave;

