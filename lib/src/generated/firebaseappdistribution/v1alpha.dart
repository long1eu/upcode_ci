// Copyright 2026 Google LLC
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd

// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: camel_case_types
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: doc_directive_unknown
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: unintended_html_in_doc_comment
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_string_interpolations

/// Firebase App Distribution API - v1alpha
///
/// For more information, see
/// <https://firebase.google.com/products/app-distribution>
///
/// Create an instance of [FirebaseAppDistributionApi] to access these
/// resources:
///
/// - [AppsResource]
///   - [AppsReleaseByHashResource]
///   - [AppsReleasesResource]
///     - [AppsReleasesNotesResource]
///   - [AppsTestersResource]
///   - [AppsUploadStatusResource]
/// - [ProjectsResource]
///   - [ProjectsAppsResource]
///     - [ProjectsAppsReleasesResource]
///       - [ProjectsAppsReleasesTestsResource]
///     - [ProjectsAppsTestCasesResource]
///   - [ProjectsTestersResource]
library;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Request headers used by all libraries in this package
final requestHeaders = {
  'user-agent': 'google-api-dart-client/v1alpha',
  'x-goog-api-client': 'gl-dart/${commons.dartVersion} gdcl/v1alpha',
};

class FirebaseAppDistributionApi {
  /// See, edit, configure, and delete your Google Cloud data and see the email
  /// address for your Google Account.
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  AppsResource get apps => AppsResource(_requester);
  ProjectsResource get projects => ProjectsResource(_requester);

  FirebaseAppDistributionApi(
    http.Client client, {
    core.String rootUrl = 'https://firebaseappdistribution.googleapis.com/',
    core.String servicePath = '',
  }) : _requester = commons.ApiRequester(
         client,
         rootUrl,
         servicePath,
         requestHeaders,
       );
}

class AppsResource {
  final commons.ApiRequester _requester;

  AppsReleaseByHashResource get releaseByHash =>
      AppsReleaseByHashResource(_requester);
  AppsReleasesResource get releases => AppsReleasesResource(_requester);
  AppsTestersResource get testers => AppsTestersResource(_requester);
  AppsUploadStatusResource get uploadStatus =>
      AppsUploadStatusResource(_requester);

  AppsResource(commons.ApiRequester client) : _requester = client;

