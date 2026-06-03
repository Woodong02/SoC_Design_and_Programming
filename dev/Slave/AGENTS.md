# AI Harness Rules for This Project

이 문서는 이 디렉토리에서 AI가 임베디드 C 및 Verilog HDL 작업을 수행할 때 따라야 하는 작업 하네스이다.

## Project Context

- Target board: Huins RPS-Z020-TK educational board.
- Target device: Xilinx Zynq-7000 `xc7z020clg484-1`.
- Main tool: Vivado 2019.1.
- Vivado executable confirmed at:
  - `C:\Xilinx\Vivado\2019.1\bin\vivado.bat`
- ModelSim is available by user statement, but CLI access has not yet been verified.
- Simulation priority:
  - Use Vivado/xsim first for architecture-dependent or Vivado-IP-dependent work.
  - ModelSim may be used first for architecture-independent pure Verilog module verification.
- HDL language constraint: use pure Verilog only. Do not introduce SystemVerilog-only syntax.
- Main task: create PL-side IP that communicates with another board.

## Repository Permission Model

- All files under this directory may be inspected and modified by AI.
- AI may create design notes, source files, testbenches, simulation scripts, and project-support files in this directory.
- Git may be initialized and managed inside this directory when needed, but do not assume a repository already exists.

## Existing Inputs

- Coding standard: `CODING_STANDARDS.md`.
- Existing master PL source directory: `Master_ip`.
- Existing master PS software/reference directory: `Master_ps`.
- Previous master/slave specification directory: `이전 버전의 master와 slave 사양`.
- Fault decision reference image: `Fault_decisions_chart.jpg`.
- Fault decision chart status: final confirmed behavior. Treat the chart as the source of truth for master-side fault decision behavior. If details are unclear, verify against the master source code because the user states the master implements the chart exactly.

## Primary Work Sequence

1. Understand the provided master IP.
2. Define how the master is driven and controlled.
3. Define what features the master implements.
4. Define what requests, packets, timing, status, or control behavior the master expects from the slave.
5. Design a matching slave IP that can communicate with the master.
6. Implement slave modules bottom-up, with documentation and testbench verification at each level.

## Master IP Analysis Requirements

Before writing a matching slave, AI must produce Markdown analysis that answers:

- What modules exist in the master IP and what each module does.
- How the master is controlled from AXI or other control interfaces.
- What registers, control bits, status bits, or data paths exist.
- What transmit and receive behavior exists.
- What timing, framing, encoding, error-detection, or correction behavior exists.
- What response the master expects from a slave.
- What assumptions are confirmed by source code, and what assumptions are inferred.

The analysis must distinguish clearly between:

- Confirmed behavior from source.
- Inferred behavior.
- Unknown behavior requiring simulation or user clarification.

## Slave IP Design Rules

The slave must be designed to interoperate with the existing master, even if older abstract slave specifications conflict with the implemented master behavior.

Slave design must follow these principles:

- Follow `CODING_STANDARDS.md`.
- Use pure Verilog only.
- Use minimal-function module decomposition.
- One module should contain one primary function.
- Define the full module structure before writing implementation code.
- Build from leaf modules upward.
- A parent module may get its own testbench only after every instantiated child module has passed its own testbench.
- Each module must define all reachable states as an FSM when stateful behavior exists.
- Testbenches must cover the full FSM case space for the module under test.

## Required Per-Module Workflow

For every new or modified design module, follow this order:

1. Write a Korean-centered Markdown design note before writing source.
2. In the design note, explain the purpose of the module and why this source is being written.
3. Define the module interface.
4. Define the FSM, including all states, transitions, inputs, outputs, and terminal/error cases.
5. Define expected behavior and test coverage.
6. Write or modify the Verilog source.
7. Write the testbench for that module.
8. Run simulation or lint when tools are available.
9. Record verification results in Markdown.

## Coding Standard Summary

Use `CODING_STANDARDS.md` as the source of truth. Key rules include:

- Input ports use `i_` prefix.
- Output ports use `o_` prefix.
- Do not use port signals directly in logic.
- Use internal wire copies for inputs and outputs.
- Maintain structure: port declarations, parameters, internal wires, input assignments, combinational logic, sequential logic, output assignments.
- Use `assign` for combinational signal paths.
- Use `always` blocks for sequential logic.
- One `always` block should handle one flip-flop bus only.
- Prefer `signed [31:0]` signals unless protocol width or hardware meaning requires another width.
- Comments should explain non-obvious constraints, not restate the code.

## Verification Discipline

Verification should be bottom-up and evidence-based.

For each module:

- Identify all valid input classes.
- Identify all FSM states.
- Test every state transition.
- Test reset behavior.
- Test boundary/error cases.
- Test nominal communication behavior.
- Write self-checking testbenches.
- Testbenches should print meaningful progress and result information with `$display`.
- Testbenches must clearly report PASS/FAIL in terminal output.
- Testbenches should remain waveform-friendly so the user can inspect signals later in Vivado or ModelSim.
- Keep simulation artifacts and notes organized.

For integration:

- Verify child modules first.
- Then verify composed modules.
- Then verify master/slave communication behavior.
- Use Vivado batch/Tcl or ModelSim CLI when possible.

## Tooling Notes

Vivado access was tested with:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -version
```

Confirmed version:

```text
Vivado v2019.1 (64-bit)
```

When using Vivado for automation, prefer batch mode and Tcl scripts over GUI-only workflows.

ModelSim may be used for early leaf-module simulations when the module has no Vivado architecture dependency. If a discrepancy exists between ModelSim and Vivado/xsim behavior, Vivado/xsim is authoritative for this project.

## Working Style

- Read existing source before making assumptions.
- Write analysis and design documents primarily in Korean, while preserving signal names, module names, and code identifiers in English.
- Keep design notes close to the modules they describe, or place them under a clearly named documentation directory.
- Do not skip documentation before source implementation.
- Do not skip testbench creation for new modules.
- Clearly report unverified assumptions.
- When a command fails, capture the important failure reason and decide whether it is a tool setup issue, source issue, or test issue.
