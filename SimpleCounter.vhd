library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity SimpleCounter is
    Generic(DATA_WIDTH : natural := 7);
    Port (
        piClk : in STD_LOGIC ;
        piRst : in STD_LOGIC ;
        piEna : in STD_LOGIC ;
        poQ : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)
    ) ;
end SimpleCounter;

architecture ArchSimpleCounter of SimpleCounter is

    signal sRegisters : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    main : process(piClk, piEna)
    begin
        if(rising_edge(piClk)) then
            if(piRst = '1') then
                sRegisters <= (others => '0');
            elsif(piEna = '1') then
                sRegisters <= std_logic_vector(unsigned(sRegisters) + to_unsigned(1, sRegisters'length));
            else
                sRegisters <= sRegisters;
            end if;
        end if;
    end process ; -- main
    poQ <= sRegisters;
end ArchSimpleCounter ; -- SimpleCounter