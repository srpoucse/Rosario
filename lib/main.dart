
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert' as JSON;
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';

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

  CameraPosition mostRecent = null;
  bool didZoom = false;
  
  Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    if (_markers.length == 0) {
      setupMarkers();
    }

    scheduleTimer();

    return new Scaffold(
      appBar: AppBar(
        title: Text("Rosario's Journey"),
        backgroundColor: Colors.green[700],
          actions: <Widget>[IconButton(
          icon: didZoom ? Icon(Icons.zoom_out) : Icon(Icons.zoom_in),
          onPressed: toggleZoom,
        )],
      ),
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: center,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);

        },
        markers: _markers,
      )
    );

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
          if (i == 0) {
            mostRecent = CameraPosition(
              target: LatLng(location.lat, location.long),
              zoom: 16,
            );
          }
        }
        setState(() {
          _markers = tempSet;
        });

      } catch (e) {
        print(e.toString());
      }
  }

  Future<void> toggleZoom() async {
    final GoogleMapController controller = await _controller.future;
    CameraPosition position = didZoom ? center : mostRecent;
    controller.animateCamera(CameraUpdate.newCameraPosition(position));
    setState(() {
      didZoom = !didZoom;
    });
  }

  void fetchData() {
    http.get('https://www.google.com/maps/d/kml?mid=1c528h6kSOFLsJ0RWf0T-qE7j1yjCa9AB&forcekml=1').then((response) {
      Set<Marker> tempSet = {};
      Xml2Json xml2json = new Xml2Json();  //Make an instance.
      xml2json.parse(response.body);
      var jsondata = xml2json.toGData();
      var placemarks = (JSON.jsonDecode(jsondata)["kml"]["Document"]["Folder"]["Placemark"] as List);
      for (int i = 0; i < placemarks.length; i++) {
        var properties = placemarks[i]["ExtendedData"]["Data"];
        String lat = "", long = "", date = "", time = "";
        for (int j=0; j < properties.length; j++) {
          var kv = properties[j];
          if (kv["name"] == "UTC_Date") {
            date = kv["value"]["\$t"];
          }
          else if (kv["name"] == "UTC_Time") {
            time = kv["value"]["\$t"];
          }
          else if (kv["name"] == "Latitude") {
            lat = kv["value"]["\$t"];
          }
          else if (kv["name"] == "Longitude") {
            long = kv["value"]["\$t"];
          }
        }

        var location = Response(double.parse(lat), double.parse(long), date, time);
        Marker marker = createMarker(i, location);
        tempSet.add(marker);

        setState(() {
          _markers = tempSet;
        });

      }
    });
  }

  void scheduleTimer() {
    Timer.periodic(new Duration(seconds: 10 * 60), (timer) {
      fetchData();
    });
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
}
