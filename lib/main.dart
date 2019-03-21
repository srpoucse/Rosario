import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert' as JSON;
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition center = CameraPosition(
    target: LatLng(-0.785, -90.290),
    zoom: 8,
  );

  Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    if (_markers.length == 0) {
      setupMarkers();
    }
    return new Scaffold(
      appBar: AppBar(
        title: Text("Rosario's Journey"),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: center,
            onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            },
            markers: _markers,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.topRight,
              child: FloatingActionButton(
                onPressed: _findRosario,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                backgroundColor: Colors.green,
                child: const Icon(Icons.fullscreen, size: 36.0),
              ),
            ),
          ),
        ],
      )
    );
  }

  Future<void> _findRosario() async {
    final GoogleMapController controller = await _controller.future;

    String jsonString = await MapService().loadGPSData();
    var locations = (JSON.jsonDecode(jsonString)['features'] as List);
    var location = Response.fromJson(locations[0]['properties']);

    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(location.lat, location.long),
        zoom: 16,
      )
    ));
  }

  Marker createMarker(int i, Response response) {
    return Marker(
      markerId: MarkerId(i.toString()),
      icon: (i == 0) ? BitmapDescriptor.fromAsset("assets/turtle.png") : BitmapDescriptor.defaultMarker,
      position: LatLng(response.lat, response.long),
      infoWindow: InfoWindow(
        title: "UTC Date: " + response.date.toString(),
        snippet: "UTC Time: " + response.time.toString(),
      )
    );
  }

  void setupMarkers() async {
    String jsonString = await MapService().loadGPSData();
      try {
        Set<Marker> tempSet = {};
        var locations = (JSON.jsonDecode(jsonString)['features'] as List);
        for (int i = 0; i < locations.length; i++) {
          var location = Response.fromJson(locations[i]['properties']);
          Marker marker = createMarker(i, location);
          tempSet.add(marker);
        }
        setState(() {
          _markers = tempSet;
        });

      } catch (e) {
        print(e.toString());
      }
  }
}

class Response {
  final double lat;
  final double long;
  final String date;
  final String time;

  Response(this.lat, this.long, this.date, this.time);

  Response.fromJson(Map<String, dynamic> json)
      : lat = double.parse(json['Latitude']),
        long = double.parse(json['Longitude']),
        date = json['UTC_Date'],
        time = json['UTC_Time'];


}



class MapService {
  Future<String> loadGPSData() async {
     return await rootBundle.loadString('assets/GPS.json');
  }

  //timer that updates GPS data and refreshes the view
  //json parser in dart
}