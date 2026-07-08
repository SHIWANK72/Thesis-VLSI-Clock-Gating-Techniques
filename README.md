# Thesis-VLSI-Clock-Gating-Techniques

> **Status: 🔄 Under Reproducibility Verification (as of July 2026)**

## Current Situation

This repository originally contained a **pre-research thesis** (Jan–Sep 2025, Kurukshetra University) investigating clock gating for dynamic power reduction. The original methodology assumed access to commercial EDA tools (Synopsys Design Compiler, PrimeTime PX, IC Compiler) at 45nm. Those tools were not independently accessible, so **the reported results (61.7% dynamic power reduction, clock tree metrics, 180nm–16nm technology scaling) were theoretical/assumed — not derived from actual simulation, synthesis, or power analysis.**

This project is currently being **rebuilt end-to-end using a fully open-source, reproducible flow**, so that every number in the final version is backed by a log file, waveform, netlist, or power report that anyone can regenerate from this repo.

## Reproducibility Roadmap

| Phase | Description | Status |
|---|---|---|
| 0 | Toolchain setup (Icarus Verilog, Yosys, sky130 PDK, OpenSTA) | ⬜ Pending |
| 1 | RTL — 6-module RISC datapath (640 FFs): ALU, Register File, Multiplier, Shift Register Bank, Control FSM, Data Path Bus | ⬜ Pending |
| 2 | Testbenches — 4 workload vectors (ALU-intensive, memory-heavy, multiplier-intensive, mixed) | ⬜ Pending |
| 3 | Functional verification (Icarus Verilog, VCD waveforms) | ⬜ Pending |
| 4 | Synthesis — Yosys + sky130 PDK, 4 gating configurations (None / Static / Dynamic / Hybrid) | ⬜ Pending |
| 5 | Power analysis — OpenSTA + real switching activity from VCD (replaces PrimeTime PX) | ⬜ Pending |
| 6 | Thesis rewrite with real numbers + proof package (RTL, VCDs, netlists, power reports) | ⬜ Pending |

*(Checkboxes will be updated as each phase completes, with linked proof artifacts.)*

## Why the Rewrite

Engineering credibility comes from reproducibility, not just plausible-sounding numbers. Rather than leave an unverified academic thesis as the final artifact, this repo is being converted into a fully open, buildable flow — same design, same architecture, but every claim traceable to a command and its output.

## Original Thesis

The original pre-research thesis document is retained in this repo for reference and historical context. It should be read as a **design and methodology proposal**, not as validated experimental results, until the reproducibility phases above are complete.

## Project Overview

The core objective is to analyze and implement clock gating to prevent unnecessary switching activity in idle registers of a 32-bit RISC datapath, evaluating static, dynamic, and hybrid gating strategies for dynamic power reduction.

## Author

**Shiwank Gupta** — VLSI Design Engineer / FPGA Developer, Nik-Coronics R&D
# Thesis-VLSI-Clock-Gating-Techniques
A research thesis investigating the effectiveness of clock gating techniques for reducing dynamic power consumption in synchronous digital circuits.
# Thesis: Investigation of Novel Clock Gating Techniques

This repository contains the documentation and sample code for my undergraduate thesis on clock gating techniques. The clock network is one of the largest sources of power consumption in synchronous digital systems. This research explores methods to reduce this dynamic power by deactivating the clock to idle modules.

## Project Overview
[cite_start]The core objective was to analyze and implement clock gating to prevent unnecessary switching activity in idle functional blocks, thereby saving a significant amount of dynamic power. 

## Concepts Investigated
- **Dynamic Power Consumption**: A deep dive into the `P = C * V^2 * f * a` equation, with a focus on reducing the activity factor (`a`).
- **Latch-Free vs. Latch-Based Clock Gating**: Analysis of different implementation styles. Latch-based gating is generally preferred as it is glitch-free and safer for synthesis.

## Implementation & Analysis
A standard, latch-based clock gating cell was implemented in Verilog to demonstrate the concept. The logic uses an enable signal to control the clock flow to a downstream register bank.

The efficacy of this technique was validated by integrating the clock gating cell into a benchmark digital circuit. [cite_start]The design was then analyzed using **Synopsys tools** to: [cite: 47]
1.  Synthesize the design correctly, ensuring timing constraints were met.
2.  Run power analysis simulations both with and without clock gating.
3.  Quantify the percentage reduction in dynamic power.

## Key Learnings
This research provided a strong understanding of low-power design methodologies used in the industry. It offered practical experience in writing synthesizable Verilog for power-sensitive applications and using professional EDA tools for power analysis and verification.
