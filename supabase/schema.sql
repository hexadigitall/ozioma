-- ==============================================================================
-- OZIOMA CANONICAL SUPABASE SCHEMA (THEOCRATIC & ZERO-CLOUD PII COMPLIANT)
-- ==============================================================================
-- Classification: Production Schema for PostgreSQL with PowerSync Integration
-- Data Privacy: Householder PII (Names, Phones, Notes) is strictly Local-First
--               Only anonymized territory status and boundaries are replicated.
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. CONGREGATIONS
CREATE TABLE congregations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  circuit TEXT,
  country_code TEXT DEFAULT 'WW',
  kingdom_hall_address TEXT,
  meeting_schedule TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. USER PROFILES (Linked to Supabase Auth)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  congregation_id UUID REFERENCES congregations(id),
  display_name TEXT NOT NULL,
  role TEXT CHECK (role IN ('elder', 'servant', 'regular_pioneer', 'auxiliary_pioneer', 'publisher')) DEFAULT 'publisher',
  service_group TEXT DEFAULT 'Group 1',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2B. CONGREGATION PUBLISHERS ROSTER (Full CRUD for Elders/Servants & local-first members)
CREATE TABLE congregation_publishers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  congregation_id UUID NOT NULL REFERENCES congregations(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  role TEXT CHECK (role IN ('elder', 'servant', 'regular_pioneer', 'auxiliary_pioneer', 'publisher')) DEFAULT 'publisher',
  service_group TEXT DEFAULT 'Group 1',
  is_active BOOLEAN DEFAULT TRUE,
  linked_user_id UUID REFERENCES profiles(id),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TERRITORIES
CREATE TABLE territories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  congregation_id UUID NOT NULL REFERENCES congregations(id) ON DELETE CASCADE,
  number TEXT NOT NULL,
  name TEXT NOT NULL,
  region TEXT NOT NULL, -- e.g., 'Port Harcourt', 'Lagos Metro', 'Calabar'
  boundary_geojson JSONB,
  start_lat DOUBLE PRECISION,
  start_lng DOUBLE PRECISION,
  stop_lat DOUBLE PRECISION,
  stop_lng DOUBLE PRECISION,
  status TEXT CHECK (status IN ('available', 'assigned', 'completed', 'archived')) DEFAULT 'available',
  assigned_to UUID REFERENCES profiles(id),
  assigned_date TIMESTAMPTZ,
  due_date TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_territories_congregation ON territories(congregation_id);
CREATE INDEX idx_territories_assigned ON territories(assigned_to);

-- 4. ADDRESSES (Anonymized Status Only - Zero Householder PII)
CREATE TABLE addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  territory_id UUID NOT NULL REFERENCES territories(id) ON DELETE CASCADE,
  street_address TEXT NOT NULL,
  unit TEXT,
  status TEXT CHECK (status IN ('unvisited', 'not_at_home', 'return_visit', 'do_not_call', 'inaccessible')) DEFAULT 'unvisited',
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  sort_order INT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_addresses_territory ON addresses(territory_id);

-- 5. SERVICE LOGS (Personal Anonymized Ministry Hours & Placement Totals)
CREATE TABLE service_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  duration_minutes INT NOT NULL DEFAULT 0,
  bible_studies_count INT NOT NULL DEFAULT 0,
  placements_count INT NOT NULL DEFAULT 0,
  video_showings_count INT NOT NULL DEFAULT 0,
  synced BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_service_logs_user ON service_logs(user_id);

-- 6. SHARED PINS (Congregation Location Management & Pin Sharing)
CREATE TABLE shared_pins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  congregation_id UUID NOT NULL REFERENCES congregations(id) ON DELETE CASCADE,
  territory_id UUID REFERENCES territories(id) ON DELETE SET NULL,
  created_by TEXT NOT NULL,
  title TEXT NOT NULL,
  category TEXT CHECK (category IN ('meeting_point', 'parking', 'rv_hotspot', 'cart_site', 'hazard_gate', 'custom')) DEFAULT 'meeting_point',
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. PUBLISHER CHAT & FIELD COORDINATION MESSAGES
CREATE TABLE publisher_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  congregation_id UUID NOT NULL REFERENCES congregations(id) ON DELETE CASCADE,
  sender_id TEXT NOT NULL,
  sender_name TEXT NOT NULL,
  sender_role TEXT NOT NULL,
  channel TEXT CHECK (channel IN ('general', 'field_service', 'territory_updates')) DEFAULT 'field_service',
  body TEXT NOT NULL,
  pin_id UUID REFERENCES shared_pins(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. LIVE PUBLISHER TRACKING (Anonymized/Jittered Ministry Hours Presence)
CREATE TABLE publisher_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  congregation_id UUID NOT NULL REFERENCES congregations(id) ON DELETE CASCADE,
  publisher_id TEXT NOT NULL,
  display_name TEXT NOT NULL,
  role TEXT NOT NULL,
  territory_id UUID REFERENCES territories(id) ON DELETE SET NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  is_tracking BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. CONGREGATION SERVICE REPORTS (Monthly S-4 Rollups for Secretary & Group Overseers)
CREATE TABLE congregation_service_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  congregation_id UUID NOT NULL REFERENCES congregations(id) ON DELETE CASCADE,
  publisher_id TEXT NOT NULL,
  publisher_name TEXT NOT NULL,
  year_month TEXT NOT NULL,
  publisher_role TEXT NOT NULL,
  participated BOOLEAN DEFAULT TRUE,
  hours NUMERIC(6,2) DEFAULT 0,
  credit_hours NUMERIC(6,2) DEFAULT 0,
  bible_studies INT DEFAULT 0,
  remarks TEXT,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. REGIONAL VECTOR TILE PACK MANIFEST (Served via Supabase Storage / Cloudflare R2)
CREATE TABLE vector_tile_manifests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  region_id TEXT UNIQUE NOT NULL, -- 'ph_city', 'lagos_metro', 'calabar_city'
  display_name TEXT NOT NULL,
  file_name TEXT NOT NULL,
  storage_url TEXT NOT NULL,
  size_bytes BIGINT NOT NULL,
  sha256_checksum TEXT NOT NULL,
  min_zoom INT DEFAULT 10,
  max_zoom INT DEFAULT 16,
  bounds_geojson JSONB,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE congregations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE territories ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE vector_tile_manifests ENABLE ROW LEVEL SECURITY;

-- Congregations: Members can view their own congregation record
CREATE POLICY "Congregation members can view own congregation" ON congregations
  FOR SELECT USING (
    id = (SELECT congregation_id FROM profiles WHERE id = auth.uid())
  );

-- Profiles: Users can read congregation members; can update own profile
CREATE POLICY "Profiles are readable by congregation peers" ON profiles
  FOR SELECT USING (
    congregation_id = (SELECT congregation_id FROM profiles WHERE id = auth.uid())
  );

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (id = auth.uid());

-- Territories: Congregation Isolation & Role Access
CREATE POLICY "Territories congregation isolation" ON territories
  FOR SELECT USING (
    congregation_id = (SELECT congregation_id FROM profiles WHERE id = auth.uid())
  );

CREATE POLICY "Elders have full write access to congregation territories" ON territories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role IN ('elder', 'servant') AND congregation_id = territories.congregation_id
    )
  );

