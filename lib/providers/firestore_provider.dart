import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/music_models.dart';
import '../models/mock_data.dart';
import '../providers/auth_provider.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Song>> getSongs() {
    return _db.collection('songs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Song.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Artist>> getArtists() {
    return _db.collection('artists').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Artist.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Playlist>> getPlaylists() {
    return _db.collection('playlists').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Playlist.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Album>> getAlbums() {
    return _db.collection('albums').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Album.fromFirestore(doc)).toList();
    });
  }

  Future<void> updatePlaylistLibrary(String playlistId, bool isAdding) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final docRef = _db.collection('users').doc(uid);
    
    if (isAdding) {
      await docRef.set({
        'libraryPlaylists': FieldValue.arrayUnion([playlistId])
      }, SetOptions(merge: true));
    } else {
      await docRef.set({
        'libraryPlaylists': FieldValue.arrayRemove([playlistId])
      }, SetOptions(merge: true));
    }
  }

  Future<Playlist> createPlaylist(String name, List<String> initialSongIds) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) throw Exception('Not logged in');
    
    final docRef = await _db.collection('playlists').add({
      'name': name,
      'imageUrl': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&q=80', // Default cover
      'createdBy': user?.displayName ?? 'Basal User',
      'creatorUid': uid,
      'description': '',
      'songs': initialSongIds,
    });
    
    // Automatically add to user's library when created
    await updatePlaylistLibrary(docRef.id, true);
    final doc = await docRef.get();
    return Playlist.fromFirestore(doc);
  }

  Future<void> addSongsToPlaylist(String playlistId, List<String> newSongIds) async {
    final docRef = _db.collection('playlists').doc(playlistId);
    await docRef.update({
      'songs': FieldValue.arrayUnion(newSongIds)
    });
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final docRef = _db.collection('playlists').doc(playlistId);
    await docRef.update({
      'songs': FieldValue.arrayRemove([songId])
    });
  }

  Future<void> updatePlaylistOrder(String playlistId, List<String> songIds) async {
    final docRef = _db.collection('playlists').doc(playlistId);
    await docRef.update({
      'songs': songIds
    });
  }

  Future<void> updatePlaylistDetails(String playlistId, {String? name, String? description, String? imageUrl}) async {
    final docRef = _db.collection('playlists').doc(playlistId);
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    
    if (data.isNotEmpty) {
      await docRef.update(data);
    }
  }

  Stream<List<String>> getUserLibrary(String? uid) {
    if (uid == null) return Stream.value([]);
    
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return List<String>.from(snapshot.data()!['libraryPlaylists'] ?? []);
      }
      return [];
    });
  }

  Stream<List<String>> getLikedSongIds(String? uid) {
    if (uid == null) return Stream.value([]);
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return List<String>.from(snapshot.data()!['likedSongs'] ?? []);
      }
      return [];
    });
  }

  Future<void> toggleLikedSong(Song song) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final userDocRef = _db.collection('users').doc(uid);

    final snapshot = await userDocRef.get();
    final likedSongs = List<String>.from(
      snapshot.data()?['likedSongs'] ?? [],
    );
    final isLiked = likedSongs.contains(song.id);

    if (isLiked) {
      // Unlike — remove from the private list
      await userDocRef.set({
        'likedSongs': FieldValue.arrayRemove([song.id])
      }, SetOptions(merge: true));
    } else {
      // Like — add to private list and update the Liked Songs playlist
      await userDocRef.set({
        'likedSongs': FieldValue.arrayUnion([song.id])
      }, SetOptions(merge: true));

      // Find or create the user's private "Liked Songs" playlist
      final likedPlaylistQuery = await _db
          .collection('playlists')
          .where('creatorUid', isEqualTo: uid)
          .where('isLikedPlaylist', isEqualTo: true)
          .limit(1)
          .get();

      if (likedPlaylistQuery.docs.isNotEmpty) {
        // Add to existing
        await likedPlaylistQuery.docs.first.reference.update({
          'songs': FieldValue.arrayUnion([song.id])
        });
      } else {
        // Create for first time
        final docRef = await _db.collection('playlists').add({
          'name': 'Liked Songs',
          'imageUrl': 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=800&q=80',
          'createdBy': user.displayName ?? 'Me',
          'creatorUid': uid,
          'description': 'Songs you have liked',
          'songs': [song.id],
          'isLikedPlaylist': true,
        });
        await updatePlaylistLibrary(docRef.id, true);
      }
    }
  }

  Future<void> cacheLyricsForSong(String songId, String lyrics) async {
    await _db.collection('songs').doc(songId).update({'lyrics': lyrics});
  }

  Future<void> updateFcmToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> saveSearchQuery(String query, bool found) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (query.trim().isEmpty) return;
    
    await _db.collection('search_queries').add({
      'query': query.trim().toLowerCase(),
      'uid': uid,
      'timestamp': FieldValue.serverTimestamp(),
      'found': found,
    });

    if (uid != null) {
      await _db.collection('users').doc(uid).set({
        'recentSearches': FieldValue.arrayUnion([query.trim()])
      }, SetOptions(merge: true));
    }
  }

  Future<void> addToRecentlyPlayed(Song song) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDocRef = _db.collection('users').doc(uid);
    
    // Also increment global play count for Trending Now
    await incrementPlayCount(song.id);

    // Most recent first: remove then add to the end
    await userDocRef.update({
      'recentlyPlayed': FieldValue.arrayRemove([song.id])
    });
    
    await userDocRef.update({
      'recentlyPlayed': FieldValue.arrayUnion([song.id])
    });
  }

  Future<void> incrementPlayCount(String songId) async {
    final songRef = _db.collection('songs').doc(songId);
    await songRef.update({
      'playCount': FieldValue.increment(1),
    });
  }

  Future<void> touchPlaylist(String playlistId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = _db.collection('users').doc(uid);
    
    // Move to end of recentlyTouchedPlaylists
    await userRef.update({
      'recentlyTouchedPlaylists': FieldValue.arrayRemove([playlistId])
    });
    
    await userRef.update({
      'recentlyTouchedPlaylists': FieldValue.arrayUnion([playlistId])
    });
  }

  Stream<List<String>> getRecentlyPlayedIds(String? uid) {
    if (uid == null) return Stream.value([]);
    
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // arrayUnion adds to the end, so we reverse to get most recent at the top
        return List<String>.from(snapshot.data()!['recentlyPlayed'] ?? []).reversed.toList();
      }
      return [];
    });
  }

  Stream<Map<String, dynamic>> getPremiumDetails(String? uid) {
    if (uid == null) return Stream.value({'isPremium': false});
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data() ?? {};
      return {
        'isPremium': data['isPremium'] ?? false,
        'premiumUntil': data['premiumUntil'],
      };
    });
  }

  Stream<bool> getPremiumStatus(String? uid) {
    if (uid == null) return Stream.value(false);
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      return snapshot.data()?['isPremium'] ?? false;
    });
  }

  Future<DateTime?> updatePremiumStatus(bool isPremium, {int months = 1}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      if (!isPremium) {
        await _db.collection('users').doc(uid).set({
          'isPremium': false,
          'premiumUntil': null,
        }, SetOptions(merge: true));
        return null;
      }

      final userDoc = await _db.collection('users').doc(uid).get();
      final currentUntil = userDoc.data()?['premiumUntil'] as Timestamp?;
      
      DateTime startDate = DateTime.now();
      if (currentUntil != null && currentUntil.toDate().isAfter(startDate)) {
        startDate = currentUntil.toDate();
      }

      final expiryDate = startDate.add(Duration(days: 31 * months)); 
      
      await _db.collection('users').doc(uid).set({
        'isPremium': true,
        'premiumSince': userDoc.data()?['premiumSince'] ?? FieldValue.serverTimestamp(),
        'premiumUntil': Timestamp.fromDate(expiryDate),
      }, SetOptions(merge: true));

      return expiryDate;
    }
    return null;
  }

  Future<String?> saveTransaction(Map<String, dynamic> transactionData) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final docRef = await _db.collection('transactions').add({
        ...transactionData,
        'uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    }
    return null;
  }

  Future<void> updateTransactionStatus(String docId, String status, Map<String, dynamic> data) async {
    await _db
        .collection('transactions')
        .doc(docId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      ...data,
    });
  }

  Stream<List<Map<String, dynamic>>> getTransactions(String? uid) {
    if (uid == null) return Stream.value([]);
    return _db
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getPricingPlans() {
    return _db.collection('pricing').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getNotifications(String? uid) {
    if (uid == null) return Stream.value([]);
    return _db
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final allNotifs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      return allNotifs.where((notif) {
        final audience = notif['audience'];
        if (audience == 'all_users' || audience == 'all users' || audience == 'all') return true;
        if (audience is List) {
          return audience.contains('all_users') ||
              audience.contains('all users') ||
              audience.contains('all') ||
              audience.contains(uid);
        }
        return false;
      }).toList();
    });
  }

  Future<void> markNotificationsAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'lastNotificationReadAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> normalizeSongs() async {
    final querySnapshot = await _db.collection('songs').get();
    final batch = _db.batch();
    
    for (var doc in querySnapshot.docs) {
      final song = Song.fromFirestore(doc);
      
      // Ensure all model fields are present in Firestore for future-proofing
      batch.update(doc.reference, song.toFirestore());
    }
    
    await batch.commit();
  }

  Future<void> populateWithMockData() async {
    final songsBatch = _db.batch();
    for (var song in mockSongs) {
      songsBatch.set(_db.collection('songs').doc(song.id), song.toFirestore());
    }
    await songsBatch.commit();

    final artistsBatch = _db.batch();
    for (var artist in mockArtists) {
      artistsBatch.set(_db.collection('artists').doc(artist.id), artist.toFirestore());
    }
    await artistsBatch.commit();

    final albumsBatch = _db.batch();
    for (var album in mockAlbums) {
      final data = album.toFirestore();
      data['releaseDate'] = Timestamp.now(); // Auto-populate release date
      albumsBatch.set(_db.collection('albums').doc(album.id), data);
    }
    await albumsBatch.commit();

    final playlistsBatch = _db.batch();
    final mockPlaylists = [
      Playlist(
        id: 'top_hits',
        name: 'Today\'s Top Hits',
        imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&q=80',
        creatorName: 'Basal',
        creatorUid: 'basal_admin',
        songIds: [],
        type: 'chart',
      ),
      Playlist(
        id: 'chill_vibes',
        name: 'Chill Vibes',
        imageUrl: 'https://images.unsplash.com/photo-1494232410401-ad00d5433cfa?w=800&q=80',
        creatorName: 'Basal',
        creatorUid: 'basal_admin',
        songIds: [],
        type: 'mood',
      ),
      Playlist(
        id: 'daily_mix_1',
        name: 'Daily Mix 1',
        imageUrl: 'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?w=800&q=80',
        creatorName: 'Basal',
        creatorUid: 'basal_admin',
        songIds: [],
        type: 'madeForYou',
      ),
      Playlist(
        id: 'deep_focus',
        name: 'Deep Focus',
        imageUrl: 'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=800&q=80',
        creatorName: 'Basal',
        creatorUid: 'basal_admin',
        songIds: [],
        type: 'mood',
      ),
      Playlist(
        id: 'tech_talks',
        name: 'Tech Talks Podcast',
        imageUrl: 'https://images.unsplash.com/photo-1590602847861-f357a9332bbc?w=800&q=80',
        creatorName: 'Basal Podcasts',
        creatorUid: 'basal_admin',
        songIds: [],
        type: 'podcast',
      ),
    ];
    for (var playlist in mockPlaylists) {
      playlistsBatch.set(_db.collection('playlists').doc(playlist.id), playlist.toFirestore());
    }
    await playlistsBatch.commit();
  }
}

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final userDocumentProvider = StreamProvider<DocumentSnapshot<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
});

