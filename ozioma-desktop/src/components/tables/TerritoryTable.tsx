import React from 'react';
import { useTerritoryStore } from '../../stores/territoryStore';

export const TerritoryTable: React.FC = () => {
  const {
    territories,
    selectedTerritoryId,
    selectTerritory,
    filterStatus,
    searchQuery,
  } = useTerritoryStore();

  const filtered = territories.filter((t) => {
    const matchesFilter = filterStatus === 'all' || t.status === filterStatus;
    const matchesSearch =
      t.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.number.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  return (
    <div className="divide-y divide-slate-800/60">
      {filtered.map((t) => {
        const isSelected = t.id === selectedTerritoryId;
        return (
          <div
            key={t.id}
            onClick={() => selectTerritory(t.id)}
            className={`cursor-pointer p-3 transition ${
              isSelected
                ? 'bg-slate-800/90 border-l-2 border-emerald-400'
                : 'hover:bg-slate-800/40'
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="font-bold text-white text-xs">{t.number}</span>
              <span
                className={`text-[10px] font-semibold uppercase px-1.5 py-0.5 rounded ${
                  t.status === 'assigned'
                    ? 'bg-blue-500/20 text-blue-400'
                    : t.status === 'available'
                    ? 'bg-emerald-500/20 text-emerald-400'
                    : 'bg-slate-500/20 text-slate-400'
                }`}
              >
                {t.status}
              </span>
            </div>
            <div className="mt-1 text-xs font-medium text-slate-200 truncate">{t.name}</div>
            <div className="mt-1.5 flex items-center justify-between text-[11px] text-slate-400">
              <span>{t.assignedTo || 'Unassigned'}</span>
              <span>{(t.progress * 100).toFixed(0)}%</span>
            </div>
            {/* Progress bar */}
            <div className="mt-1.5 h-1 w-full rounded-full bg-slate-800 overflow-hidden">
              <div
                className="h-full bg-emerald-500 rounded-full transition-all duration-300"
                style={{ width: `${t.progress * 100}%` }}
              />
            </div>
          </div>
        );
      })}
    </div>
  );
};
