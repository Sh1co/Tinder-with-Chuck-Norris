import 'package:soar_quest/soar_quest.dart';
import 'package:tinder_with_chuck_norris/api/cn_api.dart';

class SettingsScreen {
  static getSettingScreen() async {
    List<dynamic> jokesCategories = await ChuckNorrisApi.getCategories();
    jokesCategories.add("random");

    await UserSettings.setSettings([
      SQEnumField(SQStringField("Category", value: "random"),
          options: jokesCategories)
    ]);

    return UserSettings.settingsScreen();
  }
}
