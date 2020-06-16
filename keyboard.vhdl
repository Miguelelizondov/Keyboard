 
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity keyboard is 
    port(
        kbd_clk, kbd_data, clk : in std_logic;
        reset, enable : in std_logic;
        scan_code : out std_logic_vector(7 downto 0);
        scan_ready : out std_logic;
        error_parity : out std_logic;
        scan_parity : out std_logic
    );
end entity;

architecture arch of keyboard is

    signal filter : std_logic_vector(7 downto 0) := "00000000";
    signal kbd_clk_filtered : std_logic := '0';
    signal read_char : std_logic := '0';
    signal ready_set : std_logic;
    signal parity : std_logic := '0';
    signal incount : std_logic_vector(3 downto 0) := "0000";
    signal shiftin : std_logic_vector(8 downto 0) := "000000000";
    signal state, nextstate : integer range 0 to 11 := 0;


begin
   
    -- filtrado del reloj
    clk_filter : process
    begin
        wait until clk'event and clk = '1';
        filter(6 downto 0) <= filter(7 downto 1);
        filter(7) <= kbd_clk;
        if filter = x"FF" then 
            kbd_clk_filtered <= '1';
        elsif filter = x"00" then
            kbd_clk_filtered <= '0';
        end if;
    end process;



    process (state)
    begin 
        case state is 
            when 0 => 
                -- va a checar si es par el numero de 1 que haya 
                parity <= '0';
                nextstate <= 1;
            when 1 =>
                error_parity <= '0';
                ready_set <= '0';
                read_char <= '1';
                nextstate <= 2;
                -- el shifteo de la señal además de cambiar le parity excepto en el ultimo estado
            when 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 =>
                shiftin(7 downto 0) <= shiftin(8 downto 1);
                shiftin(8) <= kbd_data;
                ready_set <= '0';
                if kbd_data = '1' and state /= 10 then parity <= not parity; end if;
                nextstate <= nextstate+1;
            when 11 =>
                -- checar la partidad para saber si esta bien o mal, mandar las señales a los outputs
                if shiftin(8) = parity then error_parity <= '0';
                else error_parity <= '1'; end if;
            
                scan_parity <= parity;
                scan_code <= shiftin(7 downto 0);
                ready_set <= '1';
                nextstate <= 0;
        end case;
    end process;


    process(kbd_clk_filtered)
    begin
        if kbd_clk_filtered'event and kbd_clk_filtered = '0' then
            if reset = '1' then
                state <= 0;
            else
               state<= nextstate;
            end if;
        end if;
    end process;

    --scan ready 
    process (enable, ready_set)
    begin
        if enable = '1' then
            scan_ready <= '0';
        elsif ready_set'event then
            scan_ready <= ready_set;
        end if;
    end process;
end arch;