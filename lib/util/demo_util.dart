import 'dart:math';

import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:realm/realm.dart';

final DemoUtil demoUtil = DemoUtil();
const xy = '🌀🌀🌀🌀🌀DemoUtil';
final Random rand = Random(DateTime.now().millisecondsSinceEpoch);

class DemoUtil {
  final Random rand = Random(DateTime.now().millisecondsSinceEpoch);

  Future startDemo({required Route route, required List<Vehicle> cars}) async {

    final marks = await listApiDog.getRouteLandmarks(route.routeId!, false);
    final points = await listApiDog.getRoutePoints(route.routeId!, false);

   // _heavyForCommuters(route: route, marks: marks);
    for (var car in cars) {
      await demoOneCar(route: route, vehicle: car, marks: marks, points: points);
      await Future.delayed(Duration(seconds: rand.nextInt(20)));
    }

  }
    Future demoOneCar({required Route route, required Vehicle vehicle,
    required List<RouteLandmark> marks, required List<RoutePoint> points}) async {
    pp('\n\n\n🔵🔵🔵🔵🔵🔵🔵🔵🔵 Demo starting, data to be added inside '
        'Isolates; car: ${E.redDot} ${vehicle.vehicleReg} '
        'on route: ${route.name}  🔵🔵🔵🔵🔵🔵🔵🔵🔵\n\n\n');

    // _heavyTaskForPassengerCounts(route: route, vehicle: vehicle, points: points, marks: marks);
    _heavyTaskForActivity(
        route: route, vehicle: vehicle, points: points, marks: marks);
    await _heavyTaskForHeartbeats(vehicle: vehicle, points: points, marks: marks);
  }

  Future _heavyForCommuters({
    required Route route,
    required List<RouteLandmark> marks,
  }) async {

    var rootDate = DateTime.now().toUtc().subtract(const Duration(minutes: 60));

    const max = 320;
    final commuters = await listApiDog.getRandomCommuters(max);
    final x = commuters.length ~/ marks.length;
    int cnt = 0;
    for (var m in marks) {
      var commutersPerLandmark = rand.nextInt(x);
      pp('\n\n$xx ... ${E.peach}${E.peach}${E.peach} generating $commutersPerLandmark '
          'commuter requests for ${E.peach} ${m.landmarkName}');
      for (var i = 0; i < commutersPerLandmark; i++) {
        final index = rand.nextInt((max - 1) - cnt);
        final comm = commuters.elementAt(index);
        var num = rand.nextInt(12);
        if (num == 0) num = 1;
        final pos =  generateRandomLocation(m.position!.coordinates[1], m.position!.coordinates[0]);
        final cr = CommuterRequest(ObjectId(),
          routeId: route.routeId,
          routeName: route.name,
          associationId: route.associationId,
          routeLandmarkId: m.landmarkId,
          routeLandmarkName: m.landmarkName,
          numberOfPassengers: num,
          commuterId: comm.commuterId,
          commuterRequestId: Uuid.v4().toString(),
          dateNeeded: rootDate.toIso8601String(),
          dateRequested: rootDate.toIso8601String(),
          distanceToRouteLandmarkInMetres: pos.$2,
          currentPosition: pos.$1,
        );
        await dataApiDog.addCommuterRequest(cr);
        commuters.removeAt(index);
        cnt++;
        var w = rand.nextInt(10);
        if (w < 4) w = 4;
        await _wait(w, rootDate);
      }
    }
  }
  // Function to generate a random location within a radius of 2000 meters
  (Position, double) generateRandomLocation(double latitude, double longitude) {
    const double radius = 3000; // Radius in meters

    // Convert latitude and longitude to radians
    final double latRadians = latitude * pi / 180;
    final double lonRadians = longitude * pi / 180;

    // Generate random distance and bearing
    final double distance = sqrt(Random().nextDouble()) * radius;
    final double bearing = Random().nextDouble() * 2 * pi;

    // Calculate new latitude and longitude
    final double newLatRadians =
    asin(sin(latRadians) * cos(distance / 6371000) +
        cos(latRadians) * sin(distance / 6371000) * cos(bearing));
    final double newLonRadians = lonRadians +
        atan2(sin(bearing) * sin(distance / 6371000) * cos(latRadians),
            cos(distance / 6371000) - sin(latRadians) * sin(newLatRadians));

    // Convert new latitude and longitude back to degrees
    final double newLatitude = newLatRadians * 180 / pi;
    final double newLongitude = newLonRadians * 180 / pi;

    final double calculatedDistance = distance;

    return (Position(type: 'Point', coordinates: [newLongitude, newLatitude]), calculatedDistance);
  }

