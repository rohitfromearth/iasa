/// Application-wide constants.
abstract final class AppConstants {
  static const String appName = 'IASA Healthcare';
  static const String appLogoAsset = 'assets/images/app_logo.png';
  static const String aboutBackgroundAsset = 'assets/images/about.png';
  static const String databaseName = 'iasa_healthcare.db';
  static const int databaseVersion = 4;

  static const int maxSubmissionPhotos = 5;
  static const int maxSubmissionAttachments = 3;
  static const String submissionMediaDir = 'submission_media';

  static const List<String> allowedPhotoExtensions = [
    'jpg',
    'jpeg',
    'png',
  ];

  static const List<String> allowedAttachmentExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
  ];
}
