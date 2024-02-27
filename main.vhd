----------------------------------------------------------------------------------
-- Company: European Spallation Source
-- Engineer: Sølve Slettebak
--  
-- Module Name:    main - Behavioral
-- Project Name:   Firmware for HQF  
-- Target Devices: Cmod S7-25 (xc7s25csga225-1)
-- Tool Versions:  Vivado 2023.1
--
-- Description: Top level VHDL file for the project. Contains main state machine 
--              for reading EEPROM, programming PLL and step attenuator, and
--              monitoring of PLL lock and power good.
--
--              In the event of lost PLL lock, or lost "power good" signals, 
--              PLL chip enable gets disabled, up/down-mixer disabled and interlock
--              activated.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package LED_constants is
    constant col_BLACK  : std_logic_vector(2 downto 0) := "111";
    constant col_RED    : std_logic_vector(2 downto 0) := "011";
    constant col_GREEN  : std_logic_vector(2 downto 0) := "101";
    constant col_BLUE   : std_logic_vector(2 downto 0) := "110";
    constant col_PURPLE : std_logic_vector(2 downto 0) := "010";
    constant col_ORANGE : std_logic_vector(2 downto 0) := "001";
    constant col_CYAN   : std_logic_vector(2 downto 0) := "100";
    constant col_WHITE  : std_logic_vector(2 downto 0) := "000";
    
    constant index_RED   : integer := 2;
    constant index_GREEN : integer := 1;
    constant index_BLUE  : integer := 0;
    
    constant col_ON  : std_logic := '0';
    constant col_OFF : std_logic := '1';
end package LED_constants;


-------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package reg_types is 
    type t_mem_registers is array (0 to 5) of std_logic_vector(31 downto 0);    
end package reg_types;


-------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.reg_types.all;
use work.LED_constants.all;

entity main is
Generic (
    CLOCK_SPEED   : integer := 240_000_000; -- Hz
    BUS_SPEED     : integer := 100_000; -- Hz. For both PLL and EEPROM. With 10kOhm SDA/SCL pullup, this value should be 100_000 Hz.
    INIT_DELAY_us : integer := 50000; 
    REG_WIDTH     : integer := 32
);
Port (
    
    -- CMOD board  
    clock12MHz : in  std_logic;
    LED        : out std_logic_vector(3 downto 0);
    LED_RGB    : out std_logic_vector(2 downto 0);
    i_btn1     : in std_logic;
    -- i_btn2     : in std_logic;
    
    -- External in/out
    RST        : in  std_logic;
    n_ITLCK    : out std_logic;

    PGVA3      : in  std_logic;
    PGVA2      : in  std_logic;
    PGVA1      : in  std_logic;
    PGVfilter  : in  std_logic;
	
    LED_PLL    : out std_logic;
    LED_704    : out std_logic;
    LED_352    : out std_logic;
    SPARE_L    : out std_logic;
    
    PLL_LD     : in  std_logic;    
    PLL_CE     : out std_logic;
    PLL_LE     : out std_logic;    
    PLL_CLK    : out std_logic;
    PLL_DATA   : out std_logic;
    
    EE_SCL     : inout std_logic;
    EE_SDA     : inout std_logic;
    
    DoMixEN    : out std_logic;
    UpMixEN    : out std_logic;
    StpAtnLE   : out std_logic;
    StpAtnD6   : out std_logic;
    StpAtnD5   : out std_logic;
    StpAtnD4   : out std_logic;
    StpAtnD3   : out std_logic;
    StpAtnD2   : out std_logic;
    StpAtnD1   : out std_logic;
    StpAtnD0   : out std_logic
        
);
end main;

architecture Behavioral of main is

-------------------------------------------

    component clk_wiz_0
    port (
        clk_in  : in  std_logic;
        clk_out : out std_logic
    );
    end component;

    signal clockFast : std_logic;

-------------------------------------------

    component PLL_write
    generic (
        REG_WIDTH       : integer;
        CLOCK_SPEED     : integer;
        PLL_CLOCK_SPEED : integer        
    );
    port (
        i_clock      : in  std_logic;
        i_data       : in  std_logic_vector(REG_WIDTH - 1 downto 0);
        i_write_en   : in  std_logic;
        i_reset      : in  std_logic;
        o_write_done : out std_logic;
        o_TX         : out std_logic;
        o_clock      : out std_logic;
        o_LE         : out std_logic        
    );
    end component;
    
    signal PLL_write_en   : std_logic := '0';
    signal PLL_write_done : std_logic;
    signal PLL_register   : std_logic_vector(REG_WIDTH - 1 downto 0); -- to rename later. this should be one of the 6 32 bit registers.

