import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// False = Light Mode, True = Dark Mode
final themeProvider = StateProvider<bool>((ref) => false);