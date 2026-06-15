import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/models/content/images_model.dart';
import 'package:fndtv/src/ui/pages/video_player/video_player_page.dart';
import 'package:commons/commons.dart';
import 'package:ui_kit/ui_kit.dart';

class NewVODPage extends StatefulWidget {
  final String? initialCategory;
  
  const NewVODPage({super.key, this.initialCategory});

  @override
  State<NewVODPage> createState() => _NewVODPageState();
}

class _NewVODPageState extends State<NewVODPage> {
  String? _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  Map<String, List<LiveModel>> _groupByTagline(List<LiveModel> items) {
    final Map<String, List<LiveModel>> grouped = {};
    
    for (final item in items) {
      final tagline = item.details?.tagline ?? 'Other';
      if (tagline.isNotEmpty) {
        grouped.putIfAbsent(tagline, () => []).add(item);
      }
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // VOD Grid
            Expanded(
              child: BlocBuilder<ContentCubit, ContentState>(
                builder: (context, state) {
                  if (state.status == Status.loading) {
                    return Center(
                      child: CircularProgressIndicator(color: colors.accent),
                    );
                  }

                  if (state.status == Status.failure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: colors.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load videos',
                            style: TextStyle(color: colors.textPrimary, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  // Get VOD content
                  final vodItems = state.contentList?['1']?.data ?? [];

                  if (vodItems.isEmpty) {
                    return Center(
                      child: Text(
                        'No videos available',
                        style: TextStyle(color: colors.textMuted, fontSize: 14),
                      ),
                    );
                  }

                  // Group items by tagline (category)
                  final groupedItems = _groupByTagline(vodItems);
                  final categories = groupedItems.keys.toList();

                  // Set default selected category if not set
                  if (_selectedCategory == null && categories.isNotEmpty) {
                    _selectedCategory = 'All';
                  }

                  // Filter items based on selected category
                  final filteredItems = _selectedCategory == 'All' || _selectedCategory == null
                      ? vodItems
                      : groupedItems[_selectedCategory] ?? [];

                  return Column(
                    children: [
                      // Category Tabs
                      _CategoryTabs(
                        categories: ['All', ...categories],
                        selectedCategory: _selectedCategory ?? 'All',
                        onCategorySelected: (category) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // VOD Grid
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            childAspectRatio: 16 / 9,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            return _VODCard(item: filteredItems[index]);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}

// в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
// CATEGORY TABS
// в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ

class _CategoryTabs extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _CategoryTabs({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.accent : colors.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? colors.accent : colors.border,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? colors.textPrimary : colors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
// VOD CARD (Portrait)
// в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ

class _VODCard extends StatelessWidget {
  final LiveModel item;

  const _VODCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          VideoPlayerPage.path,
          arguments: {
            'channel': item,
            'contentCubit': context.read<ContentCubit>(),
            'contentType': ContentType.dvr,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 0.5, color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
          fit: StackFit.expand,
          children: [
            // Poster image - use poster property directly for VOD
            if (item.images.poster != null && item.images.poster!.isNotEmpty && item.images.poster != defaultPosterImage)
              Image.network(
                item.images.poster!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colors.bgSurface,
                    child: Icon(
                      Icons.video_library,
                      size: 48,
                      color: colors.textHint,
                    ),
                  );
                },
              )
            else
              Container(
                color: colors.bgSurface,
                child: Icon(
                  Icons.video_library,
                  size: 48,
                  color: colors.textHint,
                ),
              ),
            
            // Gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),
            
            // Title and tagline at bottom
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.tagline != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.tagline!,
                      style: GoogleFonts.sora(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: colors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Play icon overlay (center)
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