-------------------------------------------

    component read_registers
    generic (
        g_CLOCK_SPEED : integer; -- Hz
        g_BUS_SPEED   : integer
    );
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
    end component;    
    
    signal mem_read       : std_logic;
    signal mem_data_ready : std_logic;
    signal r_regs    : t_mem_registers;
    signal r_RF_freq : std_logic_vector(15 downto 0);
    signal r_stp_att : std_logic_vector( 7 downto 0);    

-------------------------------------------

    constant CLOCK_DELAY : integer := ( CLOCK_SPEED / 1_000_000 ) * INIT_DELAY_us;
    
    type t_state is (
        INIT,              -- Initialize
        WAIT_PGVA,         -- Wait for power good signals
        DELAY,             -- Wait for INIT_DELAY_us before continuing
        START_READ,        -- Initiate the EEPROM read. Could omit this step, but helps with timing closure.
        READ_EEPROM,       -- Read RF frequency, step attenuator settings and PLL registers from EEPROM
        CHECK,             -- Check RF frequency is 352 or 704 (also to verify good read of EEPROM)
        PLL_SETUP_NEXT,    -- Set up first/next register to write to external PLL
        WRITE_PLL,         -- Write one register. Return to PLL_SETUP_NEXT, or WAIT_FOR_LOCK if all registers are written
        WAIT_FOR_LOCK,     -- Wait for PLL lock (and verify power still good)
        STEP_ATT_PROGRAM,  -- Program step attenuator
        MONITOR,           -- Setup is done - monitor power and PLL lock
        ERROR_STATE        -- All errors goes here. Requires a reset signal to get out of this.
    );
    signal state : t_state := INIT;
    
    signal delay_count   : integer := 0;
    signal r_delay_count : integer := 0;

    signal reg_counter       : integer range 0 to 7 := 0;
    signal stp_att_counter   : integer range 0 to 8000 := 0;
    signal r_stp_att_counter : integer range 0 to 8000 := 0;

begin

     

    mainclock : clk_wiz_0
    port map ( 
        clk_out => clockFast,
        clk_in => clock12MHz
    );
    
-------------------------------------------------------------------
    
    PLL_writer : PLL_write
    generic map (
        REG_WIDTH       => REG_WIDTH,
        CLOCK_SPEED     => CLOCK_SPEED,
        PLL_CLOCK_SPEED => BUS_SPEED
    )
    port map (
        i_clock      => clockFast,
        i_data       => PLL_register,
        i_write_en   => PLL_write_en,
        i_reset      => RST,
        o_write_done => PLL_write_done, 
        o_TX         => PLL_DATA,
        o_clock      => PLL_CLK,
        o_LE         => PLL_LE
    );
    
-------------------------------------------------------------------


    mem_reader : read_registers
    generic map (
        g_CLOCK_SPEED => CLOCK_SPEED,
        g_BUS_SPEED   => BUS_SPEED
    )
    port map (
        clock      => clockFast,
        reset      => RST,
        read_next  => mem_read,
        data_ready => mem_data_ready,
        o_regs     => r_regs,
        o_RF_freq  => r_RF_freq,
        o_stp_att  => r_stp_att,
        sda        => EE_SDA,
        scl        => EE_SCL
    );


