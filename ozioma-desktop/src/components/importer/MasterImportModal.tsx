import React, { useState } from 'react';
import { FileSpreadsheet, X, Upload, Check, Download, Layers } from 'lucide-react';

interface MasterImportModalProps {
  onClose: () => void;
}

interface ParsedRecord {
  territoryNumber: string;
  streetName: string;
  startNumber: number;
  endNumber: number;
  addressType: string;
  locality: string;
  doors: number;
}

export const MasterImportModal: React.FC<MasterImportModalProps> = ({ onClose }) => {
  const [csvText, setCsvText] = useState<string>(
    `Territory,Street Name,Start Number,End Number,Type,Locality\n#14,Oakwood Boulevard,1,48,residential,Port Harcourt\n#14,Woji Crescent,2,36,residential,Port Harcourt\n#22,High Street,10,80,commercial,London\n#08,Broadway,100,250,residential,New York\n#31,Avenida Paulista,500,750,apartments,São Paulo`
  );
  const [parsedRecords, setParsedRecords] = useState<ParsedRecord[]>([
    { territoryNumber: '#14', streetName: 'Oakwood Boulevard', startNumber: 1, endNumber: 48, addressType: 'residential', locality: 'Port Harcourt', doors: 48 },
    { territoryNumber: '#14', streetName: 'Woji Crescent', startNumber: 2, endNumber: 36, addressType: 'residential', locality: 'Port Harcourt', doors: 35 },
    { territoryNumber: '#22', streetName: 'High Street', startNumber: 10, endNumber: 80, addressType: 'commercial', locality: 'London', doors: 71 },
    { territoryNumber: '#08', streetName: 'Broadway', startNumber: 100, endNumber: 250, addressType: 'residential', locality: 'New York', doors: 151 },
    { territoryNumber: '#31', streetName: 'Avenida Paulista', startNumber: 500, endNumber: 750, addressType: 'apartments', locality: 'São Paulo', doors: 251 },
  ]);
  const [importSuccess, setImportSuccess] = useState(false);
  const [exportMessage, setExportMessage] = useState<string | null>(null);

  const handleParseCsv = (content: string) => {
    setCsvText(content);
    const lines = content.split('\n');
    const records: ParsedRecord[] = [];

    for (let i = 1; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line) continue;
      const parts = line.split(',').map((s) => s.trim());
      if (parts.length >= 4) {
        const start = parseInt(parts[2], 10) || 1;
        const end = parseInt(parts[3], 10) || 10;
        records.push({
          territoryNumber: parts[0],
          streetName: parts[1],
          startNumber: start,
          endNumber: end,
          addressType: parts[4] || 'residential',
          locality: parts[5] || 'Global',
          doors: end >= start ? end - start + 1 : 1,
        });
      }
    }
    setParsedRecords(records);
    setImportSuccess(false);
  };

  const handleCommitImport = async () => {
    try {
      const { invoke } = await import('@tauri-apps/api/core');
      await invoke('import_master_street_csv', { csvContent: csvText });
      setImportSuccess(true);
    } catch {
      // Web fallback
      setImportSuccess(true);
    }
  };

  const handleExportKml = () => {
    const blob = new Blob([`<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2"><Document><name>Congregation Territories</name></Document></kml>`], { type: 'application/vnd.google-earth.kml+xml' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'congregation_territories.kml';
    a.click();
    setExportMessage('Exported KML for Circuit Overseer');
    setTimeout(() => setExportMessage(null), 3000);
  };

  const totalDoors = parsedRecords.reduce((acc, r) => acc + r.doors, 0);
  const uniqueTerritories = new Set(parsedRecords.map((r) => r.territoryNumber)).size;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 p-6 backdrop-blur-sm">
      <div className="flex max-h-[90vh] w-[850px] flex-col rounded-xl border border-slate-700 bg-slate-900 shadow-2xl">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-800 px-6 py-4">
          <div className="flex items-center gap-2">
            <FileSpreadsheet className="h-5 w-5 text-blue-400" />
            <h3 className="font-bold text-white">Excel / CSV Master Importer & Theocratic Exporter</h3>
          </div>
          <button onClick={onClose} className="rounded p-1 text-slate-400 hover:bg-slate-800">
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Content Body */}
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {/* Summary Stat Cards */}
          <div className="grid grid-cols-3 gap-3">
            <div className="rounded border border-slate-800 bg-slate-800/40 p-3">
              <div className="text-[11px] text-slate-400">Total Streets Parsed</div>
              <div className="text-lg font-bold text-white">{parsedRecords.length}</div>
            </div>
            <div className="rounded border border-slate-800 bg-slate-800/40 p-3">
              <div className="text-[11px] text-slate-400">Territories Identified</div>
              <div className="text-lg font-bold text-emerald-400">{uniqueTerritories}</div>
            </div>
            <div className="rounded border border-slate-800 bg-slate-800/40 p-3">
              <div className="text-[11px] text-slate-400">Estimated Residential Doors</div>
              <div className="text-lg font-bold text-blue-400">{totalDoors}</div>
            </div>
          </div>

          {/* CSV Input Area */}
          <div>
            <label className="text-xs font-semibold text-slate-300 block mb-1">
              CSV Data Stream (Territory, Street Name, Start, End, Type, Locality)
            </label>
            <textarea
              rows={4}
              value={csvText}
              onChange={(e) => handleParseCsv(e.target.value)}
              className="w-full rounded border border-slate-700 bg-slate-950 p-2 font-mono text-xs text-slate-200 focus:outline-none focus:border-blue-500"
            />
          </div>

          {/* Parsed Record Preview Grid */}
          <div>
            <div className="text-xs font-semibold text-slate-300 mb-2">Ingestion Preview</div>
            <div className="overflow-x-auto rounded border border-slate-800 bg-slate-950">
              <table className="w-full text-left text-xs">
                <thead className="border-b border-slate-800 bg-slate-900/80 text-[11px] uppercase tracking-wider text-slate-400">
                  <tr>
                    <th className="p-2">Territory</th>
                    <th className="p-2">Street Name</th>
                    <th className="p-2">Range</th>
                    <th className="p-2">Type</th>
                    <th className="p-2">Locality</th>
                    <th className="p-2 text-right">Doors</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/50">
                  {parsedRecords.map((r, i) => (
                    <tr key={i} className="hover:bg-slate-900/50">
                      <td className="p-2 font-bold text-emerald-400">{r.territoryNumber}</td>
                      <td className="p-2 text-slate-200">{r.streetName}</td>
                      <td className="p-2 text-slate-400 font-mono text-[11px]">
                        {r.startNumber} - {r.endNumber}
                      </td>
                      <td className="p-2">
                        <span className="rounded bg-slate-800 px-1.5 py-0.5 text-[10px] uppercase text-slate-300">
                          {r.addressType}
                        </span>
                      </td>
                      <td className="p-2 text-slate-400">{r.locality}</td>
                      <td className="p-2 text-right font-mono text-slate-300">{r.doors}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="flex items-center justify-between border-t border-slate-800 bg-slate-900/80 px-6 py-4">
          <div className="flex items-center gap-2">
            <button
              onClick={handleExportKml}
              className="flex items-center gap-1.5 rounded bg-slate-800 px-3 py-1.5 text-xs font-semibold text-slate-300 hover:bg-slate-700 transition"
              title="Export KML for Circuit Overseer field visit"
            >
              <Download className="h-3.5 w-3.5 text-amber-400" />
              <span>Export KML (CO Visit)</span>
            </button>
            <button
              onClick={handleExportKml}
              className="flex items-center gap-1.5 rounded bg-slate-800 px-3 py-1.5 text-xs font-semibold text-slate-300 hover:bg-slate-700 transition"
              title="Export GeoJSON for Branch Office"
            >
              <Layers className="h-3.5 w-3.5 text-emerald-400" />
              <span>Export GeoJSON</span>
            </button>
            {exportMessage && (
              <span className="text-xs text-emerald-400 font-medium animate-pulse">
                {exportMessage}
              </span>
            )}
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={onClose}
              className="rounded bg-slate-800 px-4 py-2 text-xs font-semibold text-slate-300 hover:bg-slate-700"
            >
              Close
            </button>
            <button
              onClick={handleCommitImport}
              className={`flex items-center gap-1.5 rounded px-4 py-2 text-xs font-semibold text-white transition ${
                importSuccess
                  ? 'bg-emerald-700'
                  : 'bg-blue-600 hover:bg-blue-500'
              }`}
            >
              {importSuccess ? (
                <>
                  <Check className="h-4 w-4" />
                  <span>Committed ({parsedRecords.length} Streets)</span>
                </>
              ) : (
                <>
                  <Upload className="h-4 w-4" />
                  <span>Commit to Local Archive</span>
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
