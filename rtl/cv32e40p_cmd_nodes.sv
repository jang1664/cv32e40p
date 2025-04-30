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

  // dram interface
  TCDM_BUS.master dma_dram_master,
  TCDM_BUS.master dma_smem_master
);

  clk_if clkif_inst();
  Cmd cmd;

  logic dma_dram_req;
  logic dma_dram_gnt_cmd_push;

  // ======================================================
  // SUBMODULES
  // ======================================================
  Nodes nodes = new();
  DramDMANode dram_dma_node = new();
  MxuDMANode mxu_dma_node = new();
  // DmaNodes dma_nodes = new();

  always_comb begin
    clkif_inst.clk = clk_i;
  end

  initial begin
    nodes.clk_vif = clkif_inst;
    dram_dma_node.clk_vif = clkif_inst;
    dram_dma_node.tcdm_dram_vif = dma_dram_master;
    dram_dma_node.tcdm_sram_vif = dma_smem_master;
    mxu_dma_node.clk_vif = clkif_inst;

    for(int i=0; i<GEM_NUM; i++) begin
      mxu_dma_node.gemm_nodes.push_back(nodes.node[getStartIdx(NODE_GEMM)+i]);
    end

    // start models
    fork
      nodes.run();
      dram_dma_node.run();
      mxu_dma_node.run();
    join_none
  end

  dram_dma_node u_dram_dma_node (
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .req_cmd_push_i(dma_dram_req),
    .gnt_cmd_push_o(dma_dram_gnt_cmd_push),

    // .ctrl_i(dram_dma_ctrl_t'{
    //   .opcode(cmd_opcode_i),
    //   .dram_base_addr(dma_dram_base_addr_ex_i),
    //   .dram_addr_strd(dma_dram_addr_strd_ex_i),
    //   .dram_addr_bnd(dma_dram_addr_bnd_ex_i),
    //   .sram_base_addr(dma_sram_base_addr_ex_i),
    //   .sram_addr_strd(dma_sram_addr_strd_ex_i),
    //   .sram_addr_bnd(dma_sram_addr_bnd_ex_i),
    //   .sync_reserved(sync_reserved_ex_i),
    //   .sync_reserved_idx(sync_reserved_idx_ex_i),
    //   .segment_size(segment_size_ex_i),
    //   .pad_size(pad_size_ex_i)
    // }),

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

    .smem_master(dma_smem_master),
    .dram_master(dma_dram_master)
  );

  always_comb begin
    dma_dram_req = 1'b0;
    if(req_i) begin
      case(node_type_i)
        NODE_DMA: begin
          dma_dram_req = 1'b1;
        end

        NODE_WEIGHT_LOADER:begin
        end

        NODE_MUL,
        NODE_ADD,
        NODE_GEMM,
        NODE_EXP_F32,
        NODE_FL_CONVERT,
        NODE_REDUCE_SUM_F32,
        NODE_RELU_F32,
        NODE_BIN_F32: begin
        end

        default: begin
          $error("cv32e40p_cmd_nodes: Unknown command type %0s", node_type_i.name());
        end
      endcase
    end
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
    end else begin
      if(req_i & gnt_o) begin
        case(node_type_i)
          NODE_DMA: begin
          end

          NODE_WEIGHT_LOADER:begin
            cmd = new (
              .opcode(cmd_opcode_i),
              .node_type(node_type_i),
              .base_addr_rs1(mxu_wl_sram_base_addr_ex_i),
              .strides_rs1('{mxu_wl_sram_addr_strd_ex_i, 0, 0}),
              .bnds_rs1('{mxu_wl_sram_addr_bnd_ex_i, 0, 0}),
              .reserve_sync(sync_reserved_ex_i), .sync_reg_idx(sync_reserved_idx_ex_i),
              .segment_size(segment_size_ex_i), .widx(mxu_widx_ex_i)
            );
            mxu_dma_node.push_back(cmd);
          end

          NODE_MUL,
          NODE_ADD,
          NODE_GEMM,
          NODE_EXP_F32,
          NODE_FL_CONVERT,
          NODE_REDUCE_SUM_F32,
          NODE_RELU_F32,
          NODE_BIN_F32: begin
            cmd = new (
              .opcode(cmd_opcode_i),
              .node_type(node_type_i),
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
              .vector_mask(vector_mask_reg_ex_i), .addr_update_en(cmd_addr_update_en_ex_i),
              .widx(mxu_widx_ex_i)
            );
            nodes.push_back(cmd);
          end

          default: begin
            $error("cv32e40p_cmd_nodes: Unknown command type %0s", node_type_i.name());
          end
        endcase
      end
    end
  end

  always_comb begin
    gnt_o = 1'b0;
    case(node_type_i)
      NODE_DMA:begin
        gnt_o = dma_dram_gnt_cmd_push;
      end

      NODE_WEIGHT_LOADER:begin
        gnt_o = (mxu_dma_node.getQueueSize() < 8);
      end

      NODE_MUL,
      NODE_ADD,
      NODE_GEMM,
      NODE_EXP_F32,
      NODE_FL_CONVERT,
      NODE_REDUCE_SUM_F32,
      NODE_RELU_F32,
      NODE_BIN_F32: begin
        gnt_o = (nodes.getQueueSize() < 8);
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
      sync_set_req_o <= nodes.sync_set_req | u_dram_dma_node.dram_dma_node.sync_set_req | mxu_dma_node.sync_set_req;
    end
  end

endmodule