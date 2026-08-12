import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/firebase_error_translator.dart';
import '../../providers/farm/photo_upload_controller.dart';
import 'cached_farm_image.dart';
import 'full_screen_photo_viewer.dart';

/// Land-photo editor: horizontal reorderable strip of up to
/// [PhotoUploadController.maxPhotos] photos, each showing live upload
/// progress, a retry affordance on failure, and a remove button. The
/// first photo is the cover — dragging a photo to the front sets it as
/// cover, so no separate "set cover" control is needed.
///
/// Bound to a `(ownerId, farmId)` pair — the farmId is either the real id
/// of the farm being edited, or a pre-reserved id for a farm not yet
/// created (see FarmRepository.reserveFarmId), so uploads can start the
/// moment a photo is picked rather than waiting for the whole form to be
/// submitted.
class LandPhotoManager extends ConsumerWidget {
  final String ownerId;
  final String farmId;
  const LandPhotoManager({super.key, required this.ownerId, required this.farmId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (ownerId: ownerId, farmId: farmId);
    final items = ref.watch(photoUploadControllerProvider(params));
    final controller = ref.read(photoUploadControllerProvider(params).notifier);
    final canAddMore = items.length < PhotoUploadController.maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Photos (${items.length}/${PhotoUploadController.maxPhotos})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            if (items.isNotEmpty)
              Text(
                'First photo is the cover',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 96,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            itemCount: items.length + (canAddMore ? 1 : 0),
            onReorderItem: (oldIndex, newIndex) {
              if (oldIndex >= items.length) return;
              controller.reorder(oldIndex, newIndex.clamp(0, items.length));
            },
            itemBuilder: (context, i) {
              if (i == items.length) {
                return _AddTile(
                  key: const ValueKey('__add_photo__'),
                  onGallery: controller.pickFromGallery,
                  onCamera: controller.pickFromCamera,
                );
              }
              final item = items[i];
              return ReorderableDragStartListener(
                key: ValueKey(item.localId),
                index: i,
                child: _PhotoTile(
                  item: item,
                  isCover: i == 0,
                  onTapPreview: item.status == PhotoStatus.ready
                      ? () => showFullScreenPhotoViewer(
                            context,
                            urls: controller.readyUrls,
                            initialIndex: controller.readyUrls.indexOf(item.url ?? ''),
                          )
                      : null,
                  onRetry: () => controller.retry(item.localId),
                  onRemove: () => item.status == PhotoStatus.ready
                      ? controller.deleteReady(item.localId)
                      : controller.cancelOrRemove(item.localId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Photo tile ─────────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  final PhotoItem item;
  final bool isCover;
  final VoidCallback? onTapPreview;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  const _PhotoTile({
    required this.item,
    required this.isCover,
    required this.onTapPreview,
    required this.onRetry,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: SizedBox(
        width: 88,
        height: 88,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: GestureDetector(
                onTap: onTapPreview,
                child: item.url != null
                    ? CachedFarmImage(url: item.url!, width: 88, height: 88)
                    : item.previewBytes != null
                        ? Image.memory(item.previewBytes!,
                            fit: BoxFit.cover, width: 88, height: 88)
                        : Container(color: AppColors.surfaceVariant),
              ),
            ),
            if (item.status == PhotoStatus.uploading || item.status == PhotoStatus.queued)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Center(
                    child: item.status == PhotoStatus.uploading
                        ? SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              value: item.progress > 0 ? item.progress : null,
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.hourglass_top_rounded,
                            color: Colors.white70, size: 22),
                  ),
                ),
              ),
            if (item.status == PhotoStatus.failed)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      tooltip: item.error != null
                          ? '${friendlyFirebaseMessage(item.error!)} Tap to retry.'
                          : 'Retry upload',
                      onPressed: onRetry,
                    ),
                  ),
                ),
              ),
            if (isCover && item.status == PhotoStatus.ready)
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: const Text('Cover',
                      style: TextStyle(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ),
            Positioned(
              top: 3,
              right: 3,
              child: GestureDetector(
                onTap: onRemove,
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add tile ───────────────────────────────────────────────────────────────

class _AddTile extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  const _AddTile({super.key, required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => _showPickerSheet(context),
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.outline),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary),
              SizedBox(height: 4),
              Text('Add', style: TextStyle(fontSize: 11, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                onGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                onCamera();
              },
            ),
          ],
        ),
      ),
    );
  }
}
