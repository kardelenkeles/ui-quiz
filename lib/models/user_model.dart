class UserModel {
  final String uid;
  final String? email;
  final String? password;

  UserModel({required this.uid, this.email, this.password});

  factory UserModel.fromFirebase(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      password: data['password'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'password': password};
  }
}
