class User {
  String? email;
  String? fullName;
  String? profilePhoto;
  bool? isOnline;

  User({this.email, this.fullName, this.profilePhoto, this.isOnline});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      isOnline: json['isOnline'],
      fullName: json['fullname'],
      profilePhoto: json['profilePhoto'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['email'] = this.email;
    data['fullname'] = this.fullName;
    data['isOnline'] = this.isOnline;
    data['profilePhoto'] = this.profilePhoto;
    return data;
  }
}
