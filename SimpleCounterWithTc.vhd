library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity SimpleCounterWithTc is
    Generic(
        DATA_WIDTH : natural := 7;
        MODULE : natural := 7
    );
    Port (
        piClk : in std_logic ;
        piRst : in std_logic ;
        piEna : in std_logic ;
        poQ : out std_logic_vector (DATA_WIDTH-1 downto 0);
        poTc : out std_logic
    ) ;
end SimpleCounterWithTc;

architecture ArchSimpleCounterWithTc of SimpleCounterWithTc is

    signal sRegisters : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    main : process(piClk, piEna)
    begin
        if(rising_edge(piClk)) then
            if(piRst = '1') then
                sRegisters <= (others => '0');
            elsif(piEna = '1') then
                if(unsigned(sRegisters) = to_unsigned(MODULE, sRegisters'length)) then 
                    sRegisters <= (others => '0');
                else
                    sRegisters <= std_logic_vector(unsigned(sRegisters) + to_unsigned(1, sRegisters'length));
                end if;
            else
                sRegisters <= sRegisters;
            end if;
        end if;
    end process ; -- main
    poQ <= sRegisters;
    poTc <= '1' when unsigned(sRegisters) = to_unsigned(MODULE, sRegisters'length) else '0';

end ArchSimpleCounterWithTc ; -- SimpleCounterWithTc