import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/maps/route_map.dart';
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/device_location_bloc.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/route_widgets/live_widget.dart';

class RouteManager extends StatefulWidget {
  const RouteManager({
    super.key,
    required this.association,
  });
  final lib.Association association;

  @override
  State<RouteManager> createState() => _RouteManagerState();
}

class _RouteManagerState extends State<RouteManager> {
  static const mm = '🔵🔵🔵🔵 RouteManager 🔵🔵';

  bool busy = false;
  var routes = <lib.Route>[];
  lib.Route? route;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() async {
    setState(() {
      busy = true;
    });
    try {
      final loc = await locationBloc.getLocation();
      pp('$mm ... location found: ${E.redDot} $loc');
      var mRoutes = await listApiDog.getRoutes(
          AssociationParameter(widget.association.associationId!, false));
      await _filter(mRoutes);
    } catch (e) {
      pp(e);
      _showError(e);
    }
    setState(() {
      busy = false;
    });
  }

  late Timer timer;

  void _handleRoute() async {
    pp('$mm ... start generation for route: ${route!.name}');
    _startGeneration();

  }

  void _startGeneration() {
    _generateDispatchRecords();
    _generateCommuterRequests();

    pp('$mm ... _startGeneration completed for route : ${route!.name} ');

  }

  Future<void> _filter(List<lib.Route> mRoutes) async {
    for (var route in mRoutes) {
      final marks = await listApiDog.getRouteLandmarks(route.routeId!, false);
      if (marks.isNotEmpty) {
        routes.add(route);
      }
    }
    pp('$mm ... routes found: ${routes.length}');
  }

  void _generateDispatchRecords() async {
    pp('$mm ... _generateDispatchRecords');
    setState(() {
      busy = true;
    });
    try {
      await dataApiDog.generateRouteDispatchRecords(route!.routeId!, 5, 10);
      _showSuccess('Dispatch record generation requests completed');
    } catch (e) {
      pp(e);
      _showError(e);
    }
    setState(() {
      busy = false;
    });
  }

  void _showError(e) {
    pp('$mm ... error happened, mounted? $mounted ');
    if (mounted) {
      showSnackBar(
          backgroundColor: Colors.red.shade800,
          textStyle: const TextStyle(color: Colors.white),
          message: '$e',
          duration: const Duration(milliseconds: 10000),
          context: context);
    }
  }

  void _showSuccess(String e) {
    if (mounted) {
      showSnackBar(
          backgroundColor: Colors.teal.shade800,
          textStyle: const TextStyle(color: Colors.white),
          message: e,
          duration: const Duration(milliseconds: 2000),
          context: context);
    }
  }

  void _generateCommuterRequests() async {
    pp('$mm ... _generateCommuterRequests ');
    setState(() {
      busy = true;
    });
    try {
      await dataApiDog.generateRouteCommuterRequests(route!.routeId!, 200, 5);
      _showSuccess('Commuter requests completed!');
    } catch (e) {
      pp(e);
      _showError(e);
    }
    setState(() {
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = 800.0, width = 400.0;
    final type = getThisDeviceType();
    if (type == 'phone') {
      height = 600;
    }
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Route Demo Manager'),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(60), child: Column(
          children: [
            RouteDropDown(
                routes: routes,
                onRoutePicked: (route) {
                  setState(() {
                    this.route = route;
                  });
                  _handleRoute();
                }),
          ],
        )),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                route == null
                    ? const SizedBox()
                    : GestureDetector(
                  onTap: (){
                    _handleRoute();
                  },
                      child: Text(
                          '${route!.name}',
                          style: myTextStyleMediumLargeWithColor(
                              context, Theme.of(context).primaryColor, 20),
                        ),
                    ),
                const SizedBox(
                  height: 24,
                ),

                Expanded(
                  child: LiveOperations(
                    height: height,
                    width: width,
                    elevation: 8.0,
                  ),
                ),
              ],
            ),
          ),
          busy
              ? const Positioned(
                  child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      backgroundColor: Colors.red,
                    ),
                  ),
                ))
              : const SizedBox(),
        ],
      ),
    ));
  }
}