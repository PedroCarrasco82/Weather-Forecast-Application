import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:weather_forecast/shared/Config.dart';

const firstColor = Color(0xB33b8f91);
const secondColor = Color(0xB3c0d0d0);
dynamic _apikey;

void main() async {
  await DotEnv().load(".env");

  _apikey = Config.apiKey;
  print("---------API_KEY-----------");
  print(_apikey);

  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
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
  String getRequestURL(city) => "https://api.hgbrasil.com/weather?key=$_apikey&city_name=${city}";
  static String _currentCity = "";
  Map _cityInfo;
  String _search = null;
  bool _positionPermission = true;

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
        body: FutureBuilder<bool>(
          future: _getPermissionAndSetPosition(),
          builder: (context, snapshot){
            switch(snapshot.connectionState){
              case ConnectionState.none:
              case ConnectionState.waiting:
                return Center(
                    child: Text("Getting your location...",
                        style: TextStyle(color: Colors.white, fontSize: 50.0),
                        textAlign: TextAlign.center));
              default:
                if(snapshot.hasError){
                  return Center(
                      child: Text("Error on getting your location :( ",
                          style:
                          TextStyle(color: Colors.white, fontSize: 50.0), textAlign: TextAlign.center));
                }else {
                  _positionPermission = snapshot.data;
                  return _getCurrentCityForecast();
                }
            }
          },
        )
    );
  }

  Future<bool> _getPermissionAndSetPosition() async{
    try{
      if(!_positionPermission)
        return false;

      final position = await Geolocator().getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placeMark = (await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude))[0];
      _currentCity = placeMark.subAdministrativeArea;

      return true;

    }catch(err){
      return false;

    }
  }

  Widget searchContainer(){
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(10.0),
          child: TextField(
            decoration: InputDecoration(
                labelText: "Pesquise a cidade aqui!",
                hintText: "Exemplo: São Paulo",
                labelStyle: TextStyle(
                  color: Colors.white,
                ),
                hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(0xB3EEEEEE)
                ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white)
              )
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18.0),
            onSubmitted: (text){
              setState(() {
                _search = text;
              });
            },
          ),
        ),
      ],
    );
  }

  FutureBuilder<Map> _getCurrentCityForecast(){
    final city = _search == null || _search == "" ? _currentCity : _search;
    print(city);
    return FutureBuilder<Map>(
      future: getData(city),
      builder: (context, snapshot){
        switch(snapshot.connectionState){
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(
                child: Text("Getting forecast...",
                    style: TextStyle(color: Colors.white, fontSize: 50.0),
                    textAlign: TextAlign.center));
          default:
            if(snapshot.hasError){
              return Center(
                  child: Text("Error on getting forecast :(",
                      style:
                      TextStyle(color: Colors.white, fontSize: 50.0), textAlign: TextAlign.center));
            }else {
              _cityInfo = snapshot.data;
              print(_cityInfo.toString());
              final cityText = _positionPermission || _search != null ?
              Text("Description: "+_cityInfo["results"]["description"]+"\n Temp: "+ _cityInfo["results"]["temp"].toString()+"\nCidade: "+_cityInfo["results"]["city"]) :
              SizedBox.shrink();
              return Column(
                children: <Widget>[
                  searchContainer(),
                  cityText
                ],
              );
            }
        }
      },
    );
  }

  Future<Map> getData(city) async{
    http.Response response = await http.get(getRequestURL(city));
    print(getRequestURL(city));
    return json.decode(response.body);
  }

}