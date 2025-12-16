// lib/screens/gallery/gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('gallery')
        .orderBy('date', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'School Gallery',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF516BE8),
        iconTheme: const IconThemeData(color: Colors.white), // यह line add करें
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load gallery'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No photos uploaded yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3 / 4,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = (data['eventTitle'] ?? '') as String;
              final desc = (data['description'] ?? '') as String;
              final url = (data['url'] ??
                  (data['photoURLs'] != null &&
                      (data['photoURLs'] as List).isNotEmpty
                      ? (data['photoURLs'] as List).first
                      : '')) as String;

              return _GalleryCard(
                title: title.isEmpty ? 'Untitled event' : title,
                description: desc,
                imageUrl: url,
                data: data,
              );
            },
          );
        },
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final Map<String, dynamic> data;

  const _GalleryCard({
    Key? key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.data,
  }) : super(key: key);

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        data['eventDate'] as String? ?? data['date'] as String? ?? '';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _GalleryDetailPage(data: data),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: imageUrl.isEmpty
                  ? Container(color: Colors.grey[300])
                  : Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  if (dateStr.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _formatDate(dateStr),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const _GalleryDetailPage({Key? key, required this.data}) : super(key: key);

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final title = (data['eventTitle'] ?? '') as String;
    final desc = (data['description'] ?? '') as String;
    final urls = (data['photoURLs'] as List?)?.cast<String>() ?? [];
    final mainUrl = (data['url'] ?? (urls.isNotEmpty ? urls.first : '')) as String;
    final dateStr =
        data['eventDate'] as String? ?? data['date'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? 'Event' : title),
        backgroundColor: const Color(0xFF516BE8),
      ),
      body: Column(
        children: [
          if (mainUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                mainUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (dateStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatDate(dateStr),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                if (desc.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      desc,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
          if (urls.length > 1)
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: urls.length,
                itemBuilder: (context, index) {
                  final u = urls[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        u,
                        width: 120,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
