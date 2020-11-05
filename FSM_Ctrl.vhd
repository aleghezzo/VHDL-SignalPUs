library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity FSM_Ctrl is
Generic (
    DATA_WIDTH : natural := 4;
    ADDR_WIDTH : natural := 4
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

    signal sWritingInRAM : std_logic;
    signal sWritingInRAMAddress, sFutureWritingInRAMAddress : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal sWritingInRAMData, sFutureWritingInRAMData  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sRAMOutputData : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sWritingInLFSR : std_logic; 
    signal sLFSREnabled : std_logic;
    signal sLFSRLoadSeed : std_logic;
    signal sLFSRSeed : std_logic_vector(15 downto 0);
    signal sLFSROut : std_logic_vector(15 downto 0);
    --signal 

    type tState is (Init, Idle, Resetting);
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

    ulfsr16 : LFSR16
    port map(
        piClk => piClk,
        piRst => piRst,
        piEna => sLFSREnabled,
        piLoadSeed => sLFSRLoadSeed,
        piSeed => sLFSRSeed,
        poQ => sLFSROut
    );

    main : process(piClk)
    begin
        if (rising_edge(piClk)) then
            sState <= sFutureState;
            sWritingInRAMAddress <= sFutureWritingInRAMAddress;
            sWritingInRAMData <= sFutureWritingInRAMData;
        end if;
    end process ; -- main

    sFutureStateHandler : process( piRst, sState )
    begin
        if(piRst = '1') then
            sFutureState <= Resetting;
            sWritingInRAM <= '1';
            sFutureWritingInRAMData <= (others => '0');
            sFutureWritingInRAMAddress <= (others => '0');
            sFutureState <= Resetting;
            sLFSREnabled <= '0';
            sLFSRLoadSeed <= '1';
            sLFSRSeed <= (others => '1');
        else
            case(sState) is
                when Resetting =>
                    if(sWritingInRAMAddress = std_logic_vector(to_unsigned(2**DATA_WIDTH-1,DATA_WIDTH))) then -- Si no funciona, cambiar por to_unsigned(2**N -1, N)
                        sWritingInRAM <= '0';
                        sFutureState <= Init;
                    else
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
                        sWritingInRAM <= '0';
                        sFutureState <= Idle;
                    else
                        sWritingInRAM <= '1';
                        sFutureWritingInRAMAddress <= std_logic_vector(unsigned(sFutureWritingInRAMAddress) + to_unsigned(1,sFutureWritingInRAMAddress'Length));
                        sFutureWritingInRAMData <= sLFSROut;
                        sFutureState <= Init;
                    end if;
                when others => sFutureState <= Resetting;
            end case ;
        end if;

    end process ; -- sFutureStateHandler


end ArchFSM_Ctrl ; -- ArchFSM_Ctrl
