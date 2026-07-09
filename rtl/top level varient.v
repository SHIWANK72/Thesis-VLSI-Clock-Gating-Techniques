// ═══════════════════════════════════════════════════════════════════
// VARIANT 1 — NO GATING (baseline)
// All modules run on the raw, ungated clock (en tied high everywhere)
// ═══════════════════════════════════════════════════════════════════
module datapath_no_gating (
    input  wire        clk, rst,
    input  wire [31:0] alu_a, alu_b,
    input  wire [2:0]  alu_op,
    input  wire [31:0] mult_a, mult_b,
    input  wire        shift_in_a, shift_in_b, shift_dir,
    input  wire [27:0] instr_in,
    input  wire [2:0]  rf_wr_addr, rf_rd_addr,
    input  wire [31:0] rf_wr_data,
    input  wire        rf_wr_en,
    input  wire [31:0] bus_in,
    // ── primary outputs (keep synthesis from optimizing logic away) ──
    output wire [31:0] alu_result_o, alu_accum_o,
    output wire [63:0] mult_product_o,
    output wire [31:0] shreg_a_o, shreg_b_o,
    output wire [3:0]  fsm_state_o,
    output wire [31:0] rf_rd_data_o,
    output wire [31:0] bus_stage3_o
);
    wire [31:0] alu_result, alu_accum;
    wire [31:0] mult_a_reg, mult_b_reg;
    wire [63:0] mult_product;
    wire [31:0] shreg_a, shreg_b;
    wire [3:0]  fsm_state;
    wire [27:0] fsm_instr_reg;
    wire [31:0] rf_rd_data;
    wire [31:0] bus_stage1, bus_stage2, bus_stage3;

    alu_core       u_alu   (.clk(clk), .rst(rst), .en(1'b1), .a(alu_a), .b(alu_b), .op(alu_op), .result(alu_result), .accum(alu_accum));
    mult_unit      u_mult  (.clk(clk), .rst(rst), .en(1'b1), .a(mult_a), .b(mult_b), .a_reg(mult_a_reg), .b_reg(mult_b_reg), .product(mult_product));
    shift_reg_bank u_shift (.clk(clk), .rst(rst), .en(1'b1), .shift_in_a(shift_in_a), .shift_in_b(shift_in_b), .dir(shift_dir), .shreg_a(shreg_a), .shreg_b(shreg_b));
    control_fsm    u_fsm   (.clk(clk), .rst(rst), .en(1'b1), .instr_in(instr_in), .state(fsm_state), .instr_reg(fsm_instr_reg));
    reg_file_cg    u_rf    (.clk(clk), .rst(rst), .wr_en(1'b1), .wr_addr(rf_wr_addr), .rd_addr(rf_rd_addr), .wr_data(rf_wr_data), .rd_data(rf_rd_data));
    datapath_bus   u_bus   (.clk(clk), .rst(rst), .en(1'b1), .bus_in(bus_in), .stage1(bus_stage1), .stage2(bus_stage2), .stage3(bus_stage3));

    assign alu_result_o   = alu_result;
    assign alu_accum_o    = alu_accum;
    assign mult_product_o = mult_product;
    assign shreg_a_o      = shreg_a;
    assign shreg_b_o      = shreg_b;
    assign fsm_state_o    = fsm_state;
    assign rf_rd_data_o   = rf_rd_data;
    assign bus_stage3_o   = bus_stage3;
endmodule


// ═══════════════════════════════════════════════════════════════════
// VARIANT 2 — STATIC GATING (all 6 modules gated by external enables)
// ═══════════════════════════════════════════════════════════════════
module datapath_static_cg (
    input  wire        clk, rst,
    input  wire [31:0] alu_a, alu_b,
    input  wire [2:0]  alu_op,
    input  wire        alu_en,
    input  wire [31:0] mult_a, mult_b,
    input  wire        mult_en,
    input  wire        shift_in_a, shift_in_b, shift_dir,
    input  wire        shift_en,
    input  wire [27:0] instr_in,
    input  wire        fsm_en,
    input  wire [2:0]  rf_wr_addr, rf_rd_addr,
    input  wire [31:0] rf_wr_data,
    input  wire        rf_wr_en,
    input  wire [31:0] bus_in,
    input  wire        bus_en,
    output wire [31:0] alu_result_o, alu_accum_o,
    output wire [63:0] mult_product_o,
    output wire [31:0] shreg_a_o, shreg_b_o,
    output wire [3:0]  fsm_state_o,
    output wire [31:0] rf_rd_data_o,
    output wire [31:0] bus_stage3_o
);
    wire [31:0] alu_result, alu_accum;
    wire [31:0] mult_a_reg, mult_b_reg;
    wire [63:0] mult_product;
    wire [31:0] shreg_a, shreg_b;
    wire [3:0]  fsm_state;
    wire [27:0] fsm_instr_reg;
    wire [31:0] rf_rd_data;
    wire [31:0] bus_stage1, bus_stage2, bus_stage3;

    alu_core       u_alu   (.clk(clk), .rst(rst), .en(alu_en), .a(alu_a), .b(alu_b), .op(alu_op), .result(alu_result), .accum(alu_accum));
    mult_unit      u_mult  (.clk(clk), .rst(rst), .en(mult_en), .a(mult_a), .b(mult_b), .a_reg(mult_a_reg), .b_reg(mult_b_reg), .product(mult_product));
    shift_reg_bank u_shift (.clk(clk), .rst(rst), .en(shift_en), .shift_in_a(shift_in_a), .shift_in_b(shift_in_b), .dir(shift_dir), .shreg_a(shreg_a), .shreg_b(shreg_b));
    control_fsm    u_fsm   (.clk(clk), .rst(rst), .en(fsm_en), .instr_in(instr_in), .state(fsm_state), .instr_reg(fsm_instr_reg));
    reg_file_cg    u_rf    (.clk(clk), .rst(rst), .wr_en(rf_wr_en), .wr_addr(rf_wr_addr), .rd_addr(rf_rd_addr), .wr_data(rf_wr_data), .rd_data(rf_rd_data));
    datapath_bus   u_bus   (.clk(clk), .rst(rst), .en(bus_en), .bus_in(bus_in), .stage1(bus_stage1), .stage2(bus_stage2), .stage3(bus_stage3));

    assign alu_result_o   = alu_result;
    assign alu_accum_o    = alu_accum;
    assign mult_product_o = mult_product;
    assign shreg_a_o      = shreg_a;
    assign shreg_b_o      = shreg_b;
    assign fsm_state_o    = fsm_state;
    assign rf_rd_data_o   = rf_rd_data;
    assign bus_stage3_o   = bus_stage3;
endmodule


// ═══════════════════════════════════════════════════════════════════
// VARIANT 3 — DYNAMIC GATING (all 6 modules gated by activity counters)
// ═══════════════════════════════════════════════════════════════════
module datapath_dynamic_cg (
    input  wire        clk, rst,
    input  wire [31:0] alu_a, alu_b,
    input  wire [2:0]  alu_op,
    input  wire        alu_valid,
    input  wire [31:0] mult_a, mult_b,
    input  wire        mult_valid,
    input  wire        shift_in_a, shift_in_b, shift_dir,
    input  wire        shift_valid,
    input  wire [27:0] instr_in,
    input  wire        fsm_valid,
    input  wire [2:0]  rf_wr_addr, rf_rd_addr,
    input  wire [31:0] rf_wr_data,
    input  wire        rf_valid,
    input  wire [31:0] bus_in,
    input  wire        bus_valid,
    output wire [31:0] alu_result_o, alu_accum_o,
    output wire [63:0] mult_product_o,
    output wire [31:0] shreg_a_o, shreg_b_o,
    output wire [3:0]  fsm_state_o,
    output wire [31:0] rf_rd_data_o,
    output wire [31:0] bus_stage3_o
);
    wire [31:0] alu_result, alu_accum;
    wire [31:0] mult_a_reg, mult_b_reg;
    wire [63:0] mult_product;
    wire [31:0] shreg_a, shreg_b;
    wire [3:0]  fsm_state;
    wire [27:0] fsm_instr_reg;
    wire [31:0] rf_rd_data;
    wire [31:0] bus_stage1, bus_stage2, bus_stage3;

    wire alu_en, mult_en, shift_en, fsm_en, rf_en, bus_en;

    dyn_cg_ctrl u_dyn_alu   (.clk(clk), .rst(rst), .data_valid(alu_valid),   .en_out(alu_en));
    dyn_cg_ctrl u_dyn_mult  (.clk(clk), .rst(rst), .data_valid(mult_valid),  .en_out(mult_en));
    dyn_cg_ctrl u_dyn_shift (.clk(clk), .rst(rst), .data_valid(shift_valid), .en_out(shift_en));
    dyn_cg_ctrl u_dyn_fsm   (.clk(clk), .rst(rst), .data_valid(fsm_valid),   .en_out(fsm_en));
    dyn_cg_ctrl u_dyn_rf    (.clk(clk), .rst(rst), .data_valid(rf_valid),    .en_out(rf_en));
    dyn_cg_ctrl u_dyn_bus   (.clk(clk), .rst(rst), .data_valid(bus_valid),   .en_out(bus_en));

    alu_core       u_alu   (.clk(clk), .rst(rst), .en(alu_en), .a(alu_a), .b(alu_b), .op(alu_op), .result(alu_result), .accum(alu_accum));
    mult_unit      u_mult  (.clk(clk), .rst(rst), .en(mult_en), .a(mult_a), .b(mult_b), .a_reg(mult_a_reg), .b_reg(mult_b_reg), .product(mult_product));
    shift_reg_bank u_shift (.clk(clk), .rst(rst), .en(shift_en), .shift_in_a(shift_in_a), .shift_in_b(shift_in_b), .dir(shift_dir), .shreg_a(shreg_a), .shreg_b(shreg_b));
    control_fsm    u_fsm   (.clk(clk), .rst(rst), .en(fsm_en), .instr_in(instr_in), .state(fsm_state), .instr_reg(fsm_instr_reg));
    reg_file_cg    u_rf    (.clk(clk), .rst(rst), .wr_en(rf_en), .wr_addr(rf_wr_addr), .rd_addr(rf_rd_addr), .wr_data(rf_wr_data), .rd_data(rf_rd_data));
    datapath_bus   u_bus   (.clk(clk), .rst(rst), .en(bus_en), .bus_in(bus_in), .stage1(bus_stage1), .stage2(bus_stage2), .stage3(bus_stage3));

    assign alu_result_o   = alu_result;
    assign alu_accum_o    = alu_accum;
    assign mult_product_o = mult_product;
    assign shreg_a_o      = shreg_a;
    assign shreg_b_o      = shreg_b;
    assign fsm_state_o    = fsm_state;
    assign rf_rd_data_o   = rf_rd_data;
    assign bus_stage3_o   = bus_stage3;
endmodule


// ═══════════════════════════════════════════════════════════════════
// VARIANT 4 — HYBRID GATING
// ALU + Multiplier: STATIC | RegFile + ShiftRegBank + FSM + DataPathBus: DYNAMIC
// ═══════════════════════════════════════════════════════════════════
module datapath_hybrid_cg (
    input  wire        clk, rst,
    input  wire [31:0] alu_a, alu_b,
    input  wire [2:0]  alu_op,
    input  wire        alu_en,             // static
    input  wire [31:0] mult_a, mult_b,
    input  wire        mult_en,            // static
    input  wire        shift_in_a, shift_in_b, shift_dir,
    input  wire        shift_valid,        // dynamic
    input  wire [27:0] instr_in,
    input  wire        fsm_valid,          // dynamic
    input  wire [2:0]  rf_wr_addr, rf_rd_addr,
    input  wire [31:0] rf_wr_data,
    input  wire        rf_valid,           // dynamic
    input  wire [31:0] bus_in,
    input  wire        bus_valid,          // dynamic
    output wire [31:0] alu_result_o, alu_accum_o,
    output wire [63:0] mult_product_o,
    output wire [31:0] shreg_a_o, shreg_b_o,
    output wire [3:0]  fsm_state_o,
    output wire [31:0] rf_rd_data_o,
    output wire [31:0] bus_stage3_o
);
    wire [31:0] alu_result, alu_accum;
    wire [31:0] mult_a_reg, mult_b_reg;
    wire [63:0] mult_product;
    wire [31:0] shreg_a, shreg_b;
    wire [3:0]  fsm_state;
    wire [27:0] fsm_instr_reg;
    wire [31:0] rf_rd_data;
    wire [31:0] bus_stage1, bus_stage2, bus_stage3;

    wire shift_en, fsm_en, rf_en, bus_en;

    dyn_cg_ctrl u_dyn_shift (.clk(clk), .rst(rst), .data_valid(shift_valid), .en_out(shift_en));
    dyn_cg_ctrl u_dyn_fsm   (.clk(clk), .rst(rst), .data_valid(fsm_valid),   .en_out(fsm_en));
    dyn_cg_ctrl u_dyn_rf    (.clk(clk), .rst(rst), .data_valid(rf_valid),    .en_out(rf_en));
    dyn_cg_ctrl u_dyn_bus   (.clk(clk), .rst(rst), .data_valid(bus_valid),   .en_out(bus_en));

    alu_core       u_alu   (.clk(clk), .rst(rst), .en(alu_en), .a(alu_a), .b(alu_b), .op(alu_op), .result(alu_result), .accum(alu_accum));
    mult_unit      u_mult  (.clk(clk), .rst(rst), .en(mult_en), .a(mult_a), .b(mult_b), .a_reg(mult_a_reg), .b_reg(mult_b_reg), .product(mult_product));
    shift_reg_bank u_shift (.clk(clk), .rst(rst), .en(shift_en), .shift_in_a(shift_in_a), .shift_in_b(shift_in_b), .dir(shift_dir), .shreg_a(shreg_a), .shreg_b(shreg_b));
    control_fsm    u_fsm   (.clk(clk), .rst(rst), .en(fsm_en), .instr_in(instr_in), .state(fsm_state), .instr_reg(fsm_instr_reg));
    reg_file_cg    u_rf    (.clk(clk), .rst(rst), .wr_en(rf_en), .wr_addr(rf_wr_addr), .rd_addr(rf_rd_addr), .wr_data(rf_wr_data), .rd_data(rf_rd_data));
    datapath_bus   u_bus   (.clk(clk), .rst(rst), .en(bus_en), .bus_in(bus_in), .stage1(bus_stage1), .stage2(bus_stage2), .stage3(bus_stage3));

    assign alu_result_o   = alu_result;
    assign alu_accum_o    = alu_accum;
    assign mult_product_o = mult_product;
    assign shreg_a_o      = shreg_a;
    assign shreg_b_o      = shreg_b;
    assign fsm_state_o    = fsm_state;
    assign rf_rd_data_o   = rf_rd_data;
    assign bus_stage3_o   = bus_stage3;
endmodule