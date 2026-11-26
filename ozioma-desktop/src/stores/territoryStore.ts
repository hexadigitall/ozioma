import { create } from 'zustand';
import {
  Territory,
  Address,
  CongregationInitiative,
  CongregationProfile,
  Publisher,
  TheocraticRole,
  SharedPin,
  PublisherMessage,
  PublisherLocation,
  ServiceReportEntry,
} from '../types';

interface TerritoryStore {
  congregations: CongregationProfile[];
  activeCongregationId: string;
  publishers: Publisher[];
  activePublisherId: string;
  territories: Territory[];
  initiatives: CongregationInitiative[];
  sharedPins: SharedPin[];
  messages: PublisherMessage[];
  publisherLocations: PublisherLocation[];
  serviceReports: ServiceReportEntry[];
  selectedTerritoryId: string | null;
  selectedTerritory: Territory | null;
  addresses: Address[];
  filterStatus: string;
  searchQuery: string;
  isS13ModalOpen: boolean;
  isAnalyticsModalOpen: boolean;
  showHeatmap: boolean;
  activeTool: 'select' | 'draw_poly' | 'split' | 'snap';

  // Congregation CRUD
  addCongregation: (c: Omit<CongregationProfile, 'id'>) => void;
  updateCongregation: (id: string, patch: Partial<CongregationProfile>) => void;
  deleteCongregation: (id: string) => void;
  setActiveCongregation: (id: string) => void;

  // Publisher & Role CRUD
  addPublisher: (p: Omit<Publisher, 'id'>) => void;
  updatePublisher: (id: string, patch: Partial<Publisher>) => void;
  assignPublisherRole: (id: string, role: TheocraticRole) => void;
  deletePublisher: (id: string) => void;
  setActivePublisher: (id: string) => void;

  // Territory & Address CRUD
  setTerritories: (territories: Territory[]) => void;
  selectTerritory: (id: string | null) => void;
  addTerritory: (territory: Omit<Territory, 'id'>) => void;
  updateTerritory: (id: string, patch: Partial<Territory>) => void;
  deleteTerritory: (id: string) => void;
  splitSelectedTerritory: (id: string) => void;

  // Initiatives CRUD
  addInitiative: (item: Omit<CongregationInitiative, 'id'>) => void;
  updateInitiative: (id: string, patch: Partial<CongregationInitiative>) => void;
  deleteInitiative: (id: string) => void;

  // Shared Pins, Chat & Live Tracking CRUD
  addSharedPin: (pin: Omit<SharedPin, 'id' | 'updatedAt'>) => string;
  updateSharedPin: (id: string, patch: Partial<SharedPin>) => void;
  deleteSharedPin: (id: string) => void;
  sendMessage: (msg: Omit<PublisherMessage, 'id' | 'createdAt'>) => void;
  updateMessage: (id: string, body: string) => void;
  deleteMessage: (id: string) => void;
  togglePublisherTracking: (publisherId: string, lat?: number, lng?: number) => void;

  // Congregation Field Service S-4 Reporting CRUD
  upsertServiceReport: (entry: Omit<ServiceReportEntry, 'id' | 'submittedAt'>) => void;
  deleteServiceReport: (id: string) => void;

  // Reset / Purge Demo Duds
  clearAllDemoRecords: () => void;

  // UI Filters & Tools
  setFilterStatus: (status: string) => void;
  setSearchQuery: (query: string) => void;
  setIsS13ModalOpen: (open: boolean) => void;
  setIsAnalyticsModalOpen: (open: boolean) => void;
  setShowHeatmap: (show: boolean) => void;
  setActiveTool: (tool: 'select' | 'draw_poly' | 'split' | 'snap') => void;
}

