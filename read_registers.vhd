----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/08/2023 07:50:26 PM
-- Design Name: 
-- Module Name: read_registers - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.reg_types.all;
use work.LED_constants.all;

entity read_registers is

    generic (
        g_CLOCK_SPEED   : integer := 300_000_000; -- Hz
        g_BUS_SPEED     : integer := 400_000);
    port ( 
        clock      : in  std_logic;
        reset      : in  std_logic;   
        read_next  : in  std_logic;
        data_ready : out std_logic;
    
        o_RF_freq  : out std_logic_vector(15 downto 0);
        o_stp_att  : out std_logic_vector( 7 downto 0);
        o_regs     : out t_mem_registers;
        
        sda        : inout std_logic;
        scl        : inout std_logic
     );
     
end read_registers;


architecture Behavioral of read_registers is    
  
    -- inputs/outputs for I2C master --
    signal reset_n       : std_logic := '1';
    signal I2C_ena       : std_logic := '0';
    signal I2C_addr      : std_logic_vector(6 downto 0);
    signal I2C_rw        : std_logic := '1';
    signal I2C_data_wr   : std_logic_vector(7 downto 0);
    signal I2C_busy      : std_logic := '0';
    signal I2C_data_rd   : std_logic_vector(7 downto 0);
    signal I2C_ack_error : std_logic;
    -----------------------------------
    
    signal r_I2C_data_rd : std_logic_vector(7 downto 0);
    signal r_I2C_busy    : std_logic  := '0';
  
    signal busy_prev     : std_logic := '0';
      
    signal eeprom_mem : std_logic_vector(27 * 8 - 1 downto 0);
    alias mem_RF_freq : std_logic_vector(15 downto 0) is eeprom_mem( 2 * 8 - 1 downto  0 * 8);
    alias mem_stp_att : std_logic_vector( 7 downto 0) is eeprom_mem( 3 * 8 - 1 downto  2 * 8);    
    alias mem_reg_0   : std_logic_vector(31 downto 0) is eeprom_mem( 7 * 8 - 1 downto  3 * 8);
    alias mem_reg_1   : std_logic_vector(31 downto 0) is eeprom_mem(11 * 8 - 1 downto  7 * 8);
    alias mem_reg_2   : std_logic_vector(31 downto 0) is eeprom_mem(15 * 8 - 1 downto 11 * 8);
    alias mem_reg_3   : std_logic_vector(31 downto 0) is eeprom_mem(19 * 8 - 1 downto 15 * 8);
    alias mem_reg_4   : std_logic_vector(31 downto 0) is eeprom_mem(23 * 8 - 1 downto 19 * 8);
    alias mem_reg_5   : std_logic_vector(31 downto 0) is eeprom_mem(27 * 8 - 1 downto 23 * 8);

    signal r_eeprom_mem : std_logic_vector(27 * 8 - 1 downto 0);
    alias r_mem_RF_freq : std_logic_vector(15 downto 0) is r_eeprom_mem( 2 * 8 - 1 downto  0 * 8);
    alias r_mem_stp_att : std_logic_vector( 7 downto 0) is r_eeprom_mem( 3 * 8 - 1 downto  2 * 8);    
    alias r_mem_reg_0   : std_logic_vector(31 downto 0) is r_eeprom_mem( 7 * 8 - 1 downto  3 * 8);
    alias r_mem_reg_1   : std_logic_vector(31 downto 0) is r_eeprom_mem(11 * 8 - 1 downto  7 * 8);
    alias r_mem_reg_2   : std_logic_vector(31 downto 0) is r_eeprom_mem(15 * 8 - 1 downto 11 * 8);
    alias r_mem_reg_3   : std_logic_vector(31 downto 0) is r_eeprom_mem(19 * 8 - 1 downto 15 * 8);
    alias r_mem_reg_4   : std_logic_vector(31 downto 0) is r_eeprom_mem(23 * 8 - 1 downto 19 * 8);
    alias r_mem_reg_5   : std_logic_vector(31 downto 0) is r_eeprom_mem(27 * 8 - 1 downto 23 * 8);
        
    signal registers : t_mem_registers;
    
    type t_state is ( 
        WAITING,            
        READ_EEPROM,
        READ_DONE
    ); 
    signal state : t_state := WAITING; 
        
    constant control_code : std_logic_vector(3 downto 0) := "1010";
    constant address_chip : std_logic_vector(2 downto 0) := "000";

    signal busy_cnt    : integer range 0 to 31 := 0; 
    signal r_busy_cnt  : integer range 0 to 31 := 0; 
    signal r_read_next : std_logic := '0';

