entity ByteSerializer is
    Generic (
        DATA_WIDTH : natural := 8,
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
        poDataAvailable : out STD_LOGIC
        poReady : out STD_LOGIC ;
        poDone : out STD_LOGIC
    ) ;
end entity ByteSerializer ;

architecture ArchByteSerializer of ByteSerializer is

    type tRegisters is array(AMOUNT_IN-1 downto 0) of std_logic_vector(DATA_WIDTH downto 0);
    signal sRegisters, sFutureRegisters : tRegisters;
    signal sStateCounter, sFutureStateCounter : unsigned(ceil(log2(2**(FIFO_DEPTH+2)))-1 downto 0) := (others => '0');
    signal sReady, sDone, sDataAvailable : std_logic;

begin

    clkProcess : process(piClk)
    begin
        if rising_edge(piClk)
            sStateCounter <= sFutureStateCounter;
            registerLoop : for i in sRegisters'range loop
                sRegister(i) <= sFutureRegisters(i)
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
                sFutureRegisters <= piData;
                sFutureStateCounter <= to_unsigned(AMOUNT_IN,sFutureStateCounter'length);
            elsif(piReadSingleByte = '1' and sDataAvailable = '1') then
                sFutureStateCounter <= sStateCounter - to_unsigned(1,sStateCounter'length);
                sFutureRegisters <= sRegisters;
            elsif
                sFutureStateCounter <= stateCounter;
                sFutureRegisters <= sRegisters;
            end if;
        end if;
    end process ; -- main

    sReady <= '1' when not(sCounter = to_unsigned(AMOUNT_IN-1,sCounter'length)) else '0' when others;
    sDataAvailable <= '1' when sCounter > to_unsigned(0,sCounter'length) else '0' when others;
    sDone <= '1' when sCounter = to_unsigned(0,sCounter'length) else '0' when others;
    poDataAvailable <= sDataAvailable;
    poData <= sRegister(sCounter);
    
end ArchByteSerializer ; -- ArchByteSerializer