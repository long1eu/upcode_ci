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

  group('resultsBucketResource', () {
    const String appId = '1:701983982478:android:a1c3c8af2c3e3ff3a5dadf';

    test('formats a bare bucket name as the project-scoped resource path', () {
      expect(
        resultsBucketResource('cinderblock-198615-testlab', appId),
        'projects/701983982478/buckets/cinderblock-198615-testlab',
      );
    });

    test('strips a gs:// prefix', () {
      expect(resultsBucketResource('gs://my-bucket', appId), 'projects/701983982478/buckets/my-bucket');
    });

    test('returns null when no bucket is given, so Firebase uses its default', () {
      expect(resultsBucketResource(null, appId), isNull);
      expect(resultsBucketResource('', appId), isNull);
    });

    test('rejects a bucket name that is not a valid GCS name', () {
      expect(() => resultsBucketResource('Not A Bucket', appId), throwsFormatException);
    });
  });

  group('parseAiTests', () {
    test('reads display name, id, prerequisite and steps from the YAML', () {
      const String yaml = '''
tests:
  - displayName: Log in
    id: login
    steps:
      - goal: Sign in
        hint: Tap Log in
        successCriteria: Home is shown
  - displayName: Create a task
    id: create-task
    prerequisiteTestCaseId: login
    steps:
      - goal: Open Tasks
        finalScreenAssertion: The task list is shown
''';
      final List<AiTestDefinition> tests = parseAiTests(yaml);

      expect(tests.map((AiTestDefinition t) => t.id), <String>['login', 'create-task']);
      expect(tests.first.displayName, 'Log in');
      expect(tests.first.prerequisiteTestCaseId, isNull);
      expect(tests.last.prerequisiteTestCaseId, 'login');
      expect(tests.first.steps.single.hint, 'Tap Log in');
      expect(tests.first.steps.single.successCriteria, 'Home is shown');
      expect(tests.last.steps.single.successCriteria, 'The task list is shown');
    });
  });

  group('flattenPrerequisites', () {
    fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep step(String goal) =>
        fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep(goal: goal);

    AiTestDefinition def(String id, List<String> goals, {String? prerequisite}) => AiTestDefinition(
          displayName: id,
          id: id,
          prerequisiteTestCaseId: prerequisite,
          steps: goals.map(step).toList(),
        );

    test('prepends the whole prerequisite chain, outermost first', () {
      final List<AiTestDefinition> flat = flattenPrerequisites(<AiTestDefinition>[
        def('login', <String>['sign in']),
        def('customer', <String>['create customer'], prerequisite: 'login'),
        def('appointment', <String>['book appointment'], prerequisite: 'customer'),
      ]);

      expect(
        flat.last.steps.map((fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep s) => s.goal),
        <String>['sign in', 'create customer', 'book appointment'],
      );
      expect(
        flat.first.steps.map((fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep s) => s.goal),
        <String>['sign in'],
      );
    });

    test('rejects an unknown prerequisite id', () {
      expect(
        () => flattenPrerequisites(<AiTestDefinition>[def('a', <String>['x'], prerequisite: 'missing')]),
        throwsFormatException,
      );
    });

    test('rejects a prerequisite cycle', () {
      expect(
        () => flattenPrerequisites(<AiTestDefinition>[
          def('a', <String>['x'], prerequisite: 'b'),
          def('b', <String>['y'], prerequisite: 'a'),
        ]),
        throwsFormatException,
      );
    });
  });

  group('device parsing', () {
    test('the default device is MediumPhone.arm on API 34', () {
      expect(kDefaultAiTestDevice, 'model=MediumPhone.arm,version=34,locale=en,orientation=portrait');
    });

    test('a spec without locale or orientation falls back to en_US portrait', () {
      final fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice device =
          parseTestDevice('model=akita,version=34');

      expect(device.model, 'akita');
      expect(device.version, '34');
      expect(device.locale, 'en_US');
      expect(device.orientation, 'portrait');
    });
  });
}
