// SPDX-License-Identifier: MIT
// C interface of macalla-brush-ffi (spikes/brush/macalla-brush-ffi/src/lib.rs).
#ifndef MACALLA_BRUSH_H
#define MACALLA_BRUSH_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum {
    MACALLA_BRUSH_OK = 0,
    MACALLA_BRUSH_BAD_ARGUMENT = 1,
    MACALLA_BRUSH_TRAINING_FAILED = 2,
    MACALLA_BRUSH_PANICKED = 3,
};

// Called once per training step: the step just finished, the total, and the
// mean iterations per second since training started.
typedef void (*MacallaBrushProgress)(uint32_t iter, uint32_t total,
                                     double iters_per_sec, void *user_data);

// Trains a COLMAP or Nerfstudio dataset (folder or zip) on Metal and writes
// the splat to out_ply. Blocks; call it off the main thread.
int32_t macalla_brush_train(const char *dataset_path, uint32_t iterations,
                            const char *out_ply, MacallaBrushProgress progress,
                            void *user_data);

#ifdef __cplusplus
}
#endif

#endif
