library ieee;
use ieee.std_logic_1164.all;

-- Envolvente estructural FIFO, basada en la Figura 2 de la guia.
-- Se agregaron las salidas w_ptr/r_ptr para visualizarlas en la DE0.
entity fifo is
    generic (
        ADDR_WIDTH : positive := 4;
        DATA_WIDTH : positive := 4
    );
    port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        rd     : in  std_logic;
        wr     : in  std_logic;
        w_data : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        empty  : out std_logic;
        full   : out std_logic;
        r_data : out std_logic_vector(DATA_WIDTH-1 downto 0);
        w_ptr  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        r_ptr  : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
end entity fifo;

architecture structural of fifo is
    signal full_s, empty_s, wr_en_s : std_logic;
    signal w_addr_s, r_addr_s, r_addr_next_s : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal r_data_s : std_logic_vector(DATA_WIDTH-1 downto 0);
begin
    -- No se escribe cuando full=1 ni durante reset.
    wr_en_s <= wr and (not full_s) and (not reset);

    ctrl_unit : entity work.fifo_ctrl
        generic map (ADDR_WIDTH => ADDR_WIDTH)
        port map (
            clk         => clk,
            reset       => reset,
            rd          => rd,
            wr          => wr,
            empty       => empty_s,
            full        => full_s,
            w_addr      => w_addr_s,
            r_addr      => r_addr_s,
            r_addr_next => r_addr_next_s
        );

    reg_file_unit : entity work.register_file
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk    => clk,
            wr_en  => wr_en_s,
            w_addr => w_addr_s,
            r_addr => r_addr_s,
            w_data => w_data,
            r_data => r_data_s
        );

    -- Una FIFO vacia no tiene dato valido: se muestra cero.
    r_data <= r_data_s when empty_s = '0' else (others => '0');
    w_ptr  <= w_addr_s;
    r_ptr  <= r_addr_s;
    full   <= full_s;
    empty  <= empty_s;
end architecture structural;
