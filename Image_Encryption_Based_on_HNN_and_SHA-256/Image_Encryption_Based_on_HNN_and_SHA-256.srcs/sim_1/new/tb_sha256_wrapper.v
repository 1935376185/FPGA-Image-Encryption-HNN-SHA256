
`default_nettype none

module tb_sha256_wrapper;




  // DUT signals
  reg          clk;
  reg          reset_n;
  reg  [255:0] data_in;
  reg          start;
  wire [255:0] hash_out;
  wire         valid;
  wire         busy;

  // DUT
  sha256_wrapper dut (
    .clk      (clk),
    .reset_n  (reset_n),
    .data_in  (data_in),
    .start    (start),
    .hash_out (hash_out),
    .valid    (valid),
    .busy     (busy)
  );

  // 100 MHz clock
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // Pulse start for 1 cycle
  task automatic pulse_start;
    begin
      @(posedge clk);
      start <= 1'b1;
      @(posedge clk);
      start <= 1'b0;
    end
  endtask

  // Wait for valid with timeout
  task automatic wait_valid(input integer max_cycles);
    integer i;
    begin
      for (i = 0; i < max_cycles; i = i + 1) begin
        @(posedge clk);
        if (valid)
          i = max_cycles;
      end

      if (!valid) begin
        $display("[TB] ERROR: timeout waiting for valid");
        $finish;
      end
    end
  endtask

  // Run one test case
 task automatic run_case(
  input [255:0] msg,
  input [255:0] exp_hash,
  input [1023:0] name
);
  begin
    while (busy) @(posedge clk);
    @(posedge clk);          // ensure IDLE

    data_in = msg;           // blocking assignment
    @(posedge clk);          // hold stable 1 cycle

    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    wait_valid(200000);

    if (hash_out !== exp_hash) begin
      $display("[TB] FAIL: %0s", name);
      $display("[TB]   got : %064x", hash_out);
      $display("[TB]   exp : %064x", exp_hash);
      $finish;
    end else begin
      $display("[TB] PASS: %0s  hash=%064x", name, hash_out);
    end

    @(posedge clk);
  end
endtask

  // ------------------------------------------------------------------
  // Test vectors (no all-zero case)
  // ------------------------------------------------------------------

  // SHA256(00 01 02 ... 1f)
  localparam [255:0] EXP_VEC1 =
    256'h630dcd2966c4336691125448bbb25b4ff412a49c732db2c8abc1b8581bd710dd;

  wire [255:0] MSG_VEC1 = {
    8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07,
    8'h08, 8'h09, 8'h0a, 8'h0b, 8'h0c, 8'h0d, 8'h0e, 8'h0f,
    8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15, 8'h16, 8'h17,
    8'h18, 8'h19, 8'h1a, 8'h1b, 8'h1c, 8'h1d, 8'h1e, 8'h1f
  };

  // SHA256(20 21 22 ... 3f)
localparam [255:0] EXP_VEC2 =
  256'h72dbb7336c76780023f83da4c355f2eeea85733b13d3477697917790c1229084;


  wire [255:0] MSG_VEC2 = {
    8'h20, 8'h21, 8'h22, 8'h23, 8'h24, 8'h25, 8'h26, 8'h27,
    8'h28, 8'h29, 8'h2a, 8'h2b, 8'h2c, 8'h2d, 8'h2e, 8'h2f,
    8'h30, 8'h31, 8'h32, 8'h33, 8'h34, 8'h35, 8'h36, 8'h37,
    8'h38, 8'h39, 8'h3a, 8'h3b, 8'h3c, 8'h3d, 8'h3e, 8'h3f
  };

  // ------------------------------------------------------------------
  // Main
  // ------------------------------------------------------------------
  initial begin
    reset_n = 1'b0;
    start   = 1'b0;
    data_in = 256'h0;

    repeat (5) @(posedge clk);
    reset_n = 1'b1;
    repeat (2) @(posedge clk);

    run_case(MSG_VEC1, EXP_VEC1, "INC_00_TO_1F");
    run_case(MSG_VEC2, EXP_VEC2, "INC_20_TO_3F");

    $display("[TB] ALL TESTS PASSED");
    $finish;
  end

endmodule

`default_nettype wire
