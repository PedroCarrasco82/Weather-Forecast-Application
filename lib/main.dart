import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

const firstColor = Color(0xB33b8f91);
const secondColor = Color(0xB3c0d0d0);

void main() async {
  runApp(MaterialApp(
      home: Home(),
      theme: ThemeData(
          hintColor: firstColor,
          inputDecorationTheme: InputDecorationTheme(
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: firstColor))))));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _currentCity = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: secondColor,
        appBar: AppBar(
            backgroundColor: firstColor,
            title: RichText(
              text: TextSpan(
                  children: [
                    WidgetSpan(
                        child: Icon(Icons.wb_sunny, size: 30)
                    ),
                    TextSpan(
                        text: " WEATHER FORECAST ",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold
                        )
                    ),
                    WidgetSpan(
                        child: Icon(Icons.cloud, size: 30)
                    ),
                  ]
              ),
            )
        ),
        body: FutureBuilder<Placemark>(
          future: _getCurrentLocation(),
          builder: (context, snapshot){
            switch(snapshot.connectionState){
              case ConnectionState.none:
              case ConnectionState.waiting:
                return Center(
                    child: Text("Carregando...",
                        style: TextStyle(color: Colors.white, fontSize: 50.0),
                        textAlign: TextAlign.center));
              default:
                if(snapshot.hasError){
                  return Center(
                      child: Text("Erro ao carregar os dados :(",
                          style:
                          TextStyle(color: Colors.white, fontSize: 50.0), textAlign: TextAlign.center));
                }else {
                  _currentCity = snapshot.data.subAdministrativeArea;

                  return Text("Cidade: ${_currentCity}");
                }
            }
          },
        )
    );
  }

  Future<Placemark> _getCurrentLocation() async{
    final position = await Geolocator().getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placeMark = (await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude))[0];

    return placeMark;

  }

}