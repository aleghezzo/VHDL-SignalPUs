library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

--Dise˜nar/Describir una memoria tipo FIFO. La descripcion debe tener como
--parametros el numero de bits de la palabra de datos asi como la profundidad de la memoria.
--Realizar un diagrama en bloques del dise˜no donde se muestren los componentes, el flujo de datos
--asi como los tama˜nos de todas las se˜nales. Basar la descripci´on en dicho diagrama. Escribir un
--testbench para comprobar su funcionamiento, cubrir en el mismo los casos de borde.
entity FiFo is
Generic (
    FIFO_DEPTH : NATURAL := 4;
    DATA_WIDTH : NATURAL := 8
);
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

    type tRegister is array(FIFO_DEPTH downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sRegister, sFutureRegister : tRegister;
    signal sWritingCounter,sFutureWritingCounter : unsigned(integer(ceil(log2(real(2**FIFO_DEPTH))))-1 downto 0) := (others => '0');
    signal sReadingCounter,sFutureReadingCounter : unsigned(integer(ceil(log2(real(2**FIFO_DEPTH))))-1 downto 0) := (others => '0');
    signal sFull,sEmpty, sEqualLSB, sEqualMSB : std_logic;
    
begin

    clkProcess : process(piClk)
    begin
        if rising_edge(piClk) then
            sWritingCounter <= sFutureWritingCounter;
            sReadingCounter <= sFutureReadingCounter;
            registerLoop : for i in sRegister'range loop
                sRegister(i) <= sFutureRegister(i);
            end loop ;
        end if;
    end process ; -- clkProcess

    futureRegisterLogic : process(piData, piWr, piRd)
    begin
        if(piRst = '1') then
            sFutureWritingCounter <= (others => '0');
            sFutureReadingCounter <= (others => '0');
            for i in FIFO_DEPTH downto 0 loop
                sFutureRegister(i) <= (others => '0');
            end loop;
        else 
            if(piWr = '1' and sFull = '0') then
                sFutureWritingCounter <= sWritingCounter + to_unsigned(1,sWritingCounter'length);
            else 
                sFutureWritingCounter <= sWritingCounter;
            end if;
            if(piRd = '1' and sEmpty = '0') then
                sFutureReadingCounter <= sReadingCounter + to_unsigned(1,sReadingCounter'length);
            else 
                sFutureReadingCounter <= sReadingCounter;
            end if;
        end if;
    end process ; -- futureRegisterLogic
    
    sEqualMSB <= '1' when sWritingCounter(FIFO_DEPTH-1) = sWritingCounter(FIFO_DEPTH-1) else '0';
    sEqualLSB <= '1' when sWritingCounter(FIFO_DEPTH-2 downto 0) = sReadingCounter(FIFO_DEPTH-2 downto 0) else '0';
    sFull <= '1' when (sEqualLSB = '1' and sEqualMSB = '0') else '0';
    sEmpty <= '1' when (sEqualLSB = '1' and sEqualMSB = '1') else '0';
    poFull <= sFull;
    poEmpty <= sEmpty;

end ArchFiFo ; -- ArchFiFo