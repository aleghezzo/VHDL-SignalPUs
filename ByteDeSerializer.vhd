library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity ByteDeSerializer is
    Generic (
        DATA_WIDTH : natural := 8;
        AMOUNT_IN : natural := 4
    );
    Port (
        piClk : in STD_LOGIC ;
        piRst : in STD_LOGIC ;
        piWriteSingleByte : in STD_LOGIC ;
        piData : in STD_LOGIC_VECTOR (8 -1 downto 0) ;
        piReadMultiByte : in STD_LOGIC ;
        poReady : out STD_LOGIC ;
        poData : out STD_LOGIC_VECTOR (4*8 -1 downto 0) ;
        poDataAvailable : out STD_LOGIC
    );
end entity ByteDeSerializer ;

architecture ArchByteDeSerializer of ByteDeSerializer is

    type tRegisters is array(AMOUNT_IN-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sRegisters, sFutureRegisters : tRegisters;
    signal sStateCounter, sFutureStateCounter : unsigned(1 downto 0); --integer(ceil(log2(real(AMOUNT_IN)))) - 1
    signal sReady, sDone, sDataAvailable : std_logic;
    signal sOutputCombination : std_logic_vector(AMOUNT_IN*DATA_WIDTH -1 downto 0);
    begin

        clkProcess : process(piClk)
        begin
            if rising_edge(piClk) then
                sStateCounter <= sFutureStateCounter;
                registerLoop : for i in sRegisters'range loop
                    sRegisters(i) <= sFutureRegisters(i);
                end loop;
            end if;
        end process ; -- clkProcess
    
        main : process(all)
        begin
            sFutureStateCounter <= sStateCounter;
            sFutureRegisters <= sRegisters; 
            if(piRst = '1') then
                sFutureStateCounter <= (others => '0');
                registerLoop : for i in sRegisters'range loop
                    sFutureRegisters(i) <= (others => '0');
                end loop ;
            else
                if(sDone = '1') then
                    if(piReadMultiByte = '1') then
                       sFutureStateCounter <= (others => '0');
                    end if;
                else 
                    if(piWriteSingleByte = '1' and sReady = '1') then
                        sFutureRegisters(to_integer(sStateCounter)) <= piData;
                        sFutureStateCounter <= sStateCounter + to_unsigned(1, sStateCounter'length);
                    end if;
                end if;
            end if;
        end process ; -- main
    
        Combination : for i in 0 to AMOUNT_IN-1 generate
            sOutputCombination((DATA_WIDTH*(i+1) - 1) downto DATA_WIDTH*i) <= sRegisters(i);
        end generate;
        sDone <= not(sDataAvailable);
        sReady <= '1' when not(sStateCounter = to_unsigned(AMOUNT_IN-1,sStateCounter'length)) else '0';
        sDataAvailable <= '1' when (sStateCounter = to_unsigned(AMOUNT_IN-1, sStateCounter'length)) else '0';
        poDataAvailable <= sDataAvailable;
        poReady <= sReady;
        poData <= sOutputCombination;

end ArchByteDeSerializer ; -- ArchByteDeSerializer