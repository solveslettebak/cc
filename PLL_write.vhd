----------------------------------------------------------------------------------
-- Company: European Spallation Source
-- Engineer: Sølve Slettebak
--  
-- Module Name:    PLL_write - Behavioral
-- Project Name:   Firmware for HQF  
-- Target Devices: Cmod S7-25 (xc7s25csga225-1)
-- Tool Versions:  Vivado 2023.1
--
-- Description: Writes one register to PLL
-- 
----------------------------------------------------------------------------------

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
        i_reset      : in  std_logic;
        i_data       : in  std_logic_vector(REG_WIDTH - 1 downto 0); -- register to write
        i_write_en   : in  std_logic; -- Writing starts by driving this high for one clock cycle.
        o_write_done : out std_logic; -- Goes high for one clock cycle when write is complete
        
        -- Signals for external PLL
        o_TX         : out std_logic;
        o_clock      : out std_logic;
        o_LE         : out std_logic
    );
end PLL_write;

architecture Behavioral of PLL_write is

    constant CLOCK_DIVIDE : integer := (CLOCK_SPEED / PLL_CLOCK_SPEED) / 4;

    type t_state is (
        WAITING, 
        WRITING, 
        DONE
    );
    signal state : t_state := WAITING;

    signal write_count     : integer range 0 to REG_WIDTH - 1 := 0;
    
    signal data_clock      : std_logic;
    signal last_data_clock : std_logic;
    signal PLL_clock  : std_logic;

    signal r_data : std_logic_vector(REG_WIDTH - 1 downto 0);
    signal r_LE   : std_logic := '1';
    signal r_write_en : std_logic := '0';

    signal clock_count : integer range 0 to CLOCK_DIVIDE * 4;

begin

    -- Process to create clock for the PLL, as well as a 180 deg phase shifted data clock
    -- used to time latching in data
    clock_gen : process(i_clock) 
    begin
        if rising_edge(i_clock) then

            if i_reset = '1' then
                clock_count <= 0;
            else 

                if r_LE = '0' then -- generate clock when load enable is low
                    last_data_clock <= data_clock;
                    if clock_count = CLOCK_DIVIDE * 4 - 1 then
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

    SM : process(i_clock) 
    
        procedure proc_reset is begin
            r_LE <= '1';
            o_write_done <= '0';
            write_count <= 0;
        end proc_reset;    
        
    begin
        if rising_edge(i_clock) then

            if i_reset = '1' then
                proc_reset;
            else

                case state is
                
                    when WAITING =>
                        
                        r_write_en <= i_write_en;
                        
                        if r_write_en = '1' then
                            state <= WRITING;
                            write_count <= REG_WIDTH - 1;
                            r_data <= i_data;              -- Latch in register
                            r_LE <= '0';                   -- Load Enable, active low
                        else
                            proc_reset;
                        end if;
                        
                    when WRITING =>
                    
                        if data_clock = '1' and last_data_clock = '0' then -- rising edge of data clock
                            o_TX <= r_data(write_count);                   -- latch output bit
                            if write_count = 0 then
                                state <= DONE;
                            else
                                write_count <= write_count - 1;            -- loop until all bits written
                            end if;
                        end if;
                        
                    when DONE =>
                    
                        if data_clock = '0' and last_data_clock = '1' then -- wait for falling edge of data clock before finishing.
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
