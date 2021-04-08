# ***************************************************************************
# ***************************************************************************
# Copyright 2018 (c) Analog Devices, Inc. All rights reserved.
#
# In this HDL repository, there are many different and unique modules, consisting
# of various HDL (Verilog or VHDL) components. The individual modules are
# developed independently, and may be accompanied by separate and unique license
# terms.
#
# The user should read each of these license terms, and understand the
# freedoms and responsibilities that he or she has by using this source/core.
#
# This core is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.
#
# Redistribution and use of source or resulting binaries, with or without modification
# of this file, are permitted under one of the following two license terms:
#
#   1. The GNU General Public License version 2 as published by the
#      Free Software Foundation, which can be found in the top level directory
#      of this repository (LICENSE_GPL2), and also online at:
#      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
#
# OR
#
#   2. An ADI specific BSD license, which can be found in the top level directory
#      of this repository (LICENSE_ADIBSD), and also on-line at:
#      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
#      This will allow to generate bit files and not release the source code,
#      as long as it attaches to an ADI device.
#
# ***************************************************************************
# ***************************************************************************

source ../../library/scripts/adi_env.tcl

global ad_project_params

# Ref clk
ad_ip_instance clk_vip ref_clk_vip [ list \
  INTERFACE_MODE {MASTER} \
  FREQ_HZ 250000000 \
]
adi_sim_add_define "REF_CLK=ref_clk_vip"
create_bd_port -dir O ref_clk_out
ad_connect ref_clk_out ref_clk_vip/clk_out

# Device clk
ad_ip_instance clk_vip device_clk_vip [ list \
  INTERFACE_MODE {MASTER} \
  FREQ_HZ 250000000 \
]
adi_sim_add_define "DEVICE_CLK=device_clk_vip"
create_bd_port -dir O device_clk_out
ad_connect device_clk_out device_clk_vip/clk_out

# SYSREF clk
ad_ip_instance clk_vip sysref_clk_vip [ list \
  INTERFACE_MODE {MASTER} \
  FREQ_HZ 5000000 \
]
adi_sim_add_define "SYSREF_CLK=sysref_clk_vip"
create_bd_port -dir O sysref_clk_out
ad_connect sysref_clk_out sysref_clk_vip/clk_out





#  ------------------
#  DUT
#  ------------------

# test only two QUAD MxFEs due simulation performance limitations
set NUM_OF_QUAD_MXFES 2

source $ad_hdl_dir/projects/quad_quad_mxfe/common/jesd_cores_bd.tcl


#  ------------------
#  Test harness
#  ------------------

#global mng_axi_cfg
#
## add interconnect
## config
#ad_ip_instance axi_interconnect axi_cfg_interconnect [ list \
#  NUM_SI {1} \
#  NUM_MI $NUM_OF_QUAD_MXFES \
#]
#
#
## Create instance: mng_axi , and set properties
## VIP for management port
##ad_ip_instance axi_vip mng_axi_vip $mng_axi_cfg
##adi_sim_add_define "MNG_AXI=mng_axi_vip"
#
#ad_connect mng_axi_vip/M_AXI  axi_cfg_interconnect/S00_AXI

set m_count [get_property CONFIG.NUM_MI [get_bd_cells axi_cpu_interconnect]]
set_property CONFIG.NUM_MI [expr $m_count+$NUM_OF_QUAD_MXFES] [get_bd_cells axi_cpu_interconnect]

for {set i 0} {$i < $NUM_OF_QUAD_MXFES} {incr i} {
  set m_idx [expr $i+$m_count]
  ad_connect axi_cpu_interconnect/M0${m_idx}_AXI qmxfe${i}/interconnect/S00_AXI
  ad_connect $sys_cpu_clk axi_cpu_interconnect/M0${m_idx}_ACLK
  ad_connect $sys_cpu_resetn axi_cpu_interconnect/M0${m_idx}_ARESETN
}

#
#ad_connect mng_rstn mng_axi_vip/aresetn
#ad_connect mng_rstn axi_cfg_interconnect/ARESETN
#ad_connect mng_rstn axi_cfg_interconnect/S00_ARESETN
#for {set i 0} {$i < $NUM_OF_QUAD_MXFES} {incr i} {
#ad_connect mng_rstn axi_cfg_interconnect/M0${i}_ARESETN
#}
#
#connect_bd_net [get_bd_ports mng_rst] [get_bd_pins device_clk_rstgen/ext_reset_in]
#
#ad_connect mng_clk mng_axi_vip/aclk
#ad_connect mng_clk axi_cfg_interconnect/ACLK
#ad_connect mng_clk axi_cfg_interconnect/S00_ACLK
#for {set i 0} {$i < $NUM_OF_QUAD_MXFES} {incr i} {
#ad_connect mng_clk axi_cfg_interconnect/M0${i}_ACLK
#}
#
assign_bd_address


for {set i 0} {$i < 32*$NUM_OF_QUAD_MXFES} {incr i} {
  create_bd_port -from 0 -to 15 -dir I "dac_data_${i}"
  ad_connect dac_data_$i  qmxfe[expr $i/32]/dac_data_[expr $i %32]
}

for {set i 0} {$i < 32*$NUM_OF_QUAD_MXFES} {incr i} {
  create_bd_port -from 0 -to 15 -dir O "adc_data_${i}"
  ad_connect adc_data_$i  qmxfe[expr $i/32]/adc_data_[expr $i %32]
}



