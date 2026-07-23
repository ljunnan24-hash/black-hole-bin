use serde::Serialize;
use std::collections::HashSet;
use std::path::{Path, PathBuf};
use tauri::{AppHandle, WebviewWindow};

const MAX_DROP_ITEMS: usize = 128;

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct RecycleResult {
    count: usize,
}

fn path_key(path: &Path) -> String {
    let value = path.to_string_lossy().to_string();
    if cfg!(target_os = "windows") {
        value.to_lowercase()
    } else {
        value
    }
}

fn validate_paths(paths: Vec<String>) -> Result<Vec<PathBuf>, String> {
    if paths.is_empty() {
        return Err("No files were provided.".into());
    }
    if paths.len() > MAX_DROP_ITEMS {
        return Err(format!(
            "A single drop is limited to {MAX_DROP_ITEMS} items."
        ));
    }

    let mut seen = HashSet::new();
    let mut validated = Vec::with_capacity(paths.len());

    for raw_path in paths {
        if raw_path.trim().is_empty() {
            return Err("An empty file path was provided.".into());
        }

        let path = PathBuf::from(raw_path);
        if !path.is_absolute() {
            return Err("Only absolute file paths can be recycled.".into());
        }
        if path.parent().is_none() {
            return Err("A filesystem root cannot be recycled.".into());
        }
        if std::fs::symlink_metadata(&path).is_err() {
            return Err(format!("The item no longer exists: {}", path.display()));
        }

        if seen.insert(path_key(&path)) {
            validated.push(path);
        }
    }

    validated.sort_by_key(|path| path.components().count());
    let mut top_level_paths: Vec<PathBuf> = Vec::with_capacity(validated.len());
    for path in validated {
        if !top_level_paths
            .iter()
            .any(|parent| path != *parent && path.starts_with(parent))
        {
            top_level_paths.push(path);
        }
    }

    Ok(top_level_paths)
}

#[tauri::command]
async fn move_to_recycle_bin(paths: Vec<String>) -> Result<RecycleResult, String> {
    tauri::async_runtime::spawn_blocking(move || {
        let validated = validate_paths(paths)?;
        let count = validated.len();
        trash::delete_all(&validated)
            .map_err(|error| format!("Windows Recycle Bin operation failed: {error}"))?;
        Ok(RecycleResult { count })
    })
    .await
    .map_err(|error| format!("Recycle Bin worker stopped unexpectedly: {error}"))?
}

#[tauri::command]
fn set_always_on_top(window: WebviewWindow, enabled: bool) -> Result<(), String> {
    window
        .set_always_on_top(enabled)
        .map_err(|error| error.to_string())
}

#[tauri::command]
fn start_dragging(window: WebviewWindow) -> Result<(), String> {
    window.start_dragging().map_err(|error| error.to_string())
}

#[tauri::command]
fn close_app(app: AppHandle) {
    app.exit(0);
}

#[cfg(target_os = "windows")]
#[tauri::command]
fn open_recycle_bin() -> Result<(), String> {
    std::process::Command::new("explorer.exe")
        .arg("shell:RecycleBinFolder")
        .spawn()
        .map(|_| ())
        .map_err(|error| format!("Could not open the Recycle Bin: {error}"))
}

#[cfg(not(target_os = "windows"))]
#[tauri::command]
fn open_recycle_bin() -> Result<(), String> {
    Err("Opening the Recycle Bin is only supported on Windows.".into())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_window_state::Builder::default().build())
        .invoke_handler(tauri::generate_handler![
            move_to_recycle_bin,
            set_always_on_top,
            start_dragging,
            close_app,
            open_recycle_bin
        ])
        .run(tauri::generate_context!())
        .expect("error while running Black Hole Bin");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_empty_batches() {
        assert!(validate_paths(Vec::new()).is_err());
    }

    #[test]
    fn rejects_relative_paths() {
        let result = validate_paths(vec!["relative/file.txt".into()]);
        assert!(result.is_err());
    }

    #[test]
    fn rejects_batches_over_the_limit_before_touching_the_filesystem() {
        let paths = (0..=MAX_DROP_ITEMS)
            .map(|index| format!("relative-{index}"))
            .collect();
        let error = validate_paths(paths).expect_err("oversized batches must fail");
        assert!(error.contains("limited"));
    }

    #[test]
    fn rejects_missing_absolute_paths() {
        let missing = std::env::temp_dir().join(format!(
            "black-hole-bin-missing-{}-{}",
            std::process::id(),
            u128::from(
                std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .expect("clock should be after Unix epoch")
                    .subsec_nanos()
            )
        ));
        let result = validate_paths(vec![missing.to_string_lossy().into_owned()]);
        assert!(result.is_err());
    }

    #[test]
    fn deduplicates_the_same_existing_path() {
        let executable = std::env::current_exe().expect("test executable must exist");
        let raw = executable.to_string_lossy().into_owned();
        let result = validate_paths(vec![raw.clone(), raw]).expect("path should validate");
        assert_eq!(result.len(), 1);
    }

    #[test]
    fn removes_a_nested_path_when_its_existing_parent_is_present() {
        let manifest_directory = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let manifest = manifest_directory.join("Cargo.toml");
        let result = validate_paths(vec![
            manifest.to_string_lossy().into_owned(),
            manifest_directory.to_string_lossy().into_owned(),
        ])
        .expect("existing paths should validate");
        assert_eq!(result, vec![manifest_directory]);
    }

    #[test]
    fn rejects_filesystem_root() {
        let root = if cfg!(target_os = "windows") {
            r"C:\"
        } else {
            "/"
        };
        let result = validate_paths(vec![root.into()]);
        assert!(result.is_err());
    }
}
