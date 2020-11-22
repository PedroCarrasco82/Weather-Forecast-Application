import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:weather_forecast/shared/Config.dart';

const firstColor = Color(0xB33b8f91);
const secondColor = Color(0xFFFFFFFF);
const textColor = Color(0xFF477374);
dynamic _apikey;

void main() async {
  await DotEnv().load(".env");

  _apikey = Config.apiKey;

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
  PageController _mainPagecontroller = PageController(
      initialPage: 0
  );
  String getRequestURL(city) => "https://api.hgbrasil.com/weather?key=$_apikey&city_name=$city";
  static String _currentCity = "";
  Map _cityInfo;
  String _search = null;
  bool _hasRequestedPermission = false;
  bool _positionPermission;

  @override
  Widget build(BuildContext context) {

    Map<int, List> imagesDescriptions = Map<int, List>();
    imagesDescriptions[0] = ["clear_day", "Dia limpo"];
    imagesDescriptions[1] = ["clear_night", "Noite limpa"];
    imagesDescriptions[2] = ["cloud", "Nublado"];
    imagesDescriptions[3] = ["cloudly_day", "Nublado de dia"];
    imagesDescriptions[4] = ["cloudly_night", "Nublado de noite"];
    imagesDescriptions[5] = ["fog", "Neblina"];
    imagesDescriptions[6] = ["hail", "Granizo"];
    imagesDescriptions[7] = ["humidity", "Humidade"];
    imagesDescriptions[8] = ["rain", "Chuva"];
    imagesDescriptions[9] = ["snow","Neve"];
    imagesDescriptions[10] = ["storm", "Tempestade"];
    imagesDescriptions[11] = ["sunrise", "Despertar do sol"];
    imagesDescriptions[12] = ["sunset", "Pôr do sol"];
    imagesDescriptions[13] = ["thermometer", "Max/Min"];
    imagesDescriptions[14] = ["wind_speedy", "Velocidade do vento"];

    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: secondColor,
        body: FutureBuilder<bool>(
          future: _getPermissionAndSetPosition(),
          builder: (context, snapshot){
            switch(snapshot.connectionState){
              case ConnectionState.none:
              case ConnectionState.waiting:
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _loadInfos("Getting your location...")
                );
              default:
                if(snapshot.hasError){
                  return Center(
                      child: Text("Error on getting your location :( ",
                          style:
                          TextStyle(color: textColor, fontSize: 50.0), textAlign: TextAlign.center));
                }else {
                  _positionPermission = snapshot.data;
                  return PageView(
                      controller: _mainPagecontroller,
                      scrollDirection: Axis.horizontal,
                      children: <Widget> [
                        Scaffold(
                          appBar: AppBar(
                            backgroundColor: firstColor,
                            centerTitle: true,
                            title: Text(
                              "WEATHER FORECAST",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            actions: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  child: Icon(Icons.launch, size: 30),
                                  onTap: (){
                                    _mainPagecontroller.animateToPage(
                                        1,
                                        duration: Duration(milliseconds: 200),
                                        curve: Curves.easeIn
                                    );
                                  },
                                ),
                              )
                            ],
                          ),
                          body: _getCurrentCityForecast(),
                        ),
                        Scaffold(
                          appBar: AppBar(
                            backgroundColor: firstColor,
                            leading: Container(
                              margin: EdgeInsets.only(left: 10),
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                child: Icon(Icons.arrow_back, size: 30),
                                onTap: (){
                                  _mainPagecontroller.animateToPage(
                                      0,
                                      duration: Duration(milliseconds: 500),
                                      curve: Curves.easeIn
                                  );
                                },
                              ),
                            ),
                            title: Container(
                              child: Text(
                                "DESCRIPTIONS",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            centerTitle: true,
                          ),
                          body: Container(
                              child: ListView.builder(
                                scrollDirection: Axis.vertical,
                                itemCount: imagesDescriptions.length,
                                itemBuilder: (context, index){
                                  return Container(
                                    padding: EdgeInsets.only(
                                        top: 10,
                                        left: 10,
                                        bottom: index == imagesDescriptions.length - 1? 10 : 0
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        SvgPicture.asset(
                                          "assets/images/${imagesDescriptions[index][0]}.svg",
                                          placeholderBuilder: (context) => Icon(Icons.error),
                                          semanticsLabel: imagesDescriptions[index][1],
                                          height: 50,
                                          width: 50,
                                          color: firstColor,
                                        ),
                                        Text(
                                            imagesDescriptions[index][1],
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 20
                                            ),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              )
                          ),
                        )
                      ]
                  );
                }
            }
          },
        )
    );
  }

  Future<bool> _getPermissionAndSetPosition() async{
    try{
      print(_hasRequestedPermission);
      if(_hasRequestedPermission)
        return false;

      final position = await Geolocator().getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placeMark = (await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude))[0];
      _currentCity = placeMark.subAdministrativeArea;

      _hasRequestedPermission = true;

      return true;

    }catch(err){
      _hasRequestedPermission = true;
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
                hintText: "Exemplo: \"São Paulo\"",
                labelStyle: TextStyle(
                  color: Colors.black,
                ),
                hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.withOpacity(0.3)
                ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black)
              )
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontSize: 18.0),
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
    return FutureBuilder<Map>(
      future: getData(city),
      builder: (context, snapshot){
        switch(snapshot.connectionState){
          case ConnectionState.none:
          case ConnectionState.waiting:
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _loadInfos("Getting Forecast...")
                );
          default:
            if(snapshot.hasError){
              return Center(
                  child: Text("Error on getting forecast :(",
                      style:
                      TextStyle(
                          color: textColor,
                          fontSize: 50.0,
                          backgroundColor: secondColor
                      ),
                      textAlign: TextAlign.center
                  )
              );
            }else {
              _cityInfo = snapshot.data;
              if(_cityInfo["error"] == true){
                return Center(

                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                            "ERROR",
                            style: TextStyle(
                            fontSize: 40,
                            color: Colors.red,
                            fontWeight: FontWeight.bold
                            ),
                        ),
                        Divider(
                          height: 30,
                          thickness: 0.0,
                          color: secondColor,
                        ),
                        Text(
                          _cityInfo["message"],
                          style: TextStyle(
                              fontSize: 20,
                              color: textColor,
                              fontWeight: FontWeight.bold
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    )
                  )
                );
              }

              final textCurrentCity =
                removeDiacritics(_cityInfo["results"]["city"].split(",")[0].replaceAll(" ", ""))
                    .toUpperCase()
                    .trim() == (removeDiacritics(_currentCity).toUpperCase().replaceAll(" ", "").trim()) ? "Previsão da sua cidade:\n" : "";

              final cityText = (_positionPermission && _hasRequestedPermission) || _search != null ?
              Container(
                height: 350,
                margin: EdgeInsets.only(left: 10, right: 10, top: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      textCurrentCity+_cityInfo["results"]["city"] + " - " + _cityInfo["results"]["date"],
                      style: TextStyle(
                        fontSize: 20,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          _cityInfo["results"]["temp"].toString()+"º",
                          style: TextStyle(
                              fontSize: 60,
                              color: textColor
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SvgPicture.asset(
                          "assets/images/${_cityInfo["results"]["condition_slug"]}.svg",
                          placeholderBuilder: (context) => Icon(Icons.error),
                          semanticsLabel: "condition",
                          height: 150,
                          width: 150,
                          color: firstColor,
                        ),
                      ],
                    ),
                    Container(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                          _cityInfo["results"]["description"],
                          style: TextStyle(
                            fontSize: 25,
                            color: textColor
                          ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Row()
                  ],
                ),
              ):
              SizedBox.shrink();

              List<dynamic> _cityForecast =_cityInfo["results"]["forecast"];

              _cityForecast.remove(_cityForecast[0]);

              Container forecast = _getListViewForecast(_cityForecast, context);

              List<Widget> forecastInfos = List<Widget>();

              List<Widget> todayInfosForecast = List<Widget>();
              todayInfosForecast.add(
                  Container(
                    child: Column(
                      children: <Widget>[
                        Text(
                            _cityInfo["results"]["sunrise"],
                            style: TextStyle(
                              color: textColor
                            ),
                        ),
                        SvgPicture.asset(
                          "assets/images/sunrise.svg",
                          placeholderBuilder: (context) => Icon(Icons.error),
                          semanticsLabel: "sun rise",
                          height: 50,
                          width: 50,
                          color: firstColor,
                        ),
                      ],
                    ),
                  )
              );

              todayInfosForecast.add(
                  Container(
                    child: Column(
                      children: <Widget>[
                        SvgPicture.asset(
                          "assets/images/sunset.svg",
                          placeholderBuilder: (context) => Icon(Icons.error),
                          semanticsLabel: "sun set",
                          height: 50,
                          width: 50,
                          color: firstColor,
                        ),
                        Text(
                          _cityInfo["results"]["sunset"],
                          style: TextStyle(
                            color: textColor
                          ),
                        ),
                      ],
                    ),
                  )
              );

              todayInfosForecast.add(
                  Container(
                    child: Column(
                      children: <Widget>[
                        Text(
                          _cityInfo["results"]["humidity"].toString()+"%",
                          style: TextStyle(
                            color: textColor
                          ),
                        ),
                        SvgPicture.asset(
                          "assets/images/humidity.svg",
                          placeholderBuilder: (context) => Icon(Icons.error),
                          semanticsLabel: "sun set",
                          height: 50,
                          width: 50,
                          color: firstColor,
                        ),
                      ],
                    ),
                  )
              );

              todayInfosForecast.add(
                  Container(
                    child: Column(
                      children: <Widget>[
                        SvgPicture.asset(
                          "assets/images/wind_speedy.svg",
                          placeholderBuilder: (context) => Icon(Icons.error),
                          semanticsLabel: "sun set",
                          height: 50,
                          width: 50,
                          color: firstColor,
                        ),
                        Text(
                          _cityInfo["results"]["wind_speedy"],
                          style: TextStyle(
                            color: textColor
                          ),
                        ),
                      ],
                    ),
                  )
              );

              todayInfosForecast.add(
                  Container(
                    child: Column(
                      children: <Widget>[
                        Text(
                          _cityInfo["results"]["forecast"][0]["max"].toString()+"º",
                          style: TextStyle(
                            color: textColor
                          ),
                        ),
                        SvgPicture.asset(
                          "assets/images/thermometer.svg",
                          placeholderBuilder: (context) => Icon(Icons.error),
                          semanticsLabel: "sun set",
                          height: 50,
                          width: 50,
                          color: firstColor,
                        ),
                        Text(
                          _cityInfo["results"]["forecast"][0]["min"].toString()+"º",
                          style: TextStyle(
                            color: textColor
                          ),
                        ),
                      ],
                    ),
                  )
              );

              forecastInfos.add(searchContainer());
              forecastInfos.add(
                Container(
                child: Column(
                  children: <Widget>[
                    cityText
                  ],
                ),
              ));

              forecastInfos.add(
                  Container(
                    height: 100,
                    margin: EdgeInsets.all(10),
                    alignment: Alignment.topCenter,
                    decoration: BoxDecoration(
                        color: secondColor,
                        boxShadow: [
                          BoxShadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 5.0,
                              spreadRadius: 1.0
                          ),
                        ]
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: todayInfosForecast.length,
                      padding: EdgeInsets.all(1.0),
                      itemBuilder: (context, index){
                        return Container(
                            alignment: Alignment.topCenter,
                            width: 130,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                todayInfosForecast[index]
                              ],
                            )
                        );
                      },
                    ),
                  )
              );

              forecastInfos.add(forecast);

              if((_positionPermission && _hasRequestedPermission) || _search != null){
                return Container(
                  child: ListView.builder(
                      itemCount: forecastInfos.length,
                      itemBuilder: (context, index){
                        return Column(
                          children: <Widget>[
                            forecastInfos[index]
                          ],
                        );
                      }
                  ),
                );
              }
              else{
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    searchContainer()
                  ],
                );
              }
            }
        }
      },
    );
  }

  Future<Map> getData(city) async{
    http.Response response = await http.get(getRequestURL(city));
    return json.decode(response.body);
  }

  List<Widget> _loadInfos(textLoad){
      return <Widget>[
        Text(
            textLoad,
            style: TextStyle(color: textColor, fontSize: 50.0),
            textAlign: TextAlign.center,
        ),
        Container(
          alignment: Alignment.center,
          width: 200.0,
          height: 200.0,
          child: SizedBox(
            height: 80,
            width: 80,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
              strokeWidth: 10.0,
            ),
          )
        )
      ];
  }

  Container _getListViewForecast(List<dynamic> forecasts, BuildContext buildContext){
    return Container(
      height: 130,
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: secondColor,
          boxShadow: [
            BoxShadow(
              offset: Offset(1.0, 1.0),
              blurRadius: 5.0,
              spreadRadius: 1.0
            ),
          ]
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: forecasts.length,
        padding: EdgeInsets.all(1.0),
        itemBuilder: (context, index){
          final imagePath = "assets/images/${forecasts[index]["condition"].toString()}.svg";
          return Container(
              width: 150,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.topLeft,
                        padding: EdgeInsets.only(left: 10),
                        child: Text(
                          forecasts[index]["weekday"].toString(),
                          style: TextStyle(
                            color: textColor
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.topRight,
                        padding: EdgeInsets.only(right: 10),
                        child: Text(
                          forecasts[index]["date"].toString(),
                          style: TextStyle(
                            color: textColor
                          ),
                        ),
                      )
                    ],
                  ),
                  SvgPicture.asset(
                    imagePath,
                    placeholderBuilder: (context) => Icon(Icons.error),
                    semanticsLabel: "condition",
                    height: 50,
                    width: 50,
                    color: firstColor,
                  ),
                  Text(
                      "Max: "+ forecasts[index]["max"].toString()+"º",
                      style: TextStyle(
                        color: textColor
                      ),
                  ),
                  Text(
                      "Min: "+ forecasts[index]["min"].toString()+"º",
                      style: TextStyle(
                          color: textColor
                      ),
                  ),
                ],
              )
          );
        },
      ),
    );
  }

}