-------------------------------------------------------------------
    

    --process (all) begin -- needs VHDL 2008.
    LED_PLL <= PLL_LD;
    SPARE_L <= '0';
    --end process;

    SM : process(clockFast) 
    
        procedure proc_reset is begin
            delay_count   <= 0;
            r_delay_count <= 0;
            stp_att_counter   <= 0;
            r_stp_att_counter <= 0;
            LED_704  <= '0';
            LED_352  <= '0';
            StpAtnLE <= '0';
            n_ITLCK  <= '0';
            UpMixEn  <= '0';
            DoMixEn  <= '0';              
            PLL_CE   <= '0';
            LED_RGB  <= col_BLUE;
            LED      <= "0000";
            state    <= INIT;
        end procedure;
    
    begin
        if rising_edge(clockFast) then
            
            if RST = '1' then
                proc_reset;
            else

                case state is
                
                    when INIT =>
                        
                        proc_reset;
                        state <= WAIT_PGVA;

                    when WAIT_PGVA =>
                    
                        LED(0) <= '1';
                    
                        if PGVA1 = '1' and PGVA2 = '1' and PGVA3 = '1' and PGVFilter = '1' then
                            state <= DELAY;
                        end if;
                        
                    when DELAY =>
                        r_delay_count <= delay_count;
                        if r_delay_count > CLOCK_DELAY then                        
                            state <= START_READ;         
                        else
                            delay_count <= delay_count + 1;
                        end if;
                        
                    when START_READ =>
                        mem_read <= '1';
                        state <= READ_EEPROM;
                        
                    when READ_EEPROM =>
                    
                        mem_read <= '0';
                        if mem_data_ready = '1' then    
                            state <= CHECK;
                        end if;

                    when CHECK =>
                    
                        LED(1) <= '1';
                    
                        case to_integer(unsigned(r_RF_freq)) is
                            when 704 =>
                                LED_704 <= '1';
                                LED_352 <= '0';
                                state <= PLL_SETUP_NEXT;
                                PLL_CE <= '1';
                                reg_counter <= 0;
                            when 352 =>
                                LED_704 <= '0';
                                LED_352 <= '1';
                                state <= PLL_SETUP_NEXT;
                                PLL_CE <= '1';
                                reg_counter <= 0;
                            when others =>
                                LED_704 <= '1';
                                LED_352 <= '1';    
                                state <= ERROR_STATE; 
                        end case;


                    when PLL_SETUP_NEXT =>
                                            
                        PLL_write_en <= '1';
                        PLL_register <= r_regs(reg_counter);
                        state <= WRITE_PLL;
                        
                    when WRITE_PLL =>
                    
                        LED(2) <= '1';
                        
                        PLL_write_en <= '0';
                        if PLL_write_done = '1' then
                            if reg_counter = 5 then
                                state <= WAIT_FOR_LOCK;
                            else
                                state <= PLL_SETUP_NEXT;
                            end if;
                            reg_counter <= reg_counter + 1;
                        end if;
                        
                    when WAIT_FOR_LOCK =>
                    
                        LED(3) <= '1';

                        if PGVA1 = '1' and PGVA2 = '1' and PGVA3 = '1' and PLL_LD = '1' and PGVFilter = '1' then
                            state <= STEP_ATT_PROGRAM;
                        end if;
                        
                    when STEP_ATT_PROGRAM => -- need to test this. verify it is written in the correct order, for starters.
                    
                        stp_att_counter <= r_stp_att_counter; 
                        StpAtnD0 <= r_stp_att(0);
                        StpAtnD1 <= r_stp_att(1);
                        StpAtnD2 <= r_stp_att(2);
                        StpAtnD3 <= r_stp_att(3);
                        StpAtnD4 <= r_stp_att(4);
                        StpAtnD6 <= r_stp_att(6);
                        StpAtnD5 <= r_stp_att(5);
                        r_stp_att_counter <= r_stp_att_counter + 1;
                        if stp_att_counter = 1000 then    -- Pull LE high for 1000 clock cycles (of the fast clock)
                            StpAtnLE <= '1';
                        elsif stp_att_counter = 2000 then -- Then low for the same time, and now the step attenuator is programmed.
                            StpAtnLE <= '0';
                        elsif stp_att_counter = 3000 then
                            n_ITLCK <= '1';
                            UpMixEn <= '1';
                            DoMixEn <= '1';                    
                            state <= MONITOR;
                        end if;

                    when MONITOR =>

                        if PGVA1 = '0' or PGVA2 = '0' or PGVA3 = '0' or PLL_LD = '0' or PGVFilter = '0' or i_btn1 = '1' then 
                            n_ITLCK <= '0';
                            PLL_CE <= '0'; 
                            UpMixEn <= '0';
                            DoMixEn <= '0';  
                            state <= ERROR_STATE;                  
                        end if;
                        
                        LED_RGB  <= col_GREEN;
                        
                    when ERROR_STATE =>
                    
                        state <= ERROR_STATE;
                        LED_RGB <= col_RED;
                        
                end case;
                 
            end if;
        end if;
    end process SM; 
end Behavioral;