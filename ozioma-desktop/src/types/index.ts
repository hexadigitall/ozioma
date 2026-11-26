export type TheocraticRole =
  | 'publisher'
  | 'auxiliary_pioneer'
  | 'regular_pioneer'
  | 'servant'
  | 'elder';

export interface CongregationProfile {
  id: string;
  name: string;
  circuit: string;
  countryCode: string;
  kingdomHallAddress: string;
  meetingSchedule: string;
}

export interface Territory {
  id: string;
  congregationId?: string;
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
  isElderlyFriendly?: boolean;
  isSeldomWorked?: boolean;
  specialNeedsFlag?: boolean;
  accessibilityNotes?: string;
}

export interface CongregationInitiative {
  id: string;
  category: 'elderly_care' | 'special_needs' | 'seldom_worked' | 'need_greater';
  title: string;
  coordinator: string;
  targetArea: string;
  scheduleDate: string;
  status: 'planned' | 'active' | 'completed';
  notes: string;
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
  congregationId: string;
  displayName: string;
  role: TheocraticRole;
  serviceGroup: string;
  isActive: boolean;
  assignedTerritories: string[];
}

export interface SharedPin {
  id: string;
  congregationId: string;
  territoryId?: string;
  createdBy: string;
  title: string;
  category: 'meeting_point' | 'parking' | 'rv_hotspot' | 'cart_site' | 'hazard_gate' | 'custom';
  lat: number;
  lng: number;
  notes: string;
  updatedAt: string;
}

export interface PublisherMessage {
  id: string;
  congregationId: string;
  senderId: string;
  senderName: string;
  senderRole: TheocraticRole;
  channel: 'general' | 'field_service' | 'territory_updates';
  body: string;
  pinId?: string;
  createdAt: string;
}

export interface PublisherLocation {
  id: string;
  congregationId: string;
  publisherId: string;
  displayName: string;
  role: TheocraticRole;
  territoryId?: string;
  lat: number;
  lng: number;
  isTracking: boolean;
  updatedAt: string;
}

export interface ServiceReportEntry {
  id: string;
  congregationId: string;
  publisherId: string;
  publisherName: string;
  yearMonth: string;
  publisherRole: TheocraticRole;
  participated: boolean;
  hours: number;
  creditHours: number;
  bibleStudies: number;
  remarks: string;
  submittedAt: string;
}

export interface PioneerPacing {
  publisherName: string;
  role: 'regular_pioneer' | 'auxiliary_pioneer';
  currentHours: number;
  monthlyGoal: number;
  requiredDailyPace: number;
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
