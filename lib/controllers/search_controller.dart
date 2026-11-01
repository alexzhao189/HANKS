import 'package:get/get.dart';
import 'package:tiktok_tutorial/models/user.dart';
import 'package:tiktok_tutorial/services/local_db.dart';

class SearchController extends GetxController {
  final Rx<List<User>> _searchedUsers = Rx<List<User>>([]);

  List<User> get searchedUsers => _searchedUsers.value;

  Future<void> searchUser(String typedUser) async {
    if (typedUser.trim().isEmpty) {
      _searchedUsers.value = [];
      return;
    }
    _searchedUsers.value =
        await LocalDb.instance.searchUsersByName(typedUser);
  }
}
