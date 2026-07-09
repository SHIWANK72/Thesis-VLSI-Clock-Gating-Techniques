# Clock Gating Optimization — Study Notes

> **Nik-Coronics | Independent R&D Initiative**
> **Engineer:** Shiwank Gupta
> **Date:** July 2026
> **Tools:** Yosys + OpenSTA + Sky130A PDK

---

## 🎯 Objective

Study the effect of clock gating on a 32-bit RISC datapath
by implementing 4 variants and comparing synthesis + power
results using open-source EDA tools.

---

## 📐 Design Variants

```
1. datapath_no_gating    — Baseline, no ICG cells
2. datapath_static_cg    — Static ICG: always-on gating
3. datapath_dynamic_cg   — Dynamic ICG: activity-based control
4. datapath_hybrid_cg    — Hybrid: static + dynamic combined
```

---

## 🔑 What is Clock Gating?

```
Every flip-flop consumes power on every clock edge —
even when its data hasn't changed.

Clock Gating = insert an ICG (Integrated Clock Gating) cell
               that blocks the clock when data is stable

Power saved = alpha × C × V² × f
Where alpha = switching activity factor

ICG cell structure:
  EN → Latch → AND gate → Gated CLK → FF clock pin

Key rule: EN must be stable when CLK is LOW
          (latch prevents glitches)
```

---

## ⚙️ Tool Flow

```
Platform  : Google Colab
Synthesis : Yosys 0.9 + Sky130A PDK
Timing    : OpenSTA 3.1.0
PDK       : sky130_fd_sc_hd (tt_025C_1v80)
```

---

## 📊 Synthesis Results

```
Variant               Cells    Area (µm²)
─────────────────────────────────────────
datapath_no_gating    7,164    57,837.97
datapath_static_cg    7,088    58,157.03    (+0.55%)
datapath_dynamic_cg   7,673    61,492.73    (+6.32%)
datapath_hybrid_cg    7,276    59,196.77    (+2.35%)

Note: Clock gating ADDS area due to ICG cell overhead.
Area reduction is not the goal — power reduction is.
```

---

## 📊 Power Analysis Results (OpenSTA)

```
Activity factor: 0.05 (5% switching, global uniform)
Clock period: 10 ns (100 MHz)
Corner: tt_025C_1v80

Variant               Total Power    vs Baseline
─────────────────────────────────────────────────
datapath_no_gating    3.24e-03 W     baseline
datapath_static_cg    3.24e-03 W     ~0%
datapath_dynamic_cg   3.41e-03 W     +5.7% (overhead)
datapath_hybrid_cg    3.34e-03 W     +3.1% (overhead)
```

---

## ⚠️ Honest Limitations

```
1. STATIC ANALYSIS LIMITATION
   OpenSTA uses global uniform activity (0.05)
   = Every signal treated identically
   = Clock gating benefit is selective (per-register)
   = Static analysis CANNOT capture selective benefit

2. BLACK BOX CELLS
   $_DLATCH_P_ = not in Sky130A liberty
   = Treated as black box
   = Power contribution not counted
   = Results underestimate actual power

3. VCD ANNOTATION NEEDED
   Accurate clock gating analysis requires:
   → Functional simulation → VCD file
   → Per-signal activity annotation
   → OpenSTA read_vcd → report_power
   This was NOT done in this study.

4. THEORETICAL VS TOOL RESULT
   Theoretical max saving (switching power model):
   P_dynamic = alpha × C × V² × f
   If alpha reduced by 50% via gating →
   switching power reduces by 50%
   
   Tool result: No reduction seen at alpha=0.05
   because ICG overhead > selective savings
   at this uniform activity level
```

---

## 🔑 Key Learnings

```
1. Clock gating saves power when:
   - Registers are frequently idle (alpha < 0.1)
   - Design has clear enable conditions
   - Activity is NON-UNIFORM across registers

2. Clock gating COSTS area:
   - Each ICG cell adds logic
   - Dynamic control adds extra logic
   - Net area always increases

3. Static power analysis limitations:
   - Cannot model per-register activity
   - VCD-based flow needed for accuracy
   - Global activity = worst-case approximation

4. ICG cell overhead:
   - At high activity (alpha > 0.2): overhead > savings
   - At low activity (alpha < 0.05): savings > overhead
   - Sweet spot depends on design

5. Real-world usage:
   - Clock gating applied selectively
   - Only to registers with clear idle patterns
   - Verified with power-aware simulation
```

---

## 📅 What This Study Covers

```
✅ RTL implementation — 4 variants
✅ Synthesis — Yosys + Sky130A
✅ Power estimation — OpenSTA static analysis
✅ Honest documentation of limitations
⬜ VCD-based dynamic power analysis
⬜ Gate-level simulation
⬜ Multi-corner analysis
```

---

## 🔭 Next Steps (Future Work)

```
1. Functional simulation → VCD generation
2. read_vcd in OpenSTA → per-signal activity
3. report_power → accurate dynamic power
4. Multi-corner: ff/ss/tt corners
5. Compare theoretical vs simulation results
```

---

*Shiwank Gupta | Nik-Coronics | VLSI R&D*