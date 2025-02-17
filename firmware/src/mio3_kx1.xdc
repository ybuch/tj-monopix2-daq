# ------------------------------------------------------------
#  Copyright (c) SILAB , Physics Institute of Bonn University
# ------------------------------------------------------------
#
#   Constraints for the MIO3 PCB with the Mercury KX1(160T-1) FPGA board
#

# Clock domains
# CLK_SYS: 100 MHz, from xtal oscillator
# -> PLL2: CLK8_PLL
#          CLK16_PLL: RX
#          CLK32_PLL: RX
#          CLK40_PLL: PULSER, TDC, TLU
#          CLK160_PLL: TLU, TDC
#          CLK320_PLL: TLU, TDC
# -> PLL1: BUS_CLK_PLL: 142.86 MHz, main system clock (7 ns)
#          CLK125PLLTX, Ethernet
#          CLK125PLLTX90: Ethernet
# CLK_MGT_REF: 160 MHz, from Si570 programmable oscilaltor
# ->       CMDCLK: 160 MHz, command encoder
# CLK_RGMII_RX: 125 MHz, from Ethernet chip

# Clock inputs
create_clock -period 10.000 -name CLK_SYS -add [get_ports FCLK_IN]
create_clock -period 8.000 -name CLK_RGMII_RX -add [get_ports rgmii_rxc]
create_clock -period 6.250 -name CLK_MGT_REF -add [get_ports MGT_REFCLK0_P]

# Derived clocks
create_generated_clock -name I2C_CLK -source [get_pins PLLE2_BASE_inst_comm/CLKOUT0] -divide_by 1600 [get_pins i_clock_divisor_i2c/CLOCK_reg/Q]
create_generated_clock -name CLK320_PLL_Gen -source [get_pins {i_tjmonopix2_core/gpio_i/core/IDDR_RX_i_2/I0}] -divide_by 1 -add -master_clock [get_clocks -of [get_pins i_tjmonopix2_core/gpio_i/core/IDDR_RX_i_2/I0] -filter {IS_GENERATED}] [get_pins {i_tjmonopix2_core/gpio_i/core/IDDR_RX_i_2/O}]
create_generated_clock -name CLK160_PLL_Gen -source [get_pins {i_tjmonopix2_core/gpio_i/core/IDDR_RX_i_2/I1}] -divide_by 1 -add -master_clock [get_clocks -of [get_pins i_tjmonopix2_core/gpio_i/core/IDDR_RX_i_2/I1] -filter {IS_GENERATED}] [get_pins {i_tjmonopix2_core/gpio_i/core/IDDR_RX_i_2/O}]

# Exclude asynchronous clock domains from timing (handled by CDCs)
set_clock_groups -asynchronous -group {BUS_CLK_PLL I2C_CLK} -group {CLK125PLLTX CLK125PLLTX90} -group {CLK320_PLL CLK160_PLL CLK40_PLL CLK32_PLL CLK16_PLL} -group [get_clocks -include_generated_clocks CLK_MGT_REF] -group CLK_RGMII_RX
set_clock_groups -logically_exclusive -group [get_clocks -include_generated_clocks CLK32_PLL] -group [get_clocks -include_generated_clocks CLK16_PLL]
set_clock_groups -logically_exclusive -group [get_clocks -include_generated_clocks {CLK320_PLL_Gen}] -group [get_clocks -include_generated_clocks {CLK160_PLL_Gen}]

# SiTCP
set_max_delay -datapath_only -from [get_clocks CLK125PLLTX] -to [get_ports {rgmii_txd[*]}] 4.000
set_max_delay -datapath_only -from [get_clocks CLK125PLLTX] -to [get_ports rgmii_tx_ctl] 4.000
set_max_delay -datapath_only -from [get_clocks CLK125PLLTX90] -to [get_ports rgmii_txc] 4.000
set_property ASYNC_REG true [get_cells sitcp/SiTCP/GMII/GMII_TXCNT/irMacPauseExe_0]
set_property ASYNC_REG true [get_cells sitcp/SiTCP/GMII/GMII_TXCNT/irMacPauseExe_1]

