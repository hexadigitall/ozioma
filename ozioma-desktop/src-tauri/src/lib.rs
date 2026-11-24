pub mod gis;
pub mod printing;
pub mod keystore;
pub mod db;
pub mod importer;

pub use gis::polygon_split::{SplitResult, TerritoryMetrics};
pub use importer::{ImportSummary, ExportTerritory};

#[tauri::command]
pub fn split_territory_polygon(
    polygon_geojson: String,
    split_line_geojson: String,
) -> Result<SplitResult, String> {
    gis::polygon_split::execute_polygon_split(&polygon_geojson, &split_line_geojson)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn calculate_territory_metrics(
    polygon_geojson: String,
) -> Result<TerritoryMetrics, String> {
    gis::polygon_split::calculate_metrics(&polygon_geojson)
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

#[tauri::command]
pub fn import_master_street_csv(
    csv_content: String,
) -> Result<ImportSummary, String> {
    importer::parse_master_street_csv(&csv_content)
}

#[tauri::command]
pub fn export_congregation_kml(
    congregation_name: String,
    territories: Vec<ExportTerritory>,
) -> Result<String, String> {
    Ok(importer::generate_kml_export(&congregation_name, &territories))
}

#[tauri::command]
pub fn export_congregation_geojson(
    territories: Vec<ExportTerritory>,
) -> Result<String, String> {
    Ok(importer::generate_geojson_export(&territories))
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_sql::Builder::default().build())
        .invoke_handler(tauri::generate_handler![
            split_territory_polygon,
            calculate_territory_metrics,
            generate_s13_pdf,
            import_master_street_csv,
            export_congregation_kml,
            export_congregation_geojson,
        ])
        .run(tauri::generate_context!())
        .expect("error while running Ozioma Desktop Tauri application");
}
