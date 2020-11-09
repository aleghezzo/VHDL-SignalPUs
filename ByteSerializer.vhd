library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity ByteSerializer is
    Generic (
        DATA_WIDTH : natural := 8;
        AMOUNT_IN : natural := 4
    );
    Port
    (
        piClk : in STD_LOGIC ;
        piRst : in STD_LOGIC ;

        piWriteMultiByte : in STD_LOGIC ;
        piData : in STD_LOGIC_VECTOR (AMOUNT_IN*DATA_WIDTH -1 downto 0) ;
        piReadSingleByte : in STD_LOGIC ;
        
        poData : out STD_LOGIC_VECTOR (DATA_WIDTH -1 downto 0) ;
        poDataAvailable : out STD_LOGIC;
        poReady : out STD_LOGIC ;
        poDone : out STD_LOGIC
    ) ;
end entity ByteSerializer ;

architecture ArchByteSerializer of ByteSerializer is

    type tRegisters is array(AMOUNT_IN-1 downto 0) of std_logic_vector(DATA_WIDTH downto 0);
    signal sRegisters, sFutureRegisters : tRegisters;
    signal sStateCounter, sFutureStateCounter : unsigned(integer(ceil(log2(real(AMOUNT_IN)))) - 1 downto 0);
    signal sReady, sDone, sDataAvailable : std_logic;

begin

    clkProcess : process(piClk)
    begin
        if rising_edge(piClk) then
            sStateCounter <= sFutureStateCounter;
            registerLoop : for i in sRegisters'range loop
                sRegisters(i) <= sFutureRegisters(i);
            end loop ;
        end if;
    end process ; -- clkProcess

    main : process(piRst, piWriteMultiByte, piData, piReadSingleByte)
    begin
        if(piRst = '1') then
            sFutureStateCounter <= (others => '0');
            registerLoop : for i in sRegisters'range loop
                sFutureRegisters(i) <= (others => '0');
            end loop ;
        else
            if(piWriteMultiByte = '1' and sDone = '1') then
                for i in 0 to AMOUNT_IN loop
                    sFutureRegisters(i) <= piData((DATA_WIDTH*(i+1) - 1) downto DATA_WIDTH*i);
                end loop;
                sFutureStateCounter <= to_unsigned(AMOUNT_IN,sFutureStateCounter'length);
            elsif(piReadSingleByte = '1' and sDataAvailable = '1') then
                sFutureStateCounter <= sStateCounter - to_unsigned(1,sStateCounter'length);
                sFutureRegisters <= sRegisters;
            else
                sFutureStateCounter <= sStateCounter;
                sFutureRegisters <= sRegisters;
            end if;
        end if;
    end process ; -- main

    sReady <= '1' when not(sStateCounter = to_unsigned(AMOUNT_IN-1,sStateCounter 'length)) else '0';
    sDataAvailable <= '1' when sStateCounter  > to_unsigned(0,sStateCounter 'length) else '0';
    sDone <= '1' when sStateCounter  = to_unsigned(0,sStateCounter 'length) else '0';
    poDataAvailable <= sDataAvailable;
    poData <= sRegisters(to_integer(sStateCounter));
    
end ArchByteSerializer ; -- ArchByteSerializer