class UserModel {
  final String uid;
  final String? email;

  UserModel({required this.uid, this.email});

  factory UserModel.fromFirebase(Map<String, dynamic> data) {
    return UserModel(uid: data['uid'], email: data['email']);
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email};
  }
}
