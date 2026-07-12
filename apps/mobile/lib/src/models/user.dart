class AppUser {
  AppUser({
    required this.id,
    required this.phone,
    required this.role,
    required this.fullName,
    required this.language,
    required this.status,
  });

  final int id;
  final String phone;
  final String role; // shop | distributor | factory | admin
  final String fullName;
  final String language;
  final String status; // pending | active | blocked

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isBuyer => role == 'shop' || role == 'distributor';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        phone: json['phone'] as String,
        role: json['role'] as String,
        fullName: json['full_name'] as String,
        language: json['language'] as String? ?? 'uz',
        status: json['status'] as String,
      );
}
