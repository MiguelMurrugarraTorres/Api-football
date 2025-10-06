
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Debe ser top-level y con @pragma para que no lo tree-shakee.
/// Puedes cambiar el nombre si quieres, lo importante es exportarlo e importarlo desde main.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // opcional: logging
}
