import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class FilterStrip extends StatelessWidget {
  final VideoFilter currentFilter;
  final void Function(VideoFilter) onFilterSelected;

  const FilterStrip({
    super.key,
    required this.currentFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: VideoFilter.values.map((filter) {
          final isSelected = currentFilter == filter;
          return GestureDetector(
            onTap: () => onFilterSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 54,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _filterBgColor(filter),
                      border: Border.all(
                        color: isSelected ? AppColors.rose : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.rose.withOpacity(.4), blurRadius: 8)]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        filter.emoji,
                        style: TextStyle(
                          fontSize: filter == VideoFilter.none ? 13 : 20,
                          color: Colors.white.withOpacity(.9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filter.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: isSelected ? AppColors.rose : AppColors.muted,
                      letterSpacing: .5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _filterBgColor(VideoFilter filter) {
    switch (filter) {
      case VideoFilter.none:  return const Color(0xFF3D1525);
      case VideoFilter.warm:  return const Color(0xFF5C2A0A);
      case VideoFilter.cool:  return const Color(0xFF0A2050);
      case VideoFilter.bloom: return const Color(0xFF5C1040);
      case VideoFilter.noir:  return const Color(0xFF1A1A1A);
      case VideoFilter.glam:  return const Color(0xFF4A1535);
    }
  }
}
