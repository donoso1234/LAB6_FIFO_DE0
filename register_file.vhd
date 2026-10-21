library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Archivo de registros circular: 2**ADDR_WIDTH palabras de DATA_WIDTH bits.
-- Escritura sincrona y lectura combinacional.
entity register_file is
    generic (
        DATA_WIDTH : positive := 4;
        ADDR_WIDTH : positive := 4
    );
    port (
        clk    : in  std_logic;
        wr_en  : in  std_logic;
        w_addr : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        r_addr : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        w_data : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        r_data : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity register_file;

architecture rtl of register_file is
    type mem_type is array (0 to 2**ADDR_WIDTH-1) of
        std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mem : mem_type;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if wr_en = '1' then
                mem(to_integer(unsigned(w_addr))) <= w_data;
            end if;
        end if;
    end process;

    r_data <= mem(to_integer(unsigned(r_addr)));
end architecture rtl;
