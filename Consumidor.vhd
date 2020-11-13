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
            BAUD_RATE_PRESCALLER : NATURAL := 3
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

    signal sRxAvailable, sRxInput, sDeserializerReady, sDeserializerDataAvailable, sDone : std_logic;
    signal sWriteSingleByteIntoDeserializer, sDeserializerReadMultiByte, sMissedByte : std_logic;
    signal sDeserializerInput, sRxDataOut, sFutureBuffer, sBuffer : std_logic_vector(7 downto 0);
    signal sDeserializerOutput: std_logic_vector(31 downto 0);
    
    type tState is (Ready, Busy);
    signal sState, sFutureState : tState;
    
begin

    uuartrx: Uart_Rx 
    generic map (
        BAUD_RATE_PRESCALLER => 3
    )
    port map (
        piClk => piClk,
        piRst => piRst,
        poRxAvailable => sRxAvailable,
        poData => sRxDataOut,
        piRx => sRxInput
    );

    ubytedeserializer: ByteDeSerializer 
    generic map (
        DATA_WIDTH => 8,
        AMOUNT_IN => 4
    )
    port map (
        piClk => piClk,
        piRst => piRst,
        piWriteSingleByte => sWriteSingleByteIntoDeserializer,
        piData => sDeserializerInput,
        piReadMultiByte => sDeserializerReadMultiByte,
        poReady => sDeserializerReady,
        poData => sDeserializerOutput,
        poDataAvailable => sDeserializerDataAvailable
    );

    ffHandler : process(piClk)
    begin
        if rising_edge(piClk) then
            sState <= sFutureState;
            sBuffer <= sFutureBuffer;
        else
            sState <= sState;
            sBuffer <= sBuffer;
        end if;
    end process ; -- ffHandler

    main : process( all )
    begin
    sDone <= '0'; 
    sWriteSingleByteIntoDeserializer <= '0';
    sDeserializerReadMultiByte <= '0'; 
    sFutureState <= Ready when sDeserializerReady = '1' else Busy;
    sFutureBuffer <= sBuffer; 
    sMissedByte <= '0';
    case(sState) is
      when Ready =>
        if(sRxAvailable = '1' or sMissedByte = '1') then
          sWriteSingleByteIntoDeserializer <= '1';
        end if;
      when Busy =>
         if (sRxAvailable = '1') then
            sFutureBuffer <= sRxDataOut;
            sMissedByte <= '1';
         end if;
    end case;
    
    if(sDeserializerDataAvailable = '1') then
        sDeserializerReadMultiByte <= '1';
        sDone <= '1';
    end if;
        
   end process ; -- main
   sDeserializerInput <= sRxDataOut when sMissedByte = '0' else sBuffer;
   poDone <= sDone;
   poData <= sDeserializerOutput;
   sRxInput <= piRx;
end ArchConsumidor ; -- ArchProductor
