class UserModel {
  final String uid;
  final String email;
  final String name;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
    };
  }

  // Create from JSON from Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
    );
  }
}