module icg_cell (
    input  wire  clk,
    input  wire  en,
    output wire  clk_gated
);
`ifdef SKY130_SYNTH
    // Real sky130 technology ICG primitive (used only at synthesis time)
    sky130_fd_sc_hd__dlclkp_1 u_icg_prim (
        .CLK  (clk),
        .GATE (en),
        .GCLK (clk_gated)
    );
`else
    // Behavioral model — used for Icarus Verilog functional simulation
    reg en_latch;
    always @(clk or en)
        if (!clk) en_latch <= en;
    assign clk_gated = clk & en_latch;
`endif
endmodule

module reg_file_cg #(parameter W=32, parameter D=8) (
    input  wire         clk, rst, wr_en,
    input  wire  [2:0]  wr_addr, rd_addr,
    input  wire  [W-1:0] wr_data,
    output reg   [W-1:0] rd_data
);
    reg [W-1:0] mem [0:D-1];
    integer j;
    wire clk_gated;
    icg_cell u_icg (.clk(clk), .en(wr_en), .clk_gated(clk_gated));
    always @(posedge clk_gated or posedge rst) begin
        if (rst) begin
            for (j = 0; j < D; j = j + 1)
                mem[j] <= {W{1'b0}};
        end else begin
            mem[wr_addr] <= wr_data;
        end
    end
    always @(*) rd_data = mem[rd_addr];
endmodule

module dyn_cg_ctrl #(parameter W=4, parameter THRESH=2) (
    input  wire  clk, rst, data_valid,
    output reg   en_out
);
    reg [W-1:0] cnt;
    localparam MAX = {W{1'b1}};
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt    <= 0;
            en_out <= 1'b0;
        end else begin
            if (data_valid && cnt < MAX)
                cnt <= cnt + 1;
            else if (!data_valid && cnt > 0)
                cnt <= cnt - 1;
            en_out <= (cnt >= THRESH);
        end
    end
endmodule