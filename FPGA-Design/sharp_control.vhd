-- sharp_control.vhd
--
-- FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
-- (c) Marco Winzker, Hochschule Bonn-Rhein-Sieg, 10.01.2020

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sharp_control is
  generic ( delay : integer := 7 );
  port ( clk       : in  std_logic;
         reset     : in  std_logic;
         vs_in     : in  std_logic;
         hs_in     : in  std_logic;
         de_in     : in  std_logic;
         vs_out    : out std_logic;
         hs_out    : out std_logic;
         de_out    : out std_logic);
end sharp_control;

architecture behave of sharp_control is


  type delay_array is array (0 to delay-1) of std_logic;
  signal vs_delay : delay_array;
  signal hs_delay : delay_array;
  signal de_delay : delay_array;

begin

process
begin
  wait until rising_edge(clk);

  vs_delay(0) <= vs_in;
  hs_delay(0) <= hs_in;
  de_delay(0) <= de_in;

  for i in 0 to (delay-2) loop
    vs_delay(i+1) <= vs_delay(i);
    hs_delay(i+1) <= hs_delay(i);
    de_delay(i+1) <= de_delay(i);
  end loop;

end process;

vs_out <= vs_delay(delay-1);
hs_out <= hs_delay(delay-1);
de_out <= de_delay(delay-1);
  
end behave;

