library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Reproduce la Figura 3 de la guia (FIFO circular de 8 entradas).
entity tb_fifo8 is
end entity tb_fifo8;

architecture sim of tb_fifo8 is
    signal clk, reset, wr, rd, full, empty : std_logic := '0';
    signal w_data, r_data : std_logic_vector(3 downto 0) := (others => '0');
    signal w_ptr, r_ptr : std_logic_vector(2 downto 0);
begin
    clk <= not clk after 5 ns;

    dut : entity work.fifo
        generic map (ADDR_WIDTH => 3, DATA_WIDTH => 4)
        port map (
            clk => clk, reset => reset, rd => rd, wr => wr,
            w_data => w_data, empty => empty, full => full,
            r_data => r_data, w_ptr => w_ptr, r_ptr => r_ptr
        );

    stimulus : process
        procedure verify(
            constant write_index : in natural;
            constant read_index  : in natural;
            constant is_full     : in std_logic;
            constant is_empty    : in std_logic;
            constant front_data  : in natural
        ) is
        begin
            assert to_integer(unsigned(w_ptr)) = write_index
                report "w_ptr inesperado" severity error;
            assert to_integer(unsigned(r_ptr)) = read_index
                report "r_ptr inesperado" severity error;
            assert full = is_full report "full inesperado" severity error;
            assert empty = is_empty report "empty inesperado" severity error;
            assert to_integer(unsigned(r_data)) = front_data
                report "r_data inesperado" severity error;
        end procedure;

        procedure cycle(
            constant push       : in std_logic;
            constant pop        : in std_logic;
            constant input_data : in natural
        ) is
        begin
            wr <= push;
            rd <= pop;
            w_data <= std_logic_vector(to_unsigned(input_data, 4));
            wait until rising_edge(clk);
            wait for 1 ns;
            wr <= '0';
            rd <= '0';
            wait until falling_edge(clk);
        end procedure;
    begin
        reset <= '1';
        wait for 12 ns;
        reset <= '0';
        wait until falling_edge(clk);
        verify(0, 0, '0', '1', 0); -- Figura 3(a)

        cycle('1', '0', 1);
        verify(1, 0, '0', '0', 1); -- (b): 1 escritura

        cycle('1', '0', 2);
        cycle('1', '0', 3);
        cycle('1', '0', 4);
        verify(4, 0, '0', '0', 1); -- (c): 3 escrituras mas

        cycle('0', '1', 0);
        verify(4, 1, '0', '0', 2); -- (d): 1 lectura

        cycle('1', '0', 5);
        cycle('1', '0', 6);
        cycle('1', '0', 7);
        cycle('1', '0', 8);
        verify(0, 1, '0', '0', 2); -- (e): 4 escrituras mas

        cycle('1', '0', 9);
        verify(1, 1, '1', '0', 2); -- (f): llena
        cycle('1', '0', 15);
        verify(1, 1, '1', '0', 2); -- escritura bloqueada

        cycle('0', '1', 0);
        cycle('0', '1', 0);
        verify(1, 3, '0', '0', 4); -- (g): 2 lecturas

        for i in 1 to 5 loop
            cycle('0', '1', 0);
        end loop;
        verify(1, 0, '0', '0', 9); -- (h): 5 lecturas mas

        cycle('0', '1', 0);
        verify(1, 1, '0', '1', 0); -- (i): vacia
        cycle('0', '1', 0);
        verify(1, 1, '0', '1', 0); -- lectura bloqueada

        -- Lectura y escritura simultaneas cuando esta vacia:
        -- solo se acepta la escritura.
        cycle('1', '1', 10);
        verify(2, 1, '0', '0', 10);
        -- Simultaneas cuando hay datos: conserva ocupacion.
        cycle('1', '1', 11);
        verify(3, 2, '0', '0', 11);
        cycle('0', '1', 0);
        verify(3, 3, '0', '1', 0);

        report "PASS: secuencia Figura 3 + casos limite (8 entradas)" severity note;
        wait;
    end process;
end architecture sim;
