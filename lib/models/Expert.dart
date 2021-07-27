import 'dart:convert';

class Expert {
  final String name;
  final String email;
  final String profilePhoto;
  final String specialtyDescription;
  final String specialty;
  final bool isOnline;

  Expert({
    required this.name,
    required this.isOnline,
    required this.email,
    required this.profilePhoto,
    required this.specialtyDescription,
    required this.specialty,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'isOnline': isOnline,
      'profilePhoto': profilePhoto,
      'specialtyDescription': specialtyDescription,
      'specialty': specialty,
    };
  }

  factory Expert.fromMap(Map<String, dynamic> map) {
    return Expert(
      name: map['name'],
      isOnline: map['isOnline'],
      email: map['email'],
      profilePhoto: map['profilePhoto'],
      specialtyDescription: map['specialtyDescription'],
      specialty: map['specialty'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Expert.fromJson(String source) => Expert.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Expert(name: $name, email: $email, profilePhoto: $profilePhoto, specialtyDescription: $specialtyDescription, specialty: $specialty)';
  }
}
