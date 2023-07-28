import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/maps/cluster_maps/cluster_map_controller.dart';
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/widgets/language_and_color_chooser.dart';
import 'package:badges/badges.dart' as bd;


class DemoLanding extends StatefulWidget {
  const DemoLanding({Key? key, required this.association}) : super(key: key);

  final lib.Association association;

  @override
  DemoLandingState createState() => DemoLandingState();
}

class DemoLandingState extends State<DemoLanding>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final mm = '${E.leaf2}${E.leaf2}${E.leaf2}${E.leaf2}${E.leaf2}${E.leaf2} DemoLanding: '
      '${E.leaf2}${E.leaf2}${E.leaf2}';

  var dispatches = <lib.DispatchRecord>[];
  var requests = <lib.CommuterRequest>[];
  var heartbeats = <lib.VehicleHeartbeat>[];
  var arrivals = <lib.VehicleArrival>[];

  var passengerCounts = <lib.AmbassadorPassengerCount>[];
  late StreamSubscription<lib.AmbassadorPassengerCount> passengerSub;
  late StreamSubscription<lib.DispatchRecord> dispatchSub;
  late StreamSubscription<lib.CommuterRequest> requestSub;
  late StreamSubscription<lib.VehicleHeartbeat> heartbeatSub;
  late StreamSubscription<lib.VehicleArrival> arrivalsSub;


  bool busy = false;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
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

  void _generateHeartbeats() async {
    pp('$mm ... _generateHeartbeats ');
    setState(() {
      busy = true;
    });
    try {
      dataApiDog.generateHeartbeats(widget.association.associationId!, 30, 1);
      pp('$mm ... _generateHeartbeats done: ${heartbeats.length}');
      _showSuccess('Heartbeat generation sent to backend');
    } catch (e) {
      pp(e);
      _showError(e);
    }
    setState(() {
      busy = false;
    });
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
          widget.association.associationId!, 80, 1);
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

  void _navigateToRouteList() {
   navigateWithScale(const ClusterMapController(), context);
  }

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
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.association.associationName!,
          style: myTextStyleMediumLargeWithColor(
              context, Theme.of(context).primaryColor, 14),
        ),
        actions: [
          IconButton(onPressed: (){
            _navigateToRouteList();
          }, icon: Icon(Icons.map, color: Theme.of(context).primaryColor,)),
        ],
      ),
      body: Stack(
        children: [
          SizedBox(
            width: w,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: getRoundedBorder(radius: 16),
                elevation: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                            context, Theme.of(context).primaryColorLight, 32),
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
                    const SizedBox(
                      height: 36,
                    ),
                    SizedBox(
                      width: 300,
                      child: Card(
                        shape: getRoundedBorder(radius: 8),
                        elevation: 8,
                        child: bd.Badge(
                          badgeContent: Text(
                            '${dispatches.length}',
                            style: myTextStyleTiny(context),
                          ),
                          badgeStyle: bd.BadgeStyle(
                            elevation: 12,
                            badgeColor: Colors.deepOrange.shade600,
                            padding: const EdgeInsets.all(8),
                          ),
                          child: TextButton(
                              onPressed: () {
                                _generateDispatchRecords();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Generate Dispatch Records'),
                              )),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                      width: 300,
                      child: Card(
                        shape: getRoundedBorder(radius: 8),
                        elevation: 8,
                        child: bd.Badge(
                          badgeContent: Text(
                            '${heartbeats.length}',
                            style: myTextStyleTiny(context),
                          ),
                          badgeStyle: bd.BadgeStyle(
                            elevation: 12,
                            badgeColor: Colors.teal.shade800,
                            padding: const EdgeInsets.all(8),
                          ),
                          child: TextButton(
                              onPressed: () {
                                _generateHeartbeats();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Generate Vehicle Heartbeats'),
                              )),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                      width: 300,
                      child: Card(
                        shape: getRoundedBorder(radius: 8),
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: bd.Badge(
                            badgeContent: Text(
                              '${passengerCounts.length}',
                              style: myTextStyleTiny(context),
                            ),
                            badgeStyle: bd.BadgeStyle(
                              elevation: 12,
                              badgeColor: Colors.pink.shade800,
                              padding: const EdgeInsets.all(8),
                            ),
                            child: TextButton(
                                onPressed: () {
                                  _generatePassengerCounts();
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Generate Passenger Counts'),
                                )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                      width: 300,
                      child: Card(
                        shape: getRoundedBorder(radius: 8),
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: bd.Badge(
                            badgeContent: Text(
                              '${requests.length}',
                              style: myTextStyleTiny(context),
                            ),
                            badgeStyle: bd.BadgeStyle(
                              elevation: 12,
                              badgeColor: Colors.blue.shade800,
                              padding: const EdgeInsets.all(8),
                            ),
                            child: TextButton(
                                onPressed: () {
                                  _generateCommuterRequests();
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Generate Commuter Requests'),
                                )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                      width: 300,
                      child: Card(
                        shape: getRoundedBorder(radius: 8),
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: bd.Badge(
                            badgeContent: Text(
                              '${arrivals.length}',
                              style: myTextStyleTiny(context),
                            ),
                            badgeStyle: bd.BadgeStyle(
                              elevation: 12,
                              badgeColor: Colors.green.shade800,
                              padding: const EdgeInsets.all(8),
                            ),
                            child: TextButton(
                                onPressed: () {
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Accept Vehicle Arrivals'),
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    ));
  }
}