# LED
set_property PACKAGE_PIN M17 [get_ports {LED[0]}]
set_property PACKAGE_PIN L18 [get_ports {LED[1]}]
set_property PACKAGE_PIN L17 [get_ports {LED[2]}]
set_property PACKAGE_PIN K18 [get_ports {LED[3]}]
set_property PACKAGE_PIN P26 [get_ports {LED[4]}]
set_property PACKAGE_PIN M25 [get_ports {LED[5]}]
set_property PACKAGE_PIN L25 [get_ports {LED[6]}]
set_property PACKAGE_PIN P23 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports LED*]
set_property SLEW SLOW [get_ports LED*]

# PMOD
#  ____________
# |1 2 3 4  G +|  First PMOD channel (4 signal lines, ground and vcc)
# |7_8_9_10_G_+|  Second PMOD channel ("")
#
# PMOD connector Pin10-->PMOD0; Pin9-->PMOD1; Pin8-->PMOD2; Pin7-->PMOD3;
set_property PACKAGE_PIN AC23 [get_ports {PMOD[0]}]
set_property PACKAGE_PIN AC24 [get_ports {PMOD[1]}]
set_property PACKAGE_PIN W25 [get_ports {PMOD[2]}]
set_property PACKAGE_PIN W26 [get_ports {PMOD[3]}]
# PMOD connector Pin4-->PMOD4; Pin3-->PMOD5; Pin2-->PMOD6; Pin1-->PMOD7;
set_property PACKAGE_PIN AA25 [get_ports {PMOD[4]}]
set_property PACKAGE_PIN AB25 [get_ports {PMOD[5]}]
set_property PACKAGE_PIN V24 [get_ports {PMOD[6]}]
set_property PACKAGE_PIN V26 [get_ports {PMOD[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports PMOD*]
# pull down the PMOD pins which are used as inputs
set_property PULLDOWN true [get_ports {PMOD[0]}]
set_property PULLDOWN true [get_ports {PMOD[1]}]
set_property PULLDOWN true [get_ports {PMOD[2]}]
set_property PULLDOWN true [get_ports {PMOD[3]}]

# ------ Si570 / SMA input CLK
set_property PACKAGE_PIN D6 [get_ports MGT_REFCLK0_P]
set_property PACKAGE_PIN D5 [get_ports MGT_REFCLK0_N]
set_property PACKAGE_PIN F6 [get_ports MGT_REFCLK1_P]
set_property PACKAGE_PIN F5 [get_ports MGT_REFCLK1_N]

# ------ CLK Mux
set_property PACKAGE_PIN K25 [get_ports MGT_REF_SEL]
set_property IOSTANDARD LVCMOS25 [get_ports MGT_REF_SEL]
set_property PULLUP true [get_ports MGT_REF_SEL]

# ------ FCLK (100 MHz)
set_property PACKAGE_PIN AA3 [get_ports FCLK_IN]
set_property IOSTANDARD LVCMOS15 [get_ports FCLK_IN]

# ------ Button & Spare & more - omitted for now
set_property PACKAGE_PIN C18 [get_ports RESET_BUTTON]
set_property IOSTANDARD LVCMOS25 [get_ports RESET_BUTTON]
set_property PULLUP true [get_ports RESET_BUTTON]

# ------ I2C control signals
set_property PACKAGE_PIN P24 [get_ports I2C_SDA]
set_property IOSTANDARD LVCMOS25 [get_ports I2C_SDA]
set_property PACKAGE_PIN N24 [get_ports I2C_SCL]
set_property IOSTANDARD LVCMOS25 [get_ports I2C_SCL]

# ------ Trigger IOs - partial (MIO3 has fewer lemo than MIO)
set_property PACKAGE_PIN AB21 [get_ports LEMO_TX0]
set_property PACKAGE_PIN V23 [get_ports LEMO_TX1]
set_property IOSTANDARD LVCMOS25 [get_ports LEMO_TX*]
set_property PACKAGE_PIN U22 [get_ports LEMO_RX0]
set_property PACKAGE_PIN U26 [get_ports LEMO_RX1]
set_property IOSTANDARD LVCMOS25 [get_ports LEMO_RX*]

set_property PACKAGE_PIN V21 [get_ports RJ45_TRIGGER]
set_property IOSTANDARD LVCMOS25 [get_ports RJ45_TRIGGER]
set_property PACKAGE_PIN Y25 [get_ports RJ45_RESET]
set_property IOSTANDARD LVCMOS25 [get_ports RJ45_RESET]

# ------ RGMII
set_property SLEW FAST [get_ports mdio_phy_mdc]
set_property IOSTANDARD LVCMOS25 [get_ports mdio_phy_mdc]
set_property PACKAGE_PIN N16 [get_ports mdio_phy_mdc]

set_property SLEW FAST [get_ports mdio_phy_mdio]
set_property IOSTANDARD LVCMOS25 [get_ports mdio_phy_mdio]
set_property PACKAGE_PIN U16 [get_ports mdio_phy_mdio]

set_property SLEW FAST [get_ports phy_rst_n]
set_property IOSTANDARD LVCMOS25 [get_ports phy_rst_n]
set_property PACKAGE_PIN M20 [get_ports phy_rst_n]

set_property IOSTANDARD LVCMOS25 [get_ports rgmii_rxc]
set_property PACKAGE_PIN R21 [get_ports rgmii_rxc]

set_property IOSTANDARD LVCMOS25 [get_ports rgmii_rx_ctl]
set_property PACKAGE_PIN P21 [get_ports rgmii_rx_ctl]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_rxd[0]}]
set_property PACKAGE_PIN P16 [get_ports {rgmii_rxd[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_rxd[1]}]
set_property PACKAGE_PIN N17 [get_ports {rgmii_rxd[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_rxd[2]}]
set_property PACKAGE_PIN R16 [get_ports {rgmii_rxd[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_rxd[3]}]
set_property PACKAGE_PIN R17 [get_ports {rgmii_rxd[3]}]

set_property SLEW FAST [get_ports rgmii_txc]
set_property IOSTANDARD LVCMOS25 [get_ports rgmii_txc]
set_property PACKAGE_PIN R18 [get_ports rgmii_txc]

set_property SLEW FAST [get_ports rgmii_tx_ctl]
set_property IOSTANDARD LVCMOS25 [get_ports rgmii_tx_ctl]
set_property PACKAGE_PIN P18 [get_ports rgmii_tx_ctl]

set_property SLEW FAST [get_ports {rgmii_txd[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_txd[0]}]
set_property PACKAGE_PIN N18 [get_ports {rgmii_txd[0]}]
set_property SLEW FAST [get_ports {rgmii_txd[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_txd[1]}]
set_property PACKAGE_PIN M19 [get_ports {rgmii_txd[1]}]
set_property SLEW FAST [get_ports {rgmii_txd[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_txd[2]}]
set_property PACKAGE_PIN U17 [get_ports {rgmii_txd[2]}]
set_property SLEW FAST [get_ports {rgmii_txd[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_txd[3]}]
set_property PACKAGE_PIN T17 [get_ports {rgmii_txd[3]}]

# ------ Debugging - empty in old ucf

# ------ GPAC IOs

#set_property PACKAGE_PIN G20 [get_ports {DOUT[19]}]
#set_property PACKAGE_PIN H19 [get_ports {DOUT[18]}]
#set_property PACKAGE_PIN J16 [get_ports {DOUT[17]}]
#set_property PACKAGE_PIN J15 [get_ports {DOUT[16]}]
#set_property PACKAGE_PIN F15 [get_ports {DOUT[15]}]
#set_property PACKAGE_PIN G15 [get_ports {DOUT[14]}]
#set_property PACKAGE_PIN N22 [get_ports {DOUT[13]}]
#set_property PACKAGE_PIN N21 [get_ports {DOUT[12]}]
#set_property PACKAGE_PIN Y21 [get_ports {DOUT[11]}]
#set_property PACKAGE_PIN W20 [get_ports {DOUT[10]}]
#set_property PACKAGE_PIN AC22 [get_ports {DOUT[9]}]
#set_property PACKAGE_PIN AB22 [get_ports {DOUT[8]}]
#set_property PACKAGE_PIN W24 [get_ports {DOUT[7]}]
#set_property PACKAGE_PIN W23 [get_ports {DOUT[6]}]
#set_property PACKAGE_PIN U25 [get_ports {DOUT[5]}]
#set_property PACKAGE_PIN U24 [get_ports {DOUT[4]}]
#set_property PACKAGE_PIN M26 [get_ports {DOUT[3]}]
#set_property PACKAGE_PIN N26 [get_ports {DOUT[2]}]
#set_property PACKAGE_PIN AE21 [get_ports {DOUT[1]}]
#set_property PACKAGE_PIN AD21 [get_ports {DOUT[0]}]
#set_property IOSTANDARD LVCMOS25 [get_ports "DOUT*"]

#set_property PACKAGE_PIN H17 [get_ports {DIN[11]}]
#set_property PACKAGE_PIN E15 [get_ports {DIN[10]}]
#set_property PACKAGE_PIN H18 [get_ports {DIN[9]}]
#set_property PACKAGE_PIN E16 [get_ports {DIN[8]}]
#set_property PACKAGE_PIN AF23 [get_ports {DIN[7]}]
#set_property PACKAGE_PIN AE23 [get_ports {DIN[6]}]
#set_property PACKAGE_PIN P25 [get_ports {DIN[5]}]
#set_property PACKAGE_PIN R25 [get_ports {DIN[4]}]
#set_property PACKAGE_PIN L24 [get_ports {DIN[3]}]
#set_property PACKAGE_PIN M24 [get_ports {DIN[2]}]
#set_property PACKAGE_PIN T25 [get_ports {DIN[1]}]
#set_property PACKAGE_PIN T24 [get_ports {DIN[0]}]
#set_property IOSTANDARD LVCMOS25 [get_ports "DIN*"]

# RESETB_EXT connected to DOUT6
set_property PACKAGE_PIN W23 [get_ports RESETB_EXT]
set_property IOSTANDARD LVCMOS25 [get_ports RESETB_EXT]
#set_property DRIVE 16 [get_ports RESETB_EXT]
#set_property SLEW FAST [get_ports RESETB_EXT]
set_property PULLDOWN true [get_ports RESETB_EXT]

# INPUT_SEL connected to DOUT14
set_property PACKAGE_PIN G15 [get_ports INPUT_SEL]
set_property IOSTANDARD LVCMOS25 [get_ports INPUT_SEL]
#set_property DRIVE 16 [get_ports INPUT_SEL]
set_property PULLDOWN true [get_ports INPUT_SEL]

# PULSE_EXT connected to DOUT19
set_property PACKAGE_PIN G20 [get_ports LVDS_PULSE_EXT]
set_property IOSTANDARD LVCMOS25 [get_ports LVDS_PULSE_EXT]
#set_property DRIVE 16 [get_ports PULSE_EXT]
#set_property SLEW FAST [get_ports PULSE_EXT]
set_property PULLDOWN true [get_ports LVDS_PULSE_EXT]

# CMOS_PULSE_EXT connected to DOUT12
set_property PACKAGE_PIN N21 [get_ports CMOS_PULSE_EXT]
set_property IOSTANDARD LVCMOS25 [get_ports CMOS_PULSE_EXT]
#set_property DRIVE 16 [get_ports CMOS_PULSE_EXT]
#set_property SLEW FAST [get_ports CMOS_PULSE_EXT]
set_property PULLDOWN true [get_ports CMOS_PULSE_EXT]

# LVDS_CMD_CLK connected to DOUT17
set_property PACKAGE_PIN J16 [get_ports LVDS_CMD_CLK]
set_property IOSTANDARD LVCMOS25 [get_ports LVDS_CMD_CLK]
set_property PULLDOWN true [get_ports LVDS_CMD_CLK]
set_property SLEW FAST [get_ports LVDS_CMD_CLK]

# CMOS_CMD_CLK connected to DOUT2
set_property PACKAGE_PIN N26 [get_ports CMOS_CMD_CLK]
set_property IOSTANDARD LVCMOS25 [get_ports CMOS_CMD_CLK]
set_property PULLDOWN true [get_ports CMOS_CMD_CLK]
set_property DRIVE 16 [get_ports CMOS_CMD_CLK]
set_property SLEW FAST [get_ports CMOS_CMD_CLK]

# LVDS_CMD connected to DOUT16
set_property PACKAGE_PIN J15 [get_ports LVDS_CMD]
set_property IOSTANDARD LVCMOS25 [get_ports LVDS_CMD]
set_property PULLDOWN true [get_ports LVDS_CMD]
set_property DRIVE 16 [get_ports LVDS_CMD]
set_property SLEW FAST [get_ports LVDS_CMD]

# CMOS_CMD connected to DOUT4
set_property PACKAGE_PIN U24 [get_ports CMOS_CMD]
set_property IOSTANDARD LVCMOS25 [get_ports CMOS_CMD]
set_property PULLDOWN true [get_ports CMOS_CMD]

# LVDS_SER_CLK connected to DOUT18
set_property PACKAGE_PIN H19 [get_ports LVDS_SER_CLK]
set_property IOSTANDARD LVCMOS25 [get_ports LVDS_SER_CLK]
set_property PULLDOWN true [get_ports LVDS_SER_CLK]

# CMOS_SER_CLK connected to DOUT0
set_property PACKAGE_PIN AD21 [get_ports CMOS_SER_CLK]
set_property IOSTANDARD LVCMOS25 [get_ports CMOS_SER_CLK]
#set_property DRIVE 16 [get_ports CMOS_SER_CLK]
#set_property SLEW FAST [get_ports CMOS_SER_CLK]
set_property PULLDOWN true [get_ports CMOS_SER_CLK]

# DATA_OUT connected to DIN11
set_property PACKAGE_PIN H17 [get_ports LVDS_DATA]
set_property IOSTANDARD LVCMOS25 [get_ports LVDS_DATA]
set_property PULLDOWN true [get_ports LVDS_DATA]
# set_property DRIVE 16 [get_ports DATA_OUT]
# set_property SLEW FAST [get_ports DATA_OUT]

# FREEZE_EXT connected to DOUT10
set_property PACKAGE_PIN W20 [get_ports FREEZE_EXT]
set_property IOSTANDARD LVCMOS25 [get_ports FREEZE_EXT]
set_property PULLUP true [get_ports FREEZE_EXT]

# READ_EXT connected to DOUT8
set_property PACKAGE_PIN AB22 [get_ports READ_EXT]
set_property IOSTANDARD LVCMOS25 [get_ports READ_EXT]
set_property PULLDOWN true [get_ports READ_EXT]

# RO_RST_EXT connected to DOUT9
set_property PACKAGE_PIN AC22 [get_ports RO_RST_EXT]
set_property IOSTANDARD LVCMOS25 [get_ports RO_RST_EXT]

# TOKEN_OUT connected to DIN0
set_property PACKAGE_PIN T24 [get_ports TOKEN_OUT]
set_property IOSTANDARD LVCMOS25 [get_ports TOKEN_OUT]

# CMOS_DATA_OUT connected to DIN2
set_property PACKAGE_PIN M24 [get_ports CMOS_DATA_OUT]
set_property IOSTANDARD LVCMOS25 [get_ports CMOS_DATA_OUT]

# HITOR_OUT connected to DIN9
set_property PACKAGE_PIN H18 [get_ports LVDS_HITOR]
set_property IOSTANDARD LVCMOS25 [get_ports LVDS_HITOR]

# CMOS_HITOR_OUT connected to DIN4
set_property PACKAGE_PIN R25 [get_ports CMOS_HITOR]
set_property IOSTANDARD LVCMOS25 [get_ports CMOS_HITOR]

# LVDS_CHSYNC_CLK_OUT connected to DIN8
set_property PACKAGE_PIN E16 [get_ports LVDS_CHSYNC_CLK_OUT]
set_property IOSTANDARD LVCMOS25 [get_ports LVDS_CHSYNC_CLK_OUT]

# LVDS_CHSYNC_LOCKED_OUT connected to DIN10
set_property PACKAGE_PIN E15 [get_ports LVDS_CHSYNC_LOCKED_OUT]
set_property IOSTANDARD LVCMOS25 [get_ports LVDS_CHSYNC_LOCKED_OUT]

# SPI configuration flash
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

