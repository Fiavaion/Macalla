// SPDX-License-Identifier: MIT
//! iOS stand-in for `rfd`. Brush's training path never shows a file dialog,
//! so each dialog resolves to `None` (the "user cancelled" result).

use std::path::{Path, PathBuf};

pub struct FileHandle(PathBuf);

impl FileHandle {
    pub fn file_name(&self) -> String {
        self.0
            .file_name()
            .map(|n| n.to_string_lossy().into_owned())
            .unwrap_or_default()
    }

    pub fn path(&self) -> &Path {
        &self.0
    }
}

#[derive(Default)]
pub struct AsyncFileDialog;

impl AsyncFileDialog {
    pub fn new() -> Self {
        Self
    }

    pub fn set_file_name(self, _name: impl Into<String>) -> Self {
        self
    }

    pub async fn pick_file(self) -> Option<FileHandle> {
        None
    }

    pub async fn pick_folder(self) -> Option<FileHandle> {
        None
    }

    pub async fn save_file(self) -> Option<FileHandle> {
        None
    }
}
