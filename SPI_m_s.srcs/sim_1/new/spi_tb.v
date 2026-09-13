`timescale 1ns / 1ps

module spi_tb;

    // ------------------------------------------------
    // Testbench signals
    // ------------------------------------------------
    reg clk;
    reg rst_n;

    reg start;

    reg [7:0] master_tx;
    wire [7:0] master_rx;

    reg [7:0] slave_tx;
    wire [7:0] slave_rx;

    wire busy;
    wire done;

    wire slave_rx_valid;

    wire sclk;
    wire mosi;
    wire miso;
    wire cs_n;


    // ------------------------------------------------
    // Clock generation
    //
    // 100 MHz clock
    // Period = 10 ns
    // ------------------------------------------------
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ------------------------------------------------
    // SPI MASTER instance
    // ------------------------------------------------
    spi_master #(
        .CLK_DIV(4)
    ) uut_master (
        .clk(clk),
        .rst_n(rst_n),

        .start(start),
        .tx_data(master_tx),

        .rx_data(master_rx),
        .busy(busy),
        .done(done),

        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)
    );


    // ------------------------------------------------
    // SPI SLAVE instance
    // ------------------------------------------------
    spi_slave uut_slave (
        .rst_n(rst_n),

        .sclk(sclk),
        .cs_n(cs_n),

        .mosi(mosi),
        .miso(miso),

        .tx_data(slave_tx),

        .rx_data(slave_rx),
        .rx_valid(slave_rx_valid)
    );


    // ------------------------------------------------
    // Test sequence
    // ------------------------------------------------
    initial begin

        // Initial values
        rst_n     = 1'b0;
        start     = 1'b0;

        master_tx = 8'h00;
        slave_tx  = 8'h00;


        // Hold reset for some time
        #50;

        rst_n = 1'b1;

        #20;


        // ================================================
        // TEST 1
        //
        // Master sends A5
        // Slave sends 5A
        // ================================================

        master_tx = 8'hA5;
        slave_tx  = 8'h5A;


        // Generate start pulse
        @(posedge clk);

        start = 1'b1;

        @(posedge clk);

        start = 1'b0;


        // Wait until SPI master completes transfer
        wait(done == 1'b1);

        #10;


        // ------------------------------------------------
        // Display results
        // ------------------------------------------------

        $display("");
        $display("--------------------------------------");
        $display("SPI TEST 1 COMPLETE");
        $display("--------------------------------------");

        $display("Master transmitted = 0x%h", master_tx);
        $display("Master received    = 0x%h", master_rx);

        $display("Slave transmitted  = 0x%h", slave_tx);
        $display("Slave received     = 0x%h", slave_rx);

        $display("--------------------------------------");


        // ------------------------------------------------
        // Automatic checking
        // ------------------------------------------------

        if (master_rx == 8'h5A)
            $display("MASTER RX : PASS");
        else
            $display("MASTER RX : FAIL");


        if (slave_rx == 8'hA5)
            $display("SLAVE RX  : PASS");
        else
            $display("SLAVE RX  : FAIL");


        $display("--------------------------------------");


        #100;

        $finish;

    end


endmodule