class User {
  String username;
  String password;

  User({required this.username, required this.password});

  // Pastikan toJson mengembalikan data dalam format yang diinginkan
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}
