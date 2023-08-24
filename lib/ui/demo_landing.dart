import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:kasie_transie_demoapp/ui/vehicle_list.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/isolates/routes_isolate.dart';
import 'package:kasie_transie_library/maps/association_route_maps.dart';
import 'package:kasie_transie_library/maps/cluster_maps/cluster_map_controller.dart';
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/zip_handler.dart';
import 'package:kasie_transie_library/widgets/language_and_color_chooser.dart';
import 'package:kasie_transie_library/widgets/route_list_minimum.dart';
import 'package:kasie_transie_library/widgets/route_widgets/route_manager.dart';
import 'package:kasie_transie_library/widgets/timer_widget.dart';

class DemoLanding extends StatefulWidget {
  const DemoLanding({Key? key, required this.association}) : super(key: key);

  final lib.Association association;

  @override
  DemoLandingState createState() => DemoLandingState();
}

class DemoLandingState extends State<DemoLanding>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final mm =
      '${E.leaf2}${E.leaf2}${E.leaf2}${E.leaf2}${E.leaf2}${E.leaf2} DemoLanding: '
      '${E.leaf2}${E.leaf2}${E.leaf2}';

  var dispatches = <lib.DispatchRecord>[];
  var requests = <lib.CommuterRequest>[];
  var heartbeats = <lib.VehicleHeartbeat>[];
  var arrivals = <lib.VehicleArrival>[];
  var departures = <lib.VehicleDeparture>[];
  var passengerCounts = <lib.AmbassadorPassengerCount>[];

  //
  late StreamSubscription<lib.AmbassadorPassengerCount> passengerSub;
  late StreamSubscription<lib.DispatchRecord> dispatchSub;
  late StreamSubscription<lib.CommuterRequest> requestSub;
  late StreamSubscription<lib.VehicleHeartbeat> heartbeatSub;
  late StreamSubscription<lib.VehicleArrival> arrivalsSub;
  late StreamSubscription<lib.VehicleDeparture> departureSub;

  bool busy = false;
  var routes = <lib.Route>[];
  lib.Route? route;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _getRoutes(false);
  }

  void _listen() async {
    pp('\n\n$mm ... listening to FCM topics .......................... ');

    arrivalsSub = fcmBloc.vehicleArrivalStream.listen((event) {
      pp('$mm ... vehicleArrivalStream delivered an arrival \t${E.appleRed} '
          '${event.vehicleReg} at ${event.landmarkName} ${E.blueDot} date: ${event.created}');
      // myPrettyJsonPrint(event.toJson());
      arrivals.add(event);
      if (mounted) {
        setState(() {});
      }
    });
    departureSub = fcmBloc.vehicleDepartureStream.listen((event) {
      pp('$mm ... vehicleDepartureStream delivered a departure \t${E.appleRed} '
          '${event.vehicleReg} at ${event.landmarkName} ${E.blueDot} date: ${event.created}');
      // myPrettyJsonPrint(event.toJson());
      departures.add(event);
      if (mounted) {
        setState(() {});
      }
    });
    passengerSub = fcmBloc.passengerCountStream.listen((event) {
      pp('$mm ... passengerCountStream delivered a count \t ${E.pear} ${event.vehicleReg} '
          '${E.blueDot} date:  ${event.created}');
      // myPrettyJsonPrint(event.toJson());
      pp('$mm ... PassengerCountCover - cluster item: ${E.appleRed} ${event.vehicleReg}'
          '\n${E.leaf} passengersIn: ${event.passengersIn} '
          '\n${E.leaf} passengersOut: ${event.passengersOut} '
          '\n${E.leaf} currentPassengers: ${event.currentPassengers}');
      passengerCounts.add(event);
      if (mounted) {
        setState(() {});
      }
    });
    dispatchSub = fcmBloc.dispatchStream.listen((event) {
      pp('$mm ... dispatchStream delivered a dispatch record \t '
          '${E.appleGreen} ${event.vehicleReg} ${event.landmarkName} ${E.blueDot} date:  ${event.created}');
      // myPrettyJsonPrint(event.toJson());
      dispatches.add(event);
      if (mounted) {
        setState(() {});
      }
    });
    requestSub = fcmBloc.commuterRequestStreamStream.listen((event) {
      pp('$mm ... commuterRequestStreamStream delivered a request \t ${E.appleRed} '
          '${event.routeLandmarkName} ${E.blueDot} date:  ${event.dateRequested}');
      // myPrettyJsonPrint(event.toJson());
      requests.add(event);
      if (mounted) {
        setState(() {});
      }
    });
    heartbeatSub = fcmBloc.heartbeatStreamStream.listen((event) {
      pp('$mm ... heartbeatStreamStream delivered a heartbeat \t '
          '${E.appleRed} ${event.vehicleReg} ${E.blueDot} date:  ${event.created}');
      // myPrettyJsonPrint(event.toJson());
      heartbeats.add(event);
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _getRoutes(bool refresh) async {
    pp('$mm ... get routes for ${widget.association.associationName}');
    setState(() {
      busy = true;
    });
    if (refresh) {
      final bags = await zipHandler.getRouteBags(associationId: widget.association.associationId!);
      routes.clear();
      for (var value in bags!.routeBags) {
        routes.add(value.route!);
}
    } else {
      routes = await listApiDog.getRoutes(
          AssociationParameter(widget.association.associationId!, refresh));
    }
    pp('$mm ... routes found: ${routes.length}');

    setState(() {
      busy = false;
    });
  }

  void _generateDispatchRecords() async {
    pp('$mm ... _generateDispatchRecords');
    setState(() {
      busy = true;
    });
    try {
      dataApiDog.generateDispatchRecords(
          widget.association.associationId!, 10, 2);
      pp('$mm ... _generateDispatchRecords done: ${dispatches.length}');
      _showSuccess('Dispatch record generation sent to backend');
    } catch (e) {
      pp(e);
      _showError(e);
    }
    setState(() {
      busy = false;
    });
  }

  void _showError(e) {
    if (mounted) {
      showSnackBar(
          backgroundColor: Colors.red.shade800,
          textStyle: const TextStyle(color: Colors.white),
          message: '$e',
          context: context);
    }
  }

  void _showSuccess(String e) {
    if (mounted) {
      showSnackBar(
          backgroundColor: Colors.teal.shade800,
          textStyle: const TextStyle(color: Colors.white),
          message: e,
          context: context);
    }
  }

  void _generatePassengerCounts() async {
    pp('$mm ... _generatePassengerCounts ');
    setState(() {
      busy = true;
    });
    try {
      dataApiDog.generateAmbassadorPassengerCounts(
          widget.association.associationId!, 30, 2);
      pp('$mm ... _generatePassengerCounts done: ${passengerCounts.length}');
      _showSuccess('Passenger counts generation started');
    } catch (e) {
      pp(e);
      _showError(e);
    }
    setState(() {
      busy = false;
    });
  }

  void _generateCommuterRequests() async {
    pp('$mm ... _generateCommuterRequests ');
    setState(() {
      busy = true;
    });
    try {
      dataApiDog.generateCommuterRequests(
          widget.association.associationId!, 200, 5);
      pp('$mm ... _generateCommuterRequests done: ${requests.length}');
      _showSuccess('Commuter requests generation jumping!');
    } catch (e) {
      pp(e);
      _showError(e);
    }
    setState(() {
      busy = false;
    });
  }

  void _navigateToClusterMaps() {
    navigateWithScale(const ClusterMapController(), context);
  }

  void _navigateToVehicles(lib.Route route) {
    pp('$mm _navigateToVehicles ....');
    navigateWithScale(VehicleListForDemo(route: route), context);
  }

  void _navigateToRouteManager() {
    navigateWithScale(
        RouteManager(
          association: widget.association,
        ),
        context);
  }

  bool showRouteList = false;
  @override
  void dispose() {
    _controller.dispose();
    arrivalsSub.cancel();
    requestSub.cancel();
    heartbeatSub.cancel();
    dispatchSub.cancel();
    passengerSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final type = getThisDeviceType();
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          "Demonstrations",
          style: myTextStyleMediumLargeWithColor(
              context, Theme.of(context).primaryColor, 14),
        ),
        actions: [
          IconButton(
              onPressed: () {
                _getRoutes(true);
              },
              icon: Icon(
                Icons.refresh,
                color: Theme.of(context).primaryColor,
              )),
          IconButton(
              onPressed: () {
                _navigateToClusterMaps();
              },
              icon: Icon(
                Icons.map,
                color: Theme.of(context).primaryColor,
              )),
          IconButton(
              onPressed: () {
                _navigateToRouteManager();
              },
              icon: Icon(
                Icons.roundabout_right,
                color: Theme.of(context).primaryColor,
              )),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: getRoundedBorder(radius: 16),
                  elevation: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      gapH16,
                      Text(
                        '${widget.association.associationName}',
                        style: myTextStyleMediumLargeWithColor(
                            context, Theme.of(context).primaryColorLight, 14),
                      ),
                      gapH16,
                      GestureDetector(
                        onTap: () {
                          navigateWithScale(
                              LanguageAndColorChooser(
                                onLanguageChosen: () {},
                              ),
                              context);
                        },
                        child: Text(
                          'KT Demo Driver',
                          style: myTextStyleMediumLargeWithColor(
                              context, Theme.of(context).primaryColorLight, 28),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Generate data to make demos more interactive and to enable the '
                          'display of the collaboration between all the personnel and vehicles ',
                          style: myTextStyleSmall(context),
                        ),
                      ),
                      gapH16,
                      ElevatedButton(
                          onPressed: () {
                            pp('................... button pressed');
                            navigateWithScale(RouteListMinimum(onRoutePicked: (route){
                              _navigateToVehicles(route);
                            }, association: widget.association,), context);
                          },
                          child: const SizedBox(width: 260,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Select Route'),
                            ),
                          )),
                      const SizedBox(
                        height: 36,
                      ),

                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: SingleChildScrollView(
                  child: Displays(
                      dispatches: dispatches.length,
                      heartbeats: heartbeats.length,
                      passengerCounts: passengerCounts.length,
                      arrivals: arrivals.length,
                      requests: requests.length,
                      departures: departures.length),
                ),
              )
            ],
          ),
          busy
              ? const Positioned(
                  child: Center(
                    child: TimerWidget(
                      title: 'Loading route data afresh ...',
                      subTitle: 'Hang in there! This may take a little while ', isSmallSize: false,
                    ),
                  ),
                )
              : gapH8,
        ],
      ),
    ));
  }
}

