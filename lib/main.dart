import 'package:flutter/material.dart';
import 'package:soar_quest/soar_quest.dart';
import 'package:tinder_with_chuck_norris/api/cn_api.dart';
import 'package:tinder_with_chuck_norris/device_id.dart';
import 'package:tinder_with_chuck_norris/firebase/firebase_options.dart';
import 'package:tinder_with_chuck_norris/screens/fav_screen.dart';
import 'package:tinder_with_chuck_norris/screens/jokes_screen.dart';

late final SQCollection categories;

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

  SQApp.run([
    const JokesScreen("Jokes", icon: Icons.comment),
    FavoriteJokes.getFavoriteScreen(userID),
    UserSettings.settingsScreen(),
  ]);
}
