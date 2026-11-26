import React, { useState } from 'react';
import { useTerritoryStore } from '../../stores/territoryStore';
import { SharedPin, PublisherMessage } from '../../types';
import { X, MapPin, Send, Trash2, Plus, Radio } from 'lucide-react';

interface ChatAndPinsModalProps {
  onClose: () => void;
}

export const ChatAndPinsModal: React.FC<ChatAndPinsModalProps> = ({ onClose }) => {
  const {
    activeCongregationId,
    publishers,
    activePublisherId,
    sharedPins,
    addSharedPin,
    deleteSharedPin,
    messages,
    sendMessage,
    deleteMessage,
    publisherLocations,
    togglePublisherTracking,
  } = useTerritoryStore();

  const activePub = publishers.find((p) => p.id === activePublisherId) || publishers[0];
  const [channel, setChannel] = useState<PublisherMessage['channel']>('field_service');
  const [msgText, setMsgText] = useState('');

  // Pin Form
  const [pinTitle, setPinTitle] = useState('');
  const [pinCat, setPinCat] = useState<SharedPin['category']>('meeting_point');
  const [pinLat, setPinLat] = useState('4.8210');
  const [pinLng, setPinLng] = useState('6.9880');
  const [pinNotes, setPinNotes] = useState('');

  const channelMessages = messages.filter((m) => m.channel === channel);

  const handleSend = (e: React.FormEvent) => {
    e.preventDefault();
    if (!msgText.trim()) return;
    sendMessage({
      congregationId: activeCongregationId,
      senderId: activePub?.id ?? 'desktop-admin',
      senderName: activePub?.displayName ?? 'Desktop Admin',
      senderRole: activePub?.role ?? 'elder',
      channel,
      body: msgText.trim(),
    });
    setMsgText('');
  };

  const handleDropPin = (e: React.FormEvent) => {
    e.preventDefault();
    if (!pinTitle.trim()) return;
    const lat = Number(pinLat) || 4.821;
    const lng = Number(pinLng) || 6.988;
    const pinId = addSharedPin({
      congregationId: activeCongregationId,
      createdBy: activePub?.displayName ?? 'Desktop Admin',
      title: pinTitle.trim(),
      category: pinCat,
      lat,
      lng,
      notes: pinNotes.trim(),
    });
    sendMessage({
      congregationId: activeCongregationId,
      senderId: activePub?.id ?? 'desktop-admin',
      senderName: activePub?.displayName ?? 'Desktop Admin',
      senderRole: activePub?.role ?? 'elder',
      channel,
      body: `Shared location pin "${pinTitle.trim()}" (${lat.toFixed(4)}, ${lng.toFixed(4)})`,
      pinId,
    });
    setPinTitle('');
    setPinNotes('');
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 p-6 backdrop-blur-sm">
      <div className="flex max-h-[88vh] w-full max-w-5xl flex-col rounded-xl border border-slate-700 bg-slate-900 shadow-2xl">
        <div className="flex items-center justify-between border-b border-slate-800 px-6 py-4">
          <div>
            <h2 className="text-sm font-bold text-white">Congregation Publisher Chat, Pin Sharing & Live Tracking</h2>
            <p className="text-[11px] text-slate-400">
              Coordinate territory coverage, drop field meeting pins, and monitor live active publisher tracking
            </p>
          </div>
          <button onClick={onClose} className="rounded p-1.5 text-slate-400 hover:bg-slate-800 hover:text-white">
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="grid flex-1 grid-cols-12 gap-5 overflow-hidden p-6 text-xs">
          {/* Left: Location Pins + Live Publishers */}
          <div className="col-span-5 flex flex-col gap-4 overflow-y-auto pr-1">
            <form onSubmit={handleDropPin} className="space-y-2.5 rounded-lg border border-slate-800 bg-slate-950/60 p-4">
              <div className="flex items-center gap-2 font-bold text-white">
                <MapPin className="h-4 w-4 text-emerald-400" />
                <span>Drop Shared Location Pin</span>
              </div>
              <input
                value={pinTitle}
                onChange={(e) => setPinTitle(e.target.value)}
                placeholder="Pin Label (e.g. Oakwood Meeting Point) *"
                className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-1.5 text-white"
                required
              />
              <select
                value={pinCat}
                onChange={(e) => setPinCat(e.target.value as SharedPin['category'])}
                className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-1.5 text-white"
              >
                <option value="meeting_point">Meeting Point</option>
                <option value="parking">Parking</option>
                <option value="rv_hotspot">RV Hotspot</option>
                <option value="cart_site">Cart Witnessing Site</option>
                <option value="hazard_gate">Hazard / Locked Gate</option>
              </select>
              <div className="grid grid-cols-2 gap-2">
                <input
                  value={pinLat}
                  onChange={(e) => setPinLat(e.target.value)}
                  placeholder="Lat"
                  className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-1.5 text-white"
                />
                <input
                  value={pinLng}
                  onChange={(e) => setPinLng(e.target.value)}
                  placeholder="Lng"
                  className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-1.5 text-white"
                />
              </div>
              <input
                value={pinNotes}
                onChange={(e) => setPinNotes(e.target.value)}
                placeholder="Instructions / directions"
                className="w-full rounded border border-slate-700 bg-slate-800 px-3 py-1.5 text-white"
              />
              <button
                type="submit"
                className="flex w-full items-center justify-center gap-1 rounded bg-emerald-600 py-1.5 font-semibold text-white hover:bg-emerald-500"
              >
                <Plus className="h-3.5 w-3.5" />
                <span>Share Pin</span>
              </button>
            </form>

            <div className="space-y-2">
              <div className="font-bold text-slate-300">Shared Congregation Pins ({sharedPins.length})</div>
              {sharedPins.map((pin) => (
                <div key={pin.id} className="flex items-start justify-between rounded border border-slate-800 bg-slate-800/40 p-2.5">
                  <div>
                    <div className="font-bold text-white">{pin.title}</div>
                    <div className="text-[11px] text-slate-400">
                      {pin.category} • {pin.lat.toFixed(4)}, {pin.lng.toFixed(4)}
                    </div>
                  </div>
                  <button
                    onClick={() => deleteSharedPin(pin.id)}
                    className="rounded p-1 text-slate-400 hover:text-red-400"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>
              ))}
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between font-bold text-slate-300">
                <span>Live Publisher Tracking</span>
                <button
                  onClick={() => togglePublisherTracking(activePub?.id ?? 'pub-elder-1')}
                  className="flex items-center gap-1 rounded bg-blue-600/20 px-2 py-0.5 text-[10px] text-blue-300 hover:bg-blue-600/40"
                >
                  <Radio className="h-3 w-3" />
                  <span>Toggle My Tracker</span>
                </button>
              </div>
              {publisherLocations.map((loc) => (
                <div key={loc.id} className="flex items-center justify-between rounded border border-slate-800 bg-slate-800/40 p-2.5">
                  <div>
                    <div className="font-semibold text-white">{loc.displayName}</div>
                    <div className="text-[10px] text-slate-400">
                      {loc.lat.toFixed(4)}, {loc.lng.toFixed(4)} • {loc.isTracking ? 'Live' : 'Paused'}
                    </div>
                  </div>
                  <span className={`h-2 w-2 rounded-full ${loc.isTracking ? 'bg-emerald-400' : 'bg-slate-600'}`} />
                </div>
              ))}
            </div>
          </div>

          {/* Right: Publisher Chat */}
          <div className="col-span-7 flex flex-col overflow-hidden rounded-lg border border-slate-800 bg-slate-950/60">
            <div className="flex gap-2 border-b border-slate-800 p-3">
              {(['field_service', 'general', 'territory_updates'] as const).map((ch) => (
                <button
                  key={ch}
                  onClick={() => setChannel(ch)}
                  className={`rounded px-2.5 py-1 text-[11px] font-semibold ${
                    channel === ch ? 'bg-emerald-600 text-white' : 'text-slate-400 hover:bg-slate-800'
                  }`}
                >
                  #{ch.replace('_', '-')}
                </button>
              ))}
            </div>

            <div className="flex-1 space-y-2.5 overflow-y-auto p-4">
              {channelMessages.map((m) => (
                <div key={m.id} className="rounded border border-slate-800 bg-slate-900 p-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-emerald-300">{m.senderName}</span>
                      <span className="rounded bg-slate-800 px-1.5 py-0.5 text-[10px] text-slate-400">{m.senderRole}</span>
                    </div>
                    <button onClick={() => deleteMessage(m.id)} className="text-slate-500 hover:text-red-400">
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </div>
                  <div className="mt-1 text-slate-200">{m.body}</div>
                </div>
              ))}
            </div>

            <form onSubmit={handleSend} className="flex gap-2 border-t border-slate-800 p-3">
              <input
                value={msgText}
                onChange={(e) => setMsgText(e.target.value)}
                placeholder="Write a message to your field group..."
                className="flex-1 rounded border border-slate-700 bg-slate-800 px-3 py-2 text-white"
              />
              <button
                type="submit"
                className="flex items-center gap-1 rounded bg-emerald-600 px-4 py-2 font-semibold text-white hover:bg-emerald-500"
              >
                <Send className="h-3.5 w-3.5" />
                <span>Send</span>
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
};
