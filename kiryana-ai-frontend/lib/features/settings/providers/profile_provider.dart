import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_model.dart';

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileModel>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<ProfileModel> {
  static const String _activePhoneKey = 'phone_number';

  ProfileNotifier() : super(_emptyProfile()) {
    loadActiveProfile();
  }

  static ProfileModel _emptyProfile({String phone = ''}) {
    return ProfileModel(
      name: 'Kiryana Owner',
      email: '',
      phone: phone,
      gender: '',
      dob: '',
      description: 'KiryanaAI account',
      storeName: 'Kiryana Store',
      storeLocation: '',
      age: 18,
      plan: 'free',
    );
  }

  static String _keyForPhone(String phone) => 'kiryana_profile_$phone';

  Future<bool> hasProfileForPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyForPhone(phone)) != null;
  }

  Future<void> loadActiveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_activePhoneKey) ?? '';
    await loadProfileForPhone(phone);
  }

  Future<void> loadProfileForPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyForPhone(phone));
    if (jsonStr == null) {
      state = _emptyProfile(phone: phone);
      return;
    }
    state = ProfileModel.fromJson(json.decode(jsonStr));
  }

  Future<void> updateProfile(ProfileModel profile) async {
    state = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyForPhone(profile.phone), json.encode(profile.toJson()));
  }

  Future<void> updateProfilePic(String path) async {
    await updateProfile(state.copyWith(profilePicPath: path));
  }

  Future<void> setPlan(String plan) async {
    await updateProfile(state.copyWith(plan: plan));
  }
}
