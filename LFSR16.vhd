library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity LFSR16 is
    Port (
        piClk : in STD_LOGIC ;
        piRst : in STD_LOGIC ;
        piEna : in STD_LOGIC ;
        piLoadSeed : in STD_LOGIC ;
        piSeed : in STD_LOGIC_VECTOR (16 -1 downto 0) ;
        poQ : out STD_LOGIC_VECTOR (16 -1 downto 0)
    ) ;
end entity LFSR16 ;

architecture ArchLFSR16 of LFSR16 is

    signal sRegs, sFutureRegs : std_logic_vector(15 downto 0);

begin

    main : process(piClk)
    begin
        if(rising_edge(piClk)) then
            if(piRst = '1') then
                sRegs <= (others => '0');
            elsif(piLoadSeed = '1') then
                sRegs <= piSeed; 
            elsif(piEna = '1') then
                sRegs <= sFutureRegs;
            else
                sRegs <= sRegs;
            end if;
        end if;
    end process ; -- main

    ffConnection : for i in 1 to 15 generate
        sFutureRegs(i) <= sRegs(i - 1);
    end generate ; -- ffConnection
    sFutureRegs(0) <= sRegs(10) xor sRegs(12) xor sRegs(13) xor sRegs(15);
    poQ <= sRegs;

end ArchLFSR16 ; -- ArchLFSR16ss
