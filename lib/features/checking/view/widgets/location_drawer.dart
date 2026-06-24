import 'package:flutter/material.dart';

import '../../data/datasource/model/saved_location.dart';

class LocationDrawer extends StatelessWidget {
  final List<SavedLocation> locations;
  final String? selectedId;
  final Function(String id, double lat, double lng) onLocationSelected;
  final Function(double lat, double lng)? onDrawRoute;
  final Function(String id)? onDeleteLocation;
  final VoidCallback? onMapReset;
  final Function(String id)? onToggleNotification;
  final Function(SavedLocation location)? onEditLocation;

  const LocationDrawer({
    super.key,
    required this.locations,
    this.selectedId,
    required this.onLocationSelected,
    this.onDrawRoute,
    this.onDeleteLocation,
    this.onMapReset,
    this.onToggleNotification,
    this.onEditLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Địa điểm đã lưu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${locations.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: locations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có địa điểm',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        final location = locations[index];
                        final isSelected = location.id == selectedId;
                        return _LocationTile(
                          location: location,
                          index: index + 1,
                          isSelected: isSelected,
                          onTap: () => onLocationSelected(
                            location.id,
                            location.lat,
                            location.lng,
                          ),
                          onEdit: onEditLocation != null
                              ? () => onEditLocation!(location)
                              : null,
                          onDelete: onDeleteLocation != null
                              ? () => _showDeleteConfirmation(
                                  context,
                                  () {
                                    onDeleteLocation!(location.id);
                                    onMapReset?.call();
                                  },
                                )
                              : null,
                          onToggleNotification: onToggleNotification != null
                              ? () => onToggleNotification!(location.id)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa vị trí'),
        content: const Text('Bạn có chắc muốn xóa vị trí này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final SavedLocation location;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleNotification;

  const _LocationTile({
    required this.location,
    required this.index,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleNotification,
  });

  String _formatTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _buildIndexBadge(context),
                const SizedBox(width: 10),
                Expanded(child: _buildInfoColumn(context)),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndexBadge(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$index',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 10),
              ),
            Expanded(
              child: Text(
                location.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.north, size: 9, color: Colors.grey[600]),
            const SizedBox(width: 2),
            Text(
              'Vĩ độ: ${location.lat.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.east, size: 9, color: Colors.grey[600]),
            const SizedBox(width: 2),
            Text(
              'Kinh độ: ${location.lng.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 9, color: Colors.grey[500]),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                _formatTime(location.createdAt),
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null) ...[
          _ActionButton(
            icon: Icons.edit_outlined,
            color: Theme.of(context).colorScheme.secondary,
            onTap: onEdit!,
            tooltip: 'Chỉnh sửa',
          ),
          const SizedBox(width: 4),
        ],
        if (onToggleNotification != null)
          _ActionButton(
            icon: location.notificationEnabled
                ? Icons.notifications_active
                : Icons.notifications_off,
            color: location.notificationEnabled ? Colors.green : Colors.grey,
            onTap: onToggleNotification!,
            tooltip: location.notificationEnabled
                ? 'Tắt thông báo'
                : 'Bật thông báo',
          ),
        if (onDelete != null) ...[
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.delete_outline,
            color: Colors.red[400]!,
            onTap: onDelete!,
            tooltip: 'Xóa',
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}
