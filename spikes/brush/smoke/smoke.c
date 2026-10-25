// SPDX-License-Identifier: MIT
// Command-line smoke test for MacallaBrush: trains a dataset and prints
// iterations per second. Runs in the simulator via `xcrun simctl spawn`.
#include <stdio.h>
#include <stdlib.h>
#include "macalla_brush.h"

static void on_progress(uint32_t iter, uint32_t total, double rate, void *user_data) {
    (void)user_data;
    if (iter % 100 == 0 || iter == total) {
        printf("iter %u/%u  %.1f it/s\n", iter, total, rate);
        fflush(stdout);
    }
}

int main(int argc, char **argv) {
    if (argc < 4) {
        fprintf(stderr, "usage: %s DATASET ITERATIONS OUT_PLY\n", argv[0]);
        return 2;
    }
    int32_t rc = macalla_brush_train(argv[1], (uint32_t)atoi(argv[2]), argv[3], on_progress, NULL);
    printf("exit code %d\n", rc);
    return rc;
}
