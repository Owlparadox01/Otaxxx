import 'package:flutter/material.dart';
import 'app_theme_controller.dart';

class ThemeToolsPage extends StatefulWidget {
  const ThemeToolsPage({super.key});

  @override
  State<ThemeToolsPage> createState() => _ThemeToolsPageState();
}

class _ThemeToolsPageState extends State<ThemeToolsPage> {
  late int _r;
  late int _g;
  late int _b;

  @override
  void initState() {
    super.initState();
    final current = AppThemeController.instance.seedColor;
    _r = current.red;
    _g = current.green;
    _b = current.blue;
  }

  Color get _preview => Color.fromARGB(255, _r, _g, _b);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Theme Color Tools")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 88,
              decoration: BoxDecoration(
                color: _preview,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surface.withOpacity(0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  _sliderRow("R", _r.toDouble(), const Color(0xFF5B4CFF), (v) {
                    setState(() => _r = v.round());
                  }),
                  _sliderRow("G", _g.toDouble(), const Color(0xFF4DA3FF), (v) {
                    setState(() => _g = v.round());
                  }),
                  _sliderRow("B", _b.toDouble(), Colors.blueAccent, (v) {
                    setState(() => _b = v.round());
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _presetChip(const Color(0xFF7A5CFF)),
                _presetChip(const Color(0xFF4DA3FF)),
                _presetChip(const Color(0xFF6B8CFF)),
                _presetChip(const Color(0xFF70B4FF)),
                _presetChip(const Color(0xFF4F8BFF)),
                _presetChip(const Color(0xFFB0C7FF)),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await AppThemeController.instance.reset();
                      if (!mounted) return;
                      final c = AppThemeController.instance.seedColor;
                      setState(() {
                        _r = c.red;
                        _g = c.green;
                        _b = c.blue;
                      });
                    },
                    child: const Text("Reset"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await AppThemeController.instance.setSeedColor(_preview);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Theme updated")),
                        );
                      }
                    },
                    child: const Text("Apply"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        setState(() {
          _r = color.red;
          _g = color.green;
          _b = color.blue;
        });
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
      ),
    );
  }

  Widget _sliderRow(
    String label,
    double value,
    Color activeColor,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            divisions: 255,
            value: value,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}





