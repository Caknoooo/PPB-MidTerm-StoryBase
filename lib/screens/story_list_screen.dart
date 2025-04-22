import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../models/story.dart';
import '../providers/story_provider.dart';
import '../utils/app_constants.dart';
import 'story_detail_screen.dart';
import 'story_form_screen.dart';

class StoryListScreen extends StatefulWidget {
  const StoryListScreen({super.key});

  @override
  _StoryListScreenState createState() => _StoryListScreenState();
}

class _StoryListScreenState extends State<StoryListScreen>
    with SingleTickerProviderStateMixin {
  late StoryProvider _storyProvider;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isGridView = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _storyProvider.loadStories();
    });

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_showFab) {
        setState(() {
          _showFab = false;
        });
      }
    } else {
      if (!_showFab) {
        setState(() {
          _showFab = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storyProvider = Provider.of<StoryProvider>(context, listen: false);
  }

  bool isValidImageUrl(String? url) {
    return url != null &&
        url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  Future<void> _deleteStory(String id, String title) async {
    HapticFeedback.mediumImpact();

    final success = await _storyProvider.deleteStory(id);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 16),
                Text('$title deleted'),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 16),
                Text(
                  _storyProvider.errorMessage ??
                      AppConstants.errorDeletingStory,
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    }
  }

  Widget _buildGridCard(Story story, int index) {
    final double randomRotation =
        (math.Random(index).nextDouble() - 0.5) * 0.05;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        final delayedAnimation = _animationController.drive(
          CurveTween(
            curve: Interval(0.05 * (index % 10), 1.0, curve: Curves.easeOut),
          ),
        );

        return FadeTransition(
          opacity: delayedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(delayedAnimation),
            child: child,
          ),
        );
      },
      child: Hero(
        tag: 'story-${story.id}',
        child: Transform.rotate(
          angle: randomRotation,
          child: Card(
            elevation: 5,
            shadowColor: Colors.black45,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                HapticFeedback.lightImpact();
                final result = await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            StoryDetailScreen(story: story),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
                if (result == true) {
                  _storyProvider.loadStories();
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: AspectRatio(
                          aspectRatio: 3 / 2,
                          child:
                              isValidImageUrl(story.imageUrl)
                                  ? Image.network(
                                    story.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 40,
                                        ),
                                      );
                                    },
                                  )
                                  : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade400,
                                          Colors.purple.shade300,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.book,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                ],
                                stops: const [0.6, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Text(
                          story.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      story.content.length > 80
                          ? '${story.content.substring(0, 80)}...'
                          : story.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8.0,
                      right: 8.0,
                      bottom: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Story',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Edit',
                                onPressed: () async {
                                  HapticFeedback.lightImpact();
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              StoryFormScreen(story: story),
                                    ),
                                  );
                                  if (result == true) {
                                    _storyProvider.loadStories();
                                  }
                                },
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete',
                                onPressed:
                                    () => _showDeleteConfirmationDialog(story),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(Story story, int index) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        final delayedAnimation = _animationController.drive(
          CurveTween(
            curve: Interval(0.05 * (index % 10), 1.0, curve: Curves.easeOut),
          ),
        );

        return FadeTransition(
          opacity: delayedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.2, 0),
              end: Offset.zero,
            ).animate(delayedAnimation),
            child: child,
          ),
        );
      },
      child: Hero(
        tag: 'story-${story.id}',
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              HapticFeedback.lightImpact();
              final result = await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          StoryDetailScreen(story: story),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
              if (result == true) {
                _storyProvider.loadStories();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child:
                          isValidImageUrl(story.imageUrl)
                              ? Image.network(
                                story.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 32,
                                    ),
                                  );
                                },
                              )
                              : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.purple.shade300,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.book,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          story.content.length > 120
                              ? '${story.content.substring(0, 120)}...'
                              : story.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Material(
                              color: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              StoryFormScreen(story: story),
                                    ),
                                  );
                                  if (result == true) {
                                    _storyProvider.loadStories();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap:
                                    () => _showDeleteConfirmationDialog(story),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 16,
                                        color: Colors.red[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withOpacity(0.6)),
          ),
        ),
        title: Text(
          AppConstants.appName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            foreground:
                Paint()
                  ..shader = LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
          ),
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child:
                  _searchQuery.isEmpty
                      ? const Icon(Icons.search, key: ValueKey('search'))
                      : const Icon(Icons.clear, key: ValueKey('clear')),
            ),
            onPressed: () {
              if (_searchQuery.isNotEmpty) {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              } else {
                _showSearchModal(context);
              }
            },
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return RotationTransition(
                  turns: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child:
                  _isGridView
                      ? const Icon(Icons.view_list, key: ValueKey('list'))
                      : const Icon(Icons.grid_view, key: ValueKey('grid')),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isGridView = !_isGridView;
                _animationController.reset();
                _animationController.forward();
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<StoryProvider>(
        builder: (context, storyProvider, child) {
          if (storyProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your stories...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          List<Story> filteredStories = storyProvider.stories;
          if (_searchQuery.isNotEmpty) {
            filteredStories =
                storyProvider.stories
                    .where(
                      (story) =>
                          story.title.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          story.content.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                    )
                    .toList();
          }

          if (filteredStories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty
                        ? Icons.search_off
                        : Icons.book_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No stories match "${_searchQuery}"'
                        : 'No stories added yet!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Search'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Story'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StoryFormScreen(),
                          ),
                        );
                        if (result == true) {
                          _storyProvider.loadStories();
                        }
                      },
                    ),
                  ],
                ],
              ),
            );
          }

          if (_isGridView) {
            return GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredStories.length,
              itemBuilder: (context, index) {
                final story = filteredStories[index];
                return _buildGridCard(story, index);
              },
            );
          } else {
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(0, 100, 0, 80),
              itemCount: filteredStories.length,
              itemBuilder: (context, index) {
                final story = filteredStories[index];
                return _buildListCard(story, index);
              },
            );
          }
        },
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _showFab ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showFab ? 1.0 : 0.0,
          child: FloatingActionButton.extended(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StoryFormScreen(),
                ),
              );
              if (result == true) {
                _storyProvider.loadStories();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('New Story'),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSearchModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search your stories...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = _searchController.text.trim();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Search'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Popular searches:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                              'Adventure',
                              'Fantasy',
                              'Love',
                              'Mystery',
                              'Science Fiction',
                              'Journey',
                            ]
                            .map(
                              (tag) => ActionChip(
                                avatar: const Icon(Icons.history, size: 16),
                                label: Text(tag),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = tag;
                                    _searchController.text = tag;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            )
                            .toList(),
                  ),
                ),
                Expanded(
                  child: Consumer<StoryProvider>(
                    builder: (context, storyProvider, child) {
                      if (storyProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final searchText = _searchController.text.toLowerCase();
                      final filteredStories =
                          storyProvider.stories
                              .where(
                                (story) =>
                                    story.title.toLowerCase().contains(
                                      searchText,
                                    ) ||
                                    story.content.toLowerCase().contains(
                                      searchText,
                                    ),
                              )
                              .toList();

                      if (filteredStories.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No stories match "$searchText"',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredStories.length,
                        itemBuilder: (context, index) {
                          final story = filteredStories[index];
                          return ListTile(
                            leading:
                                isValidImageUrl(story.imageUrl)
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        story.imageUrl!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.book,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                            title: Text(
                              story.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              story.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              setState(() {
                                _searchQuery = story.title;
                                _searchController.text = story.title;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(Story story) async {
    HapticFeedback.mediumImpact();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Story?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete "${story.title}"?'),
                const SizedBox(height: 16),
                const Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteStory(story.id!, story.title);
              },
            ),
          ],
        );
      },
    );
  }
}
