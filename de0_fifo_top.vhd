library ieee;
use ieee.std_logic_1164.all;

-- Terasic DE0 ORIGINAL (Cyclone III), segun la Figura 4.
-- Los pines fisicos estan en Lab_FIFO_DE0.qsf.
entity de0_fifo_top is
    port (
        CLOCK_50 : in  std_logic;
        SW       : in  std_logic_vector(9 downto 0);
        BUTTON   : in  std_logic_vector(2 downto 0);
        LEDG     : out std_logic_vector(9 downto 0);
        HEX0_D   : out std_logic_vector(6 downto 0);
        HEX1_D   : out std_logic_vector(6 downto 0);
        HEX2_D   : out std_logic_vector(6 downto 0);
        HEX3_D   : out std_logic_vector(6 downto 0);
        HEX0_DP  : out std_logic;
        HEX1_DP  : out std_logic;
        HEX2_DP  : out std_logic;
        HEX3_DP  : out std_logic
    );
end entity de0_fifo_top;

architecture rtl of de0_fifo_top is
    signal reset_s, write_pulse, read_pulse : std_logic;
    signal data_in, data_out, write_ptr, read_ptr : std_logic_vector(3 downto 0);
    signal full_s, empty_s : std_logic;
begin
    -- Coincide con la posicion de controles en la figura del profesor:
    -- 4 switches izquierdos = SW9..SW6, reset = SW1.
    reset_s <= SW(1);
    data_in <= SW(9 downto 6);

    write_button : entity work.button_onepulse
        generic map (DEBOUNCE_CYCLES => 500000)
        port map (
            clk => CLOCK_50, reset => reset_s,
            button_n => BUTTON(2), pulse => write_pulse
        );

    read_button : entity work.button_onepulse
        generic map (DEBOUNCE_CYCLES => 500000)
        port map (
            clk => CLOCK_50, reset => reset_s,
            button_n => BUTTON(1), pulse => read_pulse
        );

    fifo_unit : entity work.fifo
        generic map (ADDR_WIDTH => 4, DATA_WIDTH => 4)
        port map (
            clk    => CLOCK_50,
            reset  => reset_s,
            rd     => read_pulse,
            wr     => write_pulse,
            w_data => data_in,
            empty  => empty_s,
            full   => full_s,
            r_data => data_out,
            w_ptr  => write_ptr,
            r_ptr  => read_ptr
        );

    -- Figura 4: HEX3, HEX2, HEX1, HEX0 (de izquierda a derecha).
    disp_write_addr : entity work.hex7seg
        port map (nibble => write_ptr, seg => HEX3_D);
    disp_input : entity work.hex7seg
        port map (nibble => data_in, seg => HEX2_D);
    disp_read_addr : entity work.hex7seg
        port map (nibble => read_ptr, seg => HEX1_D);
    disp_output : entity work.hex7seg
        port map (nibble => data_out, seg => HEX0_D);

    -- Los puntos decimales de la DE0 tambien son activos en bajo.
    HEX0_DP <= '1';
    HEX1_DP <= '1';
    HEX2_DP <= '1';
    HEX3_DP <= '1';

    LEDG(9) <= '0';
    LEDG(8) <= full_s;
    LEDG(7) <= empty_s;
    LEDG(6 downto 0) <= (others => '0');
end architecture rtl;
