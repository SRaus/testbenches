// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2018 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsabilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/1ps

`include "utils.svh"

module system_tb();

parameter JESD_MODE = "8B10B";
parameter REF_CLK_RATE = 500;
parameter RX_RATE = 10;
parameter TX_RATE = 10;
parameter RX_NUM_LINKS = 1;
parameter RX_JESD_M = 8;
parameter RX_JESD_L = 4;
parameter RX_JESD_S = 1;
parameter RX_JESD_NP = 16;
parameter RX_JESD_F = 4;
parameter RX_JESD_K = 32;
parameter TX_NUM_LINKS = 1;
parameter TX_JESD_M = 8;
parameter TX_JESD_L = 4;
parameter TX_JESD_S = 1;
parameter TX_JESD_NP = 16;
parameter TX_JESD_F = 4;
parameter TX_JESD_K = 32;

  wire rx_sync_0;

  `TEST_PROGRAM #(
                .JESD_MODE (JESD_MODE),
                .REF_CLK_RATE (REF_CLK_RATE),
                .RX_RATE  (RX_RATE),
                .TX_RATE  (TX_RATE),
                .RX_NUM_LINKS (RX_NUM_LINKS),
                .RX_JESD_M  (RX_JESD_M),
                .RX_JESD_L  (RX_JESD_L),
                .RX_JESD_S  (RX_JESD_S),
                .RX_JESD_NP (RX_JESD_NP),
                .RX_JESD_F  (RX_JESD_F),
                .RX_JESD_K  (RX_JESD_K),
                .TX_NUM_LINKS (TX_NUM_LINKS),
                .TX_JESD_M  (TX_JESD_M),
                .TX_JESD_L  (TX_JESD_L),
                .TX_JESD_S  (TX_JESD_S),
                .TX_JESD_NP (TX_JESD_NP),
                .TX_JESD_F  (TX_JESD_F),
                .TX_JESD_K  (TX_JESD_K)) test ();

  test_harness `TH (
    .ref_clk_out    (ref_clk),
    .device_clk_out (device_clk),
    .sysref_clk_out (sysref),

    .rx_device_clk  (device_clk),      //-dir I
    .tx_device_clk  (device_clk),      //-dir I
    .rx_data_0_n    (data_0_n),        //-dir I
    .rx_data_0_p    (data_0_p),        //-dir I
    .rx_data_1_n    (data_1_n),        //-dir I
    .rx_data_1_p    (data_1_p),        //-dir I
    .rx_data_2_n    (data_2_n),        //-dir I
    .rx_data_2_p    (data_2_p),        //-dir I
    .rx_data_3_n    (data_3_n),        //-dir I
    .rx_data_3_p    (data_3_p),        //-dir I
    .rx_data_4_n    (data_4_n),        //-dir I
    .rx_data_4_p    (data_4_p),        //-dir I
    .rx_data_5_n    (data_5_n),        //-dir I
    .rx_data_5_p    (data_5_p),        //-dir I
    .rx_data_6_n    (data_6_n),        //-dir I
    .rx_data_6_p    (data_6_p),        //-dir I
    .rx_data_7_n    (data_7_n),        //-dir I
    .rx_data_7_p    (data_7_p),        //-dir I
    .tx_data_0_n    (data_0_n),        //-dir O
    .tx_data_0_p    (data_0_p),        //-dir O
    .tx_data_1_n    (data_1_n),        //-dir O
    .tx_data_1_p    (data_1_p),        //-dir O
    .tx_data_2_n    (data_2_n),        //-dir O
    .tx_data_2_p    (data_2_p),        //-dir O
    .tx_data_3_n    (data_3_n),        //-dir O
    .tx_data_3_p    (data_3_p),        //-dir O
    .tx_data_4_n    (data_4_n),        //-dir O
    .tx_data_4_p    (data_4_p),        //-dir O
    .tx_data_5_n    (data_5_n),        //-dir O
    .tx_data_5_p    (data_5_p),        //-dir O
    .tx_data_6_n    (data_6_n),        //-dir O
    .tx_data_6_p    (data_6_p),        //-dir O
    .tx_data_7_n    (data_7_n),        //-dir O
    .tx_data_7_p    (data_7_p),        //-dir O
    .rx_sysref_0    (sysref),          //-dir I
    .tx_sysref_0    (sysref),          //-dir I
    .rx_sync_0      (rx_sync_0),       //-dir O
    .tx_sync_0      (rx_sync_0),       //-dir I
    .ref_clk_q0     (ref_clk),         //-dir I
    .ref_clk_q1     (ref_clk),         //-dir I
    .dac_fifo_bypass(1'b0)             //-dir I

  );

endmodule
