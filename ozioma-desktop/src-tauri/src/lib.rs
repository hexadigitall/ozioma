pub mod gis;
pub mod printing;
pub mod keystore;
pub mod db;

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct SplitResult {
    pub success: bool,
    pub polygon_a_geojson: String,
    pub polygon_b_geojson: String,
    pub area_a_ha: f64,
    pub area_b_ha: f64,
}

#[tauri::command]
pub fn split_territory_polygon(
    polygon_geojson: String,
    split_line_geojson: String,
) -> Result<SplitResult, String> {
    gis::polygon_split::execute_polygon_split(&polygon_geojson, &split_line_geojson)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn generate_s13_pdf(
    territory_number: String,
    territory_name: String,
    congregation_name: String,
    output_path: String,
) -> Result<String, String> {
    printing::s13_spooler::render_s13_card_pdf(
        &territory_number,
        &territory_name,
        &congregation_name,
        &output_path,
    )
    .map_err(|e| e.to_string())
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_sql::Builder::default().build())
        .invoke_handler(tauri::generate_handler![
            split_territory_polygon,
            generate_s13_pdf,
        ])
        .run(tauri::generate_context!())
        .expect("error while running Ozioma Desktop Tauri application");
}