class Displays extends StatelessWidget {
  const Displays(
      {super.key,
      required this.dispatches,
      required this.heartbeats,
      required this.passengerCounts,
      required this.arrivals,
      required this.requests,
      required this.departures});

  final int dispatches,
      heartbeats,
      passengerCounts,
      arrivals,
      requests,
      departures;
  @override
  Widget build(BuildContext context) {
    final type = getThisDeviceType();
    return SizedBox(
      height: 600,
      child: ListView(
        children: [
          SizedBox(
            width: type == 'phone' ? 280 : 360,
            child: Card(
              shape: getRoundedBorder(radius: 8),
              elevation: 8,
              child: bd.Badge(
                badgeContent: Text(
                  '$dispatches',
                  style: myTextStyleTiny(context),
                ),
                badgeStyle: bd.BadgeStyle(
                  elevation: 12,
                  badgeColor: Colors.deepOrange.shade600,
                  padding: const EdgeInsets.all(8),
                ),
                child: TextButton(
                    onPressed: () {
                      // _generateDispatchRecords();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Dispatch Records',
                        style: type == 'phone'
                            ? myTextStyleSmall(context)
                            : myTextStyleMedium(context),
                      ),
                    )),
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          SizedBox(
            width: type == 'phone' ? 280 : 360,
            child: Card(
              shape: getRoundedBorder(radius: 8),
              elevation: 8,
              child: bd.Badge(
                badgeContent: Text(
                  '$heartbeats',
                  style: myTextStyleTiny(context),
                ),
                badgeStyle: bd.BadgeStyle(
                  elevation: 12,
                  badgeColor: Colors.teal.shade800,
                  padding: const EdgeInsets.all(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Vehicle Heartbeats',
                    style: type == 'phone'
                        ? myTextStyleSmall(context)
                        : myTextStyleMedium(context),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          SizedBox(
            width: type == 'phone' ? 280 : 360,
            child: Card(
              shape: getRoundedBorder(radius: 8),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: bd.Badge(
                  badgeContent: Text(
                    '$passengerCounts',
                    style: myTextStyleTiny(context),
                  ),
                  badgeStyle: bd.BadgeStyle(
                    elevation: 12,
                    badgeColor: Colors.pink.shade800,
                    padding: const EdgeInsets.all(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Passenger Counts',
                      style: type == 'phone'
                          ? myTextStyleSmall(context)
                          : myTextStyleMedium(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          SizedBox(
            width: type == 'phone' ? 280 : 360,
            child: Card(
              shape: getRoundedBorder(radius: 8),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: bd.Badge(
                  badgeContent: Text(
                    '$requests',
                    style: myTextStyleTiny(context),
                  ),
                  badgeStyle: bd.BadgeStyle(
                    elevation: 12,
                    badgeColor: Colors.blue.shade800,
                    padding: const EdgeInsets.all(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Commuter Requests',
                      style: type == 'phone'
                          ? myTextStyleSmall(context)
                          : myTextStyleMedium(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          SizedBox(
            width: type == 'phone' ? 280 : 360,
            child: Card(
              shape: getRoundedBorder(radius: 8),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: bd.Badge(
                  badgeContent: Text(
                    '$arrivals',
                    style: myTextStyleTiny(context),
                  ),
                  badgeStyle: bd.BadgeStyle(
                    elevation: 12,
                    badgeColor: Colors.green.shade800,
                    padding: const EdgeInsets.all(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Vehicle Arrivals',
                      style: type == 'phone'
                          ? myTextStyleSmall(context)
                          : myTextStyleMedium(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: type == 'phone' ? 280 : 360,
            child: Card(
              shape: getRoundedBorder(radius: 8),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: bd.Badge(
                  badgeContent: Text(
                    '$departures',
                    style: myTextStyleTiny(context),
                  ),
                  badgeStyle: bd.BadgeStyle(
                    elevation: 12,
                    badgeColor: Colors.indigo.shade800,
                    padding: const EdgeInsets.all(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Vehicle Departures',
                      style: type == 'phone'
                          ? myTextStyleSmall(context)
                          : myTextStyleMedium(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
