import '../models/music_models.dart';

final List<Song> mockSongs = [
  Song(
    id: '1',
    title: 'Midnight City',
    artist: 'M83',
    album: 'Hurry Up, We\'re Dreaming',
    thumbnailUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=1000&auto=format&fit=crop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    duration: const Duration(minutes: 4, seconds: 3),
    playCount: 1500,
    releaseDate: DateTime(2023, 10, 15),
  ),
  Song(
    id: '2',
    title: 'Starboy',
    artist: 'The Weeknd',
    album: 'Starboy',
    thumbnailUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=1000&auto=format&fit=crop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    duration: const Duration(minutes: 3, seconds: 50),
    playCount: 5000,
    releaseDate: DateTime(2016, 9, 22),
  ),
  Song(
    id: '3',
    title: 'Blinding Lights',
    artist: 'The Weeknd',
    album: 'After Hours',
    thumbnailUrl: 'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=1000&auto=format&fit=crop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    duration: const Duration(minutes: 3, seconds: 20),
    playCount: 8500,
    releaseDate: DateTime(2019, 11, 29),
  ),
];

final List<Artist> mockArtists = [
  Artist(
    id: '1',
    name: 'The Weeknd',
    imageUrl: 'https://images.unsplash.com/photo-1514525253361-b83a65c952c7?q=80&w=1000&auto=format&fit=crop',
    songIds: ['2', '3'],
    isFeatured: true,
  ),
  Artist(
    id: '2',
    name: 'M83',
    imageUrl: 'https://images.unsplash.com/photo-1459749411177-042180ce673b?q=80&w=1000&auto=format&fit=crop',
    songIds: ['1'],
  ),
  Artist(
    id: '3',
    name: 'Daft Punk',
    imageUrl: 'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=1000&auto=format&fit=crop',
    songIds: [],
  ),
];

final List<Album> mockAlbums = [
  Album(
    id: '1',
    title: 'Starboy',
    artist: 'The Weeknd',
    imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=1000&auto=format&fit=crop',
    songIds: ['2'],
    playCount: 20000,
    releaseDate: DateTime(2016, 11, 25),
  ),
  Album(
    id: '2',
    title: 'Hurry Up, We\'re Dreaming',
    artist: 'M83',
    imageUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=1000&auto=format&fit=crop',
    songIds: ['1'],
  ),
];