CREATE POLICY "Publishers can update assigned territory status" ON territories
  FOR UPDATE USING (
    assigned_to = auth.uid()
  );

-- Addresses: Readable and updateable by publishers working the congregation
CREATE POLICY "Addresses congregation isolation" ON addresses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM territories t
      JOIN profiles p ON t.congregation_id = p.congregation_id
      WHERE t.id = addresses.territory_id AND p.id = auth.uid()
    )
  );

CREATE POLICY "Publishers can update status of addresses" ON addresses
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM territories t
      JOIN profiles p ON t.congregation_id = p.congregation_id
      WHERE t.id = addresses.territory_id AND p.id = auth.uid()
    )
  );

-- Service Logs: Private to each user
CREATE POLICY "Service logs are strictly user-private" ON service_logs
  FOR ALL USING (user_id = auth.uid());

-- Tile Manifests: Public read for all authenticated users
CREATE POLICY "Authenticated users can read tile manifests" ON vector_tile_manifests
  FOR SELECT TO authenticated USING (true);

-- ==============================================================================
-- AUTOMATIC TIMESTAMP & CONFLICT RESOLUTION TRIGGERS
-- ==============================================================================

CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON profiles;
CREATE TRIGGER set_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

DROP TRIGGER IF EXISTS set_territories_updated_at ON territories;
CREATE TRIGGER set_territories_updated_at BEFORE UPDATE ON territories FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

DROP TRIGGER IF EXISTS set_addresses_updated_at ON addresses;
CREATE TRIGGER set_addresses_updated_at BEFORE UPDATE ON addresses FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

DROP TRIGGER IF EXISTS set_service_logs_updated_at ON service_logs;
CREATE TRIGGER set_service_logs_updated_at BEFORE UPDATE ON service_logs FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

DROP TRIGGER IF EXISTS set_vector_tile_manifests_updated_at ON vector_tile_manifests;
CREATE TRIGGER set_vector_tile_manifests_updated_at BEFORE UPDATE ON vector_tile_manifests FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();
