// ignore_for_file: file_names

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:safetynet/screens/main/video_join.dart';
import 'package:safetynet/utils/helpers.dart';

Marker buildMarker(BuildContext context, LatLng coordinates, String id,
    String type, String description) {
  if (description == 'alert') {
    return Marker(
      point: coordinates,
      width: 150,
      height: 250,
      child: Column(
        children: [
          // Card(
          //   child: SizedBox(
          //     width: 400,
          //     height: 130,
          //     child: Padding(
          //       padding: const EdgeInsets.all(5),
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.center,
          //         children: [
          //           Padding(
          //             padding: const EdgeInsets.all(8),
          //             child: Text(Helpers.replaceUnderscoreAndCapitalise(type),
          //                 textAlign: TextAlign.center,
          //                 style: const TextStyle(
          //                     color: Colors.orange,
          //                     fontSize: 13,
          //                     fontWeight: FontWeight.bold)),
          //           ),
          //           const SizedBox(height: 10),
          //           // ElevatedButton(
          //           //   onPressed: () async {
          //           //     Navigator.of(context).push(
          //           //       MaterialPageRoute(
          //           //           builder: (context) => ViewAllAlertsPage(id: id)),
          //           //     );
          //           //   },
          //           //   style: ElevatedButton.styleFrom(
          //           //     backgroundColor: ThemeConstant.primary,
          //           //   ),
          //           //   child: const SizedBox(
          //           //     width: 70,
          //           //     height: 15,
          //           //     child: Center(
          //           //         child: Text('View Details',
          //           //             style: TextStyle(
          //           //                 color: Colors.white,
          //           //                 fontSize: 11,
          //           //                 fontWeight: FontWeight.bold))),
          //           //   ),
          //           // ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoJoinRoom(
                    roomId: id,
                  ),
                ),
              );
            },
            child: const Icon(Icons.person),
          ),
        ],
      ),
    );
  } else {
    return Marker(
      point: coordinates,
      width: 150,
      height: 250,
      child: Column(
        children: [
          ClipPath(
            child: Card(
              child: SizedBox(
                width: 400,
                height: 120,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        decoration:
                            const BoxDecoration(color: Colors.orange),
                        child: const Padding(
                          padding: EdgeInsets.only(
                              left: 35, right: 35, top: 5, bottom: 5),
                          child: Text('HELP!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                            Helpers.replaceUnderscoreAndCapitalise(type),
                            style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Image.asset(
            "assets/images/background.png",
            width: 90,
            height: 60,
          ),
        ],
      ),
    );
  }
}
