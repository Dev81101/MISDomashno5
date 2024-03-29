import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'location_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'location.dart';
import 'exam.dart';

class NotificationService {
  int idCount = 0;
  bool locationNotificationActive = false;
  Location location = Location("FINKI", 42.004186212873655, 21.409531941596985);
  DateTime? lastNotificationTime;

  NotificationService() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (locationNotificationActive) {
        checkLocationAndNotify();
      }
    });
  }

  void scheduleNotificationsForExistingExams(exams) {
    for (int i = 0; i < exams.length; i++) {
      scheduleNotification(exams[i]);
    }
  }

  void scheduleNotification(Exam exam) {
    final int notificationId = idCount++;

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: "basic_channel",
        title: exam.course,
        body: "Exam tommorow!!",
      ),
      schedule: NotificationCalendar(
        day: exam.timestamp.subtract(const Duration(days: 1)).day,
        month: exam.timestamp.subtract(const Duration(days: 1)).month,
        year: exam.timestamp.subtract(const Duration(days: 1)).year,
        hour: exam.timestamp.subtract(const Duration(days: 1)).hour,
        minute: exam.timestamp.subtract(const Duration(days: 1)).minute,
      ),
    );
  }

  Future<void> toggleLocationNotification() async {
    locationNotificationActive = !locationNotificationActive;

    if (locationNotificationActive) {
      checkLocationAndNotify();
    }
  }

  Future<void> checkLocationAndNotify() async {
    if (await Permission.locationWhenInUse.serviceStatus.isEnabled) {
      bool theSameLocation = false;

      LocationService().getCurrentLocation().then((value) {
        if ((value.latitude < location.latitude + 0.01 &&
                value.latitude > location.latitude - 0.01) &&
            (value.longitude < location.longitude + 0.01 &&
                value.longitude > location.longitude - 0.01)) {
          theSameLocation = true;
        }

        if (theSameLocation && canSendNotification()) {
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: idCount++,
              channelKey: "basic_channel",
              title: "Better start going!",
              body: "Exam is comming!",
            ),
          );
          lastNotificationTime = DateTime.now();
        }
      });
    }
  }

  bool canSendNotification() {
    return lastNotificationTime == null ||
        DateTime.now().difference(lastNotificationTime!) >
            const Duration(minutes: 10);
  }
}
