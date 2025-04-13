`include "typedef.svh"
module cv32e40p_cmd_nodes 
  import cv32e40p_pkg::*;
  import params::*;
#(
  parameter DUMMY = 0
) (
  input logic clk_i,
  input logic rst_ni,

  // protocol
  input logic req_i,
  output logic gnt_o,

  // data
  input cmd_opcode_e cmd_opcode_i,
  input logic [2:0] cmd_addr_update_en_ex_i,
  input logic [31:0] cmd_base_addr_a_ex_i,
  input logic [31:0] cmd_base_addr_b_ex_i,
  input logic [31:0] cmd_base_addr_c_ex_i,
  input logic [2:0][2:0][15:0] addr_bnd_ex_i,
  input logic [2:0][2:0][15:0] addr_strd_ex_i, 
  input logic [2:0][2:0][15:0] cood_base_ex_i,
  input logic [2:0][2:0][15:0] cood_incr_ex_i, 
  input logic [31:0] vector_mask_reg_ex_i,

  // sync
  input logic sync_reserved_ex_i,
  input logic [4:0] sync_reserved_idx_ex_i,
  output logic [31:0] sync_set_req_o
);

  logic clk_;

  CommandQueue command_queue = new();
  Rstation rstation = new();
  FuseTable fuse_table = new(rstation);
  Dispatcher cmd_dp_dispatcher = new(command_queue, rstation, fuse_table);
  SharedMem smem = new();
  Nodes nodes = new(smem, rstation, fuse_table);
  IssueManager issue_manager = new(rstation, fuse_table, nodes);

  clk_if clkif_inst();
  always_comb begin
    clkif_inst.clk = clk_i;
  end
  // assign clk_ = clk_i;

  initial begin
    cmd_dp_dispatcher.clk_vif = clkif_inst;
    rstation.clk_vif = clkif_inst;
    nodes.clk_vif = clkif_inst;
    issue_manager.clk_vif = clkif_inst;
    fork
      // cmd_dp_dispatcher.run(clk_);
      // rstation.run(clk_);
      // issue_manager.run(clk_);
      // nodes.run(clk_);
      cmd_dp_dispatcher.run();
      rstation.run();
      issue_manager.run();
      nodes.run();
    join_none
  end

  function cmd_t getCmdType(cmd_opcode_e cmd_opcode_i);
    case(cmd_opcode_i)
      CMD_OPCODE_NOP          : return CMD_NOP;
      CMD_OPCODE_MUL_VV_F32   : return CMD_MUL;
      CMD_OPCODE_MUL_VS_F32   : return CMD_MUL_VS_F32;
      CMD_OPCODE_RELU_V_F32   : return CMD_RELU_V_F32;
      CMD_OPCODE_SETUP_LOAD_W : return CMD_SETUP_LOAD_W;
      CMD_OPCODE_LOAD_W_MM    : return CMD_LOAD_W_MM;
      CMD_OPCODE_LOAD_Z_MM    : return CMD_LOAD_Z_MM;
      CMD_OPCODE_GEMM         : return CMD_GEMM;
      CMD_DMA_SETUP_DRAM      : return CMD_DMA_SETUP_DRAM;
      CMD_DMA_SETUP_SRAM      : return CMD_DMA_SETUP_SRAM;
      CMD_DMA_LOAD            : return CMD_DMA_LOAD;
      CMD_DMA_STORE           : return CMD_DMA_STORE;
    endcase
  endfunction

  Cmd cmd;
  // cmd_opcode_e queue[$];

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
  
    end else begin
      if(req_i & gnt_o) begin
        cmd = new (
          .cmd(getCmdType(cmd_opcode_i)),
          .base_addr_rs1(cmd_base_addr_a_ex_i),
          .strides_rs1('{addr_strd_ex_i[0][0], addr_strd_ex_i[0][1], addr_strd_ex_i[0][2]}),
          .bnds_rs1('{addr_bnd_ex_i[0][0], addr_bnd_ex_i[0][1], addr_bnd_ex_i[0][2]}), .cache_hint_rs1('0),
          .base_addr_rs2(cmd_base_addr_b_ex_i),
          .strides_rs2('{addr_strd_ex_i[1][0], addr_strd_ex_i[1][1], addr_strd_ex_i[1][2]}),
          .bnds_rs2('{addr_bnd_ex_i[1][0], addr_bnd_ex_i[1][1], addr_bnd_ex_i[1][2]}), .cache_hint_rs2('0),
          .base_addr_rd(cmd_base_addr_c_ex_i),
          .strides_rd('{addr_strd_ex_i[2][0], addr_strd_ex_i[2][1], addr_strd_ex_i[2][2]}),
          .bnds_rd('{addr_bnd_ex_i[2][0], addr_bnd_ex_i[2][1], addr_bnd_ex_i[2][2]}), .cache_hint_rd('0), .need_flush('0),
          .base_coo_rs1('{cood_base_ex_i[0][0], cood_base_ex_i[0][1], cood_base_ex_i[0][2]}),
          .coo_incr_rs1('{cood_incr_ex_i[0][0], cood_incr_ex_i[0][1], cood_incr_ex_i[0][2]}),
          .base_coo_rs2('{cood_base_ex_i[1][0], cood_base_ex_i[1][1], cood_base_ex_i[1][2]}),
          .coo_incr_rs2('{cood_incr_ex_i[1][0], cood_incr_ex_i[1][1], cood_incr_ex_i[1][2]}),
          .base_coo_rd('{cood_base_ex_i[2][0], cood_base_ex_i[2][1], cood_base_ex_i[2][2]}),
          .coo_incr_rd('{cood_incr_ex_i[2][0], cood_incr_ex_i[2][1], cood_incr_ex_i[2][2]}),
          .reserve_sync(sync_reserved_ex_i), .sync_reg_idx(sync_reserved_idx_ex_i),
          .vector_mask(vector_mask_reg_ex_i), .addr_update_en(cmd_addr_update_en_ex_i)
        );
        command_queue.push_back(cmd);
      end
    end
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
      gnt_o <= 1'b0;
    end else begin
      if($urandom_range(0, 10)==0) begin
        gnt_o <= (command_queue.size() < 8);
      end else begin
        gnt_o <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
      sync_set_req_o <= '0;
    end else begin
      sync_set_req_o <= nodes.sync_set_req;
    end
  end

endmodule