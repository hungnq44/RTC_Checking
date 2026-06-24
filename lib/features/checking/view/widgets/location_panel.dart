import 'package:flutter/material.dart';

class RadiusPanel extends StatelessWidget {
  const RadiusPanel({
    super.key,
    required this.meters,
    required this.onChanged,
  });

  final double meters;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.adjust, size: 18, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  Text(
                    'Bán kính: ${meters.toStringAsFixed(0)} m',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Slider(
                min: 10,
                max: 1000,
                divisions: 99,
                value: meters.clamp(10, 1000).toDouble(),
                label: '${meters.toStringAsFixed(0)} m',
                onChanged: onChanged,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('10 m', style: TextStyle(fontSize: 11)),
                  Text('1 km', style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
