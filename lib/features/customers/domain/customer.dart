import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';

@freezed
abstract class Customer with _$Customer {
  const Customer._();

  const factory Customer({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? gstin,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,

    /// Integer paise. Null means no credit limit is enforced.
    int? creditLimitPaise,
    String? notes,
    DateTime? archivedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Customer;

  bool get isArchived => archivedAt != null;

  /// "Gurugram, Haryana", or empty when neither is set.
  String get locationLabel =>
      [city, state].whereType<String>().where((s) => s.isNotEmpty).join(', ');
}
