import 'dart:io';

import 'package:protobuf/protobuf.dart' as p;

import 'google/api/client.pb.dart' as p;
import 'google/api/field_behavior.pb.dart' as p;
import 'google/api/resource.pb.dart' as p;
import 'google/longrunning/operations.pb.dart' as p;
import 'google/protobuf/descriptor.pb.dart' as p;

const List<String> _kBadRef = <String>[
  'google/api/client.proto',
  'google/api/resource.proto',
  'google/api/field_behavior.proto'
];

void removeProtoReferences(String path) {
  final File file = File(path);

  final p.FileDescriptorSet descriptor = p.FileDescriptorSet.fromBuffer(file.readAsBytesSync());

  final List<p.FileDescriptorProto> fileDescriptors = descriptor.file;

  _scrubFileImports(fileDescriptors);
  _scrubFileOptions(fileDescriptors);

  for (final p.FileDescriptorProto descriptor in fileDescriptors) {
    _scrubResourceReferences(descriptor.messageType);
    _scrubServiceOptions(descriptor.service);
    for (final p.ServiceDescriptorProto service in descriptor.service) {
      _scrubMethodOptions(service.method);
    }
  }

  file.writeAsBytesSync(descriptor.writeToBuffer());
}

void _scrubFileImports(List<p.FileDescriptorProto> fileDescriptors) {
  for (final p.FileDescriptorProto item in fileDescriptors) {
    item.dependency.removeWhere((String dependency) => _kBadRef.contains(dependency));
  }
}

void _scrubFileOptions(List<p.FileDescriptorProto> fileDescriptors) {
  for (final p.FileDescriptorProto item in fileDescriptors) {
    _scrubIfExists(item, p.Resource.resourceDefinition);
  }
}

void _scrubResourceReferences(List<p.DescriptorProto> descriptors) {
  for (final p.DescriptorProto item in descriptors) {
    for (final p.FieldDescriptorProto field in item.field) {
      if (field.hasOptions()) {
        _scrubIfExists(field.options, p.Resource.resource);
        _scrubIfExists(field.options, p.Resource.resourceReference);
        _scrubIfExists(field.options, p.Field_behavior.fieldBehavior);
      }
    }

    for (final p.DescriptorProto descriptor in item.nestedType) {
      _scrubResourceReferences(descriptor.nestedType);
    }
  }
}

void _scrubServiceOptions(List<p.ServiceDescriptorProto> services) {
  for (final p.ServiceDescriptorProto service in services) {
    if (service.hasOptions()) {
      _scrubIfExists(service.options, p.Client.defaultHost);
    }
  }
}

void _scrubMethodOptions(List<p.MethodDescriptorProto> methods) {
  for (final p.MethodDescriptorProto method in methods) {
    if (method.hasOptions()) {
      _scrubIfExists(method.options, p.Client.methodSignature);
      _scrubIfExists(method.options, p.Operations.operationInfo);
    }
  }
}

void _scrubIfExists<T>(p.GeneratedMessage message, p.Extension<T> extension) {
  if (message.hasExtension(extension)) {
    message.clearExtension(extension);
  }
}
