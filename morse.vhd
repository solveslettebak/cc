library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package morse_type is
    type t_morse is array (natural range <>) of integer range 0 to 3;    
end package morse_type;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.morse_type.all;

entity morse is
generic (
    g_CLOCK_SPEED     : integer := 100_000_000;
    g_BASIC_PERIOD_ms : integer := 120;
    g_MORSE           : t_morse(0 to 99) := (0,0,0,0,2,0,2,0,1,0,0,2,0,1,1,0,2,1,0,1,0,1,1,2,3,2,0,0,2,1,1,2,3,2,1,2,0,1,0,2,0,1,2,0,1,1,0,2,0,1,1,0,2,0,2,1,0,0,2,3,2,0,0,2,1,0,2,3,2,0,1,2,1,0,2,3,2,0,0,1,0,2,0,1,1,0,2,1,1,0,2,0,1,2,1,0,1,0,1,1) --(1,0,0,0,0,1,1,1,0,3,0,2,0)
);
port ( 
    clock : in  std_logic;
    reset : in  std_logic;
    o_LED : out std_logic;
    o_done : out std_logic;
    i_start : in  std_logic
);
end morse;

architecture Behavioral of morse is
    constant c_BP_cycles  : integer := g_CLOCK_SPEED / 1000 * g_BASIC_PERIOD_ms;
      
    type t_state is (WAITING, TRANSMIT, ON_STATE, OFF_STATE);
    signal state : t_state := WAITING;
    
    signal s_morse_position : integer range 0 to 1000 := 0;
    
    signal on_count  : integer range 0 to c_BP_cycles * 3;
    signal off_count : integer range 0 to c_BP_cycles * 7;
    
    signal r_LED : std_logic := '0';
   
begin

    o_LED <= r_LED;

    process (clock) is 
        
        procedure proc_reset is begin
            state <= WAITING;
            o_done <= '0';
            s_morse_position <= 0;
            on_count <= 0;
            off_count <= 0;
            --r_LED <= '1';
        end procedure proc_reset;
    begin
        if rising_edge(clock) then
            if reset = '1' then
                proc_reset;
            else
      
                case state is
                
                    when WAITING =>

                        proc_reset;
                        if i_start = '1' then
                            state <= TRANSMIT;
                        end if;
                        
                    when TRANSMIT =>
                        r_LED <= '1';
                        case g_MORSE(s_morse_position) is
                            when 0 => -- dot
                                on_count <= c_BP_cycles;
                                off_count <= c_BP_cycles;
                            when 1 => -- dash
                                on_count <= c_BP_cycles + c_BP_cycles + c_BP_cycles;
                                off_count <= c_BP_cycles;
                            when 2 => -- new_letter
                                on_count <= 0;
                                off_count <= c_BP_cycles + c_BP_cycles + c_BP_cycles;
                            when 3 => -- new_word
                                on_count <= 0;
                                off_count <= c_BP_cycles + c_BP_cycles + c_BP_cycles + c_BP_cycles + c_BP_cycles + c_BP_cycles + c_BP_cycles;
                            when others => -- this should never happen.
                                on_count <= 5;
                                off_count <= 100;
                        end case;
                        state <= ON_STATE;

                    when ON_STATE =>
                        r_LED <= '1';
                        if on_count > 0 then
                            on_count <= on_count - 1;
                        else
                            state <= OFF_STATE;
                        end if;
                        
                    when OFF_STATE =>
                        r_LED <= '0';
                        if off_count > 0 then
                            off_count <= off_count - 1;
                        else
                            s_morse_position <= s_morse_position + 1;
                            if s_morse_position < g_morse'length - 1 then
                                state <= TRANSMIT;
                            else
                                state <= WAITING;
                                o_done <= '1';
                            end if;
                        end if;
                    

                end case;
            end if;
        end if;
    end process;
    
end Behavioral;
