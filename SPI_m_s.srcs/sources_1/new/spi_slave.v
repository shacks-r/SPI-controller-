module spi_slave (
    input        rst_n,

    input        sclk,
    input        cs_n,

    input        mosi,
    output reg   miso,

    input  [7:0] tx_data,

    output reg [7:0] rx_data,
    output reg       rx_valid
);

    // ------------------------------------------------
    // Internal registers
    // ------------------------------------------------
    reg [7:0] tx_shift;
    reg [7:0] rx_shift;

    reg [2:0] bit_count;


    // ------------------------------------------------
    // Start of SPI transaction
    //
    // CS_N goes LOW
    // Load transmit data and place first bit on MISO
    // ------------------------------------------------
    always @(negedge cs_n or negedge rst_n) begin

        if (!rst_n) begin

            tx_shift <= 8'd0;
            miso     <= 1'b0;

        end

        else begin

            // Load slave transmit data
            tx_shift <= tx_data;

            // SPI Mode 0:
            // First MISO bit must already be valid
            // before first rising SCLK edge
            miso <= tx_data[7];

        end

    end


    // ------------------------------------------------
    // RECEIVE LOGIC
    //
    // SPI Mode 0:
    // Sample MOSI on rising edge of SCLK
    // ------------------------------------------------
    always @(posedge sclk or posedge cs_n or negedge rst_n) begin

        if (!rst_n) begin

            rx_shift  <= 8'd0;
            rx_data   <= 8'd0;

            bit_count <= 3'd0;

            rx_valid  <= 1'b0;

        end

        else if (cs_n) begin

            // Transaction ended / slave deselected
            bit_count <= 3'd0;
            rx_valid  <= 1'b0;

        end

        else begin

            // Shift incoming MOSI bit into RX register
            rx_shift <= {
                rx_shift[6:0],
                mosi
            };


            // Check if this is the 8th received bit
            if (bit_count == 3'd7) begin

                // Store complete received byte
                //
                // We use mosi directly for the final bit
                // because rx_shift updates after this block
                // due to non-blocking assignment.
                rx_data <= {
                    rx_shift[6:0],
                    mosi
                };

                rx_valid <= 1'b1;

                bit_count <= 3'd0;

            end

            else begin

                bit_count <= bit_count + 1'b1;

            end

        end

    end


    // ------------------------------------------------
    // TRANSMIT LOGIC
    //
    // SPI Mode 0:
    // Change MISO on falling edge of SCLK
    // ------------------------------------------------
    always @(negedge sclk or posedge cs_n or negedge rst_n) begin

        if (!rst_n) begin

            miso <= 1'b0;

        end

        else if (cs_n) begin

            // Slave deselected
            miso <= 1'b0;

        end

        else begin

            // Shift transmit register
            tx_shift <= {
                tx_shift[6:0],
                1'b0
            };

            // Put next bit on MISO
            miso <= tx_shift[6];

        end

    end

endmodule