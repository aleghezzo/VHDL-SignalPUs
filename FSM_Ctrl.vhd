library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity FSM_Ctrl is
Generic (
    DATA_WIDTH : natural := 7;
    ADDR_WIDTH : natural := 16
);
Port (
    piClk : in STD_LOGIC ;
    piRst : in STD_LOGIC ;
    piStart : in STD_LOGIC ;
    poDone : in STD_LOGIC ;
    poSum : out STD_LOGIC_VECTOR (16 -1 downto 0)
) ;
end entity FSM_Ctrl;

architecture ArchFSM_Ctrl of FSM_Ctrl is

    signal sWritingInRAM, sFutureWritingInRAM : std_logic;
    signal sWritingInRAMAddress, sFutureWritingInRAMAddress : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal sWritingInRAMData, sFutureWritingInRAMData  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sRAMOutputData : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sWritingInLFSR : std_logic; 
    signal sLFSREnabled : std_logic;
    signal sLFSRLoadSeed : std_logic;
    signal sLFSRSeed : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sLFSROut : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sSum : std_logic_vector(poSum'length - 1 downto 0);

    type tState is (Init, Idle, Resetting, Summing);
    signal sState, sFutureState : tState;

    component RAM is
        generic(
            ADDR_WIDTH : natural;
            DATA_WIDTH : natural
        );
          port (
            piClk : in std_logic;
            piWr : in std_logic;
            piAddr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            piData : in std_logic_vector(DATA_WIDTH-1 downto 0);    
            poData : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component RAM;

    component LFSR16 is
        Port (
            piClk : in STD_LOGIC ;
            piRst : in STD_LOGIC ;
            piEna : in STD_LOGIC ;
            piLoadSeed : in STD_LOGIC ;
            piSeed : in STD_LOGIC_VECTOR (16 -1 downto 0) ;
            poQ : out STD_LOGIC_VECTOR (16 -1 downto 0)
        );
    end component LFSR16 ;

    component SimpleCounter is
        Generic(DATA_WIDTH : natural);
        Port (
            piClk : in STD_LOGIC ;
            piRst : in STD_LOGIC ;
            piEna : in STD_LOGIC ;
            poQ : out STD_LOGIC_VECTOR(DATA_WIDTH -1 downto 0)
        ) ;
    end component SimpleCounter;
    constant useCounter : std_logic := '1';
begin
    
    uram : RAM 
    generic map(ADDR_WIDTH => ADDR_WIDTH, DATA_WIDTH => DATA_WIDTH)    
    port map(
        piClk => piClk,
        piWr => sWritingInRAM,
        piAddr => sWritingInRAMAddress,
        piData => sWritingInRAMData,
        poData => sRAMOutputData
    );
    flag : if useCounter = '0' generate
        ulfsr16 : LFSR16
        port map(
            piClk => piClk,
            piRst => piRst,
            piEna => sLFSREnabled,
            piLoadSeed => sLFSRLoadSeed,
            piSeed => sLFSRSeed,
            poQ => sLFSROut
        );
    end generate flag;
    flag2: if useCounter = '1' generate
        usimplecounter : SimpleCounter
        generic map(DATA_WIDTH  => DATA_WIDTH)
        port map(
            piClk => piClk,
            piRst => piRst,
            piEna => sLFSREnabled,
            poQ => sLFSROut
        );  
    end generate flag2;

    main : process(piClk)
    begin
        if (rising_edge(piClk)) then
            sState <= sFutureState;
            sWritingInRAMAddress <= sFutureWritingInRAMAddress;
            sWritingInRAMData <= sFutureWritingInRAMData;
            sWritingInRAM <= sFutureWritingInRAM;
        end if;
    end process ; -- main

    sFutureStateHandler : process( piRst, sState, sWritingInRAMAddress, sFutureWritingInRAMAddress, piStart, sLFSROut )
    begin
        if(piRst = '1') then
            sFutureState <= Resetting;
            sFutureWritingInRAM <= '1';
            sFutureWritingInRAMData <= (others => '0'); 
            sFutureWritingInRAMAddress <= (others => '0');
            sFutureState <= Resetting;
            sLFSREnabled <= '0';
        else
            case(sState) is
                when Resetting =>
                    if(sWritingInRAMAddress = std_logic_vector(to_unsigned(2**DATA_WIDTH-1,DATA_WIDTH))) then
                        sFutureWritingInRAM <= '1';
                        sFutureWritingInRAMAddress <= (others => '0');
                        sFutureState <= Init;
                    else
                        sFutureWritingInRAM <= '1';
                        sFutureWritingInRAMAddress <= std_logic_vector(unsigned(sFutureWritingInRAMAddress) + to_unsigned(1,sFutureWritingInRAMAddress'Length));
                        sFutureState <= Resetting;
                    end if;    
                when Idle => 
                    if(piStart <= '1') then 
                        sFutureState <= Init;
                    else 
                        sFutureState <= Idle;
                    end if;
                when Init =>
                    if(sWritingInRAMAddress = std_logic_vector(to_unsigned(2**DATA_WIDTH-1,DATA_WIDTH))) then
                        sFutureWritingInRAM <= '1';
                        sLFSRLoadSeed <= '0';
                        sFutureWritingInRAMAddress <= (others => '0');
                        sFutureState <= Summing;
                    else
                        sLFSRLoadSeed <= '1';
                        sFutureWritingInRAM <= '1';
                        sFutureWritingInRAMAddress <= std_logic_vector(unsigned(sFutureWritingInRAMAddress) + to_unsigned(1,sFutureWritingInRAMAddress'Length));
                        sFutureWritingInRAMData <= sLFSROut;
                        sFutureState <= Init;
                    end if;
                when Summing =>
                    if(sWritingInRAMAddress = std_logic_vector(to_unsigned(2**DATA_WIDTH-1,DATA_WIDTH))) then
                        sFutureWritingInRAM <= '0';
                        sFutureState <= Idle;
                    else 
                        sFutureWritingInRAM <= '1';
                        sFutureWritingInRAMAddress <= std_logic_vector(unsigned(sFutureWritingInRAMAddress) + to_unsigned(1,sFutureWritingInRAMAddress'Length));
                        sSum <= std_logic_vector(unsigned(sSum) + unsigned(sRAMOutputData));
                    end if;
                when others => 
                    sFutureState <= Resetting;
                    sFutureWritingInRAM <= sWritingInRAM;
                    sFutureWritingInRAMAddress <= sWritingInRAMAddress;
                    sFutureWritingInRAMData <= sWritingInRAMData;
                    
            end case ;
        end if;

    end process ; -- sFutureStateHandler

    sLFSRSeed <= (others => '1');
    poSum <= sSum; 

end ArchFSM_Ctrl ; -- ArchFSM_Ctrl
