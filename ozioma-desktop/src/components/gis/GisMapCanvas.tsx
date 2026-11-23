import React from 'react';
import { Territory } from '../../types';

interface GisMapCanvasProps {
  territory?: Territory;
  activeTool: string;
}

export const GisMapCanvas: React.FC<GisMapCanvasProps> = ({ territory, activeTool }) => {
  return (
    <div className="relative h-full w-full bg-slate-950 flex items-center justify-center overflow-hidden">
      {/* Precision Grid Layer */}
      <div
        className="absolute inset-0 opacity-10 pointer-events-none"
        style={{
          backgroundImage:
            'radial-gradient(circle at 1px 1px, #94a3b8 1px, transparent 0)',
          backgroundSize: '24px 24px',
        }}
      />

      {/* Vector Geometry Canvas Simulation */}
      <svg className="h-full w-full">
        {territory && (
          <g>
            {/* Shaded Territory Polygon */}
            <polygon
              points="280,180 540,160 590,380 260,410"
              className="fill-emerald-500/15 stroke-emerald-400 stroke-2 transition duration-300"
            />
            {/* Vertex Nodes for Mouse Dragging */}
            {[
              [280, 180],
              [540, 160],
              [590, 380],
              [260, 410],
            ].map(([x, y], i) => (
              <circle
                key={i}
                cx={x}
                cy={y}
                r={5}
                className="fill-white stroke-emerald-600 stroke-2 cursor-move hover:scale-125 transition"
              />
            ))}

            {/* Start Pin */}
            <g transform="translate(280, 180)">
              <circle r={8} className="fill-emerald-500 animate-ping opacity-75" />
              <circle r={6} className="fill-emerald-400" />
              <text x={12} y={4} className="fill-emerald-300 text-[11px] font-bold">
                START: Oakwood Gate
              </text>
            </g>

            {/* Stop Pin */}
            <g transform="translate(590, 380)">
              <circle r={6} className="fill-red-500" />
              <text x={12} y={4} className="fill-red-300 text-[11px] font-bold">
                STOP: Woji Corner
              </text>
            </g>
          </g>
        )}
      </svg>

      {/* Bottom GIS Status Coordinate Bar */}
      <div className="absolute bottom-3 left-4 right-4 flex items-center justify-between text-[11px] text-slate-500 bg-slate-900/80 px-3 py-1.5 rounded border border-slate-800 backdrop-blur">
        <div>
          Tool: <span className="text-emerald-400 font-semibold uppercase">{activeTool}</span> | Projection: EPSG:4326 | Coordinates: 4.8210° N, 6.9882° E
        </div>
        <div className="flex gap-4">
          <span>Area: 14.8 Hectares</span>
          <span>Zoom: 16.4x</span>
          <span>Native Rust GIS: Active</span>
        </div>
      </div>
    </div>
  );
};
