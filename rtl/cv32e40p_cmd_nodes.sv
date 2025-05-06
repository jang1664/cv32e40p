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
  input node_type_e  node_type_i,
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
  output logic [31:0] sync_set_req_o,

  // dma, mxu weight loader
  input logic [15:0] segment_size_ex_i,
  input logic [15:0] pad_size_ex_i,
  input logic [31:0] dma_sram_base_addr_ex_i,
  input logic [2:0][15:0] dma_sram_addr_strd_ex_i,
  input logic [2:0][15:0] dma_sram_addr_bnd_ex_i,
  input logic [31:0] dma_dram_base_addr_ex_i,
  input logic [2:0][15:0] dma_dram_addr_strd_ex_i,
  input logic [2:0][15:0] dma_dram_addr_bnd_ex_i,

  input logic [15:0] mxu_wl_sram_base_addr_ex_i,
  input logic [15:0] mxu_wl_sram_addr_strd_ex_i,
  input logic [15:0] mxu_wl_sram_addr_bnd_ex_i,
  input logic mxu_widx_ex_i,

  // dram dma interface
  TCDM_BUS.master dma_dram_master,
  TCDM_BUS.master dma_smem_master,

  // mxu dma interface
  TCDM_BUS.master mxu_smem_master
);

  logic dma_dram_req;
  logic dma_dram_gnt_cmd_push;
  logic [31:0] dma_dram_sync_set_req;

  logic mxu_dma_req;
  logic mxu_dma_gnt_cmd_push;
  logic [31:0] mxu_dma_sync_set_req;

  logic cmd_req;
  logic cmd_gnt;
  logic [31:0] cmd_sync_set_req;

  TCDM_BUS #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) mxu_weight_master (.clk(clk_i));

  // ======================================================
  // SUBMODULES
  // ======================================================
  dram_dma_node u_dram_dma_node (
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .req_cmd_push_i(dma_dram_req),
    .gnt_cmd_push_o(dma_dram_gnt_cmd_push),

    .ctrl_i(dram_dma_ctrl_t'{
      cmd_opcode_i,
      dma_dram_base_addr_ex_i,
      dma_dram_addr_strd_ex_i,
      dma_dram_addr_bnd_ex_i,
      dma_sram_base_addr_ex_i,
      dma_sram_addr_strd_ex_i,
      dma_sram_addr_bnd_ex_i,
      sync_reserved_ex_i,
      sync_reserved_idx_ex_i,
      segment_size_ex_i,
      pad_size_ex_i
    }),
    .sync_set_req_o(dma_dram_sync_set_req),

    .smem_master(dma_smem_master),
    .dram_master(dma_dram_master)
  );

  mxu_dma_node u_mxu_dma_node (
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .tcdm_smem_master(mxu_smem_master),
    .tcdm_mxu_master(mxu_weight_master),

    .req_cmd_push_i(mxu_dma_req),
    .gnt_cmd_push_o(mxu_dma_gnt_cmd_push),
    .ctrl_i(mxu_dma_ctrl_t'{
        cmd_opcode_i,
        mxu_wl_sram_base_addr_ex_i,
        mxu_wl_sram_addr_strd_ex_i,
        mxu_wl_sram_addr_bnd_ex_i,
        sync_reserved_ex_i,
        sync_reserved_idx_ex_i,
        segment_size_ex_i,
        mxu_widx_ex_i
      }
    ),
    .sync_set_req_o(mxu_dma_sync_set_req)
  );

  nodes u_nodes (
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .req_i(cmd_req),
    .gnt_o(cmd_gnt),
    .ctrl_i(
      compute_cmd_ctrl_t'{
        cmd_opcode_i,
        node_type_i,
        cmd_base_addr_a_ex_i,
        '{addr_strd_ex_i[0][0], addr_strd_ex_i[0][1], addr_strd_ex_i[0][2]},
        '{addr_bnd_ex_i[0][0], addr_bnd_ex_i[0][1], addr_bnd_ex_i[0][2]},
        cmd_base_addr_b_ex_i,
        '{addr_strd_ex_i[1][0], addr_strd_ex_i[1][1], addr_strd_ex_i[1][2]},
        '{addr_bnd_ex_i[1][0], addr_bnd_ex_i[1][1], addr_bnd_ex_i[1][2]},
        cmd_base_addr_c_ex_i,
        '{addr_strd_ex_i[2][0], addr_strd_ex_i[2][1], addr_strd_ex_i[2][2]},
        '{addr_bnd_ex_i[2][0], addr_bnd_ex_i[2][1], addr_bnd_ex_i[2][2]},
        '{cood_base_ex_i[0][0], cood_base_ex_i[0][1], cood_base_ex_i[0][2]},
        '{cood_incr_ex_i[0][0], cood_incr_ex_i[0][1], cood_incr_ex_i[0][2]},
        '{cood_base_ex_i[1][0], cood_base_ex_i[1][1], cood_base_ex_i[1][2]},
        '{cood_incr_ex_i[1][0], cood_incr_ex_i[1][1], cood_incr_ex_i[1][2]},
        '{cood_base_ex_i[2][0], cood_base_ex_i[2][1], cood_base_ex_i[2][2]},
        '{cood_incr_ex_i[2][0], cood_incr_ex_i[2][1], cood_incr_ex_i[2][2]},
        sync_reserved_ex_i, sync_reserved_idx_ex_i,
        vector_mask_reg_ex_i, cmd_addr_update_en_ex_i, mxu_widx_ex_i
      }
    ),
    .sync_set_req_o(cmd_sync_set_req),
    .mxu_tcdm_slave(mxu_weight_master)
  );

  always_comb begin
    dma_dram_req = 1'b0;
    mxu_dma_req = 1'b0;
    cmd_req = 1'b0;
    if(req_i) begin
      case(node_type_i)
        NODE_DMA: begin
          dma_dram_req = 1'b1;
        end

        NODE_WEIGHT_LOADER:begin
          mxu_dma_req = 1'b1;
        end

        NODE_MUL,
        NODE_ADD,
        NODE_GEMM,
        NODE_EXP_F32,
        NODE_FL_CONVERT,
        NODE_REDUCE_SUM_F32,
        NODE_RELU_F32,
        NODE_BIN_F32: begin
          cmd_req = 1'b1;
        end

        NODE_NOP: begin
          
        end

        default: begin
          $error("cv32e40p_cmd_nodes: Unknown command type %0s", node_type_i.name());
        end
      endcase
    end
  end

  always_comb begin
    gnt_o = 1'b0;
    case(node_type_i)
      NODE_DMA:begin
        gnt_o = dma_dram_gnt_cmd_push;
      end

      NODE_WEIGHT_LOADER:begin
        gnt_o = mxu_dma_gnt_cmd_push;
      end

      NODE_MUL,
      NODE_ADD,
      NODE_GEMM,
      NODE_EXP_F32,
      NODE_FL_CONVERT,
      NODE_REDUCE_SUM_F32,
      NODE_RELU_F32,
      NODE_BIN_F32: begin
        gnt_o = cmd_gnt;
      end

      NODE_NOP: begin
        gnt_o = 1'b0;
      end

      default: begin
        $error("cv32e40p_cmd_nodes: Unknown command type. %s", node_type_i.name());
      end
    endcase
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
      sync_set_req_o <= '0;
    end else begin
      sync_set_req_o <= dma_dram_sync_set_req | mxu_dma_sync_set_req | cmd_sync_set_req;
    end
  end

endmodule