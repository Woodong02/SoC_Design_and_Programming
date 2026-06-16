# Verilog HDL Coding Standards

Design principles: **Descriptive, realistic, and structurally clear hardware modeling.**

---

## Port Naming Convention

### Input Ports: `i_` prefix
```verilog
input i_CLK
input signed [31:0] i_ERROR
input signed [31:0] i_SETPOINT
```

### Output Ports: `o_` prefix
```verilog
output signed [31:0] o_NEXT_DRIVE
output signed [31:0] o_HALL_SENSOR
```

### Internal Wires: Descriptive names (no prefix)
```verilog
wire internal_error;
wire motor_voltage;
wire pwm_output;
```

---

## Core Principle: Port → Internal → Logic → Output

**DO NOT use port signals directly in logic.**

**Correct Pattern:**
```verilog
module example (
    input [31:0] i_A,
    output [31:0] o_B
);
    // Step 1: Internal wire declarations
    wire [31:0] internal_a;
    wire [31:0] processed_value;
    wire [31:0] internal_b;
    
    // Step 2: Input assignment (port → internal)
    assign internal_a = i_A;
    
    // Step 3: Combinational logic (internal processing)
    assign processed_value = internal_a + 10;
    
    // Step 4: Sequential logic (always blocks for FF)
    always @(posedge clk) begin
        ff_register <= processed_value;
    end
    
    // Step 5: Output assignment (internal → port)
    assign internal_b = ff_register;
    assign o_B = internal_b;
endmodule
```

---

## Wire Assignment (`assign`) Usage

### Purpose
Direct, combinational connection of signals. One line = one logical signal path.

### When to Use
- Input buffering: `port → internal`
- Output buffering: `internal → port`
- Combinational operations
- Direct signal routing

### When NOT to Use
- Sequential logic (use `always` blocks)
- Complex logic (use separate modules or functions)

### Examples
```verilog
// ✓ Correct: Direct signal buffering
assign internal_signal = i_PORT;

// ✓ Correct: Combinational arithmetic
assign sum_result = value_a + value_b;

// ✓ Correct: Conditional logic
assign output_mux = (select) ? value_x : value_y;

// ✗ Wrong: Sequential logic
assign ff_register <= next_value;  // Don't use assign for FF

// ✗ Wrong: Complex state machine
assign next_state = (state==S0 && condition) ? S1 : state;  // Too complex
```

---

## Sequential Logic: `always` Blocks

### Critical Constraint
**One `always` block handles ONE flip-flop bus only.**

Each group of related flip-flops gets its own `always` block. This ensures:
- Realistic FF modeling (one physical register per block)
- Clear code structure
- Predictable synthesis results

### Examples

**✓ Correct: Separate FF groups**
```verilog
// FF group 1: P output
always @(posedge i_CLK) begin
    ff_p_out <= calculated_p_value;
end

// FF group 2: I accumulator
always @(posedge i_CLK) begin
    ff_i_accumulator <= ff_i_accumulator + error_term;
end

// FF group 3: D derivative
always @(posedge i_CLK) begin
    ff_d_prev_error <= current_error;
end
```

**✗ Wrong: Multiple FF groups in one block**
```verilog
always @(posedge i_CLK) begin
    ff_p_out <= calculated_p_value;           // FF group 1
    ff_i_accumulator <= new_accumulator;      // FF group 2
    ff_d_prev_error <= current_error;         // FF group 3
end  // DON'T DO THIS
```

### Sensitivity List
```verilog
always @(posedge i_CLK)        // Synchronous logic
always @(negedge i_CLK)        // Negative edge (if needed)
always @(*)                    // Combinational (rare - use assign instead)
```

---

## Code Organization Order

Every module must follow this structure:

