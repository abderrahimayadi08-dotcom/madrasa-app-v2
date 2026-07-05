import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

class BackgroundService {
  static final _service = FlutterBackgroundService();
  static bool _running = false;

  static Future<void> init() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        autoStartOnBoot: false,
        notificationChannelId: 'background_service',
        initialNotificationTitle: 'madrasa-app',
        initialNotificationContent: 'التطبيق شغال في الخلفية',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: null,
      ),
    );
  }

  static bool get isRunning => _running;

  static Future<void> start() async {
    _service.startService();
    _running = true;
  }

  static void stop() {
    _service.invoke('stopService');
    _running = false;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    if (service is AndroidServiceInstance) {
      service.on('stopService').listen((_) {
        service.stopSelf();
      });
      service.setForegroundNotificationInfo(
        title: 'madrasa-app',
        content: 'التطبيق شغال في الخلفية',
      );
    }
  }
}
