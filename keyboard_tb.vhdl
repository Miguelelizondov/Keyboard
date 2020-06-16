library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

entity key_tb2 is 
 constant period : time := 1 ns ; -- Señal de reloj de 25MHz
    constant bit_period : time := 500 ns ; -- Keyboard clock ~ 16.7 Khz max
end key_tb2;


architecture arch of key_tb2 is
    component keyboard is 
        port(
           kbd_clk, kbd_data, clk : in std_logic;
        reset, enable : in std_logic;
        scan_code : out std_logic_vector(7 downto 0);
        scan_ready : out std_logic;
        error_parity : out std_logic;
        scan_parity : out std_logic
        );
    end component;

signal  clk : std_logic := '0';
signal  kbd_clk :std_logic := '1';
signal  kbd_data : std_logic := 'H';
signal  reset  : std_logic := '0';
signal  enable :  std_logic := '0';
signal  scan_code : std_logic_vector(7 downto 0);
signal  scan_ready :  std_logic := '0';
signal  error_parity :  std_logic := '0';
signal  scan_parity : std_logic := '0';

type dataRecord is record
code : std_logic_vector(7 downto 0);
parity : std_logic;
end record;

type letras is array (natural range <>) of dataRecord;
constant datos : letras := (
                            (code => x"64", parity => '0'),
                            (code => x"8F", parity => '1'),
                            (code => x"6C", parity => '0'), 
                            (code => x"61", parity => '1')
                        );

    begin 

    UUT : keyboard port map (kbd_clk, kbd_data, clk, reset, enable, scan_code, scan_ready );

    -- Señal de reloj del sistema
    clk <= not clk after (period / 2);
    reset <= '1', '0' after period;

    process
        procedure send_code( sc : dataRecord ) is
        begin
            kbd_clk <= 'H';
            kbd_data <= 'H';

            wait for (bit_period/2);
            kbd_data <= '0'; -- Start bit
            wait for (bit_period/2);
            kbd_clk <= '0';
            wait for (bit_period/2);
            kbd_clk <= '1';
            for i in 0 to 7 loop
                kbd_data <= sc.code(i);
                wait for (bit_period/2);
                kbd_clk <= '0';
                wait for (bit_period/2);
                kbd_clk <= '1';
            end loop;
            -- bit de paridad
            kbd_data <= sc.parity;
            wait for (bit_period/2);
            kbd_clk <= '0';
            wait for (bit_period/2);
            kbd_clk <= '1';
            -- stop bit
            kbd_data <= '1';
            wait for (bit_period/2);
            kbd_clk <= '0';
            wait for (bit_period/2);
            kbd_clk <= '1';
            kbd_data <= 'H';
            wait for (bit_period * 3);
        end procedure send_code;
    
       begin
        wait for bit_period;
        for i in datos'range loop
            send_code(datos(i));
        end loop;
    end process;

    process 
        variable l : line;
    begin
        wait until scan_ready = '1' and scan_ready'event;

        if error_parity = '1' then 
           write(l,string'("Error Found: "));
        else
        write(l,string'("successful scan: "));
        write (l, string'("Scan code : "));
        write (l, scan_code);
        write (l, string'("Parity: "));
        write (l, scan_parity);
        writeline(output, l);
        end if;
        wait for bit_period;
    end process;

end arch;
