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
    await _service.start();
    _running = true;
  }

  static Future<void> stop() async {
    await _service.invoke('stopService');
    _running = false;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    if (service is AndroidServiceInstance) {
      service.on('stopService').listen((_) {
        service.stopSelf();
      });
      service.setForegroundServiceInfo(const NotificationInfo(
        channelId: 'background_service',
        channelName: 'خدمة الخلفية',
        channelDescription: 'تبقي التطبيق شغال لتلقي الإشعارات',
        notificationId: 888,
        title: 'madrasa-app',
        content: 'التطبيق شغال في الخلفية',
      ));
    }
  }
}
