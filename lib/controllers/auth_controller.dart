import 'package:get/get.dart';
import '../models/user.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();

  var loggedUser = User().obs;
  var selectedEditUser = User().obs;

  var isSyncIn = false.obs;
}
