// SPDX-License-Identifier: MIT
//! `macalla_brush_train`: train a Gaussian splat with Brush on Metal and
//! write one .ply. Blocking; call it off the main thread.

use std::ffi::{CStr, c_char, c_void};
use std::path::Path;

use brush_process::config::TrainStreamConfig;
use brush_process::message::{ProcessMessage, TrainMessage};
use brush_process::{DataSource, create_process_with_device, default_device};
use burn_wgpu::graphics::Metal;
use burn_wgpu::{MemoryConfiguration, RuntimeOptions, WgpuDevice};
use tokio_stream::StreamExt;

/// Return codes. Kept as plain integers so the C header stays trivial.
pub const MACALLA_BRUSH_OK: i32 = 0;
pub const MACALLA_BRUSH_BAD_ARGUMENT: i32 = 1;
pub const MACALLA_BRUSH_TRAINING_FAILED: i32 = 2;
pub const MACALLA_BRUSH_PANICKED: i32 = 3;

/// Called once per training step with the step just finished, the total, and
/// the mean iterations per second since training started.
pub type MacallaBrushProgress =
    extern "C" fn(iter: u32, total: u32, iters_per_sec: f64, user_data: *mut c_void);

static METAL_READY: tokio::sync::OnceCell<()> = tokio::sync::OnceCell::const_new();

fn c_str(ptr: *const c_char) -> Option<String> {
    if ptr.is_null() {
        return None;
    }
    // SAFETY: non-null, and the caller guarantees a valid NUL-terminated string.
    Some(unsafe { CStr::from_ptr(ptr) }.to_string_lossy().into_owned())
}

/// Trains `dataset_path` (a COLMAP or Nerfstudio dataset folder or zip) for
/// `iterations` steps and writes the result to `out_ply`.
///
/// # Safety
/// `dataset_path` and `out_ply` must be valid NUL-terminated strings for the
/// duration of the call. `user_data` is passed through to `progress` untouched.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn macalla_brush_train(
    dataset_path: *const c_char,
    iterations: u32,
    out_ply: *const c_char,
    progress: Option<MacallaBrushProgress>,
    user_data: *mut c_void,
) -> i32 {
    let (Some(dataset), Some(out_ply)) = (c_str(dataset_path), c_str(out_ply)) else {
        return MACALLA_BRUSH_BAD_ARGUMENT;
    };
    let out = Path::new(&out_ply);
    let (Some(out_dir), Some(out_name)) = (out.parent(), out.file_name()) else {
        return MACALLA_BRUSH_BAD_ARGUMENT;
    };
    if iterations == 0 {
        return MACALLA_BRUSH_BAD_ARGUMENT;
    }

    let mut config = TrainStreamConfig::default();
    config.train_config.total_train_iters = iterations;
    config.process_config.export_every = iterations;
    config.process_config.eval_every = iterations;
    config.process_config.export_path = out_dir.to_string_lossy().into_owned();
    config.process_config.export_name = out_name.to_string_lossy().into_owned();

    // A panic must not unwind across `extern "C"`.
    let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
        tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .expect("tokio runtime")
            .block_on(async move {
                METAL_READY
                    .get_or_init(|| async {
                        let options = RuntimeOptions {
                            tasks_max: 64,
                            memory_config: MemoryConfiguration::ExclusivePages,
                        };
                        burn_wgpu::init_setup_async::<Metal>(&WgpuDevice::default(), options)
                            .await;
                    })
                    .await;

                let mut process = create_process_with_device(
                    DataSource::Path(dataset),
                    default_device(),
                    async move |_| Some(config),
                );
                while let Some(message) = process.stream.next().await {
                    match message {
                        Ok(ProcessMessage::TrainMessage(TrainMessage::TrainStep {
                            iter,
                            total_elapsed,
                            ..
                        })) => {
                            if let Some(progress) = progress {
                                let secs = total_elapsed.as_secs_f64();
                                let rate = if secs > 0.0 { f64::from(iter) / secs } else { 0.0 };
                                progress(iter, iterations, rate, user_data);
                            }
                        }
                        Ok(_) => {}
                        Err(_) => return MACALLA_BRUSH_TRAINING_FAILED,
                    }
                }
                MACALLA_BRUSH_OK
            })
    }));
    result.unwrap_or(MACALLA_BRUSH_PANICKED)
}