export const useTerritoryStore = create<TerritoryStore>((set, get) => ({
  congregations: [
    {
      id: 'cong-default',
      name: 'Central Kingdom Congregation',
      circuit: 'Circuit 01',
      countryCode: 'WW',
      kingdomHallAddress: 'Kingdom Hall Main Campus',
      meetingSchedule: 'Thu 6:30 PM • Sun 9:30 AM',
    },
  ],
  activeCongregationId: 'cong-default',
  publishers: [
    {
      id: 'pub-elder-1',
      congregationId: 'cong-default',
      displayName: 'Bro. Samuel Ade',
      role: 'elder',
      serviceGroup: 'Group 1',
      isActive: true,
      assignedTerritories: [],
    },
    {
      id: 'pub-servant-1',
      congregationId: 'cong-default',
      displayName: 'Bro. Emeka Okon',
      role: 'servant',
      serviceGroup: 'Group 1',
      isActive: true,
      assignedTerritories: ['t-14'],
    },
    {
      id: 'pub-pioneer-1',
      congregationId: 'cong-default',
      displayName: 'Sis. Grace Obi',
      role: 'regular_pioneer',
      serviceGroup: 'Group 2',
      isActive: true,
      assignedTerritories: ['t-19'],
    },
  ],
  activePublisherId: 'pub-elder-1',
  territories: [
    {
      id: 't-14',
      congregationId: 'cong-default',
      number: '#14',
      name: 'Oakwood Estate',
      region: 'Port Harcourt (Africa)',
      status: 'assigned',
      assignedTo: 'Bro. Emeka Okon',
      assignedDate: '2026-10-12',
      dueDate: '2027-02-12',
      lastCompletedDate: '2026-06-15',
      monthsSinceWorked: 1,
      progress: 0.65,
      totalAddresses: 142,
      completedAddresses: 92,
      returnVisitsCount: 18,
      dncCount: 3,
      isElderlyFriendly: true,
      accessibilityNotes: 'Level paved streets, shaded sidewalks',
      boundaryGeojson: '{"type":"Polygon","coordinates":[[[6.988,4.821],[6.995,4.821],[6.995,4.819],[6.988,4.819],[6.988,4.821]]]}',
    },
    {
      id: 't-22',
      congregationId: 'cong-default',
      number: '#22',
      name: 'Westminster Residential & Retail',
      region: 'London (Europe)',
      status: 'assigned',
      assignedTo: 'Bro. Arthur Davies',
      assignedDate: '2026-11-01',
      dueDate: '2027-03-01',
      lastCompletedDate: '2026-04-10',
      monthsSinceWorked: 3,
      progress: 0.4,
      totalAddresses: 180,
      completedAddresses: 72,
      returnVisitsCount: 24,
      dncCount: 2,
      specialNeedsFlag: true,
      accessibilityNotes: 'Ground-floor access & quiet seating zones',
    },
    {
      id: 't-08',
      congregationId: 'cong-default',
      number: '#08',
      name: 'Brooklyn Heights Waterfront',
      region: 'New York (Americas)',
      status: 'available',
      assignedTo: null,
      lastCompletedDate: '2026-03-15',
      monthsSinceWorked: 8,
      isSeldomWorked: true,
      progress: 0.0,
      totalAddresses: 115,
      completedAddresses: 0,
      returnVisitsCount: 0,
      dncCount: 1,
    },
    {
      id: 't-19',
      congregationId: 'cong-default',
      number: '#19',
      name: 'Shinjuku Commercial & Residential',
      region: 'Tokyo (Asia-Pacific)',
      status: 'completed',
      assignedTo: 'Sis. Grace Obi',
      assignedDate: '2026-08-01',
      dueDate: '2026-12-01',
      lastCompletedDate: '2026-11-20',
      monthsSinceWorked: 0,
      progress: 1.0,
      totalAddresses: 96,
      completedAddresses: 96,
      returnVisitsCount: 15,
      dncCount: 1,
    },
  ],
  initiatives: [
    {
      id: 'init-1',
      category: 'elderly_care',
      title: 'Elderly & Infirm Letter / Phone Ministry Group',
      coordinator: 'Bro. Samuel Ade',
      targetArea: 'Territory #14 (Flat Ground Blocks)',
      scheduleDate: '2026-11-28',
      status: 'active',
      notes: 'Arrange rides at 9:00 AM; pair experienced publishers with limited-mobility friends.',
    },
    {
      id: 'init-2',
      category: 'seldom_worked',
      title: 'Rural & Outlying Waterfront Blitz (#08)',
      coordinator: 'Bro. Emeka Okon',
      targetArea: 'Territory #08',
      scheduleDate: '2026-12-05',
      status: 'planned',
      notes: 'Car group departure 8:00 AM.',
    },
  ],
  sharedPins: [
    {
      id: 'pin-1',
      congregationId: 'cong-default',
      territoryId: 't-14',
      createdBy: 'Bro. Emeka Okon',
      title: 'Saturday Morning Car Group Meetup',
      category: 'meeting_point',
      lat: 4.821,
      lng: 6.988,
      notes: 'Meet by Main Oakwood Gate at 8:45 AM.',
      updatedAt: new Date().toISOString(),
    },
  ],
  messages: [
    {
      id: 'msg-1',
      congregationId: 'cong-default',
      senderId: 'pub-servant-1',
      senderName: 'Bro. Emeka Okon',
      senderRole: 'servant',
      channel: 'field_service',
      body: 'Territory #14 morning group meeting at Oakwood Gate at 8:45 AM.',
      pinId: 'pin-1',
      createdAt: new Date().toISOString(),
    },
  ],
  publisherLocations: [
    {
      id: 'loc-1',
      congregationId: 'cong-default',
      publisherId: 'pub-servant-1',
      displayName: 'Bro. Emeka Okon',
      role: 'servant',
      territoryId: 't-14',
      lat: 4.8205,
      lng: 6.9901,
      isTracking: true,
      updatedAt: new Date().toISOString(),
    },
  ],
  serviceReports: [
    {
      id: 'rep-1',
      congregationId: 'cong-default',
      publisherId: 'pub-pioneer-1',
      publisherName: 'Sis. Grace Obi',
      yearMonth: new Date().toISOString().slice(0, 7),
      publisherRole: 'regular_pioneer',
      participated: true,
      hours: 52.5,
      creditHours: 0,
      bibleStudies: 4,
      remarks: '',
      submittedAt: new Date().toISOString(),
    },
  ],
  selectedTerritoryId: 't-14',
  selectedTerritory: null,
  addresses: [
    { id: 'a-1', territoryId: 't-14', streetAddress: '12 Oakwood Crescent', unit: 'Villa A', status: 'return_visit', lat: 4.8205, lng: 6.9892, notes: 'Studying lesson 04' },
    { id: 'a-2', territoryId: 't-14', streetAddress: '14 Oakwood Crescent', status: 'not_at_home', lat: 4.8208, lng: 6.9898 },
    { id: 'a-3', territoryId: 't-14', streetAddress: '16 Oakwood Crescent', status: 'unvisited', lat: 4.8211, lng: 6.9902 },
    { id: 'a-4', territoryId: 't-14', streetAddress: '18 Oakwood Crescent', status: 'do_not_call', lat: 4.8214, lng: 6.9906, notes: 'Requested no contact' },
  ],
  filterStatus: 'all',
  searchQuery: '',
  isS13ModalOpen: false,
  isAnalyticsModalOpen: false,
  showHeatmap: true,
  activeTool: 'select',

  addCongregation: (c) =>
    set((state) => {
      const id = `cong-${Date.now()}`;
      return {
        congregations: [...state.congregations, { ...c, id }],
        activeCongregationId: id,
      };
    }),
  updateCongregation: (id, patch) =>
    set((state) => ({
      congregations: state.congregations.map((c) => (c.id === id ? { ...c, ...patch } : c)),
    })),
  deleteCongregation: (id) =>
    set((state) => {
      const next = state.congregations.filter((c) => c.id !== id);
      return {
        congregations: next,
        activeCongregationId: state.activeCongregationId === id ? (next[0]?.id ?? '') : state.activeCongregationId,
        publishers: state.publishers.filter((p) => p.congregationId !== id),
        territories: state.territories.filter((t) => t.congregationId !== id),
        sharedPins: state.sharedPins.filter((p) => p.congregationId !== id),
        messages: state.messages.filter((m) => m.congregationId !== id),
      };
    }),
  setActiveCongregation: (activeCongregationId) => set({ activeCongregationId }),

  addPublisher: (p) =>
    set((state) => {
      const id = `pub-${Date.now()}`;
      return {
        publishers: [...state.publishers, { ...p, id }],
        activePublisherId: state.activePublisherId || id,
      };
    }),
  updatePublisher: (id, patch) =>
    set((state) => ({
      publishers: state.publishers.map((p) => (p.id === id ? { ...p, ...patch } : p)),
    })),
  assignPublisherRole: (id, role) =>
    set((state) => ({
      publishers: state.publishers.map((p) => (p.id === id ? { ...p, role } : p)),
    })),
  deletePublisher: (id) =>
    set((state) => {
      const next = state.publishers.filter((p) => p.id !== id);
      return {
        publishers: next,
        activePublisherId: state.activePublisherId === id ? (next[0]?.id ?? '') : state.activePublisherId,
      };
    }),
  setActivePublisher: (activePublisherId) => set({ activePublisherId }),

  setTerritories: (territories) => set({ territories }),
  selectTerritory: (id) => {
    const territory = get().territories.find((t) => t.id === id) || null;
    set({ selectedTerritoryId: id, selectedTerritory: territory });
  },
  addTerritory: (territory) =>
    set((state) => {
      const id = `t-${Date.now()}`;
      const next = { ...territory, id, congregationId: territory.congregationId || state.activeCongregationId };
      return {
        territories: [...state.territories, next],
        selectedTerritoryId: id,
        selectedTerritory: next,
      };
    }),
  updateTerritory: (id, patch) =>
    set((state) => {
      const updated = state.territories.map((t) => (t.id === id ? { ...t, ...patch } : t));
      const selected = state.selectedTerritoryId === id ? updated.find((t) => t.id === id) || null : state.selectedTerritory;
      return { territories: updated, selectedTerritory: selected };
    }),
  deleteTerritory: (id) =>
    set((state) => {
      const filtered = state.territories.filter((t) => t.id !== id);
      const nextId = state.selectedTerritoryId === id ? (filtered[0]?.id ?? null) : state.selectedTerritoryId;
      return {
        territories: filtered,
        selectedTerritoryId: nextId,
        selectedTerritory: filtered.find((t) => t.id === nextId) || null,
      };
    }),
  splitSelectedTerritory: (id) =>
    set((state) => {
      const target = state.territories.find((t) => t.id === id);
      if (!target) return state;
      const halfTotal = Math.max(1, Math.floor(target.totalAddresses / 2));
      const halfDone = Math.floor(target.completedAddresses / 2);
      const polyA: Territory = {
        ...target,
        id: `${id}-a`,
        number: `${target.number}A`,
        name: `${target.name} (West Sector)`,
        totalAddresses: halfTotal,
        completedAddresses: halfDone,
        progress: halfTotal > 0 ? halfDone / halfTotal : target.progress,
      };
      const polyB: Territory = {
        ...target,
        id: `${id}-b`,
        number: `${target.number}B`,
        name: `${target.name} (East Sector)`,
        status: 'available',
        assignedTo: null,
        totalAddresses: Math.max(1, target.totalAddresses - halfTotal),
        completedAddresses: 0,
        progress: 0,
      };
      const remaining = state.territories.filter((t) => t.id !== id);
      const nextList = [...remaining, polyA, polyB];
      return {
        territories: nextList,
        selectedTerritoryId: polyA.id,
        selectedTerritory: polyA,
      };
    }),

  addInitiative: (item) =>
    set((state) => ({
      initiatives: [{ ...item, id: `init-${Date.now()}` }, ...state.initiatives],
    })),
  updateInitiative: (id, patch) =>
    set((state) => ({
      initiatives: state.initiatives.map((i) => (i.id === id ? { ...i, ...patch } : i)),
    })),
  deleteInitiative: (id) =>
    set((state) => ({
      initiatives: state.initiatives.filter((i) => i.id !== id),
    })),

  addSharedPin: (pin) => {
    const id = `pin-${Date.now()}`;
    set((state) => ({
      sharedPins: [
        { ...pin, id, updatedAt: new Date().toISOString() },
        ...state.sharedPins,
      ],
    }));
    return id;
  },
  updateSharedPin: (id, patch) =>
    set((state) => ({
      sharedPins: state.sharedPins.map((p) =>
        p.id === id ? { ...p, ...patch, updatedAt: new Date().toISOString() } : p,
      ),
    })),
  deleteSharedPin: (id) =>
    set((state) => ({
      sharedPins: state.sharedPins.filter((p) => p.id !== id),
    })),

  sendMessage: (msg) =>
    set((state) => ({
      messages: [
        { ...msg, id: `msg-${Date.now()}`, createdAt: new Date().toISOString() },
        ...state.messages,
      ],
    })),
  updateMessage: (id, body) =>
    set((state) => ({
      messages: state.messages.map((m) => (m.id === id ? { ...m, body } : m)),
    })),
  deleteMessage: (id) =>
    set((state) => ({
      messages: state.messages.filter((m) => m.id !== id),
    })),

  togglePublisherTracking: (publisherId, lat = 4.821, lng = 6.992) =>
    set((state) => {
      const pub = state.publishers.find((p) => p.id === publisherId);
      const existing = state.publisherLocations.find((l) => l.publisherId === publisherId);
      if (existing) {
        return {
          publisherLocations: state.publisherLocations.map((l) =>
            l.publisherId === publisherId
              ? { ...l, isTracking: !l.isTracking, lat, lng, updatedAt: new Date().toISOString() }
              : l,
          ),
        };
      }
      return {
        publisherLocations: [
          ...state.publisherLocations,
          {
            id: `loc-${Date.now()}`,
            congregationId: state.activeCongregationId,
            publisherId,
            displayName: pub?.displayName ?? 'Publisher',
            role: pub?.role ?? 'publisher',
            territoryId: state.selectedTerritoryId ?? '',
            lat,
            lng,
            isTracking: true,
            updatedAt: new Date().toISOString(),
          },
        ],
      };
    }),

  upsertServiceReport: (entry) =>
    set((state) => {
      const idx = state.serviceReports.findIndex(
        (r) => r.publisherId === entry.publisherId && r.yearMonth === entry.yearMonth,
      );
      if (idx >= 0) {
        const next = [...state.serviceReports];
        next[idx] = { ...next[idx], ...entry, submittedAt: new Date().toISOString() };
        return { serviceReports: next };
      }
      return {
        serviceReports: [
          { ...entry, id: `rep-${Date.now()}`, submittedAt: new Date().toISOString() },
          ...state.serviceReports,
        ],
      };
    }),
  deleteServiceReport: (id) =>
    set((state) => ({
      serviceReports: state.serviceReports.filter((r) => r.id !== id),
    })),

  clearAllDemoRecords: () =>
    set({
      territories: [],
      initiatives: [],
      sharedPins: [],
      messages: [],
      publisherLocations: [],
      serviceReports: [],
      addresses: [],
      selectedTerritoryId: null,
      selectedTerritory: null,
    }),

  setFilterStatus: (filterStatus) => set({ filterStatus }),
  setSearchQuery: (searchQuery) => set({ searchQuery }),
  setIsS13ModalOpen: (isS13ModalOpen) => set({ isS13ModalOpen }),
  setIsAnalyticsModalOpen: (isAnalyticsModalOpen) => set({ isAnalyticsModalOpen }),
  setShowHeatmap: (showHeatmap) => set({ showHeatmap }),
  setActiveTool: (activeTool) => set({ activeTool }),
}));
