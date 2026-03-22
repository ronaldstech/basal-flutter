import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CategoryHeaderSkeleton(),
        const SizedBox(height: 16),
        const PlaylistGridSkeleton(),
        const SizedBox(height: 32),
        const CategoryHeaderSkeleton(),
        const SizedBox(height: 16),
        const HorizontalScrollSkeleton(height: 220, width: 160),
        const SizedBox(height: 32),
        const CategoryHeaderSkeleton(),
        const SizedBox(height: 16),
        const HorizontalScrollSkeleton(height: 140, width: 100, isCircle: true),
        const SizedBox(height: 32),
        const CategoryHeaderSkeleton(),
        const SizedBox(height: 16),
        const HorizontalScrollSkeleton(height: 180, width: 140),
      ],
    );
  }
}

class CategoryHeaderSkeleton extends StatelessWidget {
  const CategoryHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceColor,
      highlightColor: Colors.white.withOpacity(0.05),
      child: Container(
        width: 150,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class PlaylistGridSkeleton extends StatelessWidget {
  const PlaylistGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppTheme.surfaceColor,
        highlightColor: Colors.white.withOpacity(0.05),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class HorizontalScrollSkeleton extends StatelessWidget {
  final double height;
  final double width;
  final bool isCircle;

  const HorizontalScrollSkeleton({
    super.key,
    required this.height,
    required this.width,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Shimmer.fromColors(
            baseColor: AppTheme.surfaceColor,
            highlightColor: Colors.white.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: width,
                  height: isCircle ? width : height - 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isCircle ? null : BorderRadius.circular(12),
                  ),
                ),
                if (!isCircle) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: width * 0.8,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: width * 0.5,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 60,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
