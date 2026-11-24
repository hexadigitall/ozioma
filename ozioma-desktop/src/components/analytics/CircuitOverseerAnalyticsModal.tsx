import React, { useState } from 'react';
import { useTerritoryStore } from '../../stores/territoryStore';
import {
  BarChart3,
  X,
  Printer,
  AlertTriangle,
} from 'lucide-react';

interface CircuitOverseerAnalyticsModalProps {
  onClose: () => void;
}

export const CircuitOverseerAnalyticsModal: React.FC<CircuitOverseerAnalyticsModalProps> = ({
  onClose,
}) => {
  const [activeTab, setActiveTab] = useState<'s8' | 'saturation' | 'pioneers'>('s8');
  const { territories } = useTerritoryStore();

  // Derived metrics for S-8 report
  const totalCount = territories.length;
  const completedOrActive = territories.filter((t) => (t.monthsSinceWorked ?? 0) <= 6).length;
  const overdueCount = territories.filter((t) => (t.monthsSinceWorked ?? 0) > 6).length;
  const coverageRate = totalCount > 0 ? ((completedOrActive / totalCount) * 100).toFixed(0) : '0';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-6 backdrop-blur-sm">
      <div className="flex max-h-[92vh] w-[950px] flex-col rounded-xl border border-slate-700 bg-slate-900 shadow-2xl">
        {/* Header Ribbon */}
        <div className="flex items-center justify-between border-b border-slate-800 px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-emerald-500/10 border border-emerald-500/30 text-emerald-400">
              <BarChart3 className="h-5 w-5" />
            </div>
            <div>
              <h3 className="font-bold text-white text-base">
                Circuit Overseer (CO) & Annual Analytics Suite
              </h3>
              <p className="text-[11px] text-slate-400">
                Official Congregation S-8 Form & Territory Saturation Intelligence • Service Year 2026/2027
              </p>
            </div>
          </div>
          <button onClick={onClose} className="rounded p-1 text-slate-400 hover:bg-slate-800">
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Navigation Tabs */}
        <div className="flex border-b border-slate-800 bg-slate-900/60 px-6 text-xs font-semibold">
          <button
            onClick={() => setActiveTab('s8')}
            className={`border-b-2 py-3 px-4 transition ${
              activeTab === 's8'
                ? 'border-emerald-500 text-emerald-400'
                : 'border-transparent text-slate-400 hover:text-slate-200'
            }`}
          >
            Annual S-8 Form
          </button>
          <button
            onClick={() => setActiveTab('saturation')}
            className={`border-b-2 py-3 px-4 transition flex items-center gap-1.5 ${
              activeTab === 'saturation'
                ? 'border-emerald-500 text-emerald-400'
                : 'border-transparent text-slate-400 hover:text-slate-200'
            }`}
          >
            <span>Saturation Heatmap & Velocity</span>
            {overdueCount > 0 && (
              <span className="rounded-full bg-red-500/20 px-1.5 py-0.2 text-[10px] text-red-400 border border-red-500/30">
                {overdueCount} cold
              </span>
            )}
          </button>
          <button
            onClick={() => setActiveTab('pioneers')}
            className={`border-b-2 py-3 px-4 transition ${
              activeTab === 'pioneers'
                ? 'border-emerald-500 text-emerald-400'
                : 'border-transparent text-slate-400 hover:text-slate-200'
            }`}
          >
            Pioneer Hour Pacing & Assignment Equity
          </button>
        </div>

        {/* Tab Content Area */}
        <div className="flex-1 overflow-y-auto p-6">
          {/* TAB 1: OFFICIAL THEOCRATIC S-8 FORM */}
          {activeTab === 's8' && (
            <div className="space-y-6">
              {/* Form S-8 Printable Document Container */}
              <div className="rounded-lg border border-slate-300 bg-white p-8 text-slate-900 font-sans shadow-md print:border-none print:shadow-none">
                {/* Formal Theocratic Header */}
                <div className="border-b-2 border-slate-900 pb-3 flex justify-between items-start">
                  <div>
                    <h1 className="text-lg font-black tracking-wide uppercase">
                      CONGREGATION TERRITORY ANALYSIS REPORT
                    </h1>
                    <p className="text-xs font-bold text-slate-600">
                      FORM S-8 (Prepared for the Circuit Overseer's Visit)
                    </p>
                  </div>
                  <div className="text-right text-xs">
                    <div className="font-extrabold text-slate-900">SERVICE YEAR: 2026-2027</div>
                    <div className="text-slate-600">Date: November 24, 2026</div>
                  </div>
                </div>

                {/* Metadata Row */}
                <div className="mt-4 grid grid-cols-3 gap-4 border-b border-slate-200 pb-3 text-xs">
                  <div>
                    <span className="font-bold text-slate-600">Congregation:</span> Rumuola
                  </div>
                  <div>
                    <span className="font-bold text-slate-600">City / Land:</span> Port Harcourt, Nigeria
                  </div>
                  <div>
                    <span className="font-bold text-slate-600">Circuit:</span> RV-04
                  </div>
                </div>

                {/* S-8 Breakdown Table */}
                <table className="mt-6 w-full border-collapse border border-slate-400 text-xs text-left">
                  <thead className="bg-slate-100 text-[11px] font-bold uppercase tracking-wider text-slate-800">
                    <tr>
                      <th className="border border-slate-400 p-2">Category of Territory</th>
                      <th className="border border-slate-400 p-2 text-center">Total In Inventory</th>
                      <th className="border border-slate-400 p-2 text-center">Worked Once</th>
                      <th className="border border-slate-400 p-2 text-center">Worked Twice</th>
                      <th className="border border-slate-400 p-2 text-center">Worked 3+ Times</th>
                      <th className="border border-slate-400 p-2 text-center text-red-700">Not Worked</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-300 font-medium">
                    <tr>
                      <td className="border border-slate-400 p-2 font-bold">1. Regular Residential</td>
                      <td className="border border-slate-400 p-2 text-center">42</td>
                      <td className="border border-slate-400 p-2 text-center">26</td>
                      <td className="border border-slate-400 p-2 text-center">10</td>
                      <td className="border border-slate-400 p-2 text-center">2</td>
                      <td className="border border-slate-400 p-2 text-center font-bold text-red-600">4</td>
                    </tr>
                    <tr>
                      <td className="border border-slate-400 p-2 font-bold">2. Commercial & Business</td>
                      <td className="border border-slate-400 p-2 text-center">6</td>
                      <td className="border border-slate-400 p-2 text-center">4</td>
                      <td className="border border-slate-400 p-2 text-center">2</td>
                      <td className="border border-slate-400 p-2 text-center">0</td>
                      <td className="border border-slate-400 p-2 text-center text-slate-400">0</td>
                    </tr>
                    <tr>
                      <td className="border border-slate-400 p-2 font-bold">3. Foreign-Language Search</td>
                      <td className="border border-slate-400 p-2 text-center">2</td>
                      <td className="border border-slate-400 p-2 text-center">2</td>
                      <td className="border border-slate-400 p-2 text-center">0</td>
                      <td className="border border-slate-400 p-2 text-center">0</td>
                      <td className="border border-slate-400 p-2 text-center text-slate-400">0</td>
                    </tr>
                    <tr className="bg-slate-50 font-bold">
                      <td className="border border-slate-400 p-2 uppercase">TOTALS</td>
                      <td className="border border-slate-400 p-2 text-center font-black">50</td>
                      <td className="border border-slate-400 p-2 text-center">32</td>
                      <td className="border border-slate-400 p-2 text-center">12</td>
                      <td className="border border-slate-400 p-2 text-center">2</td>
                      <td className="border border-slate-400 p-2 text-center text-red-600">4</td>
                    </tr>
                  </tbody>
                </table>

                {/* S-8 Summary Highlights */}
                <div className="mt-6 grid grid-cols-3 gap-4 bg-slate-50 p-4 rounded border border-slate-200 text-xs">
                  <div>
                    <div className="text-slate-500 font-semibold">Annual Coverage Velocity</div>
                    <div className="text-xl font-extrabold text-emerald-700 mt-0.5">{coverageRate}% Covered</div>
                    <div className="text-[10px] text-slate-500">Paced to reach 100% by August 31</div>
                  </div>
                  <div>
                    <div className="text-slate-500 font-semibold">Average Completion Time</div>
                    <div className="text-xl font-extrabold text-slate-800 mt-0.5">82 Days</div>
                    <div className="text-[10px] text-slate-500">Within the 4-month guideline</div>
                  </div>
                  <div>
                    <div className="text-slate-500 font-semibold">Saturation Equilibrium</div>
                    <div className="text-xl font-extrabold text-blue-700 mt-0.5">1.3x / Year</div>
                    <div className="text-[10px] text-slate-500">Congregation territory worked fully &gt; 1x</div>
                  </div>
                </div>

                {/* Signature Block */}
                <div className="mt-8 grid grid-cols-2 gap-8 border-t border-slate-300 pt-4 text-xs">
                  <div>
                    <div className="border-b border-slate-400 pb-6 font-bold text-slate-700">
                      Territory Overseer Signature:
                    </div>
                    <div className="mt-1 text-[10px] text-slate-500">Bro. Emeka Okon (Elder)</div>
                  </div>
                  <div>
                    <div className="border-b border-slate-400 pb-6 font-bold text-slate-700">
                      Circuit Overseer Review:
                    </div>
                    <div className="mt-1 text-[10px] text-slate-500">Circuit Visit Date: _________________</div>
                  </div>
                </div>
              </div>

              {/* Action Banner */}
              <div className="flex justify-end">
                <button
                  onClick={() => window.print()}
                  className="flex items-center gap-2 rounded bg-emerald-600 px-4 py-2 text-xs font-semibold text-white hover:bg-emerald-500 shadow transition"
                >
                  <Printer className="h-4 w-4" />
                  <span>Print Formal Form S-8</span>
                </button>
              </div>
            </div>
          )}

          {/* TAB 2: SATURATION HEATMAP & VELOCITY */}
          {activeTab === 'saturation' && (
            <div className="space-y-6">
              {/* Velocity Progress Bar */}
              <div className="rounded-lg border border-slate-800 bg-slate-800/40 p-4">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-slate-300">Congregation Coverage Velocity</span>
                  <span className="font-bold text-emerald-400">{coverageRate}% Worked in Past 12 Months</span>
                </div>
                <div className="mt-2 h-2.5 w-full rounded-full bg-slate-800 overflow-hidden">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-emerald-500 via-amber-500 to-emerald-400"
                    style={{ width: `${coverageRate}%` }}
                  />
                </div>
                <div className="mt-3 flex justify-between text-[11px] text-slate-400">
                  <span>Target: 100% before August 31</span>
                  <span>Days remaining in Service Year: 279</span>
                </div>
              </div>

              {/* Heatmap Legend */}
              <div className="flex items-center gap-6 rounded border border-slate-800 bg-slate-900/60 p-3 text-xs">
                <div className="font-semibold text-slate-400">Saturation Legend:</div>
                <div className="flex items-center gap-1.5">
                  <span className="h-3 w-3 rounded-full bg-emerald-500" />
                  <span className="text-slate-300">Fresh (&lt; 2 mo)</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="h-3 w-3 rounded-full bg-amber-500" />
                  <span className="text-slate-300">Active (2 - 4 mo)</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="h-3 w-3 rounded-full bg-orange-500" />
                  <span className="text-slate-300">Aging (4 - 6 mo)</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="h-3 w-3 rounded-full bg-red-500" />
                  <span className="text-red-400 font-bold">Cold / Overdue (&gt; 6 mo)</span>
                </div>
              </div>

              {/* Territory Grid with Heatmap Status */}
              <div className="grid grid-cols-2 gap-3">
                {territories.map((t) => {
                  const months = t.monthsSinceWorked ?? 0;
                  const isCold = months > 6;
                  const isAging = months > 3 && months <= 6;
                  const isFresh = months <= 2;

                  const colorClass = isCold
                    ? 'border-red-500/50 bg-red-950/20 text-red-400'
                    : isAging
                    ? 'border-amber-500/50 bg-amber-950/20 text-amber-400'
                    : 'border-emerald-500/50 bg-emerald-950/20 text-emerald-400';

                  return (
                    <div
                      key={t.id}
                      className={`rounded-lg border p-3 flex justify-between items-center transition ${colorClass}`}
                    >
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-black text-sm">{t.number}</span>
                          <span className="font-bold text-white text-xs">{t.name}</span>
                        </div>
                        <div className="text-[11px] text-slate-400 mt-1">
                          {t.region} • {t.totalAddresses} doors
                        </div>
                        <div className="text-[10px] text-slate-500 mt-0.5">
                          Assigned: {t.assignedTo || 'Unassigned (In File)'}
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-xs font-bold">
                          {months === 0 ? 'Worked this mo.' : `${months} mo. ago`}
                        </div>
                        {isCold && (
                          <div className="mt-1 flex items-center gap-1 text-[10px] font-bold text-red-400">
                            <AlertTriangle className="h-3 w-3" />
                            <span>Action Required</span>
                          </div>
                        )}
                        {isFresh && (
                          <div className="mt-1 text-[10px] text-emerald-400">
                            Up to date
                          </div>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* TAB 3: PIONEER HOUR PACING & EQUITY */}
          {activeTab === 'pioneers' && (
            <div className="space-y-6">
              {/* Header Overview */}
              <div className="grid grid-cols-3 gap-3 text-xs">
                <div className="rounded border border-slate-800 bg-slate-800/40 p-3">
                  <div className="text-slate-400">Regular Pioneers</div>
                  <div className="text-xl font-bold text-emerald-400 mt-1">6 Active</div>
                  <div className="text-[10px] text-slate-500">Requirement: 50h / mo (600h / yr)</div>
                </div>
                <div className="rounded border border-slate-800 bg-slate-800/40 p-3">
                  <div className="text-slate-400">Auxiliary Pioneers</div>
                  <div className="text-xl font-bold text-blue-400 mt-1">14 Serving</div>
                  <div className="text-[10px] text-slate-500">Requirement: 30h or 15h / mo</div>
                </div>
                <div className="rounded border border-slate-800 bg-slate-800/40 p-3">
                  <div className="text-slate-400">Assignment Equity Index</div>
                  <div className="text-xl font-bold text-white mt-1">94% Balanced</div>
                  <div className="text-[10px] text-slate-500">Distributed across 4 service groups</div>
                </div>
              </div>

              {/* Live Pioneer Pacing Table */}
              <div className="rounded border border-slate-800 bg-slate-950 overflow-hidden">
                <table className="w-full text-left text-xs">
                  <thead className="border-b border-slate-800 bg-slate-900/80 text-[11px] uppercase tracking-wider text-slate-400">
                    <tr>
                      <th className="p-3">Publisher</th>
                      <th className="p-3">Status</th>
                      <th className="p-3">Current Hours</th>
                      <th className="p-3">Monthly Goal</th>
                      <th className="p-3">Required Pace</th>
                      <th className="p-3 text-right">Pacing State</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/50">
                    {[
                      { name: 'Bro. Emeka Okon', role: 'Regular Pioneer', hours: 44, goal: 50, pace: '1.0 h/day', state: 'On Track' },
                      { name: 'Sis. Yuka Tanaka', role: 'Regular Pioneer', hours: 52, goal: 50, pace: 'Met Goal', state: 'Ahead' },
                      { name: 'Bro. Lucas Silva', role: 'Regular Pioneer', hours: 42, goal: 50, pace: '1.3 h/day', state: 'On Track' },
                      { name: 'Bro. Arthur Davies', role: 'Auxiliary Pioneer', hours: 28, goal: 30, pace: '0.4 h/day', state: 'On Track' },
                      { name: 'Sis. Chioma Eze', role: 'Auxiliary Pioneer', hours: 22, goal: 30, pace: '1.3 h/day', state: 'Attention' },
                    ].map((p, idx) => (
                      <tr key={idx} className="hover:bg-slate-900/40">
                        <td className="p-3 font-semibold text-slate-200">{p.name}</td>
                        <td className="p-3">
                          <span className="rounded bg-slate-800 px-2 py-0.5 text-[10px] font-bold text-slate-300">
                            {p.role}
                          </span>
                        </td>
                        <td className="p-3 font-mono text-emerald-400 font-bold">{p.hours}h</td>
                        <td className="p-3 font-mono text-slate-400">{p.goal}h</td>
                        <td className="p-3 font-mono text-slate-300">{p.pace}</td>
                        <td className="p-3 text-right">
                          <span
                            className={`rounded px-2 py-0.5 text-[10px] font-bold ${
                              p.state === 'Ahead'
                                ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                                : p.state === 'On Track'
                                ? 'bg-blue-500/20 text-blue-400 border border-blue-500/30'
                                : 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                            }`}
                          >
                            {p.state}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between border-t border-slate-800 bg-slate-900/80 px-6 py-4">
          <div className="text-xs text-slate-500">
            Formal Congregation Analysis for Circuit Overseer Review • Ozioma Desktop Engine
          </div>
          <button
            onClick={onClose}
            className="rounded bg-slate-800 px-4 py-2 text-xs font-semibold text-slate-300 hover:bg-slate-700"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};
