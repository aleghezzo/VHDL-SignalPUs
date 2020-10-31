entity FiFo is
    Generic (
    FIFO_DEPTH : NATURAL := 4;
    DATA_WIDTH : NATURAL := 8
    ) ;
    Port (
    piClk : in STD_LOGIC ;
    piRst : in STD_LOGIC ;
    piWr : in STD_LOGIC ;
    piData : in STD_LOGIC_VECTOR ( DATA_WIDTH -1 downto 0) ;
    poFull : out STD_LOGIC ;
    piRd : in STD_LOGIC ;
    poData : out STD_LOGIC_VECTOR ( DATA_WIDTH -1 downto 0) ;
    poEmpty : out STD_LOGIC
    ) ;
    end entity FiFo ;

architecture ArchFiFo of FiFo is

    signal 

begin

end ArchFiFo ; -- ArchFiFo