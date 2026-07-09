// ═══════════════════════════════════════════════════════════════════
// TESTBENCH — Clock Gating Datapath
// Instantiates ONE of the 4 top-level variants (set via `define below)
// Generates 4 workload vectors: V1 (ALU), V2 (memory), V3 (mult), V4 (mixed)
// Dumps VCD for functional check + later switching-activity extraction
//
// USAGE (from command line, no editing needed):
//   iverilog -o sim.vvp -DVARIANT_NO_GATING -DVECTOR_V1 tb_datapath.v <rtl files>
//   vvp sim.vvp
//
// Valid -D flags:
//   Variant : VARIANT_NO_GATING | VARIANT_STATIC_CG | VARIANT_DYNAMIC_CG | VARIANT_HYBRID_CG
//   Vector  : VECTOR_V1 | VECTOR_V2 | VECTOR_V3 | VECTOR_V4
// ═══════════════════════════════════════════════════════════════════

`timescale 1ns/1ps

module tb_datapath;

    reg clk, rst;
    integer i;
    integer cycle_count;

    // Common stimulus regs — used differently per variant's port list
    reg  [31:0] alu_a, alu_b;
    reg  [2:0]  alu_op;
    reg         alu_ctrl;          // static: alu_en | dynamic: alu_valid

    reg  [31:0] mult_a, mult_b;
    reg         mult_ctrl;

    reg         shift_in_a, shift_in_b, shift_dir;
    reg         shift_ctrl;

    reg  [27:0] instr_in;
    reg         fsm_ctrl;

    reg  [2:0]  rf_wr_addr, rf_rd_addr;
    reg  [31:0] rf_wr_data;
    reg         rf_ctrl;

    reg  [31:0] bus_in;
    reg         bus_ctrl;

    // ── DUT instantiation (variant selected at compile time) ──────
`ifdef VARIANT_NO_GATING
    datapath_no_gating dut (
        .clk(clk), .rst(rst),
        .alu_a(alu_a), .alu_b(alu_b), .alu_op(alu_op),
        .mult_a(mult_a), .mult_b(mult_b),
        .shift_in_a(shift_in_a), .shift_in_b(shift_in_b), .shift_dir(shift_dir),
        .instr_in(instr_in),
        .rf_wr_addr(rf_wr_addr), .rf_rd_addr(rf_rd_addr), .rf_wr_data(rf_wr_data), .rf_wr_en(rf_ctrl),
        .bus_in(bus_in)
    );
`endif

`ifdef VARIANT_STATIC_CG
    datapath_static_cg dut (
        .clk(clk), .rst(rst),
        .alu_a(alu_a), .alu_b(alu_b), .alu_op(alu_op), .alu_en(alu_ctrl),
        .mult_a(mult_a), .mult_b(mult_b), .mult_en(mult_ctrl),
        .shift_in_a(shift_in_a), .shift_in_b(shift_in_b), .shift_dir(shift_dir), .shift_en(shift_ctrl),
        .instr_in(instr_in), .fsm_en(fsm_ctrl),
        .rf_wr_addr(rf_wr_addr), .rf_rd_addr(rf_rd_addr), .rf_wr_data(rf_wr_data), .rf_wr_en(rf_ctrl),
        .bus_in(bus_in), .bus_en(bus_ctrl)
    );
`endif

`ifdef VARIANT_DYNAMIC_CG
    datapath_dynamic_cg dut (
        .clk(clk), .rst(rst),
        .alu_a(alu_a), .alu_b(alu_b), .alu_op(alu_op), .alu_valid(alu_ctrl),
        .mult_a(mult_a), .mult_b(mult_b), .mult_valid(mult_ctrl),
        .shift_in_a(shift_in_a), .shift_in_b(shift_in_b), .shift_dir(shift_dir), .shift_valid(shift_ctrl),
        .instr_in(instr_in), .fsm_valid(fsm_ctrl),
        .rf_wr_addr(rf_wr_addr), .rf_rd_addr(rf_rd_addr), .rf_wr_data(rf_wr_data), .rf_valid(rf_ctrl),
        .bus_in(bus_in), .bus_valid(bus_ctrl)
    );
