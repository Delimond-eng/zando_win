import 'package:animate_do/animate_do.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zando_m/components/topbar.dart';
import 'package:zando_m/global/controllers.dart';
import 'package:zando_m/repositories/stock_repo/sync.dart';
import 'package:zando_m/services/synchonisation.dart';

import '../components/sidebar.dart';
import '../helpers/navigator.dart';
import '../responsive/base_widget.dart';
import '../responsive/enum_screens.dart';
import '../widgets/app_logo.dart';
import '../widgets/user_session_card.dart';
import '../global/data_sync_in_out.dart' as sync;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Responsive(
      builder: (context, responsiveInfo) {
        return Scaffold(
          drawer: responsiveInfo.deviceScreenType == DeviceScreenType.Desktop
              ? null
              : const Sidebar(),
          key: _globalKey,
          floatingActionButton: ZoomIn(
            child: Obx(
              () => FloatingActionButton(
                child: (authController.isSyncIn.value)
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Icon(
                        Icons.cloud_sync,
                        size: 25.0,
                      ),
                onPressed: () async {
                  sync.startSync();
                  var result = await (Connectivity().checkConnectivity());
                  if (result == ConnectivityResult.mobile ||
                      result == ConnectivityResult.wifi) {
                    if (authController.checkUser) {
                      await Synchroniser.inPutData().then((value) {
                        authController.isSyncIn.value = false;
                      });
                    } else {
                      await SyncStock.syncOut().then((value) {
                        SyncStock.syncIn().then(
                            (value) => authController.isSyncIn.value = false);
                      });
                    }
                  }
                },
              ),
            ),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                height: 70.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const SizedBox(),
                          Positioned(
                            top: -30.0,
                            child: AppLogo(
                              color: responsiveInfo.deviceScreenType !=
                                      DeviceScreenType.Desktop
                                  ? Colors.white
                                  : Colors.white,
                              secondaryColor: Colors.black,
                              size: 25.0,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        child: Obx(
                          () => UserSessionCard(
                            username: authController.loggedUser.value.userName,
                            userRole: authController.loggedUser.value.userRole,
                            color: responsiveInfo.deviceScreenType !=
                                    DeviceScreenType.Desktop
                                ? Colors.white
                                : null,
                          ),
                        ),
                        margin: const EdgeInsets.only(right: 15.0),
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    if (authController.checkUser) ...[
                      if (responsiveInfo.deviceScreenType ==
                          DeviceScreenType.Desktop) ...[
                        _customSidebar(),
                      ],
                    ],
                    _customBody()
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Expanded _customBody() {
    return Expanded(
      flex: 9,
      child: localNavigator(),
    );
  }

  Expanded _customSidebar() {
    return const Expanded(
      flex: 2,
      child: Sidebar(),
    );
  }
}
