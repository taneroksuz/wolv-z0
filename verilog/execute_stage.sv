import constants::*;
import wires::*;

module execute_stage
(
  input logic rst,
  input logic clk,
  input postdecoder_out_type postdecoder_out,
  output postdecoder_in_type postdecoder_in,
  input alu_out_type alu_out,
  output alu_in_type alu_in,
  input lsu_out_type lsu_out,
  output lsu_in_type lsu_in,
  input csr_alu_out_type csr_alu_out,
  output csr_alu_in_type csr_alu_in,
  input div_out_type div_out,
  output div_in_type div_in,
  input mul_out_type mul_out,
  output mul_in_type mul_in,
  output register_write_in_type register_win,
  output forwarding_execute_in_type forwarding_ein,
  input csr_out_type csr_out,
  output csr_in_type csr_in,
  input csr_pmp_out_type csr_pmp_out,
  output csr_pmp_in_type csr_pmp_in,
  input mem_out_type dmem_out,
  output rvfi_out_type rvfi_out,
  input execute_in_type a,
  input execute_in_type d,
  output execute_out_type y,
  output execute_out_type q
);
  timeunit 1ns;
  timeprecision 1ps;

  execute_reg_type r,rin;
  execute_reg_type v;

  always_comb begin

    v = r;

    v.pc = d.f.pc;
    v.imm = d.f.imm;
    v.instr = d.f.instr;
    v.rdata1 = d.f.rdata1;
    v.rdata2 = d.f.rdata2;
    v.sdata = d.f.sdata;
    v.wren = d.f.wren;
    v.rden1 = d.f.rden1;
    v.rden2 = d.f.rden2;
    v.waddr = d.f.waddr;
    v.raddr1 = d.f.raddr1;
    v.raddr2 = d.f.raddr2;
    v.caddr = d.f.caddr;
    v.lui = d.f.lui;
    v.auipc = d.f.auipc;
    v.jal = d.f.jal;
    v.jalr = d.f.jalr;
    v.branch = d.f.branch;
    v.load = d.f.load;
    v.store = d.f.store;
    v.ebreak = d.f.ebreak;
    v.jump = d.f.jump;
    v.valid = d.f.valid;
    v.invalid = d.f.invalid;
    v.address = d.f.address;
    v.byteenable = d.f.byteenable;
    v.alu_op = d.f.alu_op;
    v.bcu_op = d.f.bcu_op;
    v.lsu_op = d.f.lsu_op;
    v.ierror = d.f.ierror;
    v.exception = d.f.exception;
    v.ecause = d.f.ecause;
    v.etval = d.f.etval;

    v.cwren = 0;
    v.crden = 0;
    v.nop = 0;
    v.csrreg = 0;
    v.division = 0;
    v.mult = 0;
    v.ecall = 0;
    v.mret = 0;
    v.wfi = 0;

    v.div_op = init_div_op;
    v.mul_op = init_mul_op;

    if (d.e.stall == 1) begin
      v = r;
    end

    v.clear = d.e.clear;

    v.stall = 0;
    v.derror = 0;

    v.mode = csr_out.mode;
    v.mcounteren = csr_out.mcounteren;

    postdecoder_in.instr = v.instr;
    postdecoder_in.mcounteren = v.mcounteren;
    postdecoder_in.mode = v.mode;

    if (v.valid == 0) begin
      v.imm = postdecoder_out.imm;
      v.wren = postdecoder_out.wren;
      v.rden1 = postdecoder_out.rden1;
      v.rden2 = postdecoder_out.rden2;
      v.cwren = postdecoder_out.cwren;
      v.crden = postdecoder_out.crden;
      v.lui = postdecoder_out.lui;
      v.nop = postdecoder_out.nop;
      v.csrreg = postdecoder_out.csrreg;
      v.division = postdecoder_out.division;
      v.mult = postdecoder_out.mult;
      v.alu_op = postdecoder_out.alu_op;
      v.csr_op = postdecoder_out.csr_op;
      v.div_op = postdecoder_out.div_op;
      v.mul_op = postdecoder_out.mul_op;
      v.ecall = postdecoder_out.ecall;
      v.ebreak = postdecoder_out.ebreak;
      v.mret = postdecoder_out.mret;
      v.wfi = postdecoder_out.wfi;
      v.valid = postdecoder_out.valid;
      v.invalid = 0;
    end

    if (v.waddr == 0) begin
      v.wren = 0;
    end

    if (v.rden1 == 0) begin
      v.rdata1 = 0;
    end
    if (v.rden2 == 0) begin
      v.rdata2 = 0;
    end

    v.npc = v.pc + ((v.instr[1:0] == 2'b11) ? 4 : 2);

    if (v.valid == 0) begin
      v.exception = 1;
      v.ecause = except_illegal_instruction;
      v.etval = v.instr;
    end else if (v.ebreak == 1) begin
      v.exception = 1;
      v.ecause = except_breakpoint;
      v.etval = v.instr;
    end else if (v.ecall == 1) begin
      v.exception = 1;
      v.ecause = except_env_call_mach;
      v.etval = v.instr;
    end

    csr_in.crden = v.crden;
    csr_in.craddr = v.caddr;

    csr_pmp_in.crden = v.crden;
    csr_pmp_in.craddr = v.caddr;

    v.cdata = csr_pmp_out.cready == 1 ? csr_pmp_out.crdata : csr_out.crdata;

    alu_in.rdata1 = v.rdata1;
    alu_in.rdata2 = v.rdata2;
    alu_in.imm = v.imm;
    alu_in.sel = v.rden2;
    alu_in.alu_op = v.alu_op;

    v.wdata = alu_out.res;

    if (v.auipc == 1) begin
      v.wdata = v.address;
    end else if (v.lui == 1) begin
      v.wdata = v.imm;
    end else if (v.jal == 1) begin
      v.wdata = v.npc;
    end else if (v.jalr == 1) begin
      v.wdata = v.npc;
    end else if (v.crden == 1) begin
      v.wdata = v.cdata;
    end

    csr_alu_in.cdata = v.cdata;
    csr_alu_in.rdata1 = v.rdata1;
    csr_alu_in.imm = v.imm;
    csr_alu_in.sel = v.rden1;
    csr_alu_in.csr_op = v.csr_op;

    v.cdata = csr_alu_out.cdata;

    div_in.rdata1 = v.rdata1;
    div_in.rdata2 = v.rdata2;
    div_in.enable = v.division & ~(d.e.clear | d.e.stall);
    div_in.op = v.div_op;

    mul_in.rdata1 = v.rdata1;
    mul_in.rdata2 = v.rdata2;
    mul_in.enable = v.mult & ~(d.e.clear | d.e.stall);
    mul_in.op = v.mul_op;

    lsu_in.ldata = dmem_out.mem_rdata;
    lsu_in.byteenable = v.byteenable;
    lsu_in.lsu_op = v.lsu_op;

    v.ldata = lsu_out.res;

    if (v.division == 1) begin
      if (div_out.ready == 0) begin
        v.stall = 1;
      end else if (div_out.ready == 1) begin
        v.wren = |v.waddr;
        v.wdata = div_out.result;
      end
    end else if (v.mult == 1) begin
      if (mul_out.ready == 0) begin
        v.stall = 1;
      end else if (mul_out.ready == 1) begin
        v.wren = |v.waddr;
        v.wdata = mul_out.result;
      end
    end

    if (v.load == 1 | v.store == 1) begin
      if (dmem_out.mem_ready == 0) begin
        v.stall = 1;
      end else if (dmem_out.mem_error == 1) begin
        v.derror = 1;
      end else if (dmem_out.mem_ready == 1) begin
        v.wren = v.load & |v.waddr;
        v.wdata = v.ldata;
      end
    end

    if ((v.stall | v.clear | csr_out.trap | csr_out.mret) == 1) begin
      v.wren = 0;
      v.cwren = 0;
      v.auipc = 0;
      v.lui = 0;
      v.nop = 0;
      v.jal = 0;
      v.jalr = 0;
      v.branch = 0;
      v.csrreg = 0;
      v.ecall = 0;
      v.ebreak = 0;
      v.mret = 0;
      v.wfi = 0;
      v.invalid = 1;
      v.exception = 0;
      v.clear = 0;
    end

    if (v.clear == 1) begin
      v.stall = 0;
    end

    if (v.nop == 1) begin
      v.invalid = 1;
    end

    v.retired = ~v.invalid;

    register_win.wren = v.wren;
    register_win.waddr = v.waddr;
    register_win.wdata = v.wdata;

    forwarding_ein.wren = v.wren;
    forwarding_ein.waddr = v.waddr;
    forwarding_ein.wdata = v.wdata;

    csr_in.valid = v.retired;
    csr_in.cwren = v.cwren;
    csr_in.cwaddr = v.caddr;
    csr_in.cwdata = v.cdata;

    csr_pmp_in.cwren = v.cwren;
    csr_pmp_in.cwaddr = v.caddr;
    csr_pmp_in.cwdata = v.cdata;
    csr_pmp_in.mode = v.mode;

    csr_in.mret = v.mret;
    csr_in.exception = v.exception;
    csr_in.epc = v.pc;
    csr_in.ecause = v.ecause;
    csr_in.etval = v.etval;

    rvfi_out.rvfi_valid = v.retired;
    rvfi_out.rvfi_order = csr_out.minstret;
    rvfi_out.rvfi_insn = v.instr;
    rvfi_out.rvfi_trap = v.exception;
    rvfi_out.rvfi_halt = v.exception;
    rvfi_out.rvfi_intr = csr_out.trap;
    rvfi_out.rvfi_mode = v.mode;
    rvfi_out.rvfi_ixl = 1;

    rvfi_out.rvfi_rs1_addr = (v.rden1 == 1) ? v.raddr1 : 0;
    rvfi_out.rvfi_rs2_addr = (v.rden2 == 1) ? v.raddr2 : 0;
    rvfi_out.rvfi_rs1_rdata = (v.rden1 == 1) ? v.rdata1 : 0;
    rvfi_out.rvfi_rs2_rdata = (v.rden2 == 1) ? v.rdata2 : 0;
    rvfi_out.rvfi_rd_addr = (v.wren == 1) ? v.waddr : 0;
    rvfi_out.rvfi_rd_wdata = (v.wren == 1) ? v.wdata : 0;

    rvfi_out.rvfi_pc_rdata = v.pc;
    rvfi_out.rvfi_pc_wdata = (csr_out.trap == 1) ? csr_out.mtvec : v.npc;

    rvfi_out.rvfi_mem_addr = v.address;
    rvfi_out.rvfi_mem_rmask = (v.load == 1) ? v.byteenable : 0;
    rvfi_out.rvfi_mem_wmask = (v.store == 1) ? v.byteenable : 0;
    rvfi_out.rvfi_mem_rdata = (v.load == 1) ? v.ldata : 0;
    rvfi_out.rvfi_mem_wdata = (v.store == 1) ? v.sdata : 0;

    rin = v;

    y.stall = v.stall;
    y.clear = v.clear;

    q.stall = r.stall;
    q.clear = r.clear;

  end

  always_ff @(posedge clk) begin
    if (rst == 0) begin
      r <= init_execute_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
