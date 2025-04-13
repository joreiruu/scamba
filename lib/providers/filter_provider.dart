import 'package:flutter/material.dart';

class FilterProvider extends ChangeNotifier {
  bool filterHamMessages = false;
  String selectedTab = 'All Messages'; // Default tab

  void toggleFilter(bool value) {
    filterHamMessages = value;
    notifyListeners(); // Notify UI to rebuild
  }

  void setSelectedTab(String tab) {
    selectedTab = tab;
    notifyListeners(); // Notify UI to rebuild
  }
}
