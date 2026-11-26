import React, { useState } from 'react';
import { Territory } from '../../types';
import { useTerritoryStore } from '../../stores/territoryStore';
import { X, Save, Trash2 } from 'lucide-react';

interface TerritoryCrudModalProps {
  existing?: Territory | null;
  onClose: () => void;
}

export const TerritoryCrudModal: React.FC<TerritoryCrudModalProps> = ({ existing, onClose }) => {
  const { addTerritory, updateTerritory, deleteTerritory } = useTerritoryStore();

  const [number, setNumber] = useState(existing?.number ?? '#');
  const [name, setName] = useState(existing?.name ?? '');
  const [region, setRegion] = useState(existing?.region ?? 'Port Harcourt (Africa)');
  const [status, setStatus] = useState<Territory['status']>(existing?.status ?? 'available');
  const [assignedTo, setAssignedTo] = useState(existing?.assignedTo ?? '');
  const [assignedDate, setAssignedDate] = useState(existing?.assignedDate ?? new Date().toISOString().slice(0, 10));
  const [dueDate, setDueDate] = useState(existing?.dueDate ?? '');
  const [totalAddresses, setTotalAddresses] = useState(String(existing?.totalAddresses ?? 100));
  const [isElderlyFriendly, setIsElderlyFriendly] = useState(Boolean(existing?.isElderlyFriendly));
  const [isSeldomWorked, setIsSeldomWorked] = useState(Boolean(existing?.isSeldomWorked));
  const [specialNeedsFlag, setSpecialNeedsFlag] = useState(Boolean(existing?.specialNeedsFlag));
  const [accessibilityNotes, setAccessibilityNotes] = useState(existing?.accessibilityNotes ?? '');

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    const total = Math.max(1, Number(totalAddresses) || 100);
    const payload = {
      number: number.trim() || '#00',
      name: name.trim(),
      region: region.trim(),
      status,
      assignedTo: status === 'available' ? null : (assignedTo.trim() || null),
      assignedDate: status === 'available' ? null : (assignedDate || null),
      dueDate: status === 'available' ? null : (dueDate || null),
      totalAddresses: total,
      completedAddresses: existing?.completedAddresses ?? 0,
      returnVisitsCount: existing?.returnVisitsCount ?? 0,
      dncCount: existing?.dncCount ?? 0,
      progress: existing?.progress ?? 0,
      monthsSinceWorked: existing?.monthsSinceWorked ?? (isSeldomWorked ? 7 : 0),
      isElderlyFriendly,
      isSeldomWorked,
      specialNeedsFlag,
      accessibilityNotes: accessibilityNotes.trim(),
    };

    if (existing) {
      updateTerritory(existing.id, payload);
    } else {
      addTerritory(payload);
    }
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4 backdrop-blur-sm">
      <div className="w-full max-w-xl rounded-xl border border-slate-700 bg-slate-900 shadow-2xl">
        <div className="flex items-center justify-between border-b border-slate-800 px-5 py-3.5">
          <h2 className="text-sm font-bold text-white">
            {existing ? `Edit Territory ${existing.number} — ${existing.name}` : 'Create New Congregation Territory'}
          </h2>
          <button onClick={onClose} className="rounded p-1 text-slate-400 hover:bg-slate-800 hover:text-white">
            <X className="h-4 w-4" />
          </button>
        </div>

        <form onSubmit={handleSave} className="space-y-4 p-5 text-xs">
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="mb-1 block font-semibold text-slate-400">Territory #</label>
              <input
                value={number}
                onChange={(e) => setNumber(e.target.value)}
                className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white focus:border-emerald-500 focus:outline-none"
                required
              />
            </div>
            <div className="col-span-2">
              <label className="mb-1 block font-semibold text-slate-400">Territory Name / Area *</label>
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. Rumuola Phase 2"
                className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white focus:border-emerald-500 focus:outline-none"
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="mb-1 block font-semibold text-slate-400">Region / Circuit</label>
              <input
                value={region}
                onChange={(e) => setRegion(e.target.value)}
                className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white focus:border-emerald-500 focus:outline-none"
              />
            </div>
            <div>
              <label className="mb-1 block font-semibold text-slate-400">Lifecycle Status</label>
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value as Territory['status'])}
                className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white focus:border-emerald-500 focus:outline-none"
              >
                <option value="available">Available (Ready)</option>
                <option value="assigned">Assigned (In Progress)</option>
                <option value="completed">Completed</option>
                <option value="archived">Archived (Cool-down)</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="mb-1 block font-semibold text-slate-400">Assigned Publisher</label>
              <input
                value={assignedTo}
                onChange={(e) => setAssignedTo(e.target.value)}
                placeholder="Bro./Sis. Name"
                className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white focus:border-emerald-500 focus:outline-none"
              />
            </div>
            <div>
              <label className="mb-1 block font-semibold text-slate-400">Date Assigned</label>
              <input
                type="date"
                value={assignedDate}
                onChange={(e) => setAssignedDate(e.target.value)}
                className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white focus:border-emerald-500 focus:outline-none"
              />
            </div>
            <div>
              <label className="mb-1 block font-semibold text-slate-400">Due Date</label>
              <input
                type="date"
                value={dueDate}
                onChange={(e) => setDueDate(e.target.value)}
                className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white focus:border-emerald-500 focus:outline-none"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="mb-1 block font-semibold text-slate-400">Total Doors / Addresses</label>
              <input
                type="number"
                value={totalAddresses}
                onChange={(e) => setTotalAddresses(e.target.value)}
                className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white focus:border-emerald-500 focus:outline-none"
              />
            </div>
            <div className="flex flex-col justify-center gap-1.5 pt-2">
              <label className="flex items-center gap-2 text-slate-200">
                <input type="checkbox" checked={isElderlyFriendly} onChange={(e) => setIsElderlyFriendly(e.target.checked)} />
                <span>Elderly-Friendly (Flat / Shaded)</span>
              </label>
              <label className="flex items-center gap-2 text-slate-200">
                <input type="checkbox" checked={specialNeedsFlag} onChange={(e) => setSpecialNeedsFlag(e.target.checked)} />
                <span>Special Needs Accessible</span>
              </label>
              <label className="flex items-center gap-2 text-slate-200">
                <input type="checkbox" checked={isSeldomWorked} onChange={(e) => setIsSeldomWorked(e.target.checked)} />
                <span>Seldom-Worked Territory</span>
              </label>
            </div>
          </div>

          <div>
            <label className="mb-1 block font-semibold text-slate-400">S-13 Accessibility & Field Notes</label>
            <textarea
              rows={2}
              value={accessibilityNotes}
              onChange={(e) => setAccessibilityNotes(e.target.value)}
              placeholder="Parking notes, gate hours, flat walking terrain for elderly..."
              className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white focus:border-emerald-500 focus:outline-none"
            />
          </div>

          <div className="flex items-center justify-between border-t border-slate-800 pt-3">
            {existing ? (
              <button
                type="button"
                onClick={() => {
                  deleteTerritory(existing.id);
                  onClose();
                }}
                className="flex items-center gap-1 rounded bg-red-900/40 px-3 py-1.5 font-semibold text-red-300 hover:bg-red-900/70"
              >
                <Trash2 className="h-3.5 w-3.5" />
                <span>Delete</span>
              </button>
            ) : (
              <div />
            )}
            <div className="flex gap-2">
              <button
                type="button"
                onClick={onClose}
                className="rounded border border-slate-700 px-4 py-1.5 font-semibold text-slate-300 hover:bg-slate-800"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="flex items-center gap-1.5 rounded bg-emerald-600 px-4 py-1.5 font-semibold text-white hover:bg-emerald-500"
              >
                <Save className="h-3.5 w-3.5" />
                <span>{existing ? 'Save Changes' : 'Create Territory'}</span>
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
};
