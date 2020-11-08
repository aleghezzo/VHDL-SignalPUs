entity SimpleCounter is
    Port (
        piClk : in STD_LOGIC ;
        piRst : in STD_LOGIC ;
        piEna : in STD_LOGIC ;
        poQ : out STD_LOGIC_VECTOR (16 -1 downto 0)
    ) ;
end SimpleCounter;

architecture ArchSimpleCounter of SimpleCounter is

    signal sRegisters : std_logic_vector(15 downto 0);

begin

    main : process(piClk, piEna)
    begin
        if(rising_edge(piClk)) then
            if(piRst) then
                sRegisters <= (others => '0')
            elsif(piEna)    
                sRegisters <= unsigned(sRegisters) + to_unsigned(1, sRegisters'length);
            else
                sRegisters <= sRegisters;
            end if;
        end if;
    end process ; -- main
    poQ <= sRegisters;
end ArchSimpleCounter ; -- SimpleCounter