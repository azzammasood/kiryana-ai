class ProfileModel {
  final String name;
  final String email;
  final String phone;
  final String gender;
  final String dob;
  final String description;
  final String? profilePicPath;

  const ProfileModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.dob,
    required this.description,
    this.profilePicPath,
  });

  ProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? gender,
    String? dob,
    String? description,
    String? profilePicPath,
  }) {
    return ProfileModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      description: description ?? this.description,
      profilePicPath: profilePicPath ?? this.profilePicPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'dob': dob,
      'description': description,
      'profilePicPath': profilePicPath,
    };
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      gender: json['gender'] as String,
      dob: json['dob'] as String,
      description: json['description'] as String,
      profilePicPath: json['profilePicPath'] as String?,
    );
  }
}
