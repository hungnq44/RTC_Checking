import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../base/bloc/index.dart';
import '../../../../base/widgets/base_scaffold.dart';
import '../../../../base/widgets/base_widget.dart';
import '../../../../common/utils/snack_bar_helper.dart';
import '../../data/datasource/model/saved_location.dart';
import '../bloc/checking_bloc.dart';
import '../widgets/location_buttons.dart';
import '../widgets/location_drawer.dart';
import '../widgets/location_info_panel.dart';
import '../widgets/location_dialog.dart';

class CheckingScreen extends StatefulWidget {
  const CheckingScreen({super.key});

  @override
  State<CheckingScreen> createState() => _CheckingScreenState();
}

class _CheckingScreenState
    extends
        BaseState<CheckingScreen, CheckingEvent, CheckingState, CheckingBloc> {
  String? _lastShownMessage;

  @override
  Widget renderUI(BuildContext context) {
    return BlocBuilder<CheckingBloc, CheckingState>(
      bloc: bloc,
      builder: (context, state) {
        return BaseScaffold(
          endDrawer: LocationDrawer(
            locations: state.savedLocations,
            selectedId: state.selectedLocationId,
            onLocationSelected: (id, lat, lng) {
              bloc.add(CheckingEvent.selectLocation(id, lat, lng));
              Navigator.pop(context);
            },
            onDeleteLocation: (id) {
              bloc.add(CheckingEvent.deleteLocation(id));
            },
            onToggleNotification: (id) {
              bloc.add(CheckingEvent.toggleNotification(id));
            },
            onEditLocation: (location) {
              _showEditLocationDialog(context, location);
            },
          ),
          appBar: AppBar(
            title: const Text('RTC Checking'),
            centerTitle: true,
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              MapWidget(
                onMapCreated: (map) =>
                    bloc.add(CheckingEvent.init(mapboxMap: map)),
                onTapListener: (gestureContext) {
                  _showTapLocationDialog(
                    context,
                    gestureContext.point.coordinates.lat.toDouble(),
                    gestureContext.point.coordinates.lng.toDouble(),
                  );
                },
              ),
              Positioned(
                left: 2.5,
                right: 2.5,
                bottom: 2.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocationInfoPanel(
                      latitude: state.lat,
                      longitude: state.lng,
                      radius: state.radius,
                      isInZone: state.isInZone,
                      distanceToZone: state.distanceToZone,
                      locationTitle: state.title,
                      onRadiusChanged: (radius) =>
                          bloc.add(CheckingEvent.updateRadius(radius)),
                    ),
                    const SizedBox(height: 12),
                    LocationButtons(
                      isLoading: state.status == BaseStateStatus.loading,
                      onSaveLocation: () =>
                          bloc.add(CheckingEvent.saveLocation()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  bool listenWhen(CheckingState previous, CheckingState current) {
    return current.message != null &&
        current.message != _lastShownMessage &&
        (current.status == BaseStateStatus.success ||
            current.status == BaseStateStatus.failed);
  }

  @override
  void listener(BuildContext context, CheckingState state) {
    _lastShownMessage = state.message;
    if (state.status == BaseStateStatus.failed) {
      showMessage(context, state.message!, type: SnackBarType.error);
    } else {
      showMessage(context, state.message!, type: SnackBarType.success);
    }
  }

  void _showTapLocationDialog(
    BuildContext context,
    double lat,
    double lng,
  ) {
    showLocationEditDialog(
      context: context,
      lat: lat,
      lng: lng,
      onSave: (title, newLat, newLng, radius) {
        bloc.add(CheckingEvent.inputLocation(title, newLat, newLng));
        bloc.stream.firstWhere(
          (state) =>
              state.status != BaseStateStatus.loading &&
              state.lat == newLat &&
              state.lng == newLng,
        ).then((_) {
          bloc.add(CheckingEvent.saveLocation());
        });
      },
      onCancel: () {
        Navigator.canPop(context);
      },
    );
  }

  void _showEditLocationDialog(
    BuildContext context,
    SavedLocation location,
  ) {
    showLocationEditDialog(
      context: context,
      lat: location.lat,
      lng: location.lng,
      radius: location.radius,
      initialTitle: location.title,
      isEditMode: true,
      onSave: (title, lat, lng, radius) {
        bloc.add(CheckingEvent.updateLocation(
          id: location.id,
          title: title,
          lat: lat,
          lng: lng,
          radius: radius,
        ));
      },
      onCancel: () {},
      onCloseDrawer: () {
        context.pop();
      },
    );
  }
}
