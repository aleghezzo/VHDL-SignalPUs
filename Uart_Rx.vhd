library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity Uart_Rx is
    Generic (
        BAUD_RATE_PRESCALLER : NATURAL:= 3
    ) ;
    Port (
        piClk : in std_logic ;
        piRst : in std_logic ;
        poRxAvailable : out std_logic ;
        poData : out std_logic_vector (8 -1 downto 0) ;
        piRx : in std_logic
    ) ;
end entity Uart_Rx ;

architecture ArchUart_Rx of Uart_Rx is

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

    type tState is (Idle, Receiving);
    type tTransmissionState is (Start, Payload, Ending);
    signal sState, sFutureState : tState;
    signal sReceptionState, sFutureReceptionState : tTransmissionState;
    signal sStoredData, sFutureStoredData : std_logic_vector(7 downto 0);
    signal sEnablePrescaler, sPrescalerTc : std_logic;
    signal sReceiving : std_logic;
    signal sReceptionCounter, sFutureReceptionCounter : std_logic_vector(poData'length-1 downto 0);
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
            sReceptionState <= sFutureReceptionState;
            sReceptionCounter <= sFutureReceptionCounter;
        else
            sState <= sState;
        end if;
    end process ; -- main

    main : process(all)
    begin
        sFutureState <= sState;
        sFutureReceptionState <= sReceptionState;
        sFutureStoredData <= sStoredData;
        sEnablePrescaler <= '0';
        poRxAvailable <= '0';
        sFutureReceptionCounter <= sReceptionCounter;
        if(piRst = '1') then
            sFutureState <= Idle;
            sFutureStoredData <= (others => '0');
            sFutureReceptionState <= Start;
            sFutureReceptionCounter <= (others => '0');
        else
            case( sState ) is
                when Idle =>
                    poRxAvailable <= '1';
                    if(piRx = cLINE_START) then
                        sFutureState <= Receiving;
                    end if;
                when Receiving =>
                    poRxAvailable <= '0';
                    sEnablePrescaler <= '1';
                    case(sReceptionState) is
                        when Start =>
                            sFutureReceptionCounter <= (others => '0');
                            if(sPrescalerTc = '1') then
                                sFutureReceptionState <= Payload;
                            end if;
                            sFutureReceptionState <= Payload;
                        when Payload =>
                            if(sPrescalerTc = '1') then
                                sFutureReceptionCounter <= std_logic_vector(unsigned(sReceptionCounter) + to_unsigned(1, sReceptionCounter'length));
                                sFutureStoredData(to_integer(unsigned(sReceptionCounter))) <= piRx;
                            end if;
                            if(sReceptionCounter = std_logic_vector(to_unsigned(sStoredData'length, sReceptionCounter'length))) then
                                sFutureReceptionState <= Ending;
                            end if;
                        when Ending =>
                            if(sPrescalerTc = '1' and piRx = cLINE_END) then
                                sFutureState <= Idle;
                                sFutureReceptionState <= Start;
                            end if;
                        when others =>
                            sFutureState <= Idle;
                            sFutureReceptionState <= Start;
                    end case;
                when others =>
                    sFutureState <= Idle;
                    sReceptionState <= Start;
            end case ;
        end if;
    end process ; -- main
    sReceiving <= piRx;
    poData <= sStoredData;

end ArchUart_Rx ; -- arch