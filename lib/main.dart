import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

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
  _MyHomePageState createState() {
    _MyHomePageState state = _MyHomePageState();
    return state;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  static const int SOURCES = 2;
  static const int NORM_TYPES = 3;
  static const int TRANSPORT_TYPES = 4;
  static const int RAW = 0;
  static const int MEAN = 1;
  static const int MED = 2;
  static const int TYPE_WALK = 0;
  static const int TYPE_RUN = 1;
  static const int TYPE_BIKE = 2;
  static const int TYPE_CAR = 3;

  int activeType = TYPE_BIKE;
  List<List<List<List<LatLng>>>> positions = generatePositionsList();

  List<List<String>> texts = [
    ["GT Raw", "GT Mean", "GT Med"],
    ["Phone Raw", "Phone Mean", "Phone Med"]
  ];
  List<List<bool>> active = [
    [true, true, true],
    [true, true, true]
  ];

  List<List<Color>> colors = [
    [const Color(0x70673AB7), const Color(0x709C27B0), const Color(0x70E040FB)],
    [const Color(0x70FF5722), const Color(0x70FF9800), const Color(0x70FFEB3B)]
  ];

  List<String> assets = ["assets/walking.csv", "assets/running.csv", "assets/biking.csv", "assets/driving.csv"];

  List<RaisedButton> dataButtons = [];

  Future initFuture;

  _MyHomePageState() {
    initFuture = init();
  }

  MapController mapController = MapController();

  init() async {
    generateDataButtons();
    clearPositions();
    for (int k = 0; k < TRANSPORT_TYPES; k++) {
          final csvCodec = new CsvCodec(eol: "\n");
          List<List<dynamic>> table  = await rootBundle
                .loadString(assets[k])
                .asStream()
                .transform(csvCodec.decoder)
                .toList();
            table.removeAt(0);
          setState(() {
            for (List<dynamic> row in table) {
              LatLng GTll = LatLng(row[1], row[2]);
              LatLng Mobilell = LatLng(row[3], row[4]);
              //if (positions[k][0][RAW].isEmpty || positions[k][0][RAW].last != GTll)
                positions[k][0][RAW].add(GTll);
              //if (positions[k][1][RAW].isEmpty || positions[k][1][RAW].last != Mobilell)
                positions[k][1][RAW].add(Mobilell);
            }

            for (int j = 0; j < SOURCES; j++) {
              calculateMeanPositions(k, j);
              calculateMedianPositions(k, j);
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = [];
    List<Polyline> polylines = [];

    for (int j = 0; j < SOURCES; j++) {
      for (int i = 0; i < NORM_TYPES; i++) {
        if (!active[j][i]) continue;
        markers.addAll(positions[activeType][j][i].map((latlng) {
          return new Marker(
            width: 5.0,
            height: 5.0,
            point: latlng,
            builder: (ctx) => new Container(
                  decoration: new BoxDecoration(
                    color: colors[j][i],
                    shape: BoxShape.circle,
                  ),
                ),
          );
        }).toList());

        polylines.add(
            Polyline(points: positions[activeType][j][i], color: colors[j][i]));
      }
    }
    LatLng focusPos = positions[activeType][0][0].isEmpty ? LatLng(0.0,0.0) : positions[activeType][0][0][0];
    if (mapController.ready) {
      mapController.move(focusPos, mapController.zoom);
    }
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Leaflet test page"),
        ),
        body: Stack(children: <Widget>[
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
                /*minZoom: 10.0, */
                center: positions[activeType][0][0].isEmpty ? LatLng(0.0,0.0) : positions[activeType][0][0][0]),//LatLng(56.25714966666666, 10.0690625)),
            layers: [
              TileLayerOptions(
                  urlTemplate:
                      "https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
                  additionalOptions: {
                    'accessToken':
                        'pk.eyJ1Ijoia2xleGlrIiwiYSI6ImNqbW0wNng1cjBjdjczcW83bDR6cXhkemkifQ.vsqKwg4BWrMwKfMV6i_sbw',
                    'id': 'mapbox.streets'
                  }),
              PolylineLayerOptions(polylines: polylines),
              MarkerLayerOptions(markers: markers)
            ],
          ),
          new Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              verticalDirection: VerticalDirection.up,
              children: dataButtons),
          new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                    key: null,
                    onPressed: () => setState(() {activeType = TYPE_WALK;}),
                    color: activeType != TYPE_WALK ? const Color(0xFFe0e0e0) : Colors.grey,
                    child: Icon(Icons.directions_walk)),
                RaisedButton(
                    key: null,
                    onPressed: () => setState(() {activeType = TYPE_RUN;}),
                    color: activeType != TYPE_RUN ? const Color(0xFFe0e0e0) : Colors.grey,
                    child: Icon(Icons.directions_run)),
                RaisedButton(
                    key: null,
                    onPressed: () => setState(() {activeType = TYPE_BIKE;}),
                    color: activeType != TYPE_BIKE ? const Color(0xFFe0e0e0) : Colors.grey,
                    child: Icon(Icons.directions_bike)),
                RaisedButton(
                    key: null,
                    onPressed: () => setState(() {activeType = TYPE_CAR;}),
                    color: activeType != TYPE_CAR ? const Color(0xFFe0e0e0) : Colors.grey,
                    child: Icon(Icons.directions_car))
              ])
        ]));
  }



  void clearPositions() {
    for (int k = 0; k < TRANSPORT_TYPES; k++) {
      for (int j = 0; j < SOURCES; j++) {
        for (int i = 0; i < NORM_TYPES; i++) {
          positions[k][j][i].clear();
        }
      }
    }
  }

  void dataButtonPressed(int source, int type) {
    setState(() {
      active[source][type] = !active[source][type];
      generateDataButtons();
    });
  }

  void calculateMeanPositions(int k, int j) {
    for (int i = 0; i < positions[k][j][RAW].length; i++) {
      if (i < 5) {
        positions[k][j][MEAN].add(positions[k][j][RAW][i]);
        continue;
      }

      double lat = 0.0;
      double lon = 0.0;
      positions[k][j][RAW].getRange(i - 5, i).forEach((LatLng latLon) {
        lat += latLon.latitude;
        lon += latLon.longitude;
      });

      positions[k][j][MEAN].add(LatLng(lat / 5.0, lon / 5.0));
    }
  }

  void calculateMedianPositions(int k, int j) {
    for (int i = 0; i < positions[k][j][RAW].length; i++) {
      if (i < 5) {
        positions[k][j][MED].add(positions[k][j][RAW][i]);
        continue;
      }

      List<double> lat = [];
      List<double> lon = [];
      positions[k][j][RAW].getRange(i - 5, i).forEach((LatLng latLon) {
        lat.add(latLon.latitude);
        lon.add(latLon.longitude);
      });

      lat.sort();
      lon.sort();
      positions[k][j][MED].add(LatLng(lat[2], lon[2]));
    }
  }

  Color dataButtonColor(int source, int type) {
    return active[source][type] ? colors[source][type] : Colors.grey;
  }

  void generateDataButtons() {
    dataButtons.clear();
    for (int j = 0; j < SOURCES; j++) {
      for (int i = 0; i < NORM_TYPES; i++) {
        dataButtons.add(RaisedButton(
            key: null,
            onPressed: () => dataButtonPressed(j, i),
            color: dataButtonColor(j, i),
            child: new Text(
              texts[j][i],
              style: new TextStyle(
                  fontSize: 12.0,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontFamily: "Roboto"),
            )));
      }
    }
  }

  static List<List<List<List<LatLng>>>> generatePositionsList() {
    List<List<List<List<LatLng>>>> list = [];
    for (int k = 0; k < TRANSPORT_TYPES; k++) {
      list.add(List<List<List<LatLng>>>());
      for (int j = 0; j < SOURCES; j++) {
        list[k].add(List<List<LatLng>>());
        for (int i = 0; i < NORM_TYPES; i++) {
          list[k][j].add(List<LatLng>());
        }
      }
    }

    return list;
  }
}
