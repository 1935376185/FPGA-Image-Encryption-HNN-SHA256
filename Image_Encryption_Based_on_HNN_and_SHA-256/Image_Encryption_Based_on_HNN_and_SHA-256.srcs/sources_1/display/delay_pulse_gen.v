`timescale 1ns / 1ps
// ============================================================================
// Module Name: delay_pulse_gen
// Description:
//   Generates a single pulse after a specified delay time.
//   Commonly used for initialization timing control.
//
// Parameters:
//   - DELAY_TIME_MS : Delay duration in milliseconds
//   - CLK_FREQ_MHZ  : Clock frequency in MHz
// ============================================================================

module delay_pulse_gen #(
    parameter DELAY_TIME_MS = 0,   // Delay time (ms)
    parameter CLK_FREQ_MHZ  = 50    // Clock frequency (MHz)
)(
    input  wire clk,
    input  wire rst_n,
    output reg  pulse_out           // Output pulse (1-cycle pulse)
);

    // ------------------------------------------------------------------------
    // Counter configuration
    // ------------------------------------------------------------------------
    localparam CNT_MAX   = DELAY_TIME_MS * CLK_FREQ_MHZ * 1000 - 1;
    localparam CNT_WIDTH = $clog2(CNT_MAX + 2);

    reg [CNT_WIDTH-1:0] cnt;

    // ------------------------------------------------------------------------
    // Counter logic
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 0;
        else if (cnt <= CNT_MAX)
            cnt <= cnt + 1;
        else
            cnt <= CNT_MAX + 1;  // Stop counting after reaching max
    end

    // ------------------------------------------------------------------------
    // Pulse generation (single-cycle pulse at CNT_MAX)
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pulse_out <= 1'b0;
        else if (cnt == CNT_MAX)
            pulse_out <= 1'b1;
        else
            pulse_out <= 1'b0;
    end

endmodule
