import React from 'react';
import { useTerritoryStore } from '../../stores/territoryStore';
import { TerritoryTable } from '../tables/TerritoryTable';
import { GisMapCanvas } from '../gis/GisMapCanvas';
import { S13CardModal } from '../s13/S13CardModal';
import {
  Map,
  Users,
  Printer,
  Search,
  Scissors,
  Route,
  FileSpreadsheet,
  CheckCircle2,
  Clock,
  ShieldAlert,
} from 'lucide-react';

export const TriPaneWorkspace: React.FC = () => {
  const {
    territories,
    selectedTerritoryId,
    selectTerritory,
    filterStatus,
    setFilterStatus,
    searchQuery,
    setSearchQuery,
    isS13ModalOpen,
    setIsS13ModalOpen,
    activeTool,
    setActiveTool,
  } = useTerritoryStore();

  const selectedTerritory = territories.find((t) => t.id === selectedTerritoryId);

  return (
    <div className="flex h-screen w-screen flex-col bg-slate-950 text-slate-100">
      {/* Top Application Ribbon / Desktop Menu */}
      <header className="flex h-12 items-center justify-between border-b border-slate-800 bg-slate-900 px-4 text-xs font-medium">
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 font-bold tracking-wider text-emerald-400">
            <Map className="h-5 w-5 text-emerald-400" />
            <span>OZIOMA DESKTOP</span>
          </div>
          <span className="text-slate-600">|</span>
          <span className="text-slate-400">Rumuola Congregation (Port Harcourt, Nigeria)</span>
        </div>

        {/* Global Desktop Shortcuts & Actions */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setIsS13ModalOpen(true)}
            className="flex items-center gap-1.5 rounded bg-slate-800 px-3 py-1.5 text-xs font-semibold text-slate-200 transition hover:bg-slate-700"
            title="Batch S-13 Print (Ctrl+P)"
          >
            <Printer className="h-3.5 w-3.5 text-emerald-400" />
            <span>Print S-13 Cards</span>
          </button>
          <button
            className="flex items-center gap-1.5 rounded bg-slate-800 px-3 py-1.5 text-xs font-semibold text-slate-200 transition hover:bg-slate-700"
            title="Bulk CSV / Excel Master Import"
          >
            <FileSpreadsheet className="h-3.5 w-3.5 text-blue-400" />
            <span>Import Excel</span>
          </button>
          <div className="h-4 w-px bg-slate-800" />
          <div className="flex items-center gap-1 text-[11px] text-emerald-400">
            <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
            <span>Sync: Connected</span>
          </div>
        </div>
      </header>

      {/* Main Tri-Pane Split Area */}
      <div className="flex flex-1 overflow-hidden">
        {/* Pane 1: Left Territory Catalog & Filter (Width: 340px) */}
        <aside className="flex w-80 flex-col border-r border-slate-800 bg-slate-900/50">
          <div className="border-b border-slate-800 p-3 space-y-2">
            <div className="relative">
              <Search className="absolute left-2.5 top-2.5 h-3.5 w-3.5 text-slate-500" />
              <input
                type="text"
                placeholder="Search territories (Ctrl+F)..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full rounded bg-slate-800/80 pl-8 pr-3 py-1.5 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-emerald-500"
              />
            </div>
            {/* Quick Filter Tabs */}
            <div className="flex gap-1 text-[11px]">
              {['all', 'available', 'assigned', 'completed'].map((status) => (
                <button
                  key={status}
                  onClick={() => setFilterStatus(status)}
                  className={`flex-1 rounded py-1 font-semibold uppercase tracking-wider transition ${
                    filterStatus === status
                      ? 'bg-emerald-600/20 text-emerald-400 border border-emerald-500/30'
                      : 'text-slate-400 hover:bg-slate-800'
                  }`}
                >
                  {status}
                </button>
              ))}
            </div>
          </div>

          <div className="flex-1 overflow-y-auto">
            <TerritoryTable />
          </div>

          {/* Left Footer Counters */}
          <div className="flex justify-between border-t border-slate-800 bg-slate-900/80 px-4 py-2 text-[11px] text-slate-400">
            <span>{territories.length} Territories</span>
            <span className="text-emerald-400">42 In Progress</span>
          </div>
        </aside>

        {/* Pane 2: Center GIS Canvas (Flex-1) */}
        <main className="relative flex flex-1 flex-col bg-slate-950">
          {/* GIS Geometry Toolbar */}
          <div className="absolute left-4 top-4 z-10 flex items-center gap-1 rounded-lg border border-slate-800 bg-slate-900/90 p-1 shadow-2xl backdrop-blur">
            <button
              onClick={() => setActiveTool('select')}
              className={`rounded p-1.5 text-xs font-medium transition ${
                activeTool === 'select' ? 'bg-emerald-600 text-white' : 'text-slate-400 hover:bg-slate-800'
              }`}
              title="Select / Pan (V)"
            >
              Select
            </button>
            <button
              onClick={() => setActiveTool('draw_poly')}
              className={`flex items-center gap-1 rounded p-1.5 text-xs font-medium transition ${
                activeTool === 'draw_poly' ? 'bg-emerald-600 text-white' : 'text-slate-400 hover:bg-slate-800'
              }`}
              title="Draw Polygon Boundary (P)"
            >
              <Route className="h-3.5 w-3.5" />
              <span>Draw Poly</span>
            </button>
            <button
              onClick={() => setActiveTool('split')}
              className={`flex items-center gap-1 rounded p-1.5 text-xs font-medium transition ${
                activeTool === 'split' ? 'bg-emerald-600 text-white' : 'text-slate-400 hover:bg-slate-800'
              }`}
              title="Split Polygon across line (S)"
            >
              <Scissors className="h-3.5 w-3.5 text-amber-400" />
              <span>Split (#A/#B)</span>
            </button>
            <div className="h-4 w-px bg-slate-800" />
            <button
              onClick={() => setActiveTool('snap')}
              className={`rounded p-1.5 text-xs font-medium transition ${
                activeTool === 'snap' ? 'bg-blue-600 text-white' : 'text-slate-400 hover:bg-slate-800'
              }`}
              title="Snap to Street Vector"
            >
              Snap Streets
            </button>
          </div>

          <GisMapCanvas territory={selectedTerritory} activeTool={activeTool} />
        </main>

        {/* Pane 3: Right Territory & Publisher Detail Inspector (Width: 360px) */}
        <aside className="flex w-96 flex-col border-l border-slate-800 bg-slate-900/60 p-4 overflow-y-auto">
          {selectedTerritory ? (
            <div className="space-y-6">
              <div>
                <div className="flex items-center justify-between">
                  <span className="rounded bg-emerald-500/20 px-2 py-0.5 text-xs font-bold text-emerald-400 border border-emerald-500/30">
                    {selectedTerritory.number}
                  </span>
                  <span className="text-xs uppercase tracking-wider text-slate-400">
                    {selectedTerritory.region}
                  </span>
                </div>
                <h2 className="mt-2 text-lg font-bold text-white">{selectedTerritory.name}</h2>
              </div>

              {/* Progress & Stat Cards */}
              <div className="grid grid-cols-2 gap-2 text-xs">
                <div className="rounded border border-slate-800 bg-slate-800/40 p-2.5">
                  <div className="text-slate-400">Coverage</div>
                  <div className="mt-1 text-base font-bold text-emerald-400">
                    {(selectedTerritory.progress * 100).toFixed(0)}%
                  </div>
                  <div className="text-[10px] text-slate-500">
                    {selectedTerritory.completedAddresses}/{selectedTerritory.totalAddresses} doors
                  </div>
                </div>
                <div className="rounded border border-slate-800 bg-slate-800/40 p-2.5">
                  <div className="text-slate-400">Return Visits</div>
                  <div className="mt-1 text-base font-bold text-blue-400">
                    {selectedTerritory.returnVisitsCount} active
                  </div>
                  <div className="text-[10px] text-slate-500">Local E2EE Encrypted</div>
                </div>
              </div>

              {/* Assignment Details */}
              <div className="rounded border border-slate-800 bg-slate-800/30 p-3 space-y-3 text-xs">
                <div className="font-semibold text-slate-300">Assignment Record</div>
                <div className="space-y-1.5 text-slate-400">
                  <div className="flex justify-between">
                    <span>Assigned Brother:</span>
                    <span className="font-medium text-slate-200">
                      {selectedTerritory.assignedTo || 'Unassigned'}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span>Date Assigned:</span>
                    <span className="text-slate-200">{selectedTerritory.assignedDate || '—'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Due Date:</span>
                    <span className="text-amber-400 font-medium">
                      {selectedTerritory.dueDate || '—'}
                    </span>
                  </div>
                </div>

                <div className="pt-2 flex gap-2">
                  <button className="flex-1 rounded bg-slate-700 py-1.5 text-xs font-semibold hover:bg-slate-600 transition">
                    Reassign
                  </button>
                  <button
                    onClick={() => setIsS13ModalOpen(true)}
                    className="flex-1 rounded bg-emerald-600 py-1.5 text-xs font-semibold text-white hover:bg-emerald-500 transition flex items-center justify-center gap-1"
                  >
                    <Printer className="h-3 w-3" />
                    <span>Card S-13</span>
                  </button>
                </div>
              </div>

              {/* Theocratic Privacy & DNC Protection Notice */}
              <div className="rounded border border-red-900/30 bg-red-950/20 p-3 text-xs text-red-300">
                <div className="flex items-center gap-2 font-semibold">
                  <ShieldAlert className="h-4 w-4 text-red-400" />
                  <span>Do Not Call (DNC): {selectedTerritory.dncCount} Locked Addresses</span>
                </div>
                <p className="mt-1 text-[11px] text-red-400/80">
                  DNC records are synced anonymously to prevent unauthorized field calls. Householder identities remain protected under NDPA/GDPR zero-cloud privacy rules.
                </p>
              </div>
            </div>
          ) : (
            <div className="flex h-full items-center justify-center text-xs text-slate-500">
              Select a territory to inspect records
            </div>
          )}
        </aside>
      </div>

      {/* S-13 Print Preview Modal */}
      {isS13ModalOpen && selectedTerritory && (
        <S13CardModal territory={selectedTerritory} onClose={() => setIsS13ModalOpen(false)} />
      )}
    </div>
  );
};
