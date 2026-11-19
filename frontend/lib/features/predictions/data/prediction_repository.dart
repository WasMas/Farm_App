import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class PredictionRepository {
  PredictionRepository(this.dio);
  final Dio dio;

  Future<Map<String, dynamic>> disease(XFile image) async {
    final bytes = await image.readAsBytes();
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: image.name),
    });
    return Map<String, dynamic>.from(
      (await dio.post('predictions/disease/', data: form)).data as Map,
    );
  }

  Future<Map<String, dynamic>> yieldEstimate(int cycle) async =>
      Map<String, dynamic>.from(
        (await dio.post('predictions/yield/', data: {'cycle': cycle})).data
            as Map,
      );

  Future<List<Map<String, dynamic>>> history() async =>
      ((await dio.get('predictions/history/')).data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
}
