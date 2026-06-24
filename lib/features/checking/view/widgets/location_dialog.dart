import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class TapLocationDialog extends StatefulWidget {
  const TapLocationDialog({
    super.key,
    required this.lat,
    required this.lng,
    this.radius,
    this.initialTitle,
    this.isEditMode = false,
    required this.onSave,
    required this.onCancel,
    this.onCloseDrawer,
  });

  final double lat;
  final double lng;
  final double? radius;
  final String? initialTitle;
  final bool isEditMode;
  final void Function(String title, double lat, double lng, double radius) onSave;
  final VoidCallback onCancel;
  final VoidCallback? onCloseDrawer;

  @override
  State<TapLocationDialog> createState() => _TapLocationDialogState();
}

class _TapLocationDialogState extends State<TapLocationDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _radiusCtrl;
  bool _isTitleValid = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    _radiusCtrl = TextEditingController(
      text: (widget.radius ?? 15.0).toInt().toString(),
    );
    _isTitleValid = _titleCtrl.text.trim().isNotEmpty;
    _titleCtrl.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    final isValid = _titleCtrl.text.trim().isNotEmpty;
    if (isValid != _isTitleValid) {
      setState(() => _isTitleValid = isValid);
    }
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTitleChanged);
    _titleCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_isTitleValid) return;

    final title = _titleCtrl.text.trim();
    final radius = (int.tryParse(_radiusCtrl.text) ?? 25).toDouble();

    context.pop();
    widget.onCloseDrawer?.call();
    widget.onSave(
      title.isEmpty ? 'Vị trí' : title,
      widget.lat,
      widget.lng,
      radius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.isEditMode ? Icons.edit_location : Icons.location_on,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEditMode ? 'Chỉnh sửa vị trí' : 'Vị trí mới',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.isEditMode ? 'Cập nhật thông tin vị trí' : 'Điểm đã chọn trên bản đồ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'Nhập tên vị trí',
                errorText: _titleCtrl.text.isNotEmpty && !_isTitleValid ? 'Vui lòng nhập tên vị trí' : null,
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.label_outline,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            _RadiusField(
              controller: _radiusCtrl,
              colorScheme: colorScheme,
              label: 'Bán kính (m)',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _CoordinateDisplay(
                    label: 'Vĩ độ',
                    value: widget.lat.toStringAsFixed(6),
                    icon: Icons.north,
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 16),
                  _CoordinateDisplay(
                    label: 'Kinh độ',
                    value: widget.lng.toStringAsFixed(6),
                    icon: Icons.east,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.pop();
                      widget.onCloseDrawer?.call();
                      widget.onCancel();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Huỷ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:               FilledButton(
                    onPressed: _isTitleValid ? _handleSave : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(widget.isEditMode ? 'Cập nhật' : 'Lưu'),
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

class _CoordinateDisplay extends StatelessWidget {
  const _CoordinateDisplay({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _RadiusField extends StatelessWidget {
  const _RadiusField({
    required this.controller,
    required this.colorScheme,
    required this.label,
  });

  final TextEditingController controller;
  final ColorScheme colorScheme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        prefixIcon: Icon(
          Icons.radio_button_unchecked,
          color: colorScheme.onSurfaceVariant,
          size: 20,
        ),
        suffixText: 'm',
        suffixStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

Future<void> showLocationEditDialog({
  required BuildContext context,
  required double lat,
  required double lng,
  double? radius,
  String? initialTitle,
  bool isEditMode = false,
  required void Function(String title, double lat, double lng, double radius) onSave,
  required VoidCallback onCancel,
  VoidCallback? onCloseDrawer,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TapLocationDialog(
      lat: lat,
      lng: lng,
      radius: radius,
      initialTitle: initialTitle,
      isEditMode: isEditMode,
      onSave: onSave,
      onCancel: onCancel,
      onCloseDrawer: onCloseDrawer,
    ),
  );
}
