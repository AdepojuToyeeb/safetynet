import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safetynet/widget/buildMarker.dart';

class RoomMapWidget extends StatefulWidget {
  const RoomMapWidget({super.key});

  @override
  State<RoomMapWidget> createState() => _RoomMapWidgetState();
}

class _RoomMapWidgetState extends State<RoomMapWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late MapController _mapController = MapController();
  double latitude = 0;
  double longitude = 0;
  double topMargin = 500;
  List<LatLng> alertLatLngList = [];
  List<Map<String, dynamic>> alerts = [];

  // void setNameCurrentPos() async {
  //   double latitude = _mapController.camera.center.latitude;
  //   double longitude = _mapController.camera.center.longitude;
  //   String url =
  //       '$/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1';

  //   var response = await client.get(Uri.parse(url));
  //   var decodedResponse =
  //       jsonDecode(utf8.decode(response.bodyBytes)) as Map<dynamic, dynamic>;

  //   _searchController.text =
  //       decodedResponse['display_name'] ?? "MOVE TO CURRENT POSITION";
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('rooms')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        LatLng mapCentre = const LatLng(9.1073416, 7.4689621);
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        alertLatLngList.clear();
        alerts.clear();

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          GeoPoint geoPoint = data['location'];

          // Check if location data exists
          if (data.containsKey('location')) {
            LatLng alertLocation = LatLng(geoPoint.latitude, geoPoint.longitude);

            alertLatLngList.add(alertLocation);

            // Create alert object
            var alert = {
              'id': doc.id,
              'alertType': data['alertType'] ?? 'Unknown',
              'latitude': geoPoint.latitude,
              'longitude': geoPoint.longitude,
              'roomId': data['roomId'],
            };
            alerts.add(alert);
          }
        }

        // Use the first room's location as map center if available
        if (alertLatLngList.isNotEmpty) {
          mapCentre = alertLatLngList.first;
        }

        return Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: mapCentre,
                  initialZoom: 12,
                  maxZoom: 18,
                  minZoom: 12,
                ),
                mapController: _mapController,
                children: [
                  TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
                  Stack(
                    alignment: AlignmentDirectional.topCenter,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 900),
                        margin: EdgeInsets.only(bottom: topMargin),
                        child: MarkerLayer(
                          markers: List<Marker>.generate(
                            alertLatLngList.length,
                            (index) {
                              var alert = alerts[
                                  index]; // Get the corresponding alert object
                                  print("alert12345");
                              print(alert);
                              String alertId = alert['roomId'].toString();
                              String alertType = alert['alertType'].toString();
                              String alertDescription = 'alert';
                              LatLng latLng = alertLatLngList[
                                  index]; // Get the corresponding LatLng
                              return buildMarker(context, latLng, alertId,
                                  alertType, alertDescription);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            //drawer icon
            // Positioned(
            //   top: 50,
            //   child: SizedBox(
            //     width: 80,
            //     child: FloatingActionButton(
            //       shape: const CircleBorder(),
            //       heroTag: 'drawer',
            //       backgroundColor: Colors.orange,
            //       onPressed: () {
            //         Scaffold.of(context).openDrawer();
            //       },
            //       child: Icon(
            //         widget.drawerIcon,
            //         color: widget.buttonTextColor,
            //         size: 35,
            //       ),
            //     ),
            //   ),
            // ),

            //search icon
            // Positioned(
            //   top: 50,
            //   right: 5,
            //   child: SizedBox(
            //     width: 80,
            //     child: FloatingActionButton(
            //       shape: const CircleBorder(),
            //       heroTag: 'notifications',
            //       backgroundColor: Colors.amber,
            //       onPressed: () {
            //         Navigator.push(
            //             context,
            //             PageTransition(
            //                 child: NotificationsPage(
            //                   latitude: latitude,
            //                   longitude: longitude,
            //                 ),
            //                 type: PageTransitionType.fade));
            //       },
            //       child: Icon(
            //         Icons.notifications,
            //         color: widget.buttonTextColor,
            //         size: 30,
            //       ),
            //     ),
            //   ),
            // ),

            //location on map
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: Image.asset(
                          width: 150,
                          height: 150,
                          "assets/images/logo.png",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            //zoom in button
            Positioned(
              bottom: 250,
              right: 5,
              child: FloatingActionButton(
                heroTag: 'zoom_in',
                backgroundColor: const Color.fromARGB(255, 237, 215, 215),
                onPressed: () {
                  _mapController.move(_mapController.camera.center,
                      _mapController.camera.zoom + 1);
                },
                child: const Icon(
                  Icons.zoom_in,
                  color: Colors.black,
                ),
              ),
            ),

            //zoom out button
            Positioned(
              bottom: 190,
              right: 5,
              child: FloatingActionButton(
                heroTag: 'zoom_out',
                backgroundColor: const Color.fromARGB(255, 237, 215, 215),
                onPressed: () {
                  _mapController.move(_mapController.camera.center,
                      _mapController.camera.zoom - 1);
                },
                child: const Icon(
                  Icons.zoom_out,
                  color: Colors.black,
                ),
              ),
            ),

            //current location button
            Positioned(
              bottom: 129,
              right: 5,
              child: FloatingActionButton(
                heroTag: 'current_location',
                backgroundColor: const Color.fromARGB(255, 237, 215, 215),
                onPressed: () async {
                  _mapController.move(
                      LatLng(mapCentre.latitude, mapCentre.longitude),
                      _mapController.camera.zoom);
                                  // setNameCurrentPos();
                },
                child: const Icon(
                  Icons.person_pin_circle_outlined,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