final songsStreamProvider = StreamProvider<List<Song>>((ref) {
  return ref.watch(firestoreServiceProvider).getSongs();
});

final artistsStreamProvider = StreamProvider<List<Artist>>((ref) {
  return ref.watch(firestoreServiceProvider).getArtists();
});

final albumsStreamProvider = StreamProvider<List<Album>>((ref) {
  return ref.watch(firestoreServiceProvider).getAlbums();
});

final playlistsStreamProvider = StreamProvider<List<Playlist>>((ref) {
  return ref.watch(firestoreServiceProvider).getPlaylists();
});

final userLibraryIdsProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  return ref.watch(firestoreServiceProvider).getUserLibrary(uid);
});

final likedSongIdsProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  return ref.watch(firestoreServiceProvider).getLikedSongIds(uid);
});

final recentSearchesProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance.collection('users').doc(uid).snapshots().map((snap) {
    return List<String>.from(snap.data()?['recentSearches'] ?? []).reversed.toList();
  });
});

final recentlyPlayedIdsStreamProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  return ref.watch(firestoreServiceProvider).getRecentlyPlayedIds(uid);
});

final recentlyPlayedSongsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final idsAsync = ref.watch(recentlyPlayedIdsStreamProvider);
  final allSongsAsync = ref.watch(songsStreamProvider);

  if (idsAsync.isLoading || allSongsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final ids = idsAsync.value ?? [];
  final allSongs = allSongsAsync.value ?? [];

  // Map IDs back to full Song objects, maintaining the order from IDs list
  final recentSongs = ids.map((id) {
    return allSongs.firstWhere((s) => s.id == id, orElse: () => Song(id: id, title: 'Unknown', artist: 'Unknown', album: '', thumbnailUrl: '', audioUrl: '', duration: Duration.zero));
  }).where((s) => s.title != 'Unknown').toList();

  return AsyncValue.data(recentSongs);
});

final likedSongsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final likedIdsAsync = ref.watch(likedSongIdsProvider);
  final allSongsAsync = ref.watch(songsStreamProvider);

  if (likedIdsAsync.isLoading || allSongsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final ids = likedIdsAsync.value ?? [];
  final allSongs = allSongsAsync.value ?? [];

  final likedSongs = allSongs.where((s) => ids.contains(s.id)).toList();
  return AsyncValue.data(likedSongs);
});

final dynamicDailyMixProvider = Provider<AsyncValue<List<Playlist>>>((ref) {
  final historyAsync = ref.watch(recentlyPlayedSongsProvider);
  final manualMixesAsync = ref.watch(madeForYouMixesProvider);

  if (historyAsync.isLoading || manualMixesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final manualMixes = manualMixesAsync.value ?? [];
  if (manualMixes.isNotEmpty) {
    return AsyncValue.data(manualMixes);
  }

  // Generate dynamic mix based on history
  final history = historyAsync.value ?? [];
  if (history.isEmpty) return const AsyncValue.data([]);

  // Create a virtual "Daily Mix" playlist
  final dailyMix = Playlist(
    id: 'dynamic_daily_mix',
    name: 'Your Daily Mix',
    imageUrl: history.first.thumbnailUrl,
    creatorName: 'Basal AI',
    creatorUid: 'system',
    songIds: history.map((s) => s.id).toList(),
    type: 'madeForYou',
  );

  return AsyncValue.data([dailyMix]);
});

final recommendedRadioProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final historyAsync = ref.watch(recentlyPlayedSongsProvider);
  final allSongsAsync = ref.watch(songsStreamProvider);

  if (historyAsync.isLoading || allSongsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final history = historyAsync.value ?? [];
  if (history.isEmpty) return const AsyncValue.data([]);
  
  final lastArtist = history.first.artist;
  final allSongs = allSongsAsync.value ?? [];
  
  // Recommend songs from the same artist or genre (if we had genre)
  final recommendations = allSongs
      .where((s) => s.artist == lastArtist && s.id != history.first.id)
      .toList();
  
  return AsyncValue.data(recommendations);
});

