import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:swipe_cards/draggable_card.dart';
import 'package:swipe_cards/swipe_cards.dart';

part 'main.g.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tinder with Chuck Norris',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: const MyHomePage(title: 'Tinder with Chuck Norris'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<SwipeItem> _swipeItems = <SwipeItem>[];
  late MatchEngine _matchEngine;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  Future<Joke> _getJoke() async {
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

  Future<void> addItem() async {
    Joke joke = await _getJoke();
    _swipeItems.add(SwipeItem(
        content: joke.value,
        onSlideUpdate: (SlideRegion? region) async {
          addItem();
        }));
  }

  void addInitItem() {
    _swipeItems.add(SwipeItem(content: "Swipe to get new Chuck Norris jokes"));
  }

  @override
  void initState() {
    addInitItem();
    for (int i = 0; i < 3; i++) {
      addItem();
    }

    _matchEngine = MatchEngine(swipeItems: _swipeItems);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(widget.title),
          leading: Image(image: AssetImage('graphics/chuck-norris-icon.png')),
        ),
        body: Container(
            child: Column(children: [
          Container(
            height: 550,
            child: SwipeCards(
              matchEngine: _matchEngine,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                    alignment: Alignment.center,
                    color: Colors.brown,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Image(
                              image: AssetImage('graphics/chuck-norris.png'),
                              width: 300,
                            ),
                          ),
                          Text(
                            _swipeItems[index].content,
                            style: const TextStyle(
                                fontSize: 20, color: Colors.white),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    ));
              },
              onStackFinished: () {
                _scaffoldKey.currentState?.showSnackBar(const SnackBar(
                  content: const Text("Stack Finished"),
                  duration: Duration(milliseconds: 500),
                ));
              },
              itemChanged: (SwipeItem item, int index) {
                print("item: ${item.content}, index: $index");
              },
              upSwipeAllowed: true,
              fillSpace: true,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 25, 0, 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RawMaterialButton(
                  onPressed: () {
                    _matchEngine.currentItem?.nope();
                  },
                  elevation: 2.0,
                  fillColor: Colors.red,
                  padding: const EdgeInsets.all(15.0),
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.arrow_downward_outlined,
                    color: Colors.white,
                    size: 35.0,
                  ),
                ),
                RawMaterialButton(
                  onPressed: () {
                    _matchEngine.currentItem?.like();
                  },
                  elevation: 2.0,
                  fillColor: Colors.green,
                  padding: const EdgeInsets.all(15.0),
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.arrow_upward_outlined,
                    color: Colors.white,
                    size: 35.0,
                  ),
                ),
              ],
            ),
          ),
        ])));
  }
}

@JsonSerializable()
class Joke {
  final String icon_url, id, url, value;

  Joke(
      {required this.icon_url,
      required this.id,
      required this.url,
      required this.value});

  factory Joke.fromJson(Map<String, dynamic> json) => _$JokeFromJson(json);

  Map<String, dynamic> toJson() => _$JokeToJson(this);
}
