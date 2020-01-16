-- sim_sharp_self-checking.vhd
--
-- testbench for edge enhancement with FIR filter
-- reading and writing images in ppm-file format
--          ppm-file can be viewed with IrfanView and probably other image viewers
--          verified with IrfanView version 4.54 - 64 bit and 4.44 - 64 bit
--
-- FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
-- (c) Marco Winzker, Hochschule Bonn-Rhein-Sieg, 14.01.2020

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;

entity sim_sharp is
end sim_sharp;

architecture sim of sim_sharp is

-- define constants for simulation
  constant stimuli_filename  : string  := "Lindau_Harbour_720p.ppm";
  constant expected_filename : string  := "Lindau_Harbour_expected.ppm";
  constant response_filename : string  := "Lindau_Harbour_response.ppm";
  constant x_blank           : integer := 100;   -- horizontal blanking
  constant trail             : integer := 1000;  -- clock cycles after active image

-- signals of testbench
  signal clk       : std_logic := '0';
  signal reset_n   : std_logic;
  signal enable_in : std_logic_vector(2 downto 0);
  signal vs_in     : std_logic;
  signal hs_in     : std_logic;
  signal de_in     : std_logic;
  signal r_in      : std_logic_vector(7 downto 0);
  signal g_in      : std_logic_vector(7 downto 0);
  signal b_in      : std_logic_vector(7 downto 0);
  signal vs_out    : std_logic;
  signal hs_out    : std_logic;
  signal de_out    : std_logic;
  signal r_out     : std_logic_vector(7 downto 0);
  signal g_out     : std_logic_vector(7 downto 0);
  signal b_out     : std_logic_vector(7 downto 0);
  signal clk_o     : std_logic;
  signal led       : std_logic_vector(2 downto 0);
  signal x_size, y_size      : integer;
  signal end_tb    : integer   := 0;
  signal mismatch  : integer   := 0;

begin

  -- clock generation
  clk <= not clk after 5 ns;

  -- instantiation of design-under-verification
  duv : entity work.sharp
    port map (clk       => clk,
              reset_n   => reset_n,
              enable_in => enable_in,
              vs_in     => vs_in,
              hs_in     => hs_in,
              de_in     => de_in,
              r_in      => r_in,
              g_in      => g_in,
              b_in      => b_in,
              vs_out    => vs_out,
              hs_out    => hs_out,
              de_out    => de_out,
              r_out     => r_out,
              g_out     => g_out,
              b_out     => b_out,
              clk_o     => clk_o,
              led       => led);

  -- main process for stimuli
  stimuli_process : process

  -- variables for stimuli file
    file stimuli_file       : text;
    variable l              : line;
    variable stimuli_status : file_open_status;
    variable x, y      : integer;
    variable i, r_integer, g_integer, b_integer  : integer;

  begin

    -- read stimuli file
    file_open(stimuli_status, stimuli_file, stimuli_filename, read_mode);
    readline(stimuli_file, l);          -- read line 1 with magic number
    readline(stimuli_file, l);          -- read line 2 with comments
    readline(stimuli_file, l);          -- read line 3 with x, y size
    read(l, i); x_size <= i;
    read(l, i); y_size <= i;
    readline(stimuli_file, l);          -- read line 4 with maximum value
    readline(stimuli_file, l);          -- read first line of image data

    -- init
    reset_n   <= '0', '1' after 50 ns;  -- reset for 10 clock cycles
    enable_in <= "111";
    vs_in     <= '0';
    hs_in     <= '0';
    de_in     <= '0';
    r_in      <= "00000000";
    g_in      <= "00000000";
    b_in      <= "00000000";

    -- wait for reset
    wait for 100 ns;

    -- loop for one frame
    for y in 0 to y_size-1 loop
    
      -- set vertical sync
      if (y = 0) then
        vs_in <= '1';
      else
        vs_in <= '0';
      end if;

      -- set herizontal sync
      hs_in <= '1';
      for x in 0 to x_blank-1 loop
        wait until falling_edge(clk);
      end loop;  -- x, blanking
      hs_in <= '0';

      -- read one image line from file and give it to device under verification
      -- set de_in to '1' for active pixel
      de_in <= '1';
      for x in 0 to x_size-1 loop
      
        -- a ppm-file has several pixel per line
        -- check if the current line has characters to be processed
        -- if no character or only one  character is present, read new line (single character might be one blank)
        if l'length < 2 then readline(stimuli_file, l); end if;
        read(l, r_integer);
        read(l, g_integer);
        read(l, b_integer);
        -- convert integer values to std_logic
        r_in <= std_logic_vector(to_unsigned(r_integer,8));
        g_in <= std_logic_vector(to_unsigned(g_integer,8));
        b_in <= std_logic_vector(to_unsigned(b_integer,8));

        wait until falling_edge(clk);
      end loop;  -- x, active line
      de_in <= '0';
      r_in  <= "00000000";
      g_in  <= "00000000";
      b_in  <= "00000000";

    end loop;  -- y

