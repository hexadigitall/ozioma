use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MasterStreetRecord {
    pub territory_number: String,
    pub street_name: String,
    pub start_number: u32,
    pub end_number: u32,
    pub address_type: String, // 'residential', 'commercial', 'apartments'
    pub locality: String,
    pub estimated_doors: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExportTerritory {
    pub number: String,
    pub name: String,
    pub region: String,
    pub coordinates: Vec<[f64; 2]>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ImportSummary {
    pub success: bool,
    pub total_records: usize,
    pub total_doors_estimated: u32,
    pub territory_count: usize,
    pub sample_records: Vec<MasterStreetRecord>,
}

/// High-speed streaming CSV parser for congregation master street lists
pub fn parse_master_street_csv(csv_content: &str) -> Result<ImportSummary, String> {
    let mut records = Vec::new();
    let mut territories_seen = std::collections::HashSet::new();
    let mut total_doors = 0;

    for (line_idx, line) in csv_content.lines().enumerate() {
        let trimmed = line.trim();
        if trimmed.is_empty() || line_idx == 0 && trimmed.to_lowercase().contains("territory") {
            continue; // Skip header and blank lines
        }

        let parts: Vec<&str> = trimmed.split(',').map(|s| s.trim()).collect();
        if parts.len() < 4 {
            continue;
        }

        let territory_number = parts[0].to_string();
        let street_name = parts[1].to_string();
        let start_num: u32 = parts[2].parse().unwrap_or(1);
        let end_num: u32 = parts[3].parse().unwrap_or(10);
        let address_type = if parts.len() > 4 { parts[4].to_string() } else { "residential".to_string() };
        let locality = if parts.len() > 5 { parts[5].to_string() } else { "Port Harcourt".to_string() };

        let doors = if end_num >= start_num { (end_num - start_num) + 1 } else { 1 };
        total_doors += doors;
        territories_seen.insert(territory_number.clone());

        records.push(MasterStreetRecord {
            territory_number,
            street_name,
            start_number: start_num,
            end_number: end_num,
            address_type,
            locality,
            estimated_doors: doors,
        });
    }

    let territory_count = territories_seen.len();
    let sample = records.iter().take(5).cloned().collect();

    Ok(ImportSummary {
        success: true,
        total_records: records.len(),
        total_doors_estimated: total_doors,
        territory_count,
        sample_records: sample,
    })
}

/// Generates standard OGC KML document for Circuit Overseer and Branch Office field reporting
pub fn generate_kml_export(congregation_name: &str, territories: &[ExportTerritory]) -> String {
    let mut kml = String::new();
    kml.push_str("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    kml.push_str("<kml xmlns=\"http://www.opengis.net/kml/2.2\">\n");
    kml.push_str("  <Document>\n");
    kml.push_str(&format!("    <name>{} — Congregation Territories</name>\n", congregation_name));
    kml.push_str("    <description>Official Worldwide Congregation Field Boundaries</description>\n");

    for t in territories {
        kml.push_str("    <Placemark>\n");
        kml.push_str(&format!("      <name>Territory {} - {}</name>\n", t.number, t.name));
        kml.push_str(&format!("      <description>Locality: {}</description>\n", t.region));
        kml.push_str("      <Polygon>\n");
        kml.push_str("        <outerBoundaryIs>\n");
        kml.push_str("          <LinearRing>\n");
        kml.push_str("            <coordinates>\n");

        for coord in &t.coordinates {
            kml.push_str(&format!("              {},{},0\n", coord[0], coord[1]));
        }

        kml.push_str("            </coordinates>\n");
        kml.push_str("          </LinearRing>\n");
        kml.push_str("        </outerBoundaryIs>\n");
        kml.push_str("      </Polygon>\n");
        kml.push_str("    </Placemark>\n");
    }

    kml.push_str("  </Document>\n");
    kml.push_str("</kml>\n");
    kml
}

/// Generates standard RFC 7946 GeoJSON FeatureCollection
pub fn generate_geojson_export(territories: &[ExportTerritory]) -> String {
    let features: Vec<serde_json::Value> = territories
        .iter()
        .map(|t| {
            serde_json::json!({
                "type": "Feature",
                "properties": {
                    "number": t.number,
                    "name": t.name,
                    "region": t.region
                },
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [t.coordinates]
                }
            })
        })
        .collect();

    serde_json::to_string_pretty(&serde_json::json!({
        "type": "FeatureCollection",
        "features": features
    }))
    .unwrap_or_else(|_| "{}".to_string())
}
