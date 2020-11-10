entity Uart_Rx is
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
end entity Uart_Rx ;

architecture ArchUart_Rx of Uart_Rx is

    signal 

begin

end ArchUart_Rx ; -- ArchUart_Rx|