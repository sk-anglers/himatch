import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/photo.dart';
import 'package:himatch/features/group/presentation/providers/photo_providers.dart';

/// Photo album screen for a group.
///
/// Displays photos in a 3-column grid with filter chips.
/// Tap to open full-screen view, long-press for reaction picker, FAB to upload.
class AlbumScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const AlbumScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  String? _selectedFilter; // null = all
  static const _reactionEmojis = [
    '\u{1F44D}', // thumbs up
    '\u{2764}\u{FE0F}', // heart
    '\u{1F602}', // joy
    '\u{1F389}', // party
    '\u{1F64C}', // raising hands
  ];

  @override
  Widget build(BuildContext context) {
    final allPhotos = ref.watch(localPhotosProvider);
    final photos = allPhotos[widget.groupId] ?? [];

    // Build filter chips from suggestion IDs
    final suggestionIds = photos
        .where((p) => p.suggestionId != null)
        .map((p) => p.suggestionId!)
        .toSet()
        .toList();

    // Apply filter
    final filtered = _selectedFilter == null
        ? photos
        : photos
            .where((p) => p.suggestionId == _selectedFilter)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.groupName} のアルバム'),
      ),
      body: Column(
        children: [
          // Filter chips
          if (suggestionIds.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('すべて'),
                      selected: _selectedFilter == null,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primary,
                      onSelected: (_) {
                        setState(() => _selectedFilter = null);
                      },
                    ),
                  ),
                  ...suggestionIds.map(
                    (id) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(id),
                        selected: _selectedFilter == id,
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                        onSelected: (_) {
                          setState(
                            () => _selectedFilter =
                                _selectedFilter == id ? null : id,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Photo grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '写真がありません',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '右下のボタンから写真を追加しましょう',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final photo = filtered[index];
                      return _PhotoGridItem(
                        photo: photo,
                        onTap: () => _openFullScreen(context, photo),
                        onLongPress: () =>
                            _showReactionPicker(context, photo),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadOptions(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  void _openFullScreen(BuildContext context, Photo photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenPhotoView(
          photo: photo,
          groupId: widget.groupId,
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context, Photo photo) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _reactionEmojis
                .map(
                  (emoji) => GestureDetector(
                    onTap: () {
                      ref.read(localPhotosProvider.notifier).addReaction(
                            groupId: widget.groupId,
                            photoId: photo.id,
                            emoji: emoji,
                            userId: 'local-user',
                          );
                      Navigator.pop(ctx);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: Integrate image_picker camera
                _addDemoPhoto();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('ギャラリーから選択'),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: Integrate image_picker gallery
                _addDemoPhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addDemoPhoto() {
    ref.read(localPhotosProvider.notifier).addPhoto(
          groupId: widget.groupId,
          uploadedBy: 'local-user',
          uploaderName: 'あなた',
          imageUrl: 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/400/400',
          caption: 'デモ写真',
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('写真をアップロードしました')),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid item
// ---------------------------------------------------------------------------

class _PhotoGridItem extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoGridItem({
    required this.photo,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              photo.thumbnailUrl ?? photo.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.broken_image, color: AppColors.textHint),
              ),
            ),
          ),
          // Reaction count badge
          if (photo.reactions.isNotEmpty)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, size: 10, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(
                      '${photo.reactions.values.fold<int>(0, (s, v) => s + v.length)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen photo view
// ---------------------------------------------------------------------------

class _FullScreenPhotoView extends ConsumerWidget {
  final Photo photo;
  final String groupId;

  const _FullScreenPhotoView({
    required this.photo,
    required this.groupId,
  });

  static const _reactionEmojis = [
    '\u{1F44D}',
    '\u{2764}\u{FE0F}',
    '\u{1F602}',
    '\u{1F389}',
    '\u{1F64C}',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          photo.uploaderName,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          // Zoomable image
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: Image.network(
                  photo.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),

          // Caption + reactions
          Container(
            color: Colors.black87,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photo.caption != null && photo.caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      photo.caption!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),

                // Reactions
                if (photo.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      children: photo.reactions.entries
                          .where((e) => e.value.isNotEmpty)
                          .map(
                            (entry) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${entry.key} ${entry.value.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                // Reaction picker row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _reactionEmojis
                      .map(
                        (emoji) => GestureDetector(
                          onTap: () {
                            ref
                                .read(localPhotosProvider.notifier)
                                .addReaction(
                                  groupId: groupId,
                                  photoId: photo.id,
                                  emoji: emoji,
                                  userId: 'local-user',
                                );
                          },
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
