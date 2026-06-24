import 'package:flutter/material.dart';

class LocationInfoPanel extends StatelessWidget {
  const LocationInfoPanel({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.isInZone,
    required this.distanceToZone,
    required this.onRadiusChanged,
    this.locationTitle,
  });

  final double? latitude;
  final double? longitude;
  final double radius;
  final bool isInZone;
  final double distanceToZone;
  final ValueChanged<double> onRadiusChanged;
  final String? locationTitle;

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(2)} m';
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;
    final primaryColor = isInZone ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: hasLocation
                  ? primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: hasLocation
                        ? primaryColor.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasLocation
                        ? (isInZone ? Icons.check_circle : Icons.location_off)
                        : Icons.help_outline,
                    size: 16,
                    color: hasLocation ? primaryColor : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasLocation
                        ? (isInZone
                            ? 'Trong vùng'
                            : 'Ngoài vùng: ${_formatDistance(distanceToZone)}')
                        : 'Chưa chọn vị trí',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasLocation ? primaryColor : Colors.grey[600],
                    ),
                  ),
                ),
                if (locationTitle != null && locationTitle!.isNotEmpty)
                  Flexible(
                    child: Text(
                      locationTitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (latitude != null && longitude != null) ...[
                  Row(
                    children:[
                      Expanded(
                        child: _buildInfoRow(
                          label: 'Kinh độ',
                          value: latitude!.toStringAsFixed(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoRow(
                          label: 'Vĩ độ',
                          value: longitude!.toStringAsFixed(6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Bán kính:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width:4),
                              Text(
                                '${radius.toStringAsFixed(0)} m',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFFF59E0B),
                              inactiveTrackColor: Colors.grey[200],
                              thumbColor: Colors.white,
                              overlayColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                                elevation: 4,
                              ),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
                              activeTickMarkColor: Colors.white,
                              inactiveTickMarkColor: Colors.grey[400],
                            ),
                            child: Slider(
                              min: 10,
                              max: 1000,
                              divisions: 99,
                              value: radius.clamp(10, 1000),
                              onChanged: onRadiusChanged,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '10 m',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                '1 km',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
