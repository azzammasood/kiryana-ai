class ProfileModel {
  final String name;
  final String email;
  final String phone;
  final String gender;
  final String dob;
  final String description;
  final String storeName;
  final String storeLocation;
  final int age;
  final String plan;
  final String? profilePicPath;

  const ProfileModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.dob,
    required this.description,
    required this.storeName,
    required this.storeLocation,
    required this.age,
    required this.plan,
    this.profilePicPath,
  });

  ProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? gender,
    String? dob,
    String? description,
    String? storeName,
    String? storeLocation,
    int? age,
    String? plan,
    String? profilePicPath,
  }) {
    return ProfileModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      description: description ?? this.description,
      storeName: storeName ?? this.storeName,
      storeLocation: storeLocation ?? this.storeLocation,
      age: age ?? this.age,
      plan: plan ?? this.plan,
      profilePicPath: profilePicPath ?? this.profilePicPath,
    );
  }

  bool get isPremium => plan == 'premium';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'dob': dob,
      'description': description,
      'storeName': storeName,
      'storeLocation': storeLocation,
      'age': age,
      'plan': plan,
      'profilePicPath': profilePicPath,
    };
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'] as String? ?? 'Kiryana Owner',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      dob: json['dob'] as String? ?? '',
      description: json['description'] as String? ?? '',
      storeName: json['storeName'] as String? ?? 'Kiryana Store',
      storeLocation: json['storeLocation'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 18,
      plan: json['plan'] as String? ?? 'free',
      profilePicPath: json['profilePicPath'] as String?,
    );
  }
}
