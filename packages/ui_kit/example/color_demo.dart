import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Example demonstrating how to use the new UiKitColors system
class ColorDemoPage extends StatelessWidget {
  const ColorDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        title: Text(
          'UiKit Colors Demo',
          style: TextStyle(color: colors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              title: 'Background Colors',
              colors: colors,
              items: [
                _ColorItem('bgPrimary', colors.bgPrimary),
                _ColorItem('bgSurface', colors.bgSurface),
                _ColorItem('bgCard', colors.bgCard),
                _ColorItem('bgCardHover', colors.bgCardHover),
                _ColorItem('bgHero', colors.bgHero),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Border Colors',
              colors: colors,
              items: [
                _ColorItem('border', colors.border),
                _ColorItem('borderStrong', colors.borderStrong),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Text Colors',
              colors: colors,
              items: [
                _ColorItem('textPrimary', colors.textPrimary),
                _ColorItem('textMuted', colors.textMuted),
                _ColorItem('textHint', colors.textHint),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Accent Colors',
              colors: colors,
              items: [
                _ColorItem('accent', colors.accent),
                _ColorItem('accentDim', colors.accentDim),
                _ColorItem('accentHover', colors.accentHover),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Badge Colors',
              colors: colors,
              items: [
                _ColorItem('badgeNowBg', colors.badgeNowBg),
                _ColorItem('badgeNowText', colors.badgeNowText),
              ],
            ),
            const SizedBox(height: 24),
            _buildExampleComponents(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required UiKitColors colors,
    required List<_ColorItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildColorRow(item, colors)),
      ],
    );
  }

  Widget _buildColorRow(_ColorItem item, UiKitColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderStrong),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _colorToHex(item.color),
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleComponents(UiKitColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Example Components',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Card Example
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgCard,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Example Card',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This is an example card using bgCard and border colors',
                style: TextStyle(color: colors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Button Example
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Accent Button'),
        ),
        const SizedBox(height: 16),
        
        // Live Badge Example
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.badgeNowBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.badgeNowText,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE NOW',
                style: TextStyle(
                  color: colors.badgeNowText,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

class _ColorItem {
  final String name;
  final Color color;

  _ColorItem(this.name, this.color);
}