```verilog
module module_name (
    // 1. Port declarations
    input wire [...] port_list,
    output wire [...] port_list
);

    // 2. Parameter declarations
    parameter [...] PARAM_NAME = value;
    
    // 3. Internal wire declarations
    wire [...] input_buffers;
    wire [...] internal_signals;
    wire [...] ff_outputs;
    wire [...] output_buffers;
    
    // 4. Input assignments (port → internal)
    assign input_buffer_1 = i_PORT_1;
    assign input_buffer_2 = i_PORT_2;
    
    // 5. Combinational logic (internal processing)
    assign processed_signal = operation(input_buffer);
    assign another_result = calculation(input_buffer);
    
    // 6. Sequential logic blocks (one FF bus each)
    always @(posedge i_CLK) begin
        ff_register_1 <= calculated_value_1;
    end
    
    always @(posedge i_CLK) begin
        ff_register_2 <= calculated_value_2;
    end
    
    // 7. Output assignments (internal → port)
    assign o_PORT_1 = ff_register_1;
    assign o_PORT_2 = ff_register_2;

endmodule
```

---

## Data Types

### All signals in this project
Use: `signed [31:0]` (32-bit signed integer)

```verilog
input signed [31:0] i_ERROR;
wire signed [31:0] processed;
output signed [31:0] o_RESULT;
```

**Why signed 32-bit:**
- Supports negative values (for error, relative velocity, etc.)
- Large enough for typical arithmetic
- Standard across all modules (consistency)

---

## Naming Conventions

### Clock Signals
```verilog
i_CLK, i_CLK_SLOW, i_CLK_FAST
```

### Data Signals (Descriptive)
```verilog
error_signal
proportional_term, p_term, p_out
integral_accumulator, i_out
derivative_term, d_out
motor_voltage
pwm_output
```

### Temporary/Intermediate Signals
```verilog
temp_result
intermediate_sum
calculated_value
```

### Multiplied Results
```verilog
value_product
scaled_output
```

### Accumulated Values
```verilog
accumulator
sum_total
```

---

## Comments

### When to Comment
- Non-obvious constraints
- Workarounds for specific bugs
- Hardware-level details that code can't express

### When NOT to Comment
- Code is self-documenting (good naming, clear structure)
- Describing WHAT the code does (the code does that)
- Referencing external requirements (belongs in PR description, not code)

### Examples
```verilog
// ✓ Good: Explains WHY
assign distance = distance + (v_rel * dt);  // Integrate relative velocity

// ✗ Bad: Explains WHAT (code already shows this)
// Add error to accumulator
ff_accumulator <= ff_accumulator + error;

// ✓ Good: Explains constraint
// Clamp to prevent overflow in 32-bit arithmetic
assign clamped = (sum > MAX_VAL) ? MAX_VAL : sum;
```

---

## Module Declaration Template

```verilog
module module_name (
    input i_CLK,
    input signed [31:0] i_INPUT_1,
    input signed [31:0] i_INPUT_2,
    output signed [31:0] o_OUTPUT
);

    parameter [31:0] PARAM_1 = 32'd0;
    parameter [31:0] PARAM_2 = 32'd0;

    wire signed [31:0] input_1;
    wire signed [31:0] input_2;
    wire signed [31:0] internal_result;
    wire signed [31:0] ff_output;

    assign input_1 = i_INPUT_1;
    assign input_2 = i_INPUT_2;
    
    assign internal_result = input_1 + input_2;
    
    always @(posedge i_CLK) begin
        ff_output <= internal_result;
    end
    
    assign o_OUTPUT = ff_output;

endmodule
```

---

## Quick Checklist

Before committing code:
- [ ] All inputs use `i_` prefix
- [ ] All outputs use `o_` prefix
- [ ] All inputs have internal wire copies
- [ ] All outputs have internal wire sources
- [ ] Each FF has its own `always` block
- [ ] `assign` statements only for combinational logic
- [ ] Code follows: input → internal → logic → FF → output
- [ ] All signals are `signed [31:0]`
- [ ] No unused ports or signals
- [ ] Comments only for non-obvious logic
