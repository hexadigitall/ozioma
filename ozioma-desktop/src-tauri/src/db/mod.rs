use rusqlite::{Connection, Result};

pub fn init_local_congregation_db(path: &str) -> Result<Connection> {
    let conn = Connection::open(path)?;
    conn.execute(
        "CREATE TABLE IF NOT EXISTS local_territories_cache (
            id TEXT PRIMARY KEY,
            number TEXT NOT NULL,
            name TEXT NOT NULL,
            geojson TEXT,
            status TEXT NOT NULL,
            assigned_to TEXT,
            updated_at TEXT NOT NULL
        )",
        [],
    )?;
    Ok(conn)
}
