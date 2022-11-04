import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cn_api.g.dart';

class CNApi {
  Future<Joke> getJoke() async {
    try {
      var response = await Dio().get('https://api.chucknorris.io/jokes/random');
      var jsonData = jsonDecode(response.toString());

      Joke joke = Joke.fromJson(jsonData);

      return joke;
    } catch (e) {
      Joke failed = Joke(
          icon_url: "",
          id: "",
          url: "",
          value: "Failed to load joke, check internet connection");
      return failed;
    }
  }
}

@JsonSerializable()
class Joke {
  //Ignore used here because this needs to be the same name as the field name returned from the chuck norris API
  // ignore: non_constant_identifier_names
  final String icon_url, id, url, value;

  Joke(
      // ignore: non_constant_identifier_names
      {required this.icon_url,
      required this.id,
      required this.url,
      required this.value});

  factory Joke.fromJson(Map<String, dynamic> json) => _$JokeFromJson(json);

  Map<String, dynamic> toJson() => _$JokeToJson(this);
}