-- simulation for trailing clock cycles
    for i in 0 to trail-1 loop
      wait until falling_edge(clk);
    end loop;

    end_tb <= 1;                        -- signal to close response_file
    file_close(stimuli_file);
    wait for 20 ns;

-- stop simulation
    if (mismatch = 0) then
      assert false
        report "Simulation completed, EVERYTHING OK"
        severity failure;
    else
      assert false
        report "Simulation completed, " & integer'image(mismatch) & " MISMATCHES XXXX XXXX XXXX XXXX XXXX XXXX"
        severity failure;
    end if;

  end process;

-- second process to handle DUT output
  response_process : process
    variable x_pos, y_pos     : integer := 0;
-- variables for writing simulated response
    file response_file        : text;
    variable l_sim            : line;
    variable response_status  : file_open_status;
    variable r_sim, g_sim, b_sim        : integer;
-- variables for expected response file
    file expected_file        : text;
    variable l_ex             : line;
    variable expected_status  : file_open_status;
    variable r_ex, g_ex, b_ex : integer;
    variable x_size_expected, y_size_expected : integer;

  begin

    wait until (hs_out = '1');  -- wait until stimuli process is started


-- open file for output image
    file_open(response_status, response_file, response_filename, write_mode);
    write (l_sim, string'("P3"));       -- magic number
    writeline(response_file, l_sim);        
    write (l_sim, string'("# generated by VHDL testbench"));       -- comment
    writeline(response_file, l_sim);   
    write (l_sim, x_size);
    write (l_sim, string'(" "));
    write (l_sim, y_size);
    writeline(response_file, l_sim);        
    write (l_sim, string'("255"));       -- maximum value
    writeline(response_file, l_sim);        
    
-- open file for expected data
    file_open(expected_status, expected_file, expected_filename, read_mode);
    readline(expected_file, l_ex);      -- read line 1 with magic number
    readline(expected_file, l_ex);      -- read line 2 with comments
    readline(expected_file, l_ex);      -- read line 3 with x, y size
    read(l_ex, x_size_expected);
    read(l_ex, y_size_expected);
        if (x_size_expected /= x_size) or (y_size_expected /= y_size) then
            assert false
              report "FAILURE: image size of expected values does not match stimuli"
              severity failure;
          end if;
    readline(expected_file, l_ex);          -- read line 4 with maximum value
    readline(expected_file, l_ex);          -- read first line of image data

    while (end_tb /= 1) loop
      wait until falling_edge(clk);
      if (de_out = '1') then

        -- get response and write to response file
          r_sim := to_integer(unsigned(r_out));
          g_sim := to_integer(unsigned(g_out));
          b_sim := to_integer(unsigned(b_out));
        write(l_sim, r_sim);
        write (l_sim, string'(" "));
        write(l_sim, g_sim);
        write (l_sim, string'(" "));
        write(l_sim, b_sim);
        writeline(response_file, l_sim);

        if (y_pos > 2) then
          -- output of VHDL is shifted verticaly by three lines
          -- compensate by start reading expected image in line 3
          
            -- read expected response and compare to simulation response
            if l_ex'length < 2 then readline(expected_file, l_ex); end if; -- remaining line length might be one blank character
            read(l_ex, r_ex);
            read(l_ex, g_ex);
            read(l_ex, b_ex);
            if (x_pos > 2 and x_pos < x_size-3 and y_pos > 5) then
              -- do not check left, right and top edge of image
              if (r_sim /= r_ex) or (g_sim /= g_ex) or (b_sim /= b_ex) then
                mismatch <= mismatch + 1;
                assert false
                  report "MISMATCH in simulation at position x=" & integer'image(x_pos) & " y=" & integer'image(y_pos)
                  severity note;
              end if; -- simulation /= expected
            end if; -- do not check edge of image
        end if; -- y_pos >2

        x_pos := x_pos + 1;
        if x_pos = x_size then
          y_pos := y_pos + 1;
          x_pos := 0;
        end if;

      end if;
    end loop;

    file_close(response_file);
    file_close(expected_file);
    wait until (end_tb = 2); -- wait forever, because end_tb will not become 2

  end process;

end sim;
