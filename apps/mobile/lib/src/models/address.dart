class Address {
  Address({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.region,
    this.district,
    required this.street,
    this.landmark,
    required this.isDefault,
  });

  final int id;
  final String label;
  final String fullName;
  final String phone;
  final String region;
  final String? district;
  final String street;
  final String? landmark;
  final bool isDefault;

  String get oneLine {
    final parts = [region, district, street, landmark]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: j['id'] as int,
        label: j['label'] as String,
        fullName: j['full_name'] as String,
        phone: j['phone'] as String,
        region: j['region'] as String,
        district: j['district'] as String?,
        street: j['street'] as String,
        landmark: j['landmark'] as String?,
        isDefault: j['is_default'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'full_name': fullName,
        'phone': phone,
        'region': region,
        'district': district,
        'street': street,
        'landmark': landmark,
        'is_default': isDefault,
      };
}
