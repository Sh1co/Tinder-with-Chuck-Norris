import 'package:flutter/material.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:soar_quest/soar_quest.dart';
import 'package:tinder_with_chuck_norris/api/cn_api.dart';
import 'package:tinder_with_chuck_norris/device_id.dart';
import 'package:tinder_with_chuck_norris/firebase/firebase_options.dart';

late final SQCollection favJokesCollection, categories;

void main() async {
  await SQApp.init(
    "Tinder with Chuck Norris",
    theme: ThemeData(primarySwatch: Colors.deepOrange),
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );

  List<dynamic> jokesCategories = await ChuckNorrisApi.getCategories();
  jokesCategories.add("random");

  await UserSettings.setSettings([
    SQEnumField(SQStringField("Category", value: "random"),
        options: jokesCategories)
  ]);

  String userID = await DeviceIdentifier.getUUID();

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

class JokesScreen extends Screen {
  const JokesScreen(super.title, {super.icon, super.key});
  @override
  createState() => JokesScreenState();
}

class JokesScreenState extends ScreenState<JokesScreen> {
  final List<SwipeItem> _swipeItems = <SwipeItem>[];
  late MatchEngine _matchEngine;

  Future<void> addItem() async {
    Joke joke = await ChuckNorrisApi.getJoke();
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
    setState(() {});
  }

  void addInitItem() {
    _swipeItems.add(SwipeItem(content: "Swipe to get new Chuck Norris jokes"));
  }

  @override
  void initState() {
    for (int i = 0; i < 5; i++) {
      addItem();
    }
    _matchEngine = MatchEngine(swipeItems: _swipeItems);
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
