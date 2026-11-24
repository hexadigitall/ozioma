export interface Territory {
  id: string;
  number: string;
  name: string;
  region: string;
  status: 'available' | 'assigned' | 'completed' | 'archived';
  assignedTo?: string | null;
  assignedDate?: string | null;
  dueDate?: string | null;
  lastCompletedDate?: string | null;
  monthsSinceWorked?: number;
  progress: number;
  totalAddresses: number;
  completedAddresses: number;
  returnVisitsCount: number;
  dncCount: number;
  boundaryGeojson?: string;
}

export interface Address {
  id: string;
  territoryId: string;
  streetAddress: string;
  unit?: string;
  status: 'unvisited' | 'not_at_home' | 'return_visit' | 'do_not_call';
  lat: number;
  lng: number;
  notes?: string;
}

export interface Publisher {
  id: string;
  displayName: string;
  role: 'publisher' | 'auxiliary_pioneer' | 'regular_pioneer' | 'servant' | 'elder';
  assignedTerritories: string[];
}

export interface PioneerPacing {
  publisherName: string;
  role: 'regular_pioneer' | 'auxiliary_pioneer';
  currentHours: number;
  monthlyGoal: number;
  requiredDailyPace: number; // hours/day remaining
  projectedHours: number;
  status: 'on_track' | 'ahead' | 'needs_attention';
}

export interface S8ReportSummary {
  serviceYear: string;
  totalCongregationTerritories: number;
  workedOnce: number;
  workedTwice: number;
  workedThreePlus: number;
  unworkedInServiceYear: number;
  coveragePercentage: number;
  averageCompletionDays: number;
  businessTerritoriesCount: number;
  foreignLanguageCount: number;
}
