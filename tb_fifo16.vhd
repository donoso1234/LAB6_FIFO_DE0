library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Verifica 16 posiciones de 4 bits y la vuelta circular de punteros.
entity tb_fifo16 is
end entity tb_fifo16;

architecture sim of tb_fifo16 is
    signal clk, reset, wr, rd, full, empty : std_logic := '0';
    signal w_data, r_data, w_ptr, r_ptr : std_logic_vector(3 downto 0) := (others => '0');
begin
    clk <= not clk after 5 ns;

    dut : entity work.fifo
        generic map (ADDR_WIDTH => 4, DATA_WIDTH => 4)
        port map (
            clk => clk, reset => reset, rd => rd, wr => wr,
            w_data => w_data, empty => empty, full => full,
            r_data => r_data, w_ptr => w_ptr, r_ptr => r_ptr
        );

    stimulus : process
        procedure cycle(
            constant push : in std_logic;
            constant pop  : in std_logic;
            constant data : in natural
        ) is
        begin
            wr <= push;
            rd <= pop;
            w_data <= std_logic_vector(to_unsigned(data,4));
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
        assert empty = '1' and full = '0' severity error;

        for i in 0 to 15 loop
            cycle('1', '0', i);
            assert to_integer(unsigned(w_ptr)) = ((i+1) mod 16)
                report "Error puntero escritura 16" severity error;
            assert r_data = x"0" report "Error cabeza FIFO 16" severity error;
        end loop;
        assert full = '1' and empty = '0' report "No activa full" severity error;
        cycle('1', '0', 5);
        assert full = '1' and w_ptr = x"0" report "Escritura en full" severity error;

        -- Con full y ambas peticiones: solo puede retirarse un dato.
        cycle('1', '1', 15);
        assert full = '0' and r_ptr = x"1" and w_ptr = x"0"
            report "Caso simultaneo en full" severity error;
        assert r_data = x"1" severity error;

        for i in 1 to 15 loop
            assert to_integer(unsigned(r_data)) = i
                report "Desorden FIFO: no respeta first-in-first-out" severity error;
            cycle('0', '1', 0);
        end loop;
        assert empty = '1' and full = '0' report "No activa empty" severity error;
        assert w_ptr = x"0" and r_ptr = x"0" severity error;
        assert r_data = x"0" severity error;

        cycle('1', '0', 10);
        assert r_data = x"A" and w_ptr = x"1" and r_ptr = x"0"
            report "Error circularidad" severity error;
        cycle('1', '1', 11);
        assert r_data = x"B" and w_ptr = x"2" and r_ptr = x"1"
            report "Error simultaneo" severity error;

        report "PASS: FIFO 16x4 full/empty/punteros/orden/circularidad" severity note;
        wait;
    end process;
end architecture sim;
