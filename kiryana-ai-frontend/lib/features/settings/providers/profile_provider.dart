import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_model.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileModel>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<ProfileModel> {
  static const String _storageKey = 'kiryana_profile';

  ProfileNotifier()
      : super(const ProfileModel(
          name: 'Usman Ali',
          email: 'usman.ali@example.com',
          phone: '0300 1234567',
          gender: 'Male',
          dob: '15/05/1990',
          description: 'Proud owner of Ali Kiryana Store since 2015.',
        )) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      state = ProfileModel.fromJson(json.decode(jsonStr));
    }
  }

  Future<void> updateProfile(ProfileModel profile) async {
    state = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(state.toJson()));
  }

  Future<void> updateProfilePic(String path) async {
    state = state.copyWith(profilePicPath: path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(state.toJson()));
  }
}
