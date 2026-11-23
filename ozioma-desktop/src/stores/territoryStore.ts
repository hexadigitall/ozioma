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
  activeTool: 'select' | 'draw_poly' | 'split' | 'snap';

  setTerritories: (territories: Territory[]) => void;
  selectTerritory: (id: string | null) => void;
  setFilterStatus: (status: string) => void;
  setSearchQuery: (query: string) => void;
  setIsS13ModalOpen: (open: boolean) => void;
  setActiveTool: (tool: 'select' | 'draw_poly' | 'split' | 'snap') => void;
}

export const useTerritoryStore = create<TerritoryStore>((set, get) => ({
  territories: [
    {
      id: 't-14',
      number: '#14',
      name: 'Oakwood Estate',
      region: 'Port Harcourt',
      status: 'assigned',
      assignedTo: 'Bro. Emeka Okon',
      assignedDate: '2026-10-12',
      dueDate: '2027-02-12',
      progress: 0.65,
      totalAddresses: 142,
      completedAddresses: 92,
      returnVisitsCount: 18,
      dncCount: 3,
      boundaryGeojson: '{"type":"Polygon","coordinates":[[[6.988,4.821],[6.995,4.821],[6.995,4.819],[6.988,4.819],[6.988,4.821]]]}',
    },
    {
      id: 't-15',
      number: '#15',
      name: 'GRA Phase 2 Commercial Strip',
      region: 'Port Harcourt',
      status: 'available',
      assignedTo: null,
      progress: 0.0,
      totalAddresses: 88,
      completedAddresses: 0,
      returnVisitsCount: 0,
      dncCount: 1,
    },
    {
      id: 't-16',
      number: '#16',
      name: 'Woji South Gated Zone',
      region: 'Port Harcourt',
      status: 'assigned',
      assignedTo: 'Bro. Kenneth Eze',
      assignedDate: '2026-11-01',
      dueDate: '2027-03-01',
      progress: 0.22,
      totalAddresses: 110,
      completedAddresses: 24,
      returnVisitsCount: 6,
      dncCount: 0,
    },
    {
      id: 't-22',
      number: '#22',
      name: 'Trans-Amadi Industrial Zone',
      region: 'Port Harcourt',
      status: 'completed',
      assignedTo: 'Sis. Grace Adele',
      assignedDate: '2026-08-10',
      dueDate: '2026-12-10',
      progress: 1.0,
      totalAddresses: 64,
      completedAddresses: 64,
      returnVisitsCount: 12,
      dncCount: 2,
    },
  ],
  selectedTerritoryId: 't-14',
  selectedTerritory: null,
  addresses: [],
  filterStatus: 'all',
  searchQuery: '',
  isS13ModalOpen: false,
  activeTool: 'select',

  setTerritories: (territories) => set({ territories }),
  selectTerritory: (id) => {
    const t = get().territories.find((item) => item.id === id) || null;
    set({ selectedTerritoryId: id, selectedTerritory: t });
  },
  setFilterStatus: (filterStatus) => set({ filterStatus }),
  setSearchQuery: (searchQuery) => set({ searchQuery }),
  setIsS13ModalOpen: (isS13ModalOpen) => set({ isS13ModalOpen }),
  setActiveTool: (activeTool) => set({ activeTool }),
}));
