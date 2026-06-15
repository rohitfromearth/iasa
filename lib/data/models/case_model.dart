import '../../domain/entities/case_entity.dart';

import '../../domain/enums/case_status.dart';

import '../../domain/enums/sync_status.dart';

import '../../domain/enums/user_role.dart';

import '../../core/constants/database_constants.dart';



class CaseModel {

  const CaseModel({

    required this.id,

    required this.title,

    required this.questionBody,

    required this.status,

    required this.createdByRole,

    required this.syncStatus,

    required this.createdAt,

    required this.updatedAt,

    this.answerBody,

    this.onlineStatus,

    this.lastSyncedAt,

    this.verifiedAt,

  });



  final String id;

  final String title;

  final String questionBody;

  final String? answerBody;

  final CaseStatus status;

  final CaseStatus? onlineStatus;

  final UserRole createdByRole;

  final SyncStatus syncStatus;

  final DateTime createdAt;

  final DateTime updatedAt;

  final DateTime? lastSyncedAt;

  final DateTime? verifiedAt;



  factory CaseModel.fromEntity(CaseEntity entity) {

    return CaseModel(

      id: entity.id,

      title: entity.title,

      questionBody: entity.questionBody,

      answerBody: entity.answerBody,

      status: entity.status,

      onlineStatus: entity.onlineStatus,

      createdByRole: entity.createdByRole,

      syncStatus: entity.syncStatus,

      createdAt: entity.createdAt,

      updatedAt: entity.updatedAt,

      lastSyncedAt: entity.lastSyncedAt,

      verifiedAt: entity.verifiedAt,

    );

  }



  factory CaseModel.fromMap(Map<String, Object?> map) {

    return CaseModel(

      id: map[DatabaseConstants.colId]! as String,

      title: map[DatabaseConstants.colTitle]! as String,

      questionBody: map[DatabaseConstants.colQuestionBody]! as String,

      answerBody: map[DatabaseConstants.colAnswerBody] as String?,

      status: CaseStatus.values.byName(map[DatabaseConstants.colStatus]! as String),

      onlineStatus: _statusFromMap(map[DatabaseConstants.colOnlineStatus] as String?),

      createdByRole:

          UserRole.values.byName(map[DatabaseConstants.colCreatedByRole]! as String),

      syncStatus:

          SyncStatus.values.byName(map[DatabaseConstants.colSyncStatus]! as String),

      createdAt: DateTime.fromMillisecondsSinceEpoch(

        map[DatabaseConstants.colCreatedAt]! as int,

        isUtc: true,

      ),

      updatedAt: DateTime.fromMillisecondsSinceEpoch(

        map[DatabaseConstants.colUpdatedAt]! as int,

        isUtc: true,

      ),

      lastSyncedAt: _dateFromMillis(map[DatabaseConstants.colLastSyncedAt] as int?),

      verifiedAt: _dateFromMillis(map[DatabaseConstants.colVerifiedAt] as int?),

    );

  }



  Map<String, Object?> toMap() {

    return {

      DatabaseConstants.colId: id,

      DatabaseConstants.colTitle: title,

      DatabaseConstants.colQuestionBody: questionBody,

      DatabaseConstants.colAnswerBody: answerBody,

      DatabaseConstants.colStatus: status.name,

      DatabaseConstants.colOnlineStatus: onlineStatus?.name,

      DatabaseConstants.colCreatedByRole: createdByRole.name,

      DatabaseConstants.colSyncStatus: syncStatus.name,

      DatabaseConstants.colCreatedAt: createdAt.millisecondsSinceEpoch,

      DatabaseConstants.colUpdatedAt: updatedAt.millisecondsSinceEpoch,

      DatabaseConstants.colLastSyncedAt: lastSyncedAt?.millisecondsSinceEpoch,

      DatabaseConstants.colVerifiedAt: verifiedAt?.millisecondsSinceEpoch,

    };

  }



  CaseEntity toEntity() {

    return CaseEntity(

      id: id,

      title: title,

      questionBody: questionBody,

      answerBody: answerBody,

      status: status,

      onlineStatus: onlineStatus,

      createdByRole: createdByRole,

      syncStatus: syncStatus,

      createdAt: createdAt,

      updatedAt: updatedAt,

      lastSyncedAt: lastSyncedAt,

      verifiedAt: verifiedAt,

    );

  }



  static CaseStatus? _statusFromMap(String? value) {

    if (value == null) {

      return null;

    }

    return CaseStatus.values.byName(value);

  }



  static DateTime? _dateFromMillis(int? millis) {

    if (millis == null) {

      return null;

    }

    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);

  }

}


