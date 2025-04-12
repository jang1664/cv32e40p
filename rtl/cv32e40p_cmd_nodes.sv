module cv32e40p_cmd_nodes 
  import cv32e40p_pkg::*;
#(
  parameter DUMMY = 0
) (
  input logic clk_i,
  input logic rst_ni,

  // protocol
  input logic req_i,
  output logic gnt_o,

  // data
  input cmd_opcode_e cmd_opcode_i
);

  cmd_opcode_e queue[$];

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
  
    end else begin
      if(req_i & !gnt_o) begin
        queue.push_back(cmd_opcode_i);
      end
    end
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
      gnt_o <= 1'b0;
    end else begin
      if($urandom_range(0, 10)==0) begin
        gnt_o <= 1'b1;
      end else begin
        gnt_o <= 1'b0;
      end
    end
  end

endmodule