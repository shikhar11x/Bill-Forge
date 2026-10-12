import 'package:freezed_annotation/freezed_annotation.dart';

part 'supplier.freezed.dart';

@freezed
abstract class Supplier with _$Supplier {
  const Supplier._();

  const factory Supplier({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? gstin,
    String? city,
    String? notes,
    DateTime? archivedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Supplier;

  bool get isArchived => archivedAt != null;
}