# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_S00_AXIS_TDATA_WIDTH" -parent ${Page_0} -widget comboBox


}

proc update_PARAM_VALUE.MSG_W { PARAM_VALUE.MSG_W } {
	# Procedure called to update MSG_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MSG_W { PARAM_VALUE.MSG_W } {
	# Procedure called to validate MSG_W
	return true
}

proc update_PARAM_VALUE.ORN_W { PARAM_VALUE.ORN_W } {
	# Procedure called to update ORN_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ORN_W { PARAM_VALUE.ORN_W } {
	# Procedure called to validate ORN_W
	return true
}

proc update_PARAM_VALUE.PACKET_W { PARAM_VALUE.PACKET_W } {
	# Procedure called to update PACKET_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PACKET_W { PARAM_VALUE.PACKET_W } {
	# Procedure called to validate PACKET_W
	return true
}

proc update_PARAM_VALUE.PRICE_W { PARAM_VALUE.PRICE_W } {
	# Procedure called to update PRICE_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PRICE_W { PARAM_VALUE.PRICE_W } {
	# Procedure called to validate PRICE_W
	return true
}

proc update_PARAM_VALUE.SHARES_W { PARAM_VALUE.SHARES_W } {
	# Procedure called to update SHARES_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SHARES_W { PARAM_VALUE.SHARES_W } {
	# Procedure called to validate SHARES_W
	return true
}

proc update_PARAM_VALUE.STOCK_W { PARAM_VALUE.STOCK_W } {
	# Procedure called to update STOCK_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.STOCK_W { PARAM_VALUE.STOCK_W } {
	# Procedure called to validate STOCK_W
	return true
}

proc update_PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH { PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH } {
	# Procedure called to update C_S00_AXIS_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH { PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH } {
	# Procedure called to validate C_S00_AXIS_TDATA_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXIS_TDATA_WIDTH { MODELPARAM_VALUE.C_S00_AXIS_TDATA_WIDTH PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXIS_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.ORN_W { MODELPARAM_VALUE.ORN_W PARAM_VALUE.ORN_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ORN_W}] ${MODELPARAM_VALUE.ORN_W}
}

proc update_MODELPARAM_VALUE.PRICE_W { MODELPARAM_VALUE.PRICE_W PARAM_VALUE.PRICE_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PRICE_W}] ${MODELPARAM_VALUE.PRICE_W}
}

proc update_MODELPARAM_VALUE.SHARES_W { MODELPARAM_VALUE.SHARES_W PARAM_VALUE.SHARES_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SHARES_W}] ${MODELPARAM_VALUE.SHARES_W}
}

proc update_MODELPARAM_VALUE.PACKET_W { MODELPARAM_VALUE.PACKET_W PARAM_VALUE.PACKET_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PACKET_W}] ${MODELPARAM_VALUE.PACKET_W}
}

proc update_MODELPARAM_VALUE.STOCK_W { MODELPARAM_VALUE.STOCK_W PARAM_VALUE.STOCK_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.STOCK_W}] ${MODELPARAM_VALUE.STOCK_W}
}

proc update_MODELPARAM_VALUE.MSG_W { MODELPARAM_VALUE.MSG_W PARAM_VALUE.MSG_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MSG_W}] ${MODELPARAM_VALUE.MSG_W}
}
