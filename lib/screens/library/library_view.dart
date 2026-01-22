import 'package:flutter/material.dart';

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    int crossAxisCount = width > 1200 ? 5 : (width > 800 ? 3 : 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "MY LIBRARY",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: ogaSampleAssets.length,
          itemBuilder: (context, index) =>
              OgaAssetCard(asset: ogaSampleAssets[index]),
        ),
      ],
    );
  }
}

class OgaAssetCard extends StatelessWidget {
  final Map<String, String> asset;
  const OgaAssetCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Image.asset(
                asset['image']!,
                fit: BoxFit.contain,
                // Fallback if the image isn't in your assets folder yet
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.videogame_asset,
                  color: Color(0xFF00FF00),
                  size: 50,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset['name']!.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Text(
                  asset['series']!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Data mapping to your local assets listed in pubspec.yaml
final List<Map<String, String>> ogaSampleAssets = [
  {
    'name': 'Vegeta',
    'series': 'Dragon Ball Super',
    'image': 'assets/vegeta.png', // Switched to local path
  },
  {
    'name': 'Ryu',
    'series': 'Street Fighter',
    'image': 'assets/ryu.png', // Switched to local path
  },
  {
    'name': 'Mickey',
    'series': 'Disney',
    'image': 'assets/mickey.png', // Switched to local path
  },
];
