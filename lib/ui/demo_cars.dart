import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:badges/badges.dart' as bd;

class MultiCarMonitor extends StatefulWidget {
  const MultiCarMonitor({super.key, required this.cars, required this.route});

  final List<lib.Vehicle> cars;
  final lib.Route route;

  @override
  State<MultiCarMonitor> createState() => _MultiCarMonitorState();
}

class _MultiCarMonitorState extends State<MultiCarMonitor> {
  late StreamSubscription<lib.DispatchRecord> dispatchStreamSub;
  late StreamSubscription<lib.AmbassadorPassengerCount> passengerStreamSub;
  late StreamSubscription<lib.VehicleArrival> arrivalStreamSub;
  late StreamSubscription<lib.VehicleDeparture> departureStreamSub;
  late StreamSubscription<lib.VehicleHeartbeat> heartbeatStreamSub;
  final mm = '🍐🍐🍐🍐DemoCars 🍐🍐';

  int dispatches = 0;
  int passengerCounts = 0;
  int heartbeats = 0;
  int departures = 0;
  int arrivals = 0;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() async {
    pp('$mm ... listening to fcm events .......');
    dispatchStreamSub = fcmBloc.dispatchStream.listen((event) {
      pp('$mm ... dispatchStream delivered event: ${event.vehicleReg}');
      if (_isCarValid(event.vehicleId!)) {
        dispatches++;
        int index = _getHighlightIndex(event.vehicleId);
        if (mounted) {
          setState(() {
            highlightIndex = index;
          });
        }
      }
    });
    //
    heartbeatStreamSub = fcmBloc.heartbeatStreamStream.listen((event) {
      pp('$mm ... heartbeatStreamStream delivered event: ${event.vehicleReg}');
      if (_isCarValid(event.vehicleId!)) {
        heartbeats++;
        int index = _getHighlightIndex(event.vehicleId);
        if (mounted) {
          setState(() {
            highlightIndex = index;
          });
        }
      }
    });
    //
    passengerStreamSub = fcmBloc.passengerCountStream.listen((event) {
      pp('$mm ... passengerCountStream delivered event: ${event.vehicleReg}');
      if (_isCarValid(event.vehicleId!)) {
        passengerCounts += event.passengersIn!;
        int index = _getHighlightIndex(event.vehicleId);
        if (mounted) {
          setState(() {
            highlightIndex = index;
          });
        }
      }
    });
    //
    arrivalStreamSub = fcmBloc.vehicleArrivalStream.listen((event) {
      pp('$mm ... vehicleArrivalStream delivered event: ${event.vehicleReg}');
      if (_isCarValid(event.vehicleId!)) {
        arrivals++;
        int index = _getHighlightIndex(event.vehicleId);
        if (mounted) {
          setState(() {
            highlightIndex = index;
          });
        }
      }
    });
    //
    departureStreamSub = fcmBloc.vehicleDepartureStream.listen((event) {
      pp('$mm ... vehicleDepartureStream delivered event: ${event.vehicleReg}');
      if (_isCarValid(event.vehicleId!)) {
        departures++;
        int index = _getHighlightIndex(event.vehicleId);
        if (mounted) {
          setState(() {
            highlightIndex = index;
          });
        }
      }
    });
  }

  bool _isCarValid(String vehicleId) {
    for (var value in widget.cars) {
      if (value.vehicleId == vehicleId) {
        return true;
      }
    }
    return false;
  }

  int highlightIndex = -1;

