import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';

class PostAttributeGroup {
  const PostAttributeGroup({required this.title, required this.options});

  final String title;
  final List<String> options;
}

const postAttributeGroups = [
  PostAttributeGroup(title: '席', options: ['個室利用', 'テーブル利用', 'カウンター利用']),
  PostAttributeGroup(title: '喫煙', options: ['禁煙', '喫煙']),
  PostAttributeGroup(
    title: '利用シーン',
    options: ['デート', '友達', '一人', '宴会', '接待', '家族', '合コン'],
  ),
];

class PostAttributeSelector extends StatelessWidget {
  const PostAttributeSelector({
    super.key,
    required this.selectedValues,
    required this.onToggle,
  });

  final Set<String> selectedValues;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: postAttributeGroups.map((group) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title,
                style: const TextStyle(
                  color: foodMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.options.map((option) {
                  final isSelected = selectedValues.contains(option);

                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (_) => onToggle(option),
                    selectedColor: foodPrimary,
                    backgroundColor: const Color(0xFFFFEFE3),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : foodPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    side: const BorderSide(color: foodPrimary),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class PostAttributeFilterSelector extends StatelessWidget {
  const PostAttributeFilterSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: postAttributeGroups.map((group) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title,
                style: const TextStyle(
                  color: foodMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.options.map((option) {
                  final isSelected = value == option;

                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      onChanged(selected ? option : null);
                    },
                    selectedColor: foodPrimary,
                    backgroundColor: const Color(0xFFFFEFE3),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : foodPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    side: const BorderSide(color: foodPrimary),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
