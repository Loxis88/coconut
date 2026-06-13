import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../domain/product.dart';
import '../theme.dart';
import 'coco_card.dart';
import 'score_widgets.dart';

bool _needsProxy(String url) {
  try {
    final uri = Uri.parse(url);
    if (!uri.isAbsolute) return false;
    final host = uri.host;
    // Proxy if host contains % (percent-encoded IDN/Cyrillic domain) or is rskrf.ru
    return host.contains('%') || host.contains('rskrf.ru');
  } catch (_) {
    return true; // unparseable URL (raw Cyrillic host etc.) → proxy
  }
}

String _resolveImageUrl(String url) =>
    _needsProxy(url) ? '$coconutBackendBaseUrl/proxy/image?url=${Uri.encodeComponent(url)}' : url;

class NetImg extends StatelessWidget {
  const NetImg(this.url, {super.key, this.fit = BoxFit.cover, this.width, this.height});
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveImageUrl(url);
    return CachedNetworkImage(
      imageUrl: resolved,
      // Cache by original URL so proxy vs direct doesn't create duplicate entries.
      cacheKey: url,
      fit: fit,
      width: width,
      height: height,
      errorWidget: (context, _, error) {
        debugPrint('NetImg error: $url → $error');
        return const Icon(Icons.fastfood, color: Colors.white);
      },
    );
  }
}

class ProductRow extends StatelessWidget {
  const ProductRow({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              ProductThumb(product: product, size: 52, radius: 16),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      product.manufacturer.isNotEmpty ? product.manufacturer : product.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: MayakTheme.mutedFg, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              ScoreChip(score: product.score),
            ],
          ),
        ),
      );
}

class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.product, required this.size, required this.radius});
  final Product product;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (product.thumbnail != null && product.thumbnail!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: NetImg(product.thumbnail!, width: size, height: size),
      );
    }
    final label = product.title.isEmpty ? '?' : product.title.characters.first;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0xffffe4b5), borderRadius: BorderRadius.circular(radius)),
      child: Center(child: Text(label, style: TextStyle(color: MayakTheme.scorePoor, fontSize: size * .38, fontWeight: FontWeight.w900))),
    );
  }
}

class NutrientGrid extends StatelessWidget {
  const NutrientGrid({super.key, required this.nutrients});
  final Nutrients nutrients;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(children: [
            NutrientCell(label: 'Белки', value: nutrients.proteins ?? '-'),
            NutrientCell(label: 'Жиры', value: nutrients.fats ?? '-'),
            NutrientCell(label: 'Углеводы', value: nutrients.carbohydrates ?? '-'),
          ]),
          Row(children: [
            NutrientCell(label: 'Ккал', value: nutrients.calories ?? '-'),
            if (nutrients.fiber != null) NutrientCell(label: 'Клетчатка', value: nutrients.fiber!),
          ]),
        ],
      );
}

class NutrientCell extends StatelessWidget {
  const NutrientCell({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.all(5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text(label.toUpperCase(), style: const TextStyle(color: MayakTheme.mutedFg, fontSize: 10, fontWeight: FontWeight.w900)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

class AxisRow extends StatelessWidget {
  const AxisRow({super.key, required this.label, required this.value, required this.note});
  final String label;
  final int value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final tier = scoreTier(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))), Text('$value', style: TextStyle(color: tier.color))]),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / 100),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(value: v, color: tier.color, backgroundColor: MayakTheme.muted),
          ),
          Text(note, style: const TextStyle(color: MayakTheme.mutedFg, fontSize: 12)),
        ],
      ),
    );
  }
}

class Flag extends StatelessWidget {
  const Flag({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CocoCard(
          child: Row(children: [
            const CircleAvatar(backgroundColor: MayakTheme.scoreExcellent, child: Icon(Icons.check, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(color: MayakTheme.mutedFg, fontWeight: FontWeight.w600))),
          ]),
        ),
      );
}

extension StringListX on List<String> {
  String firstOrNullText(String fallback) => isEmpty ? fallback : first;
}
