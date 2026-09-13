SPI Controller

<img width="227" height="143" alt="image" src="https://github.com/user-attachments/assets/132856e6-9aa8-413a-acc9-722fc10902d8" />
<img width="533" height="353" alt="image" src="https://github.com/user-attachments/assets/0c6a4c60-7d55-41a7-9df8-7ca087221d4d" />


RTL implementation of an SPI Master and Slave in Verilog, developed and verified using AMD Vivado.

The current design implements SPI Mode 0 (CPOL = 0, CPHA = 0) with 8-bit, MSB-first, full-duplex communication. The project will later be extended to support all four SPI modes and an AMBA AHB-Lite interface.

Current Features
SPI Master and Slave
SPI Mode 0 (CPOL = 0, CPHA = 0)
8-bit data transfer
MSB-first transmission
Full-duplex communication
Active-low Chip Select (CS_N)
Configurable SPI clock divider
TX/RX shift registers
busy, done, and rx_valid status signals
Verilog testbench
Vivado XSim behavioral verification
Architecture
                     SPI MASTER
              +----------------------+
              | Control FSM          |
              | Clock Divider        |
TX Data ----->| TX Shift Register    |-----> MOSI
RX Data <-----| RX Shift Register    |<----- MISO
              | Bit Counter          |
              +----------+-----------+
                         |
                    SCLK / CS_N
                         |
                         v
              +----------------------+
              |      SPI SLAVE       |
              |                      |
              | TX Shift Register    |
              | RX Shift Register    |
              | Bit Counter          |
              +----------------------+
