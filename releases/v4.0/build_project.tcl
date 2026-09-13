# Build script for the Nasdaq-ITCH feed handler & Order Book release v4.0

set project_name "Feed_Handler_v4.0"
set project_dir  "./Feed_Handler_v4.0"
set board        "xczu7ev-ffvc1156-2-e"

puts "Creating $project_name :"
create_project $project_name $project_dir -part $board -force

puts "Loading Custom IPs..."
set_property ip_repo_paths {./ip_repo} [current_project]
update_ip_catalog

puts "Adding taxi library sources..."
add_files -norecurse [glob -nocomplain ./rtl/taxi/*.v ./rtl/taxi/*.sv]

puts "Adding project RTL sources..."
add_files -norecurse [glob -nocomplain ./rtl/*.v ./rtl/*.sv]

update_compile_order -fileset sources_1

puts "Creating taxi transceiver IP (GTH wizard cores)..."

create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 \
    -module_name taxi_eth_phy_25g_us_gth_ch -dir ./ip
set_property -dict [list \
    CONFIG.GT_TYPE {GTH} \
    CONFIG.CHANNEL_ENABLE {X0Y0} \
    CONFIG.TX_MASTER_CHANNEL {X0Y0} \
    CONFIG.RX_MASTER_CHANNEL {X0Y0} \
    CONFIG.LOCATE_COMMON {EXAMPLE_DESIGN} \
    CONFIG.RX_PPM_OFFSET {200} \
    CONFIG.INS_LOSS_NYQ {20} \
    CONFIG.PCIE_CORECLK_FREQ {250} \
    CONFIG.PCIE_USERCLK_FREQ {250} \
    CONFIG.TX_LINE_RATE {10.3125} \
    CONFIG.TX_PLL_TYPE {QPLL0} \
    CONFIG.TX_REFCLK_FREQUENCY {156.25} \
    CONFIG.TX_DATA_ENCODING {64B66B_ASYNC} \
    CONFIG.TX_USER_DATA_WIDTH {64} \
    CONFIG.TX_INT_DATA_WIDTH {32} \
    CONFIG.TX_BUFFER_MODE {1} \
    CONFIG.TX_QPLL_FRACN_NUMERATOR {0} \
    CONFIG.TX_OUTCLK_SOURCE {TXPROGDIVCLK} \
    CONFIG.TX_DIFF_SWING_EMPH_MODE {CUSTOM} \
    CONFIG.RX_LINE_RATE {10.3125} \
    CONFIG.RX_PLL_TYPE {QPLL0} \
    CONFIG.RX_REFCLK_FREQUENCY {156.25} \
    CONFIG.RX_DATA_DECODING {64B66B_ASYNC} \
    CONFIG.RX_USER_DATA_WIDTH {64} \
    CONFIG.RX_INT_DATA_WIDTH {32} \
    CONFIG.RX_BUFFER_MODE {1} \
    CONFIG.RX_QPLL_FRACN_NUMERATOR {0} \
    CONFIG.RX_EQ_MODE {DFE} \
    CONFIG.RX_JTOL_FC {6.1862627} \
    CONFIG.RX_JTOL_LF_SLOPE {-20} \
    CONFIG.RX_OUTCLK_SOURCE {RXPROGDIVCLK} \
    CONFIG.SIM_CPLL_CAL_BYPASS {1} \
    CONFIG.RX_TERMINATION {PROGRAMMABLE} \
    CONFIG.RX_TERMINATION_PROG_VALUE {800} \
    CONFIG.RX_COUPLING {AC} \
    CONFIG.RESET_SEQUENCE_INTERVAL {0} \
    CONFIG.RX_SLIDE_MODE {OFF} \
    CONFIG.ENABLE_OPTIONAL_PORTS {drpclk_in drpaddr_in drpdi_in drpen_in drpwe_in drpdo_out drprdy_out gttxreset_in txuserrdy_in txpmareset_in txpcsreset_in txprogdivreset_in txresetdone_out txpmaresetdone_out txprgdivresetdone_out gtrxreset_in rxuserrdy_in rxpmareset_in rxdfelpmreset_in eyescanreset_in rxpcsreset_in rxprogdivreset_in rxresetdone_out rxpmaresetdone_out rxprgdivresetdone_out txpd_in txpdelecidlemode_in rxpd_in txsysclksel_in txpllclksel_in rxsysclksel_in rxpllclksel_in txpolarity_in rxpolarity_in txelecidle_in txinhibit_in txdiffctrl_in txmaincursor_in txprecursor_in txpostcursor_in rxcdrlock_out rxcdrhold_in rxcdrovrden_in rxlpmen_in} \
    CONFIG.LOCATE_RESET_CONTROLLER {EXAMPLE_DESIGN} \
    CONFIG.LOCATE_TX_BUFFER_BYPASS_CONTROLLER {CORE} \
    CONFIG.LOCATE_RX_BUFFER_BYPASS_CONTROLLER {CORE} \
    CONFIG.LOCATE_IN_SYSTEM_IBERT_CORE {NONE} \
    CONFIG.LOCATE_TX_USER_CLOCKING {CORE} \
    CONFIG.LOCATE_RX_USER_CLOCKING {CORE} \
    CONFIG.LOCATE_USER_DATA_WIDTH_SIZING {CORE} \
    CONFIG.PRESET {GTH-10GBASE-R} \
    CONFIG.SECONDARY_QPLL_ENABLE {true} \
    CONFIG.SECONDARY_QPLL_LINE_RATE {10.3125} \
    CONFIG.SECONDARY_QPLL_FRACN_NUMERATOR {0} \
    CONFIG.SECONDARY_QPLL_REFCLK_FREQUENCY {156.25} \
    CONFIG.SATA_TX_BURST_LEN {15} \
    CONFIG.FREERUN_FREQUENCY {125} \
    CONFIG.INCLUDE_CPLL_CAL {2} \
    CONFIG.USER_GTPOWERGOOD_DELAY_EN {1} \
    CONFIG.DISABLE_LOC_XDC {1} \
    CONFIG.ENABLE_COMMON_USRCLK {0} \
] [get_ips taxi_eth_phy_25g_us_gth_ch]

create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 \
    -module_name taxi_eth_phy_25g_us_gth_full -dir ./ip
set_property -dict [list \
    CONFIG.GT_TYPE {GTH} \
    CONFIG.CHANNEL_ENABLE {X0Y0} \
    CONFIG.TX_MASTER_CHANNEL {X0Y0} \
    CONFIG.RX_MASTER_CHANNEL {X0Y0} \
    CONFIG.LOCATE_COMMON {CORE} \
    CONFIG.RX_PPM_OFFSET {200} \
    CONFIG.INS_LOSS_NYQ {20} \
    CONFIG.PCIE_CORECLK_FREQ {250} \
    CONFIG.PCIE_USERCLK_FREQ {250} \
    CONFIG.TX_LINE_RATE {10.3125} \
    CONFIG.TX_PLL_TYPE {QPLL0} \
    CONFIG.TX_REFCLK_FREQUENCY {156.25} \
    CONFIG.TX_DATA_ENCODING {64B66B_ASYNC} \
    CONFIG.TX_USER_DATA_WIDTH {64} \
    CONFIG.TX_INT_DATA_WIDTH {32} \
    CONFIG.TX_BUFFER_MODE {1} \
    CONFIG.TX_QPLL_FRACN_NUMERATOR {0} \
    CONFIG.TX_OUTCLK_SOURCE {TXPROGDIVCLK} \
    CONFIG.TX_DIFF_SWING_EMPH_MODE {CUSTOM} \
    CONFIG.RX_LINE_RATE {10.3125} \
    CONFIG.RX_PLL_TYPE {QPLL0} \
    CONFIG.RX_REFCLK_FREQUENCY {156.25} \
    CONFIG.RX_DATA_DECODING {64B66B_ASYNC} \
    CONFIG.RX_USER_DATA_WIDTH {64} \
    CONFIG.RX_INT_DATA_WIDTH {32} \
    CONFIG.RX_BUFFER_MODE {1} \
    CONFIG.RX_QPLL_FRACN_NUMERATOR {0} \
    CONFIG.RX_EQ_MODE {DFE} \
    CONFIG.RX_JTOL_FC {6.1862627} \
    CONFIG.RX_JTOL_LF_SLOPE {-20} \
    CONFIG.RX_OUTCLK_SOURCE {RXPROGDIVCLK} \
    CONFIG.SIM_CPLL_CAL_BYPASS {1} \
    CONFIG.RX_TERMINATION {PROGRAMMABLE} \
    CONFIG.RX_TERMINATION_PROG_VALUE {800} \
    CONFIG.RX_COUPLING {AC} \
    CONFIG.RESET_SEQUENCE_INTERVAL {0} \
    CONFIG.RX_SLIDE_MODE {OFF} \
    CONFIG.ENABLE_OPTIONAL_PORTS {drpclk_common_in drpaddr_common_in drpdi_common_in drpen_common_in drpwe_common_in drpdo_common_out drprdy_common_out qpll0reset_in qpll1reset_in qpll0pd_in qpll1pd_in gtrefclk00_in qpll0lock_out qpll0outclk_out qpll0outrefclk_out gtrefclk01_in qpll1lock_out qpll1outclk_out qpll1outrefclk_out pcierateqpll0_in pcierateqpll1_in drpclk_in drpaddr_in drpdi_in drpen_in drpwe_in drpdo_out drprdy_out gttxreset_in txuserrdy_in txpmareset_in txpcsreset_in txprogdivreset_in txresetdone_out txpmaresetdone_out txprgdivresetdone_out gtrxreset_in rxuserrdy_in rxpmareset_in rxdfelpmreset_in eyescanreset_in rxpcsreset_in rxprogdivreset_in rxresetdone_out rxpmaresetdone_out rxprgdivresetdone_out txpd_in txpdelecidlemode_in rxpd_in txsysclksel_in txpllclksel_in rxsysclksel_in rxpllclksel_in txpolarity_in rxpolarity_in txelecidle_in txinhibit_in txdiffctrl_in txmaincursor_in txprecursor_in txpostcursor_in rxcdrlock_out rxcdrhold_in rxcdrovrden_in rxlpmen_in} \
    CONFIG.LOCATE_RESET_CONTROLLER {EXAMPLE_DESIGN} \
    CONFIG.LOCATE_TX_BUFFER_BYPASS_CONTROLLER {CORE} \
    CONFIG.LOCATE_RX_BUFFER_BYPASS_CONTROLLER {CORE} \
    CONFIG.LOCATE_IN_SYSTEM_IBERT_CORE {NONE} \
    CONFIG.LOCATE_TX_USER_CLOCKING {CORE} \
    CONFIG.LOCATE_RX_USER_CLOCKING {CORE} \
    CONFIG.LOCATE_USER_DATA_WIDTH_SIZING {CORE} \
    CONFIG.PRESET {GTH-10GBASE-R} \
    CONFIG.SECONDARY_QPLL_ENABLE {true} \
    CONFIG.SECONDARY_QPLL_LINE_RATE {10.3125} \
    CONFIG.SECONDARY_QPLL_FRACN_NUMERATOR {0} \
    CONFIG.SECONDARY_QPLL_REFCLK_FREQUENCY {156.25} \
    CONFIG.SATA_TX_BURST_LEN {15} \
    CONFIG.FREERUN_FREQUENCY {125} \
    CONFIG.INCLUDE_CPLL_CAL {2} \
    CONFIG.USER_GTPOWERGOOD_DELAY_EN {1} \
    CONFIG.DISABLE_LOC_XDC {1} \
    CONFIG.ENABLE_COMMON_USRCLK {0} \
] [get_ips taxi_eth_phy_25g_us_gth_full]

create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 \
    -module_name taxi_eth_phy_25g_us_gth_ll_ch -dir ./ip
set_property -dict [list \
    CONFIG.GT_TYPE {GTH} \
    CONFIG.CHANNEL_ENABLE {X0Y0} \
    CONFIG.TX_MASTER_CHANNEL {X0Y0} \
    CONFIG.RX_MASTER_CHANNEL {X0Y0} \
    CONFIG.LOCATE_COMMON {EXAMPLE_DESIGN} \
    CONFIG.RX_PPM_OFFSET {200} \
    CONFIG.INS_LOSS_NYQ {20} \
    CONFIG.PCIE_CORECLK_FREQ {250} \
    CONFIG.PCIE_USERCLK_FREQ {250} \
    CONFIG.TX_LINE_RATE {10.3125} \
    CONFIG.TX_PLL_TYPE {QPLL0} \
    CONFIG.TX_REFCLK_FREQUENCY {156.25} \
    CONFIG.TX_DATA_ENCODING {64B66B} \
    CONFIG.TX_USER_DATA_WIDTH {64} \
    CONFIG.TX_INT_DATA_WIDTH {32} \
    CONFIG.TX_BUFFER_MODE {0} \
    CONFIG.TX_QPLL_FRACN_NUMERATOR {0} \
    CONFIG.TX_OUTCLK_SOURCE {TXPROGDIVCLK} \
    CONFIG.TX_DIFF_SWING_EMPH_MODE {CUSTOM} \
    CONFIG.RX_LINE_RATE {10.3125} \
    CONFIG.RX_PLL_TYPE {QPLL0} \
    CONFIG.RX_REFCLK_FREQUENCY {156.25} \
    CONFIG.RX_DATA_DECODING {64B66B} \
    CONFIG.RX_USER_DATA_WIDTH {64} \
    CONFIG.RX_INT_DATA_WIDTH {32} \
    CONFIG.RX_BUFFER_MODE {0} \
    CONFIG.RX_QPLL_FRACN_NUMERATOR {0} \
    CONFIG.RX_EQ_MODE {DFE} \
    CONFIG.RX_JTOL_FC {6.1862627} \
    CONFIG.RX_JTOL_LF_SLOPE {-20} \
    CONFIG.RX_OUTCLK_SOURCE {RXOUTCLKPMA} \
    CONFIG.SIM_CPLL_CAL_BYPASS {1} \
    CONFIG.RX_TERMINATION {PROGRAMMABLE} \
    CONFIG.RX_TERMINATION_PROG_VALUE {800} \
    CONFIG.RX_COUPLING {AC} \
    CONFIG.RESET_SEQUENCE_INTERVAL {0} \
    CONFIG.RX_SLIDE_MODE {OFF} \
    CONFIG.ENABLE_OPTIONAL_PORTS {drpclk_in drpaddr_in drpdi_in drpen_in drpwe_in drpdo_out drprdy_out gttxreset_in txuserrdy_in txpmareset_in txpcsreset_in txprogdivreset_in txresetdone_out txpmaresetdone_out txprgdivresetdone_out gtrxreset_in rxuserrdy_in rxpmareset_in rxdfelpmreset_in eyescanreset_in rxpcsreset_in rxprogdivreset_in rxresetdone_out rxpmaresetdone_out rxprgdivresetdone_out txpd_in txpdelecidlemode_in rxpd_in txsysclksel_in txpllclksel_in rxsysclksel_in rxpllclksel_in txpolarity_in rxpolarity_in txelecidle_in txinhibit_in txdiffctrl_in txmaincursor_in txprecursor_in txpostcursor_in rxcdrlock_out rxcdrhold_in rxcdrovrden_in rxlpmen_in} \
    CONFIG.LOCATE_RESET_CONTROLLER {EXAMPLE_DESIGN} \
    CONFIG.LOCATE_TX_BUFFER_BYPASS_CONTROLLER {CORE} \
    CONFIG.LOCATE_RX_BUFFER_BYPASS_CONTROLLER {CORE} \
    CONFIG.LOCATE_IN_SYSTEM_IBERT_CORE {NONE} \
    CONFIG.LOCATE_TX_USER_CLOCKING {CORE} \
    CONFIG.LOCATE_RX_USER_CLOCKING {CORE} \
    CONFIG.LOCATE_USER_DATA_WIDTH_SIZING {CORE} \
    CONFIG.PRESET {GTH-10GBASE-R} \
    CONFIG.SECONDARY_QPLL_ENABLE {true} \
    CONFIG.SECONDARY_QPLL_LINE_RATE {10.3125} \
    CONFIG.SECONDARY_QPLL_FRACN_NUMERATOR {0} \
    CONFIG.SECONDARY_QPLL_REFCLK_FREQUENCY {156.25} \
    CONFIG.SATA_TX_BURST_LEN {15} \
    CONFIG.FREERUN_FREQUENCY {125} \
    CONFIG.INCLUDE_CPLL_CAL {2} \
    CONFIG.USER_GTPOWERGOOD_DELAY_EN {1} \
    CONFIG.DISABLE_LOC_XDC {1} \
    CONFIG.ENABLE_COMMON_USRCLK {0} \
] [get_ips taxi_eth_phy_25g_us_gth_ll_ch]

create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 \
    -module_name taxi_eth_phy_25g_us_gth_ll_full -dir ./ip
set_property -dict [list \
    CONFIG.GT_TYPE {GTH} \
    CONFIG.CHANNEL_ENABLE {X0Y0} \
    CONFIG.TX_MASTER_CHANNEL {X0Y0} \
    CONFIG.RX_MASTER_CHANNEL {X0Y0} \
    CONFIG.LOCATE_COMMON {CORE} \
    CONFIG.RX_PPM_OFFSET {200} \
    CONFIG.INS_LOSS_NYQ {20} \
    CONFIG.PCIE_CORECLK_FREQ {250} \
    CONFIG.PCIE_USERCLK_FREQ {250} \
    CONFIG.TX_LINE_RATE {10.3125} \
    CONFIG.TX_PLL_TYPE {QPLL0} \
    CONFIG.TX_REFCLK_FREQUENCY {156.25} \
    CONFIG.TX_DATA_ENCODING {64B66B} \
    CONFIG.TX_USER_DATA_WIDTH {64} \
    CONFIG.TX_INT_DATA_WIDTH {32} \
    CONFIG.TX_BUFFER_MODE {0} \
    CONFIG.TX_QPLL_FRACN_NUMERATOR {0} \
    CONFIG.TX_OUTCLK_SOURCE {TXPROGDIVCLK} \
    CONFIG.TX_DIFF_SWING_EMPH_MODE {CUSTOM} \
    CONFIG.RX_LINE_RATE {10.3125} \
    CONFIG.RX_PLL_TYPE {QPLL0} \
    CONFIG.RX_REFCLK_FREQUENCY {156.25} \
    CONFIG.RX_DATA_DECODING {64B66B} \
    CONFIG.RX_USER_DATA_WIDTH {64} \
    CONFIG.RX_INT_DATA_WIDTH {32} \
    CONFIG.RX_BUFFER_MODE {0} \
    CONFIG.RX_QPLL_FRACN_NUMERATOR {0} \
    CONFIG.RX_EQ_MODE {DFE} \
    CONFIG.RX_JTOL_FC {6.1862627} \
    CONFIG.RX_JTOL_LF_SLOPE {-20} \
    CONFIG.RX_OUTCLK_SOURCE {RXOUTCLKPMA} \
    CONFIG.SIM_CPLL_CAL_BYPASS {1} \
    CONFIG.RX_TERMINATION {PROGRAMMABLE} \
    CONFIG.RX_TERMINATION_PROG_VALUE {800} \
    CONFIG.RX_COUPLING {AC} \
    CONFIG.RESET_SEQUENCE_INTERVAL {0} \
    CONFIG.RX_SLIDE_MODE {OFF} \
    CONFIG.ENABLE_OPTIONAL_PORTS {drpclk_common_in drpaddr_common_in drpdi_common_in drpen_common_in drpwe_common_in drpdo_common_out drprdy_common_out qpll0reset_in qpll1reset_in qpll0pd_in qpll1pd_in gtrefclk00_in qpll0lock_out qpll0outclk_out qpll0outrefclk_out gtrefclk01_in qpll1lock_out qpll1outclk_out qpll1outrefclk_out pcierateqpll0_in pcierateqpll1_in drpclk_in drpaddr_in drpdi_in drpen_in drpwe_in drpdo_out drprdy_out gttxreset_in txuserrdy_in txpmareset_in txpcsreset_in txprogdivreset_in txresetdone_out txpmaresetdone_out txprgdivresetdone_out gtrxreset_in rxuserrdy_in rxpmareset_in rxdfelpmreset_in eyescanreset_in rxpcsreset_in rxprogdivreset_in rxresetdone_out rxpmaresetdone_out rxprgdivresetdone_out txpd_in txpdelecidlemode_in rxpd_in txsysclksel_in txpllclksel_in rxsysclksel_in rxpllclksel_in txpolarity_in rxpolarity_in txelecidle_in txinhibit_in txdiffctrl_in txmaincursor_in txprecursor_in txpostcursor_in rxcdrlock_out rxcdrhold_in rxcdrovrden_in rxlpmen_in} \
    CONFIG.LOCATE_RESET_CONTROLLER {EXAMPLE_DESIGN} \
    CONFIG.LOCATE_TX_BUFFER_BYPASS_CONTROLLER {CORE} \
    CONFIG.LOCATE_RX_BUFFER_BYPASS_CONTROLLER {CORE} \
    CONFIG.LOCATE_IN_SYSTEM_IBERT_CORE {NONE} \
    CONFIG.LOCATE_TX_USER_CLOCKING {CORE} \
    CONFIG.LOCATE_RX_USER_CLOCKING {CORE} \
    CONFIG.LOCATE_USER_DATA_WIDTH_SIZING {CORE} \
    CONFIG.PRESET {GTH-10GBASE-R} \
    CONFIG.SECONDARY_QPLL_ENABLE {true} \
    CONFIG.SECONDARY_QPLL_LINE_RATE {10.3125} \
    CONFIG.SECONDARY_QPLL_FRACN_NUMERATOR {0} \
    CONFIG.SECONDARY_QPLL_REFCLK_FREQUENCY {156.25} \
    CONFIG.SATA_TX_BURST_LEN {15} \
    CONFIG.FREERUN_FREQUENCY {125} \
    CONFIG.INCLUDE_CPLL_CAL {2} \
    CONFIG.USER_GTPOWERGOOD_DELAY_EN {1} \
    CONFIG.DISABLE_LOC_XDC {1} \
    CONFIG.ENABLE_COMMON_USRCLK {0} \
] [get_ips taxi_eth_phy_25g_us_gth_ll_full]

puts "Generating output products for taxi transceiver IP..."
generate_target all [get_ips]

puts "Adding constraints..."
add_files -fileset constrs_1 -norecurse ./constraints/zcu106_taxi_10gbe.xdc

add_files -fileset constrs_1 -norecurse ./constraints/taxi/taxi_sync_reset.tcl
add_files -fileset constrs_1 -norecurse ./constraints/taxi/taxi_sync_signal.tcl
add_files -fileset constrs_1 -norecurse ./constraints/taxi/taxi_axis_async_fifo.tcl
add_files -fileset constrs_1 -norecurse ./constraints/taxi/taxi_eth_mac_fifo.tcl

set_property PROCESSING_ORDER LATE [get_files taxi_sync_reset.tcl]
set_property PROCESSING_ORDER LATE [get_files taxi_sync_signal.tcl]
set_property PROCESSING_ORDER LATE [get_files taxi_axis_async_fifo.tcl]
set_property PROCESSING_ORDER LATE [get_files taxi_eth_mac_fifo.tcl]

puts "Building Block Design..."
source ./bd.tcl

puts "Generating HDL Wrapper..."
set bd_name "v4_release"
make_wrapper -files [get_files ${bd_name}.bd] -top
add_files -norecurse ${project_dir}/${project_name}.gen/sources_1/bd/${bd_name}/hdl/${bd_name}_wrapper.v

set_property top ${bd_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

puts "Project generation complete"
