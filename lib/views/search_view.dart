import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../models/music_models.dart';
import '../providers/auth_provider.dart';
import '../providers/firestore_provider.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';
import 'playlist_detail_view.dart';
import 'album_detail_view.dart';
import '../widgets/profile_drawer.dart';
import '../widgets/skeleton_image.dart';
import '../widgets/home_skeleton.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _searchController = TextEditingController();

  final List<CategoryItem> categories = const [
    CategoryItem('Pop', Color(0xFFE91E63)),
    CategoryItem('Hip-Hop', Color(0xFFFF9800)),
    CategoryItem('Rock', Color(0xFFF44336)),
    CategoryItem('Jazz', Color(0xFF9C27B0)),
    CategoryItem('Classical', Color(0xFF3F51B5)),
    CategoryItem('Electronic', Color(0xFF00BCD4)),
    CategoryItem('Chill', Color(0xFF4CAF50)),
    CategoryItem('Indie', Color(0xFFCDDC39)),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      endDrawer: const ProfileDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                  ),
                  Builder(
                    builder: (context) {
                      return GestureDetector(
                        onTap: () => Scaffold.of(context).openEndDrawer(),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final user = ref.watch(authRepositoryProvider).currentUser;
                            final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.surfaceColor,
                                  backgroundImage: user?.photoURL != null 
                                    ? NetworkImage(user!.photoURL!) 
                                    : null,
                                  child: user?.photoURL == null 
                                    ? const Icon(Iconsax.user, size: 18, color: Colors.white70)
                                    : null,
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).scaffoldBackgroundColor, 
                                          width: 2
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      );
                    }
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                    ref.read(isSearchSubmittedProvider.notifier).state = false;
                  },
                  onSubmitted: (value) {
                    ref.read(isSearchSubmittedProvider.notifier).state = true;
                    if (value.isNotEmpty) {
                      final results = ref.read(searchResultsProvider).value;
                      final hasResults = results != null && results.values.any((list) => list.isNotEmpty);
                      ref.read(firestoreServiceProvider).saveSearchQuery(value, hasResults);
                    }
                  },
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'What do you want to listen to?',
                    icon: const Icon(Iconsax.search_normal, color: Colors.white54),
                    suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                            ref.read(isSearchSubmittedProvider.notifier).state = false;
                          },
                        )
                      : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (searchQuery.isNotEmpty) 
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: SearchCategory.values.map((category) {
                      final isActive = ref.watch(searchFilterProvider) == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category.name[0].toUpperCase() + category.name.substring(1)),
                          selected: isActive,
                          onSelected: (selected) {
                            ref.read(searchFilterProvider.notifier).state = category;
                          },
                          backgroundColor: Colors.white.withOpacity(0.05),
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isActive ? Colors.black : Colors.white70,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: isActive ? AppTheme.primaryColor : Colors.white10,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 16),
              
              Expanded(
                child: searchQuery.isEmpty
                  ? CustomScrollView(
                      slivers: [
                        // Recent Searches
                        ref.watch(recentSearchesProvider).when(
                          data: (recent) {
                            if (recent.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                            return SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recent Searches',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 40,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: recent.length > 5 ? 5 : recent.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: ActionChip(
                                            label: Text(recent[index]),
                                            onPressed: () {
                                              _searchController.text = recent[index];
                                              ref.read(searchQueryProvider.notifier).state = recent[index];
                                            },
                                            backgroundColor: Colors.white.withOpacity(0.05),
                                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                                            shape: StadiumBorder(side: BorderSide(color: Colors.white.withOpacity(0.1))),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            );
                          },
                          loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                          error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                        ),
                        
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Browse All',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.6,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final category = categories[index];
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      category.color,
                                      category.color.withOpacity(0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: category.color.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Stack(
                                  children: [
                                    Text(
                                      category.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: categories.length,
                          ),
                        ),
                      ],
                    )
                  : searchResults.when(
                      data: (resultsMap) {
                        final allResults = resultsMap.values.expand((element) => element).toList();
                        final isSubmitted = ref.watch(isSearchSubmittedProvider);
                        
                        if (allResults.isEmpty) {
                          if (isSubmitted) {
                            return const Center(child: Text('No results found'));
                          } else {
                            return const SizedBox.shrink();
                          }
                        }

                        return ListView(
                          children: resultsMap.entries.map((entry) {
                            if (entry.value.isEmpty) return const SizedBox.shrink();
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key.name[0].toUpperCase() + entry.key.name.substring(1),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                ...entry.value.map((item) {
                                  if (item is Song) {
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: SkeletonImage(
                                        imageUrl: item.thumbnailUrl,
                                        width: 50,
                                        height: 50,
                                        borderRadius: 8,
                                      ),
                                      title: Text(item.title),
                                      subtitle: Text(item.artist),
                                      onTap: () {
                                        ref.read(firestoreServiceProvider).saveSearchQuery(item.title, true);
                                        ref.read(audioProvider.notifier).playSong(item);
                                      },
                                    );
                                  } else if (item is Artist) {
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: SkeletonImage(
                                        imageUrl: item.imageUrl,
                                        width: 50,
                                        height: 50,
                                        shape: BoxShape.circle,
                                      ),
                                      title: Text(item.name),
                                      subtitle: const Text('Artist'),
                                      onTap: () {
                                        // TODO: Navigate to artist page
                                      },
                                    );
                                  } else if (item is Album) {
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: SkeletonImage(
                                        imageUrl: item.imageUrl,
                                        width: 50,
                                        height: 50,
                                        borderRadius: 8,
                                      ),
                                      title: Text(item.title),
                                      subtitle: Text(item.artist),
                                      onTap: () {
                                        ref.read(firestoreServiceProvider).saveSearchQuery(item.title, true);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AlbumDetailView(album: item),
                                          ),
                                        );
                                      },
                                    );
                                  } else if (item is Playlist) {
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item.imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      title: Text(item.name),
                                      subtitle: Text('Playlist • ${item.creatorName}'),
                                      onTap: () {
                                        ref.read(firestoreServiceProvider).saveSearchQuery(item.name, true);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlaylistDetailView(playlist: item),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                                const SizedBox(height: 24),
                              ],
                            );
                          }).toList()..add(const SizedBox(height: 100)),
                        );
                      },
                      loading: () => const PlaylistGridSkeleton(),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryItem {
  final String title;
  final Color color;
  const CategoryItem(this.title, this.color);
}
