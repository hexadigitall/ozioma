import React, { useState } from 'react';
import { Territory } from '../../types';
import { useTerritoryStore } from '../../stores/territoryStore';
import { Scissors, Sparkles, Flame, Radio, MapPin } from 'lucide-react';

interface GisMapCanvasProps {
  territory?: Territory;
  activeTool: string;
}

export const GisMapCanvas: React.FC<GisMapCanvasProps> = ({ territory, activeTool }) => {
  const {
    sharedPins,
    publisherLocations,
    showHeatmap,
    setShowHeatmap,
    splitSelectedTerritory,
  } = useTerritoryStore();

  const [zoom, setZoom] = useState(1);

  const handleExecuteSplit = async () => {
    if (!territory) return;
    try {
      const { invoke } = await import('@tauri-apps/api/core');
      await invoke('split_territory_polygon', {
        polygonGeojson: territory.boundaryGeojson || '{"type":"Polygon","coordinates":[]}',
        splitLineGeojson: '{"type":"LineString","coordinates":[[400,100],[400,500]]}',
      });
    } catch {
      // Browser/Electron runtime executes store topological split directly
    }
    splitSelectedTerritory(territory.id);
  };

  const progress = territory?.progress ?? 0;
  const fillClass =
    progress >= 0.75
      ? 'fill-emerald-500/30 stroke-emerald-400'
      : progress >= 0.3
      ? 'fill-amber-500/25 stroke-amber-400'
      : 'fill-red-500/20 stroke-red-400';

  const activeTrackers = publisherLocations.filter((p) => p.isTracking);

  return (
    <div className="relative flex h-full w-full items-center justify-center overflow-hidden bg-slate-950">
      {/* Precision Grid Layer */}
      <div
        className="pointer-events-none absolute inset-0 opacity-15"
        style={{
          backgroundImage: 'radial-gradient(circle at 1px 1px, #94a3b8 1px, transparent 0)',
          backgroundSize: `${24 * zoom}px ${24 * zoom}px`,
        }}
      />

      {/* Heatmap Legend & Zoom Controls */}
      <div className="absolute right-4 top-4 z-10 flex items-center gap-2 rounded-lg border border-slate-800 bg-slate-900/90 px-3 py-1.5 text-[11px] backdrop-blur">
        <button
          onClick={() => setShowHeatmap(!showHeatmap)}
          className={`flex items-center gap-1 rounded px-2 py-1 font-semibold transition ${
            showHeatmap ? 'bg-amber-500/20 text-amber-300' : 'text-slate-400 hover:bg-slate-800'
          }`}
        >
          <Flame className="h-3.5 w-3.5" />
          <span>Heatmap: {showHeatmap ? 'ON' : 'OFF'}</span>
        </button>
        <span className="text-slate-600">|</span>
        <button onClick={() => setZoom((z) => Math.max(0.7, +(z - 0.15).toFixed(2)))} className="px-1.5 text-slate-300 hover:text-white">-</button>
        <span className="text-slate-400">{Math.round(zoom * 100)}%</span>
        <button onClick={() => setZoom((z) => Math.min(1.6, +(z + 0.15).toFixed(2)))} className="px-1.5 text-slate-300 hover:text-white">+</button>
      </div>

      {/* Live Interactive Territory Vector Canvas */}
      <svg className="h-full w-full" style={{ transform: `scale(${zoom})`, transition: 'transform 150ms ease' }}>
        {territory ? (
          <g>
            {/* Dynamic Territory Polygon colored by Heatmap saturation */}
            <polygon
              points="260,170 560,150 610,390 240,420"
              className={`${fillClass} stroke-2 transition duration-300`}
            />

            {/* Heatmap Saturation Nodes when enabled */}
            {showHeatmap && (
              <g>
                <circle cx="350" cy="240" r={45 + progress * 35} fill="#10b981" opacity={0.14} />
                <circle cx="480" cy="280" r={38 + progress * 30} fill={progress < 0.4 ? '#ef4444' : '#f59e0b'} opacity={0.15} />
              </g>
            )}

            {/* Split Line Preview when Split Tool is active */}
            {activeTool === 'split' && (
              <g className="animate-pulse">
                <line x1="410" y1="120" x2="410" y2="450" stroke="#f59e0b" strokeWidth="2" strokeDasharray="6,4" />
                <circle cx="410" cy="160" r="4" fill="#f59e0b" />
                <circle cx="410" cy="405" r="4" fill="#f59e0b" />
              </g>
            )}

            {/* Start / Stop Boundary Markers */}
            <g transform="translate(260, 170)">
              <circle r={7} className="fill-emerald-400" />
              <text x={12} y={4} className="fill-emerald-300 text-[11px] font-bold">
                {territory.number} • {territory.name} ({Math.round(progress * 100)}%)
              </text>
            </g>

            {/* Shared Location Pins from Store */}
            {sharedPins.map((pin, idx) => (
              <g key={pin.id} transform={`translate(${310 + idx * 65}, ${315 - idx * 35})`}>
                <circle r={6} className="fill-cyan-400 stroke-slate-950 stroke-2" />
                <text x={10} y={4} className="fill-cyan-200 text-[10px] font-semibold">
                  PIN: {pin.title}
                </text>
              </g>
            ))}

            {/* Live Tracked Publishers from Store */}
            {activeTrackers.map((loc, idx) => (
              <g key={loc.id} transform={`translate(${390 + idx * 55}, ${245 + idx * 40})`}>
                <circle r={10} className="animate-ping fill-blue-500 opacity-50" />
                <circle r={6} className="fill-blue-400 stroke-white stroke-2" />
                <text x={10} y={4} className="fill-blue-200 text-[10px] font-bold">
                  {loc.displayName} ({loc.role})
                </text>
              </g>
            ))}
          </g>
        ) : (
          <text x="50%" y="50%" textAnchor="middle" className="fill-slate-500 text-xs">
            Create or select a territory to view boundaries, heatmap, pins & live publisher trackers
          </text>
        )}
      </svg>

      {/* Split Tool Action Card */}
      {activeTool === 'split' && territory && (
        <div className="absolute left-4 top-16 z-20 flex items-center gap-2 rounded-lg border border-amber-500/40 bg-slate-900/95 p-2 shadow-2xl backdrop-blur">
          <Scissors className="h-4 w-4 text-amber-400" />
          <span className="text-xs text-slate-200">Carve {territory.number} into #A & #B sectors</span>
          <button
            onClick={handleExecuteSplit}
            className="flex items-center gap-1 rounded bg-amber-600 px-2.5 py-1 text-[11px] font-bold text-white transition hover:bg-amber-500"
          >
            <Sparkles className="h-3 w-3" />
            <span>Execute Split</span>
          </button>
        </div>
      )}

      {/* Bottom Live Telemetry Strip */}
      <div className="absolute bottom-4 left-4 flex items-center gap-4 rounded-lg border border-slate-800 bg-slate-900/90 px-3.5 py-2 text-[11px] text-slate-300 backdrop-blur">
        <span className="flex items-center gap-1.5">
          <MapPin className="h-3.5 w-3.5 text-cyan-400" />
          <strong>{sharedPins.length}</strong> Shared Pins
        </span>
        <span className="flex items-center gap-1.5">
          <Radio className="h-3.5 w-3.5 text-emerald-400" />
          <strong>{activeTrackers.length}</strong> Live Publishers Tracked
        </span>
      </div>
    </div>
  );
};
