import React, { useState } from 'react';
import { useTerritoryStore } from '../../stores/territoryStore';
import { TerritoryTable } from '../tables/TerritoryTable';
import { GisMapCanvas } from '../gis/GisMapCanvas';
import { S13CardModal } from '../s13/S13CardModal';
import { MasterImportModal } from '../importer/MasterImportModal';
import { CircuitOverseerAnalyticsModal } from '../analytics/CircuitOverseerAnalyticsModal';
import { TerritoryCrudModal } from '../territory/TerritoryCrudModal';
import { CongregationCareModal } from '../care/CongregationCareModal';
import { CongregationAdminModal } from '../congregation/CongregationAdminModal';
import { ChatAndPinsModal } from '../collaboration/ChatAndPinsModal';
import { Territory } from '../../types';
import {
  Printer,
  Search,
  Scissors,
  Route,
  FileSpreadsheet,
  BarChart3,
  ShieldAlert,
  Plus,
  HeartHandshake,
  Edit3,
  CheckCircle2,
  ShieldCheck,
  MessageSquare,
} from 'lucide-react';

export const TriPaneWorkspace: React.FC = () => {
  const {
    congregations,
    activeCongregationId,
    publishers,
    activePublisherId,
    territories,
    selectedTerritoryId,
    filterStatus,
    setFilterStatus,
    searchQuery,
    setSearchQuery,
    isS13ModalOpen,
    setIsS13ModalOpen,
    isAnalyticsModalOpen,
    setIsAnalyticsModalOpen,
    activeTool,
    setActiveTool,
    updateTerritory,
  } = useTerritoryStore();

  const [isImportModalOpen, setIsImportModalOpen] = useState(false);
  const [isCareModalOpen, setIsCareModalOpen] = useState(false);
  const [isCongAdminOpen, setIsCongAdminOpen] = useState(false);
  const [isChatOpen, setIsChatOpen] = useState(false);
  const [crudModalTarget, setCrudModalTarget] = useState<Territory | null | 'new'>(null);

  const selectedTerritory = territories.find((t) => t.id === selectedTerritoryId);
  const activeCong = congregations.find((c) => c.id === activeCongregationId);
  const activePub = publishers.find((p) => p.id === activePublisherId);
  const canManageTerritories = !activePub || activePub.role === 'elder' || activePub.role === 'servant';

  return (
    <div className="flex h-screen w-screen flex-col bg-slate-950 text-slate-100">
      {/* Top Application Ribbon / Desktop Menu */}
      <header className="flex h-12 items-center justify-between border-b border-slate-800 bg-slate-900 px-4 text-xs font-medium">
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 font-bold tracking-wider text-emerald-400">
            <img
              src="./brand/ozioma-logo-transparent.png"
              alt="Ozioma"
              className="h-6 w-6 rounded object-contain"
              onError={(e) => {
                (e.currentTarget as HTMLImageElement).style.display = 'none';
              }}
            />
            <span>OZIOMA DESKTOP</span>
          </div>
          <span className="text-slate-600">|</span>
          <button
            onClick={() => setIsCongAdminOpen(true)}
            className="rounded px-2 py-1 text-left text-slate-300 transition hover:bg-slate-800"
            title="Manage Congregation, Publishers, Roles & S-4 Reports"
          >
            <span>{activeCong?.name ?? 'Register Congregation'}</span>
            {activePub && (
              <span className="ml-2 rounded bg-emerald-500/20 px-1.5 py-0.5 text-[10px] font-bold text-emerald-300">
                {activePub.displayName} ({activePub.role})
              </span>
            )}
          </button>
        </div>

        {/* Global Desktop Shortcuts & Actions */}
        <div className="flex items-center gap-1.5">
          {canManageTerritories && (
            <button
              onClick={() => setCrudModalTarget('new')}
              className="flex items-center gap-1 rounded bg-emerald-600 px-2.5 py-1.5 text-xs font-semibold text-white transition hover:bg-emerald-500"
              title="New Territory Boundary (Ctrl+N)"
            >
              <Plus className="h-3.5 w-3.5" />
              <span>Territory</span>
            </button>
          )}
          <button
            onClick={() => setIsCongAdminOpen(true)}
            className="flex items-center gap-1 rounded bg-slate-800 px-2.5 py-1.5 text-xs font-semibold text-slate-200 transition hover:bg-slate-700"
            title="Congregation Setup, Publisher Roster, Roles & S-4 Reporting"
          >
            <ShieldCheck className="h-3.5 w-3.5 text-emerald-400" />
            <span>Roles & S-4</span>
          </button>
          <button
            onClick={() => setIsChatOpen(true)}
            className="flex items-center gap-1 rounded bg-slate-800 px-2.5 py-1.5 text-xs font-semibold text-slate-200 transition hover:bg-slate-700"
            title="Publisher Chat, Pin Sharing & Live Tracking"
          >
            <MessageSquare className="h-3.5 w-3.5 text-cyan-400" />
            <span>Chat & Pins</span>
          </button>
          <button
            onClick={() => setIsCareModalOpen(true)}
            className="flex items-center gap-1 rounded bg-slate-800 px-2.5 py-1.5 text-xs font-semibold text-slate-200 transition hover:bg-slate-700"
            title="Elderly, Special Needs, Seldom-Worked & Need-Greater Care"
          >
            <HeartHandshake className="h-3.5 w-3.5 text-amber-400" />
            <span>Care</span>
          </button>
          <button
            onClick={() => setIsS13ModalOpen(true)}
            className="flex items-center gap-1 rounded bg-slate-800 px-2.5 py-1.5 text-xs font-semibold text-slate-200 transition hover:bg-slate-700"
            title="Batch S-13 Print (Ctrl+P)"
          >
            <Printer className="h-3.5 w-3.5 text-emerald-400" />
            <span>S-13</span>
          </button>
          <button
            onClick={() => setIsImportModalOpen(true)}
            className="flex items-center gap-1 rounded bg-slate-800 px-2.5 py-1.5 text-xs font-semibold text-slate-200 transition hover:bg-slate-700"
            title="Bulk CSV / Excel Master Import"
          >
            <FileSpreadsheet className="h-3.5 w-3.5 text-blue-400" />
            <span>Import</span>
          </button>
          <button
            onClick={() => setIsAnalyticsModalOpen(true)}
            className="flex items-center gap-1 rounded border border-emerald-500/30 bg-emerald-600/20 px-2.5 py-1.5 text-xs font-semibold text-emerald-300 transition hover:bg-emerald-600/30"
            title="Circuit Overseer (CO) & Annual S-8 Suite"
          >
            <BarChart3 className="h-3.5 w-3.5 text-emerald-400" />
            <span>S-8</span>
          </button>
        </div>
      </header>

      {/* Main Tri-Pane Split Area */}
      <div className="flex flex-1 overflow-hidden">
        {/* Pane 1: Left Territory Catalog & Filter */}
        <aside className="flex w-80 flex-col border-r border-slate-800 bg-slate-900/50">
          <div className="space-y-2 border-b border-slate-800 p-3">
            <div className="relative">
              <Search className="absolute left-2.5 top-2.5 h-3.5 w-3.5 text-slate-500" />
              <input
                type="text"
                placeholder="Search territories (Ctrl+F)..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full rounded bg-slate-800/80 py-1.5 pl-8 pr-3 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-emerald-500"
              />
            </div>
            <div className="flex gap-1 text-[11px]">
              {['all', 'available', 'assigned', 'completed'].map((status) => (
                <button
                  key={status}
                  onClick={() => setFilterStatus(status)}
                  className={`flex-1 rounded py-1 font-semibold uppercase tracking-wider transition ${
                    filterStatus === status
                      ? 'border border-emerald-500/30 bg-emerald-600/20 text-emerald-400'
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

          <div className="flex justify-between border-t border-slate-800 bg-slate-900/80 px-4 py-2 text-[11px] text-slate-400">
            <span>{territories.length} Territories</span>
            <span className="text-emerald-400">
              {territories.filter((t) => t.status === 'assigned').length} Active
            </span>
          </div>
        </aside>

        {/* Pane 2: Center GIS Canvas */}
        <main className="relative flex flex-1 flex-col bg-slate-950">
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

        {/* Pane 3: Right Territory & Care Inspector */}
        <aside className="flex w-96 flex-col overflow-y-auto border-l border-slate-800 bg-slate-900/60 p-4">
          {selectedTerritory ? (
            <div className="space-y-5">
              <div>
                <div className="flex items-center justify-between">
                  <span className="rounded border border-emerald-500/30 bg-emerald-500/20 px-2 py-0.5 text-xs font-bold text-emerald-400">
                    {selectedTerritory.number}
                  </span>
                  <span className="text-xs uppercase tracking-wider text-slate-400">
                    {selectedTerritory.region}
                  </span>
                </div>
                <h2 className="mt-2 text-lg font-bold text-white">{selectedTerritory.name}</h2>
                <div className="mt-2 flex flex-wrap gap-1.5 text-[10px] font-semibold">
                  {selectedTerritory.isElderlyFriendly && (
                    <span className="rounded bg-blue-500/20 px-2 py-0.5 text-blue-300">Elderly-Friendly</span>
                  )}
                  {selectedTerritory.specialNeedsFlag && (
                    <span className="rounded bg-purple-500/20 px-2 py-0.5 text-purple-300">Special Needs Access</span>
                  )}
                  {(selectedTerritory.isSeldomWorked || (selectedTerritory.monthsSinceWorked ?? 0) >= 6) && (
                    <span className="rounded bg-amber-500/20 px-2 py-0.5 text-amber-300">Seldom Worked</span>
                  )}
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 text-xs">
                <div className="rounded border border-slate-800 bg-slate-800/40 p-2.5">
                  <div className="text-slate-400">Heatmap Coverage</div>
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

              {/* Assignment & CRUD Controls */}
              <div className="space-y-3 rounded border border-slate-800 bg-slate-800/30 p-3 text-xs">
                <div className="font-semibold text-slate-300">Assignment Record</div>
                <div className="space-y-1.5 text-slate-400">
                  <div className="flex justify-between">
                    <span>Assigned Publisher:</span>
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
                    <span className="font-medium text-amber-400">{selectedTerritory.dueDate || '—'}</span>
                  </div>
                </div>

                {selectedTerritory.accessibilityNotes && (
                  <div className="rounded bg-slate-900/80 p-2 text-[11px] text-slate-300">
                    {selectedTerritory.accessibilityNotes}
                  </div>
                )}

                <div className="grid grid-cols-2 gap-2 pt-2">
                  {canManageTerritories && (
                    <button
                      onClick={() => setCrudModalTarget(selectedTerritory)}
                      className="flex items-center justify-center gap-1 rounded bg-slate-700 py-1.5 text-xs font-semibold transition hover:bg-slate-600"
                    >
                      <Edit3 className="h-3 w-3" />
                      <span>Edit / Assign</span>
                    </button>
                  )}
                  <button
                    onClick={() =>
                      updateTerritory(selectedTerritory.id, {
                        status: 'completed',
                        progress: 1.0,
                        completedAddresses: selectedTerritory.totalAddresses,
                        lastCompletedDate: new Date().toISOString().slice(0, 10),
                        monthsSinceWorked: 0,
                      })
                    }
                    className="flex items-center justify-center gap-1 rounded bg-blue-600/80 py-1.5 text-xs font-semibold text-white transition hover:bg-blue-600"
                  >
                    <CheckCircle2 className="h-3 w-3" />
                    <span>Check In Done</span>
                  </button>
                </div>

                <button
                  onClick={() => setIsS13ModalOpen(true)}
                  className="flex w-full items-center justify-center gap-1 rounded bg-emerald-600 py-1.5 text-xs font-semibold text-white transition hover:bg-emerald-500"
                >
                  <Printer className="h-3 w-3" />
                  <span>Print Card S-13</span>
                </button>
              </div>

              <div className="rounded border border-red-900/30 bg-red-950/20 p-3 text-xs text-red-300">
                <div className="flex items-center gap-2 font-semibold">
                  <ShieldAlert className="h-4 w-4 text-red-400" />
                  <span>Do Not Call (DNC): {selectedTerritory.dncCount} Locked Addresses</span>
                </div>
                <p className="mt-1 text-[11px] text-red-400/80">
                  DNC records sync anonymously to prevent unauthorized calls. Householder identities remain strictly local & AES-256 encrypted.
                </p>
              </div>
            </div>
          ) : (
            <div className="flex h-full items-center justify-center text-xs text-slate-500">
              Create or select a territory to inspect records
            </div>
          )}
        </aside>
      </div>

      {isS13ModalOpen && selectedTerritory && (
        <S13CardModal territory={selectedTerritory} onClose={() => setIsS13ModalOpen(false)} />
      )}
      {isImportModalOpen && <MasterImportModal onClose={() => setIsImportModalOpen(false)} />}
      {isAnalyticsModalOpen && <CircuitOverseerAnalyticsModal onClose={() => setIsAnalyticsModalOpen(false)} />}
      {isCareModalOpen && <CongregationCareModal onClose={() => setIsCareModalOpen(false)} />}
      {isCongAdminOpen && <CongregationAdminModal onClose={() => setIsCongAdminOpen(false)} />}
      {isChatOpen && <ChatAndPinsModal onClose={() => setIsChatOpen(false)} />}
      {crudModalTarget && (
        <TerritoryCrudModal
          existing={crudModalTarget === 'new' ? null : crudModalTarget}
          onClose={() => setCrudModalTarget(null)}
        />
      )}
    </div>
  );
};