  /// Get the app, if it exists
  ///
  /// Request parameters:
  ///
  /// [mobilesdkAppId] - Unique id for a Firebase app of the format:
  /// {version}:{project_number}:{platform}:{hash(bundle_id)} Example:
  /// 1:581234567376:android:aa0a3c7b135e90289
  ///
  /// [appView] - App view. When unset or set to BASIC, returns an App with
  /// everything set except for aab_state. When set to FULL, returns an App with
  /// aab_state set.
  /// Possible string values are:
  /// - "APP_VIEW_UNSPECIFIED" : The default / unset value. The API will default
  /// to the BASIC view.
  /// - "BASIC" : Include everything except aab_state.
  /// - "FULL" : Include everything.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaApp].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaApp> get(
    core.String mobilesdkAppId, {
    core.String? appView,
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'appView': ?appView == null ? null : [appView],
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ = 'v1alpha/apps/' + commons.escapeVariable('$mobilesdkAppId');

    final response_ = await _requester.request(
      url_,
      'GET',
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaApp.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }

  /// Get a JWT token
  ///
  /// Request parameters:
  ///
  /// [mobilesdkAppId] - Required. Unique id for a Firebase app of the format:
  /// {version}:{project_number}:{platform}:{hash(bundle_id)} Example:
  /// 1:581234567376:android:aa0a3c7b135e90289
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaJwt].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaJwt> getJwt(
    core.String mobilesdkAppId, {
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ =
        'v1alpha/apps/' + commons.escapeVariable('$mobilesdkAppId') + '/jwt';

    final response_ = await _requester.request(
      url_,
      'GET',
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaJwt.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }
}

class AppsReleaseByHashResource {
  final commons.ApiRequester _requester;

  AppsReleaseByHashResource(commons.ApiRequester client) : _requester = client;

  /// GET Release by binary upload hash
  ///
  /// Request parameters:
  ///
  /// [mobilesdkAppId] - Required. Unique id for a Firebase app of the format:
  /// {version}:{project_number}:{platform}:{hash(bundle_id)} Example:
  /// 1:581234567376:android:aa0a3c7b135e90289
  ///
  /// [uploadHash] - Required. The hash for the upload
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleFirebaseAppdistroV1alphaGetReleaseByUploadHashResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaGetReleaseByUploadHashResponse>
  get(
    core.String mobilesdkAppId,
    core.String uploadHash, {
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ =
        'v1alpha/apps/' +
        commons.escapeVariable('$mobilesdkAppId') +
        '/release_by_hash/' +
        commons.escapeVariable('$uploadHash');

    final response_ = await _requester.request(
      url_,
      'GET',
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaGetReleaseByUploadHashResponse.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }
}

class AppsReleasesResource {
  final commons.ApiRequester _requester;

  AppsReleasesNotesResource get notes => AppsReleasesNotesResource(_requester);

  AppsReleasesResource(commons.ApiRequester client) : _requester = client;

  /// Enable access on a release for testers.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [mobilesdkAppId] - Required. Unique id for a Firebase app of the format:
  /// {version}:{project_number}:{platform}:{hash(bundle_id)} Example:
  /// 1:581234567376:android:aa0a3c7b135e90289
  ///
  /// [releaseId] - Required. Release identifier
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleFirebaseAppdistroV1alphaEnableAccessOnReleaseResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaEnableAccessOnReleaseResponse>
  enableAccess(
    GoogleFirebaseAppdistroV1alphaEnableAccessOnReleaseRequest request,
    core.String mobilesdkAppId,
    core.String releaseId, {
    core.String? $fields,
  }) async {
    final body_ = convert.json.encode(request);
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ =
        'v1alpha/apps/' +
        commons.escapeVariable('$mobilesdkAppId') +
        '/releases/' +
        commons.escapeVariable('$releaseId') +
        '/enable_access';

    final response_ = await _requester.request(
      url_,
      'POST',
      body: body_,
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaEnableAccessOnReleaseResponse.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }
}

class AppsReleasesNotesResource {
  final commons.ApiRequester _requester;

  AppsReleasesNotesResource(commons.ApiRequester client) : _requester = client;

  /// Create release notes on a release.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [mobilesdkAppId] - Required. Unique id for a Firebase app of the format:
  /// {version}:{project_number}:{platform}:{hash(bundle_id)} Example:
  /// 1:581234567376:android:aa0a3c7b135e90289
  ///
  /// [releaseId] - Required. Release identifier
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleFirebaseAppdistroV1alphaCreateReleaseNotesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaCreateReleaseNotesResponse> create(
    GoogleFirebaseAppdistroV1alphaCreateReleaseNotesRequest request,
    core.String mobilesdkAppId,
    core.String releaseId, {
    core.String? $fields,
  }) async {
    final body_ = convert.json.encode(request);
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ =
        'v1alpha/apps/' +
        commons.escapeVariable('$mobilesdkAppId') +
        '/releases/' +
        commons.escapeVariable('$releaseId') +
        '/notes';

    final response_ = await _requester.request(
      url_,
      'POST',
      body: body_,
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaCreateReleaseNotesResponse.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }
}

class AppsTestersResource {
  final commons.ApiRequester _requester;

  AppsTestersResource(commons.ApiRequester client) : _requester = client;

  /// Get UDIDs of tester iOS devices in a project
  ///
  /// Request parameters:
  ///
  /// [mobilesdkAppId] - Unique id for a Firebase app of the format:
  /// {version}:{project_number}:{platform}:{hash(bundle_id)} Example:
  /// 1:581234567376:android:aa0a3c7b135e90289
  ///
  /// [project] - The name of the project, which is the parent of testers
  /// Format: `projects/{project_number}`
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaGetTesterUdidsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaGetTesterUdidsResponse>
  getTesterUdids(
    core.String mobilesdkAppId, {
    core.String? project,
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'project': ?project == null ? null : [project],
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ =
        'v1alpha/apps/' +
        commons.escapeVariable('$mobilesdkAppId') +
        '/testers:getTesterUdids';

    final response_ = await _requester.request(
      url_,
      'GET',
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaGetTesterUdidsResponse.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }
}

class AppsUploadStatusResource {
  final commons.ApiRequester _requester;

  AppsUploadStatusResource(commons.ApiRequester client) : _requester = client;

  /// GET Binary upload status by token
  ///
  /// Request parameters:
  ///
  /// [mobilesdkAppId] - Required. Unique id for a Firebase app of the format:
  /// {version}:{project_number}:{platform}:{hash(bundle_id)} Example:
  /// 1:581234567376:android:aa0a3c7b135e90289
  ///
  /// [uploadToken] - Required. The token for the upload
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaGetUploadStatusResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaGetUploadStatusResponse> get(
    core.String mobilesdkAppId,
    core.String uploadToken, {
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ =
        'v1alpha/apps/' +
        commons.escapeVariable('$mobilesdkAppId') +
        '/upload_status/' +
        commons.escapeVariable('$uploadToken');

    final response_ = await _requester.request(
      url_,
      'GET',
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaGetUploadStatusResponse.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsAppsResource get apps => ProjectsAppsResource(_requester);
  ProjectsTestersResource get testers => ProjectsTestersResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;

  /// Get information about the quota for `ReleaseTests`.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the `TestQuota` resource to retrieve.
  /// Format: `projects/{project_number}/testQuota`
  /// Value must have pattern `^projects/\[^/\]+/testQuota$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaTestQuota].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaTestQuota> getTestQuota(
    core.String name, {
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ = 'v1alpha/' + core.Uri.encodeFull('$name');

    final response_ = await _requester.request(
      url_,
      'GET',
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaTestQuota.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }
}

class ProjectsAppsResource {
  final commons.ApiRequester _requester;

  ProjectsAppsReleasesResource get releases =>
      ProjectsAppsReleasesResource(_requester);
  ProjectsAppsTestCasesResource get testCases =>
      ProjectsAppsTestCasesResource(_requester);

  ProjectsAppsResource(commons.ApiRequester client) : _requester = client;

  /// Gets configuration for automated tests.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the `TestConfig` resource to retrieve.
  /// Format: `projects/{project_number}/apps/{app}/testConfig`
  /// Value must have pattern `^projects/\[^/\]+/apps/\[^/\]+/testConfig$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaTestConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaTestConfig> getTestConfig(
    core.String name, {
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ = 'v1alpha/' + core.Uri.encodeFull('$name');

    final response_ = await _requester.request(
      url_,
      'GET',
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaTestConfig.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }

  /// Updates automated test configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Identifier. The name of the test configuration resource. Format:
  /// `projects/{project_number}/apps/{app}/testConfig`
  /// Value must have pattern `^projects/\[^/\]+/apps/\[^/\]+/testConfig$`.
  ///
  /// [updateMask] - Optional. The list of fields to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaTestConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaTestConfig> updateTestConfig(
    GoogleFirebaseAppdistroV1alphaTestConfig request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final body_ = convert.json.encode(request);
    final queryParams_ = <core.String, core.List<core.String>>{
      'updateMask': ?updateMask == null ? null : [updateMask],
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ = 'v1alpha/' + core.Uri.encodeFull('$name');

    final response_ = await _requester.request(
      url_,
      'PATCH',
      body: body_,
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaTestConfig.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }
}

class ProjectsAppsReleasesResource {
  final commons.ApiRequester _requester;

  ProjectsAppsReleasesTestsResource get tests =>
      ProjectsAppsReleasesTestsResource(_requester);

  ProjectsAppsReleasesResource(commons.ApiRequester client)
    : _requester = client;
}

class ProjectsAppsReleasesTestsResource {
  final commons.ApiRequester _requester;

  ProjectsAppsReleasesTestsResource(commons.ApiRequester client)
    : _requester = client;

  /// Abort automated test run on release.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the release test resource. Format:
  /// `projects/{project_number}/apps/{app}/releases/{release}/tests/{test}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/apps/\[^/\]+/releases/\[^/\]+/tests/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleFirebaseAppdistroV1alphaCancelReleaseTestResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaCancelReleaseTestResponse> cancel(
    core.String name, {
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ = 'v1alpha/' + core.Uri.encodeFull('$name') + ':cancel';

    final response_ = await _requester.request(
      url_,
      'GET',
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaCancelReleaseTestResponse.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }

  /// Run automated test(s) on release.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the release resource, which is the parent
  /// of the test Format:
  /// `projects/{project_number}/apps/{app}/releases/{release}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/apps/\[^/\]+/releases/\[^/\]+$`.
  ///
  /// [releaseTestId] - Optional. The ID to use for the test, which will become
  /// the final component of the test's resource name. This value should be 4-63
  /// characters, and valid characters are /a-z-/. If it is not provided one
  /// will be automatically generated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaReleaseTest].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaReleaseTest> create(
    GoogleFirebaseAppdistroV1alphaReleaseTest request,
    core.String parent, {
    core.String? releaseTestId,
    core.String? $fields,
  }) async {
    final body_ = convert.json.encode(request);
    final queryParams_ = <core.String, core.List<core.String>>{
      'releaseTestId': ?releaseTestId == null ? null : [releaseTestId],
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ = 'v1alpha/' + core.Uri.encodeFull('$parent') + '/tests';

    final response_ = await _requester.request(
      url_,
      'POST',
      body: body_,
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaReleaseTest.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }

  /// Get results for automated test run on release.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the release test resource. Format:
  /// `projects/{project_number}/apps/{app}/releases/{release}/tests/{test}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/apps/\[^/\]+/releases/\[^/\]+/tests/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaReleaseTest].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaReleaseTest> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ = 'v1alpha/' + core.Uri.encodeFull('$name');

    final response_ = await _requester.request(
      url_,
      'GET',
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaReleaseTest.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }

  /// List results for automated tests run on release.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the release resource, which is the parent
  /// of the tests Format:
  /// `projects/{project_number}/apps/{app}/releases/{release}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/apps/\[^/\]+/releases/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of tests to return. The service
  /// may return fewer than this value.
  ///
  /// [pageToken] - Optional. A page token, received from a previous
  /// `ListReleaseTests` call. Provide this to retrieve the subsequent page.
  ///
  /// [view] - Optional. The requested view on the returned ReleaseTests.
  /// Defaults to the basic view.
  /// Possible string values are:
  /// - "RELEASE_TEST_VIEW_UNSPECIFIED" : The default / unset value. The default
  /// view depends on the RPC.
  /// - "RELEASE_TEST_VIEW_BASIC" : Include basic metadata about the release
  /// test and its status, but not the full result details. This is the default
  /// value for ListReleaseTests.
  /// - "RELEASE_TEST_VIEW_FULL" : Include everything.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaListReleaseTestsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaListReleaseTestsResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? view,
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'pageSize': ?pageSize == null ? null : ['${pageSize}'],
      'pageToken': ?pageToken == null ? null : [pageToken],
      'view': ?view == null ? null : [view],
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ = 'v1alpha/' + core.Uri.encodeFull('$parent') + '/tests';

    final response_ = await _requester.request(
      url_,
      'GET',
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaListReleaseTestsResponse.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }
}

class ProjectsAppsTestCasesResource {
  final commons.ApiRequester _requester;

  ProjectsAppsTestCasesResource(commons.ApiRequester client)
    : _requester = client;

  /// Deletes multiple test cases.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource of the test cases being deleted.
  /// Format: `projects/{project_number}/apps/{app}`
  /// Value must have pattern `^projects/\[^/\]+/apps/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> batchDelete(
    GoogleFirebaseAppdistroV1alphaBatchDeleteTestCasesRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final body_ = convert.json.encode(request);
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ =
        'v1alpha/' + core.Uri.encodeFull('$parent') + '/testCases:batchDelete';

    final response_ = await _requester.request(
      url_,
      'POST',
      body: body_,
      queryParams: queryParams_,
    );
    return GoogleProtobufEmpty.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }

  /// Updates multiple test cases.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource of the test cases being updated.
  /// Format: `projects/{project_number}/apps/{app}`
  /// Value must have pattern `^projects/\[^/\]+/apps/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleFirebaseAppdistroV1alphaBatchUpdateTestCasesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaBatchUpdateTestCasesResponse>
  batchUpdate(
    GoogleFirebaseAppdistroV1alphaBatchUpdateTestCasesRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final body_ = convert.json.encode(request);
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ =
        'v1alpha/' + core.Uri.encodeFull('$parent') + '/testCases:batchUpdate';

    final response_ = await _requester.request(
      url_,
      'POST',
      body: body_,
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaBatchUpdateTestCasesResponse.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }

  /// Clears cached test runs for a specific test case and device(s).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [testCase] - Required. The name of the test case resource for which to
  /// clear the cache. Format:
  /// `projects/{project_number}/apps/{app}/testCases/{test_case}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/apps/\[^/\]+/testCases/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleFirebaseAppdistroV1alphaClearTestCaseCacheResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaClearTestCaseCacheResponse>
  clearTestCaseCache(
    GoogleFirebaseAppdistroV1alphaClearTestCaseCacheRequest request,
    core.String testCase, {
    core.String? $fields,
  }) async {
    final body_ = convert.json.encode(request);
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ =
        'v1alpha/' + core.Uri.encodeFull('$testCase') + ':clearTestCaseCache';

    final response_ = await _requester.request(
      url_,
      'POST',
      body: body_,
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaClearTestCaseCacheResponse.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }

  /// Create a new test case.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource where this test case will be
  /// created. Format: `projects/{project_number}/apps/{app}`
  /// Value must have pattern `^projects/\[^/\]+/apps/\[^/\]+$`.
  ///
  /// [testCaseId] - Optional. The ID to use for the test case, which will
  /// become the final component of the test case's resource name. This value
  /// should be 4-63 characters, and valid characters are /a-z-/.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaTestCase].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaTestCase> create(
    GoogleFirebaseAppdistroV1alphaTestCase request,
    core.String parent, {
    core.String? testCaseId,
    core.String? $fields,
  }) async {
    final body_ = convert.json.encode(request);
    final queryParams_ = <core.String, core.List<core.String>>{
      'testCaseId': ?testCaseId == null ? null : [testCaseId],
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ = 'v1alpha/' + core.Uri.encodeFull('$parent') + '/testCases';

    final response_ = await _requester.request(
      url_,
      'POST',
      body: body_,
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaTestCase.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }

  /// Delete a test case.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the test case resource to delete. Format:
  /// `projects/{project_number}/apps/{app}/testCases/{test_case}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/apps/\[^/\]+/testCases/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ = 'v1alpha/' + core.Uri.encodeFull('$name');

    final response_ = await _requester.request(
      url_,
      'DELETE',
      queryParams: queryParams_,
    );
    return GoogleProtobufEmpty.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }

  /// Get a test case.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the test case resource to retrieve. Format:
  /// `projects/{project_number}/apps/{app}/testCases/{test_case}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/apps/\[^/\]+/testCases/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaTestCase].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaTestCase> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ = 'v1alpha/' + core.Uri.encodeFull('$name');

    final response_ = await _requester.request(
      url_,
      'GET',
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaTestCase.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }

  /// List test cases.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource from which to list test cases.
  /// Format: `projects/{project_number}/apps/{app}`
  /// Value must have pattern `^projects/\[^/\]+/apps/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of test cases to return. The
  /// service may return fewer than this value. If unspecified, at most 50 test
  /// cases will be returned. The maximum value is 1000; values above 1000 will
  /// be coerced to 1000.
  ///
  /// [pageToken] - Optional. A page token, received from a previous
  /// `ListTestCases` call. Provide this to retrieve the subsequent page. When
  /// paginating, all other parameters provided to `ListTestCases` must match
  /// the call that provided the page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaListTestCasesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaListTestCasesResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'pageSize': ?pageSize == null ? null : ['${pageSize}'],
      'pageToken': ?pageToken == null ? null : [pageToken],
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ = 'v1alpha/' + core.Uri.encodeFull('$parent') + '/testCases';

    final response_ = await _requester.request(
      url_,
      'GET',
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaListTestCasesResponse.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }

  /// Update a test case.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Identifier. The name of the test case resource. Format:
  /// `projects/{project_number}/apps/{app}/testCases/{test_case}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/apps/\[^/\]+/testCases/\[^/\]+$`.
  ///
  /// [allowMissing] - Optional. If set to true, and the test case is not found,
  /// a new test case will be created.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaTestCase].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaTestCase> patch(
    GoogleFirebaseAppdistroV1alphaTestCase request,
    core.String name, {
    core.bool? allowMissing,
    core.String? $fields,
  }) async {
    final body_ = convert.json.encode(request);
    final queryParams_ = <core.String, core.List<core.String>>{
      'allowMissing': ?allowMissing == null ? null : ['${allowMissing}'],
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ = 'v1alpha/' + core.Uri.encodeFull('$name');

    final response_ = await _requester.request(
      url_,
      'PATCH',
      body: body_,
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaTestCase.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }
}

class ProjectsTestersResource {
  final commons.ApiRequester _requester;

  ProjectsTestersResource(commons.ApiRequester client) : _requester = client;

  /// Get UDIDs of tester iOS devices in a project
  ///
  /// Request parameters:
  ///
  /// [project] - The name of the project, which is the parent of testers
  /// Format: `projects/{project_number}`
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [mobilesdkAppId] - Unique id for a Firebase app of the format:
  /// {version}:{project_number}:{platform}:{hash(bundle_id)} Example:
  /// 1:581234567376:android:aa0a3c7b135e90289
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleFirebaseAppdistroV1alphaGetTesterUdidsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleFirebaseAppdistroV1alphaGetTesterUdidsResponse> getUdids(
    core.String project, {
    core.String? mobilesdkAppId,
    core.String? $fields,
  }) async {
    final queryParams_ = <core.String, core.List<core.String>>{
      'mobilesdkAppId': ?mobilesdkAppId == null ? null : [mobilesdkAppId],
      'fields': ?$fields == null ? null : [$fields],
    };

    final url_ =
        'v1alpha/' + core.Uri.encodeFull('$project') + '/testers:udids';

    final response_ = await _requester.request(
      url_,
      'GET',
      queryParams: queryParams_,
    );
    return GoogleFirebaseAppdistroV1alphaGetTesterUdidsResponse.fromJson(
      response_ as core.Map<core.String, core.dynamic>,
    );
  }
}

/// Point for describing bounding boxes tap locations Top left is 0,0
class AndroidxCrawlerOutputPoint {
  core.int? xCoordinate;
  core.int? yCoordinate;

  AndroidxCrawlerOutputPoint({this.xCoordinate, this.yCoordinate});

  AndroidxCrawlerOutputPoint.fromJson(core.Map json_)
    : this(
        xCoordinate: json_['xCoordinate'] as core.int?,
        yCoordinate: json_['yCoordinate'] as core.int?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final xCoordinate = this.xCoordinate;
    final yCoordinate = this.yCoordinate;
    return {'xCoordinate': ?xCoordinate, 'yCoordinate': ?yCoordinate};
  }
}

/// Rectangle for describing bounding boxes
class AndroidxCrawlerOutputRectangle {
  core.int? bottom;
  core.int? left;
  core.int? right;
  core.int? top;

  AndroidxCrawlerOutputRectangle({
    this.bottom,
    this.left,
    this.right,
    this.top,
  });

  AndroidxCrawlerOutputRectangle.fromJson(core.Map json_)
    : this(
        bottom: json_['bottom'] as core.int?,
        left: json_['left'] as core.int?,
        right: json_['right'] as core.int?,
        top: json_['top'] as core.int?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final bottom = this.bottom;
    final left = this.left;
    final right = this.right;
    final top = this.top;
    return {'bottom': ?bottom, 'left': ?left, 'right': ?right, 'top': ?top};
  }
}

/// App bundle test certificate
class GoogleFirebaseAppdistroV1alphaAabCertificate {
  /// MD5 hash of the certificate used to resign the AAB
  core.String? certificateHashMd5;

  /// SHA1 hash of the certificate used to resign the AAB
  core.String? certificateHashSha1;

  /// SHA256 hash of the certificate used to resign the AAB
  core.String? certificateHashSha256;

  GoogleFirebaseAppdistroV1alphaAabCertificate({
    this.certificateHashMd5,
    this.certificateHashSha1,
    this.certificateHashSha256,
  });

  GoogleFirebaseAppdistroV1alphaAabCertificate.fromJson(core.Map json_)
    : this(
        certificateHashMd5: json_['certificateHashMd5'] as core.String?,
        certificateHashSha1: json_['certificateHashSha1'] as core.String?,
        certificateHashSha256: json_['certificateHashSha256'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final certificateHashMd5 = this.certificateHashMd5;
    final certificateHashSha1 = this.certificateHashSha1;
    final certificateHashSha256 = this.certificateHashSha256;
    return {
      'certificateHashMd5': ?certificateHashMd5,
      'certificateHashSha1': ?certificateHashSha1,
      'certificateHashSha256': ?certificateHashSha256,
    };
  }
}

class GoogleFirebaseAppdistroV1alphaAiInstructions {
  /// Steps to be accomplished by the AI
  ///
  /// Required.
  core.List<GoogleFirebaseAppdistroV1alphaAiStep>? steps;

  GoogleFirebaseAppdistroV1alphaAiInstructions({this.steps});

  GoogleFirebaseAppdistroV1alphaAiInstructions.fromJson(core.Map json_)
    : this(
        steps: (json_['steps'] as core.List?)
            ?.map(
              (value) => GoogleFirebaseAppdistroV1alphaAiStep.fromJson(
                value as core.Map<core.String, core.dynamic>,
              ),
            )
            .toList(),
      );

  core.Map<core.String, core.dynamic> toJson() {
    final steps = this.steps;
    return {'steps': ?steps};
  }
}

/// A step to be accomplished by the AI
class GoogleFirebaseAppdistroV1alphaAiStep {
  /// An assertion to be checked by the AI
  core.String? assertion;

  /// A goal to be accomplished by the AI
  core.String? goal;

  /// Hint text containing suggestions to help the agent accomplish the goal
  ///
  /// Optional.
  core.String? hint;

  /// A visual description of the screen's expected state after the step has
  /// been successfully completed.
  ///
  /// This is referred to as the "final screen assertion" in the Firebase
  /// console and CLI tools. This field must be provided for the last step in a
  /// test case, and is optional for all other steps.
  ///
  /// Optional.
  core.String? successCriteria;

  /// The test case that contained this step.
  ///
  /// Note: The test case may have changed or been deleted since this step was
  /// created. Format:
  /// `projects/{project_number}/apps/{app}/testCases/{test_case}`
  ///
  /// Output only.
  core.String? testCase;

  GoogleFirebaseAppdistroV1alphaAiStep({
    this.assertion,
    this.goal,
    this.hint,
    this.successCriteria,
    this.testCase,
  });

  GoogleFirebaseAppdistroV1alphaAiStep.fromJson(core.Map json_)
    : this(
        assertion: json_['assertion'] as core.String?,
        goal: json_['goal'] as core.String?,
        hint: json_['hint'] as core.String?,
        successCriteria: json_['successCriteria'] as core.String?,
        testCase: json_['testCase'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final assertion = this.assertion;
    final goal = this.goal;
    final hint = this.hint;
    final successCriteria = this.successCriteria;
    final testCase = this.testCase;
    return {
      'assertion': ?assertion,
      'goal': ?goal,
      'hint': ?hint,
      'successCriteria': ?successCriteria,
      'testCase': ?testCase,
    };
  }
}

/// Captures the results of an AiStep
class GoogleFirebaseAppdistroV1alphaAiStepResult {
  /// Details for an assertion step.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaAssertionDetails? assertionDetails;

  /// Details for a goal step.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaGoalDetails? goalDetails;

  /// The current state of the step
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STEP_STATE_UNSPECIFIED" : Step state unspecified
  /// - "IN_PROGRESS" : The step is in progress
  /// - "PASSED" : The step has completed successfully
  /// - "FAILED" : The step has failed
  /// - "TIMED_OUT" : The test timed out during this step
  /// - "GOAL_ACTION_LIMIT_REACHED" : The number of actions needed to reach the
  /// goal exceeded its limit
  core.String? state;

  /// The step performed by the AI
  ///
  /// Required.
  GoogleFirebaseAppdistroV1alphaAiStep? step;

  GoogleFirebaseAppdistroV1alphaAiStepResult({
    this.assertionDetails,
    this.goalDetails,
    this.state,
    this.step,
  });

  GoogleFirebaseAppdistroV1alphaAiStepResult.fromJson(core.Map json_)
    : this(
        assertionDetails: json_.containsKey('assertionDetails')
            ? GoogleFirebaseAppdistroV1alphaAssertionDetails.fromJson(
                json_['assertionDetails']
                    as core.Map<core.String, core.dynamic>,
              )
            : null,
        goalDetails: json_.containsKey('goalDetails')
            ? GoogleFirebaseAppdistroV1alphaGoalDetails.fromJson(
                json_['goalDetails'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        state: json_['state'] as core.String?,
        step: json_.containsKey('step')
            ? GoogleFirebaseAppdistroV1alphaAiStep.fromJson(
                json_['step'] as core.Map<core.String, core.dynamic>,
              )
            : null,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final assertionDetails = this.assertionDetails;
    final goalDetails = this.goalDetails;
    final state = this.state;
    final step = this.step;
    return {
      'assertionDetails': ?assertionDetails,
      'goalDetails': ?goalDetails,
      'state': ?state,
      'step': ?step,
    };
  }
}

/// An app.
class GoogleFirebaseAppdistroV1alphaApp {
  /// App bundle test certificate generated for the app.
  GoogleFirebaseAppdistroV1alphaAabCertificate? aabCertificate;

  /// App bundle state.
  ///
  /// Only valid for android apps. The app_view field in the request must be set
  /// to FULL in order for this to be populated.
  /// Possible string values are:
  /// - "AAB_STATE_UNSPECIFIED" : Aab state unspecified
  /// - "ACTIVE" : App can receive app bundle uploads
  /// - "PLAY_ACCOUNT_NOT_LINKED" : Firebase project is not linked to a Play
  /// developer account
  /// - "NO_APP_WITH_GIVEN_BUNDLE_ID_IN_PLAY_ACCOUNT" : There is no app in
  /// linked Play developer account with the same bundle id
  /// - "APP_NOT_PUBLISHED" : The app in Play developer account is not in a
  /// published state
  /// - "AAB_STATE_UNAVAILABLE" : Play App status is unavailable
  /// - "PLAY_IAS_TERMS_NOT_ACCEPTED" : Play IAS terms not accepted
  core.String? aabState;

  /// Firebase gmp app id
  core.String? appId;

  /// Bundle identifier
  core.String? bundleId;

  /// Developer contact email for testers to reach out to about privacy or
  /// support issues.
  core.String? contactEmail;

  /// iOS or Android
  core.String? platform;

  /// Project number of the Firebase project, for example 300830567303.
  core.String? projectNumber;

  GoogleFirebaseAppdistroV1alphaApp({
    this.aabCertificate,
    this.aabState,
    this.appId,
    this.bundleId,
    this.contactEmail,
    this.platform,
    this.projectNumber,
  });

  GoogleFirebaseAppdistroV1alphaApp.fromJson(core.Map json_)
    : this(
        aabCertificate: json_.containsKey('aabCertificate')
            ? GoogleFirebaseAppdistroV1alphaAabCertificate.fromJson(
                json_['aabCertificate'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        aabState: json_['aabState'] as core.String?,
        appId: json_['appId'] as core.String?,
        bundleId: json_['bundleId'] as core.String?,
        contactEmail: json_['contactEmail'] as core.String?,
        platform: json_['platform'] as core.String?,
        projectNumber: json_['projectNumber'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final aabCertificate = this.aabCertificate;
    final aabState = this.aabState;
    final appId = this.appId;
    final bundleId = this.bundleId;
    final contactEmail = this.contactEmail;
    final platform = this.platform;
    final projectNumber = this.projectNumber;
    return {
      'aabCertificate': ?aabCertificate,
      'aabState': ?aabState,
      'appId': ?appId,
      'bundleId': ?bundleId,
      'contactEmail': ?contactEmail,
      'platform': ?platform,
      'projectNumber': ?projectNumber,
    };
  }
}

/// An app crash that occurred during an automated test.
class GoogleFirebaseAppdistroV1alphaAppCrash {
  /// The message associated with the crash.
  ///
  /// Output only.
  core.String? message;

  /// The raw stack trace.
  ///
  /// Output only.
  core.String? stackTrace;

  GoogleFirebaseAppdistroV1alphaAppCrash({this.message, this.stackTrace});

  GoogleFirebaseAppdistroV1alphaAppCrash.fromJson(core.Map json_)
    : this(
        message: json_['message'] as core.String?,
        stackTrace: json_['stackTrace'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final message = this.message;
    final stackTrace = this.stackTrace;
    return {'message': ?message, 'stackTrace': ?stackTrace};
  }
}

/// Details for an assertion step.
class GoogleFirebaseAppdistroV1alphaAssertionDetails {
  /// An explanation justifying the assertion result.
  ///
  /// Output only.
  core.String? explanation;

  /// The result of the assertion.
  ///
  /// Output only.
  core.bool? result;

  /// The screenshot used in the context of this assertion.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaScreenshot? screenshot;

  GoogleFirebaseAppdistroV1alphaAssertionDetails({
    this.explanation,
    this.result,
    this.screenshot,
  });

  GoogleFirebaseAppdistroV1alphaAssertionDetails.fromJson(core.Map json_)
    : this(
        explanation: json_['explanation'] as core.String?,
        result: json_['result'] as core.bool?,
        screenshot: json_.containsKey('screenshot')
            ? GoogleFirebaseAppdistroV1alphaScreenshot.fromJson(
                json_['screenshot'] as core.Map<core.String, core.dynamic>,
              )
            : null,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final explanation = this.explanation;
    final result = this.result;
    final screenshot = this.screenshot;
    return {
      'explanation': ?explanation,
      'result': ?result,
      'screenshot': ?screenshot,
    };
  }
}

/// The request message for `BatchDeleteTestCase`.
class GoogleFirebaseAppdistroV1alphaBatchDeleteTestCasesRequest {
  /// The name of the test cases to delete.
  ///
  /// A maximum number of 1000 test cases can be deleted in one batch Format:
  /// `projects/{project_number}/apps/{app}/testCases/{test_case}`
  ///
  /// Required.
  core.List<core.String>? names;

  GoogleFirebaseAppdistroV1alphaBatchDeleteTestCasesRequest({this.names});

  GoogleFirebaseAppdistroV1alphaBatchDeleteTestCasesRequest.fromJson(
    core.Map json_,
  ) : this(
        names: (json_['names'] as core.List?)
            ?.map((value) => value as core.String)
            .toList(),
      );

  core.Map<core.String, core.dynamic> toJson() {
    final names = this.names;
    return {'names': ?names};
  }
}

/// The request message for `BatchUpdateTestCase`.
class GoogleFirebaseAppdistroV1alphaBatchUpdateTestCasesRequest {
  /// The update requests.
  ///
  /// A maximum number of 1000 test cases can be updated in one batch
  ///
  /// Required.
  core.List<GoogleFirebaseAppdistroV1alphaUpdateTestCaseRequest>? requests;

  GoogleFirebaseAppdistroV1alphaBatchUpdateTestCasesRequest({this.requests});

  GoogleFirebaseAppdistroV1alphaBatchUpdateTestCasesRequest.fromJson(
    core.Map json_,
  ) : this(
        requests: (json_['requests'] as core.List?)
            ?.map(
              (value) =>
                  GoogleFirebaseAppdistroV1alphaUpdateTestCaseRequest.fromJson(
                    value as core.Map<core.String, core.dynamic>,
                  ),
            )
            .toList(),
      );

  core.Map<core.String, core.dynamic> toJson() {
    final requests = this.requests;
    return {'requests': ?requests};
  }
}

/// The response message for `BatchUpdateTestCase`.
class GoogleFirebaseAppdistroV1alphaBatchUpdateTestCasesResponse {
  /// The updated test cases.
  core.List<GoogleFirebaseAppdistroV1alphaTestCase>? testCases;

  GoogleFirebaseAppdistroV1alphaBatchUpdateTestCasesResponse({this.testCases});

  GoogleFirebaseAppdistroV1alphaBatchUpdateTestCasesResponse.fromJson(
    core.Map json_,
  ) : this(
        testCases: (json_['testCases'] as core.List?)
            ?.map(
              (value) => GoogleFirebaseAppdistroV1alphaTestCase.fromJson(
                value as core.Map<core.String, core.dynamic>,
              ),
            )
            .toList(),
      );

  core.Map<core.String, core.dynamic> toJson() {
    final testCases = this.testCases;
    return {'testCases': ?testCases};
  }
}

/// The (empty) response message for `CancelReleaseTest`.
class GoogleFirebaseAppdistroV1alphaCancelReleaseTestResponse {
  GoogleFirebaseAppdistroV1alphaCancelReleaseTestResponse();

  GoogleFirebaseAppdistroV1alphaCancelReleaseTestResponse.fromJson(
    // ignore: avoid_unused_constructor_parameters
    core.Map json_,
  );

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Request message for `ClearTestCaseCache`.
class GoogleFirebaseAppdistroV1alphaClearTestCaseCacheRequest {
  /// The list of devices for which to clear the cache.
  ///
  /// If not present, clear all of them.
  ///
  /// Optional.
  core.List<GoogleFirebaseAppdistroV1alphaTestDevice>? testDevices;

  GoogleFirebaseAppdistroV1alphaClearTestCaseCacheRequest({this.testDevices});

  GoogleFirebaseAppdistroV1alphaClearTestCaseCacheRequest.fromJson(
    core.Map json_,
  ) : this(
        testDevices: (json_['testDevices'] as core.List?)
            ?.map(
              (value) => GoogleFirebaseAppdistroV1alphaTestDevice.fromJson(
                value as core.Map<core.String, core.dynamic>,
              ),
            )
            .toList(),
      );

  core.Map<core.String, core.dynamic> toJson() {
    final testDevices = this.testDevices;
    return {'testDevices': ?testDevices};
  }
}

/// Response empty (google.protobuf.Empty) message for `ClearTestCaseCache`
class GoogleFirebaseAppdistroV1alphaClearTestCaseCacheResponse {
  GoogleFirebaseAppdistroV1alphaClearTestCaseCacheResponse();

  GoogleFirebaseAppdistroV1alphaClearTestCaseCacheResponse.fromJson(
    // ignore: avoid_unused_constructor_parameters
    core.Map json_,
  );

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The request message for `CreateReleaseNotes`.
class GoogleFirebaseAppdistroV1alphaCreateReleaseNotesRequest {
  /// The actual release notes body from the user
  GoogleFirebaseAppdistroV1alphaReleaseNotes? releaseNotes;

  GoogleFirebaseAppdistroV1alphaCreateReleaseNotesRequest({this.releaseNotes});

  GoogleFirebaseAppdistroV1alphaCreateReleaseNotesRequest.fromJson(
    core.Map json_,
  ) : this(
        releaseNotes: json_.containsKey('releaseNotes')
            ? GoogleFirebaseAppdistroV1alphaReleaseNotes.fromJson(
                json_['releaseNotes'] as core.Map<core.String, core.dynamic>,
              )
            : null,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final releaseNotes = this.releaseNotes;
    return {'releaseNotes': ?releaseNotes};
  }
}

/// The response message for `CreateReleaseNotes`.
class GoogleFirebaseAppdistroV1alphaCreateReleaseNotesResponse {
  GoogleFirebaseAppdistroV1alphaCreateReleaseNotesResponse();

  GoogleFirebaseAppdistroV1alphaCreateReleaseNotesResponse.fromJson(
    // ignore: avoid_unused_constructor_parameters
    core.Map json_,
  );

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A high level action taken by the AI on the device, potentially involving
/// multiple taps, text entries, waits, etc.
class GoogleFirebaseAppdistroV1alphaDeviceAction {
  /// A short description of the high level action taken by the AI agent.
  ///
  /// Output only.
  core.String? description;

  /// The interactions made with the device as part of this higher level action
  /// taken by the agent, such as taps, text entries, waits, etc.
  ///
  /// Output only.
  core.List<GoogleFirebaseAppdistroV1alphaDeviceInteraction>?
  deviceInteractions;

  GoogleFirebaseAppdistroV1alphaDeviceAction({
    this.description,
    this.deviceInteractions,
  });

  GoogleFirebaseAppdistroV1alphaDeviceAction.fromJson(core.Map json_)
    : this(
        description: json_['description'] as core.String?,
        deviceInteractions: (json_['deviceInteractions'] as core.List?)
            ?.map(
              (value) =>
                  GoogleFirebaseAppdistroV1alphaDeviceInteraction.fromJson(
                    value as core.Map<core.String, core.dynamic>,
                  ),
            )
            .toList(),
      );

  core.Map<core.String, core.dynamic> toJson() {
    final description = this.description;
    final deviceInteractions = this.deviceInteractions;
    return {
      'description': ?description,
      'deviceInteractions': ?deviceInteractions,
    };
  }
}

/// The results of running an automated test on a particular device.
class GoogleFirebaseAppdistroV1alphaDeviceExecution {
  /// Results of the AI steps if passed in
  ///
  /// Output only.
  core.List<GoogleFirebaseAppdistroV1alphaAiStepResult>? aiStepResults;

  /// An app crash, if any occurred during the test.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaAppCrash? appCrash;

  /// A URI to an image of the Robo crawl graph.
  ///
  /// Output only.
  core.String? crawlGraphUri;

  /// The device that the test was run on.
  ///
  /// Required.
  GoogleFirebaseAppdistroV1alphaTestDevice? device;

  /// The type of execution for the test.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "EXECUTION_TYPE_UNSPECIFIED" : Execution type unspecified.
  /// - "AI" : An AI-driven test.
  /// - "ACTION_BASED_REPLAY" : A replay of a previous test run.
  /// - "AI_REPLAY" : A failed replay that was rerun using the AI agent.
  /// - "RANDOM_CRAWL" : A random Robo test.
  core.String? executionType;

  /// The reason why the test failed.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "FAILED_REASON_UNSPECIFIED" : Reason unspecified.
  /// - "CRASHED" : The app crashed during the test.
  /// - "NOT_INSTALLED" : If an app is not installed and thus no test can be run
  /// with the app. This might be caused by trying to run a test on an
  /// unsupported platform.
  /// - "UNABLE_TO_CRAWL" : If the app could not be crawled (possibly because
  /// the app did not start).
  /// - "DEVICE_OUT_OF_MEMORY" : If the device ran out of memory during the
  /// test.
  /// - "FAILED_AI_STEP" : At least one AI step failed.
  /// - "TIMED_OUT" : The crawl reached the time limit before the test could be
  /// completed.
  core.String? failedReason;

  /// Indicates that the test replayed saved actions and concluded without a
  /// final AI assertion.
  ///
  /// Output only.
  core.bool? finalAiAssertionMissing;

  /// The reason why the test was inconclusive.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "INCONCLUSIVE_REASON_UNSPECIFIED" : Reason unspecified.
  /// - "QUOTA_EXCEEDED" : Not enough quota remained to run the test.
  /// - "INFRASTRUCTURE_FAILURE" : The outcome of the test could not be
  /// determined because of a failure in the test running infrastructure.
  /// - "SERVICE_NOT_ACTIVATED" : A required cloud service api is not activated
  /// (Google Cloud Testing API or Cloud Tool Results API).
  /// - "NO_SIGNATURE" : The app was not signed.
  /// - "NO_LAUNCHER_ACTIVITY" : A main launcher activity could not be found.
  /// - "FORBIDDEN_PERMISSIONS" : The app declares one or more permissions that
  /// are not allowed.
  /// - "DEVICE_ADMIN_RECEIVER" : Device administrator applications are not
  /// allowed.
  /// - "NO_CODE_APK" : APK contains no code. See also
  /// https://developer.android.com/guide/topics/manifest/application-element.html#code
  /// - "INVALID_APK_PREVIEW_SDK" : APK is built for a preview SDK which is
  /// unsupported.
  core.String? inconclusiveReason;

  /// Identifier.
  ///
  /// The name of the device execution resource. Format:
  /// `projects/{project_number}/apps/{app}/releases/{release}/tests/{test}/deviceExecutions/{device_execution}`
  core.String? name;

  /// The device execution from which cached steps were used during this
  /// execution.
  ///
  /// Note: This field is only populated for ACTION_BASED_REPLAY executions. If
  /// the original device execution no longer exists, this field will be empty.
  /// Format:
  /// `projects/{project_number}/apps/{app}/releases/{release}/tests/{test}/deviceExecutions/{device_execution}`
  ///
  /// Output only.
  core.String? originDeviceExecution;

  /// The path to a directory in Cloud Storage that will eventually contain the
  /// results for this execution.
  ///
  /// For example, gs://bucket/Nexus5-18-en-portrait.
  ///
  /// Output only.
  core.String? resultsStoragePath;

  /// The statistics collected during the Robo test.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaRoboStats? roboStats;

  /// A list of screenshot image URIs taken from the Robo crawl.
  ///
  /// The file names are numbered by the order in which they were taken.
  ///
  /// Output only.
  core.List<core.String>? screenshotUris;

  /// The state of the test.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "TEST_STATE_UNSPECIFIED" : Test state unspecified.
  /// - "IN_PROGRESS" : The test is in progress.
  /// - "PASSED" : The test has passed.
  /// - "FAILED" : The test has failed.
  /// - "INCONCLUSIVE" : The test was inconclusive.
  core.String? state;

  /// The time at which the video started recording.
  ///
  /// Output only.
  core.String? videoStartTime;

  /// A URI to a video of the test run.
  ///
  /// Output only.
  core.String? videoUri;

  GoogleFirebaseAppdistroV1alphaDeviceExecution({
    this.aiStepResults,
    this.appCrash,
    this.crawlGraphUri,
    this.device,
    this.executionType,
    this.failedReason,
    this.finalAiAssertionMissing,
    this.inconclusiveReason,
    this.name,
    this.originDeviceExecution,
    this.resultsStoragePath,
    this.roboStats,
    this.screenshotUris,
    this.state,
    this.videoStartTime,
    this.videoUri,
  });

  GoogleFirebaseAppdistroV1alphaDeviceExecution.fromJson(core.Map json_)
    : this(
        aiStepResults: (json_['aiStepResults'] as core.List?)
            ?.map(
              (value) => GoogleFirebaseAppdistroV1alphaAiStepResult.fromJson(
                value as core.Map<core.String, core.dynamic>,
              ),
            )
            .toList(),
        appCrash: json_.containsKey('appCrash')
            ? GoogleFirebaseAppdistroV1alphaAppCrash.fromJson(
                json_['appCrash'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        crawlGraphUri: json_['crawlGraphUri'] as core.String?,
        device: json_.containsKey('device')
            ? GoogleFirebaseAppdistroV1alphaTestDevice.fromJson(
                json_['device'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        executionType: json_['executionType'] as core.String?,
        failedReason: json_['failedReason'] as core.String?,
        finalAiAssertionMissing: json_['finalAiAssertionMissing'] as core.bool?,
        inconclusiveReason: json_['inconclusiveReason'] as core.String?,
        name: json_['name'] as core.String?,
        originDeviceExecution: json_['originDeviceExecution'] as core.String?,
        resultsStoragePath: json_['resultsStoragePath'] as core.String?,
        roboStats: json_.containsKey('roboStats')
            ? GoogleFirebaseAppdistroV1alphaRoboStats.fromJson(
                json_['roboStats'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        screenshotUris: (json_['screenshotUris'] as core.List?)
            ?.map((value) => value as core.String)
            .toList(),
        state: json_['state'] as core.String?,
        videoStartTime: json_['videoStartTime'] as core.String?,
        videoUri: json_['videoUri'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final aiStepResults = this.aiStepResults;
    final appCrash = this.appCrash;
    final crawlGraphUri = this.crawlGraphUri;
    final device = this.device;
    final executionType = this.executionType;
    final failedReason = this.failedReason;
    final finalAiAssertionMissing = this.finalAiAssertionMissing;
    final inconclusiveReason = this.inconclusiveReason;
    final name = this.name;
    final originDeviceExecution = this.originDeviceExecution;
    final resultsStoragePath = this.resultsStoragePath;
    final roboStats = this.roboStats;
    final screenshotUris = this.screenshotUris;
    final state = this.state;
    final videoStartTime = this.videoStartTime;
    final videoUri = this.videoUri;
    return {
      'aiStepResults': ?aiStepResults,
      'appCrash': ?appCrash,
      'crawlGraphUri': ?crawlGraphUri,
      'device': ?device,
      'executionType': ?executionType,
      'failedReason': ?failedReason,
      'finalAiAssertionMissing': ?finalAiAssertionMissing,
      'inconclusiveReason': ?inconclusiveReason,
      'name': ?name,
      'originDeviceExecution': ?originDeviceExecution,
      'resultsStoragePath': ?resultsStoragePath,
      'roboStats': ?roboStats,
      'screenshotUris': ?screenshotUris,
      'state': ?state,
      'videoStartTime': ?videoStartTime,
      'videoUri': ?videoUri,
    };
  }
}

/// An interaction with the device, such as a tap, text entry, wait, etc.
class GoogleFirebaseAppdistroV1alphaDeviceInteraction {
  /// A back action.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaDeviceInteractionBack? backAction;

  /// A drag and drop action.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaDeviceInteractionDragAndDrop? dragAndDrop;

  /// A text entry action, that enters text into a particular text field,
  /// clearing any existing text in the field.
  ///
  /// Unlike `text_input` this action does not require any other actions such as
  /// a tap to be performed before it can enter the text.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaDeviceInteractionEnterText? enterText;

  /// Key code for a key event action.
  ///
  /// Output only.
  core.String? keyCode;

  /// A long press (tap and hold) action.
  ///
  /// Output only.
  AndroidxCrawlerOutputPoint? longPress;

  /// The screenshot used in the context of this action.
  ///
  /// The screen may have changed before the action was actually taken.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaScreenshot? screenshot;

  /// A swipe action.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaDeviceInteractionSwipe? swipe;

  /// A tap action.
  ///
  /// Output only.
  AndroidxCrawlerOutputPoint? tap;

  /// The target folded state of the device in a set folded state action.
  ///
  /// The valid string values are device-dependent, and can be found using `adb
  /// shell cmd device_state print-states`.
  ///
  /// Output only.
  core.String? targetFoldedState;

  /// The target orientation of the device in a set orientation action.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ORIENTATION_UNSPECIFIED" : Orientation unspecified.
  /// - "PORTRAIT" : Portrait orientation.
  /// - "LANDSCAPE" : Landscape orientation.
  core.String? targetOrientation;

  /// A text input action, that types some text into whatever field is currently
  /// focused, if any.
  ///
  /// Unlike `enter_text` this action requires that the field be brought into
  /// focus first, for example by emitting a tap action before this one.
  ///
  /// Output only.
  core.String? textInput;

  /// A wait action.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaDeviceInteractionWait? wait;

  GoogleFirebaseAppdistroV1alphaDeviceInteraction({
    this.backAction,
    this.dragAndDrop,
    this.enterText,
    this.keyCode,
    this.longPress,
    this.screenshot,
    this.swipe,
    this.tap,
    this.targetFoldedState,
    this.targetOrientation,
    this.textInput,
    this.wait,
  });

  GoogleFirebaseAppdistroV1alphaDeviceInteraction.fromJson(core.Map json_)
    : this(
        backAction: json_.containsKey('backAction')
            ? GoogleFirebaseAppdistroV1alphaDeviceInteractionBack.fromJson(
                json_['backAction'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        dragAndDrop: json_.containsKey('dragAndDrop')
            ? GoogleFirebaseAppdistroV1alphaDeviceInteractionDragAndDrop.fromJson(
                json_['dragAndDrop'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        enterText: json_.containsKey('enterText')
            ? GoogleFirebaseAppdistroV1alphaDeviceInteractionEnterText.fromJson(
                json_['enterText'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        keyCode: json_['keyCode'] as core.String?,
        longPress: json_.containsKey('longPress')
            ? AndroidxCrawlerOutputPoint.fromJson(
                json_['longPress'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        screenshot: json_.containsKey('screenshot')
            ? GoogleFirebaseAppdistroV1alphaScreenshot.fromJson(
                json_['screenshot'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        swipe: json_.containsKey('swipe')
            ? GoogleFirebaseAppdistroV1alphaDeviceInteractionSwipe.fromJson(
                json_['swipe'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        tap: json_.containsKey('tap')
            ? AndroidxCrawlerOutputPoint.fromJson(
                json_['tap'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        targetFoldedState: json_['targetFoldedState'] as core.String?,
        targetOrientation: json_['targetOrientation'] as core.String?,
        textInput: json_['textInput'] as core.String?,
        wait: json_.containsKey('wait')
            ? GoogleFirebaseAppdistroV1alphaDeviceInteractionWait.fromJson(
                json_['wait'] as core.Map<core.String, core.dynamic>,
              )
            : null,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final backAction = this.backAction;
    final dragAndDrop = this.dragAndDrop;
    final enterText = this.enterText;
    final keyCode = this.keyCode;
    final longPress = this.longPress;
    final screenshot = this.screenshot;
    final swipe = this.swipe;
    final tap = this.tap;
    final targetFoldedState = this.targetFoldedState;
    final targetOrientation = this.targetOrientation;
    final textInput = this.textInput;
    final wait = this.wait;
    return {
      'backAction': ?backAction,
      'dragAndDrop': ?dragAndDrop,
      'enterText': ?enterText,
      'keyCode': ?keyCode,
      'longPress': ?longPress,
      'screenshot': ?screenshot,
      'swipe': ?swipe,
      'tap': ?tap,
      'targetFoldedState': ?targetFoldedState,
      'targetOrientation': ?targetOrientation,
      'textInput': ?textInput,
      'wait': ?wait,
    };
  }
}

/// A back action.
class GoogleFirebaseAppdistroV1alphaDeviceInteractionBack {
  GoogleFirebaseAppdistroV1alphaDeviceInteractionBack();

  GoogleFirebaseAppdistroV1alphaDeviceInteractionBack.fromJson(
    // ignore: avoid_unused_constructor_parameters
    core.Map json_,
  );

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A drag and drop action.
class GoogleFirebaseAppdistroV1alphaDeviceInteractionDragAndDrop {
  /// The end point of the drag and drop.
  ///
  /// Output only.
  AndroidxCrawlerOutputPoint? end;

  /// The start point of the drag and drop.
  ///
  /// Output only.
  AndroidxCrawlerOutputPoint? start;

  GoogleFirebaseAppdistroV1alphaDeviceInteractionDragAndDrop({
    this.end,
    this.start,
  });

  GoogleFirebaseAppdistroV1alphaDeviceInteractionDragAndDrop.fromJson(
    core.Map json_,
  ) : this(
        end: json_.containsKey('end')
            ? AndroidxCrawlerOutputPoint.fromJson(
                json_['end'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        start: json_.containsKey('start')
            ? AndroidxCrawlerOutputPoint.fromJson(
                json_['start'] as core.Map<core.String, core.dynamic>,
              )
            : null,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final end = this.end;
    final start = this.start;
    return {'end': ?end, 'start': ?start};
  }
}

/// A text entry action, that enters text into a particular text field, clearing
/// any existing text in the field.
class GoogleFirebaseAppdistroV1alphaDeviceInteractionEnterText {
  /// The visible bounds of the element to enter text into.
  ///
  /// Output only.
  AndroidxCrawlerOutputRectangle? elementBounds;

  /// The text to enter.
  ///
  /// Output only.
  core.String? text;

  GoogleFirebaseAppdistroV1alphaDeviceInteractionEnterText({
    this.elementBounds,
    this.text,
  });

  GoogleFirebaseAppdistroV1alphaDeviceInteractionEnterText.fromJson(
    core.Map json_,
  ) : this(
        elementBounds: json_.containsKey('elementBounds')
            ? AndroidxCrawlerOutputRectangle.fromJson(
                json_['elementBounds'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        text: json_['text'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final elementBounds = this.elementBounds;
    final text = this.text;
    return {'elementBounds': ?elementBounds, 'text': ?text};
  }
}

/// A swipe action.
class GoogleFirebaseAppdistroV1alphaDeviceInteractionSwipe {
  /// The end point of the swipe.
  ///
  /// Output only.
  AndroidxCrawlerOutputPoint? end;

  /// The start point of the swipe.
  ///
  /// Output only.
  AndroidxCrawlerOutputPoint? start;

  GoogleFirebaseAppdistroV1alphaDeviceInteractionSwipe({this.end, this.start});

  GoogleFirebaseAppdistroV1alphaDeviceInteractionSwipe.fromJson(core.Map json_)
    : this(
        end: json_.containsKey('end')
            ? AndroidxCrawlerOutputPoint.fromJson(
                json_['end'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        start: json_.containsKey('start')
            ? AndroidxCrawlerOutputPoint.fromJson(
                json_['start'] as core.Map<core.String, core.dynamic>,
              )
            : null,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final end = this.end;
    final start = this.start;
    return {'end': ?end, 'start': ?start};
  }
}

/// A wait action.
class GoogleFirebaseAppdistroV1alphaDeviceInteractionWait {
  /// The duration of the wait.
  ///
  /// Output only.
  core.String? duration;

  GoogleFirebaseAppdistroV1alphaDeviceInteractionWait({this.duration});

  GoogleFirebaseAppdistroV1alphaDeviceInteractionWait.fromJson(core.Map json_)
    : this(duration: json_['duration'] as core.String?);

  core.Map<core.String, core.dynamic> toJson() {
    final duration = this.duration;
    return {'duration': ?duration};
  }
}

/// The request message for `EnableAccessOnRelease`.
class GoogleFirebaseAppdistroV1alphaEnableAccessOnReleaseRequest {
  /// Ignored.
  ///
  /// Used to be build version of the app release if an instance identifier was
  /// provided for the release_id.
  ///
  /// Optional.
  @core.Deprecated(
    'Not supported. Member documentation may have more information.',
  )
  core.String? buildVersion;

  /// Ignored.
  ///
  /// Used to be display version of the app release if an instance identifier
  /// was provided for the release_id.
  ///
  /// Optional.
  @core.Deprecated(
    'Not supported. Member documentation may have more information.',
  )
  core.String? displayVersion;

  /// An email address which should get access to this release, for example
  /// rebeccahe@google.com
  ///
  /// Optional.
  core.List<core.String>? emails;

  /// A repeated list of group aliases to enable access to a release for Note:
  /// This field is misnamed, but can't be changed because we need to maintain
  /// compatibility with old build tools
  ///
  /// Optional.
  core.List<core.String>? groupIds;

  GoogleFirebaseAppdistroV1alphaEnableAccessOnReleaseRequest({
    this.buildVersion,
    this.displayVersion,
    this.emails,
    this.groupIds,
  });

  GoogleFirebaseAppdistroV1alphaEnableAccessOnReleaseRequest.fromJson(
    core.Map json_,
  ) : this(
        buildVersion: json_['buildVersion'] as core.String?,
        displayVersion: json_['displayVersion'] as core.String?,
        emails: (json_['emails'] as core.List?)
            ?.map((value) => value as core.String)
            .toList(),
        groupIds: (json_['groupIds'] as core.List?)
            ?.map((value) => value as core.String)
            .toList(),
      );

  core.Map<core.String, core.dynamic> toJson() {
    final buildVersion = this.buildVersion;
    final displayVersion = this.displayVersion;
    final emails = this.emails;
    final groupIds = this.groupIds;
    return {
      'buildVersion': ?buildVersion,
      'displayVersion': ?displayVersion,
      'emails': ?emails,
      'groupIds': ?groupIds,
    };
  }
}

/// The response message for `EnableAccessOnRelease`.
class GoogleFirebaseAppdistroV1alphaEnableAccessOnReleaseResponse {
  GoogleFirebaseAppdistroV1alphaEnableAccessOnReleaseResponse();

  GoogleFirebaseAppdistroV1alphaEnableAccessOnReleaseResponse.fromJson(
    // ignore: avoid_unused_constructor_parameters
    core.Map json_,
  );

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Response object to get the release given a upload hash
class GoogleFirebaseAppdistroV1alphaGetReleaseByUploadHashResponse {
  /// Release object
  GoogleFirebaseAppdistroV1alphaRelease? release;

  GoogleFirebaseAppdistroV1alphaGetReleaseByUploadHashResponse({this.release});

  GoogleFirebaseAppdistroV1alphaGetReleaseByUploadHashResponse.fromJson(
    core.Map json_,
  ) : this(
        release: json_.containsKey('release')
            ? GoogleFirebaseAppdistroV1alphaRelease.fromJson(
                json_['release'] as core.Map<core.String, core.dynamic>,
              )
            : null,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final release = this.release;
    return {'release': ?release};
  }
}

/// Response containing the UDIDs of tester iOS devices in a project
class GoogleFirebaseAppdistroV1alphaGetTesterUdidsResponse {
  /// The UDIDs of tester iOS devices in a project
  core.List<GoogleFirebaseAppdistroV1alphaTesterUdid>? testerUdids;

  GoogleFirebaseAppdistroV1alphaGetTesterUdidsResponse({this.testerUdids});

  GoogleFirebaseAppdistroV1alphaGetTesterUdidsResponse.fromJson(core.Map json_)
    : this(
        testerUdids: (json_['testerUdids'] as core.List?)
            ?.map(
              (value) => GoogleFirebaseAppdistroV1alphaTesterUdid.fromJson(
                value as core.Map<core.String, core.dynamic>,
              ),
            )
            .toList(),
      );

  core.Map<core.String, core.dynamic> toJson() {
    final testerUdids = this.testerUdids;
    return {'testerUdids': ?testerUdids};
  }
}

/// The response message for `GetUploadStatus`.
class GoogleFirebaseAppdistroV1alphaGetUploadStatusResponse {
  /// The error code associated with (only set on "FAILURE")
  /// Possible string values are:
  /// - "ERROR_UNSPECIFIED"
  /// - "INVALID_ZIP"
  /// - "MISSING_PLIST"
  /// - "MISSING_PROFILE"
  /// - "VERSION_TOO_LONG"
  /// - "MISSING_UUIDS"
  /// - "MISSING_RESOURCES"
  /// - "MISSING_MANIFEST"
  /// - "IOS_METADATA_ERROR"
  /// - "ANDROID_METADATA_ERROR"
  /// - "UNSUPPORTED_PLATFORM_TYPE"
  /// - "BUNDLE_ID_MISMATCH"
  /// - "APK_NOT_ZIP_ALIGNED"
  /// - "INVALID_CERTIFICATE"
  /// - "APK_TOO_LARGE"
  /// - "AAB_NOT_PUBLISHED"
  /// - "INVALID_PLIST_DEVICE_FAMILIES"
  /// - "AAB_TOS_NOT_ACCEPTED"
  /// - "APP_NAME_TOO_LONG"
  /// - "AAB_DEVELOPER_ACCOUNT_NOT_LINKED"
  /// - "AAB_NO_APP_WITH_GIVEN_PACKAGE_NAME_IN_ACCOUNT"
  /// - "AAB_UPLOAD_ERROR"
  /// - "APP_NOT_FOUND" : Happens if the Firebase app no longer exists by the
  /// time of extraction
  /// - "AAB_ADHOC_SHARING_KEY_NOT_REGISTERED"
  /// - "AAB_ANDROID_DEVELOPER_CONSOLE_ACCOUNT_NOT_FOUND" : A corresponding
  /// Android Developer Console account for this app's Play Console account was
  /// not found.
  core.String? errorCode;

  /// Any additional context for the given upload status (e.g. error message)
  /// Meant to be displayed to the client
  core.String? message;

  /// The release that was created from the upload (only set on "SUCCESS")
  GoogleFirebaseAppdistroV1alphaRelease? release;

  /// The status of the upload
  /// Possible string values are:
  /// - "STATUS_UNSPECIFIED" : Status unspecified.
  /// - "IN_PROGRESS" : The upload is in progress.
  /// - "ALREADY_UPLOADED" : The binary has already been uploaded.
  /// - "SUCCESS" : The upload was successful.
  /// - "ERROR" : The upload failed.
  core.String? status;

  GoogleFirebaseAppdistroV1alphaGetUploadStatusResponse({
    this.errorCode,
    this.message,
    this.release,
    this.status,
  });

  GoogleFirebaseAppdistroV1alphaGetUploadStatusResponse.fromJson(core.Map json_)
    : this(
        errorCode: json_['errorCode'] as core.String?,
        message: json_['message'] as core.String?,
        release: json_.containsKey('release')
            ? GoogleFirebaseAppdistroV1alphaRelease.fromJson(
                json_['release'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        status: json_['status'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final errorCode = this.errorCode;
    final message = this.message;
    final release = this.release;
    final status = this.status;
    return {
      'errorCode': ?errorCode,
      'message': ?message,
      'release': ?release,
      'status': ?status,
    };
  }
}

/// An action taken by the AI agent while attempting to accomplish a goal.
class GoogleFirebaseAppdistroV1alphaGoalAction {
  /// The type of caching used to determine the action.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "CACHING_TYPE_UNSPECIFIED" : Caching type unspecified.
  /// - "NO_CACHING" : The model alone was used to determine the action with no
  /// caching.
  /// - "CACHE_AND_MODEL" : The model used information from a previous
  /// successful run to determine the action.
  /// - "CACHE_ONLY" : The action was replayed from a previous successful run
  /// without model input.
  core.String? cachingType;

  /// Debug information explaining why the agent to the specific action.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaGoalActionDebugInfo? debugInfo;

  /// A high level action taken by the AI on the device.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaDeviceAction? deviceAction;

  /// An explanation justifying why the action was taken.
  ///
  /// Output only.
  core.String? explanation;

  /// The time at which the action started.
  ///
  /// Output only.
  core.String? startTime;

  /// An action taken by the AI to end the goal.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaTerminalAction? terminalAction;

  GoogleFirebaseAppdistroV1alphaGoalAction({
    this.cachingType,
    this.debugInfo,
    this.deviceAction,
    this.explanation,
    this.startTime,
    this.terminalAction,
  });

  GoogleFirebaseAppdistroV1alphaGoalAction.fromJson(core.Map json_)
    : this(
        cachingType: json_['cachingType'] as core.String?,
        debugInfo: json_.containsKey('debugInfo')
            ? GoogleFirebaseAppdistroV1alphaGoalActionDebugInfo.fromJson(
                json_['debugInfo'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        deviceAction: json_.containsKey('deviceAction')
            ? GoogleFirebaseAppdistroV1alphaDeviceAction.fromJson(
                json_['deviceAction'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        explanation: json_['explanation'] as core.String?,
        startTime: json_['startTime'] as core.String?,
        terminalAction: json_.containsKey('terminalAction')
            ? GoogleFirebaseAppdistroV1alphaTerminalAction.fromJson(
                json_['terminalAction'] as core.Map<core.String, core.dynamic>,
              )
            : null,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final cachingType = this.cachingType;
    final debugInfo = this.debugInfo;
    final deviceAction = this.deviceAction;
    final explanation = this.explanation;
    final startTime = this.startTime;
    final terminalAction = this.terminalAction;
    return {
      'cachingType': ?cachingType,
      'debugInfo': ?debugInfo,
      'deviceAction': ?deviceAction,
      'explanation': ?explanation,
      'startTime': ?startTime,
      'terminalAction': ?terminalAction,
    };
  }
}

/// Information to help the customer understand why the agent took this action.
class GoogleFirebaseAppdistroV1alphaGoalActionDebugInfo {
  /// URI of the screenshot with elements labeled which was used by the agent.
  ///
  /// Output only.
  core.String? annotatedScreenshotUri;

  /// Structured data explaining the agent's choice.
  ///
  /// Output only.
  core.String? jsonUri;

  GoogleFirebaseAppdistroV1alphaGoalActionDebugInfo({
    this.annotatedScreenshotUri,
    this.jsonUri,
  });

  GoogleFirebaseAppdistroV1alphaGoalActionDebugInfo.fromJson(core.Map json_)
    : this(
        annotatedScreenshotUri: json_['annotatedScreenshotUri'] as core.String?,
        jsonUri: json_['jsonUri'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final annotatedScreenshotUri = this.annotatedScreenshotUri;
    final jsonUri = this.jsonUri;
    return {
      'annotatedScreenshotUri': ?annotatedScreenshotUri,
      'jsonUri': ?jsonUri,
    };
  }
}

/// Details for a goal step.
class GoogleFirebaseAppdistroV1alphaGoalDetails {
  /// The actions taken by the AI while attempting to accomplish the goal.
  ///
  /// Output only.
  core.List<GoogleFirebaseAppdistroV1alphaGoalAction>? goalActions;

  GoogleFirebaseAppdistroV1alphaGoalDetails({this.goalActions});

  GoogleFirebaseAppdistroV1alphaGoalDetails.fromJson(core.Map json_)
    : this(
        goalActions: (json_['goalActions'] as core.List?)
            ?.map(
              (value) => GoogleFirebaseAppdistroV1alphaGoalAction.fromJson(
                value as core.Map<core.String, core.dynamic>,
              ),
            )
            .toList(),
      );

  core.Map<core.String, core.dynamic> toJson() {
    final goalActions = this.goalActions;
    return {'goalActions': ?goalActions};
  }
}

/// A JWT token.
class GoogleFirebaseAppdistroV1alphaJwt {
  /// The JWT token (three Base64URL-encoded strings joined by dots).
  core.String? token;

  GoogleFirebaseAppdistroV1alphaJwt({this.token});

  GoogleFirebaseAppdistroV1alphaJwt.fromJson(core.Map json_)
    : this(token: json_['token'] as core.String?);

  core.Map<core.String, core.dynamic> toJson() {
    final token = this.token;
    return {'token': ?token};
  }
}

/// The response message for `ListReleaseTests`.
class GoogleFirebaseAppdistroV1alphaListReleaseTestsResponse {
  /// A short-lived token, which can be sent as `pageToken` to retrieve the next
  /// page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// The tests listed.
  core.List<GoogleFirebaseAppdistroV1alphaReleaseTest>? releaseTests;

  GoogleFirebaseAppdistroV1alphaListReleaseTestsResponse({
    this.nextPageToken,
    this.releaseTests,
  });

  GoogleFirebaseAppdistroV1alphaListReleaseTestsResponse.fromJson(
    core.Map json_,
  ) : this(
        nextPageToken: json_['nextPageToken'] as core.String?,
        releaseTests: (json_['releaseTests'] as core.List?)
            ?.map(
              (value) => GoogleFirebaseAppdistroV1alphaReleaseTest.fromJson(
                value as core.Map<core.String, core.dynamic>,
              ),
            )
            .toList(),
      );

  core.Map<core.String, core.dynamic> toJson() {
    final nextPageToken = this.nextPageToken;
    final releaseTests = this.releaseTests;
    return {'nextPageToken': ?nextPageToken, 'releaseTests': ?releaseTests};
  }
}

/// The response message for `ListTestCases`.
class GoogleFirebaseAppdistroV1alphaListTestCasesResponse {
  /// A token, which can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// The test cases from the specified app.
  core.List<GoogleFirebaseAppdistroV1alphaTestCase>? testCases;

  GoogleFirebaseAppdistroV1alphaListTestCasesResponse({
    this.nextPageToken,
    this.testCases,
  });

  GoogleFirebaseAppdistroV1alphaListTestCasesResponse.fromJson(core.Map json_)
    : this(
        nextPageToken: json_['nextPageToken'] as core.String?,
        testCases: (json_['testCases'] as core.List?)
            ?.map(
              (value) => GoogleFirebaseAppdistroV1alphaTestCase.fromJson(
                value as core.Map<core.String, core.dynamic>,
              ),
            )
            .toList(),
      );

  core.Map<core.String, core.dynamic> toJson() {
    final nextPageToken = this.nextPageToken;
    final testCases = this.testCases;
    return {'nextPageToken': ?nextPageToken, 'testCases': ?testCases};
  }
}

/// Login credential for automated tests
class GoogleFirebaseAppdistroV1alphaLoginCredential {
  /// Hints to the crawler for identifying input fields
  ///
  /// Optional.
  GoogleFirebaseAppdistroV1alphaLoginCredentialFieldHints? fieldHints;

  /// Are these credentials for Google?
  ///
  /// Optional.
  core.bool? google;

  /// Password for automated tests
  ///
  /// Optional.
  core.String? password;

  /// Username for automated tests
  ///
  /// Optional.
  core.String? username;

  GoogleFirebaseAppdistroV1alphaLoginCredential({
    this.fieldHints,
    this.google,
    this.password,
    this.username,
  });

  GoogleFirebaseAppdistroV1alphaLoginCredential.fromJson(core.Map json_)
    : this(
        fieldHints: json_.containsKey('fieldHints')
            ? GoogleFirebaseAppdistroV1alphaLoginCredentialFieldHints.fromJson(
                json_['fieldHints'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        google: json_['google'] as core.bool?,
        password: json_['password'] as core.String?,
        username: json_['username'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final fieldHints = this.fieldHints;
    final google = this.google;
    final password = this.password;
    final username = this.username;
    return {
      'fieldHints': ?fieldHints,
      'google': ?google,
      'password': ?password,
      'username': ?username,
    };
  }
}

/// Hints to the crawler for identifying input fields
class GoogleFirebaseAppdistroV1alphaLoginCredentialFieldHints {
  /// The Android resource name of the password UI element.
  ///
  /// For example, in Java: R.string.foo in xml: @string/foo Only the "foo" part
  /// is needed. Reference doc:
  /// https://developer.android.com/guide/topics/resources/accessing-resources.html
  ///
  /// Required.
  core.String? passwordResourceName;

  /// The Android resource name of the username UI element.
  ///
  /// For example, in Java: R.string.foo in xml: @string/foo Only the "foo" part
  /// is needed. Reference doc:
  /// https://developer.android.com/guide/topics/resources/accessing-resources.html
  ///
  /// Required.
  core.String? usernameResourceName;

  GoogleFirebaseAppdistroV1alphaLoginCredentialFieldHints({
    this.passwordResourceName,
    this.usernameResourceName,
  });

  GoogleFirebaseAppdistroV1alphaLoginCredentialFieldHints.fromJson(
    core.Map json_,
  ) : this(
        passwordResourceName: json_['passwordResourceName'] as core.String?,
        usernameResourceName: json_['usernameResourceName'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final passwordResourceName = this.passwordResourceName;
    final usernameResourceName = this.usernameResourceName;
    return {
      'passwordResourceName': ?passwordResourceName,
      'usernameResourceName': ?usernameResourceName,
    };
  }
}

/// Proto defining a release object
class GoogleFirebaseAppdistroV1alphaRelease {
  /// Release build version
  core.String? buildVersion;

  /// Release version
  core.String? displayVersion;

  /// Timestamp when the release was created
  core.String? distributedAt;

  /// Release Id
  core.String? id;

  /// Instance id of the release
  core.String? instanceId;

  /// Last activity timestamp
  core.String? lastActivityAt;

  /// Number of testers who have open invitations for the release
  core.int? openInvitationCount;

  /// unused.
  @core.Deprecated(
    'Not supported. Member documentation may have more information.',
  )
  core.String? receivedAt;

  /// Release notes summary
  core.String? releaseNotesSummary;

  /// Count of testers added to the release
  core.int? testerCount;

  /// Number of testers who have installed the release
  core.int? testerWithInstallCount;

  GoogleFirebaseAppdistroV1alphaRelease({
    this.buildVersion,
    this.displayVersion,
    this.distributedAt,
    this.id,
    this.instanceId,
    this.lastActivityAt,
    this.openInvitationCount,
    this.receivedAt,
    this.releaseNotesSummary,
    this.testerCount,
    this.testerWithInstallCount,
  });

  GoogleFirebaseAppdistroV1alphaRelease.fromJson(core.Map json_)
    : this(
        buildVersion: json_['buildVersion'] as core.String?,
        displayVersion: json_['displayVersion'] as core.String?,
        distributedAt: json_['distributedAt'] as core.String?,
        id: json_['id'] as core.String?,
        instanceId: json_['instanceId'] as core.String?,
        lastActivityAt: json_['lastActivityAt'] as core.String?,
        openInvitationCount: json_['openInvitationCount'] as core.int?,
        receivedAt: json_['receivedAt'] as core.String?,
        releaseNotesSummary: json_['releaseNotesSummary'] as core.String?,
        testerCount: json_['testerCount'] as core.int?,
        testerWithInstallCount: json_['testerWithInstallCount'] as core.int?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final buildVersion = this.buildVersion;
    final displayVersion = this.displayVersion;
    final distributedAt = this.distributedAt;
    final id = this.id;
    final instanceId = this.instanceId;
    final lastActivityAt = this.lastActivityAt;
    final openInvitationCount = this.openInvitationCount;
    final receivedAt = this.receivedAt;
    final releaseNotesSummary = this.releaseNotesSummary;
    final testerCount = this.testerCount;
    final testerWithInstallCount = this.testerWithInstallCount;
    return {
      'buildVersion': ?buildVersion,
      'displayVersion': ?displayVersion,
      'distributedAt': ?distributedAt,
      'id': ?id,
      'instanceId': ?instanceId,
      'lastActivityAt': ?lastActivityAt,
      'openInvitationCount': ?openInvitationCount,
      'receivedAt': ?receivedAt,
      'releaseNotesSummary': ?releaseNotesSummary,
      'testerCount': ?testerCount,
      'testerWithInstallCount': ?testerWithInstallCount,
    };
  }
}

/// Release notes for a release.
class GoogleFirebaseAppdistroV1alphaReleaseNotes {
  /// The actual release notes text from the user.
  core.String? releaseNotes;

  GoogleFirebaseAppdistroV1alphaReleaseNotes({this.releaseNotes});

  GoogleFirebaseAppdistroV1alphaReleaseNotes.fromJson(core.Map json_)
    : this(releaseNotes: json_['releaseNotes'] as core.String?);

  core.Map<core.String, core.dynamic> toJson() {
    final releaseNotes = this.releaseNotes;
    return {'releaseNotes': ?releaseNotes};
  }
}

/// Instance of an automated test for a release.
class GoogleFirebaseAppdistroV1alphaReleaseTest {
  /// Instructions for AI driven test.
  ///
  /// Optional.
  GoogleFirebaseAppdistroV1alphaAiInstructions? aiInstructions;

  /// Timestamp when the test was run.
  ///
  /// Output only.
  core.String? createTime;

  /// The results of the test on each device.
  ///
  /// Required.
  core.List<GoogleFirebaseAppdistroV1alphaDeviceExecution>? deviceExecutions;

  /// Display name of the release test.
  ///
  /// Required if the release test is created with multiple goals.
  ///
  /// Optional.
  core.String? displayName;

  /// Input only.
  ///
  /// Login credentials for the test. Input only.
  ///
  /// Optional.
  GoogleFirebaseAppdistroV1alphaLoginCredential? loginCredential;

  /// The name of the release test resource.
  ///
  /// Format:
  /// `projects/{project_number}/apps/{app}/releases/{release}/tests/{test}`
  core.String? name;

  /// Input only.
  ///
  /// The custom Cloud Storage bucket where test results are stored. Format:
  /// `projects/{project_number}/buckets/{bucket}` If not provided, the default
  /// test lab bucket is used.
  ///
  /// Optional.
  core.String? resultsBucket;

  /// The test case that was used to generate this release test.
  ///
  /// Note: The test case may have changed or been deleted since the release
  /// test was created. Format:
  /// `projects/{project_number}/apps/{app}/testCases/{test_case}`
  ///
  /// Optional.
  core.String? testCase;

  /// The state of the release test.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "TEST_STATE_UNSPECIFIED" : Test state unspecified.
  /// - "IN_PROGRESS" : The test is in progress.
  /// - "PASSED" : The test has passed.
  /// - "FAILED" : The test has failed.
  /// - "INCONCLUSIVE" : The test was inconclusive.
  core.String? testState;

  GoogleFirebaseAppdistroV1alphaReleaseTest({
    this.aiInstructions,
    this.createTime,
    this.deviceExecutions,
    this.displayName,
    this.loginCredential,
    this.name,
    this.resultsBucket,
    this.testCase,
    this.testState,
  });

  GoogleFirebaseAppdistroV1alphaReleaseTest.fromJson(core.Map json_)
    : this(
        aiInstructions: json_.containsKey('aiInstructions')
            ? GoogleFirebaseAppdistroV1alphaAiInstructions.fromJson(
                json_['aiInstructions'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        createTime: json_['createTime'] as core.String?,
        deviceExecutions: (json_['deviceExecutions'] as core.List?)
            ?.map(
              (value) => GoogleFirebaseAppdistroV1alphaDeviceExecution.fromJson(
                value as core.Map<core.String, core.dynamic>,
              ),
            )
            .toList(),
        displayName: json_['displayName'] as core.String?,
        loginCredential: json_.containsKey('loginCredential')
            ? GoogleFirebaseAppdistroV1alphaLoginCredential.fromJson(
                json_['loginCredential'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        name: json_['name'] as core.String?,
        resultsBucket: json_['resultsBucket'] as core.String?,
        testCase: json_['testCase'] as core.String?,
        testState: json_['testState'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final aiInstructions = this.aiInstructions;
    final createTime = this.createTime;
    final deviceExecutions = this.deviceExecutions;
    final displayName = this.displayName;
    final loginCredential = this.loginCredential;
    final name = this.name;
    final resultsBucket = this.resultsBucket;
    final testCase = this.testCase;
    final testState = this.testState;
    return {
      'aiInstructions': ?aiInstructions,
      'createTime': ?createTime,
      'deviceExecutions': ?deviceExecutions,
      'displayName': ?displayName,
      'loginCredential': ?loginCredential,
      'name': ?name,
      'resultsBucket': ?resultsBucket,
      'testCase': ?testCase,
      'testState': ?testState,
    };
  }
}

/// Configuration for Robo crawler
class GoogleFirebaseAppdistroV1alphaRoboCrawler {
  /// Instructions for AI driven test
  ///
  /// Optional.
  GoogleFirebaseAppdistroV1alphaAiInstructions? aiInstructions;

  /// Login credential for automated tests
  ///
  /// Optional.
  GoogleFirebaseAppdistroV1alphaLoginCredential? loginCredential;

  GoogleFirebaseAppdistroV1alphaRoboCrawler({
    this.aiInstructions,
    this.loginCredential,
  });

  GoogleFirebaseAppdistroV1alphaRoboCrawler.fromJson(core.Map json_)
    : this(
        aiInstructions: json_.containsKey('aiInstructions')
            ? GoogleFirebaseAppdistroV1alphaAiInstructions.fromJson(
                json_['aiInstructions'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        loginCredential: json_.containsKey('loginCredential')
            ? GoogleFirebaseAppdistroV1alphaLoginCredential.fromJson(
                json_['loginCredential'] as core.Map<core.String, core.dynamic>,
              )
            : null,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final aiInstructions = this.aiInstructions;
    final loginCredential = this.loginCredential;
    return {
      'aiInstructions': ?aiInstructions,
      'loginCredential': ?loginCredential,
    };
  }
}

/// Statistics collected during a Robo test.
class GoogleFirebaseAppdistroV1alphaRoboStats {
  /// Number of actions that crawler performed.
  ///
  /// Output only.
  core.int? actionsPerformed;

  /// Duration of crawl.
  ///
  /// Output only.
  core.String? crawlDuration;

  /// Number of distinct screens visited.
  ///
  /// Output only.
  core.int? distinctVisitedScreens;

  /// Whether the main activity crawl timed out.
  ///
  /// Output only.
  core.bool? mainActivityCrawlTimedOut;

  GoogleFirebaseAppdistroV1alphaRoboStats({
    this.actionsPerformed,
    this.crawlDuration,
    this.distinctVisitedScreens,
    this.mainActivityCrawlTimedOut,
  });

  GoogleFirebaseAppdistroV1alphaRoboStats.fromJson(core.Map json_)
    : this(
        actionsPerformed: json_['actionsPerformed'] as core.int?,
        crawlDuration: json_['crawlDuration'] as core.String?,
        distinctVisitedScreens: json_['distinctVisitedScreens'] as core.int?,
        mainActivityCrawlTimedOut:
            json_['mainActivityCrawlTimedOut'] as core.bool?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final actionsPerformed = this.actionsPerformed;
    final crawlDuration = this.crawlDuration;
    final distinctVisitedScreens = this.distinctVisitedScreens;
    final mainActivityCrawlTimedOut = this.mainActivityCrawlTimedOut;
    return {
      'actionsPerformed': ?actionsPerformed,
      'crawlDuration': ?crawlDuration,
      'distinctVisitedScreens': ?distinctVisitedScreens,
      'mainActivityCrawlTimedOut': ?mainActivityCrawlTimedOut,
    };
  }
}

/// A device screenshot taken during a test.
class GoogleFirebaseAppdistroV1alphaScreenshot {
  /// The height of the screenshot, in pixels.
  ///
  /// Output only.
  core.int? height;

  /// The URI of the screenshot.
  ///
  /// Output only.
  core.String? uri;

  /// The width of the screenshot, in pixels.
  ///
  /// Output only.
  core.int? width;

  GoogleFirebaseAppdistroV1alphaScreenshot({this.height, this.uri, this.width});

  GoogleFirebaseAppdistroV1alphaScreenshot.fromJson(core.Map json_)
    : this(
        height: json_['height'] as core.int?,
        uri: json_['uri'] as core.String?,
        width: json_['width'] as core.int?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final height = this.height;
    final uri = this.uri;
    final width = this.width;
    return {'height': ?height, 'uri': ?uri, 'width': ?width};
  }
}

/// An action taken by the AI to end the goal.
class GoogleFirebaseAppdistroV1alphaTerminalAction {
  /// The reason why this goal was ended.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "REASON_UNSPECIFIED" : Reason unspecified.
  /// - "GOAL_IMPOSSIBLE" : The goal failed to be completed. Note that
  /// "impossible" is a legacy term and the goal is reported to the customer as
  /// having "failed".
  /// - "GOAL_COMPLETE" : The goal was completed successfully.
  core.String? reason;

  /// The screenshot used in the context of this terminal action.
  ///
  /// Output only.
  GoogleFirebaseAppdistroV1alphaScreenshot? screenshot;

  GoogleFirebaseAppdistroV1alphaTerminalAction({this.reason, this.screenshot});

  GoogleFirebaseAppdistroV1alphaTerminalAction.fromJson(core.Map json_)
    : this(
        reason: json_['reason'] as core.String?,
        screenshot: json_.containsKey('screenshot')
            ? GoogleFirebaseAppdistroV1alphaScreenshot.fromJson(
                json_['screenshot'] as core.Map<core.String, core.dynamic>,
              )
            : null,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final reason = this.reason;
    final screenshot = this.screenshot;
    return {'reason': ?reason, 'screenshot': ?screenshot};
  }
}

/// AI test cases
class GoogleFirebaseAppdistroV1alphaTestCase {
  /// Instructions for AI driven test.
  ///
  /// Optional.
  GoogleFirebaseAppdistroV1alphaAiInstructions? aiInstructions;

  /// Timestamp when the test case was created
  ///
  /// Output only.
  core.String? createTime;

  /// Other test cases that depend on this test case as a prerequisite.
  ///
  /// Output only.
  core.List<core.String>? dependentTestCases;

  /// Display name of the test case.
  ///
  /// Required.
  core.String? displayName;

  /// Identifier.
  ///
  /// The name of the test case resource. Format:
  /// `projects/{project_number}/apps/{app}/testCases/{test_case}`
  core.String? name;

  /// Test case that must be run before this test case.
  ///
  /// Optional.
  core.String? prerequisiteTestCase;

  GoogleFirebaseAppdistroV1alphaTestCase({
    this.aiInstructions,
    this.createTime,
    this.dependentTestCases,
    this.displayName,
    this.name,
    this.prerequisiteTestCase,
  });

  GoogleFirebaseAppdistroV1alphaTestCase.fromJson(core.Map json_)
    : this(
        aiInstructions: json_.containsKey('aiInstructions')
            ? GoogleFirebaseAppdistroV1alphaAiInstructions.fromJson(
                json_['aiInstructions'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        createTime: json_['createTime'] as core.String?,
        dependentTestCases: (json_['dependentTestCases'] as core.List?)
            ?.map((value) => value as core.String)
            .toList(),
        displayName: json_['displayName'] as core.String?,
        name: json_['name'] as core.String?,
        prerequisiteTestCase: json_['prerequisiteTestCase'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final aiInstructions = this.aiInstructions;
    final createTime = this.createTime;
    final dependentTestCases = this.dependentTestCases;
    final displayName = this.displayName;
    final name = this.name;
    final prerequisiteTestCase = this.prerequisiteTestCase;
    return {
      'aiInstructions': ?aiInstructions,
      'createTime': ?createTime,
      'dependentTestCases': ?dependentTestCases,
      'displayName': ?displayName,
      'name': ?name,
      'prerequisiteTestCase': ?prerequisiteTestCase,
    };
  }
}

/// Configuration for automated tests
class GoogleFirebaseAppdistroV1alphaTestConfig {
  /// Display name of the AI driven test.
  ///
  /// Required if the release test is created with multiple goals.
  ///
  /// Optional.
  core.String? displayName;

  /// Identifier.
  ///
  /// The name of the test configuration resource. Format:
  /// `projects/{project_number}/apps/{app}/testConfig`
  core.String? name;

  /// The custom Cloud Storage bucket where test results are stored.
  ///
  /// Format: `projects/{project_number}/buckets/{bucket}` If not provided, the
  /// default test lab bucket is used.
  ///
  /// Optional.
  core.String? resultsBucket;

  /// Configuration for Robo crawler
  ///
  /// Optional.
  GoogleFirebaseAppdistroV1alphaRoboCrawler? roboCrawler;

  /// Tests will be run on this list of devices
  ///
  /// Optional.
  core.List<GoogleFirebaseAppdistroV1alphaTestDevice>? testDevices;

  GoogleFirebaseAppdistroV1alphaTestConfig({
    this.displayName,
    this.name,
    this.resultsBucket,
    this.roboCrawler,
    this.testDevices,
  });

  GoogleFirebaseAppdistroV1alphaTestConfig.fromJson(core.Map json_)
    : this(
        displayName: json_['displayName'] as core.String?,
        name: json_['name'] as core.String?,
        resultsBucket: json_['resultsBucket'] as core.String?,
        roboCrawler: json_.containsKey('roboCrawler')
            ? GoogleFirebaseAppdistroV1alphaRoboCrawler.fromJson(
                json_['roboCrawler'] as core.Map<core.String, core.dynamic>,
              )
            : null,
        testDevices: (json_['testDevices'] as core.List?)
            ?.map(
              (value) => GoogleFirebaseAppdistroV1alphaTestDevice.fromJson(
                value as core.Map<core.String, core.dynamic>,
              ),
            )
            .toList(),
      );

  core.Map<core.String, core.dynamic> toJson() {
    final displayName = this.displayName;
    final name = this.name;
    final resultsBucket = this.resultsBucket;
    final roboCrawler = this.roboCrawler;
    final testDevices = this.testDevices;
    return {
      'displayName': ?displayName,
      'name': ?name,
      'resultsBucket': ?resultsBucket,
      'roboCrawler': ?roboCrawler,
      'testDevices': ?testDevices,
    };
  }
}

/// A device on which automated tests can be run.
class GoogleFirebaseAppdistroV1alphaTestDevice {
  /// The locale of the device (e.g. "en_US" for US English) during the test.
  ///
  /// Optional.
  core.String? locale;

  /// The device model.
  ///
  /// Required.
  core.String? model;

  /// The orientation of the device during the test.
  ///
  /// Optional.
  core.String? orientation;

  /// The version of the device (API level on Android).
  ///
  /// Required.
  core.String? version;

  GoogleFirebaseAppdistroV1alphaTestDevice({
    this.locale,
    this.model,
    this.orientation,
    this.version,
  });

  GoogleFirebaseAppdistroV1alphaTestDevice.fromJson(core.Map json_)
    : this(
        locale: json_['locale'] as core.String?,
        model: json_['model'] as core.String?,
        orientation: json_['orientation'] as core.String?,
        version: json_['version'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final locale = this.locale;
    final model = this.model;
    final orientation = this.orientation;
    final version = this.version;
    return {
      'locale': ?locale,
      'model': ?model,
      'orientation': ?orientation,
      'version': ?version,
    };
  }
}

/// Customer quota information for `ReleaseTests`.
///
/// Note: This quota only applies to tests with `AiInstructions` and is separate
/// from the quota which might apply to the device time used by any tests.
class GoogleFirebaseAppdistroV1alphaTestQuota {
  /// Maximum number of `ReleaseTests` allotted for the current month.
  ///
  /// Output only.
  core.String? limit;

  /// Identifier.
  ///
  /// The name of the `TestQuota` resource. Format:
  /// `projects/{project_number}/testQuota`
  core.String? name;

  /// Number of `ReleaseTests` run in the current month
  ///
  /// Output only.
  core.String? usage;

  GoogleFirebaseAppdistroV1alphaTestQuota({this.limit, this.name, this.usage});

  GoogleFirebaseAppdistroV1alphaTestQuota.fromJson(core.Map json_)
    : this(
        limit: json_['limit'] as core.String?,
        name: json_['name'] as core.String?,
        usage: json_['usage'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final limit = this.limit;
    final name = this.name;
    final usage = this.usage;
    return {'limit': ?limit, 'name': ?name, 'usage': ?usage};
  }
}

/// The UDIDs of a tester's iOS device
class GoogleFirebaseAppdistroV1alphaTesterUdid {
  /// The name of the tester's device
  core.String? name;

  /// The platform of the tester's device
  core.String? platform;

  /// The UDID of the tester's device
  core.String? udid;

  GoogleFirebaseAppdistroV1alphaTesterUdid({
    this.name,
    this.platform,
    this.udid,
  });

  GoogleFirebaseAppdistroV1alphaTesterUdid.fromJson(core.Map json_)
    : this(
        name: json_['name'] as core.String?,
        platform: json_['platform'] as core.String?,
        udid: json_['udid'] as core.String?,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final name = this.name;
    final platform = this.platform;
    final udid = this.udid;
    return {'name': ?name, 'platform': ?platform, 'udid': ?udid};
  }
}

/// The request message for `UpdateTestCase`.
class GoogleFirebaseAppdistroV1alphaUpdateTestCaseRequest {
  /// If set to true, and the test case is not found, a new test case will be
  /// created.
  ///
  /// Optional.
  core.bool? allowMissing;

  /// The test case to update.
  ///
  /// The test case's `name` field is used to identify the test case to update.
  /// Format: `projects/{project_number}/apps/{app}/testCases/{test_case}`
  ///
  /// Required.
  GoogleFirebaseAppdistroV1alphaTestCase? testCase;

  GoogleFirebaseAppdistroV1alphaUpdateTestCaseRequest({
    this.allowMissing,
    this.testCase,
  });

  GoogleFirebaseAppdistroV1alphaUpdateTestCaseRequest.fromJson(core.Map json_)
    : this(
        allowMissing: json_['allowMissing'] as core.bool?,
        testCase: json_.containsKey('testCase')
            ? GoogleFirebaseAppdistroV1alphaTestCase.fromJson(
                json_['testCase'] as core.Map<core.String, core.dynamic>,
              )
            : null,
      );

  core.Map<core.String, core.dynamic> toJson() {
    final allowMissing = this.allowMissing;
    final testCase = this.testCase;
    return {'allowMissing': ?allowMissing, 'testCase': ?testCase};
  }
}

/// A generic empty message that you can re-use to avoid defining duplicated
/// empty messages in your APIs.
///
/// A typical example is to use it as the request or the response type of an API
/// method. For instance: service Foo { rpc Bar(google.protobuf.Empty) returns
/// (google.protobuf.Empty); }
class GoogleProtobufEmpty {
  GoogleProtobufEmpty();

  GoogleProtobufEmpty.fromJson(
    // ignore: avoid_unused_constructor_parameters
    core.Map json_,
  );

  core.Map<core.String, core.dynamic> toJson() => {};
}
