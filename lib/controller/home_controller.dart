import 'package:get/get.dart';

class HomeController extends GetxController {
  var userName = "Memuat...".obs;
  var userLevel = "Beginner".obs;

  @override
  void onInit() {
    fetchUserData();
    super.onInit();
  }

  void fetchUserData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    userName.value = "Gym Bro";
    userLevel.value = "Beginner";
  }
}
