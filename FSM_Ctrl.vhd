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
    poDone : out STD_LOGIC ;
    poSum : out STD_LOGIC_VECTOR (16 -1 downto 0)
) ;
end entity FSM_Ctrl;

architecture ArchFSM_Ctrl of FSM_Ctrl is

    signal sWritingInRAM, sFutureWritingInRAM : std_logic := '0';
    signal sWritingInRAMAddress, sFutureWritingInRAMAddress : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal sWritingInRAMData, sFutureWritingInRAMData  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal sRAMOutputData : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sLFSREnabled : std_logic := '0';
    signal sLFSRLoadSeed : std_logic := '0';
    signal sLFSRSeed : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '1');
    signal sLFSROut : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sSum, sFutureSum : std_logic_vector(poSum'length - 1 downto 0) := (others => '0');
    signal sDone : std_logic;
    type tState is (Init, Idle, Reset, Resetting, Summing);
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
            sSum <= sFutureSum; 
        else 
            sState <= sState;
            sWritingInRAMAddress <= sWritingInRAMAddress;
            sWritingInRAMData <= sWritingInRAMData;
            sWritingInRAM <= sWritingInRAM;
            sSum <= sSum;
        end if;
    end process ; -- main

    sFutureStateHandler : process( piRst, sState, sWritingInRAM, sWritingInRAMData, sWritingInRAMAddress, sFutureWritingInRAMAddress, piStart, sLFSROut, sSum, sRAMOutputData, sFutureSum )
    begin
        sFutureSum <= sSum;
        sFutureWritingInRAMAddress <= sWritingInRAMAddress;
        sFutureWritingInRAM <= sWritingInRAM;
        sFutureWritingInRAMData <= sWritingInRAMData;
        sFutureState <= sState;
        sLFSRLoadSeed <= '0';
        sLFSREnabled <= '0';
        sDone <= '0';
        if(piRst = '1') then 
            sFutureState <= Reset;
        else 
            case(sState) is
                    when Reset =>
                        sFutureWritingInRAM <= '1';
                        sFutureWritingInRAMData <= (others => '0'); 
                        sFutureWritingInRAMAddress <= (others => '0');
                        sFutureState <= Resetting;
                    when Resetting =>
                        if(not(sWritingInRAMAddress = std_logic_vector(to_unsigned(2**ADDR_WIDTH-1,ADDR_WIDTH)))) then
                            sFutureWritingInRAMAddress <= std_logic_vector(unsigned(sWritingInRAMAddress) + to_unsigned(1,sWritingInRAMAddress'Length));
                            sFutureState <= Resetting;
                            sFutureWritingInRAM <= '1';
                        else
                            sFutureWritingInRAM <= '0';
                            sFutureWritingInRAMData <= sWritingInRAMData;
                            sFutureWritingInRAMAddress <= (others => '0');
                            sFutureSum <= (others => '0');
                            sFutureState <= Idle;
                        end if;    
                    when Idle =>
                        if(piStart = '1') then 
                            sFutureState <= Init;
                        else 
                            sFutureState <= Idle;
                        end if;
                    when Init =>
                        if(sWritingInRAMAddress = std_logic_vector(to_unsigned(2**ADDR_WIDTH-1,ADDR_WIDTH))) then
                            sFutureWritingInRAM <= '1';
                            sFutureWritingInRAMAddress <= (others => '0');
                            sFutureState <= Summing;
                            sLFSREnabled <= '0';
                        else
                            sLFSREnabled <= '1';
                            sLFSRLoadSeed <= '1';
                            sFutureWritingInRAM <= '1';
                            sFutureWritingInRAMAddress <= std_logic_vector(unsigned(sWritingInRAMAddress) + to_unsigned(1,sWritingInRAMAddress'Length));
                            sFutureWritingInRAMData <= sLFSROut;
                            sFutureState <= Init;
                        end if;
                    when Summing =>
                        if(sWritingInRAMAddress = std_logic_vector(to_unsigned(2**ADDR_WIDTH-1,ADDR_WIDTH))) then
                            sFutureState <= Idle;
                            sDone <= '1';
                            sFutureWritingInRAMAddress <= sWritingInRAMAddress; 
                            sFutureSum <= sSum;
                        else 
                            sFutureWritingInRAM <= '0';
                            sDone <= '0';
                            sFutureWritingInRAMAddress <= std_logic_vector(unsigned(sWritingInRAMAddress) + to_unsigned(1,sWritingInRAMAddress'Length));
                            sFutureSum <= std_logic_vector(unsigned(sSum) + unsigned(sRAMOutputData));
                        end if;
                    when others => 
                        sFutureState <= Resetting;
                end case ;
            end if;
    end process ; -- sFutureStateHandler

    sLFSRSeed <= (others => '1');
    poSum <= sSum;
    poDone <= sDone;
    
end ArchFSM_Ctrl ; -- ArchFSM_Ctrl
