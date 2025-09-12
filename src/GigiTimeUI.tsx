import React, { useEffect, useRef, useState, useCallback } from "react";
import { Play, Square, Plus, Minus, Pencil, Trash2, Save, GripVertical, Music, RotateCcw, HelpCircle, ChevronLeft, ChevronRight } from "lucide-react";
import { Song, loadSongs, addSong as addSongToStorage, updateSong as updateSongInStorage, deleteSong as deleteSongFromStorage, reorderSongs as reorderSongsInStorage, resetToDefaultSongs } from "./songsData";

// Embedded drummer photo path (loads directly from your attached file in this workspace)
const DRUMMER_PHOTO = "/images/Gigi.png";

// Debug: Log the image path to console
console.log("Drummer photo path:", DRUMMER_PHOTO);

const clamp = (v: number, min: number, max: number) => Math.max(min, Math.min(max, v));

export default function GigiTimeUIMock() {
  // Core state
  const [tempo, setTempo] = useState(90);
  const [running, setRunning] = useState(false);
  const [currentBeat, setCurrentBeat] = useState(1);
  const [selectedSongId, setSelectedSongId] = useState<number | null>(null);

  // Add-song draft
  const [draftName, setDraftName] = useState("");
  const [draftTempo, setDraftTempo] = useState(90);

  // Songs - loaded from external storage
  const [songs, setSongs] = useState<Song[]>(() => loadSongs());

  // Tips modal state
  const [showTips, setShowTips] = useState(false);

  // Selecting a song loads its tempo & highlights
  const selectSong = useCallback((song: { id: number; tempo: number }) => {
    setTempo(clamp(song.tempo, 30, 240));
    setSelectedSongId(song.id);
  }, []);

  // Select first song on app launch
  useEffect(() => {
    if (songs.length > 0 && selectedSongId === null) {
      selectSong(songs[0]);
    }
  }, [songs, selectedSongId, selectSong]);

  // Beat blink (visual metronome)
  useEffect(() => {
    if (!running) return;
    const msPerBeat = 60000 / tempo;
    const timer = setInterval(() => setCurrentBeat((b) => (b === 1 ? 2 : 1)), msPerBeat);
    return () => clearInterval(timer);
  }, [running, tempo]);

  // Keyboard shortcuts
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      // Check if user is editing a song (allow spacebar in input fields)
      const target = e.target as HTMLElement;
      const isEditingSong = target.tagName === 'INPUT' && target.closest('.song-edit-form');

      if (e.key === " " && !isEditingSong) {
        e.preventDefault();
        setRunning((r) => !r);
      }
      if (e.key === "+" || e.key === "=") setTempo((t) => clamp(t + 1, 30, 240));
      if (e.key === "-") setTempo((t) => clamp(t - 1, 30, 240));
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  // Add / remove songs
  const addSong = () => {
    const name = draftName.trim();
    const t = clamp(Number(draftTempo) || tempo, 30, 240);
    if (!name) return;
    const updatedSongs = addSongToStorage(songs, name, t);
    setSongs(updatedSongs);
    setDraftName("");
    setDraftTempo(tempo);
  };
  const removeSong = (id: number) => {
    const updatedSongs = deleteSongFromStorage(songs, id);
    setSongs(updatedSongs);
  };

  // Start/Stop & tempo controls
  const start = () => setRunning(true);
  const stop = () => setRunning(false);
  const inc = (d = 1) => setTempo((t) => clamp(t + d, 30, 240));
  const dec = (d = 1) => setTempo((t) => clamp(t - d, 30, 240));

  // Navigation functions
  const goToPreviousSong = () => {
    if (selectedSongId === null || songs.length === 0) return;
    const currentIndex = songs.findIndex(song => song.id === selectedSongId);
    if (currentIndex > 0) {
      selectSong(songs[currentIndex - 1]);
    }
  };

  const goToNextSong = () => {
    if (selectedSongId === null || songs.length === 0) return;
    const currentIndex = songs.findIndex(song => song.id === selectedSongId);
    if (currentIndex < songs.length - 1) {
      selectSong(songs[currentIndex + 1]);
    }
  };

  // Drag & drop ordering
  const dragIdRef = useRef<number | null>(null);
  const onDragStart = (id: number) => (e: React.DragEvent) => {
    dragIdRef.current = id;
    e.dataTransfer.effectAllowed = "move";
  };
  const onDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = "move";
  };
  const onDrop = (overId: number) => (e: React.DragEvent) => {
    e.preventDefault();
    const fromId = dragIdRef.current;
    if (fromId == null || fromId === overId) return;
    const updatedSongs = reorderSongsInStorage(songs, fromId, overId);
    setSongs(updatedSongs);
    dragIdRef.current = null;
  };

  return (
    <div className="app-container">
      {/* Header */}
      <header className="app-header">
        <div className="header-content">
          <div className="drummer-thumbnail">
            <img
              src={DRUMMER_PHOTO}
              alt="Drummer"
              onError={(e) => {
                console.error("Image failed to load:", e);
                console.error("Image path attempted:", DRUMMER_PHOTO);
              }}
              onLoad={() => console.log("Image loaded successfully from:", DRUMMER_PHOTO)}
              style={{ border: '2px solid red' }} // Temporary debug border
            />
          </div>
          <div className="brand">
            <h1>GIGI‑TIME</h1>
            <p>Rock‑solid metronome for Gigi</p>
          </div>
          <button
            className="help-button"
            onClick={() => setShowTips(!showTips)}
            aria-label="Show quick tips"
            title="Quick Tips"
          >
            <HelpCircle />
          </button>
        </div>
      </header>

      {/* Tips Modal */}
      {showTips && (
        <div className="tips-modal-overlay" onClick={() => setShowTips(false)}>
          <div className="tips-modal" onClick={(e) => e.stopPropagation()}>
            <div className="tips-modal-header">
              <h3>Quick Tips</h3>
              <button
                className="close-button"
                onClick={() => setShowTips(false)}
                aria-label="Close tips"
              >
                ×
              </button>
            </div>
            <ul className="tips-list">
              <li className="tip-item">
                <span className="tip-bullet"></span>
                <span>Big, high‑contrast buttons and 2‑beat focus for simple practice.</span>
              </li>
              <li className="tip-item">
                <span className="tip-bullet"></span>
                <span>Use +/- or the slider to fine‑tune tempo (30–240 BPM).</span>
              </li>
              <li className="tip-item">
                <span className="tip-bullet"></span>
                <span>Tap a song to load its BPM; drag the grip icon to re‑order the setlist.</span>
              </li>
              <li className="tip-item">
                <span className="tip-bullet"></span>
                <span>Pencil edits; trash removes. Spacebar toggles start/stop.</span>
              </li>
            </ul>
          </div>
        </div>
      )}

      {/* Main content */}
      <main className="app-main">
        {/* Controls */}
        <section className="controls-section">
          {/* Selected Song Display */}
          {selectedSongId && (
            <div className="selected-song-display">
              <button
                className="nav-button nav-button-left"
                onClick={goToPreviousSong}
                disabled={songs.findIndex(s => s.id === selectedSongId) === 0}
                aria-label="Previous song"
              >
                <ChevronLeft />
              </button>
              <div className="selected-song-name">
                {songs.find(s => s.id === selectedSongId)?.name}
              </div>
              <button
                className="nav-button nav-button-right"
                onClick={goToNextSong}
                disabled={songs.findIndex(s => s.id === selectedSongId) === songs.length - 1}
                aria-label="Next song"
              >
                <ChevronRight />
              </button>
            </div>
          )}

          <div className="tempo-display">
            <div>
              <div className="tempo-label">Tempo</div>
              <div className="tempo-value" aria-live="polite">
                {tempo} <span className="tempo-unit">BPM</span>
              </div>
            </div>
            <div className="tempo-buttons-row">
              <button
                onClick={() => dec(5)}
                className="tempo-button-coarse"
                aria-label="Decrease tempo by 5"
              >
                -5
              </button>
              <button
                onClick={() => dec(1)}
                className="tempo-button"
                aria-label="Decrease tempo"
              >
                <Minus />
              </button>
              <button
                onClick={() => inc(1)}
                className="tempo-button"
                aria-label="Increase tempo"
              >
                <Plus />
              </button>
              <button
                onClick={() => inc(5)}
                className="tempo-button-coarse"
                aria-label="Increase tempo by 5"
              >
                +5
              </button>
            </div>
          </div>

          <div className="control-buttons-mini">
            <button
              onClick={start}
              disabled={running}
              className={`control-button-mini control-start-button-mini ${running ? 'disabled' : ''}`}
              aria-label="Start metronome"
            >
              <Play fill={running ? "none" : "white"} />&nbsp;&nbsp;Start
            </button>
            <button
              onClick={stop}
              disabled={!running}
              className={`control-button-mini control-stop-button-mini ${!running ? 'disabled' : ''}`}
              aria-label="Stop metronome"
            >
              <Square fill={!running ? "none" : "white"} />&nbsp;&nbsp;Stop
            </button>

            <div className="tempo-slider-container">
              <input
                type="range"
                min={30}
                max={240}
                value={tempo}
                onChange={(e) => setTempo(Number(e.target.value))}
                className="tempo-slider"
                aria-label="Tempo slider"
              />
              <div className="tempo-range">
                <span>30</span>
                <span>240</span>
              </div>
            </div>
          </div>
          <div className="beat-buttons">
            {[1, 2].map((b) => (
              <button
                key={b}
                className={running && currentBeat === b ? "beat-button active" : "beat-button inactive"}
                aria-pressed={running && currentBeat === b}
              >
                {b}
              </button>
            ))}
          </div>
        </section>

        {/* Songs */}
        <section className="media-section">
          <div className="songs-container">
            <div className="songs-header">
              <div className="songs-header-left">
                <Music className="songs-icon" />
                <h2 className="songs-title">Songs</h2>
              </div>
              <button
                className="reset-button"
                onClick={() => {
                  const updatedSongs = resetToDefaultSongs();
                  setSongs(updatedSongs);
                }}
                title="Reset to default songs"
              >
                <RotateCcw className="reset-icon" />
              </button>
            </div>

            <div className="songs-form">
              <div className="form-group">
                <label>Song name</label>
                <input
                  value={draftName}
                  onChange={(e) => setDraftName(e.target.value)}
                  placeholder="e.g., My Way"
                />
              </div>
              <div className="form-group tempo-input">
                <label>Tempo</label>
                <input
                  type="number"
                  min={30}
                  max={240}
                  value={draftTempo}
                  onChange={(e) => setDraftTempo(Number(e.target.value))}
                />
              </div>
              <button
                onClick={addSong}
                className="save-button"
              >
                <Save className="save-icon" /> Save
              </button>
            </div>

            <ul className="songs-list">
              {songs.map((s) => (
                <li
                  key={s.id}
                  draggable
                  onDragStart={onDragStart(s.id)}
                  onDragOver={onDragOver}
                  onDrop={onDrop(s.id)}
                  className={`song-item ${selectedSongId === s.id ? 'selected' : ''}`}
                  onClick={() => selectSong(s)}
                >
                  <GripVertical className="grip-icon" />
                  {s.editing ? (
                    <div className="song-edit-form">
                      <input
                        className="song-edit-input"
                        value={s.name}
                        onChange={(e) => {
                          const updatedSongs = updateSongInStorage(songs, s.id, { name: e.target.value });
                          setSongs(updatedSongs);
                        }}
                      />
                      <input
                        type="number"
                        min={30}
                        max={240}
                        className="song-edit-tempo"
                        value={s.tempo}
                        onChange={(e) => {
                          const updatedSongs = updateSongInStorage(songs, s.id, { tempo: Number(e.target.value) });
                          setSongs(updatedSongs);
                        }}
                      />
                      <button
                        className="done-button"
                        onClick={(e) => {
                          e.stopPropagation();
                          const updatedSongs = updateSongInStorage(songs, s.id, { editing: false });
                          setSongs(updatedSongs);
                        }}
                      >
                        Done
                      </button>
                    </div>
                  ) : (
                    <>
                      <div className="song-info">
                        <div className="song-name">{s.name}</div>
                        <div className="song-tempo">{s.tempo} BPM</div>
                      </div>
                      <div className="song-actions">
                        <button
                          className="edit-button"
                          aria-label={`Edit ${s.name}`}
                          onClick={(e) => {
                            e.stopPropagation();
                            const updatedSongs = updateSongInStorage(songs, s.id, { editing: true });
                            setSongs(updatedSongs);
                          }}
                        >
                          <Pencil className="edit-icon" />
                        </button>
                        <button
                          className="delete-button"
                          aria-label={`Remove ${s.name}`}
                          onClick={(e) => { e.stopPropagation(); removeSong(s.id); }}
                        >
                          <Trash2 className="delete-icon" />
                        </button>
                      </div>
                    </>
                  )}
                </li>
              ))}
            </ul>
          </div>
        </section>
      </main>

    </div>
  );
}