  Future _heavyTaskForActivity({
    required Route route,
    required Vehicle vehicle,
    required List<RoutePoint> points,
    required List<RouteLandmark> marks,
  }) async {
    pp('$xy _heavyTaskForActivity starting ................car: ${vehicle.vehicleReg}');
    pp('$xy _heavyTaskForActivity starting ................ route: ${route.name}');

    marks.sort((a, b) => a.index!.compareTo(b.index!));
    points.sort((a, b) => a.index!.compareTo(b.index!));
    pp('$xy routeLandmarks: ${marks.length} - routePoints: ${points.length}');

    var rootDate = DateTime.now().toUtc().subtract(const Duration(minutes: 60));
    final List<AmbassadorPassengerCount> counts = [];
    for (var index = 0; index < marks.length; index++) {
      final landmark = marks[index];
      pp('\n\n\n$xx ... processing routeLandmark: ${landmark.landmarkName}');

      await dataApiDog.addVehicleArrival(VehicleArrival(
        ObjectId(),
        vehicleArrivalId: Uuid.v4().toString(),
        vehicleId: vehicle.vehicleId!,
        vehicleReg: vehicle.vehicleReg,
        created: rootDate.toIso8601String(),
        associationId: vehicle.associationId,
        associationName: vehicle.associationName,
        landmarkId: landmark.landmarkId,
        landmarkName: landmark.landmarkName,
        make: vehicle.make,
        model: vehicle.model,
        ownerId: vehicle.ownerId,
        ownerName: vehicle.ownerName,
        position: landmark.position,
        dispatched: false,
      ));
      pp('$xy arrival added: ${vehicle.vehicleReg} - ${rootDate.toIso8601String()} at ${landmark.landmarkName}');

      var wait = rand.nextInt(10);
      if (wait < 4) wait = 4;
      await _wait(wait, rootDate);

      final numIn = index == 0 ? rand.nextInt(20) : rand.nextInt(10);
      var numOut = 0;
      var numCurrent = 0;
      AmbassadorPassengerCount? passengerCount;
      if (passengerCount == null) {
        numCurrent = numIn;
      } else {
        numOut = index == marks.length - 1 ? passengerCount.currentPassengers! : rand.nextInt(passengerCount!.currentPassengers!);
        numCurrent = (passengerCount.currentPassengers! - numOut) + numIn;
      }

      final c = AmbassadorPassengerCount(
        ObjectId(),
        associationId: vehicle.associationId,
        ownerName: vehicle.ownerName,
        ownerId: vehicle.ownerId,
        created: rootDate.toIso8601String(),
        vehicleReg: vehicle.vehicleReg,
        vehicleId: vehicle.vehicleId,
        routeId: route.routeId,
        routeName: route.name,
        passengersIn: numIn,
        passengersOut: numOut,
        currentPassengers: numCurrent,
        position: landmark.position,
      );
      passengerCount = await dataApiDog.addAmbassadorPassengerCount(c);
      counts.add(passengerCount);

      var wait2 = rand.nextInt(10);
      if (wait2 < 4) wait2 = 4;
      rootDate = await _wait(wait2, rootDate);

      await dataApiDog.addDispatchRecord(DispatchRecord(
        ObjectId(),
        dispatched: true,
        dispatchRecordId: Uuid.v4().toString(),
        position: landmark.position,
        ownerId: vehicle.ownerId,
        landmarkName: landmark.landmarkName,
        routeLandmarkId: landmark.landmarkId,
        associationId: vehicle.associationId,
        associationName: vehicle.associationName,
        vehicleId: vehicle.vehicleId,
        vehicleReg: vehicle.vehicleReg,
        routeId: route.routeId,
        routeName: route.name,
        passengers: rand.nextInt(20),
        created: rootDate.toIso8601String(),
      ));
      pp('$xy dispatch added: ${vehicle.vehicleReg} - ${rootDate.toIso8601String()} - at ${landmark.landmarkName}');

      var wait3 = rand.nextInt(10);
      if (wait3 < 4) wait3 = 4;
      rootDate = await _wait(wait3, rootDate);

      await dataApiDog.addVehicleDeparture(VehicleDeparture(
        ObjectId(),
        vehicleId: vehicle.vehicleId,
        vehicleReg: vehicle.vehicleReg,
        created: rootDate.toIso8601String(),
        landmarkName: landmark.landmarkName,
        landmarkId: landmark.landmarkId,
        ownerId: vehicle.ownerId,
        ownerName: vehicle.ownerName,
        position: landmark.position,
        make: vehicle.make,
        model: vehicle.model,
        associationName: vehicle.associationName,
        associationId: vehicle.associationId,
        vehicleDepartureId: Uuid.v4().toString(),
      ));
      pp('$xy departure added: ${vehicle.vehicleReg} '
          '- ${rootDate.toIso8601String()} - at ${landmark.landmarkName}\n\n');
      var wait4 = rand.nextInt(15);
      if (wait4 < 5) wait4 = 6;
      rootDate = await _wait(wait4, rootDate);
    }

    _printCounts(counts);
  }

