import 'package:test/test.dart';
import 'package:upcode_ci/src/commands/flutter/firebase_app_distribution.dart';
import 'package:upcode_ci/src/generated/firebaseappdistribution/v1alpha.dart' as fad_v1alpha;

void main() {
  group('buildReleaseTest', () {
    final List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice> devices =
        <fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice>[
      fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice(
        model: 'MediumPhone.arm',
        version: '34',
        locale: 'en',
        orientation: 'portrait',
      ),
    ];

    test('maps steps, device executions, display name and results bucket', () {
      final fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest result = buildReleaseTest(
        displayName: 'smoke',
        steps: <fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep>[
          fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep(goal: 'open app', successCriteria: 'home shown'),
        ],
        devices: devices,
        loginCredential: null,
        resultsBucket: 'gs://bucket',
      );

      expect(result.displayName, 'smoke');
      expect(result.resultsBucket, 'gs://bucket');
      expect(result.aiInstructions!.steps!.single.goal, 'open app');
      expect(result.deviceExecutions!.single.device!.model, 'MediumPhone.arm');
      expect(result.loginCredential, isNull);
    });

    test('omits results bucket and includes login credential when provided', () {
      final fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest result = buildReleaseTest(
        displayName: null,
        steps: <fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep>[],
        devices: devices,
        loginCredential: fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential(username: 'a@b.c'),
        resultsBucket: null,
      );

      expect(result.displayName, isNull);
      expect(result.resultsBucket, isNull);
      expect(result.loginCredential!.username, 'a@b.c');
    });
  });
}
