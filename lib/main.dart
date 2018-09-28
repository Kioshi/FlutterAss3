import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState()
  {
    _MyHomePageState state = _MyHomePageState();
    state.generateBikePolyline();
    return state;
  }
}

class _MyHomePageState extends State<MyHomePage> {

  List<List<List<LatLng>>> positions = [[[],[],[]],[[],[],[]]];

  List<List<Color>> colors = [[Colors.deepPurple, Colors.purple, Colors.purpleAccent],
    [Colors.deepOrange, Colors.orange, Colors.yellow]];

  @override
  Widget build(BuildContext context) {

    List<Marker> markers = [];
    List<Polyline> polylines = [];

    for(int j = 0; j < 2; j++) {
      for (int i = 0; i < 3; i++) {
        markers.addAll(positions[j][i].map((latlng) {
          return new Marker(
            width: 5.0,
            height: 5.0,
            point: latlng,
            builder: (ctx) =>
            new Container(
              decoration: new BoxDecoration(
                color: colors[j][i],
                shape: BoxShape.circle,
              ),
            ),
          );
        }).toList());


        polylines.add(Polyline(points: positions[j][i], color: colors[j][i]));
      }
    }
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Leaflet test page"),
      ),
      body: FlutterMap(
        options: MapOptions(
          minZoom: 10.0,
          center: LatLng(56.25714966666666,10.0690625)
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: "https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
            additionalOptions: {
              'accessToken': 'pk.eyJ1Ijoia2xleGlrIiwiYSI6ImNqbW0wNng1cjBjdjczcW83bDR6cXhkemkifQ.vsqKwg4BWrMwKfMV6i_sbw',
              'id': 'mapbox.streets'
            }
          ),
          PolylineLayerOptions(
            polylines: polylines
          ),
          MarkerLayerOptions(markers: markers)
        ],
      ),
    );
  }

  void clearPositions()
  {
    for(int j = 0; j < 2; j++) {
      for (int i = 0; i < 3; i++) {
        positions[j][i].clear();
      }
    }
  }

  void generateBikePolyline() async {
    final csvCodec = new CsvCodec(eol: "\n");
    List<List<dynamic>> table = await rootBundle.loadString("assets/biking.csv").asStream().transform(csvCodec.decoder).toList();
    table.removeAt(0);
    setState(() {
      clearPositions();

      for (List<dynamic> row in table)
      {
        positions[0][0].add(LatLng(row[1],row[2]));
        positions[1][0].add(LatLng(row[3],row[4]));
      }
      calculateMeanPositions();
      calculateMedianPositions();
    });
  }

  void calculateMeanPositions() {

  }

  void calculateMedianPositions() {

  }
}
