import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:soar_quest/soar_quest.dart';
import 'package:tinder_with_chuck_norris/firebase_options.dart';

part 'main.g.dart';

late final SQCollection favsCollection, categories, jokesCollection;

final addFavAction = CreateDocAction("Add to favs",
    show: DocCond((doc, context) =>
        favsCollection.docs.any((favDoc) => favDoc.label == doc.label)).not,
    getCollection: () => favsCollection,
    form: false,
    goBack: true,
    initialFields: (doc) => [SQStringField("Joke", value: doc.label)],
    onExecute: (doc, context) async {
      doc.collection.deleteDoc(doc);
      doc.collection.loadCollection();
    });

final discardAction =
    CustomAction("Discard", customExecute: (doc, context) async {
  await doc.collection.deleteDoc(doc);
  doc.collection.loadCollection();
});

void main() async {
  await SQApp.init(
    "Tinder with Chuck Norris",
    theme: ThemeData(primarySwatch: Colors.deepOrange),
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );

  await UserSettings.setSettings([
    SQEnumField(SQStringField("Category", value: "random"),
        options: ["random", "animal", "career", "celebrity"])
  ]);

  jokesCollection = JokesCollection(
    id: "Jokes",
    fields: [SQStringField("value")],
    actions: [addFavAction, discardAction],
  );

  await jokesCollection.loadCollection();

  favsCollection = FirestoreCollection(
      id: "Favourites",
      fields: [SQStringField("Joke")],
      updates: false,
      adds: false,
      parentDoc: SQDoc("uid", collection: SQAuth.usersCollection));

// TODO: Fetch categories from api and add a drop down for them
// TODO: Handle no internet

  SQApp.run([
    // const JokesScreen("Jokes", icon: Icons.comment),
    // CollectionScreen(collection: jokesCollection),
    JokesScreen2(collection: jokesCollection),
    // DocScreen(jokesCollection.docs.first, title: "Joke"),
    // DocScreen(doc)
    CollectionScreen(collection: favsCollection, icon: Icons.favorite),
    UserSettings.settingsScreen(),
  ]);
}

class JokesScreen2 extends CollectionScreen {
  JokesScreen2({required super.collection, super.title, super.icon, super.key});
  @override
  createState() => JokesScreenState2();
}

class JokesScreenState2 extends CollectionScreenState<JokesScreen2> {
  @override
  Widget docDisplay(SQDoc doc, BuildContext context) {
    return Dismissible(
      key: ValueKey(doc.id),
      child: Column(
        children: [
          Container(
            color: Colors.orange,
            height: 400,
            padding: const EdgeInsets.all(8.0),
            child: Text(doc.label),
          ),
          Row(
              children: collection.actions
                  .where((action) => action.show.check(doc, context))
                  .take(2)
                  .map((action) => action.button(doc))
                  .toList())
        ],
      ),
      onDismissed: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await addFavAction.execute(doc, context);
          refreshScreen();
        }
        if (direction == DismissDirection.endToStart) {
          await discardAction.execute(doc, context);
          refreshScreen();
        }
      },
    );
  }

  @override
  Widget docsDisplay(List<SQDoc> docs, BuildContext context) {
    return Stack(
      children: docs.map((doc) => docDisplay(doc, context)).toList(),
    );
  }
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
      final String? category = UserSettings().getSetting("Category");
      if (category != null) {
        if (category != "random") queryUrl += "?category=$category";
      }
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
          favsCollection.saveDoc(favsCollection.newDoc(initialFields: [
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
                      // const Padding(
                      //   padding: EdgeInsets.all(16.0),
                      //   child: Image(
                      //     image: AssetImage('graphics/chuck-norris.png'),
                      //     width: 300,
                      //   ),
                      // ),
                      Text(
                        _swipeItems[index].content,
                        style:
                            const TextStyle(fontSize: 25, color: Colors.white),
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

class JokesCollection extends SQCollection {
  JokesCollection({required super.id, required super.fields, super.actions})
      : super(readOnly: true);

  @override
  Future<void> loadCollection() async {
    try {
      String queryUrl = 'https://api.chucknorris.io/jokes/random';
      final String? category = UserSettings().getSetting("Category");
      if (category != null) {
        if (category != "random") queryUrl += "?category=$category";
      }
      var response = await Dio().get(queryUrl);
      var jsonData = jsonDecode(response.toString());

      await saveDoc(
        newDoc()..parse(jsonData),
      );
    } catch (e) {
      return;
    }
  }

  @override
  Future<void> saveCollection() async {}
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
