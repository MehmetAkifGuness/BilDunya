import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bildunya_frontend/core/network/dio_client.dart';
import 'package:bildunya_frontend/data/repositories/auth_repository.dart';
import 'package:bildunya_frontend/data/repositories/content_repository.dart';
import 'package:bildunya_frontend/features/auth/providers/auth_provider.dart';
import 'package:bildunya_frontend/features/content/providers/contents_provider.dart';
import 'package:bildunya_frontend/main.dart';

void main() {
  testWidgets('Splash shows BilDünya branding', (WidgetTester tester) async {
    const storage = FlutterSecureStorage();
    final dio = DioClient.create(storage);
    final authRepository = AuthRepository(dio, storage);
    final contentRepository = ContentRepository(dio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ContentRepository>.value(value: contentRepository),
          ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
          ChangeNotifierProvider(create: (_) => ContentsProvider(contentRepository)),
        ],
        child: const BilDunyaApp(),
      ),
    );

    expect(find.text('BilDünya'), findsOneWidget);
    expect(find.text('THE MIDNIGHT NAVIGATOR'), findsOneWidget);
    expect(find.text('Keşfetmeye Başla'), findsOneWidget);
  });
}
