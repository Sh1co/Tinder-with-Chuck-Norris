import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:soar_quest/soar_quest.dart';
import 'package:tinder_with_chuck_norris/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'main.g.dart';

late final SQCollection favJokesCollection, categories;

void main() async {
  await SQApp.init(
    "Tinder with Chuck Norris",
    theme: ThemeData(primarySwatch: Colors.deepOrange),
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );

  List<dynamic> jokesCategories = await getCategories();

  await UserSettings.setSettings([
    SQEnumField(SQStringField("Category", value: "random"),
        options: jokesCategories)
  ]);


  favJokesCollection = FirestoreCollection(
      id: "Favourites",
      fields: [SQStringField("Joke")],
      updates: false,
      adds: false,
      parentDoc: SQDoc(userID, collection: SQAuth.usersCollection));

  SQApp.run([
    const JokesScreen("Jokes", icon: Icons.comment),
    CollectionScreen(collection: favJokesCollection, icon: Icons.favorite),
    UserSettings.settingsScreen(),
  ]);
}

Future<List<dynamic>> getCategories() async {
  try {
    var response =
        await Dio().get("https://api.chucknorris.io/jokes/categories");
    String responseStr = response.toString();
    final jokesCategories = [];
    String categorie = "";
    for (var i = 0; i < responseStr.length; i++) {
      if (responseStr[i] == '[') {
        continue;
      } else if (responseStr[i] == ',' || responseStr[i] == ']') {
        jokesCategories.add(categorie);
        categorie = "";
        i++;
      } else {
        categorie = categorie + responseStr[i];
      }
    }
    return jokesCategories;
  } on Exception {
    return [];
  }
}
  }
  return jokesCategories;
}

class JokesScreen extends Screen {
  const JokesScreen(super.title, {super.icon, super.key});
  @override
  createState() => JokesScreenState();
}

class JokesScreenState extends ScreenState<JokesScreen> {
  final List<SwipeItem> _swipeItems = <SwipeItem>[];
  late MatchEngine _matchEngine;

  Future<Joke> _getJoke() async {
    try {
      String queryUrl = 'https://api.chucknorris.io/jokes/random';
      final String category = UserSettings().getSetting("Category");
      if (category != "random") queryUrl += "?category=$category";
      var response = await Dio().get(queryUrl);
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
        nopeAction: () => addItem(),
        likeAction: () {
          addItem();

          final SwipeItem? currentItem = _matchEngine.currentItem;
          if (currentItem == null) return;
          favJokesCollection.saveDoc(favJokesCollection.newDoc(initialFields: [
            SQStringField("Joke", value: currentItem.content)
          ]));
        }));
    _matchEngine = MatchEngine(swipeItems: _swipeItems);
    setState(() {});
  }

  void addInitItem() {
    _swipeItems.add(SwipeItem(content: "Swipe to get new Chuck Norris jokes"));
  }

  @override
  void initState() {
    for (int i = 0; i < 2; i++) {
      addItem();
    }
    super.initState();
  }

  @override
  AppBar appBar(BuildContext context) {
    return AppBar(
      title: Text(widget.title),
      leading: const Image(image: AssetImage('graphics/chuck-norris-icon.png')),
    );
  }

  @override
  Widget screenBody(BuildContext context) {
    if (_swipeItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(children: [
      SizedBox(
        height: 450,
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
                          width: 200,
                        ),
                      ),
                      Text(
                        _swipeItems[index].content,
                        style:
                            const TextStyle(fontSize: 15, color: Colors.white),
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                ));
          },
          onStackFinished: () {},
          upSwipeAllowed: false,
          fillSpace: true,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 13, 0, 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SQButton.icon(Icons.thumb_down,
                onPressed: () => _matchEngine.currentItem?.nope(),
                iconSize: 50),
            SQButton.icon(Icons.thumb_up,
                onPressed: () => _matchEngine.currentItem?.like(),
                iconSize: 50),
          ],
        ),
      ),
    ]);
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
