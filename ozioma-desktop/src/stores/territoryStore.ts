import { create } from 'zustand';
import { Territory, Address } from '../types';

interface TerritoryStore {
  territories: Territory[];
  selectedTerritoryId: string | null;
  selectedTerritory: Territory | null;
  addresses: Address[];
  filterStatus: string;
  searchQuery: string;
  isS13ModalOpen: boolean;
  isAnalyticsModalOpen: boolean;
  activeTool: 'select' | 'draw_poly' | 'split' | 'snap';

  setTerritories: (territories: Territory[]) => void;
  selectTerritory: (id: string | null) => void;
  setFilterStatus: (status: string) => void;
  setSearchQuery: (query: string) => void;
  setIsS13ModalOpen: (open: boolean) => void;
  setIsAnalyticsModalOpen: (open: boolean) => void;
  setActiveTool: (tool: 'select' | 'draw_poly' | 'split' | 'snap') => void;
}

export const useTerritoryStore = create<TerritoryStore>((set, get) => ({
  territories: [
    {
      id: 't-14',
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
      boundaryGeojson: '{"type":"Polygon","coordinates":[[[6.988,4.821],[6.995,4.821],[6.995,4.819],[6.988,4.819],[6.988,4.821]]]}',
    },
    {
      id: 't-22',
      number: '#22',
      name: 'Westminster Residential & Retail',
      region: 'London (Europe)',
      status: 'assigned',
      assignedTo: 'Bro. Arthur Davies',
      assignedDate: '2026-11-01',
      dueDate: '2027-03-01',
      lastCompletedDate: '2026-04-10',
      monthsSinceWorked: 3,
      progress: 0.40,
      totalAddresses: 180,
      completedAddresses: 72,
      returnVisitsCount: 24,
      dncCount: 2,
      boundaryGeojson: '{"type":"Polygon","coordinates":[[[-0.142,51.498],[-0.128,51.503],[-0.124,51.496],[-0.138,51.492],[-0.142,51.498]]]}',
    },
    {
      id: 't-08',
      number: '#08',
      name: 'Brooklyn Heights Waterfront',
      region: 'New York (Americas)',
      status: 'available',
      assignedTo: null,
      lastCompletedDate: '2026-03-15',
      monthsSinceWorked: 8, // Overdue / Cold (>6 months)
      progress: 0.0,
      totalAddresses: 115,
      completedAddresses: 0,
      returnVisitsCount: 0,
      dncCount: 1,
      boundaryGeojson: '{"type":"Polygon","coordinates":[[[-73.998,40.695],[-73.991,40.701],[-73.985,40.697],[-73.992,40.690],[-73.998,40.695]]]}',
    },
    {
      id: 't-31',
      number: '#31',
      name: 'Jardins Residential High-Rise',
      region: 'São Paulo (Americas)',
      status: 'assigned',
      assignedTo: 'Bro. Lucas Silva',
      assignedDate: '2026-10-15',
      dueDate: '2027-02-15',
      lastCompletedDate: '2026-07-20',
      monthsSinceWorked: 2,
      progress: 0.85,
      totalAddresses: 210,
      completedAddresses: 178,
      returnVisitsCount: 32,
      dncCount: 4,
    },
    {
      id: 't-19',
      number: '#19',
      name: 'Shinjuku Commercial & Residential',
      region: 'Tokyo (Asia-Pacific)',
      status: 'completed',
      assignedTo: 'Sis. Yuka Tanaka',
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
    {
      id: 't-04',
      number: '#04',
      name: 'Trans-Amadi Industrial Layout',
      region: 'Port Harcourt (Africa)',
      status: 'available',
      assignedTo: null,
      lastCompletedDate: '2026-02-01',
      monthsSinceWorked: 9, // Overdue (>6 months)
      progress: 0.0,
      totalAddresses: 84,
      completedAddresses: 0,
      returnVisitsCount: 2,
      dncCount: 0,
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
  activeTool: 'select',

  setTerritories: (territories) => set({ territories }),
  selectTerritory: (id) => {
    const territory = get().territories.find((t) => t.id === id) || null;
    set({ selectedTerritoryId: id, selectedTerritory: territory });
  },
  setFilterStatus: (filterStatus) => set({ filterStatus }),
  setSearchQuery: (searchQuery) => set({ searchQuery }),
  setIsS13ModalOpen: (isS13ModalOpen) => set({ isS13ModalOpen }),
  setIsAnalyticsModalOpen: (isAnalyticsModalOpen) => set({ isAnalyticsModalOpen }),
  setActiveTool: (activeTool) => set({ activeTool }),
}));
