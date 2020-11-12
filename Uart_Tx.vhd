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
        piData : in std_logic_vector (8-1 downto 0) ;
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
    signal sTransmitting,sRstPrescaler : std_logic;
    signal sTransmissionCounter, sFutureTransmissionCounter : std_logic_vector(piData'length downto 0);
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
        piRst => sRstPrescaler,
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
            sTransmissionCounter <= sFutureTransmissionCounter;
        else
            sState <= sState;
            sStoredData <= sStoredData;
            sTransmissionState <= sTransmissionState; 
            sTransmissionCounter <= sTransmissionCounter;
        end if;
    end process ; -- main

    main : process( piRst, piTxStart, sState, sFutureState, sStoredData, sTransmissionState, sFutureTransmissionCounter ,sTransmissionCounter, sPrescalerTc, piData )
    begin
        sFutureState <= sState;
        sFutureTransmissionState <= sTransmissionState;
        sFutureTransmissionCounter <= sTransmissionCounter;
        sFutureStoredData <= sStoredData;
        sTransmitting <= cLINE_IDLE;
        poTxReady <= '0';
        sEnablePrescaler <= '0';
        sRstPrescaler <= '0';
        if(piRst = '1') then
            sFutureStoredData <= (others => '0');
            sFutureTransmissionCounter <= (others => '0');
            sFutureState <= Idle;
            sFutureTransmissionState <= Start;
        else
            case( sState ) is
                when Idle =>
                    poTxReady <= '1';
                    sRstPrescaler <= '1';
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
                            if(sPrescalerTc = '1') then
                                sFutureTransmissionState <= Payload;
                            end if;
                        when Payload =>
                            sTransmitting <= sStoredData(to_integer(unsigned(sTransmissionCounter)));
                            if(sPrescalerTc = '1') then
                                sFutureTransmissionCounter <= std_logic_vector(unsigned(sTransmissionCounter) + to_unsigned(1, sTransmissionCounter'length));
                            end if;
                            if(sTransmissionCounter = std_logic_vector(to_unsigned(sStoredData'length-1, sTransmissionCounter'length))) then
                                sFutureTransmissionState <= Ending;
                            end if;
                        when Ending =>
                            sFutureTransmissionCounter <= (others => '0');
                            sTransmitting <= cLINE_END;
                            if(sPrescalerTc = '1') then
                                sEnablePrescaler <= '0';
                                sRstPrescaler <= '0';
                                sFutureState <= Idle;
                                sFutureTransmissionState <= Start;
                            end if;
                        when others =>
                            sFutureState <= Idle;
                            sFutureTransmissionState <= Start;
                    end case ;
            end case ;
        end if;
    end process ; -- main
    poTx <= sTransmitting;

end ArchUart_Tx ; -- arch