  Future _heavyTaskForPassengerCounts({
    required Route route,
    required Vehicle vehicle,
    required List<RoutePoint> points,
    required List<RouteLandmark> marks,
  }) async {
    pp('$xy _heavyTaskForPassengerCounts starting ................car: ${vehicle.vehicleReg}');
    pp('$xy _heavyTaskForPassengerCounts starting ................ route: ${route.name}');

    marks.sort((a, b) => a.index!.compareTo(b.index!));
    points.sort((a, b) => a.index!.compareTo(b.index!));
    pp('$xy routeLandmarks: ${marks.length} - routePoints: ${points.length}');

    var rootDate = DateTime.now().toUtc().subtract(const Duration(minutes: 60));
    final List<AmbassadorPassengerCount> counts = [];
    AmbassadorPassengerCount? prevPassengerCount;

    for (var index = 0; index < marks.length; index++) {
      final landmark = marks[index];
      pp('$xx _heavyTaskForPassengerCounts: ... processing routeLandmark: ${landmark.landmarkName}');

      var numIn = index == 0 ? rand.nextInt(20) : rand.nextInt(10);
      var numOut = 0;
      var numCurrent = 0;
      if (prevPassengerCount == null) {
        numCurrent = numIn;
      } else {
        if (index == marks.length - 1) {
          numIn = 0;
          numOut = prevPassengerCount.currentPassengers!;
          numCurrent = 0;
        } else {
          numOut = rand.nextInt(prevPassengerCount.currentPassengers!);
          numCurrent = (prevPassengerCount.currentPassengers! - numOut) + numIn;
        }

      }

      final c = AmbassadorPassengerCount(
        ObjectId(),
        associationId: vehicle.associationId,
        ownerName: vehicle.ownerName,
        ownerId: vehicle.ownerId,
        created: rootDate.toIso8601String(),
        vehicleReg: vehicle.vehicleReg,
        vehicleId: vehicle.vehicleId,
        routeId: route.routeId,
        routeName: route.name,
        passengersIn: numIn,
        passengersOut: numOut,
        currentPassengers: numCurrent,
        position: landmark.position,
      );
      prevPassengerCount = await dataApiDog.addAmbassadorPassengerCount(c);
      counts.add(prevPassengerCount);

      var wait2 = rand.nextInt(10);
      if (wait2 < 4) wait2 = 4;
      rootDate = await _wait(wait2, rootDate);

      pp('$xy _heavyTaskForPassengerCounts: passenger count added: ${vehicle.vehicleReg} '
          '- ${rootDate.toIso8601String()} - at ${landmark.landmarkName}\n\n');
      var wait4 = rand.nextInt(15);
      if (wait4 < 5) wait4 = 6;
      rootDate = await _wait(wait4, rootDate);
    }
    _printCounts(counts);
  }
  void _printCounts(List<AmbassadorPassengerCount> counts) {
    pp('\n\n${E.check}${E.check}${E.check}${E.check} AmbassadorPassengerCounts to be printed');
    for (var c in counts) {
      pp('${E.check}${E.check} ${c.vehicleReg} ${E.blueDot} in: ${c.passengersIn} out: ${c.passengersOut} '
          'current: ${c.currentPassengers} \t ${E.pear} route: ${c.routeName}');
    }
    pp('\n\n');
  }

