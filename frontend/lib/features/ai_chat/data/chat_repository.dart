
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/chat_message.dart';

class ChatRepository {
  ChatRepository(this.dio);

  final Dio dio;

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['results'] is List) {
      return data['results'] as List;
    }
    return [];
  }

  Future<int> getOrCreateConversation() async {
    final response = await dio.get('ai-chat/conversations/');

    final conversations = _extractList(response.data);

    if (conversations.isNotEmpty) {
      return conversations.first['id'] as int;
    }

    final created = await dio.post(
      'ai-chat/conversations/',
      data: <String, dynamic>{},
    );

    return created.data['id'] as int;
  }

  Future<List<ChatMessage>> getMessages(int conversationId) async {
    final response = await dio.get(
      'ai-chat/conversations/$conversationId/messages/',
    );

    return _extractList(response.data)
        .map(
          (item) => ChatMessage.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<ChatMessage>> sendMessage({
    required int conversationId,
    required String content,
    XFile? image,
  }) async {
    final formData = FormData();

    if (content.trim().isNotEmpty) {
      formData.fields.add(
        MapEntry('content', content.trim()),
      );
    }

    if (image != null) {
      final bytes = await image.readAsBytes();

      formData.files.add(
        MapEntry(
          'image',
          MultipartFile.fromBytes(
            bytes,
            filename: image.name,
          ),
        ),
      );
    }

    final response = await dio.post(
      'ai-chat/conversations/$conversationId/messages/',
      data: formData,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
      ),
    );

    final data = response.data as Map<String, dynamic>;

    return [
      ChatMessage.fromJson(
        Map<String, dynamic>.from(data['user_message'] as Map),
      ),
      ChatMessage.fromJson(
        Map<String, dynamic>.from(data['assistant_message'] as Map),
      ),
    ];
  }
}
