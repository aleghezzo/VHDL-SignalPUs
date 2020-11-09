library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_FMS_Ctrl is
    Generic (
        DATA_WIDTH : natural := 7;
        ADDR_WIDTH : natural := 4
    );
end tb_FMS_Ctrl;

architecture Arch_tb_FMS_Ctrl of tb_FMS_Ctrl is

    signal tb_Clk, tb_Rst, tb_Start, tb_Done : std_logic := '0';
    signal tb_Sum : std_logic_vector(15 downto 0) := (others => '0');
    
    component FSM_Ctrl is 
    Generic (
        DATA_WIDTH : natural;
        ADDR_WIDTH : natural
    );
    Port (
        piClk : in STD_LOGIC ;
        piRst : in STD_LOGIC ;
        piStart : in STD_LOGIC ;
        poDone : out STD_LOGIC ;
        poSum : out STD_LOGIC_VECTOR (16 -1 downto 0)
    ) ;
    end component;
begin

    uut: FSM_Ctrl
    generic map(
       DATA_WIDTH => DATA_WIDTH,
       ADDR_WIDTH => ADDR_WIDTH
    )
    port map(
       piClk => tb_Clk,
       piRst => tb_Rst,
       piStart => tb_Start,
       poDone => tb_Done,
       poSum => tb_Sum
    );

   clk : process
    begin
      tb_Clk <= not(tb_Clk);
      wait for 1 ns;
   end process;
   
   main: process
   begin
      tb_Rst <= '1';
      wait for 2 ns;
      tb_Rst <= '0';
      wait for 5 ns;
      wait for 20 ns;
      tb_Start <= '1';
      wait for 1 ns;
      tb_Start <= '0';
      wait for 100 ns;
      tb_Start <= '1';
      wait for 2 ns;
      tb_Start <= '0';
      wait for 100 ns;
      wait for 100 ns;
      wait for 100 ns;
      assert false
      report "Simulation completed"
      severity failure;
   end process;

end Arch_tb_FMS_Ctrl;
