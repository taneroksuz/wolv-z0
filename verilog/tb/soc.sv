import configure::*;

module soc();

  timeunit 1ns;
  timeprecision 1ps;

  logic reset;
  logic clock;
  logic clock_irpt;

  logic [0  : 0] rvfi_valid;
  logic [63 : 0] rvfi_order;
  logic [31 : 0] rvfi_insn;
  logic [0  : 0] rvfi_trap;
  logic [0  : 0] rvfi_halt;
  logic [0  : 0] rvfi_intr;
  logic [1  : 0] rvfi_mode;
  logic [1  : 0] rvfi_ixl;
  logic [4  : 0] rvfi_rs1_addr;
  logic [4  : 0] rvfi_rs2_addr;
  logic [31 : 0] rvfi_rs1_rdata;
  logic [31 : 0] rvfi_rs2_rdata;
  logic [4  : 0] rvfi_rd_addr;
  logic [31 : 0] rvfi_rd_wdata;
  logic [31 : 0] rvfi_pc_rdata;
  logic [31 : 0] rvfi_pc_wdata;
  logic [31 : 0] rvfi_mem_addr;
  logic [3  : 0] rvfi_mem_rmask;
  logic [3  : 0] rvfi_mem_wmask;
  logic [31 : 0] rvfi_mem_rdata;
  logic [31 : 0] rvfi_mem_wdata;

  logic [0  : 0] imemory_valid;
  logic [0  : 0] imemory_instr;
  logic [31 : 0] imemory_addr;
  logic [31 : 0] imemory_wdata;
  logic [3  : 0] imemory_wstrb;
  logic [31 : 0] imemory_rdata;
  logic [0  : 0] imemory_error;
  logic [0  : 0] imemory_ready;

  logic [0  : 0] dmemory_valid;
  logic [0  : 0] dmemory_instr;
  logic [31 : 0] dmemory_addr;
  logic [31 : 0] dmemory_wdata;
  logic [3  : 0] dmemory_wstrb;
  logic [31 : 0] dmemory_rdata;
  logic [0  : 0] dmemory_error;
  logic [0  : 0] dmemory_ready;

  logic [0  : 0] memory_valid;
  logic [0  : 0] memory_instr;
  logic [31 : 0] memory_addr;
  logic [31 : 0] memory_wdata;
  logic [3  : 0] memory_wstrb;
  logic [31 : 0] memory_rdata;
  logic [0  : 0] memory_error;
  logic [0  : 0] memory_ready;

  logic [0  : 0] mem_error;
  logic [0  : 0] mem_ready;

  logic [0  : 0] rom_valid;
  logic [0  : 0] rom_instr;
  logic [31 : 0] rom_addr;
  logic [31 : 0] rom_rdata;
  logic [0  : 0] rom_ready;

  logic [0  : 0] print_valid;
  logic [0  : 0] print_instr;
  logic [31 : 0] print_addr;
  logic [31 : 0] print_wdata;
  logic [3  : 0] print_wstrb;
  logic [31 : 0] print_rdata;
  logic [0  : 0] print_ready;

  logic [0  : 0] clint_valid;
  logic [0  : 0] clint_instr;
  logic [31 : 0] clint_addr;
  logic [31 : 0] clint_wdata;
  logic [3  : 0] clint_wstrb;
  logic [31 : 0] clint_rdata;
  logic [0  : 0] clint_ready;

  logic [0  : 0] clic_valid;
  logic [0  : 0] clic_instr;
  logic [31 : 0] clic_addr;
  logic [31 : 0] clic_wdata;
  logic [3  : 0] clic_wstrb;
  logic [31 : 0] clic_rdata;
  logic [0  : 0] clic_ready;

  logic [0  : 0] bram_valid;
  logic [0  : 0] bram_instr;
  logic [31 : 0] bram_addr;
  logic [31 : 0] bram_wdata;
  logic [3  : 0] bram_wstrb;
  logic [31 : 0] bram_rdata;
  logic [0  : 0] bram_ready;

  logic [0 : 0] meip;
  logic [0 : 0] msip;
  logic [0 : 0] mtip;

  logic [31: 0] irpt;

  logic [11 : 0] meid;
  logic [63 : 0] mtime;

  logic [31 : 0] mem_addr;

  logic [31 : 0] base_addr;

  logic [31 : 0] host[0:0] = '{default:'0};

  logic [31 : 0] stoptime = 10000000;
  logic [31 : 0] counter = 0;

  integer reg_file;
  integer csr_file;
  integer pmp_file;
  integer mem_file;

  initial begin
    $readmemh("host.dat", host);
  end

  initial begin
    string filename;
    if ($value$plusargs("FILENAME=%s",filename)) begin
      $dumpfile(filename);
      $dumpvars(0, soc);
    end
  end

  initial begin
    string maxtime;
    if ($value$plusargs("MAXTIME=%s",maxtime)) begin
      stoptime = maxtime.atoi();
    end
  end

  initial begin
    reset = 0;
    clock = 1;
    clock_irpt = 1;
  end

  initial begin
    #10 reset = 1;
  end

  always #0.5 clock = ~clock;
  always #2 clock_irpt = ~clock_irpt;

  initial begin
    string filename;
    if ($value$plusargs("REGFILE=%s",filename)) begin
      reg_file = $fopen(filename,"w");
      for (int i=0; i<stoptime; i=i+1) begin
        @(posedge clock);
        if (soc.cpu_comp.register_comp.register_win.wren == 1) begin
          $fwrite(reg_file,"PERIOD = %t\t",$time);
          $fwrite(reg_file,"WADDR = %d\t",soc.cpu_comp.register_comp.register_win.waddr);
          $fwrite(reg_file,"WDATA = %x\n",soc.cpu_comp.register_comp.register_win.wdata);
        end
      end
      $fclose(reg_file);
    end
  end

  initial begin
    string filename;
    if ($value$plusargs("CSRFILE=%s",filename)) begin
      csr_file = $fopen(filename,"w");
      for (int i=0; i<stoptime; i=i+1) begin
        @(posedge clock);
        if (soc.cpu_comp.csr_comp.csr_in.cwren == 1) begin
          $fwrite(csr_file,"PERIOD = %t\t",$time);
          $fwrite(csr_file,"WADDR = %x\t",soc.cpu_comp.csr_comp.csr_in.cwaddr);
          $fwrite(csr_file,"WDATA = %x\n",soc.cpu_comp.csr_comp.csr_in.cwdata);
        end
      end
      $fclose(csr_file);
    end
  end

  initial begin
    string filename;
    if ($value$plusargs("PMPFILE=%s",filename)) begin
      pmp_file = $fopen(filename,"w");
      for (int i=0; i<stoptime; i=i+1) begin
        @(posedge clock);
        if (soc.cpu_comp.pmp_comp.csr_pmp_in.cwren == 1) begin
          $fwrite(pmp_file,"PERIOD = %t\t",$time);
          $fwrite(pmp_file,"WADDR = %x\t",soc.cpu_comp.pmp_comp.csr_pmp_in.cwaddr);
          $fwrite(pmp_file,"WDATA = %x\n",soc.cpu_comp.pmp_comp.csr_pmp_in.cwaddr);
        end
      end
      $fclose(pmp_file);
    end
  end

  initial begin
    string filename;
    if ($value$plusargs("MEMFILE=%s",filename)) begin
      mem_file = $fopen(filename,"w");
      for (int i=0; i<stoptime; i=i+1) begin
        @(posedge clock);
        if (soc.bram_comp.bram_valid == 1) begin
          if (|soc.bram_comp.bram_wstrb == 1) begin
            $fwrite(mem_file,"PERIOD = %t\t",$time);
            $fwrite(mem_file,"WADDR = %x\t",soc.bram_comp.bram_addr);
            $fwrite(mem_file,"WSTRB = %b\t",soc.bram_comp.bram_wstrb);
            $fwrite(mem_file,"WDATA = %x\n",soc.bram_comp.bram_wdata);
          end
        end
      end
      $fclose(mem_file);
    end
  end

  always_ff @(posedge clock) begin
    if (counter == stoptime) begin
      $write("%c[1;33m",8'h1B);
      $display("TEST STOPPED");
      $write("%c[0m",8'h1B);
      $finish;
    end else begin
      counter <= counter + 1;
    end
  end

  always_ff @(posedge clock) begin
    if (soc.cpu_comp.fetch_stage_comp.dmem_in.mem_valid == 1) begin
      if (soc.cpu_comp.fetch_stage_comp.dmem_in.mem_addr[31:2] == host[0][31:2]) begin
        if (|soc.cpu_comp.fetch_stage_comp.dmem_in.mem_wstrb == 1) begin
          if (soc.cpu_comp.fetch_stage_comp.dmem_in.mem_wdata == 32'h1) begin
            $write("%c[1;32m",8'h1B);
            $display("TEST SUCCEEDED");
            $write("%c[0m",8'h1B);
            $finish;
          end else begin
            $write("%c[1;31m",8'h1B);
            $display("TEST FAILED");
            $write("%c[0m",8'h1B);
            $finish;
          end
        end
      end
    end
  end

  always_comb begin

    mem_error = 0;

    rom_valid = 0;
    print_valid = 0;
    clint_valid = 0;
    clic_valid = 0;
    bram_valid = 0;

    base_addr = 0;

    if (memory_valid == 1) begin
      if (memory_addr >= bram_base_addr &&
        memory_addr < bram_top_addr) begin
          mem_error = 0;
          rom_valid = 0;
          print_valid = 0;
          clint_valid = 0;
          clic_valid = 0;
          bram_valid = memory_valid;
          base_addr = bram_base_addr;
      end else if (memory_addr >= clic_base_addr &&
        memory_addr < clic_top_addr) begin
          mem_error = 0;
          rom_valid = 0;
          print_valid = 0;
          clint_valid = 0;
          clic_valid = memory_valid;
          bram_valid = 0;
          base_addr = clic_base_addr;
      end else if (memory_addr >= clint_base_addr &&
        memory_addr < clint_top_addr) begin
          mem_error = 0;
          rom_valid = 0;
          print_valid = 0;
          clint_valid = memory_valid;
          clic_valid = 0;
          bram_valid = 0;
          base_addr = clint_base_addr;
      end else if (memory_addr >= print_base_addr &&
        memory_addr < print_top_addr) begin
          mem_error = 0;
          rom_valid = 0;
          print_valid = memory_valid;
          clint_valid = 0;
          clic_valid = 0;
          bram_valid = 0;
          base_addr = print_base_addr;
      end else if (memory_addr >= rom_base_addr &&
        memory_addr < rom_top_addr) begin
          mem_error = 0;
          rom_valid = memory_valid;
          print_valid = 0;
          clint_valid = 0;
          clic_valid = 0;
          bram_valid = 0;
          base_addr = rom_base_addr;
      end else begin
          mem_error = 1;
          rom_valid = 0;
          print_valid = 0;
          clint_valid = 0;
          clic_valid = 0;
          bram_valid = 0;
          base_addr = 0;
      end
    end

    mem_addr = memory_addr - base_addr;

    rom_instr = memory_instr;
    rom_addr = mem_addr;

    print_instr = memory_instr;
    print_addr = mem_addr;
    print_wdata = memory_wdata;
    print_wstrb = memory_wstrb;

    clint_instr = memory_instr;
    clint_addr = mem_addr;
    clint_wdata = memory_wdata;
    clint_wstrb = memory_wstrb;

    clic_instr = memory_instr;
    clic_addr = mem_addr;
    clic_wdata = memory_wdata;
    clic_wstrb = memory_wstrb;

    bram_instr = memory_instr;
    bram_addr = mem_addr;
    bram_wdata = memory_wdata;
    bram_wstrb = memory_wstrb;

    if (rom_ready == 1) begin
      memory_rdata = rom_rdata;
      memory_error = 0;
      memory_ready = rom_ready;
    end else if (print_ready == 1) begin
      memory_rdata = print_rdata;
      memory_error = 0;
      memory_ready = print_ready;
    end else if (clint_ready == 1) begin
      memory_rdata = clint_rdata;
      memory_error = 0;
      memory_ready = clint_ready;
    end else if (clic_ready == 1) begin
      memory_rdata = clic_rdata;
      memory_error = 0;
      memory_ready = clic_ready;
    end else if (bram_ready == 1) begin
      memory_rdata = bram_rdata;
      memory_error = 0;
      memory_ready = bram_ready;
    end else if (mem_ready == 1) begin
      memory_rdata = 0;
      memory_error = 1;
      memory_ready = 1;
    end else begin
      memory_rdata = 0;
      memory_error = 0;
      memory_ready = 0;
    end

  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      mem_ready <= 0;
    end else begin
      mem_ready <= mem_error;
    end
  end

  cpu cpu_comp
  (
    .reset (reset),
    .clock (clock),
    .rvfi_valid (rvfi_valid),
    .rvfi_order (rvfi_order),
    .rvfi_insn (rvfi_insn),
    .rvfi_trap (rvfi_trap),
    .rvfi_halt (rvfi_halt),
    .rvfi_intr (rvfi_intr),
    .rvfi_mode (rvfi_mode),
    .rvfi_ixl (rvfi_ixl),
    .rvfi_rs1_addr (rvfi_rs1_addr),
    .rvfi_rs2_addr (rvfi_rs2_addr),
    .rvfi_rs1_rdata (rvfi_rs1_rdata),
    .rvfi_rs2_rdata (rvfi_rs2_rdata),
    .rvfi_rd_addr (rvfi_rd_addr),
    .rvfi_rd_wdata (rvfi_rd_wdata),
    .rvfi_pc_rdata (rvfi_pc_rdata),
    .rvfi_pc_wdata (rvfi_pc_wdata),
    .rvfi_mem_addr (rvfi_mem_addr),
    .rvfi_mem_rmask (rvfi_mem_rmask),
    .rvfi_mem_wmask (rvfi_mem_wmask),
    .rvfi_mem_rdata (rvfi_mem_rdata),
    .rvfi_mem_wdata (rvfi_mem_wdata),
    .imemory_valid (imemory_valid),
    .imemory_instr (imemory_instr),
    .imemory_addr (imemory_addr),
    .imemory_wdata (imemory_wdata),
    .imemory_wstrb (imemory_wstrb),
    .imemory_rdata (imemory_rdata),
    .imemory_error (imemory_error),
    .imemory_ready (imemory_ready),
    .dmemory_valid (dmemory_valid),
    .dmemory_instr (dmemory_instr),
    .dmemory_addr (dmemory_addr),
    .dmemory_wdata (dmemory_wdata),
    .dmemory_wstrb (dmemory_wstrb),
    .dmemory_rdata (dmemory_rdata),
    .dmemory_error (dmemory_error),
    .dmemory_ready (dmemory_ready),
    .meip (meip),
    .msip (msip),
    .mtip (mtip),
    .mtime (mtime)
  );

  arbiter arbiter_comp
  (
    .reset (reset),
    .clock (clock),
    .imemory_valid (imemory_valid),
    .imemory_instr (imemory_instr),
    .imemory_addr (imemory_addr),
    .imemory_wdata (imemory_wdata),
    .imemory_wstrb (imemory_wstrb),
    .imemory_rdata (imemory_rdata),
    .imemory_error (imemory_error),
    .imemory_ready (imemory_ready),
    .dmemory_valid (dmemory_valid),
    .dmemory_instr (dmemory_instr),
    .dmemory_addr (dmemory_addr),
    .dmemory_wdata (dmemory_wdata),
    .dmemory_wstrb (dmemory_wstrb),
    .dmemory_rdata (dmemory_rdata),
    .dmemory_error (dmemory_error),
    .dmemory_ready (dmemory_ready),
    .memory_valid (memory_valid),
    .memory_instr (memory_instr),
    .memory_addr (memory_addr),
    .memory_wdata (memory_wdata),
    .memory_wstrb (memory_wstrb),
    .memory_rdata (memory_rdata),
    .memory_error (memory_error),
    .memory_ready (memory_ready)
  );

  rom rom_comp
  (
    .reset (reset),
    .clock (clock),
    .rom_valid (rom_valid),
    .rom_instr (rom_instr),
    .rom_addr (rom_addr),
    .rom_rdata (rom_rdata),
    .rom_ready (rom_ready)
  );

  print print_comp
  (
    .reset (reset),
    .clock (clock),
    .print_valid (print_valid),
    .print_instr (print_instr),
    .print_addr (print_addr),
    .print_wdata (print_wdata),
    .print_wstrb (print_wstrb),
    .print_rdata (print_rdata),
    .print_ready (print_ready)
  );

  clint clint_comp
  (
    .reset (reset),
    .clock (clock),
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

  clic clic_comp
  (
    .reset (reset),
    .clock (clock),
    .clock_irpt (clock_irpt),
    .clic_valid (clic_valid),
    .clic_instr (clic_instr),
    .clic_addr (clic_addr),
    .clic_wdata (clic_wdata),
    .clic_wstrb (clic_wstrb),
    .clic_rdata (clic_rdata),
    .clic_ready (clic_ready),
    .clic_meip (meip),
    .clic_meid (meid),
    .clic_irpt (irpt)
  );

  bram bram_comp
  (
    .reset (reset),
    .clock (clock),
    .bram_valid (bram_valid),
    .bram_instr (bram_instr),
    .bram_addr (bram_addr),
    .bram_wdata (bram_wdata),
    .bram_wstrb (bram_wstrb),
    .bram_rdata (bram_rdata),
    .bram_ready (bram_ready)
  );

endmodule
