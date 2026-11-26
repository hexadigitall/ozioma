import React, { useState } from 'react';
import { CongregationInitiative } from '../../types';
import { useTerritoryStore } from '../../stores/territoryStore';
import { X, Plus, Trash2, CheckCircle2, HeartHandshake, Compass, Globe } from 'lucide-react';

interface CongregationCareModalProps {
  onClose: () => void;
}

export const CongregationCareModal: React.FC<CongregationCareModalProps> = ({ onClose }) => {
  const { initiatives, territories, addInitiative, updateInitiative, deleteInitiative } = useTerritoryStore();

  const [category, setCategory] = useState<CongregationInitiative['category']>('elderly_care');
  const [title, setTitle] = useState('');
  const [coordinator, setCoordinator] = useState('');
  const [targetArea, setTargetArea] = useState('');
  const [scheduleDate, setScheduleDate] = useState(new Date().toISOString().slice(0, 10));
  const [notes, setNotes] = useState('');

  const seldomWorkedTerritories = territories.filter(
    (t) => t.isSeldomWorked || (t.monthsSinceWorked ?? 0) >= 6,
  );

  const handleAdd = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    addInitiative({
      category,
      title: title.trim(),
      coordinator: coordinator.trim() || 'Service Committee',
      targetArea: targetArea.trim() || 'Congregation Wide',
      scheduleDate,
      status: 'planned',
      notes: notes.trim(),
    });
    setTitle('');
    setCoordinator('');
    setTargetArea('');
    setNotes('');
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 p-6 backdrop-blur-sm">
      <div className="flex max-h-[88vh] w-full max-w-4xl flex-col rounded-xl border border-slate-700 bg-slate-900 shadow-2xl">
        <div className="flex items-center justify-between border-b border-slate-800 px-6 py-4">
          <div className="flex items-center gap-2.5">
            <HeartHandshake className="h-5 w-5 text-emerald-400" />
            <div>
              <h2 className="text-sm font-bold text-white">Congregation Care, Seldom-Worked & Need-Greater Hub</h2>
              <p className="text-[11px] text-slate-400">
                Coordinate support for elderly/special-needs publishers, seldom-worked campaigns, and ministry expansion
              </p>
            </div>
          </div>
          <button onClick={onClose} className="rounded p-1.5 text-slate-400 hover:bg-slate-800 hover:text-white">
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="grid flex-1 grid-cols-12 gap-5 overflow-y-auto p-6 text-xs">
          {/* Left: Create Initiative Form + Seldom Worked Alert */}
          <div className="col-span-5 space-y-4">
            <form onSubmit={handleAdd} className="space-y-3 rounded-lg border border-slate-800 bg-slate-950/60 p-4">
              <div className="font-bold text-slate-200">Schedule Care / Expansion Initiative</div>
              <div>
                <label className="mb-1 block text-slate-400">Initiative Focus</label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value as CongregationInitiative['category'])}
                  className="w-full rounded border border-slate-700 bg-slate-800 px-2.5 py-1.5 text-white"
                >
                  <option value="elderly_care">Working with Elderly Publishers</option>
                  <option value="special_needs">Special Needs Support & Rides</option>
                  <option value="seldom_worked">Seldom-Worked Territory Campaign</option>
                  <option value="need_greater">Expanding Ministry / Need-Greater</option>
                </select>
              </div>
              <div>
                <label className="mb-1 block text-slate-400">Title *</label>
                <input
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="e.g. Saturday Elderly Car Group / Rural Drive"
                  className="w-full rounded border border-slate-700 bg-slate-800 px-2.5 py-1.5 text-white"
                  required
                />
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="mb-1 block text-slate-400">Coordinator</label>
                  <input
                    value={coordinator}
                    onChange={(e) => setCoordinator(e.target.value)}
                    placeholder="Bro. Name"
                    className="w-full rounded border border-slate-700 bg-slate-800 px-2.5 py-1.5 text-white"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-slate-400">Target Date</label>
                  <input
                    type="date"
                    value={scheduleDate}
                    onChange={(e) => setScheduleDate(e.target.value)}
                    className="w-full rounded border border-slate-700 bg-slate-800 px-2.5 py-1.5 text-white"
                  />
                </div>
              </div>
              <div>
                <label className="mb-1 block text-slate-400">Territory / Area</label>
                <input
                  value={targetArea}
                  onChange={(e) => setTargetArea(e.target.value)}
                  placeholder="Territory # or Outlying Town"
                  className="w-full rounded border border-slate-700 bg-slate-800 px-2.5 py-1.5 text-white"
                />
              </div>
              <div>
                <label className="mb-1 block text-slate-400">Logistics & Care Notes</label>
                <textarea
                  rows={2}
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Wheelchair access, pickup points, bilingual tracts..."
                  className="w-full rounded border border-slate-700 bg-slate-800 px-2.5 py-1.5 text-white"
                />
              </div>
              <button
                type="submit"
                className="flex w-full items-center justify-center gap-1.5 rounded bg-emerald-600 py-2 font-semibold text-white hover:bg-emerald-500"
              >
                <Plus className="h-3.5 w-3.5" />
                <span>Add Congregation Initiative</span>
              </button>
            </form>

            <div className="rounded-lg border border-amber-500/30 bg-amber-950/20 p-4">
              <div className="flex items-center gap-2 font-bold text-amber-300">
                <Compass className="h-4 w-4" />
                <span>Seldom-Worked Queue ({seldomWorkedTerritories.length})</span>
              </div>
              <ul className="mt-2 space-y-1.5 text-slate-300">
                {seldomWorkedTerritories.map((t) => (
                  <li key={t.id} className="flex justify-between">
                    <span>{t.number} {t.name}</span>
                    <span className="text-amber-400 font-semibold">{t.monthsSinceWorked ?? 0} mo idle</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          {/* Right: Active Initiatives Grid */}
          <div className="col-span-7 space-y-3">
            <div className="flex items-center justify-between">
              <span className="font-bold text-slate-200">Active & Planned Congregation Plans ({initiatives.length})</span>
              <span className="flex items-center gap-1 text-[11px] text-emerald-400">
                <Globe className="h-3.5 w-3.5" /> Worldwide Expansion Support
              </span>
            </div>

            {initiatives.map((item) => (
              <div key={item.id} className="rounded-lg border border-slate-800 bg-slate-800/35 p-4 space-y-2">
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="rounded bg-slate-700 px-2 py-0.5 text-[10px] font-bold uppercase text-emerald-300">
                        {item.category.replace('_', ' ')}
                      </span>
                      <span className="text-[11px] text-slate-400">{item.scheduleDate}</span>
                    </div>
                    <h3 className="mt-1 font-bold text-white text-sm">{item.title}</h3>
                  </div>
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() =>
                        updateInitiative(item.id, {
                          status: item.status === 'completed' ? 'active' : 'completed',
                        })
                      }
                      className={`rounded p-1.5 transition ${
                        item.status === 'completed'
                          ? 'bg-emerald-600/20 text-emerald-400'
                          : 'bg-slate-700/60 text-slate-300 hover:bg-slate-700'
                      }`}
                      title="Toggle Complete"
                    >
                      <CheckCircle2 className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => deleteInitiative(item.id)}
                      className="rounded p-1.5 text-slate-400 hover:bg-red-900/40 hover:text-red-300"
                      title="Delete Initiative"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </div>
                <div className="text-slate-300">{item.notes}</div>
                <div className="flex gap-4 text-[11px] text-slate-400">
                  <span>Coordinator: <strong className="text-slate-200">{item.coordinator}</strong></span>
                  <span>Area: <strong className="text-slate-200">{item.targetArea}</strong></span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
