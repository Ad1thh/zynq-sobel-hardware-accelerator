#include <stdio.h>
#include <stdint.h>
#include "xil_io.h"

#include "xil_io.h"

#define SOBEL_BASEADDR 0x43C00000

#define SOBEL_REG0_OFFSET 0x0
#define SOBEL_REG1_OFFSET 0x4
#define SOBEL_REG2_OFFSET 0x8
#define SOBEL_REG3_OFFSET 0xC

static const uint8_t input_image[5][5] = {
    {10, 10, 240, 240, 240},
    {10, 10, 240, 240, 240},
    {10, 10, 240, 240, 240},
    {10, 10, 240, 240, 240},
    {10, 10, 240, 240, 240}
};

static uint8_t output_image[3][3];

// Helper functions to control ARM Cortex-A9 Performance Monitor Unit (PMU) Cycle Counter
static inline void init_ccnt() {
    #ifdef __arm__
        // Enable PMU and reset cycle counter
        asm volatile ("mcr p15, 0, %0, c9, c12, 0" :: "r"(0x17)); 
        // Enable CCNT (bit 31)
        asm volatile ("mcr p15, 0, %0, c9, c12, 1" :: "r"(0x80000000));
    #endif
}

static inline uint32_t read_ccnt() {
    uint32_t cc = 0;
    #ifdef __arm__
        asm volatile ("mrc p15, 0, %0, c9, c13, 0" : "=r"(cc));
    #endif
    return cc;
}

int main() {
    uint32_t tStart, tEnd;
    int r, c;

    printf("====================================================\n");
    printf("Zynq-7000 Real-Time Edge Vision Convolution Driver  \n");
    printf("Hardware/Software Co-Design - Sobel Accelerator Core\n");
    printf("====================================================\n\n");

    printf("Input Grayscale Image Matrix (5x5):\n");
    for (r = 0; r < 5; r++) {
        printf("  [ ");
        for (c = 0; c < 5; c++) {
            printf("%3d ", input_image[r][c]);
        }
        printf("]\n");
    }
    printf("\n");

    // Initialize the CPU performance counters
    init_ccnt();
    
    // Read start cycles
    tStart = read_ccnt();

    for (r = 1; r <= 3; r++) {
        for (c = 1; c <= 3; c++) {
            uint32_t packed_row0 = ((uint32_t)input_image[r-1][c+1] << 16) |
                                   ((uint32_t)input_image[r-1][c]   << 8)  |
                                    (uint32_t)input_image[r-1][c-1];

            uint32_t packed_row1 = ((uint32_t)input_image[r][c+1]   << 16) |
                                   ((uint32_t)input_image[r][c]     << 8)  |
                                    (uint32_t)input_image[r][c-1];

            uint32_t packed_row2 = ((uint32_t)input_image[r+1][c+1] << 16) |
                                   ((uint32_t)input_image[r+1][c]   << 8)  |
                                    (uint32_t)input_image[r+1][c-1];

            Xil_Out32(SOBEL_BASEADDR + SOBEL_REG0_OFFSET, packed_row0);
            Xil_Out32(SOBEL_BASEADDR + SOBEL_REG1_OFFSET, packed_row1);
            Xil_Out32(SOBEL_BASEADDR + SOBEL_REG2_OFFSET, packed_row2);

            uint32_t result = Xil_In32(SOBEL_BASEADDR + SOBEL_REG3_OFFSET);
            output_image[r-1][c-1] = (uint8_t)(result & 0xFF);
        }
    }

    // Read end cycles
    tEnd = read_ccnt();

    printf("Edge-Detected Output Image Matrix (3x3):\n");
    for (r = 0; r < 3; r++) {
        printf("  [ ");
        for (c = 0; c < 3; c++) {
            printf("%3d ", output_image[r][c]);
        }
        printf("]\n");
    }
    printf("\n");

    uint32_t elapsed_cycles = tEnd - tStart;
    
    // CPU runs at 666.67 MHz (1 cycle = 1.5 ns) on Zybo Z7-10
    double elapsed_us = (double)elapsed_cycles / 666.666687;

    printf("====================================================\n");
    printf("Hardware Accelerator Performance Profile\n");
    printf("====================================================\n");
    printf("ARM CPU Clock Cycles : %u cycles\n", elapsed_cycles);
    printf("Elapsed Execution    : %.3f microseconds\n", elapsed_us);
    printf("====================================================\n");

    return 0;
}
