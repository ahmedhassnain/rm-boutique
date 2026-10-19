import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// OWNER: Maheen.
/// A simple size guide: body measurements per size, plus a how-to-measure note.
/// (Static reference content — no database needed.)
class SizeGuideScreen extends StatelessWidget {
  const SizeGuideScreen({super.key});

  // Measurements in centimetres.
  static const _rows = <List<String>>[
    ['XS', '81–84', '61–64', '87–90'],
    ['S', '85–88', '65–68', '91–94'],
    ['M', '89–92', '69–72', '95–98'],
    ['L', '93–97', '73–77', '99–103'],
    ['XL', '98–103', '78–83', '104–109'],
    ['XXL', '104–110', '84–90', '110–116'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Size guide')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'All measurements are in centimetres. If you are between two sizes, '
            'we recommend sizing up for a relaxed fit.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 16),
          _table(),
          const SizedBox(height: 24),
          const Text('How to measure',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const _Tip('Bust',
              'Measure around the fullest part of your chest, keeping the tape level.'),
          const _Tip('Waist',
              'Measure around the narrowest part of your natural waistline.'),
          const _Tip('Hips', 'Measure around the fullest part of your hips.'),
        ],
      ),
    );
  }

  Widget _table() {
    const headStyle = TextStyle(fontWeight: FontWeight.w600);
    return Table(
      border: TableBorder.all(color: AppColors.sand, width: 1),
      columnWidths: const {0: FixedColumnWidth(64)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.sand),
          children: const [
            _Cell('Size', style: headStyle),
            _Cell('Bust', style: headStyle),
            _Cell('Waist', style: headStyle),
            _Cell('Hips', style: headStyle),
          ],
        ),
        for (final r in _rows)
          TableRow(children: [
            _Cell(r[0], style: const TextStyle(fontWeight: FontWeight.w600)),
            _Cell(r[1]),
            _Cell(r[2]),
            _Cell(r[3]),
          ]),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.style});
  final String text;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(text, style: style),
      );
}

class _Tip extends StatelessWidget {
  const _Tip(this.title, this.body);
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: AppColors.charcoal, height: 1.4),
            children: [
              TextSpan(
                  text: '$title — ',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: body),
            ],
          ),
        ),
      );
}