  Future<DateTime> _wait(int seconds, DateTime rootDate) async {
    pp('\n\n$xx _wait: 🔆🔆🔆🔆🔆🔆🔆🔆🔆🔆🔆🔆🔆waiting for '
        '$seconds seconds .... ${DateTime.now().toIso8601String()}');
    await Future.delayed(Duration(seconds: seconds));
    rootDate = DateTime.parse(rootDate.toIso8601String())
        .add(Duration(minutes: rand.nextInt(5)));
    pp('$xx _wait: waking up!  🔆🔆🔆🔆🔆🔆🔆🔆🔆🔆🔆🔆🔆 .... '
        '${DateTime.now().toIso8601String()} 🔆🔆🔆🔆🔆🔆🔆🔆\n\n');

    return rootDate;
  }

  Future _heavyTaskForHeartbeats({
    required Vehicle vehicle,
    required List<RoutePoint> points,
    required List<RouteLandmark> marks,
  }) async {
    pp('$xx routeLandmarks: ${marks.length} - routePoints: ${points.length}');

    marks.sort((a, b) => a.index!.compareTo(b.index!));
    points.sort((a, b) => a.index!.compareTo(b.index!));

    var rootDate = DateTime.now().toUtc().subtract(const Duration(minutes: 60));

    final numberOfPoints = points.length / 10;

    final pages = numberOfPoints.toInt();
    for (var i = 0; i < 10; i++) {
      final pointIndex = i * (pages);
      pp('$xx heartbeat to be added;  pointIndex: $pointIndex : '
          'number of points: ${points.length} numberOfPoints: $pages');

      late VehicleHeartbeat hb;
      try {
        if (i == 5) {
          pp('$xx ..... adding last heartbeat .... ');
          hb = _createHeartbeat(vehicle, rootDate, points, points.length - 1);
          await _write(hb, pointIndex, rootDate);
          return;
        } else {
          hb = _createHeartbeat(vehicle, rootDate, points, pointIndex);
          await _write(hb, pointIndex, rootDate);
        }

      } catch (e, s) {
        pp('$e - $s');
      }
    }
  }

  Future<void> _write(VehicleHeartbeat hb, int pointIndex, DateTime rootDate) async {
    await dataApiDog.addVehicleHeartbeat(hb);
    pp('$xx _write: heartbeat added :  ${hb.vehicleReg} - ${hb.created} '
        '- ${hb.position!.toJson()} pointIndex: $pointIndex');
    var seconds = rand.nextInt(10);
    if (seconds < 4) seconds = 5;
    await _wait(seconds, rootDate);
  }

  VehicleHeartbeat _createHeartbeat(Vehicle vehicle, DateTime rootDate,
      List<RoutePoint> points, int pointIndex) {
    pp('$xx _createHeartbeat, ....... pointIndex: $pointIndex');
    final hb = VehicleHeartbeat(
      ObjectId(),
      vehicleHeartbeatId: Uuid.v4().toString(),
      vehicleReg: vehicle.vehicleReg,
      vehicleId: vehicle.vehicleId,
      created: rootDate.toIso8601String(),
      associationId: vehicle.associationId,
      make: vehicle.make,
      model: vehicle.model,
      ownerId: vehicle.ownerId,
      ownerName: vehicle.ownerName,
      position: points.elementAt(pointIndex).position,
    );
    return hb;
  }
}

const xx = '❤️❤️❤️❤️❤️❤️ _heavyTaskForHeartbeats: ❤️';
