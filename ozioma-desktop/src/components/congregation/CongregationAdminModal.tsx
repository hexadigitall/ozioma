import React, { useState } from 'react';
import { useTerritoryStore } from '../../stores/territoryStore';
import { TheocraticRole } from '../../types';
import { X, Plus, Trash2, ShieldCheck, Building2, Users, FileText, RotateCcw } from 'lucide-react';

interface CongregationAdminModalProps {
  onClose: () => void;
}

const ROLE_OPTIONS: { value: TheocraticRole; label: string }[] = [
  { value: 'elder', label: 'Elder / Overseer' },
  { value: 'servant', label: 'Ministerial / Territory Servant' },
  { value: 'regular_pioneer', label: 'Regular Pioneer (50h)' },
  { value: 'auxiliary_pioneer', label: 'Auxiliary Pioneer (15h/30h)' },
  { value: 'publisher', label: 'Publisher' },
];

export const CongregationAdminModal: React.FC<CongregationAdminModalProps> = ({ onClose }) => {
  const {
    congregations,
    activeCongregationId,
    setActiveCongregation,
    addCongregation,
    deleteCongregation,
    publishers,
    activePublisherId,
    setActivePublisher,
    addPublisher,
    assignPublisherRole,
    deletePublisher,
    serviceReports,
    upsertServiceReport,
    deleteServiceReport,
    clearAllDemoRecords,
  } = useTerritoryStore();

  const [tab, setTab] = useState<'congregations' | 'publishers' | 'reports'>('publishers');

  const activePublisher = publishers.find((p) => p.id === activePublisherId) || publishers[0];
  const canManageAdmin = !activePublisher || activePublisher.role === 'elder';

  // Congregation Form State
  const [congName, setCongName] = useState('');
  const [circuit, setCircuit] = useState('');
  const [countryCode, setCountryCode] = useState('WW');
  const [khAddress, setKhAddress] = useState('');
  const [meetings, setMeetings] = useState('Thu 6:30 PM • Sun 9:30 AM');

  // Publisher Form State
  const [pubName, setPubName] = useState('');
  const [pubRole, setPubRole] = useState<TheocraticRole>('publisher');
  const [pubGroup, setPubGroup] = useState('Group 1');

  // Report Form State
  const [repPubId, setRepPubId] = useState(activePublisher?.id ?? '');
  const [repMonth, setRepMonth] = useState(new Date().toISOString().slice(0, 7));
  const [repHours, setRepHours] = useState('12');
  const [repStudies, setRepStudies] = useState('1');

  const handleAddCong = (e: React.FormEvent) => {
    e.preventDefault();
    if (!congName.trim()) return;
    addCongregation({
      name: congName.trim(),
      circuit: circuit.trim(),
      countryCode: countryCode.trim() || 'WW',
      kingdomHallAddress: khAddress.trim(),
      meetingSchedule: meetings.trim(),
    });
    setCongName('');
    setCircuit('');
    setKhAddress('');
  };

  const handleAddPub = (e: React.FormEvent) => {
    e.preventDefault();
    if (!pubName.trim() || !activeCongregationId) return;
    addPublisher({
      congregationId: activeCongregationId,
      displayName: pubName.trim(),
      role: pubRole,
      serviceGroup: pubGroup.trim() || 'Group 1',
      isActive: true,
      assignedTerritories: [],
    });
    setPubName('');
  };

  const handleAddReport = (e: React.FormEvent) => {
    e.preventDefault();
    const targetPub = publishers.find((p) => p.id === repPubId) || activePublisher;
    if (!targetPub) return;
    upsertServiceReport({
      congregationId: activeCongregationId,
      publisherId: targetPub.id,
      publisherName: targetPub.displayName,
      yearMonth: repMonth,
      publisherRole: targetPub.role,
      participated: true,
      hours: Number(repHours) || 0,
      creditHours: 0,
      bibleStudies: Number(repStudies) || 0,
      remarks: '',
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 p-6 backdrop-blur-sm">
      <div className="flex max-h-[88vh] w-full max-w-5xl flex-col rounded-xl border border-slate-700 bg-slate-900 shadow-2xl">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-800 px-6 py-4">
          <div className="flex items-center gap-3">
            <ShieldCheck className="h-5 w-5 text-emerald-400" />
            <div>
              <h2 className="text-sm font-bold text-white">Congregation Structure, Publisher Roles & S-4 Reporting</h2>
              <p className="text-[11px] text-slate-400">
                Active Operator: <strong className="text-emerald-300">{activePublisher?.displayName || 'Setup Mode'}</strong> ({activePublisher?.role || 'elder'})
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => {
                clearAllDemoRecords();
              }}
              className="flex items-center gap-1 rounded border border-red-800/60 bg-red-950/30 px-2.5 py-1 text-[11px] font-semibold text-red-300 hover:bg-red-900/40"
              title="Clear preloaded sample entries to start fresh"
            >
              <RotateCcw className="h-3 w-3" />
              <span>Clear Sample Duds</span>
            </button>
            <button onClick={onClose} className="rounded p-1.5 text-slate-400 hover:bg-slate-800 hover:text-white">
              <X className="h-4 w-4" />
            </button>
          </div>
        </div>

        {/* Sub-Tabs */}
        <div className="flex gap-2 border-b border-slate-800 px-6 py-2 text-xs">
          <button
            onClick={() => setTab('publishers')}
            className={`flex items-center gap-1.5 rounded px-3 py-1.5 font-semibold ${
              tab === 'publishers' ? 'bg-emerald-600 text-white' : 'text-slate-400 hover:bg-slate-800'
            }`}
          >
            <Users className="h-3.5 w-3.5" />
            <span>Publishers & Role Access ({publishers.length})</span>
          </button>
          <button
            onClick={() => setTab('congregations')}
            className={`flex items-center gap-1.5 rounded px-3 py-1.5 font-semibold ${
              tab === 'congregations' ? 'bg-emerald-600 text-white' : 'text-slate-400 hover:bg-slate-800'
            }`}
          >
            <Building2 className="h-3.5 w-3.5" />
            <span>Congregations ({congregations.length})</span>
          </button>
          <button
            onClick={() => setTab('reports')}
            className={`flex items-center gap-1.5 rounded px-3 py-1.5 font-semibold ${
              tab === 'reports' ? 'bg-emerald-600 text-white' : 'text-slate-400 hover:bg-slate-800'
            }`}
          >
            <FileText className="h-3.5 w-3.5" />
            <span>Congregation S-4 Reports ({serviceReports.length})</span>
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-6 text-xs">
          {tab === 'publishers' && (
            <div className="grid grid-cols-12 gap-5">
              <div className="col-span-4 space-y-4">
                <form onSubmit={handleAddPub} className="space-y-3 rounded-lg border border-slate-800 bg-slate-950/60 p-4">
                  <div className="font-bold text-white">Create Publisher Profile</div>
                  <input
                    value={pubName}
                    onChange={(e) => setPubName(e.target.value)}
                    placeholder="Display Name (e.g. Bro. David) *"
                    className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white"
                    required
                  />
                  <select
                    value={pubRole}
                    onChange={(e) => setPubRole(e.target.value as TheocraticRole)}
                    className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white"
                  >
                    {ROLE_OPTIONS.map((r) => (
                      <option key={r.value} value={r.value}>
                        {r.label}
                      </option>
                    ))}
                  </select>
                  <input
                    value={pubGroup}
                    onChange={(e) => setPubGroup(e.target.value)}
                    placeholder="Service Group"
                    className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white"
                  />
                  <button
                    type="submit"
                    disabled={!canManageAdmin}
                    className="flex w-full items-center justify-center gap-1.5 rounded bg-emerald-600 py-2 font-semibold text-white hover:bg-emerald-500 disabled:opacity-40"
                  >
                    <Plus className="h-3.5 w-3.5" />
                    <span>Add Publisher</span>
                  </button>
                  {!canManageAdmin && (
                    <div className="text-[11px] text-amber-400">
                      Switch active operator to an Elder role to add or modify congregation privileges.
                    </div>
                  )}
                </form>
              </div>

              <div className="col-span-8 space-y-2">
                {publishers.map((p) => {
                  const isMe = p.id === activePublisherId;
                  return (
                    <div
                      key={p.id}
                      className="flex items-center justify-between rounded-lg border border-slate-800 bg-slate-800/40 px-4 py-3"
                    >
                      <div>
                        <div className="flex items-center gap-2 font-bold text-white">
                          <span>{p.displayName}</span>
                          {isMe && (
                            <span className="rounded bg-emerald-500/20 px-1.5 py-0.5 text-[10px] text-emerald-300">
                              ACTIVE OPERATOR
                            </span>
                          )}
                        </div>
                        <div className="text-[11px] text-slate-400">
                          {p.serviceGroup} • {p.isActive ? 'Active' : 'Inactive'}
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <select
                          disabled={!canManageAdmin}
                          value={p.role}
                          onChange={(e) => assignPublisherRole(p.id, e.target.value as TheocraticRole)}
                          className="rounded border border-slate-700 bg-slate-900 px-2 py-1 text-xs text-white"
                        >
                          {ROLE_OPTIONS.map((r) => (
                            <option key={r.value} value={r.value}>
                              {r.label}
                            </option>
                          ))}
                        </select>
                        <button
                          onClick={() => setActivePublisher(p.id)}
                          className="rounded border border-slate-700 px-2.5 py-1 text-[11px] text-slate-200 hover:bg-slate-700"
                        >
                          Switch User
                        </button>
                        {canManageAdmin && (
                          <button
                            onClick={() => deletePublisher(p.id)}
                            className="rounded p-1.5 text-slate-400 hover:bg-red-900/40 hover:text-red-300"
                            title="Delete Publisher"
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </button>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {tab === 'congregations' && (
            <div className="grid grid-cols-12 gap-5">
              <form onSubmit={handleAddCong} className="col-span-5 space-y-3 rounded-lg border border-slate-800 bg-slate-950/60 p-4">
                <div className="font-bold text-white">Register New Congregation</div>
                <input
                  value={congName}
                  onChange={(e) => setCongName(e.target.value)}
                  placeholder="Congregation Name *"
                  className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white"
                  required
                />
                <div className="grid grid-cols-2 gap-2">
                  <input
                    value={circuit}
                    onChange={(e) => setCircuit(e.target.value)}
                    placeholder="Circuit"
                    className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white"
                  />
                  <input
                    value={countryCode}
                    onChange={(e) => setCountryCode(e.target.value)}
                    placeholder="Country (e.g. NG/US)"
                    className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white"
                  />
                </div>
                <input
                  value={khAddress}
                  onChange={(e) => setKhAddress(e.target.value)}
                  placeholder="Kingdom Hall Address"
                  className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white"
                />
                <input
                  value={meetings}
                  onChange={(e) => setMeetings(e.target.value)}
                  placeholder="Meeting Schedule"
                  className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white"
                />
                <button
                  type="submit"
                  className="flex w-full items-center justify-center gap-1.5 rounded bg-emerald-600 py-2 font-semibold text-white hover:bg-emerald-500"
                >
                  <Plus className="h-3.5 w-3.5" />
                  <span>Register Congregation</span>
                </button>
              </form>

              <div className="col-span-7 space-y-3">
                {congregations.map((c) => (
                  <div key={c.id} className="flex items-center justify-between rounded-lg border border-slate-800 bg-slate-800/40 p-4">
                    <div>
                      <div className="font-bold text-white">{c.name}</div>
                      <div className="text-[11px] text-slate-400">
                        {c.circuit || 'Circuit TBD'} • {c.countryCode} • {c.kingdomHallAddress}
                      </div>
                      <div className="text-[11px] text-emerald-400">{c.meetingSchedule}</div>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => setActiveCongregation(c.id)}
                        className={`rounded px-3 py-1 text-[11px] font-semibold ${
                          c.id === activeCongregationId
                            ? 'bg-emerald-600 text-white'
                            : 'border border-slate-700 text-slate-300 hover:bg-slate-700'
                        }`}
                      >
                        {c.id === activeCongregationId ? 'Active' : 'Select'}
                      </button>
                      <button
                        onClick={() => deleteCongregation(c.id)}
                        className="rounded p-1.5 text-slate-400 hover:bg-red-900/40 hover:text-red-300"
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {tab === 'reports' && (
            <div className="grid grid-cols-12 gap-5">
              <form onSubmit={handleAddReport} className="col-span-4 space-y-3 rounded-lg border border-slate-800 bg-slate-950/60 p-4">
                <div className="font-bold text-white">Submit / Record S-4 Report</div>
                <select
                  value={repPubId}
                  onChange={(e) => setRepPubId(e.target.value)}
                  className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white"
                >
                  {publishers.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.displayName} ({p.role})
                    </option>
                  ))}
                </select>
                <input
                  type="month"
                  value={repMonth}
                  onChange={(e) => setRepMonth(e.target.value)}
                  className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white"
                />
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="mb-1 block text-slate-400">Hours</label>
                    <input
                      type="number"
                      step="0.5"
                      value={repHours}
                      onChange={(e) => setRepHours(e.target.value)}
                      className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white"
                    />
                  </div>
                  <div>
                    <label className="mb-1 block text-slate-400">Studies</label>
                    <input
                      type="number"
                      value={repStudies}
                      onChange={(e) => setRepStudies(e.target.value)}
                      className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white"
                    />
                  </div>
                </div>
                <button
                  type="submit"
                  className="flex w-full items-center justify-center gap-1.5 rounded bg-emerald-600 py-2 font-semibold text-white hover:bg-emerald-500"
                >
                  <Plus className="h-3.5 w-3.5" />
                  <span>Save S-4 Entry</span>
                </button>
              </form>

              <div className="col-span-8 space-y-2">
                {serviceReports.map((r) => (
                  <div key={r.id} className="flex items-center justify-between rounded-lg border border-slate-800 bg-slate-800/40 px-4 py-3">
                    <div>
                      <div className="font-bold text-white">{r.publisherName} — {r.yearMonth}</div>
                      <div className="text-[11px] text-slate-400">
                        {r.publisherRole} • {r.hours} hrs • {r.bibleStudies} Bible studies
                      </div>
                    </div>
                    <button
                      onClick={() => deleteServiceReport(r.id)}
                      className="rounded p-1.5 text-slate-400 hover:bg-red-900/40 hover:text-red-300"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
