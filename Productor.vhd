library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Productor is
    Port (
        piClk : in std_logic ;
        piRst : in std_logic ;
        piStart : in std_logic ;
        poDone : out std_logic ;
        poTx : out std_logic
    ) ;
end entity Productor ;

--Productor: modulo que transmite por un puerto serie los primeros 32 terminos de la serie
--de Fibonacci. Cada vez que se completa la transmision de un dato (numero) se lo indica
--con un pulso en poDone. Mediante el puerto piStart se indica que se comienza un ciclo de
--envios de la totalidad (32 x 4 bytes) de los datos.

architecture ArchProductor of Productor is

    type tConstTable is array(31 downto 0) of integer;
    type tState is (Reset, Transmitting, Idle);
    type tTransmitterState is (Idle, Processing);
    type tSerializer is (Idle, Processing);
    type tROM is array(integer(ceil(log2(real(32))))-1 downto 0) of std_logic_vector(31 downto 0);
    constant cFibonacci : tConstTable :=   (1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,
                                            1597,2584,4181,6765,10946,17711,28657,46368,75025,
                                            121393,196418,317811,514229,832040,1346269,2178309);
    signal sROM : tROM;
    
    signal sStartTx : std_logic;
    signal sTxDataInput : std_logic_vector(7 downto 0);
    signal sTxReady : std_logic;

    signal sWriteMultiByteIntoSerializer : std_logic;
    signal sSerializerInput : std_logic_vector(31 downto 0);
    signal sSerializerDataOutput : std_logic_vector(7 downto 0);
    signal sSerializerReadByte, sSerializerDataAvailable, sSerializerReady, sSerializerDone : std_logic;
    
    signal sStateCounter, sFutureStateCounter : std_logic_vector(integer(ceil(log2(real(32))))-1 downto 0);
    signal sTxCounter, sFutureTxCounter : std_logic_vector(integer(ceil(log2(real(4))))-1 downto 0);

    signal sState, sFutureState : tState;
    signal sTransmitterState, sFutureTransmitterState : tTransmitterState;
    signal sSerializerState, sFutureSerializerState : tSerializer;
    
    signal sDone : std_logic;
    
    component Uart_Tx
        Generic (
            BAUD_RATE_PRESCALLER : NATURAL := 3
        ) ;
        Port (
            piClk : in std_logic ;
            piRst : in std_logic ;
            piTxStart : in std_logic ;
            poTxReady : out std_logic ;
            piData : in std_logic_vector (8 -1 downto 0) ;
            poTx : out std_logic
        ) ;
    end component Uart_Tx ;

    component ByteSerializer
        Generic (
            DATA_WIDTH : natural;
            AMOUNT_IN : natural
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
    end component ByteSerializer ;

begin
    -- ROM Values
    identifier : for i in 0 to integer(ceil(log2(real(32))))-1 generate
        sROM(i) <= std_logic_vector(to_unsigned(cFibonacci(i), 32));
    end generate ; -- identifier

    uuart: Uart_Tx
    generic map (
        BAUD_RATE_PRESCALLER => 3
    )
    port map(
        piClk => piClk,
        piRst => piRst,
        piTxStart => sStartTx,
        poTxReady => sTxReady,
        piData => sTxDataInput,
        poTx => poTx
    );

    ubyteserializer: ByteSerializer
    generic map(
        DATA_WIDTH  => 8,
        AMOUNT_IN => 4
    )
    port map(
        piClk => piClk,
        piRst => piRst,
        piWriteMultiByte => sWriteMultiByteIntoSerializer,
        piData => sSerializerInput,
        piReadSingleByte => sSerializerReadByte,
        poData => sSerializerDataOutput,
        poDataAvailable => sSerializerDataAvailable,
        poReady => sSerializerReady,
        poDone => sSerializerDone
    );

    ffHandler : process(piClk)
    begin
        if rising_edge(piClk) then
            sStateCounter <= sFutureStateCounter;
            sState <= sFutureState;
            sTransmitterState <= sFutureTransmitterState;
            sSerializerState <= sFutureSerializerState;
            sTxCounter <= sFutureTxCounter;
        else
            sStateCounter <= sStateCounter;
            sState <= sState;
            sTransmitterState <= sTransmitterState;
            sSerializerState <= sSerializerState;
            sTxCounter <= sTxCounter;
        end if;
    end process ; -- ffHandler

    main : process(sStateCounter, sTxCounter, sState, sTransmitterState, sSerializerState,
     sSerializerReadByte, sStartTx, sSerializerInput, sDone, piRst, sROM, sSerializerDataAvailable,
     sTxReady, sSerializerDone, sSerializerReady, piStart)
    begin
        sFutureStateCounter <= sStateCounter;
        sFutureTxCounter <= sTxCounter;
        
        sFutureState <= sState;    
        sFutureTransmitterState <= sTransmitterState;
        sFutureSerializerState <= sSerializerState;

        sSerializerReadByte <= '0';
        sWriteMultiByteIntoSerializer <= '0';
        sStartTx <= '0';
        sSerializerInput <= sROM(to_integer(unsigned(sStateCounter)));
        sDone <= '0'; 
        
        if(piRst = '1') then
            sFutureState <= Reset;
            sFutureStateCounter <= (others => '0');
        else 
            case( sState ) is
                when Reset =>
                    sFutureState <= Idle;
                    sFutureTransmitterState <= Idle;
                    sFutureSerializerState <= Idle;
                    sFutureStateCounter <= (others => '0');
                    sFutureTxCounter <= (others => '0');
                when Transmitting =>
                    case(sTransmitterState) is
                        when Idle =>
                            if(sSerializerDataAvailable = '1' and sTxReady = '1') then
                                sSerializerReadByte <= '1';
                                sStartTx <= '1';
                                sFutureTransmitterState <= Processing;
                            end if;
                        when Processing =>
                            if(sTxReady = '1') then
                                sFutureTransmitterState <= Idle;
                                if(sTxCounter = std_logic_vector(to_unsigned(4-1,sTxCounter'length))) then
                                    sFutureTxCounter <= (others => '0');
                                    sFutureStateCounter <= std_logic_vector(unsigned(sStateCounter) + to_unsigned(1, sStateCounter'length));
                                else 
                                    sFutureTxCounter <= std_logic_vector(unsigned(sTxCounter) + to_unsigned(1, sTxCounter'length));
                                end if;
                            end if;
                    end case ;
                    case(sSerializerState) is
                        when Processing =>
                            if(sSerializerDone = '1') then
                                sFutureSerializerState <= Idle;
                            end if;
                        when Idle =>
                            if(sStateCounter = std_logic_vector(to_unsigned(31,sStateCounter'length))) then
                                sFutureState <= Idle;
                                sDone <= '1';
                                sFutureStateCounter <= (others => '0');
                            elsif(sSerializerReady = '1') then
                                sWriteMultiByteIntoSerializer <= '1';
                                sFutureSerializerState <= Processing;
                            else 
                                sSerializerInput <= (others => '0');
                                sWriteMultiByteIntoSerializer <= '0';
                            end if;
                    end case ;
                when Idle =>                    
                    if(piStart = '1') then
                        sFutureState <= Transmitting;
                        sFutureStateCounter <= (others => '0');
                    end if;
            end case;
        end if;
    end process ; -- main
    sTxDataInput <= sSerializerDataOutput;
    poDone <= sDone;
end ArchProductor ; -- ArchProductor