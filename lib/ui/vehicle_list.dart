import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/generation_request.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lm;
import 'package:kasie_transie_library/l10n/translation_handler.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/vehicle_widgets/car_details.dart';

import 'demo_cars.dart';

class VehicleListForDemo extends StatefulWidget {
  const VehicleListForDemo({Key? key, required this.route}) : super(key: key);

  final lm.Route route;

  @override
  VehicleListForDemoState createState() => VehicleListForDemoState();
}

class VehicleListForDemoState extends State<VehicleListForDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final mm = '🌎🌎🌎🌎🌎🌎VehicleListForDemo 🍐🍐';

  bool busy = false;
  var cars = <lm.Vehicle>[];
  var carsToDisplay = <lm.Vehicle>[];
  bool showCarDetails = false;
  bool _showSearch = false;

  // late StreamSubscription<bool> compSubscription;
  lm.Vehicle? car;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    pp('$mm initState ....');

    _listen();
    _setTexts();
    _getVehicles();
  }

  void _listen() async {}

  void _getVehicles() async {
    pp('$mm ........... _getVehicles ........... ');

    setState(() {
      busy = true;
    });
    try {
      if (widget.route.associationId != null) {
        cars = await listApiDog.getAssociationVehicles(
            widget.route.associationId!, false);
      }
      //
      cars.sort((a, b) => a.vehicleReg!.compareTo(b.vehicleReg!));

      _carPlates.clear();
      for (var element in cars) {
        _carPlates.add(element.vehicleReg!);
        carsToDisplay.add(element);
      }
      if (cars.length > 19) {
        _showSearch = true;
      }
      pp('$mm ..... cars found: ${cars.length}');
    } catch (e) {
      pp(e);
    }

    setState(() {
      busy = false;
    });
  }

  Future _onCarSelected(lm.Vehicle car) async {
    pp('$mm .... car selected ... will show details ...');
    myPrettyJsonPrint(car.toJson());

    this.car = car;
    myPrettyJsonPrint(car.toJson());
    if (getThisDeviceType() == 'phone') {
      _navigateToCarDetails();
      return;
    }
    setState(() {
      showCarDetails = true;
      _showSearch = false;
    });
  }

  bool doneInitializing = false;

  final _carPlates = <String>[];

  void _runFilter(String text) {
    pp('$mm .... _runFilter: text: $text ......');
    if (text.isEmpty) {
      pp('$mm .... text is empty ......');
      carsToDisplay.clear();
      for (var project in cars) {
        carsToDisplay.add(project);
      }
      setState(() {});
      return;
    }
    carsToDisplay.clear();

    pp('$mm ...  filtering cars that contain: $text from ${_carPlates.length} car plates');
    for (var carPlate in _carPlates) {
      if (carPlate.toLowerCase().contains(text.toLowerCase())) {
        var car = _findVehicle(carPlate);
        if (car != null) {
          carsToDisplay.add(car);
        }
      }
    }
    pp('$mm .... set state with projectsToDisplay: ${carsToDisplay.length} ......');
    setState(() {});
  }

  lm.Vehicle? _findVehicle(String carPlate) {
    for (var car in cars) {
      if (car.vehicleReg!.toLowerCase() == carPlate.toLowerCase()) {
        return car;
      }
    }
    pp('$mm ..................................${E.redDot} ${E.redDot} DID NOT FIND $carPlate');

    return null;
  }

  String? search, searchVehicles, vehicles;

  Future _setTexts() async {
    final col = await prefs.getColorAndLocale();
    search = await translator.translate("search", col.locale);
    searchVehicles = await translator.translate("search", col.locale);
    vehicles = await translator.translate("vehicles", col.locale);
  }

  var demoCars = <lm.Vehicle>[];

  void _showError(Object e) {
    if (mounted) {
      showToast(
          duration: const Duration(seconds: 10),
          padding: 20,
          textStyle: myTextStyleMedium(context),
          backgroundColor: Colors.amber,
          message: 'Error starting generation: $e',
          context: context);
    }
  }

  void _showGoodMessage() {
    if (mounted) {
      showToast(
          padding: 20,
          textStyle: myTextStyleMedium(context),
          backgroundColor: Colors.teal,
          message:
              'Demo generation started OK. Watch the action on the other apps',
          context: context);
    }
  }

  void _startGeneratorForSelectedCars() async {
    setState(() {
      busy = true;
    });
    pp('\n$mm ... start generation for list of cars: ${demoCars.length}..');
    final startDate = DateTime.now()
        .toUtc()
        .subtract(const Duration(minutes: 30))
        .toIso8601String();
    final vehicleIds = <String>[];
    for (var value in demoCars) {
      vehicleIds.add(value.vehicleId!);
    }

    try {
      final gen =
          GenerationRequest(widget.route.routeId!, startDate, vehicleIds, 5);
      await dataApiDog.generateRouteDispatchRecords(gen);
      await dataApiDog.generateRouteCommuterRequests(
          widget.route.routeId!);

      _showGoodMessage();
    } catch (e) {
      pp(e);
      _showError(e);
    }

    if (mounted) {
      setState(() {
        busy = false;
      });
    }
  }

  void _navigateToDemoStarted() async {
    navigateWithScale(
        MultiCarMonitor(
          cars: demoCars,
          route: widget.route,
        ),
        context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (cars.length > 20) {
      _showSearch = true;
    }
    final height = MediaQuery.of(context).size.height;
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Monitor Vehicles',
                style: myTextStyleMediumLargeWithColor(
                    context, Theme.of(context).primaryColor, 24),
              ),
              bottom: PreferredSize(
                  preferredSize: Size.fromHeight(demoCars.isEmpty ? 160 : 220),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        busy
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 16,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      backgroundColor: Colors.pink,
                                    ),
                                  )
                                ],
                              )
                            : gapW8,
                        busy ? gapH16 : gapH4,
                        Text(
                          '${widget.route.name}',
                          style: myTextStyleMediumLargeWithColor(
                              context, Colors.teal, 16),
                        ),
                        gapH8,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Cars Selected: ',
                              style: myTextStyleSmall(context),
                            ),
                            gapW12,
                            Text(
                              '${demoCars.length}',
                              style: myTextStyleMediumLargeWithColor(
                                  context, Colors.amber, 20),
                            ),
                            const SizedBox(
                              width: 100,
                            ),
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    demoCars.clear();
                                  });
                                },
                                icon: const Icon(
                                  Icons.clear,
                                  size: 16,
                                ))
                          ],
                        ),
                        gapH16,
                        demoCars.isEmpty
                            ? gapW12
                            : SizedBox(
                                width: 300,
                                child: ElevatedButton.icon(
                                    onPressed: () {
                                      _startGeneratorForSelectedCars();
                                    },
                                    icon: const Icon(Icons.airport_shuttle),
                                    label: const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Text('Start Demo Generation'),
                                    )),
                              ),
                        SizedBox(
                          height: demoCars.isEmpty ? 24 : 36,
                        ),
                      ],
                    ),
                  )),
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      shape: getDefaultRoundedBorder(),
                      elevation: 8,
                      child: SizedBox(
                        height: height,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: _showSearch ? 100 : 8,
                            ),
                            cars.isEmpty
                                ? Center(
                                    child: SizedBox(
                                      height: 120,
                                      child: Column(
                                        children: [
                                          Text(
                                            'No cars found',
                                            style:
                                                myTextStyleMediumLargeWithColor(
                                                    context,
                                                    Theme.of(context)
                                                        .primaryColorLight,
                                                    24),
                                          ),
                                          const SizedBox(
                                            height: 32,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Expanded(
                                    child: bd.Badge(
                                      badgeContent: Text(
                                        '${cars.length}',
                                        style: myTextStyleTiny(context),
                                      ),
                                      position: bd.BadgePosition.topEnd(
                                          top: 12, end: 12),
                                      badgeStyle: bd.BadgeStyle(
                                          badgeColor: Colors.green[900]!,
                                          padding: const EdgeInsets.all(8)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: GridView.builder(
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 3),
                                            itemCount: carsToDisplay.length,
                                            itemBuilder: (ctx, index) {
                                              final car = carsToDisplay
                                                  .elementAt(index);
                                              var color = Colors.white;
                                              var found = false;
                                              for (var value in demoCars) {
                                                if (car.vehicleId ==
                                                    value.vehicleId) {
                                                  color = Colors.green;
                                                  found = true;
                                                }
                                              }
                                              return GestureDetector(
                                                onTap: () {
                                                  _addToCars(car);
                                                  setState(() {});
                                                },
                                                child: Card(
                                                  shape: getRoundedBorder(
                                                      radius: 16),
                                                  elevation: 12,
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.airport_shuttle,
                                                          color: color,
                                                        ),
                                                        gapH8,
                                                        Text(
                                                          '${car.vehicleReg}',
                                                          style: myTextStyleMediumLargeWithColor(
                                                              context,
                                                              found
                                                                  ? color
                                                                  : Theme.of(
                                                                          context)
                                                                      .primaryColor,
                                                              14),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                      ),
                                    ),
                                  )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                showCarDetails
                    ? Positioned(
                        top: -48,
                        bottom: 0,
                        child: CarDetails(
                          vehicle: car!,
                          onClose: () {
                            setState(() {
                              showCarDetails = false;
                              if (cars.length > 19) {
                                _showSearch = true;
                              }
                            });
                          },
                        ))
                    : const SizedBox(),
                _showSearch
                    ? Positioned(
                        top: 0,
                        child: SizedBox(
                          height: 100,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 300,
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20.0, horizontal: 12.0),
                                    child: TextField(
                                      controller: _textEditingController,
                                      onChanged: (text) {
                                        pp(' ........... changing to: $text');
                                        _runFilter(text);
                                      },
                                      decoration: InputDecoration(
                                          label: Text(
                                            search == null ? 'Search' : search!,
                                            style: myTextStyleSmall(
                                              context,
                                            ),
                                          ),
                                          icon: Icon(
                                            Icons.search,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          border: const OutlineInputBorder(),
                                          hintText: searchVehicles == null
                                              ? 'Search Vehicles'
                                              : searchVehicles!,
                                          hintStyle: myTextStyleSmallWithColor(
                                              context,
                                              Theme.of(context).primaryColor)),
                                    )),
                              ),
                              const SizedBox(
                                width: 0,
                              ),
                              bd.Badge(
                                position: bd.BadgePosition.topEnd(),
                                badgeContent: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text('${carsToDisplay.length}',
                                      style: myTextStyleTiny(
                                        context,
                                      )),
                                ),
                              )
                            ],
                          ),
                        ))
                    : const SizedBox()
              ],
            )));
  }

  void _addToCars(lm.Vehicle car) {
    pp('$mm adding to cars, ${demoCars.length}, adding ${car.vehicleReg}');
    demoCars.add(car);
    pp('$mm added to cars, ${demoCars.length}');
  }

  void _navigateToCarDetails() {
    if (car == null) {
      return;
    }
    navigateWithScale(
        CarDetails(
          vehicle: car!,
          onClose: () {
            setState(() {
              showCarDetails = false;
              if (cars.length > 19) {
                _showSearch = true;
              }
            });
          },
        ),
        context);
  }
}
