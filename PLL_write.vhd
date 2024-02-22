library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PLL_write is
    Generic (
        REG_WIDTH       : integer := 32;
        CLOCK_SPEED     : integer := 300_000_000;
        PLL_CLOCK_SPEED : integer := 100_000
    );
    Port ( 
        i_clock      : in  std_logic;
        i_data       : in  std_logic_vector(REG_WIDTH - 1 downto 0);
        i_write_en   : in  std_logic;
        i_reset      : in  std_logic;
        o_write_done : out std_logic;
        o_TX         : out std_logic;
        o_clock      : out std_logic;
        o_LE         : out std_logic
    );
end PLL_write;

architecture Behavioral of PLL_write is
constant CLOCK_DIVIDE : integer := (CLOCK_SPEED / PLL_CLOCK_SPEED) / 4;
--    constant CLOCK_DIVIDE : integer := 750; -- can't seem to do this with the generics.. can hard code it anyway if necessary.
--    constant CLOCK_DIVIDE : integer := 10; -- for simulation

    type t_state is (WAITING, WRITING, DONE);
    signal state : t_state := WAITING;
    signal write_count : integer := 0;
--signal clock_count : integer := 0;
    signal data_clock : std_logic;
    signal last_data_clock : std_logic;

    signal PLL_clock : std_logic;

    signal r_data : std_logic_vector(REG_WIDTH - 1 downto 0);
    signal r_LE   : std_logic := '1';

    signal clock_count : integer range 0 to CLOCK_DIVIDE * 4;

begin

    clock_gen : process(i_clock) 
        --variable clock_count : integer range 0 to CLOCK_DIVIDE * 4;
        -- TODO if i keep the signal, i need to check if i've got some off-by-one's
    begin
        if rising_edge(i_clock) then

            if i_reset = '1' then
                --clock_count := 0;
                clock_count <= 0;
            else 

				if r_LE = '0' then -- generate clock when load enable is low
					last_data_clock <= data_clock;
					if clock_count = CLOCK_DIVIDE * 4 - 1 then
						--clock_count := 0;
						clock_count <= 0;
					else
						clock_count <= clock_count + 1;
					end if; 
					case clock_count is
						when 0 to CLOCK_DIVIDE - 1 =>
							data_clock <= '1';
							PLL_clock  <= '0';
						when CLOCK_DIVIDE to 2 * CLOCK_DIVIDE - 1 => 
							data_clock <= '1';
							PLL_clock  <= '1';
						when 2 * CLOCK_DIVIDE to 3 * CLOCK_DIVIDE - 1 =>
							data_clock <= '0';
							PLL_clock  <= '1';
						when others =>
							data_clock <= '0';
							PLL_clock  <= '0';
					end case;
				else
					data_clock <= '0';
					last_data_clock <= '0';
					PLL_clock  <= '0';
					clock_count <= 0;
				end if;
				
			end if;
        end if;
    end process clock_gen;

    SM : process(i_clock) begin
        if rising_edge(i_clock) then

			if i_reset = '1' then
				r_LE <= '1';
				o_write_done <= '0';
				write_count <= 0;
				--clock_count <= 0;
			else

				case state is
					when WAITING =>
						if i_write_en = '1' then
							state <= WRITING;
							write_count <= REG_WIDTH - 1;
							r_data <= i_data;
							r_LE <= '0';
						else
							r_LE <= '1';
							o_write_done <= '0';
							write_count <= 0;
							--clock_count <= 0;
						end if;
					when WRITING =>
						if data_clock = '1' and last_data_clock = '0' then -- rising edge of data clock
							o_TX <= r_data(write_count);
							if write_count = 0 then
								state <= DONE;
							else
								write_count <= write_count - 1;
							end if;
						end if;
					when DONE =>
						if data_clock = '0' and last_data_clock = '1' then -- falling edge of data clock
							r_LE <= '1';
							state <= WAITING;
							o_write_done <= '1';
						end if;                    
				end case;
			end if;
        end if;
    end process SM;
    
    o_clock <= PLL_clock;
    o_LE <= r_LE;

end Behavioral;
