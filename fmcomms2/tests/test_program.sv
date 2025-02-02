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
//
//
//
`include "utils.svh"

import test_harness_env_pkg::*;
import adi_regmap_pkg::*;
import axi_vip_pkg::*;
import axi4stream_vip_pkg::*;
import logger_pkg::*;
import adi_regmap_dmac_pkg::*;
import adi_regmap_dac_pkg::*;
import adi_regmap_adc_pkg::*;
import adi_regmap_common_pkg::*;
`define RX_DMA       32'h7C40_0000
`define TX_DMA       32'h7C42_0000
`define AXI_AD9361   32'h7902_0000
`define DDR_BASE     32'h8000_0000
program test_program;

  parameter BASE = `AXI_AD9361;
  parameter R1_MODE = 0;

  parameter CH0 = 8'h00 * 4;
  parameter CH1 = 8'h10 * 4;
  parameter CH2 = 8'h20 * 4;
  parameter CH3 = 8'h30 * 4;

  parameter RX1_COMMON  = BASE + 'h00_00 * 4;
  parameter RX1_CHANNEL = BASE;

  parameter RX1_DLY = BASE + 'h02_00 * 4;

  parameter TX1_COMMON  = BASE + 'h10_00 * 4;
  parameter TX1_CHANNEL = BASE + 32'h0000_4000;

  parameter TDD1 = BASE + 'h12_00 * 4;
  

  test_harness_env env;
  bit [31:0] val;

  // --------------------------
  // Wrapper function for AXI read verify
  // --------------------------
  task axi_read_v();

      input   [31:0]  raddr;
      input   [31:0]  vdata;

  begin
    env.mng.RegReadVerify32(raddr,vdata);
  end
  endtask

  // --------------------------
  // Wrapper function for AXI write
  // --------------------------
  task axi_write;
    input [31:0]  waddr;
    input [31:0]  wdata;
  begin
    env.mng.RegWrite32(waddr,wdata);
  end
  endtask
  
  integer rate;
  initial begin
      rate = R1_MODE ? 2 : 4;
  end
  
  // --------------------------
  // Main procedure
  // --------------------------
  initial begin

    //creating environment
    env = new(`TH.`SYS_CLK.inst.IF,
              `TH.`DMA_CLK.inst.IF,
              `TH.`DDR_CLK.inst.IF,
              `TH.`MNG_AXI.inst.IF,
              `TH.`DDR_AXI.inst.IF);

    #2ps;

    setLoggerVerbosity(6);
    env.start();

    //set source synchronous interface clock frequency
    `TH.`SSI_CLK.inst.IF.set_clk_frq(.user_frequency(80000000));
    `TH.`SSI_CLK.inst.IF.start_clock;

    //asserts all the resets for 100 ns
    `TH.`SYS_RST.inst.IF.assert_reset;
    #100
    `TH.`SYS_RST.inst.IF.deassert_reset;

    #1us;
    // This is required since the AD9361 interface always requires to receive
    // something first before transmitting. This is not possible in loopback mode.
    force system_tb.test_harness.axi_ad9361.inst.i_tx.dac_sync_enable = 1'b1;

    sanity_test;

    pn_test();

    dds_test;

    dma_test;

    //dma_test;
    `INFO(("Test Done"));

  end

  // --------------------------
  // Sanity test reg interface
  // --------------------------
  task sanity_test;
  begin
    //check ADC VERSION
    axi_read_v (RX1_COMMON + GetAddrs(REG_VERSION),
               `SET_REG_VERSION_VERSION('h000a0162));
    //check DAC VERSION
    axi_read_v (TX1_COMMON + GetAddrs(REG_VERSION),
               `SET_REG_VERSION_VERSION('h00090162));
  end
  endtask

  // --------------------------
  // Setup link
  // --------------------------
  task link_setup;
  begin
    // Configure Rx interface
    axi_write (RX1_COMMON + GetAddrs(ADC_COMMON_REG_CNTRL),
              `SET_ADC_COMMON_REG_CNTRL_R1_MODE(R1_MODE));

    // Configure Tx interface
    axi_write (TX1_COMMON + GetAddrs(DAC_COMMON_REG_CNTRL_2), 
              `SET_DAC_COMMON_REG_CNTRL_2_R1_MODE(R1_MODE));
    axi_write (TX1_COMMON + GetAddrs(DAC_COMMON_REG_RATECNTRL),
              `SET_DAC_COMMON_REG_RATECNTRL_RATE(rate-1));
    
    // pull out RX of reset
    axi_write (RX1_COMMON + GetAddrs(ADC_COMMON_REG_RSTN),
              `SET_ADC_COMMON_REG_RSTN_RSTN(1));
    // pull out TX of reset
    axi_write (TX1_COMMON + GetAddrs(DAC_COMMON_REG_RSTN),
              `SET_DAC_COMMON_REG_RSTN_RSTN(1));

  end
  endtask

  // --------------------------
  // Link teardown
  // --------------------------
  task link_down;
  begin
    // put RX in reset
   axi_write (RX1_COMMON + GetAddrs(ADC_COMMON_REG_RSTN),
             `SET_ADC_COMMON_REG_RSTN_RSTN(0));
    // put TX in reset
   axi_write (TX1_COMMON + GetAddrs(DAC_COMMON_REG_RSTN),
             `SET_DAC_COMMON_REG_RSTN_RSTN(0));
   #1000;
  end
  endtask

  // --------------------------
  // Test pattern test
  // --------------------------
  task pn_test;
  begin


    link_setup;

    // enable test data for TX1
    axi_write (TX1_CHANNEL + CH0 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_7),
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_7_DAC_DDS_SEL(9));
    axi_write (TX1_CHANNEL + CH1 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_7),
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_7_DAC_DDS_SEL(9));
    if (R1_MODE==0) begin
    axi_write (TX1_CHANNEL + CH2 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_7),
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_7_DAC_DDS_SEL(9));
    axi_write (TX1_CHANNEL + CH3 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_7),
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_7_DAC_DDS_SEL(9));
    end

    // enable test data check for RX1
    axi_write (RX1_CHANNEL + CH0 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL_3),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_3_ADC_PN_SEL(9));
    axi_write (RX1_CHANNEL + CH1 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL_3),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_3_ADC_PN_SEL(9));
    if (R1_MODE==0) begin
    axi_write (RX1_CHANNEL + CH2 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL_3),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_3_ADC_PN_SEL(9));
    axi_write (RX1_CHANNEL + CH3 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL_3),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_3_ADC_PN_SEL(9));
    end
 
    // SYNC DAC channels
    axi_write (TX1_COMMON+GetAddrs(DAC_COMMON_REG_CNTRL_1),
              `SET_DAC_COMMON_REG_CNTRL_1_SYNC(1));
    // SYNC ADC channels
    axi_write (RX1_COMMON+GetAddrs(ADC_COMMON_REG_CNTRL),
              `SET_ADC_COMMON_REG_CNTRL_SYNC(1));

    // Allow initial OOS to propagate
    #15000;

    // clear PN OOS and PN ER   
    axi_write (RX1_CHANNEL + CH0 + GetAddrs(ADC_CHANNEL_REG_CHAN_STATUS),
              `SET_ADC_CHANNEL_REG_CHAN_STATUS_PN_ERR(1) |
              `SET_ADC_CHANNEL_REG_CHAN_STATUS_PN_OOS(1) |
              `SET_ADC_CHANNEL_REG_CHAN_STATUS_OVER_RANGE(1));
    axi_write (RX1_CHANNEL + CH1 + GetAddrs(ADC_CHANNEL_REG_CHAN_STATUS),
              `SET_ADC_CHANNEL_REG_CHAN_STATUS_PN_ERR(1) |
              `SET_ADC_CHANNEL_REG_CHAN_STATUS_PN_OOS(1) |
              `SET_ADC_CHANNEL_REG_CHAN_STATUS_OVER_RANGE(1));
    if (R1_MODE==0) begin
    axi_write (RX1_CHANNEL + CH2 + GetAddrs(ADC_CHANNEL_REG_CHAN_STATUS),
              `SET_ADC_CHANNEL_REG_CHAN_STATUS_PN_ERR(1) |
              `SET_ADC_CHANNEL_REG_CHAN_STATUS_PN_OOS(1) |
              `SET_ADC_CHANNEL_REG_CHAN_STATUS_OVER_RANGE(1));
    axi_write (RX1_CHANNEL + CH3 + GetAddrs(ADC_CHANNEL_REG_CHAN_STATUS),
              `SET_ADC_CHANNEL_REG_CHAN_STATUS_PN_ERR(1) |
              `SET_ADC_CHANNEL_REG_CHAN_STATUS_PN_OOS(1) |
              `SET_ADC_CHANNEL_REG_CHAN_STATUS_OVER_RANGE(1));
    end
    
    #10000;

    // check PN OOS and PN ERR flags
    axi_read_v (RX1_COMMON + GetAddrs(ADC_COMMON_REG_STATUS),
               `SET_ADC_COMMON_REG_STATUS_STATUS('h1));
    link_down;

  end
  endtask


  // --------------------------
  // DDS test procedure
  // --------------------------
  task dds_test;
  begin

    //  -------------------------------------------------------
    //  Test DDS path
    //  -------------------------------------------------------

    link_setup;

    // Select DDS as source
    axi_write (TX1_CHANNEL + CH0 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_7),
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_7_DAC_DDS_SEL(0));
    axi_write (TX1_CHANNEL + CH1 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_7), 
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_7_DAC_DDS_SEL(0));
    if (R1_MODE==0) begin
    axi_write (TX1_CHANNEL + CH2 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_7),
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_7_DAC_DDS_SEL(0));
    axi_write (TX1_CHANNEL + CH3 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_7),
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_7_DAC_DDS_SEL(0));
    end

    // enable normal data path for RX1
    axi_write (RX1_CHANNEL + CH0 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL_3),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_3_ADC_PN_SEL(0));
    axi_write (RX1_CHANNEL + CH1 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL_3),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_3_ADC_PN_SEL(0));
    if (R1_MODE==0) begin
    axi_write (RX1_CHANNEL + CH2 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL_3),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_3_ADC_PN_SEL(0));
    axi_write (RX1_CHANNEL + CH3 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL_3),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_3_ADC_PN_SEL(0));
    end

    // Configure tone amplitude and frequency
    axi_write (TX1_CHANNEL + CH0 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_1),
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_1_DDS_SCALE_1(16'h0fff));
    axi_write (TX1_CHANNEL + CH1 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_1), 
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_1_DDS_SCALE_1(16'h07ff));
    if (R1_MODE==0) begin
    axi_write (TX1_CHANNEL + CH2 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_1), 
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_1_DDS_SCALE_1(16'h03ff));
    axi_write (TX1_CHANNEL + CH3 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_1), 
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_1_DDS_SCALE_1(16'h01ff));
    end
    axi_write (TX1_CHANNEL + CH0 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_2), 
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_2_DDS_INCR_1(16'h0100));
    axi_write (TX1_CHANNEL + CH1 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_2), 
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_2_DDS_INCR_1(16'h0200));
    if (R1_MODE==0) begin
    axi_write (TX1_CHANNEL + CH2 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_2), 
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_2_DDS_INCR_1(16'h0400));
    axi_write (TX1_CHANNEL + CH3 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_2), 
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_2_DDS_INCR_1(16'h0800));
    end    

    // Enable Rx channel, enable sign extension
    axi_write (RX1_CHANNEL + CH0 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_SIGNEXT(1));
    axi_write (RX1_CHANNEL + CH1 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_SIGNEXT(1));
    if (R1_MODE==0) begin
    axi_write (RX1_CHANNEL + CH2 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_SIGNEXT(1));
    axi_write (RX1_CHANNEL + CH3 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_SIGNEXT(1));
    end
    // SYNC DAC channels
    axi_write (TX1_COMMON+GetAddrs(DAC_COMMON_REG_CNTRL_1),
              `SET_DAC_COMMON_REG_CNTRL_1_SYNC(1));
    // SYNC ADC channels 
    axi_write (RX1_COMMON+GetAddrs(ADC_COMMON_REG_CNTRL),
              `SET_ADC_COMMON_REG_CNTRL_SYNC(1));
    #20000;

    link_down;

  end
  endtask

  // --------------------------
  // DMA test procedure
  // --------------------------
  task dma_test;
  begin

    //  -------------------------------------------------------
    //  Test DMA path
    //  -------------------------------------------------------

    // Init test data
    for (int i=0;i<2048*2 ;i=i+2) begin
      env.ddr_axi_agent.mem_model.backdoor_memory_write_4byte(`DDR_BASE+i*2,(((i+1)<<4) << 16) | i<<4 ,15); // (<< 4) - 4 LSBs are dropped in the AXI_AD9361
    end

    // Configure TX DMA
    axi_write (`TX_DMA+GetAddrs(dmac_CONTROL), 
               `SET_dmac_CONTROL_ENABLE(1)); 
    axi_write (`TX_DMA+GetAddrs(dmac_X_LENGTH), 
               `SET_dmac_X_LENGTH_X_LENGTH(32'h00000FFF));
    axi_write (`TX_DMA+GetAddrs(dmac_FLAGS),
               `SET_dmac_FLAGS_CYCLIC(1)); 
    axi_write (`TX_DMA+GetAddrs(dmac_SRC_ADDRESS),
               `SET_dmac_SRC_ADDRESS_SRC_ADDRESS(`DDR_BASE+32'h00000000)); 
    axi_write (`TX_DMA+GetAddrs(dmac_TRANSFER_SUBMIT),
               `SET_dmac_TRANSFER_SUBMIT_TRANSFER_SUBMIT(1));
    // Select DDS as source
    axi_write (TX1_CHANNEL + CH0 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_7),
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_7_DAC_DDS_SEL(2));
    axi_write (TX1_CHANNEL + CH1 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_7),
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_7_DAC_DDS_SEL(2));
    if (R1_MODE==0) begin
    axi_write (TX1_CHANNEL + CH2 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_7),
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_7_DAC_DDS_SEL(2));
    axi_write (TX1_CHANNEL + CH3 + GetAddrs(DAC_CHANNEL_REG_CHAN_CNTRL_7),
              `SET_DAC_CHANNEL_REG_CHAN_CNTRL_7_DAC_DDS_SEL(2));
    end


    // enable normal data path for RX1
    axi_write (RX1_CHANNEL + CH0 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL_3),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_3_ADC_PN_SEL(0));
    axi_write (RX1_CHANNEL + CH1 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL_3),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_3_ADC_PN_SEL(0));
    if (R1_MODE==0) begin
    axi_write (RX1_CHANNEL + CH2 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL_3),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_3_ADC_PN_SEL(0));
    axi_write (RX1_CHANNEL + CH3 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL_3),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_3_ADC_PN_SEL(0));
    end


    // Enable Rx channel, enable sign extension

    axi_write (RX1_CHANNEL + CH0 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_SIGNEXT(1));
    axi_write (RX1_CHANNEL + CH1 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_SIGNEXT(1));
    if (R1_MODE==0) begin
    axi_write (RX1_CHANNEL + CH2 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_SIGNEXT(1));
    axi_write (RX1_CHANNEL + CH3 + GetAddrs(ADC_CHANNEL_REG_CHAN_CNTRL),
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_ENABLE(1) | 
              `SET_ADC_CHANNEL_REG_CHAN_CNTRL_FORMAT_SIGNEXT(1));
    end
    // SYNC DAC channels
    axi_write (TX1_COMMON+GetAddrs(DAC_COMMON_REG_CNTRL_1),
              `SET_DAC_COMMON_REG_CNTRL_1_SYNC(1));
    // SYNC ADC channels
    axi_write (RX1_COMMON+GetAddrs(ADC_COMMON_REG_CNTRL),
              `SET_ADC_COMMON_REG_CNTRL_SYNC(1));

    link_setup;

    #20us;

    // Configure RX DMA
    axi_write (`RX_DMA+GetAddrs(dmac_CONTROL),
               `SET_dmac_CONTROL_ENABLE(1));
    axi_write (`RX_DMA+GetAddrs(dmac_FLAGS),
               `SET_dmac_FLAGS_TLAST(1));
    axi_write (`RX_DMA+GetAddrs(dmac_X_LENGTH),
               `SET_dmac_X_LENGTH_X_LENGTH(32'h000003FF));
    axi_write (`RX_DMA+GetAddrs(dmac_DEST_ADDRESS),
               `SET_dmac_DEST_ADDRESS_DEST_ADDRESS(`DDR_BASE+32'h00002000));
    axi_write (`RX_DMA+GetAddrs(dmac_TRANSFER_SUBMIT),
               `SET_dmac_TRANSFER_SUBMIT_TRANSFER_SUBMIT(1));

    #10us;

    check_captured_data(
      .address (`DDR_BASE+'h00002000),
      .length (1024),
      .step (1),
      .max_sample(2048)
    );

  end
  endtask

  // Check captured data against incremental pattern based on first sample
  // Pattern should be contiguous
  task check_captured_data(bit [31:0] address,
                           int length = 1024,
                           int step = 1,
                           int max_sample = 2048
                          );

    bit [31:0] current_address;
    bit [31:0] captured_word;
    bit [31:0] reference_word;
    bit [15:0] first;

    for (int i=0;i<length/2;i=i+2) begin
      current_address = address+(i*2);
      captured_word = env.ddr_axi_agent.mem_model.backdoor_memory_read_4byte(current_address);
      if (i==0) begin
        first = captured_word[15:0];
      end else begin
        reference_word = (((first + (i+1)*step)%max_sample) << 16) | ((first + (i*step))%max_sample);

        if (captured_word !== reference_word) begin
          `ERROR(("Address 0x%h Expected 0x%h found 0x%h",current_address,reference_word,captured_word));
        end else begin
          `INFO(("Address 0x%h Expected 0x%h found 0x%h",current_address,reference_word,captured_word));
        end
      end

    end
  endtask
endprogram
