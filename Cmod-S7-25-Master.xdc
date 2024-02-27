## This file is a general .xdc for the Cmod S7-25 Rev. B
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

# 12 MHz System Clock
#set_property -dict {PACKAGE_PIN M9 IOSTANDARD LVCMOS33} [get_ports clock12MHz]
#create_clock -period 83.330 -name sys_clk_pin -waveform {0.000 41.660} -add [get_ports clock12MHz]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

# pullups / pulldowns
set_property PULLDOWN TRUE [get_ports {PLL_LD}]
set_property PULLDOWN TRUE [get_ports {n_ITLCK}]
set_property PULLDOWN TRUE [get_ports {UpMixEN}]
set_property PULLDOWN TRUE [get_ports {DoMixEN}]
set_property PULLDOWN TRUE [get_ports {PLL_CE}]

# Push Buttons
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS33} [get_ports i_btn1]
# set_property -dict {PACKAGE_PIN D1 IOSTANDARD LVCMOS33} [get_ports i_btn2]


# RGB LEDs
set_property -dict {PACKAGE_PIN F1 IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports {LED_RGB[0]}]
set_property -dict {PACKAGE_PIN D3 IOSTANDARD LVCMOS33  PULLDOWN TRUE} [get_ports {LED_RGB[1]}]
set_property -dict {PACKAGE_PIN F2 IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports {LED_RGB[2]}]

# 4 LEDs
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]

## Pmod Header JA
#set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33 } [get_ports { m_CS   }]; #IO_L14P_T2_SRCC_34 Sch=ja[1]
#set_property -dict { PACKAGE_PIN H2    IOSTANDARD LVCMOS33 } [get_ports { m_MOSI }]; #IO_L14N_T2_SRCC_34 Sch=ja[2]
#set_property -dict { PACKAGE_PIN H4    IOSTANDARD LVCMOS33 } [get_ports { m_MISO }]; #IO_L13P_T2_MRCC_34 Sch=ja[3]
#set_property -dict { PACKAGE_PIN F3    IOSTANDARD LVCMOS33 } [get_ports { m_clk  }]; #IO_L11N_T1_SRCC_34 Sch=ja[4]
#set_property -dict { PACKAGE_PIN H3    IOSTANDARD LVCMOS33 } [get_ports { ja[4] }]; #IO_L13N_T2_MRCC_34 Sch=ja[7]
#set_property -dict { PACKAGE_PIN H1    IOSTANDARD LVCMOS33 } [get_ports { ja[5] }]; #IO_L12P_T1_MRCC_34 Sch=ja[8]
#set_property -dict { PACKAGE_PIN G1    IOSTANDARD LVCMOS33 } [get_ports { ja[6] }]; #IO_L12N_T1_MRCC_34 Sch=ja[9]
#set_property -dict { PACKAGE_PIN F4    IOSTANDARD LVCMOS33 } [get_ports { spi_reset }]; #IO_L11P_T1_SRCC_34 Sch=ja[10]

## USB UART
## Note: Port names are from the perspoctive of the FPGA.
#set_property -dict { PACKAGE_PIN L12   IOSTANDARD LVCMOS33 } [get_ports { tx }]; #IO_L6N_T0_D08_VREF_14 Sch=uart_rxd_out
#set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { rx }]; #IO_L5N_T0_D07_14 Sch=uart_txd_in

## Analog Inputs on PIO Pins 32 and 33
#set_property -dict { PACKAGE_PIN A13   IOSTANDARD LVDS     } [get_ports { vaux5_p }]; #IO_L12P_T1_MRCC_AD5P_15 Sch=ain_p[32]
#set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVDS     } [get_ports { vaux5_n }]; #IO_L12N_T1_MRCC_AD5N_15 Sch=ain_n[32]
#set_property -dict { PACKAGE_PIN A11   IOSTANDARD LVDS     } [get_ports { vaux12_p }]; #IO_L11P_T1_SRCC_AD12P_15 Sch=ain_p[33]
#set_property -dict { PACKAGE_PIN A12   IOSTANDARD LVDS     } [get_ports { vaux12_n }]; #IO_L11N_T1_SRCC_AD12N_15 Sch=ain_n[33]

