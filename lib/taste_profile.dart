import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';

class TasteProfile {
  const TasteProfile({
    required this.spicySweet,
    required this.richLight,
    required this.meatFish,
    required this.favoriteFood,
    required this.dislikedFood,
    required this.schoolLunchFood,
  });

  final int spicySweet;
  final int richLight;
  final int meatFish;
  final String favoriteFood;
  final String dislikedFood;
  final String schoolLunchFood;

  factory TasteProfile.fromJson(Map<String, dynamic> json) {
    int readScore(String key) {
      final value = json[key];
      if (value is int) {
        return value.clamp(0, 100);
      }
      return int.tryParse(value?.toString() ?? '')?.clamp(0, 100) ?? 50;
    }

    return TasteProfile(
      spicySweet: readScore('taste_spicy_sweet'),
      richLight: readScore('taste_rich_light'),
      meatFish: readScore('taste_meat_fish'),
      favoriteFood: json['favorite_food']?.toString() ?? '',
      dislikedFood: json['disliked_food']?.toString() ?? '',
      schoolLunchFood: json['school_lunch_food']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson(String email) {
    return {
      'email': email,
      'taste_spicy_sweet': spicySweet,
      'taste_rich_light': richLight,
      'taste_meat_fish': meatFish,
      'favorite_food': favoriteFood,
      'disliked_food': dislikedFood,
      'school_lunch_food': schoolLunchFood,
    };
  }
}

class TasteProfileCard extends StatelessWidget {
  const TasteProfileCard({super.key, required this.profile, this.onEdit});

  final TasteProfile profile;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: foodLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10241812),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '食のプロフィール',
                    style: TextStyle(
                      color: foodInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: '編集',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, color: foodPrimary),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      _TasteMeter(
                        leftLabel: '辛党',
                        rightLabel: '甘党',
                        value: profile.spicySweet,
                      ),
                      const SizedBox(height: 12),
                      _TasteMeter(
                        leftLabel: '濃味',
                        rightLabel: '薄味',
                        value: profile.richLight,
                      ),
                      const SizedBox(height: 12),
                      _TasteMeter(
                        leftLabel: '肉',
                        rightLabel: '魚',
                        value: profile.meatFish,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _TasteBubble(label: '好き', value: profile.favoriteFood),
                      const SizedBox(height: 10),
                      _TasteBubble(label: '苦手', value: profile.dislikedFood),
                      const SizedBox(height: 10),
                      _TasteBubble(label: '給食', value: profile.schoolLunchFood),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TasteMeter extends StatelessWidget {
  const _TasteMeter({
    required this.leftLabel,
    required this.rightLabel,
    required this.value,
  });

  final String leftLabel;
  final String rightLabel;
  final int value;

  @override
  Widget build(BuildContext context) {
    final alignment = Alignment((value.clamp(0, 100) / 50) - 1, 0);

    return Column(
      children: [
        Row(
          children: [
            Text(
              leftLabel,
              style: const TextStyle(
                color: foodInk,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              rightLabel,
              style: const TextStyle(
                color: foodInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE8E3),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Align(
            alignment: alignment,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: foodPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33241812),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TasteBubble extends StatelessWidget {
  const _TasteBubble({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '未設定' : value.trim();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: foodSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD8C8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: foodPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: value.trim().isEmpty ? foodMuted : foodInk,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
