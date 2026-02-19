import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';

class ApiService {
  final String baseUrl = "https://sumberbaru.evognito.my.id/api";

  Future<LoginResponse> login(String nik, String password) async {
    try {
      var uri = Uri.parse("$baseUrl/login");
      var request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';


      request.fields['nik'] = nik;
      request.fields['password'] = password;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        return LoginResponse.fromJson(json);
      } else if (response.statusCode == 401) {
        return LoginResponse(success: false, message: "NIK atau Password Salah");
      } else if (response.statusCode == 422) {
        return LoginResponse(success: false, message: "Data tidak lengkap/valid");
      } else {
        return LoginResponse(
            success: false,
            message: "Error Server: ${response.statusCode}"
        );
      }
    } catch (e) {
      return LoginResponse(success: false, message: "Error: $e");
    }
  }
  Future<bool> changePassword(String token, String current, String newPass, String confirm) async {
    try {
      var uri = Uri.parse("$baseUrl/change-password");
      var request = http.MultipartRequest('POST', uri);

      // Header Wajib
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['current_password'] = current;
      request.fields['new_password'] = newPass;
      request.fields['new_password_confirmation'] = confirm;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Gagal Ganti Password: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  // Ubah return type jadi Map agar bisa bawa pesan
  Future<Map<String, dynamic>> postAttendance(String token, double lat, double long, File photo) async {
    try {
      var uri = Uri.parse("$baseUrl/attendance"); // Pastikan endpoint benar (attendance/attendances)
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['latitude'] = lat.toString();
      request.fields['longitude'] = long.toString();

      // Langsung kirim path (lebih stabil daripada cek exists dulu di beberapa android)
      var pic = await http.MultipartFile.fromPath("photo", photo.path);
      request.files.add(pic);

      print("Mengirim Absen: Lat: $lat, Long: $long");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Status Absen: ${response.statusCode}");
      print("Body Absen: ${response.body}");

      // Ambil body response
      var json = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message": json['message'] ?? "Absen Berhasil" // Ambil pesan dari API
        };
      } else {
        return {
          "success": false,
          "message": json['message'] ?? "Gagal Absen (Error ${response.statusCode})"
        };
      }
    } catch (e) {
      print("Error Absen: $e");
      return {
        "success": false,
        "message": "Terjadi kesalahan koneksi: $e"
      };
    }
  }
  Future<List<dynamic>> getHistory(String token) async {
    try {
      var uri = Uri.parse("$baseUrl/attendance/history");
      var response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        return json['data'];
      }
      return [];
    } catch (e) {
      print("Error History: $e");
      return [];
    }
  }
  Future<Map<String, dynamic>?> getProfile(String token) async {
    try {
      var uri = Uri.parse("$baseUrl/profile");
      var response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        return json['data'];
      }
      return null;
    } catch (e) {
      print("Error Profile: $e");
      return null;
    }
  }
  // Tambahkan ini di dalam class ApiService
  Future<bool> updateProfile(String token, String field, String value) async {
    try {
      var uri = Uri.parse("$baseUrl/profile"); // Sesuaikan endpoint API Anda
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Kirim field yang diedit (misal: 'email' atau 'phone')
      request.fields[field] = value;

      // Jika backend butuh method PUT/PATCH, sesuaikan.
      // Biasanya POST untuk update profil juga bisa tergantung backend.

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("Error Update: $e");
      return false;
    }
  }
  Future<List<dynamic>> getLeaveHistory(String token) async {
    try {
      var uri = Uri.parse("$baseUrl/leaves");
      var response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        return json['data'];
      }
      return [];
    } catch (e) {
      print("Error Leave History: $e");
      return [];
    }
  }

  Future<bool> postLeave(String token, String type, String startDate, String endDate, String reason, File? attachment) async {
    try {
      var uri = Uri.parse("$baseUrl/leaves");
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['type'] = type;
      request.fields['start_date'] = startDate;
      request.fields['end_date'] = endDate;
      request.fields['reason'] = reason;

      if (attachment != null) {
        if (await attachment.exists()) {
          var file = await http.MultipartFile.fromPath("attachment", attachment.path);
          request.files.add(file);
        }
      }

      print("Mengirim Cuti: $type, $startDate s/d $endDate");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Status Cuti: ${response.statusCode}");
      print("Body Cuti: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        var json = jsonDecode(response.body);
        return json['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error Cuti: $e");
      return false;
    }
  }
}