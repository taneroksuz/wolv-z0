import configure::*;

module soc
(
  input logic rst,
  input logic clk,
  input logic rx,
  output logic tx
);
  timeunit 1ns;
  timeprecision 1ps;

  logic rtc = 0;
  logic [31 : 0] count = 0;

  logic clk_pll = 0;
  logic [31 : 0] count_pll = 0;

  logic [0  : 0] memory_valid;
  logic [0  : 0] memory_instr;
  logic [31 : 0] memory_addr;
  logic [31 : 0] memory_wdata;
  logic [3  : 0] memory_wstrb;
  logic [31 : 0] memory_rdata;
  logic [0  : 0] memory_ready;

  logic [0  : 0] bram_valid;
  logic [0  : 0] bram_instr;
  logic [31 : 0] bram_addr;
  logic [31 : 0] bram_wdata;
  logic [3  : 0] bram_wstrb;
  logic [31 : 0] bram_rdata;
  logic [0  : 0] bram_ready;

  logic [0  : 0] uart_valid;
  logic [0  : 0] uart_instr;
  logic [31 : 0] uart_addr;
  logic [31 : 0] uart_wdata;
  logic [3  : 0] uart_wstrb;
  logic [31 : 0] uart_rdata;
  logic [0  : 0] uart_ready;

  logic [0  : 0] clint_valid;
  logic [0  : 0] clint_instr;
  logic [31 : 0] clint_addr;
  logic [31 : 0] clint_wdata;
  logic [3  : 0] clint_wstrb;
  logic [31 : 0] clint_rdata;
  logic [0  : 0] clint_ready;

  logic [2**plic_contexts-1 : 0] meip;
  logic [2**clint_contexts-1 : 0] msip;
  logic [2**clint_contexts-1 : 0] mtip;

  logic [63 : 0] mtime;

  always_ff @(posedge clk) begin
    if (count == clk_divider_rtc) begin
      rtc <= ~rtc;
      count <= 0;
    end else begin
      count <= count + 1;
    end
    if (count_pll == clk_divider_pll) begin
      clk_pll <= ~clk_pll;
      count_pll <= 0;
    end else begin
      count_pll <= count_pll + 1;
    end
  end

  always_comb begin

    if (memory_addr >= uart_base_addr &&
          memory_addr < uart_top_addr) begin
      bram_valid = 0;
      clint_valid = 0;
      uart_valid = memory_valid;
    end else if (memory_addr >= clint_base_address &&
          memory_addr < clint_top_address) begin
      bram_valid = 0;
      clint_valid = memory_valid;
      uart_valid = 0;
    end else begin
      bram_valid = memory_valid;
      clint_valid = 0;
      uart_valid = 0;
    end

    bram_instr = memory_instr;
    bram_addr = memory_addr;
    bram_wdata = memory_wdata;
    bram_wstrb = memory_wstrb;

    clint_instr = memory_instr;
    clint_addr = memory_addr ^ clint_base_address;
    clint_wdata = memory_wdata;
    clint_wstrb = memory_wstrb;

    uart_instr = memory_instr;
    uart_addr = memory_addr ^ uart_base_addr;
    uart_wdata = memory_wdata;
    uart_wstrb = memory_wstrb;

    if (bram_ready == 1) begin
      memory_rdata = bram_rdata;
      memory_ready = bram_ready;
    end else if  (uart_ready == 1) begin
      memory_rdata = uart_rdata;
      memory_ready = uart_ready;
    end else if  (clint_ready == 1) begin
      memory_rdata = clint_rdata;
      memory_ready = clint_ready;
    end else begin
      memory_rdata = 0;
      memory_ready = 0;
    end

  end

  cpu cpu_comp
  (
    .rst (rst),
    .clk (clk_pll),
    .memory_valid (memory_valid),
    .memory_instr (memory_instr),
    .memory_addr (memory_addr),
    .memory_wdata (memory_wdata),
    .memory_wstrb (memory_wstrb),
    .memory_rdata (memory_rdata),
    .memory_ready (memory_ready),
    .meip (meip[0]),
    .msip (msip[0]),
    .mtip (mtip[0]),
    .mtime (mtime)
  );

  bram bram_comp
  (
    .rst (rst),
    .clk (clk_pll),
    .bram_valid (bram_valid),
    .bram_instr (bram_instr),
    .bram_addr (bram_addr),
    .bram_wdata (bram_wdata),
    .bram_wstrb (bram_wstrb),
    .bram_rdata (bram_rdata),
    .bram_ready (bram_ready)
  );

  uart uart_comp
  (
    .rst (rst),
    .clk (clk_pll),
    .uart_valid (uart_valid),
    .uart_instr (uart_instr),
    .uart_addr (uart_addr),
    .uart_wdata (uart_wdata),
    .uart_wstrb (uart_wstrb),
    .uart_rdata (uart_rdata),
    .uart_ready (uart_ready),
    .uart_rx (rx),
    .uart_tx (tx)
  );

  clint clint_comp
  (
    .rst (rst),
    .clk (clk_pll),
    .rtc (rtc),
    .clint_valid (clint_valid),
    .clint_instr (clint_instr),
    .clint_addr (clint_addr),
    .clint_wdata (clint_wdata),
    .clint_wstrb (clint_wstrb),
    .clint_rdata (clint_rdata),
    .clint_ready (clint_ready),
    .clint_msip (msip),
    .clint_mtip (mtip),
    .clint_mtime (mtime)
  );

endmodule
