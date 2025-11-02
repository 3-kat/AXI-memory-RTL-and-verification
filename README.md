# AXI-memory-RTL-and-verification
Project on the verilog implementation of AXI lite Memory and its verification using Universal verification methodology in system verilog

# **AXI-Lite Slave (axilite\_s)**

## **Overview**

This repository contains a Verilog implementation of a **simple AXI-Lite Slave** (memory-mapped) interface. This module acts as a peripheral accessible from an AXI Master (like a processor core), providing read and write access to an internal register array.

The design utilizes a single Finite State Machine (FSM) to manage the transaction handshake sequences for both AXI write and AXI read operations, adhering strictly to the AXI-Lite protocol specifications (single data beat per transaction).

| Feature | Status |
| :---- | :---- |
| **AXI Standard** | AXI4-Lite |
| **Data Width** | 32-bit |
| **Memory Size** | 128 x 32-bit registers (512 Bytes) |
| **Clock Domain** | Single Clock (s\_axi\_aclk) |
| **Write Response** | OKAY (2'b00) for valid addresses, SLVERR (2'b11) for out-of-bounds addresses. |
| **Read Response** | OKAY (2'b00) for valid addresses, SLVERR (2'b11) for out-of-bounds addresses. |

## **Internal Memory Map**

The slave module incorporates a simple on-chip memory array for demonstration and functional testing.

| Address Range (32-bit offset) | Description |
| :---- | :---- |
| 0x00 to 0x7F | **Internal Register Array (128 Registers):** Read/Write accessible data. |
| 0x80 and above | **Invalid/Reserved:** Access results in an SLVERR response. |

The memory is initialized to zero upon a synchronous reset (s\_axi\_aresetn \= 0).

## **AXI-Lite Write Operation FSM**

The write transaction is managed by the FSM moving through the following states:

1. **idle**: Waiting for a valid AW address or AR address.  
2. **send\_waddr\_ack**: The master asserts AWVALID. The slave accepts the address by asserting S\_AXI\_AWREADY and captures s\_axi\_awaddr into the waddr register. Transitions to wait for write data.  
3. **send\_wdata\_ack**: The master asserts WVALID. The slave accepts the data by asserting S\_AXI\_WREADY and captures s\_axi\_wdata into the wdata register.  
4. **update\_mem**: The valid address/data pair is committed to the internal mem array.  
5. **send\_wr\_resp**: The slave asserts S\_AXI\_BVALID with an OKAY response (2'b00). Stays in this state until the master asserts BREADY.  
6. **send\_wr\_err**: If the address was invalid, the slave asserts S\_AXI\_BVALID with an SLVERR response (2'b11). Stays until BREADY is asserted.

## **AXI-Lite Read Operation FSM**

The read transaction follows a separate path in the FSM:

1. **idle**: Waiting for a valid AR address or AW address.  
2. **send\_raddr\_ack**: The master asserts ARVALID. The slave accepts the address by asserting S\_AXI\_ARREADY and captures s\_axi\_araddr into the raddr register.  
3. **gen\_data**: For valid addresses, the data is retrieved from mem\[raddr\] into the rdata register.  
   * *Note: There is a short two-cycle delay (count \< 2\) inserted in the gen\_data state before asserting RVALID, simulating latency typical in real hardware.*  
4. **send\_rdata**: The slave asserts S\_AXI\_RVALID with the data (s\_axi\_rdata) and an OKAY response (2'b00). Transitions back to idle upon receiving RREADY from the master.  
5. **send\_rd\_err**: If the address was invalid, the slave asserts S\_AXI\_RVALID with a zero payload and an SLVERR response (2'b11). Stays until RREADY is asserted.

## **Port Definitions**

The axilite\_s module exposes the standard AXI4-Lite signals:

| Port Name | Direction | Width | Description |
| :---- | :---- | :---- | :---- |
| s\_axi\_aclk | Input | 1 | System clock |
| s\_axi\_aresetn | Input | 1 | Active-low asynchronous reset |
| **Write Address Channel** |  |  |  |
| s\_axi\_awvalid | Input | 1 | Write address valid |
| s\_axi\_awready | Output | 1 | Write address ready |
| s\_axi\_awaddr | Input | 32 | Write address |
| **Write Data Channel** |  |  |  |
| s\_axi\_wvalid | Input | 1 | Write data valid |
| s\_axi\_wready | Output | 1 | Write data ready |
| s\_axi\_wdata | Input | 32 | Write data |
| **Write Response Channel** |  |  |  |
| s\_axi\_bvalid | Output | 1 | Write response valid |
| s\_axi\_bready | Input | 1 | Write response ready |
| s\_axi\_bresp | Output | 2 | Write response (OKAY/SLVERR) |
| **Read Address Channel** |  |  |  |
| s\_axi\_arvalid | Input | 1 | Read address valid |
| s\_axi\_arready | Output | 1 | Read address ready |
| s\_axi\_araddr | Input | 32 | Read address |
| **Read Data Channel** |  |  |  |
| s\_axi\_rvalid | Output | 1 | Read data valid |
| s\_axi\_rready | Input | 1 | Read data ready |
| s\_axi\_rdata | Output | 32 | Read data |
| s\_axi\_rresp | Output | 2 | Read response (OKAY/SLVERR) |


