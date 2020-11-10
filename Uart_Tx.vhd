library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity Uart_Tx is
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
end entity Uart_Tx ;

architecture ArchUart_Tx of Uart_Tx is

    component SimpleCounterWithTc
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
    end component SimpleCounterWithTc;

    type tState is (Idle, Transmitting);
    type tTransmissionState is (Start, Payload, Ending);
    signal sState, sFutureState : tState;
    signal sTransmissionState, sFutureTransmissionState : tTransmissionState;
    signal sStoredData, sFutureStoredData : std_logic_vector(7 downto 0);
    signal sEnablePrescaler, sPrescalerTc : std_logic;
    signal sTransmitting : std_logic;
    signal sTransmissionCounter : std_logic_vector(piData'length downto 0);
    constant cLINE_IDLE : std_logic := '1';
    constant cLINE_START : std_logic := '0';
    constant cLINE_END : std_logic := '1';
    
begin

    uPrescaler : SimpleCounterWithTc
    generic map ( 
        MODULE => BAUD_RATE_PRESCALLER,
        DATA_WIDTH => integer(ceil(log2(real(BAUD_RATE_PRESCALLER))))
    )
    port map (
        piClk => piClk,
        piRst => piRst,
        piEna => sEnablePrescaler,
        poQ => open,
        poTc => sPrescalerTc
    );

    clk : process( piClk )
    begin
        if rising_edge(piClk) then
            sState <= sFutureState;
            sStoredData <= sFutureStoredData;
            sTransmissionState <= sFutureTransmissionState; 
        else
            sState <= sState;
        end if;
    end process ; -- main

    main : process( piRst, piTxStart, sState, sFutureState, sStoredData, sTransmissionState, sTransmissionCounter, sPrescalerTc, piData )
    begin
        sFutureState <= sState;
        sFutureTransmissionState <= sTransmissionState;
        sFutureStoredData <= sStoredData;
        sTransmitting <= cLINE_IDLE;
        poTxReady <= '0';
        sEnablePrescaler <= '0';
        if(piRst = '1') then
            sFutureState <= Idle;
            sFutureStoredData <= (others => '0');
            sTransmissionState <= Start;
        else
            case( sState ) is
                when Idle =>
                    poTxReady <= '1';
                    if (piTxStart = '1') then
                        sFutureStoredData <= piData;
                        sFutureState <= Transmitting;
                    else 
                        sFutureState <= Idle;
                    end if;
                when Transmitting =>
                    sEnablePrescaler <= '1';
                    case( sTransmissionState ) is
                        when Start =>
                            sTransmitting <= cLINE_START;
                            sFutureTransmissionState <= Payload;
                        when Payload =>
                            sTransmitting <= sStoredData(to_integer(unsigned(sTransmissionCounter)));
                            if(sPrescalerTc = '1') then
                                sTransmissionCounter <= std_logic_vector(unsigned(sTransmissionCounter) + to_unsigned(1, sTransmissionCounter'length));
                            end if;
                            if(sTransmissionCounter = std_logic_vector(to_unsigned(sStoredData'length, sTransmissionCounter'length))) then
                                sFutureTransmissionState <= Ending;
                            end if;
                        when Ending =>
                            if(piTxStart = '1') then
                                sFutureState <= Transmitting;
                            else 
                                sFutureState <= Idle;
                            end if;
                            sTransmitting <= cLINE_END;
                            sFutureTransmissionState <= Start;
                        when others =>
                            sFutureState <= Idle;
                            sTransmissionState <= Start;
                    end case ;
                when others =>
                    sFutureState <= Idle;
                    sTransmissionState <= Start;
            end case ;
        end if;
    end process ; -- main
    poTx <= sTransmitting;

end ArchUart_Tx ; -- arch