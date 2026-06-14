#include <stdio.h>
#include <stdint.h>
#include "xil_io.h"

// Vitis 2025.2 compatibility: map the new SDT CPU clock parameter to the legacy BSP name
#ifndef XPAR_CPU_CORTEXA9_0_CPU_CLK_FREQ_HZ
  #ifdef XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ
    #define XPAR_CPU_CORTEXA9_0_CPU_CLK_FREQ_HZ XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ
  #else
    #define XPAR_CPU_CORTEXA9_0_CPU_CLK_FREQ_HZ 666666687U // Standard 666.67 MHz CPU Clock for Zybo Z7-10
  #endif
#endif

#include "xtime_l.h"


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

int main() {
    XTime tStart, tEnd;
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

    XTime_GetTime(&tStart);

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

    XTime_GetTime(&tEnd);

    printf("Edge-Detected Output Image Matrix (3x3):\n");
    for (r = 0; r < 3; r++) {
        printf("  [ ");
        for (c = 0; c < 3; c++) {
            printf("%3d ", output_image[r][c]);
        }
        printf("]\n");
    }
    printf("\n");

    XTime elapsed_ticks = tEnd - tStart;
    double elapsed_us = (double)elapsed_ticks / (COUNTS_PER_SECOND / 1000000.0);
    double cpu_cycles = (double)elapsed_ticks * 2.0;

    printf("====================================================\n");
    printf("Hardware Accelerator Performance Profile\n");
    printf("====================================================\n");
    printf("Global Timer Ticks   : %llu ticks\n", (unsigned long long)elapsed_ticks);
    printf("Estimated CPU Cycles : %.0f clock cycles\n", cpu_cycles);
    printf("Elapsed Execution    : %.3f microseconds\n", elapsed_us);
    printf("====================================================\n");

    return 0;
}
