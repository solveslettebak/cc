# Purpose

In short, this code reads data from EEPROM, then programs a step attenuator and PLL with the values from EEPROM.

After that setup is done, it will monitor the PLL and power-good inputs.

# Notes

Firmware runs on a CMOD S7-25 board, which is connected to custom hardware.

Clock is 230 MHz, using the vivado clocking wizard. Board clock is 12 MHz.

I2C_master.vhd - modified to use synchronous reset, and replaced a variable with a signal, but otherwise as taken from Digi-Key.

