import 'media_item.dart';
import 'playlist_entry.dart';

class SeedBundle {
  const SeedBundle({
    required this.mediaItems,
    required this.playlists,
  });

  final List<MediaItem> mediaItems;
  final List<PlaylistEntry> playlists;
}

SeedBundle buildSeedBundle() {
  final bluePlanet = MediaItem()
    ..mediaId = 'blue-planet-one-ocean'
    ..title = 'Blue Planet II - S1E1: One Ocean'
    ..subtitle = 'BBC Earth'
    ..source = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'
    ..artworkUrl = 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=900&q=80'
    ..backdropUrl = 'https://images.unsplash.com/photo-1544551763-77ef2d0cfc6c?auto=format&fit=crop&w=1600&q=80'
    ..metaLine = '2017  ·  Documentary  ·  58:24  ·  4K'
    ..genreLine = 'Nature · Ocean · Family'
    ..synopsis = 'Dive into the open ocean and follow sea turtles, dolphins and deep-water hunters across a bright, cinematic underwater world.'
    ..qualityLabel = '4K HDR'
    ..audioLabel = 'Dolby Atmos'
    ..languageLabel = 'ENG'
    ..year = 2017
    ..durationMillis = const Duration(minutes: 58, seconds: 24).inMilliseconds
    ..progressMillis = const Duration(minutes: 32, seconds: 16).inMilliseconds
    ..lastPlayedAt = DateTime.now().subtract(const Duration(hours: 2))
    ..spotlight = true
    ..sortOrder = 1
    ..chapters = [
      ChapterCue(
        title: '1. Sunlight Zone',
        startMillis: const Duration(minutes: 0).inMilliseconds,
        thumbnailUrl: 'https://images.unsplash.com/photo-1516117172878-fd2c41f4a759?auto=format&fit=crop&w=600&q=80',
      ),
      ChapterCue(
        title: '2. Open Water',
        startMillis: const Duration(minutes: 12, seconds: 20).inMilliseconds,
        thumbnailUrl: 'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=600&q=80',
      ),
      ChapterCue(
        title: '3. The Chase',
        startMillis: const Duration(minutes: 27, seconds: 18).inMilliseconds,
        thumbnailUrl: 'https://images.unsplash.com/photo-1521207418485-99c705420785?auto=format&fit=crop&w=600&q=80',
      ),
      ChapterCue(
        title: '4. Deep Dive',
        startMillis: const Duration(minutes: 45, seconds: 7).inMilliseconds,
        thumbnailUrl: 'https://images.unsplash.com/photo-1526336024174-e58f5cdd8e13?auto=format&fit=crop&w=600&q=80',
      ),
    ];

  final interstellar = MediaItem()
    ..mediaId = 'interstellar-2014'
    ..title = 'Interstellar.2014.1080p.BluRay'
    ..subtitle = 'Christopher Nolan'
    ..source = 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4'
    ..artworkUrl = 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=900&q=80'
    ..backdropUrl = 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1600&q=80'
    ..metaLine = '2014  ·  Sci‑Fi / Adventure  ·  2:49:04  ·  1080p'
    ..genreLine = 'Sci‑Fi · Adventure · Drama'
    ..synopsis = 'A pilot and a team of researchers travel through a wormhole in search of a future for humanity.'
    ..qualityLabel = '1080p'
    ..audioLabel = 'DDP 5.1'
    ..languageLabel = 'ENG'
    ..year = 2014
    ..durationMillis = const Duration(hours: 2, minutes: 49, seconds: 4).inMilliseconds
    ..progressMillis = const Duration(hours: 1, minutes: 22, seconds: 10).inMilliseconds
    ..lastPlayedAt = DateTime.now().subtract(const Duration(hours: 8))
    ..isFavorite = true
    ..sortOrder = 2
    ..chapters = [
      ChapterCue(
        title: '1. Opening',
        startMillis: 0,
        thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=600&q=80',
      ),
      ChapterCue(
        title: '2. Earth',
        startMillis: const Duration(minutes: 14, seconds: 32).inMilliseconds,
        thumbnailUrl: 'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?auto=format&fit=crop&w=600&q=80',
      ),
      ChapterCue(
        title: '3. The Wormhole',
        startMillis: const Duration(minutes: 28, seconds: 11).inMilliseconds,
        thumbnailUrl: 'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=600&q=80',
      ),
      ChapterCue(
        title: "4. Miller's Planet",
        startMillis: const Duration(minutes: 45, seconds: 7).inMilliseconds,
        thumbnailUrl: 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=600&q=80',
      ),
      ChapterCue(
        title: '5. Docking',
        startMillis: const Duration(hours: 1, minutes: 5, seconds: 32).inMilliseconds,
        thumbnailUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=600&q=80',
      ),
    ];

  final yourName = MediaItem()
    ..mediaId = 'your-name-2016'
    ..title = 'Your Name.2016.1080p.BluRay'
    ..subtitle = 'Makoto Shinkai'
    ..source = 'https://samplelib.com/lib/preview/mp4/sample-10s.mp4'
    ..artworkUrl = 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=900&q=80'
    ..backdropUrl = 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=1600&q=80'
    ..metaLine = '2016  ·  Animation  ·  1:46:36  ·  1080p'
    ..genreLine = 'Animation · Romance · Fantasy'
    ..synopsis = 'Two teenagers mysteriously begin to swap bodies and form a connection across time.'
    ..qualityLabel = '1080p'
    ..audioLabel = 'FLAC'
    ..languageLabel = 'JP / CN'
    ..year = 2016
    ..durationMillis = const Duration(hours: 1, minutes: 46, seconds: 36).inMilliseconds
    ..progressMillis = const Duration(minutes: 42, seconds: 8).inMilliseconds
    ..lastPlayedAt = DateTime.now().subtract(const Duration(hours: 12))
    ..sortOrder = 3;

  final shawshank = MediaItem()
    ..mediaId = 'shawshank-redemption-1994'
    ..title = 'The Shawshank Redemption.1994'
    ..subtitle = 'Frank Darabont'
    ..source = 'https://samplelib.com/lib/preview/mp4/sample-15s.mp4'
    ..artworkUrl = 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=900&q=80'
    ..backdropUrl = 'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=1600&q=80'
    ..metaLine = '1994  ·  Drama  ·  2:22:33  ·  Remastered'
    ..genreLine = 'Drama · Classic'
    ..synopsis = 'Two imprisoned men bond over years, finding solace and eventual redemption through acts of common decency.'
    ..qualityLabel = 'Remastered'
    ..audioLabel = 'AAC'
    ..languageLabel = 'ENG'
    ..year = 1994
    ..durationMillis = const Duration(hours: 2, minutes: 22, seconds: 33).inMilliseconds
    ..progressMillis = const Duration(hours: 2, minutes: 22, seconds: 33).inMilliseconds
    ..lastPlayedAt = DateTime.now().subtract(const Duration(days: 1, hours: 3))
    ..isCompleted = true
    ..sortOrder = 4;

  final freshWater = MediaItem()
    ..mediaId = 'planet-earth-fresh-water'
    ..title = 'Planet Earth II - S1E3: Fresh Water'
    ..subtitle = 'BBC Earth'
    ..source = 'https://samplelib.com/lib/preview/mp4/sample-20s.mp4'
    ..artworkUrl = 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=900&q=80'
    ..backdropUrl = 'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?auto=format&fit=crop&w=1600&q=80'
    ..metaLine = '2016  ·  Documentary  ·  50:11  ·  4K'
    ..genreLine = 'Nature · Freshwater'
    ..synopsis = 'An exploration of rivers, lakes and the wildlife that depends on these fragile ecosystems.'
    ..qualityLabel = '4K'
    ..audioLabel = 'AAC'
    ..languageLabel = 'ENG'
    ..year = 2016
    ..durationMillis = const Duration(minutes: 50, seconds: 11).inMilliseconds
    ..progressMillis = const Duration(minutes: 39, seconds: 2).inMilliseconds
    ..lastPlayedAt = DateTime.now().subtract(const Duration(days: 1, hours: 6))
    ..isFavorite = true
    ..sortOrder = 5;

  return SeedBundle(
    mediaItems: [
      bluePlanet,
      interstellar,
      yourName,
      shawshank,
      freshWater,
    ],
    playlists: const [],
  );
}
