// ═══════════════════════════════════════════════════════════════════
// ALU Core — 64 FFs (32-bit result reg + 32-bit accumulator reg)
// ═══════════════════════════════════════════════════════════════════
module alu_core (
    input  wire        clk, rst, en,       // en drives the ICG
    input  wire [31:0] a, b,
    input  wire [2:0]  op,                 // 0:add 1:sub 2:and 3:or 4:xor
    output reg  [31:0] result,             // 32 FF
    output reg  [31:0] accum               // 32 FF (running accumulator)
);
    wire clk_gated;
    icg_cell u_icg (.clk(clk), .en(en), .clk_gated(clk_gated));

    reg [31:0] alu_out;
    always @(*) begin
        case (op)
            3'd0: alu_out = a + b;
            3'd1: alu_out = a - b;
            3'd2: alu_out = a & b;
            3'd3: alu_out = a | b;
            3'd4: alu_out = a ^ b;
            default: alu_out = 32'd0;
        endcase
    end

    always @(posedge clk_gated or posedge rst) begin
        if (rst) begin
            result <= 32'd0;
            accum  <= 32'd0;
        end else begin
            result <= alu_out;
            accum  <= accum + alu_out;
        end
    end
endmodule


// ═══════════════════════════════════════════════════════════════════
// Multiplier Unit — 128 FFs (2×32-bit operand regs + 64-bit product reg)
// ═══════════════════════════════════════════════════════════════════
module mult_unit (
    input  wire        clk, rst, en,
    input  wire [31:0] a, b,
    output reg  [31:0] a_reg, b_reg,       // 64 FF (operand capture)
    output reg  [63:0] product             // 64 FF
);
    wire clk_gated;
    icg_cell u_icg (.clk(clk), .en(en), .clk_gated(clk_gated));

    always @(posedge clk_gated or posedge rst) begin
        if (rst) begin
            a_reg   <= 32'd0;
            b_reg   <= 32'd0;
            product <= 64'd0;
        end else begin
            a_reg   <= a;
            b_reg   <= b;
            product <= a * b;
        end
    end
endmodule


// ═══════════════════════════════════════════════════════════════════
// Shift Register Bank — 64 FFs (2× 32-bit shift registers)
// ═══════════════════════════════════════════════════════════════════
module shift_reg_bank (
    input  wire        clk, rst, en,
    input  wire        shift_in_a, shift_in_b,
    input  wire        dir,                // 0: left, 1: right
    output reg  [31:0] shreg_a,             // 32 FF
    output reg  [31:0] shreg_b              // 32 FF
);
    wire clk_gated;
    icg_cell u_icg (.clk(clk), .en(en), .clk_gated(clk_gated));

    always @(posedge clk_gated or posedge rst) begin
        if (rst) begin
            shreg_a <= 32'd0;
            shreg_b <= 32'd0;
        end else if (dir) begin
            shreg_a <= {shift_in_a, shreg_a[31:1]};
            shreg_b <= {shift_in_b, shreg_b[31:1]};
        end else begin
            shreg_a <= {shreg_a[30:0], shift_in_a};
            shreg_b <= {shreg_b[30:0], shift_in_b};
        end
    end
endmodule


// ═══════════════════════════════════════════════════════════════════
// Control FSM — 32 FFs (4-bit state reg + 28-bit instruction/opcode capture)
// ═══════════════════════════════════════════════════════════════════
module control_fsm (
    input  wire        clk, rst, en,
    input  wire [27:0] instr_in,
    output reg  [3:0]  state,               // 4 FF
    output reg  [27:0] instr_reg            // 28 FF
);
    wire clk_gated;
    icg_cell u_icg (.clk(clk), .en(en), .clk_gated(clk_gated));

    localparam IDLE = 4'd0, FETCH = 4'd1, DECODE = 4'd2, EXEC = 4'd3;

    always @(posedge clk_gated or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            instr_reg <= 28'd0;
        end else begin
            instr_reg <= instr_in;
            case (state)
                IDLE:   state <= FETCH;
                FETCH:  state <= DECODE;
                DECODE: state <= EXEC;
                EXEC:   state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end
endmodule


// ═══════════════════════════════════════════════════════════════════
// Data Path Bus — 96 FFs (3× 32-bit pipeline/bus registers)
// ═══════════════════════════════════════════════════════════════════
module datapath_bus (
    input  wire        clk, rst, en,
    input  wire [31:0] bus_in,
    output reg  [31:0] stage1,              // 32 FF
    output reg  [31:0] stage2,              // 32 FF
    output reg  [31:0] stage3               // 32 FF
);
    wire clk_gated;
    icg_cell u_icg (.clk(clk), .en(en), .clk_gated(clk_gated));

    always @(posedge clk_gated or posedge rst) begin
        if (rst) begin
            stage1 <= 32'd0;
            stage2 <= 32'd0;
            stage3 <= 32'd0;
        end else begin
            stage1 <= bus_in;
            stage2 <= stage1;
            stage3 <= stage2;
        end
    end
endmodule