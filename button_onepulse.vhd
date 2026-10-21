library ieee;
use ieee.std_logic_1164.all;

-- Sincronizador + filtro antirrebote + pulso de un ciclo por pulsacion.
entity button_onepulse is
    generic (
        DEBOUNCE_CYCLES : positive := 500000 -- 10 ms a 50 MHz
    );
    port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        button_n : in  std_logic; -- nivel 0 = presionado
        pulse    : out std_logic
    );
end entity button_onepulse;

architecture rtl of button_onepulse is
    signal meta, synced, stable : std_logic := '1';
    signal count : natural range 0 to DEBOUNCE_CYCLES-1 := 0;
    signal pulse_reg : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            meta   <= button_n;
            synced <= meta;
            pulse_reg <= '0';

            if reset = '1' then
                stable <= '1';
                count  <= 0;
            elsif synced = stable then
                count <= 0;
            elsif count = DEBOUNCE_CYCLES-1 then
                stable <= synced;
                count  <= 0;
                if synced = '0' then
                    pulse_reg <= '1';
                end if;
            else
                count <= count + 1;
            end if;
        end if;
    end process;

    pulse <= pulse_reg;
end architecture rtl;
