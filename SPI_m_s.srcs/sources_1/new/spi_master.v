module spi_master #(
    parameter CLK_DIV = 4
)(
    input        clk,
    input        rst_n,

    input        start,
    input  [7:0] tx_data,

    output reg [7:0] rx_data,
    output reg       busy,
    output reg       done,

    output reg       sclk,
    output reg       mosi,
    input            miso,
    output reg       cs_n
);

    // ------------------------------------------------
    // State definitions
    // ------------------------------------------------
    localparam IDLE     = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam FINISH   = 2'b10;

    reg [1:0] state;

    // ------------------------------------------------
    // Internal registers
    // ------------------------------------------------
    reg [7:0] tx_shift;
    reg [7:0] rx_shift;

    reg [2:0] bit_count;

    // Wide enough for normal divider values
    reg [15:0] clk_count;


    // ------------------------------------------------
    // Main sequential block
    // ------------------------------------------------
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            state     <= IDLE;

            tx_shift  <= 8'd0;
            rx_shift  <= 8'd0;
            rx_data   <= 8'd0;

            bit_count <= 3'd0;
            clk_count <= 16'd0;

            sclk      <= 1'b0;
            mosi      <= 1'b0;
            cs_n      <= 1'b1;

            busy      <= 1'b0;
            done      <= 1'b0;

        end

        else begin

            // Done remains HIGH only for one clk cycle
            done <= 1'b0;

            case (state)

                // ========================================
                // IDLE STATE
                // ========================================
                IDLE: begin

                    sclk      <= 1'b0;
                    cs_n      <= 1'b1;
                    busy      <= 1'b0;

                    clk_count <= 16'd0;
                    bit_count <= 3'd0;

                    if (start) begin

                        // Load TX data
                        tx_shift <= tx_data;

                        // Clear RX register
                        rx_shift <= 8'd0;

                        // Mode 0:
                        // First MOSI bit must be valid
                        // before first rising SCLK edge
                        mosi <= tx_data[7];

                        // Select slave
                        cs_n <= 1'b0;

                        busy <= 1'b1;

                        state <= TRANSFER;

                    end

                end


                // ========================================
                // TRANSFER STATE
                // ========================================
                TRANSFER: begin

                    busy <= 1'b1;

                    if (clk_count == CLK_DIV - 1) begin

                        clk_count <= 16'd0;

                        // --------------------------------
                        // SCLK LOW -> HIGH
                        //
                        // Rising edge
                        // Sample MISO
                        // --------------------------------
                        if (sclk == 1'b0) begin

                            sclk <= 1'b1;

                            rx_shift <= {
                                rx_shift[6:0],
                                miso
                            };

                        end


                        // --------------------------------
                        // SCLK HIGH -> LOW
                        //
                        // Falling edge
                        // Change MOSI
                        // --------------------------------
                        else begin

                            sclk <= 1'b0;


                            // Last bit completed
                            if (bit_count == 3'd7) begin

                                state <= FINISH;

                            end

                            else begin

                                // Shift transmit register
                                tx_shift <= {
                                    tx_shift[6:0],
                                    1'b0
                                };

                                // Prepare next MOSI bit
                                mosi <= tx_shift[6];

                                // Next bit
                                bit_count <= bit_count + 1'b1;

                            end

                        end

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                // ========================================
                // FINISH STATE
                // ========================================
                FINISH: begin

                    // SPI Mode 0 idle clock
                    sclk <= 1'b0;

                    // Release chip select
                    cs_n <= 1'b1;

                    busy <= 1'b0;

                    // Pulse completion signal
                    done <= 1'b1;

                    // Save received byte
                    rx_data <= rx_shift;

                    state <= IDLE;

                end


                // ========================================
                // DEFAULT
                // ========================================
                default: begin

                    state <= IDLE;

                    sclk <= 1'b0;
                    cs_n <= 1'b1;
                    busy <= 1'b0;

                end

            endcase

        end

    end

endmodule