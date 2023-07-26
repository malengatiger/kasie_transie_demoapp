import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
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
  final mm = '${E.leaf2}${E.leaf2}${E.leaf2} DemoLanding: ';

  var dispatches = <lib.DispatchRecord>[];
  var requests = <lib.CommuterRequest>[];
  var heartbeats = <lib.VehicleHeartbeat>[];
  var passengerCounts = <lib.AmbassadorPassengerCount>[];
  late StreamSubscription<lib.AmbassadorPassengerCount> passengerSub;
  late StreamSubscription<lib.DispatchRecord> dispatchSub;
  late StreamSubscription<lib.CommuterRequest> requestSub;
  late StreamSubscription<lib.VehicleHeartbeat> heartbeatSub;

  bool busy = false;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
  }

  void _listen() async {
    pp('\n\n$mm ... listening to FCM topics .......................... ');

    passengerSub = fcmBloc.passengerCountStream.listen((event) {
      pp('$mm ... passengerCountStream delivered a count : ${event.vehicleReg} ');
      // myPrettyJsonPrint(event.toJson());
      passengerCounts.add(event);
      if (mounted) {
        setState(() {});
      }
    });
    dispatchSub = fcmBloc.dispatchStream.listen((event) {
      pp('$mm ... dispatchStream delivered a dispatch record : ${event.vehicleReg} ${event.landmarkName}');
      // myPrettyJsonPrint(event.toJson());
      dispatches.add(event);
      if (mounted) {
        setState(() {});
      }
    });
    requestSub = fcmBloc.commuterRequestStreamStream.listen((event) {
      pp('$mm ... commuterRequestStreamStream delivered a request : ${event.routeLandmarkName}');
      // myPrettyJsonPrint(event.toJson());
      requests.add(event);
      if (mounted) {
        setState(() {});
      }
    });
    heartbeatSub = fcmBloc.heartbeatStreamStream.listen((event) {
      pp('$mm ... heartbeatStreamStream delivered a heartbeat : ${event.vehicleReg}');
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
          widget.association.associationId!, 100, 2);
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
      dataApiDog.generateHeartbeats(widget.association.associationId!, 20, 1);
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
          widget.association.associationId!, 12, 2);
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
          widget.association.associationId!, 50, 1);
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

  @override
  void dispose() {
    _controller.dispose();
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
                        'Demo Driver',
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
                      height: 64,
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
                      height: 24,
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
                      height: 24,
                    ),
                    SizedBox(
                      width: 300,
                      child: Card(
                        shape: getRoundedBorder(radius: 16),
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
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Generate Passenger Counts'),
                                )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    SizedBox(
                      width: 300,
                      child: Card(
                        shape: getRoundedBorder(radius: 16),
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
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Generate Commuter Requests'),
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
