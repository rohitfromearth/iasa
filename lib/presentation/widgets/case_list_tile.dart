import 'package:flutter/material.dart';

import '../../domain/entities/case_entity.dart';
import 'case_status_display.dart';

class CaseListTile extends StatelessWidget {
  const CaseListTile({
    super.key,
    required this.caseEntity,
    required this.onTap,
  });

  final CaseEntity caseEntity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(caseEntity.title),
        subtitle: Text(
          caseEntity.questionBody,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: CaseStatusDisplay(caseEntity: caseEntity, compact: true),
        onTap: onTap,
      ),
    );
  }
}