  @override
  void dispose() {
    dispatchStreamSub.cancel();
    passengerStreamSub.cancel();
    arrivalStreamSub.cancel();
    departureStreamSub.cancel();
    heartbeatStreamSub.cancel();
    pp('$mm stream subscriptions cancelled!');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vehicles Monitor'),
        ),
        body: Card(
          shape: getDefaultRoundedBorder(),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                gapH16,
                Text(
                  '${widget.route.name}',
                  style: myTextStyleMediumLargeWithColor(
                      context, Theme.of(context).primaryColor, 18),
                ),
                gapH16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Number of Cars:',
                      style: myTextStyleSmall(context),
                    ),
                    gapW12,
                    Text('${widget.cars.length}',
                        style: myTextStyleMediumLargeWithColor(
                            context, Colors.green, 20)),
                  ],
                ),
                gapH16,
                gapH32,
                EventsTab(
                    dispatches: dispatches,
                    arrivals: arrivals,
                    departures: departures,
                    passengerCounts: passengerCounts,
                    heartbeats: heartbeats),
                gapH32,
                gapH32,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      itemCount: widget.cars.length,
                      itemBuilder: (ctx, index) {
                        final car = widget.cars.elementAt(index);
                        var color = Theme.of(context).primaryColorLight;
                        var iconSize = 18.0;
                        if (index == highlightIndex) {
                          color = Colors.amberAccent;
                          iconSize = 26.0;
                        }
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            shape: getRoundedBorder(radius: 8),
                            elevation: 12,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.airport_shuttle,
                                  color: color, size: iconSize,
                                ),
                                gapH8,
                                Text(
                                  '${car.vehicleReg}',
                                  style: myTextStyleMediumLargeWithColor(
                                      context, color, 14),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getHighlightIndex(String? vehicleId) {
    var index = 0;
    for (var value in widget.cars) {
      if (value.vehicleId == vehicleId) {
        return index;
      }
      index++;
    }
    return -1;
  }
}

class EventsTab extends StatelessWidget {
  const EventsTab(
      {super.key,
      required this.dispatches,
      required this.arrivals,
      required this.departures,
      required this.passengerCounts,
      required this.heartbeats});

  final int dispatches, arrivals, departures, passengerCounts, heartbeats;
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: getRoundedBorder(radius: 8),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: 56,
              child: Column(
                children: [
                  bd.Badge(
                    badgeContent: Text(
                      '$dispatches',
                      style: myTextStyleSmall(context),
                    ),
                    badgeStyle: const bd.BadgeStyle(
                      badgeColor: Colors.deepOrange,
                      elevation: 16,
                      padding: EdgeInsets.all(8),
                    ),
                  ),
                  gapH4,
                  Text(
                    'Dispatches',
                    style: myTextStyleTiniest(context),
                  ),
                ],
              ),
            ),
            gapW8,
            SizedBox(
              height: 56,
              child: Column(
                children: [
                  bd.Badge(
                    badgeContent:
                        Text('$heartbeats', style: myTextStyleSmall(context)),
                    badgeStyle: const bd.BadgeStyle(
                      badgeColor: Colors.green,
                      elevation: 16,
                      padding: EdgeInsets.all(8),
                    ),
                  ),
                  gapH4,
                  Text(
                    'Heartbeats',
                    style: myTextStyleTiniest(context),
                  ),
                ],
              ),
            ),
            gapW8,
            SizedBox(
              height: 56,
              child: Column(
                children: [
                  bd.Badge(
                    badgeContent: Text('$passengerCounts',
                        style: myTextStyleSmall(context)),
                    badgeStyle: const bd.BadgeStyle(
                      badgeColor: Colors.pink,
                      elevation: 16,
                      padding: EdgeInsets.all(8),
                    ),
                  ),
                  gapH4,
                  Text(
                    'Passengers',
                    style: myTextStyleTiniest(context),
                  ),
                ],
              ),
            ),
            gapW8,
            SizedBox(
              height: 56,
              child: Column(
                children: [
                  bd.Badge(
                    badgeContent:
                        Text('$arrivals', style: myTextStyleSmall(context)),
                    badgeStyle: const bd.BadgeStyle(
                      badgeColor: Colors.blue,
                      elevation: 16,
                      padding: EdgeInsets.all(8),
                    ),
                  ),
                  gapH4,
                  Text(
                    'Arrivals',
                    style: myTextStyleTiniest(context),
                  ),
                ],
              ),
            ),
            gapW8,
            SizedBox(
              height: 56,
              child: Column(
                children: [
                  bd.Badge(
                    badgeContent:
                        Text('$departures', style: myTextStyleSmall(context)),
                    badgeStyle: bd.BadgeStyle(
                      badgeColor: Colors.amber.shade900,
                      elevation: 16,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  gapH4,
                  Text(
                    'Departures',
                    style: myTextStyleTiniest(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
