import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String thumbnailUrl;
  final String audioUrl;
  final Duration duration;
  final String lyrics;
  final int playCount;
  final DateTime? releaseDate;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.thumbnailUrl,
    required this.audioUrl,
    required this.duration,
    this.lyrics = '',
    this.playCount = 0,
    this.releaseDate,
  });

  factory Song.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Helper to find field regardless of common casing
    dynamic getField(List<String> variants) {
      for (var variant in variants) {
        if (data.containsKey(variant)) return data[variant];
      }
      return null;
    }

    return Song(
      id: doc.id,
      title: getField(['title', 'Title']) ?? '',
      artist: getField(['artist', 'Artist']) ?? '',
      album: getField(['album', 'Album']) ?? '',
      thumbnailUrl: getField(['imageUrl', 'imageurl', 'thumbnailUrl', 'thumbnail_url']) ?? '',
      audioUrl: getField(['songUrl', 'songurl', 'audioUrl', 'audio_url']) ?? '',
      duration: Duration(seconds: getField(['durationSeconds', 'duration_seconds', 'duration']) ?? 0),
      lyrics: getField(['lyrics']) ?? '',
      playCount: getField(['playCount', 'play_count']) ?? 0,
      releaseDate: (getField(['releaseDate', 'release_date']) as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'thumbnailUrl': thumbnailUrl,
      'audioUrl': audioUrl,
      'durationSeconds': duration.inSeconds,
      'playCount': playCount,
      'releaseDate': releaseDate != null ? Timestamp.fromDate(releaseDate!) : null,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      thumbnailUrl: json['thumbnailUrl'],
      audioUrl: json['audioUrl'],
      duration: Duration(seconds: json['durationSeconds']),
    );
  }
}

class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> songIds;
  final bool isFeatured;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.songIds,
    this.isFeatured = false,
  });

  factory Artist.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Artist(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      songIds: List<String>.from(data['songIds'] ?? []),
      isFeatured: data['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'songIds': songIds,
      'isFeatured': isFeatured,
    };
  }
}

class Album {
  final String id;
  final String title;
  final String artist;
  final String imageUrl;
  final List<String> songIds;
  final int playCount;
  final DateTime? releaseDate;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.songIds,
    this.playCount = 0,
    this.releaseDate,
  });

  factory Album.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Album(
      id: doc.id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      songIds: List<String>.from(data['songIds'] ?? []),
      playCount: data['playCount'] ?? 0,
      releaseDate: (data['releaseDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'artist': artist,
      'imageUrl': imageUrl,
      'songIds': songIds,
      'playCount': playCount,
      'releaseDate': releaseDate != null ? Timestamp.fromDate(releaseDate!) : null,
    };
  }
}

class Playlist {
  final String id;
  final String name;
  final String imageUrl;
  final String creatorName;
  final String creatorUid;
  final String description;
  final List<String> songIds;
  final String? type;

  Playlist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.creatorName,
    required this.creatorUid,
    this.description = '',
    required this.songIds,
    this.type,
  });

  factory Playlist.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    dynamic getField(List<String> variants) {
      for (var variant in variants) {
        if (data.containsKey(variant)) return data[variant];
      }
      return null;
    }

    return Playlist(
      id: doc.id,
      name: getField(['name', 'title', 'Title']) ?? '',
      imageUrl: getField(['imageUrl', 'imageurl', 'thumbnailUrl']) ?? '',
      creatorName: getField(['createdBy', 'creator']) ?? '',
      creatorUid: getField(['creatorUid', 'createdBy', 'creator']) ?? '',
      description: getField(['description']) ?? '',
      songIds: List<String>.from(getField(['songs', 'songIds']) ?? []),
      type: getField(['type']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'createdBy': creatorName,
      'creatorUid': creatorUid,
      'description': description,
      'songs': songIds,
      'type': type,
    };
  }
}
