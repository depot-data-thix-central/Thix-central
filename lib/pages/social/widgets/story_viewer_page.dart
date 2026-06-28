import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/pages/social/models/social_models.dart';
import 'package:thix_central/theme.dart';

/// Plein écran léger pour consulter une story.
///
/// Note: cette page est pensée pour être affichée via `showDialog`/
/// `showGeneralDialog` (donc fermeture via `context.pop()`).
class StoryViewerPage extends StatelessWidget {
  const StoryViewerPage({super.key, required this.story});

  final SocialStory story;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = story.mediaUrl ?? '';
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: mediaUrl.isEmpty
                  ? const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 48))
                  : InteractiveViewer(
                      minScale: 1,
                      maxScale: 3,
                      child: Image.network(
                        mediaUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, _, __) => const Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 48),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        },
                      ),
                    ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      story.author.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Text(
                      '${story.viewCount} vues',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
            if ((story.caption ?? '').trim().isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.mainCard),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Text(
                    story.caption!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, height: 1.35),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
