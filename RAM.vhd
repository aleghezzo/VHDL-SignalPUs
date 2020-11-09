library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity RAM is
  generic(
      ADDR_WIDTH : natural := 7;
      DATA_WIDTH : natural := 16
  );
    port (
    piClk : in std_logic;
    piWr : in std_logic;
    piAddr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    piData : in std_logic_vector(DATA_WIDTH-1 downto 0);    
    poData : out std_logic_vector(DATA_WIDTH-1 downto 0)
  ) ;
end RAM;

architecture ArchRAM of RAM is

    type tRAM is array(2**ADDR_WIDTH-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal RAM : tRAM;

begin

    process(piClk)
    begin
        if rising_edge(piClk) then
            if piWr = '1' then
                RAM(to_integer(unsigned(piAddr))) <= piData;
            else
                poData <= RAM(to_integer(unsigned(piAddr)));
            end if;
        end if;
    end process;

end ArchRAM ; -- ArchRAM
