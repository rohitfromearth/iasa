import '../enums/case_status.dart';

import '../enums/sync_status.dart';

import '../enums/user_role.dart';



/// Cached or optimistically created healthcare case.

///

/// [id] is a client-generated UUID used as the idempotency key.

/// [status] is the local workflow state on this device.

/// [onlineStatus] is the last status confirmed from the server.

class CaseEntity {

  const CaseEntity({

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



  /// Server-confirmed status, falling back to local when never fetched online.

  CaseStatus get displayOnlineStatus => onlineStatus ?? status;



  /// True when a local status change has not yet reached the server.

  bool get hasUnsyncedStatusChange =>

      onlineStatus != null && status != onlineStatus;



  CaseEntity copyWith({

    String? id,

    String? title,

    String? questionBody,

    String? answerBody,

    bool clearAnswerBody = false,

    CaseStatus? status,

    CaseStatus? onlineStatus,

    bool clearOnlineStatus = false,

    UserRole? createdByRole,

    SyncStatus? syncStatus,

    DateTime? createdAt,

    DateTime? updatedAt,

    DateTime? lastSyncedAt,

    bool clearLastSyncedAt = false,

    DateTime? verifiedAt,

    bool clearVerifiedAt = false,

  }) {

    return CaseEntity(

      id: id ?? this.id,

      title: title ?? this.title,

      questionBody: questionBody ?? this.questionBody,

      answerBody: clearAnswerBody ? null : (answerBody ?? this.answerBody),

      status: status ?? this.status,

      onlineStatus:

          clearOnlineStatus ? null : (onlineStatus ?? this.onlineStatus),

      createdByRole: createdByRole ?? this.createdByRole,

      syncStatus: syncStatus ?? this.syncStatus,

      createdAt: createdAt ?? this.createdAt,

      updatedAt: updatedAt ?? this.updatedAt,

      lastSyncedAt:

          clearLastSyncedAt ? null : (lastSyncedAt ?? this.lastSyncedAt),

      verifiedAt: clearVerifiedAt ? null : (verifiedAt ?? this.verifiedAt),

    );

  }



  @override

  bool operator ==(Object other) =>

      identical(this, other) ||

      other is CaseEntity &&

          runtimeType == other.runtimeType &&

          id == other.id &&

          title == other.title &&

          questionBody == other.questionBody &&

          answerBody == other.answerBody &&

          status == other.status &&

          onlineStatus == other.onlineStatus &&

          createdByRole == other.createdByRole &&

          syncStatus == other.syncStatus &&

          createdAt == other.createdAt &&

          updatedAt == other.updatedAt &&

          lastSyncedAt == other.lastSyncedAt &&

          verifiedAt == other.verifiedAt;



  @override

  int get hashCode => Object.hash(

        id,

        title,

        questionBody,

        answerBody,

        status,

        onlineStatus,

        createdByRole,

        syncStatus,

        createdAt,

        updatedAt,

        lastSyncedAt,

        verifiedAt,

      );

}


