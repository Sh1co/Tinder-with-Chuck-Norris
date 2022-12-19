import 'package:flutter/material.dart';
import 'package:soar_quest/soar_quest.dart';

class FavoriteJokes {
  static late final SQCollection favJokesCollection;
  static getFavoriteScreen(userID) {
    favJokesCollection = FirestoreCollection(
        id: "Favourites",
        fields: [SQStringField("Joke")],
        updates: false,
        adds: false,
        parentDoc: SQDoc(userID, collection: SQAuth.usersCollection));

    return CollectionScreen(
        collection: favJokesCollection, icon: Icons.favorite);
  }

  static getFavJokes() {
    return favJokesCollection;
  }
}
