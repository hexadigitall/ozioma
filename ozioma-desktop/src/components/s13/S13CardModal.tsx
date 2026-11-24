import React, { useState } from 'react';
import { Territory } from '../../types';
import { Printer, X, Check, Loader2 } from 'lucide-react';

interface S13CardModalProps {
  territory: Territory;
  onClose: () => void;
}

export const S13CardModal: React.FC<S13CardModalProps> = ({ territory, onClose }) => {
  const [isPrinting, setIsPrinting] = useState(false);
  const [printSuccess, setPrintSuccess] = useState(false);

  const handlePrint = async () => {
    setIsPrinting(true);
    setPrintSuccess(false);

    try {
      const { invoke } = await import('@tauri-apps/api/core');
      await invoke('generate_s13_pdf', {
        territoryNumber: territory.number,
        territoryName: territory.name,
        congregationName: 'Rumuola Congregation',
        outputPath: `S13_${territory.number.replace('#', '')}.pdf`,
      });
      setPrintSuccess(true);
    } catch (err) {
      console.warn('Native Tauri PDF spooler fallback to browser print:', err);
      window.print();
      setPrintSuccess(true);
    } finally {
      setIsPrinting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 p-6 backdrop-blur-sm">
      <div className="flex max-h-[90vh] w-[750px] flex-col rounded-xl border border-slate-700 bg-slate-900 shadow-2xl">
        <div className="flex items-center justify-between border-b border-slate-800 px-6 py-4">
          <div className="flex items-center gap-2">
            <Printer className="h-5 w-5 text-emerald-400" />
            <h3 className="font-bold text-white">S-13 Territory Card Vector Spooler</h3>
          </div>
          <button onClick={onClose} className="rounded p-1 text-slate-400 hover:bg-slate-800">
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Card Vector Preview (Standard Theocratic S-13 Card Layout) */}
        <div className="flex-1 overflow-y-auto p-6 flex justify-center">
          <div className="w-[500px] bg-white text-slate-900 p-6 rounded shadow border border-slate-300 font-sans text-xs print:w-full print:shadow-none print:border-none">
            {/* Header */}
            <div className="border-b-2 border-slate-900 pb-2 flex justify-between items-start">
              <div>
                <h1 className="text-base font-extrabold tracking-wide uppercase">
                  TERRITORY ASSIGNMENT CARD
                </h1>
                <p className="text-[10px] text-slate-600">Form S-13 (Rumuola Congregation)</p>
              </div>
              <div className="text-right">
                <span className="text-xl font-black text-slate-900">{territory.number}</span>
              </div>
            </div>

            {/* Territory Metadata */}
            <div className="mt-3 grid grid-cols-2 gap-2 text-[11px]">
              <div>
                <span className="font-bold">Territory Name:</span> {territory.name}
              </div>
              <div>
                <span className="font-bold">Locality:</span> {territory.region}
              </div>
            </div>

            {/* Vector Map Preview Box */}
            <div className="mt-3 h-48 w-full border border-slate-400 rounded bg-slate-100 flex items-center justify-center relative overflow-hidden">
              <div className="absolute inset-2 border border-dashed border-emerald-600 rounded flex items-center justify-center text-slate-400 text-xs font-mono">
                [High-Resolution Vector Boundary Map]
              </div>
              <div className="absolute bottom-2 right-2 bg-white px-2 py-0.5 rounded text-[9px] font-bold border border-slate-300">
                QR: Mobile Import
              </div>
            </div>

            {/* Boundary Streets */}
            <div className="mt-3 text-[10px] text-slate-700">
              <span className="font-bold">Boundary Streets:</span> North: Oakwood Boulevard • East: Woji Road • South: Trans-Amadi Expressway • West: Phase 2 Canal
            </div>

            {/* Assignment History Table */}
            <table className="mt-4 w-full border-collapse border border-slate-300 text-[10px]">
              <thead>
                <tr className="bg-slate-100">
                  <th className="border border-slate-300 p-1 text-left">Assigned To</th>
                  <th className="border border-slate-300 p-1">Date Assigned</th>
                  <th className="border border-slate-300 p-1">Date Completed</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td className="border border-slate-300 p-1">{territory.assignedTo || 'Bro. Emeka Okon'}</td>
                  <td className="border border-slate-300 p-1 text-center">{territory.assignedDate || '12-Oct-2026'}</td>
                  <td className="border border-slate-300 p-1 text-center">—</td>
                </tr>
                <tr>
                  <td className="border border-slate-300 p-1 text-slate-400">&nbsp;</td>
                  <td className="border border-slate-300 p-1">&nbsp;</td>
                  <td className="border border-slate-300 p-1">&nbsp;</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        {/* Modal Actions */}
        <div className="flex items-center justify-between border-t border-slate-800 bg-slate-900/80 px-6 py-4">
          <div className="text-xs text-slate-400">
            Layout: 4-up Duplex A4 Vector PDF Spooler (Rust `printpdf`)
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={onClose}
              className="rounded bg-slate-800 px-4 py-2 text-xs font-semibold hover:bg-slate-700"
            >
              Cancel
            </button>
            <button
              onClick={handlePrint}
              disabled={isPrinting}
              className={`flex items-center gap-1.5 rounded px-4 py-2 text-xs font-semibold text-white transition ${
                printSuccess
                  ? 'bg-emerald-700'
                  : 'bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50'
              }`}
            >
              {isPrinting ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  <span>Spooling Vector PDF...</span>
                </>
              ) : printSuccess ? (
                <>
                  <Check className="h-4 w-4" />
                  <span>Spool Ready</span>
                </>
              ) : (
                <>
                  <Printer className="h-4 w-4" />
                  <span>Spool to Printer</span>
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
