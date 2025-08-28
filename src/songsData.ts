export interface Song {
  id: number;
  name: string;
  tempo: number;
  editing: boolean;
}

const STORAGE_KEY = 'gigitime-songs';

// Default songs data
const defaultSongs: Song[] = [
  { id: 1, name: "Juniors wailing – Status Quo", tempo: 135, editing: false },
  { id: 2, name: "Sharp dressed man - Nickelback", tempo: 127, editing: false },
  { id: 3, name: "Wiskey in the jar", tempo: 129, editing: false },
  { id: 4, name: "Shout", tempo: 94, editing: false },
  { id: 5, name: "I want to break free", tempo: 119, editing: false },
  { id: 6, name: "Behind blue eyes", tempo: 124, editing: false },
  { id: 7, name: "Pretty woman", tempo: 126, editing: false },
  { id: 8, name: "Eye in the sky", tempo: 122, editing: false },
  { id: 9, name: "What's a woman", tempo: 100, editing: false },
  { id: 10, name: "Ran so far away", tempo: 120, editing: false },
  { id: 11, name: "Summer of 69", tempo: 128, editing: false },
  { id: 12, name: "Don't bring me down", tempo: 119, editing: false },
  { id: 13, name: "Hold the line", tempo: 102, editing: false },
  { id: 14, name: "The best", tempo: 104, editing: false },
  { id: 15, name: "Every breath you take", tempo: 117, editing: false },
  { id: 16, name: "Beat it", tempo: 139, editing: false },
  { id: 17, name: "Call me", tempo: 139, editing: false },
  { id: 18, name: "Sweet dreams", tempo: 120, editing: false },
  { id: 19, name: "Livin on a prayer, Poison, The final countdown", tempo: 120, editing: false },
];

// Load songs from localStorage or return default songs
export function loadSongs(): Song[] {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      const parsed = JSON.parse(stored);
      // Ensure all songs have the required properties
      return parsed.map((song: any) => ({
        id: song.id || Date.now(),
        name: song.name || '',
        tempo: song.tempo || 90,
        editing: false // Always reset editing state on load
      }));
    }
  } catch (error) {
    console.error('Error loading songs from localStorage:', error);
  }
  return defaultSongs;
}

// Save songs to localStorage
export function saveSongs(songs: Song[]): void {
  try {
    // Remove editing state before saving
    const songsToSave = songs.map(song => ({
      id: song.id,
      name: song.name,
      tempo: song.tempo
    }));
    localStorage.setItem(STORAGE_KEY, JSON.stringify(songsToSave));
  } catch (error) {
    console.error('Error saving songs to localStorage:', error);
  }
}

// Add a new song
export function addSong(songs: Song[], name: string, tempo: number): Song[] {
  const newSong: Song = {
    id: Date.now(),
    name: name.trim(),
    tempo: Math.max(30, Math.min(240, tempo)),
    editing: false
  };
  const updatedSongs = [...songs, newSong];
  saveSongs(updatedSongs);
  return updatedSongs;
}

// Update a song
export function updateSong(songs: Song[], id: number, updates: Partial<Song>): Song[] {
  const updatedSongs = songs.map(song => 
    song.id === id ? { ...song, ...updates } : song
  );
  saveSongs(updatedSongs);
  return updatedSongs;
}

// Delete a song
export function deleteSong(songs: Song[], id: number): Song[] {
  const updatedSongs = songs.filter(song => song.id !== id);
  saveSongs(updatedSongs);
  return updatedSongs;
}

// Reorder songs (for drag and drop)
export function reorderSongs(songs: Song[], fromId: number, toId: number): Song[] {
  const fromIndex = songs.findIndex(song => song.id === fromId);
  const toIndex = songs.findIndex(song => song.id === toId);
  
  if (fromIndex === -1 || toIndex === -1) return songs;
  
  const updatedSongs = [...songs];
  const [moved] = updatedSongs.splice(fromIndex, 1);
  updatedSongs.splice(toIndex, 0, moved);
  
  saveSongs(updatedSongs);
  return updatedSongs;
}

// Reset to default songs
export function resetToDefaultSongs(): Song[] {
  saveSongs(defaultSongs);
  return defaultSongs;
}