`endif

`ifdef VARIANT_HYBRID_CG
    datapath_hybrid_cg dut (
        .clk(clk), .rst(rst),
        .alu_a(alu_a), .alu_b(alu_b), .alu_op(alu_op), .alu_en(alu_ctrl),
        .mult_a(mult_a), .mult_b(mult_b), .mult_en(mult_ctrl),
        .shift_in_a(shift_in_a), .shift_in_b(shift_in_b), .shift_dir(shift_dir), .shift_valid(shift_ctrl),
        .instr_in(instr_in), .fsm_valid(fsm_ctrl),
        .rf_wr_addr(rf_wr_addr), .rf_rd_addr(rf_rd_addr), .rf_wr_data(rf_wr_data), .rf_valid(rf_ctrl),
        .bus_in(bus_in), .bus_valid(bus_ctrl)
    );
`endif

    // ── Clock: 100 MHz (10ns period) ───────────────────────────────
    always #5 clk = ~clk;

    // ── VCD dump ────────────────────────────────────────────────────
    initial begin
        $dumpfile(`VCD_NAME);
        $dumpvars(0, tb_datapath);
    end

    // ── Reset + stimulus ─────────────────────────────────────────────
    initial begin
        clk = 0; rst = 1;
        alu_a = 0; alu_b = 0; alu_op = 0; alu_ctrl = 0;
        mult_a = 0; mult_b = 0; mult_ctrl = 0;
        shift_in_a = 0; shift_in_b = 0; shift_dir = 0; shift_ctrl = 0;
        instr_in = 0; fsm_ctrl = 0;
        rf_wr_addr = 0; rf_rd_addr = 0; rf_wr_data = 0; rf_ctrl = 0;
        bus_in = 0; bus_ctrl = 0;
        cycle_count = `NUM_CYCLES;

        repeat (4) @(posedge clk);
        rst = 0;

        // ── Workload vectors ────────────────────────────────────────
`ifdef VECTOR_V1
        // V1 — ALU-intensive: ALU active every cycle, everything else idle
        for (i = 0; i < cycle_count; i = i + 1) begin
            @(posedge clk);
            alu_a    <= $random;
            alu_b    <= $random;
            alu_op   <= $random % 5;
            alu_ctrl <= 1'b1;
            mult_ctrl  <= 1'b0;
            shift_ctrl <= 1'b0;
            fsm_ctrl   <= 1'b0;
            rf_ctrl    <= 1'b0;
            bus_ctrl   <= 1'b0;
        end
`endif

`ifdef VECTOR_V2
        // V2 — Memory/register-file-heavy: RF + bus active, rest idle
        for (i = 0; i < cycle_count; i = i + 1) begin
            @(posedge clk);
            rf_wr_addr <= $random % 8;
            rf_rd_addr <= $random % 8;
            rf_wr_data <= $random;
            rf_ctrl    <= 1'b1;
            bus_in     <= $random;
            bus_ctrl   <= 1'b1;
            alu_ctrl   <= 1'b0;
            mult_ctrl  <= 1'b0;
            shift_ctrl <= 1'b0;
            fsm_ctrl   <= 1'b0;
        end
`endif

`ifdef VECTOR_V3
        // V3 — Multiplier-intensive: mult active every cycle, rest idle
        for (i = 0; i < cycle_count; i = i + 1) begin
            @(posedge clk);
            mult_a    <= $random;
            mult_b    <= $random;
            mult_ctrl <= 1'b1;
            alu_ctrl   <= 1'b0;
            shift_ctrl <= 1'b0;
            fsm_ctrl   <= 1'b0;
            rf_ctrl    <= 1'b0;
            bus_ctrl   <= 1'b0;
        end
`endif

`ifdef VECTOR_V4
        // V4 — Mixed workload: ~50% activity across all modules, randomized
        for (i = 0; i < cycle_count; i = i + 1) begin
            @(posedge clk);
            alu_a      <= $random;
            alu_b      <= $random;
            alu_op     <= $random % 5;
            alu_ctrl   <= $random % 2;
            mult_a     <= $random;
            mult_b     <= $random;
            mult_ctrl  <= $random % 2;
            shift_in_a <= $random % 2;
            shift_in_b <= $random % 2;
            shift_dir  <= $random % 2;
            shift_ctrl <= $random % 2;
            instr_in   <= $random;
            fsm_ctrl   <= $random % 2;
            rf_wr_addr <= $random % 8;
            rf_rd_addr <= $random % 8;
            rf_wr_data <= $random;
            rf_ctrl    <= $random % 2;
            bus_in     <= $random;
            bus_ctrl   <= $random % 2;
        end
`endif

        repeat (10) @(posedge clk);
        $display("SIM_DONE: variant + vector completed, %0d cycles", cycle_count);
        $finish;
    end

endmodule