# Zynq-7000 Sobel Edge Detection Hardware Accelerator

A high-performance, real-time edge vision hardware accelerator implemented on an AMD/Xilinx Zynq-7000 SoC (`xc7z010clg400-1`). This project utilizes a hardware-software co-design paradigm, combining a custom 4-stage pipelined Sobel filter core implemented in the Programmable Logic (PL) with a bare-metal control driver executed on the dual-core ARM Cortex-A9 Processing System (PS).

---

## 🚀 Key Features

* **4-Stage Pipelined RTL Core (`spatial_filter_core.v`):** Highly optimized HDL implementing row difference calculations, gradient summation, absolute value calculations, and thresholding across distinct clock cycles to minimize the critical path.
* **AXI4-Lite register mapping (`sobel_axi_wrapper.v`):** Connects the PL accelerator core to the PS general-purpose AXI interconnect.
* **Pixel Row Packing Strategy:** Software driver packs three adjacent 8-bit grayscale pixels into single 32-bit registers using bit-shifting, reducing bus write transactions from 9 to 3 per matrix operation.
* **Bus Latency Masking:** The AXI bus write/read transaction delays naturally overlap with the 4-stage PL pipeline depth, allowing wait-free registers access without CPU `nop` delay states.
* **Dual Benchmarking Methodologies:** Supports high-precision execution timing profiling using the ARM Performance Monitor Unit (PMU) cycle counter (`CCNT`) and the Zynq Global Timer.

---

## 📂 Repository Structure

```
├── README.md                          # Project Documentation
├── Project_Report.docx                # Complete Academic Project Report (Word)
├── pipeline_block_diagram.png         # Hardware pipeline diagram
├── top_schematic.png                  # Top-level I/O boundary schematic
├── Block Design.png                   # Vivado block design schematic
├── Address Editor.png                 # Memory-mapped peripheral addresses
├── Utilization.png                    # FPGA resource utilization report
├── Timing.png                         # Timing closure and slack reports
├── Vitis - Serial Monitor.png         # Hardware validation serial console log
│
├── Prj_final/                         # Vivado Hardware Design Directory
│   ├── Prj_final.xpr                  # Vivado Project File
│   └── Prj_final.srcs/                # Source Code Directories
│       ├── sources_1/new/             # RTL Source Files
│       │   ├── spatial_filter_core.v  # Sobel Filter Core RTL
│       │   └── sobel_axi_wrapper.v    # AXI4-Lite Wrapper IP
│       └── sim_1/new/                 # Testbench Source Files
│           └── tb_spatial_filter.v    # Behavioral Testbench
│
└── app_component/                     # Vitis Software Driver Directory
    └── main.c                         # Bare-Metal C Application Driver
```

---

## 🛠️ Hardware Architecture (RTL)

The Sobel edge detection filter is broken down into a 4-stage synchronous pipeline:

```
                  +----------------------------------+
                  |  Inputs: p00-p22 (8-bit Unsigned)|
                  +-----------------+----------------+
                                    |
+-----------------------------------v-----------------------------------+
| STAGE 1: Row Difference Calculation (diff_x0_r1 to diff_y2_r1)        |
| - Expands 8-bit unsigned to 11-bit signed values.                     |
| - Computes directional pixel differences (e.g., p02 - p00).          |
+-----------------------------------+-----------------------------------+
                                    | Registered
+-----------------------------------v-----------------------------------+
| STAGE 2: Gradient Summation (Gx_r2, Gy_r2)                           |
| - Sums Stage 1 differences.                                           |
| - Multiplies center terms by 2 using arithmetic shifts (<<< 1).      |
+-----------------------------------+-----------------------------------+
                                    | Registered
+-----------------------------------v-----------------------------------+
| STAGE 3: Absolute Value Calculation (abs_Gx_r3, abs_Gy_r3)            |
| - Resolves sign of gradients using two's complement negation.         |
+-----------------------------------+-----------------------------------+
                                    | Registered
+-----------------------------------v-----------------------------------+
| STAGE 4: Magnitude Addition & Thresholding (out_pixel)                |
| - Adds absolute gradients and compares to 128 to output 0x00 or 0xFF. |
+-----------------------------------------------------------------------+
```

### Resource Utilization Summary
Post-routing implementation results indicate extremely low hardware overhead:
* **Look-Up Tables (LUTs):** 395 consumed (2.24% of the 17,600 available)
* **Registers (Flip-Flops):** 568 consumed (1.61% of the 35,200 available)
* **DSPs & Block RAM (BRAM):** 0% utilization (multiplication by 2 is wired via logic shifting; window buffering is handled across fabric registers).

### Timing & Performance Analysis
* **Clock Frequency:** 100 MHz (10.0 ns Period)
* **Worst Negative Slack (WNS):** +4.217 ns
* **Theoretical Fmax:** 172.9 MHz
* **Total Power:** 1.523 W (dominated by the ARM PS, with the PL logic consuming only 6 mW).

---

## 💻 Software Driver & Benchmarking

The bare-metal C application driver runs on the ARM Cortex-A9 processor. To minimize bus transactions, the driver packs adjacent 8-bit pixel values into a 32-bit register prior to writing:

```c
uint32_t packed_row0 = ((uint32_t)input_image[r-1][c+1] << 16) |
                       ((uint32_t)input_image[r-1][c]   << 8)  |
                        (uint32_t)input_image[r-1][c-1];
```

The execution time is profiled using high-precision assembly-level cycle counters accessing the ARM Coprocessor CP15:
$$\text{Time (us)} = \frac{\text{CCNT Cycles}}{666.67\text{ MHz}}$$

---

## 🔨 Build & Build Configuration Instructions

### Prerequisites
* AMD/Xilinx Vivado Design Suite v2025.2 (or compatible version)
* AMD/Xilinx Vitis Unified IDE v2025.2

### Step 1: Rebuilding Hardware (Vivado)
1. Launch **Vivado** and open the project `Prj_final/Prj_final.xpr`.
2. Open the Block Design: **IP Integrator > Open Block Design** (`system_bd.bd`).
3. Run synthesis, implementation, and verify timing closure.
4. Export the hardware design: **File > Export > Export Hardware**, choose **Include bitstream**, and save the `.xsa` file.

### Step 2: Running Software (Vitis)
1. Launch **Vitis Unified IDE** and open the workspace folder.
2. Import/rebuild the Platform project using your exported `.xsa` file.
3. Import the `app_component` code.
4. Build the application and run/debug bare-metal on the Zynq-7000 target board.

---

## 🚦 Simulation & Verification

A behavioral testbench (`tb_spatial_filter.v`) is provided in the project directories to validate RTL functional correctness before compilation. The testbench simulates clock generation, resets, and checks cases (uniform region, vertical edge, horizontal edge, weak edge) by waiting 4 clock cycles for pipeline propagation:

To run behavioral simulation:
1. In Vivado, click **Run Simulation > Run Behavioral Simulation**.
2. Run simulation and inspect the wave windows and display console logs.

---

## 📄 License & Student Info

* **Student Author:** Adithyan B
* **Institution:** Saintgits College of Engineering, Kottayam
* **Department:** Department of Electronics Engineering
* **Program:** Short-Term Training Program on ASIC & FPGA SoC Design (CUSAT)