begin

    reset_n <= not reset;
    
    memory_reader : entity work.I2C_master
    generic map (
        input_clk => g_CLOCK_SPEED,
        bus_clk   => g_BUS_SPEED    
    )
    port map (
        clk       => clock,
        reset_n   => reset_n,
        ena       => I2C_ena,
        addr      => I2C_addr,
        rw        => I2C_rw,
        data_wr   => I2C_data_wr,
        busy      => r_I2C_busy,
        data_rd   => r_I2C_data_rd,
        ack_error => I2C_ack_error,
        sda       => sda,
        scl       => scl
    );
    
    mem_proc : process(clock) begin
        if rising_edge(clock) then
            registers(0) <= r_mem_reg_0;
            registers(1) <= r_mem_reg_1;
            registers(2) <= r_mem_reg_2;
            registers(3) <= r_mem_reg_3;
            registers(4) <= r_mem_reg_4;
            registers(5) <= r_mem_reg_5;
        
            r_eeprom_mem <= eeprom_mem;
            I2C_data_rd <= r_I2C_data_rd;
            I2C_busy    <= r_I2C_busy;
            
            r_read_next <= read_next;
        end if;
    end process mem_proc;
    
    SM_read_registers : process(clock) 
    begin
        if rising_edge(clock) then
			if reset = '1' then
				state <= WAITING;
				I2C_ena <= '0';
				busy_prev <= '0';
			else

				case state is 
					when WAITING =>
						data_ready <= '0';
						busy_cnt <= 0;

						if r_read_next = '1' then
							state <= READ_EEPROM;
						end if;
						
					when READ_EEPROM =>
					
						-- I2C master busy, means we are sending a command, and can prepare the next, or read result from previous
						busy_prev <= I2C_busy;
						if (busy_prev = '0') and (I2C_busy = '1') then
							busy_cnt <= busy_cnt + 1;
						end if;
						
						r_busy_cnt <= busy_cnt; 
				
						case r_busy_cnt is
							when 0 =>
								I2C_ena <= '1';             -- enable I2C master
								I2C_addr <= control_code & address_chip; -- load chip code and chip address
								I2C_data_wr <= "00000000";  -- address 0
								I2C_rw <= '0';              -- command: write
							when 1 =>
								I2C_rw <= '0';              -- write one more byte. Address still 0.
							 
							when 2 =>
								I2C_rw <= '1'; -- read      -- start reading bytes consecutively 
			 
							-- RF Frequency
							when 3 => if I2C_busy = '0' then mem_RF_freq(15 downto  8) <= I2C_data_rd; end if;
							when 4 => if I2C_busy = '0' then mem_RF_freq( 7 downto  0) <= I2C_data_rd; end if;
							
							-- Step attenuator
							when 5 => if I2C_busy = '0' then mem_stp_att <= I2C_data_rd; end if;

							-- PLL register 0
							when 6 => if I2C_busy = '0' then mem_reg_0(31 downto 24) <= I2C_data_rd; end if;
							when 7 => if I2C_busy = '0' then mem_reg_0(23 downto 16) <= I2C_data_rd; end if;
							when 8 => if I2C_busy = '0' then mem_reg_0(15 downto  8) <= I2C_data_rd; end if;         
							when 9 => if I2C_busy = '0' then mem_reg_0( 7 downto  0) <= I2C_data_rd; end if;         

							-- PLL register 1
							when 10 => if I2C_busy = '0' then mem_reg_1(31 downto 24) <= I2C_data_rd; end if;
							when 11 => if I2C_busy = '0' then mem_reg_1(23 downto 16) <= I2C_data_rd; end if;
							when 12 => if I2C_busy = '0' then mem_reg_1(15 downto  8) <= I2C_data_rd; end if;         
							when 13 => if I2C_busy = '0' then mem_reg_1( 7 downto  0) <= I2C_data_rd; end if;         
											 
							-- PLL register 2                                                         
							when 14 => if I2C_busy = '0' then mem_reg_2(31 downto 24) <= I2C_data_rd; end if;
							when 15 => if I2C_busy = '0' then mem_reg_2(23 downto 16) <= I2C_data_rd; end if;
							when 16 => if I2C_busy = '0' then mem_reg_2(15 downto  8) <= I2C_data_rd; end if;         
							when 17 => if I2C_busy = '0' then mem_reg_2( 7 downto  0) <= I2C_data_rd; end if;         

							-- PLL register 3
							when 18 => if I2C_busy = '0' then mem_reg_3(31 downto 24) <= I2C_data_rd; end if;
							when 19 => if I2C_busy = '0' then mem_reg_3(23 downto 16) <= I2C_data_rd; end if;
							when 20 => if I2C_busy = '0' then mem_reg_3(15 downto  8) <= I2C_data_rd; end if;         
							when 21 => if I2C_busy = '0' then mem_reg_3( 7 downto  0) <= I2C_data_rd; end if;         

							-- PLL register 4
							when 22 => if I2C_busy = '0' then mem_reg_4(31 downto 24) <= I2C_data_rd; end if;
							when 23 => if I2C_busy = '0' then mem_reg_4(23 downto 16) <= I2C_data_rd; end if;
							when 24 => if I2C_busy = '0' then mem_reg_4(15 downto  8) <= I2C_data_rd; end if;         
							when 25 => if I2C_busy = '0' then mem_reg_4( 7 downto  0) <= I2C_data_rd; end if;

							-- PLL register 5
							when 26 => if I2C_busy = '0' then mem_reg_5(31 downto 24) <= I2C_data_rd; end if;
							when 27 => if I2C_busy = '0' then mem_reg_5(23 downto 16) <= I2C_data_rd; end if;
							when 28 => if I2C_busy = '0' then mem_reg_5(15 downto  8) <= I2C_data_rd; end if;         
							when 29 => if I2C_busy = '0' then mem_reg_5( 7 downto  0) <= I2C_data_rd; end if;         
															
							when others =>
								I2C_ena <= '0';
								state <= READ_DONE;
						end case;
						
					when READ_DONE =>                    
						o_regs <= registers;
						o_stp_att <= mem_stp_att;
						o_RF_freq <= mem_RF_freq;                    
						data_ready <= '1';
						state <= WAITING;
					
				end case;
			end if;
        end if;
    end process SM_read_registers;
end Behavioral;
