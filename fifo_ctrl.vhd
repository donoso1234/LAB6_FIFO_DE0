library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Controlador de punteros circulares y banderas full/empty.
-- Coincide con las señales del controlador incompleto de la guia.
entity fifo_ctrl is
    generic (
        ADDR_WIDTH : positive := 4
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        rd          : in  std_logic;
        wr          : in  std_logic;
        empty       : out std_logic;
        full        : out std_logic;
        w_addr      : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        r_addr      : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        r_addr_next : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
end entity fifo_ctrl;

architecture arch of fifo_ctrl is
    signal w_ptr_reg, w_ptr_next, w_ptr_succ : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal r_ptr_reg, r_ptr_next, r_ptr_succ : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal full_reg, full_next   : std_logic;
    signal empty_reg, empty_next : std_logic;
begin
    -- Estado del controlador (reset activo en alto).
    process(clk, reset)
    begin
        if reset = '1' then
            w_ptr_reg <= (others => '0');
            r_ptr_reg <= (others => '0');
            full_reg  <= '0';
            empty_reg <= '1';
        elsif rising_edge(clk) then
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end if;
    end process;

    w_ptr_succ <= std_logic_vector(unsigned(w_ptr_reg) + 1);
    r_ptr_succ <= std_logic_vector(unsigned(r_ptr_reg) + 1);

    -- Operaciones aceptadas:
    -- empty y rd+wr: solo se escribe.
    -- full  y rd+wr: solo se lee.
    -- estado intermedio y rd+wr: ambas operaciones en paralelo.
    process(wr, rd, full_reg, empty_reg,
            w_ptr_reg, r_ptr_reg, w_ptr_succ, r_ptr_succ)
        variable accept_write : boolean;
        variable accept_read  : boolean;
    begin
        accept_write := (wr = '1' and full_reg = '0');
        accept_read  := (rd = '1' and empty_reg = '0');

        w_ptr_next <= w_ptr_reg;
        r_ptr_next <= r_ptr_reg;
        full_next  <= full_reg;
        empty_next <= empty_reg;

        if accept_write and accept_read then
            -- Se retira el dato mas antiguo y se agrega uno nuevo.
            w_ptr_next <= w_ptr_succ;
            r_ptr_next <= r_ptr_succ;
        elsif accept_write then
            w_ptr_next <= w_ptr_succ;
            empty_next <= '0';
            if w_ptr_succ = r_ptr_reg then
                full_next <= '1';
            end if;
        elsif accept_read then
            r_ptr_next <= r_ptr_succ;
            full_next <= '0';
            if r_ptr_succ = w_ptr_reg then
                empty_next <= '1';
            end if;
        end if;
    end process;

    w_addr      <= w_ptr_reg;
    r_addr      <= r_ptr_reg;
    r_addr_next <= r_ptr_next;
    full        <= full_reg;
    empty       <= empty_reg;
end architecture arch;
