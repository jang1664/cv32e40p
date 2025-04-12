module cv32e40p_config_register (
   input logic clk_i,
   input logic rst_ni,

   // addr config register
   input logic [2:0][15:0] addr_bnd_i, // dim x width
   input logic [2:0][15:0] addr_strd_i, // dim x width
   input logic        addr_config_we_i,
   input logic [1:0]  addr_config_widx_i,

   output logic [2:0][2:0][15:0] addr_bnd_o,
   output logic [2:0][2:0][15:0] addr_strd_o,

   // coordinate range register
   input logic [2:0][15:0] cood_base_i, // dim x width
   input logic [2:0][15:0] cood_incr_i, // dim x width
   input logic        cood_reg_we_i,
   input logic [1:0]  cood_reg_widx_i,

   output logic [2:0][2:0][15:0] cood_base_o,
   output logic [2:0][2:0][15:0] cood_incr_o,

   // sync register
   input logic [4:0] sync_reg_idx_i,
   input logic sync_reserve_i,
   input logic sync_reg_wait_i,
   output logic sync_reg_wait_complete_o,

   input logic [31:0] sync_reg_set_i,

   input logic sync_taken_i,
   output logic [4:0] sync_reserved_reg_idx_o,
   output logic sync_reserved_o,

   output logic [31:0] sync_reg_o,

   // vector mask
   input logic [31:0] vector_mask_i,
   input logic vector_mask_we_i,
   output logic [31:0] vector_mask_o
  );

  // addr configuration
  logic [2:0][2:0][15:0] addr_config_strd; // op_idx x dim x width
  logic [2:0][2:0][15:0] addr_config_bnd; // op_idx x dim x width

  // coordinate range
  logic [2:0][2:0][15:0] cood_base; // op_idx x dim x width
  logic [2:0][2:0][15:0] cood_incr; // op_idx x dim x width

  // sync register
  logic [31:0] sync_reg;
  logic [4:0] sync_reserved_reg_idx;
  logic sync_reserved;
  logic [31:0] sync_complete;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
      addr_config_strd <= '0;
      addr_config_bnd <= '0;
    end else begin
      if(addr_config_we_i) begin
        addr_config_bnd[addr_config_widx_i] <= addr_bnd_i;
        addr_config_strd[addr_config_widx_i] <= addr_strd_i;
      end
    end
  end

  assign addr_bnd_o = addr_config_bnd;
  assign addr_strd_o = addr_config_strd;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
      cood_base <= '0;
      cood_incr <= '0;
    end else begin
      if(cood_reg_we_i) begin
        cood_base[cood_reg_widx_i] <= cood_base_i;
        cood_incr[cood_reg_widx_i] <= cood_incr_i;
      end
    end
  end

  assign cood_base_o = cood_base;
  assign cood_incr_o = cood_incr;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
      sync_reg <= '0;
    end else begin
      for(int i=0; i<32; i++) begin
        if(sync_reg_set_i[i]) begin
          sync_reg[i] <= 1'b1;
        end else if(sync_complete[i]) begin
          sync_reg[i] <= 1'b0;
        end
      end
    end
  end
  assign sync_reg_o = sync_reg;

  always_comb begin
    sync_complete = '0;
    for(int i=0; i<32; i++) begin
      if(sync_reg_wait_i && (sync_reg_idx_i == i) && sync_reg[i]) begin
        sync_complete[i] = 1'b1;
      end
    end
  end
  assign sync_reg_wait_complete_o = |sync_complete;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
      sync_reserved <= 1'b0;
      sync_reserved_reg_idx <= 5'b0;
    end else begin
      if(sync_reserve_i) begin
        sync_reserved <= 1'b1;
        sync_reserved_reg_idx <= sync_reg_idx_i;
      end else if (sync_taken_i) begin
        sync_reserved <= 1'b0;
        sync_reserved_reg_idx <= 5'b0;
      end
    end
  end
  assign sync_reserved_reg_idx_o = sync_reserved_reg_idx;
  assign sync_reserved_o = sync_reserved;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
      vector_mask_o <= '0;
    end else begin
      if(vector_mask_we_i) begin
        vector_mask_o <= vector_mask_i;
      end
    end
  end

endmodule