import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef GetKeyFunc = Pointer<Utf8> Function();

class NativeService {
  static final DynamicLibrary _nativeLib = Platform.isAndroid
      ? DynamicLibrary.open("libnative_key.so")
      : DynamicLibrary.process();

  static String getApiKey() {
    try {
      final getNativeKey = _nativeLib
          .lookup<NativeFunction<GetKeyFunc>>('get_native_key')
          .asFunction<GetKeyFunc>();

      final Pointer<Utf8> ptr = getNativeKey();
      final String key = ptr.toDartString();

      // GIẢI PHÓNG BỘ NHỚ C++ TỪ DART
      // Cần thêm package ffi vào pubspec.yaml nếu chưa có
      malloc.free(ptr);

      return key;
    } catch (e) {
      print("❌ Lỗi FFI: $e");
      return "";
    }
  }
}
