library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Consumidor is
    Port (
        piClk : in std_logic ;
        piRst : in std_logic ;
        poDone : out std_logic ;
        poData : out std_logic_vector (32 -1 downto 0) ;
        piRx : in std_logic
    );
end entity Consumidor ;

-- Consumidor: modulo que recibe lo enviando por el transmisor y recupera los numeros de la
-- serie. Cada vez que recupera un numero lo saca por su puerto de datos y lo indica mediante
-- un pulso en poDone

architecture ArchConsumidor of Consumidor is
    
    component Uart_Rx is
        Generic (
            BAUD_RATE_PRESCALLER : NATURAL
        ) ;
        Port (
            piClk : in std_logic ;
            piRst : in std_logic ;
            poRxAvailable : out std_logic ;
            poData : out std_logic_vector (8 -1 downto 0) ;
            piRx : in std_logic
        ) ;
    end component Uart_Rx;

    component ByteDeSerializer is
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
    end component ByteDeSerializer ;

    signal sRxAvailable, sRxDataOut, sRxInput : std_logic;
    signal sWriteSingleByteIntoDeserializer, sDeserializerReadMultiByte, sRxInput : std_logic;
    signal sDeserializerInput : std_logic_vector(7 downto 0);

    
begin

    uuartrx: Uart_Rx 
    generic map (
        BAUD_RATE_PRESCALLER : NATURAL
    )
    port map (
        piClk => piClk,
        piRst => piRst,
        poRxAvailable => sRxAvailable,
        poData => sRxDataOut,
        piRx => sRxInput
    );

    ubytedeserializer: Uart_Rx 
    generic map (
        DATA_WIDTH => 8
        AMOUNT_IN => 4
    )
    port map (
        piClk => piClk,
        piRst => piRst,
        piWriteSingleByte => sWriteSingleByteIntoDeserializer;
        piData => sDeserializerInput;
        piReadMultiByte => sDeserializerReadMultiByte
        poReady => sDeserializerReady;
        poData => sDeserializerOutput;
        poDataAvailable => sDeserializerDataAvailable
    );

    ffHandler : process(piClk)
    begin
        if rising_edge(piClk) then
            sStateCounter <= sFutureStateCounter;
            sState <= sFutureState;
            sRxCounter <= sFutureRxCounter;
        else
            sStateCounter <= sStateCounter;
            sState <= sState;
            sReceptorState <= sReceptorState;
            sDeserializerState <= sDeserializerState;
            sRxCounter <= sRxCounter;
        end if;
    end process ; -- ffHandler

    main : process( all )
   begin
    sDone <= '0'; 
    sWriteSingleByteIntoDeserializer <= '0';
    sDeserializerReadMultiByte <= '0'; 
    if(sDeserializerDataAvailable = '1') then
        sDeserializerReadMultiByte <= '1';
    end if;
    if(sRxAvailable = '1') then
        piWriteSingleByte = '1';
    end if;
   end process ; -- main
   sDeserializerInput <= sRxDataOut;
   poDone <= sDone;
   poData <= sDeserializerOutput;
end ArchConsumidor ; -- ArchProductor
