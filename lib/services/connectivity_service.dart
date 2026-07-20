import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    // checkConnectivity returns a List of ConnectivityResult since version 6.0.0
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }
}