## Dedicated Digital I/O on the PIO Headers
set_property -dict {PACKAGE_PIN N3 IOSTANDARD LVCMOS33} [get_ports PGVfilter]
set_property -dict {PACKAGE_PIN L1 IOSTANDARD LVCMOS33} [get_ports n_ITLCK]
set_property -dict {PACKAGE_PIN M4 IOSTANDARD LVCMOS33} [get_ports PGVA3]
set_property -dict {PACKAGE_PIN M3 IOSTANDARD LVCMOS33} [get_ports RST]
set_property -dict {PACKAGE_PIN N2 IOSTANDARD LVCMOS33} [get_ports PGVA2]
set_property -dict {PACKAGE_PIN M2 IOSTANDARD LVCMOS33} [get_ports SPARE_L]
set_property -dict {PACKAGE_PIN P3 IOSTANDARD LVCMOS33} [get_ports PGVA1]
#set_property -dict { PACKAGE_PIN P1    IOSTANDARD LVCMOS33 } [get_ports { pio8 }]; #IO_L22P_T3_34 Sch=pio[08]
set_property -dict {PACKAGE_PIN N1 IOSTANDARD LVCMOS33} [get_ports LED_PLL]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports LED_704]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports LED_352]
#set_property -dict { PACKAGE_PIN N13   IOSTANDARD LVCMOS33 } [get_ports { pio18 }]; #IO_L8N_T1_D12_14 Sch=pio[18]
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports PLL_LD]
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports PLL_CE]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports PLL_LE]


#set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { I2C_SCL }];   #IO_L9P_T1_DQS_14 Sch=pio[22]
#set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS33 } [get_ports { I2C_SDA }];   #IO_L4N_T0_D05_14 Sch=pio[23]

set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports PLL_CLK]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports PLL_DATA]
#set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { PLL_CLOCK }]; #IO_L5P_T0_D06_14 Sch=pio[28] # Define as SPARE in schematic
set_property -dict {PACKAGE_PIN L13 IOSTANDARD LVCMOS33} [get_ports EE_SCL]
set_property -dict {PACKAGE_PIN M13 IOSTANDARD LVCMOS33} [get_ports EE_SDA]
set_property -dict {PACKAGE_PIN J11 IOSTANDARD LVCMOS33} [get_ports DoMixEN]

set_property -dict {PACKAGE_PIN C5 IOSTANDARD LVCMOS33} [get_ports UpMixEN]
set_property -dict {PACKAGE_PIN A2 IOSTANDARD LVCMOS33} [get_ports StpAtnLE]
set_property -dict {PACKAGE_PIN B2 IOSTANDARD LVCMOS33} [get_ports StpAtnD6]
set_property -dict {PACKAGE_PIN B1 IOSTANDARD LVCMOS33} [get_ports StpAtnD5]
set_property -dict {PACKAGE_PIN C1 IOSTANDARD LVCMOS33} [get_ports StpAtnD4]
set_property -dict {PACKAGE_PIN B3 IOSTANDARD LVCMOS33} [get_ports StpAtnD3]
set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS33} [get_ports StpAtnD2]
set_property -dict {PACKAGE_PIN A3 IOSTANDARD LVCMOS33} [get_ports StpAtnD1]
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS33} [get_ports StpAtnD0]

## Quad SPI Flash
## Note: QSPI clock can only be accessed through the STARTUPE2 primitive
#set_property -dict { PACKAGE_PIN L11   IOSTANDARD LVCMOS33 } [get_ports { qspi_cs }]; #IO_L6P_T0_FCS_B_14 Sch=qspi_cs
#set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[0] }]; #IO_L1P_T0_D00_MOSI_14 Sch=qspi_dq[0]
#set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[1] }]; #IO_L1N_T0_D01_DIN_14 Sch=qspi_dq[1]
#set_property -dict { PACKAGE_PIN J12   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[2] }]; #IO_L2P_T0_D02_14 Sch=qspi_dq[2]
#set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[3] }]; #IO_L2N_T0_D03_14 Sch=qspi_dq[3]