final topArtistsProvider = Provider<AsyncValue<List<Artist>>>((ref) {
  final artistsAsync = ref.watch(artistsStreamProvider);
  final songsAsync = ref.watch(songsStreamProvider);

  if (artistsAsync.isLoading || songsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final allArtists = artistsAsync.value ?? [];
  final allSongs = songsAsync.value ?? [];

  final sortedArtists = allArtists.toList();
  sortedArtists.sort((a, b) {
    final aPlays = allSongs.where((s) => a.songIds.contains(s.id)).fold(0, (sum, s) => sum + s.playCount);
    final bPlays = allSongs.where((s) => b.songIds.contains(s.id)).fold(0, (sum, s) => sum + s.playCount);
    return bPlays.compareTo(aPlays);
  });

  return AsyncValue.data(sortedArtists);
});


final userLibraryPlaylistsProvider = Provider<AsyncValue<List<Playlist>>>((ref) {
  final libraryIdsAsync = ref.watch(userLibraryIdsProvider);
  final allPlaylistsAsync = ref.watch(playlistsStreamProvider);

  if (libraryIdsAsync.isLoading || allPlaylistsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final libraryIds = libraryIdsAsync.value ?? [];
  final allPlaylists = allPlaylistsAsync.value ?? [];

  final savedPlaylists = allPlaylists.where((p) => libraryIds.contains(p.id)).toList();
  return AsyncValue.data(savedPlaylists);
});

enum SearchCategory { all, songs, albums, artists, playlists, podcasts }

final searchQueryProvider = StateProvider<String>((ref) => '');
final isSearchSubmittedProvider = StateProvider<bool>((ref) => false);
final searchFilterProvider = StateProvider<SearchCategory>((ref) => SearchCategory.all);

final searchResultsProvider = Provider<AsyncValue<Map<SearchCategory, List<dynamic>>>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final activeFilter = ref.watch(searchFilterProvider);

  if (query.isEmpty) return const AsyncValue.data({});

  final songsAsync = ref.watch(songsStreamProvider);
  final artistsAsync = ref.watch(artistsStreamProvider);
  final albumsAsync = ref.watch(albumsStreamProvider);

  // Helper to wait for all data
  if (songsAsync.isLoading || artistsAsync.isLoading || albumsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final allSongs = songsAsync.value ?? [];
  final allArtists = artistsAsync.value ?? [];
  final allAlbums = albumsAsync.value ?? [];

  Map<SearchCategory, List<dynamic>> results = {};

  if (activeFilter == SearchCategory.all || activeFilter == SearchCategory.songs) {
    results[SearchCategory.songs] = allSongs
        .where((s) => s.title.toLowerCase().contains(query) || s.artist.toLowerCase().contains(query))
        .toList();
  }

  if (activeFilter == SearchCategory.all || activeFilter == SearchCategory.artists) {
    results[SearchCategory.artists] = allArtists
        .where((a) => a.name.toLowerCase().contains(query))
        .toList();
  }

  if (activeFilter == SearchCategory.all || activeFilter == SearchCategory.albums) {
    results[SearchCategory.albums] = allAlbums
        .where((a) => a.title.toLowerCase().contains(query) || a.artist.toLowerCase().contains(query))
        .toList();
  }

  // Placeholder for playlists/podcasts
  results[SearchCategory.playlists] = [];
  results[SearchCategory.podcasts] = [];

  return AsyncValue.data(results);
});

final isPremiumStreamProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  return ref.watch(firestoreServiceProvider).getPremiumStatus(uid);
});

final premiumDetailsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  return ref.watch(firestoreServiceProvider).getPremiumDetails(uid);
});

final transactionsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  return ref.watch(firestoreServiceProvider).getTransactions(uid);
});

final pricingPlansStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(firestoreServiceProvider).getPricingPlans();
});

final notificationsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  return ref.watch(firestoreServiceProvider).getNotifications(uid);
});

final systemConfigStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return FirebaseFirestore.instance
      .collection('updates')
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data();
  });
});

final bannersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('banners')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

final unreadNotificationsCountProvider = Provider<AsyncValue<int>>((ref) {
  final notifsAsync = ref.watch(notificationsStreamProvider);
  final userDocAsync = ref.watch(userDocumentProvider);

  if (notifsAsync.isLoading || userDocAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final notifs = notifsAsync.value ?? [];
  final userDoc = userDocAsync.value;
  
  if (userDoc == null || !userDoc.exists) {
    return AsyncValue.data(notifs.length);
  }

  final lastRead = userDoc.data()?['lastNotificationReadAt'] as Timestamp?;
  if (lastRead == null) {
    return AsyncValue.data(notifs.length);
  }

  final unreadCount = notifs.where((n) {
    final timestamp = n['timestamp'] as Timestamp?;
    if (timestamp == null) return false;
    // Compare timestamps to see if it's newer than lastRead
    return timestamp.toDate().isAfter(lastRead.toDate());
  }).length;

  return AsyncValue.data(unreadCount);
});

// Discovery Section Providers
final trendingSongsProvider = StreamProvider<List<Song>>((ref) {
  return FirebaseFirestore.instance
      .collection('songs')
      .orderBy('playCount', descending: true)
      .limit(10)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Song.fromFirestore(doc)).toList());
});

