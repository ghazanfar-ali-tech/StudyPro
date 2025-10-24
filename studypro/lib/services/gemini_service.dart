import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:studypro/views/Gemini_AI/constants.dart';

class GeminiService {
  

  Future<String> callGeminiAPI(String prompt) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: geminiApiKey,
      );
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'No response from Gemini API';
    } catch (e) {
      throw Exception('Failed to call Gemini API: $e');
    }
  }
}