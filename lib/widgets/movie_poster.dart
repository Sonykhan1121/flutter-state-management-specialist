import 'package:flutter/material.dart';

class MoviePoster extends StatelessWidget {
  const MoviePoster({
    super.key,
    required this.url,
    required this.title,
    this.borderRadius = BorderRadius.zero,
  });

  final String url;
  final String title;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF343A46), Color(0xFF171A20)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_movies_outlined,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: ColoredBox(
        color: const Color(0xFF171A20),
        child:
            url.isEmpty
                ? fallback
                : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback,
                ),
      ),
    );
  }
}
