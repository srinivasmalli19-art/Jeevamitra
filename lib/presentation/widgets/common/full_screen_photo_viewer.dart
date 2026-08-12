import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Pushes a full-screen, pinch-to-zoom, swipeable viewer over [urls]
/// starting at [initialIndex]. A local overlay (not a named/deep-linkable
/// route), so it doesn't touch go_router.
Future<void> showFullScreenPhotoViewer(
  BuildContext context, {
  required List<String> urls,
  int initialIndex = 0,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _FullScreenPhotoViewer(
        urls: urls,
        initialIndex: initialIndex,
      ),
    ),
  );
}

class _FullScreenPhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _FullScreenPhotoViewer({required this.urls, required this.initialIndex});

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late final _pageCtrl = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageCtrl,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            builder: (context, i) => PhotoViewGalleryPageOptions(
              imageProvider: CachedNetworkImageProvider(widget.urls[i]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              heroAttributes: PhotoViewHeroAttributes(tag: widget.urls[i]),
            ),
            loadingBuilder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (widget.urls.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.urls.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
