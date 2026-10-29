import 'package:test/test.dart';
import 'package:upcode_ci/src/commands/flutter/windows_identity.dart';

void main() {
  const Map<String, String> prod = <String, String>{
    'name': 'Cinderblock',
    'binary_name': 'cinderblock',
    'installer_id': 'fd9718a0-aed3-4c67-ad70-fb4f40f11e2a',
  };

  group('WindowsIdentity.fromConfig', () {
    test('returns null when there is no windows section', () {
      expect(WindowsIdentity.fromConfig(null), isNull);
    });

    test('reads the three values, upper-casing the GUID', () {
      final WindowsIdentity identity = WindowsIdentity.fromConfig(prod)!;
      expect(identity.name, 'Cinderblock');
      expect(identity.binaryName, 'cinderblock');
      expect(identity.installerId, 'FD9718A0-AED3-4C67-AD70-FB4F40F11E2A');
    });

    for (final MapEntry<String, Map<String, String>> invalid in <String, Map<String, String>>{
      'windows.name': <String, String>{...prod}..remove('name'),
      'windows.binary_name': <String, String>{...prod, 'binary_name': 'cinder block'},
      'windows.installer_id': <String, String>{...prod, 'installer_id': '{FD9718A0-AED3-4C67-AD70-FB4F40F11E2A}'},
    }.entries) {
      test('names ${invalid.key} when it is missing or malformed', () {
        expect(
          () => WindowsIdentity.fromConfig(invalid.value),
          throwsA(isA<ArgumentError>().having((ArgumentError error) => error.name, 'name', invalid.key)),
        );
      });
    }

    test('refuses a name with a quote, which would end the generated strings', () {
      expect(
        () => WindowsIdentity.fromConfig(<String, String>{...prod, 'name': 'Cinder"block'}),
        throwsA(isA<ArgumentError>().having((ArgumentError error) => error.name, 'name', 'windows.name')),
      );
    });

    test('refuses a windows value that is not a map', () {
      expect(() => WindowsIdentity.fromConfig('Cinderblock'), throwsArgumentError);
    });
  });

  group('WindowsIdentity files', () {
    final WindowsIdentity identity = WindowsIdentity.fromConfig(prod)!;

    test('cmake sets the executable and app names', () {
      expect(identity.cmake, contains('set(BINARY_NAME "cinderblock")\n'));
      expect(identity.cmake, contains('set(APP_NAME "Cinderblock")\n'));
    });

    test('innoSetup defines the app name, executable and a braced AppId', () {
      expect(identity.innoSetup, contains('#define AppName "Cinderblock"\n'));
      expect(identity.innoSetup, contains('#define AppExeName "cinderblock.exe"\n'));
      expect(identity.innoSetup, contains('#define AppId "{{FD9718A0-AED3-4C67-AD70-FB4F40F11E2A}"\n'));
    });
  });
}