final newReleasesProvider = StreamProvider<List<Song>>((ref) {
  return FirebaseFirestore.instance
      .collection('songs')
      .orderBy('releaseDate', descending: true)
      .limit(10)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Song.fromFirestore(doc)).toList());
});

final moodMixesProvider = StreamProvider<List<Playlist>>((ref) {
  return FirebaseFirestore.instance
      .collection('playlists')
      .where('type', isEqualTo: 'mood')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Playlist.fromFirestore(doc)).toList());
});

final madeForYouMixesProvider = StreamProvider<List<Playlist>>((ref) {
  return FirebaseFirestore.instance
      .collection('playlists')
      .where('type', isEqualTo: 'madeForYou')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Playlist.fromFirestore(doc)).toList());
});

final topChartsProvider = StreamProvider<List<Playlist>>((ref) {
  return FirebaseFirestore.instance
      .collection('playlists')
      .where('type', isEqualTo: 'chart')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Playlist.fromFirestore(doc)).toList());
});

final podcastProvider = StreamProvider<List<Playlist>>((ref) {
  return FirebaseFirestore.instance
      .collection('playlists')
      .where('type', isEqualTo: 'podcast')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Playlist.fromFirestore(doc)).toList());
});

final dynamicUserPlaylistsProvider = Provider<AsyncValue<List<Playlist>>>((ref) {
  final allPlaylistsAsync = ref.watch(playlistsStreamProvider);
  final userLibraryIdsAsync = ref.watch(userLibraryIdsProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (allPlaylistsAsync.isLoading || userLibraryIdsAsync.isLoading || uid == null) {
    return const AsyncValue.loading();
  }

  final allPlaylists = allPlaylistsAsync.value ?? [];
  final libraryIds = userLibraryIdsAsync.value ?? [];

  // Get user's created playlists
  final createdPlaylists = allPlaylists.where((p) => p.creatorUid == uid).toList();
  
  // Get other playlists in library
  final otherLibraryPlaylists = allPlaylists.where((p) => libraryIds.contains(p.id) && p.creatorUid != uid).toList();

  // Combine and sort by "importance" (created first, then recently touched if we had a timestamp, but for now just presence)
  // For a truly dynamic experience, we'd fetch the user's recentlyTouchedPlaylists from their doc.
  
  return ref.watch(userDocumentProvider).when(
    data: (userDoc) {
      final touchedIds = List<String>.from(userDoc.data()?['recentlyTouchedPlaylists'] ?? []);
      
      final result = <Playlist>[];
      
      // Order: Recently touched first (if they are in library or created by user)
      for (final id in touchedIds.reversed) {
        final p = allPlaylists.firstWhere((element) => element.id == id, orElse: () => Playlist(id: '', name: '', imageUrl: '', creatorName: '', creatorUid: '', songIds: []));
        if (p.id.isNotEmpty && (p.creatorUid == uid || libraryIds.contains(p.id))) {
          result.add(p);
        }
      }
      
      // Add remaining created playlists
      for (final p in createdPlaylists) {
        if (!result.contains(p)) result.add(p);
      }
      
      // Add remaining library playlists
      for (final p in otherLibraryPlaylists) {
        if (!result.contains(p)) result.add(p);
      }
      
      // Fill with generic playlists if we have fewer than 6
      if (result.length < 6) {
        for (final p in allPlaylists) {
          if (!result.contains(p)) {
            result.add(p);
            if (result.length >= 6) break;
          }
        }
      }

      return AsyncValue.data(result.take(6).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.data((createdPlaylists + otherLibraryPlaylists).take(6).toList()),
  );
});

final featuredArtistsStreamProvider = StreamProvider<List<Artist>>((ref) {
  return FirebaseFirestore.instance
      .collection('artists')
      .where('isFeatured', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Artist.fromFirestore(doc)).toList());
});
