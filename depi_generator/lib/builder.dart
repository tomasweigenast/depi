/// Depi builder library
library builder;

import 'package:build/build.dart';
import 'package:depi_generator/src/build_services.builder.dart';
import 'package:depi_generator/src/export_services.builder.dart';

Builder exportServices(BuilderOptions options) => ExportServicesBuilder();
Builder collectionGenerator(BuilderOptions options) => CollectionBuilder();
