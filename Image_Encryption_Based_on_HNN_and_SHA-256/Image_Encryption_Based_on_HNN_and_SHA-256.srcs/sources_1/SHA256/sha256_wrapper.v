
`timescale 1ns / 1ps
`default_nettype none

module sha256_wrapper(
    input  wire           clk,
    input  wire           reset_n,

    input  wire [255:0]   data_in,
    input  wire           start,
    output reg  [255:0]   hash_out,
    output reg            valid,
    output wire           busy
);

    // State encoding
    localparam [3:0] IDLE          = 4'd0;
    localparam [3:0] WRITE_BLOCK   = 4'd1;
    localparam [3:0] TRIGGER_HASH  = 4'd2;
    localparam [3:0] WAIT_RDY_LOW  = 4'd3; // wait ready go low (core starts)
    localparam [3:0] WAIT_RDY_HIGH = 4'd4; // wait ready go high (core done)
    localparam [3:0] READ_DIGEST   = 4'd5;
    localparam [3:0] READ_LAST     = 4'd6;
    localparam [3:0] DONE          = 4'd7;

    reg [3:0] state_reg;

    reg [3:0] block_counter;   // 0..15
    reg [2:0] digest_idx;      // 0..7

    // Secworks sha256 wrapper bus
    reg         sha_cs;
    reg         sha_we;
    reg [7:0]   sha_address;
    reg [31:0]  sha_write_data;
    wire [31:0] sha_read_data;
    wire        sha_error;

    // Latch input message to avoid changing during block writes
    reg [255:0] msg_reg;

    // Padded single 512-bit block for 256-bit message
    reg [511:0] padded_block;

    // status read alignment flag (because read_data corresponds to previous cycle address)
    reg status_valid;

    assign busy = (state_reg != IDLE);

    sha256 sha256_core(
        .clk(clk),
        .reset_n(reset_n),
        .cs(sha_cs),
        .we(sha_we),
        .address(sha_address),
        .write_data(sha_write_data),
        .read_data(sha_read_data),
        .error(sha_error)
    );

    // Build padded block from latched msg_reg
    always @* begin
        padded_block = {
            msg_reg,
            8'h80,
            184'h0,
            64'h0000000000000100  // length = 256 bits
        };
    end

    // Digest store task
    task automatic store_digest_word(
        input [2:0]  idx,
        input [31:0] w
    );
        begin
            case (idx)
                3'd0: hash_out[255:224] <= w;
                3'd1: hash_out[223:192] <= w;
                3'd2: hash_out[191:160] <= w;
                3'd3: hash_out[159:128] <= w;
                3'd4: hash_out[127:96]  <= w;
                3'd5: hash_out[95:64]   <= w;
                3'd6: hash_out[63:32]   <= w;
                3'd7: hash_out[31:0]    <= w;
            endcase
        end
    endtask

    // Digest read pipeline (read_data corresponds to previous cycle address)
    reg       prev_valid;
    reg [2:0] prev_idx;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state_reg      <= IDLE;
            block_counter  <= 4'd0;
            digest_idx     <= 3'd0;

            sha_cs         <= 1'b0;
            sha_we         <= 1'b0;
            sha_address    <= 8'h00;
            sha_write_data <= 32'h0;

            msg_reg        <= 256'h0;
            hash_out       <= 256'h0;
            valid          <= 1'b0;

            prev_valid     <= 1'b0;
            prev_idx       <= 3'd0;

            status_valid   <= 1'b0;
        end else begin
            // Defaults
            sha_cs         <= 1'b0;
            sha_we         <= 1'b0;
            sha_address    <= 8'h00;
            sha_write_data <= 32'h0;

            case (state_reg)
                IDLE: begin
                    valid         <= 1'b0;
                    block_counter <= 4'd0;
                    digest_idx    <= 3'd0;
                    prev_valid    <= 1'b0;
                    status_valid  <= 1'b0;

                    if (start) begin
                        // Latch input once at start
                        msg_reg  <= data_in;
                        // Clear output so no-strobe is obvious
                        hash_out <= 256'h0;
                        state_reg <= WRITE_BLOCK;
                    end
                end

                // Write BLOCK0..BLOCK15 at 0x10..0x1F
                WRITE_BLOCK: begin
                    sha_cs      <= 1'b1;
                    sha_we      <= 1'b1;
                    sha_address <= 8'h10 + block_counter;
                    sha_write_data <= padded_block[511 - block_counter*32 -: 32];

                    if (block_counter == 4'd15) begin
                        state_reg <= TRIGGER_HASH;
                    end else begin
                        block_counter <= block_counter + 1'b1;
                    end
                end

                // CTRL at 0x08: init=1, next=0, mode=SHA-256 => 0x5
                TRIGGER_HASH: begin
                    sha_cs         <= 1'b1;
                    sha_we         <= 1'b1;
                    sha_address    <= 8'h08;
                    sha_write_data <= 32'h00000005;

                    // prepare to read STATUS with correct alignment
                    status_valid   <= 1'b0;
                    state_reg      <= WAIT_RDY_LOW;
                end

                // STATUS at 0x09: wait until ready goes low (core has started)
                WAIT_RDY_LOW: begin
                    sha_cs      <= 1'b1;
                    sha_we      <= 1'b0;
                    sha_address <= 8'h09;

                    // first cycle here: read_data is stale (previous address), do not evaluate
                    if (!status_valid) begin
                        status_valid <= 1'b1;
                    end else begin
                        // ready is bit0
                        if (!sha_read_data[0]) begin
                            status_valid <= 1'b0;
                            state_reg <= WAIT_RDY_HIGH;
                        end
                    end
                end

                // STATUS at 0x09: wait until ready goes high (core has finished)
                WAIT_RDY_HIGH: begin
                    sha_cs      <= 1'b1;
                    sha_we      <= 1'b0;
                    sha_address <= 8'h09;

                    if (!status_valid) begin
                        status_valid <= 1'b1;
                    end else begin
                        if (sha_read_data[0]) begin
                            digest_idx   <= 3'd0;
                            prev_valid   <= 1'b0;
                            status_valid <= 1'b0;
                            state_reg    <= READ_DIGEST;
                        end
                    end
                end

                // Issue reads to DIGEST0..DIGEST7 (0x20..0x27)
                // Store previous cycle's read_data each cycle.
                READ_DIGEST: begin
                    sha_cs      <= 1'b1;
                    sha_we      <= 1'b0;
                    sha_address <= 8'h20 + digest_idx;

                    if (prev_valid)
                        store_digest_word(prev_idx, sha_read_data);

                    prev_valid <= 1'b1;
                    prev_idx   <= digest_idx;

                    if (digest_idx == 3'd7) begin
                        state_reg <= READ_LAST;
                    end else begin
                        digest_idx <= digest_idx + 1'b1;
                    end
                end

                // One extra cycle to capture the last word (DIGEST7)
                READ_LAST: begin
                    if (prev_valid)
                        store_digest_word(prev_idx, sha_read_data);

                    prev_valid <= 1'b0;
                    state_reg  <= DONE;
                end

                DONE: begin
                    valid     <= 1'b1;
                    state_reg <= IDLE;
                end

                default: state_reg <= IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
