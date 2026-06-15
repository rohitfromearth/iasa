import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/auth/session_storage.dart';
import '../core/database/database_helper.dart';
import '../core/network/network_info.dart';
import '../core/utils/uuid_generator.dart';
import '../data/datasources/local/case_local_datasource.dart';
import '../data/datasources/remote/api_datasource.dart';
import '../data/datasources/remote/mock_api_datasource.dart';
import '../data/repositories/case_repository_impl.dart';
import '../domain/enums/user_role.dart';
import '../domain/repositories/case_repository.dart';
import '../domain/usecases/get_cases_usecase.dart';
import '../domain/usecases/get_pending_submissions_usecase.dart';
import '../domain/usecases/refresh_cases_usecase.dart';
import '../domain/usecases/submit_question_usecase.dart';
import '../domain/usecases/sync_pending_submissions_usecase.dart';
import '../domain/usecases/update_case_status_usecase.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/case_detail_provider.dart';
import '../presentation/providers/case_list_provider.dart';
import '../presentation/providers/submission_provider.dart';

/// Composes the dependency graph and exposes it via Provider.
class Injection {
  Injection._();

  static List<SingleChildWidget> providers({
    required SessionStorage sessionStorage,
  }) {
    return [
      // Core services
      Provider<Connectivity>.value(value: Connectivity()),
      Provider<DatabaseHelper>.value(value: DatabaseHelper.instance),
      Provider<SessionStorage>.value(value: sessionStorage),
      Provider<UuidGenerator>(
        create: (_) => UuidGeneratorImpl(),
      ),
      ProxyProvider<Connectivity, NetworkInfo>(
        update: (_, connectivity, _) => NetworkInfoImpl(connectivity),
      ),

      // Data layer
      Provider<CaseLocalDataSource>(
        create: (context) =>
            CaseLocalDataSource.fromHelper(context.read<DatabaseHelper>()),
      ),
      Provider<ApiDataSource>(
        create: (_) => MockApiDataSource(),
      ),
      ProxyProvider4<CaseLocalDataSource, ApiDataSource, NetworkInfo,
          UuidGenerator, CaseRepository>(
        update: (_, local, api, networkInfo, uuidGenerator, _) =>
            CaseRepositoryImpl(
          localDataSource: local,
          apiDataSource: api,
          networkInfo: networkInfo,
          uuidGenerator: uuidGenerator,
        ),
      ),

      // Use cases
      ProxyProvider<CaseRepository, GetCasesUseCase>(
        update: (_, repository, _) => GetCasesUseCase(repository),
      ),
      ProxyProvider<CaseRepository, RefreshCasesUseCase>(
        update: (_, repository, _) => RefreshCasesUseCase(repository),
      ),
      ProxyProvider<CaseRepository, SubmitQuestionUseCase>(
        update: (_, repository, _) => SubmitQuestionUseCase(repository),
      ),
      ProxyProvider<CaseRepository, SyncPendingSubmissionsUseCase>(
        update: (_, repository, _) =>
            SyncPendingSubmissionsUseCase(repository),
      ),
      ProxyProvider<CaseRepository, GetPendingSubmissionsUseCase>(
        update: (_, repository, _) =>
            GetPendingSubmissionsUseCase(repository),
      ),
      ProxyProvider<CaseRepository, UpdateCaseStatusUseCase>(
        update: (_, repository, _) => UpdateCaseStatusUseCase(repository),
      ),

      // Presentation
      ChangeNotifierProvider(
        create: (context) => AuthProvider(context.read<SessionStorage>()),
      ),
      ChangeNotifierProxyProvider2<GetCasesUseCase, RefreshCasesUseCase,
          CaseListProvider>(
        create: (context) => CaseListProvider(
          getCasesUseCase: context.read<GetCasesUseCase>(),
          refreshCasesUseCase: context.read<RefreshCasesUseCase>(),
        ),
        update: (_, getCases, refreshCases, previous) =>
            previous ??
            CaseListProvider(
              getCasesUseCase: getCases,
              refreshCasesUseCase: refreshCases,
            ),
      ),
      ChangeNotifierProxyProvider2<GetCasesUseCase, UpdateCaseStatusUseCase,
          CaseDetailProvider>(
        create: (context) => CaseDetailProvider(
          getCasesUseCase: context.read<GetCasesUseCase>(),
          updateCaseStatusUseCase: context.read<UpdateCaseStatusUseCase>(),
        ),
        update: (_, getCases, updateStatus, previous) =>
            previous ??
            CaseDetailProvider(
              getCasesUseCase: getCases,
              updateCaseStatusUseCase: updateStatus,
            ),
      ),
      ChangeNotifierProxyProvider4<SubmitQuestionUseCase,
          SyncPendingSubmissionsUseCase, GetPendingSubmissionsUseCase,
          AuthProvider, SubmissionProvider>(
        create: (context) => SubmissionProvider(
          submitQuestionUseCase: context.read<SubmitQuestionUseCase>(),
          syncPendingSubmissionsUseCase:
              context.read<SyncPendingSubmissionsUseCase>(),
          getPendingSubmissionsUseCase:
              context.read<GetPendingSubmissionsUseCase>(),
          roleResolver: () =>
              context.read<AuthProvider>().selectedRole ?? UserRole.warrior,
        ),
        update: (_, submit, sync, getPending, auth, previous) =>
            previous ??
            SubmissionProvider(
              submitQuestionUseCase: submit,
              syncPendingSubmissionsUseCase: sync,
              getPendingSubmissionsUseCase: getPending,
              roleResolver: () => auth.selectedRole ?? UserRole.warrior,
            ),
      ),
    ];
  }
}
