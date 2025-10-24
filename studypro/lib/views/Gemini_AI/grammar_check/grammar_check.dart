import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:record/record.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:rich_text_controller/rich_text_controller.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/components/size_config.dart';
import 'package:studypro/services/gemini_service.dart';
import 'package:studypro/views/Gemini_AI/constants.dart';

class GrammarCheckerScreen extends StatefulWidget {
  const GrammarCheckerScreen({super.key});

  @override
  State<GrammarCheckerScreen> createState() => _GrammarCheckerScreenState();
}

class _GrammarCheckerScreenState extends State<GrammarCheckerScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final Deepgram _deepgram = Deepgram(deepgramApiKey);
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterTts _flutterTts = FlutterTts();
  final GeminiService _geminiService = GeminiService();
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  String? _correctedText;
  String? _explanation;
  List<String> _grammarErrors = [];
  bool _isListening = false;
  bool _isLoading = false;
  bool _speechInitialized = false;
  bool _isSpeaking = false;
  double _speechVolume = 0.0;
  RichTextController? _richTextController;
  Stream<DeepgramListenResult>? _sttStream;
  
  List<String> _textHistory = [];
  int _historyIndex = -1;
  
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initSpeech();
    _initTts();
    _setupRichTextController();
    _textController.addListener(_onTextChanged);
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  void _setupRichTextController() {
    _richTextController = RichTextController(
      targetMatches: [
        MatchTargetItem.pattern(
          r'\b\w+\b(?= →)',
          style: const TextStyle(
            color: Colors.red,
            backgroundColor: Colors.red,
            decoration: TextDecoration.lineThrough,
            fontWeight: FontWeight.w500,
          ),
        ),
        MatchTargetItem.pattern(
          r'→ \w+\b',
          style: const TextStyle(
            color: Colors.green,
            backgroundColor: Colors.lightGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
        MatchTargetItem.pattern(
          r'\b(grammar|spelling|punctuation|tense|agreement)\b',
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
      onMatch: (matches) {
        debugPrint('Grammar matches found: ${matches.length}');
      },
    );
  }

  void _onTextChanged() {
    if (mounted && _textController.text.isNotEmpty){
      setState(() {});
    }
  }

  Future<void> _initSpeech() async {
  try {
    final isValid = await _deepgram.isApiKeyValid();
    if (!isValid) {
      _showErrorSnackBar('Invalid Deepgram API key. Please check your configuration.');
      return;
    }
    
    _speechInitialized = await _recorder.hasPermission();
    if (!_speechInitialized) {
      _showErrorSnackBar('Microphone permission required for speech recognition');
    } else {
      _showSuccessSnackBar('Speech recognition ready!');
    }
    
    if (mounted) {
      setState(() {});
    }
  } catch (e) {
    _showErrorSnackBar('Failed to initialize speech recognition: $e');
    if (mounted) {
      setState(() => _speechInitialized = false);
    }
  }
}

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      
      _flutterTts.setStartHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = true);
        }
      });
      
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
      });
      
      _flutterTts.setCancelHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
      });
      
      _flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() => _isSpeaking = false);
          _showErrorSnackBar('Speech error: $msg');
        }
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to initialize text-to-speech: $e');
      }
    }
  }

  Future<void> _startListening() async {
  if (!_speechInitialized) {
    _showErrorSnackBar('Speech recognition not available');
    return;
  }

  try {
    _addToHistory(_textController.text);

    final micStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    final sttStreamParams = {
      'language': 'en',
      'encoding': 'linear16',
      'sample_rate': 16000,
      'punctuate': true,
      'interim_results': true,
    };

    _sttStream = _deepgram.listen.live(micStream, queryParams: sttStreamParams);
    _sttStream!.listen(
      (result) {
        if (mounted && (result.transcript?.isNotEmpty ?? false)) {
          setState(() {
            _textController.text = result.transcript ?? '';
            _speechVolume = (result.transcript?.length ?? 0) / 100.0;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          _showErrorSnackBar('Speech recognition error: $error');
          _stopListening();
        }
      },
    );

    if (mounted) {
      setState(() {
        _isListening = true;
      });
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          HapticFeedback.lightImpact();
        }
      });
    }
  } catch (e) {
    if (mounted) {
      _showErrorSnackBar('Error starting speech recognition: $e');
      setState(() {
        _isListening = false;
      });
    }
  }
}

  Future<void> _stopListening() async {
    try {
      if (_sttStream != null) {
        await _recorder.stop();
        _sttStream = null;
      }
      if (mounted) {
        setState(() {
          _isListening = false;
          _speechVolume = 0.0;
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error stopping recording: $e');
      } else {
        debugPrint('Error stopping recording in dispose: $e');
      }
    }
  }

  void _addToHistory(String text) {
    if (text.isNotEmpty && (text != (_textHistory.isNotEmpty ? _textHistory.last : ''))) {
      _textHistory.add(text);
      _historyIndex = _textHistory.length - 1;
      if (_textHistory.length > 10) {
        _textHistory.removeAt(0);
        _historyIndex--;
      }
    }
  }

  void _undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _textController.text = _textHistory[_historyIndex];
      setState(() {});
    }
  }

  void _redo() {
    if (_historyIndex < _textHistory.length - 1) {
      _historyIndex++;
      _textController.text = _textHistory[_historyIndex];
      setState(() {});
    }
  }

  Future<void> _checkGrammar() async {
  if (_textController.text.trim().isEmpty) {
    _showErrorSnackBar('Please enter or speak a sentence first');
    return;
  }

  _addToHistory(_textController.text);

  if (mounted) {
    setState(() => _isLoading = true);
  }

  final prompt = '''
    Please check the grammar, spelling, and punctuation for the following text and provide corrections:
    "${_textController.text}"
    
    Format your response as follows:
    1. First line: Show corrections in format "original → corrected" for each error
    2. Second line onwards: Provide detailed explanation of errors found
    
    If no errors are found, respond with " No errors found" followed by a brief positive comment.
    ''';

  try {
    final response = await _geminiService.callGeminiAPI(prompt);
    final parts = response.split('\n');

    if (mounted) {
      setState(() {
        if (response.contains('No errors found')) {
          _correctedText = ' No errors found - Great job!';
          _explanation = 'Your text is grammatically correct.';
          _grammarErrors = [];
        } else {
          _correctedText = parts.isNotEmpty ? parts[0] : response;
          _explanation = parts.length > 1 ? parts.sublist(1).join('\n') : '';
          _grammarErrors = _extractErrors(_correctedText ?? '');
        }

        _richTextController!.text = _correctedText ?? '';
        _isLoading = false;
      });

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _slideController.forward();
          HapticFeedback.mediumImpact();
        }
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _correctedText = 'Error occurred while checking grammar';
        _explanation = 'Please check your internet connection and try again.\nError: $e';
        _grammarErrors = [];
        _isLoading = false;
      });
      _showErrorSnackBar('Grammar check failed: $e');
    }
  }
}

  List<String> _extractErrors(String correctedText) {
    final errors = <String>[];
    final regex = RegExp(r'(\w+) → (\w+)');
    final matches = regex.allMatches(correctedText);
    
    for (final match in matches) {
      errors.add('${match.group(1)} → ${match.group(2)}');
    }
    
    return errors;
  }

  Future<void> _speakCorrectedText() async {
    if (_correctedText == null) return;
    
    String textToSpeak;
    if (_correctedText!.contains('No errors found')) {
      textToSpeak = 'Your text is correct: ${_textController.text}. ${_explanation ?? "Great job!"}';
    } else {
      String correctedVersion = _correctedText!
          .replaceAll(RegExp(r'\w+ → '), '')
          .replaceAll(' Correct:', '')
          .trim();
      
      if (correctedVersion.isEmpty) {
        correctedVersion = _textController.text;
      }
      
      String explanationText = _explanation ?? '';
      explanationText = explanationText
          .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
          .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
          .replaceAll(RegExp(r'`(.*?)`'), r'$1')
          .replaceAll(RegExp(r'#{1,6}\s'), '')
          .replaceAll(RegExp(r'\n+'), '. ')
          .trim();
      
      if (_grammarErrors.isNotEmpty) {
        textToSpeak = 'Here are the corrections: $correctedVersion. ';
        textToSpeak += 'I found ${_grammarErrors.length} error${_grammarErrors.length == 1 ? '' : 's'}. ';
        if (explanationText.isNotEmpty) {
          textToSpeak += explanationText;
        }
      } else {
        textToSpeak = 'Corrected text: $correctedVersion. $explanationText';
      }
    }
    
    await _flutterTts.speak(textToSpeak);
  }

  Future<void> _speakCorrectedTextOnly() async {
    if (_correctedText == null) return;
    
    String textToSpeak;
    if (_correctedText!.contains('No errors found')) {
      textToSpeak = _textController.text;
    } else {
      textToSpeak = _correctedText!
          .replaceAll(RegExp(r'\w+ → '), '')
          .replaceAll(' Correct:', '')
          .trim();
      
      if (textToSpeak.isEmpty) {
        textToSpeak = _textController.text;
      }
    }
    
    await _flutterTts.speak(textToSpeak);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() => _isSpeaking = false);
      HapticFeedback.lightImpact();
    }
  }

  void _clearAll() {
    _textController.clear();
    setState(() {
      _correctedText = null;
      _explanation = null;
      _grammarErrors.clear();
    });
    _slideController.reverse();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccessSnackBar('Copied to clipboard');
  }

  void _showErrorSnackBar(String message) {
  if (mounted && _scaffoldMessenger != null) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                 SizedBox(width: SizeConfig().scaleWidth(8, context)),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  } else {
    debugPrint('Error: $message');
  }
}

void _showSuccessSnackBar(String message) {
  if (mounted && _scaffoldMessenger != null) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                 SizedBox(width: SizeConfig().scaleWidth(8, context)),
                Text(message),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  } else {
    debugPrint('Success: $message');
  }
}

  @override
  void dispose() {
    _stopListening();
    _flutterTts.stop();
    _pulseController.dispose();
    _slideController.dispose();
    _recorder.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textFocusNode.dispose();
    _richTextController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title:  Text('Grammar Checker', style: TextStyle(fontWeight: FontWeight.w600,color: AppColors.textPrimary(context))),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.cardBackground(context),
        foregroundColor: AppColors.textPrimary(context),
        actions: [
          if (_isSpeaking)
            IconButton(
              onPressed: _stopSpeaking,
              icon: const Icon(Icons.stop_circle),
              tooltip: 'Stop Speaking',
            ),
          if (_textController.text.isNotEmpty)
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sharp),
              tooltip: 'Clear All',
            ),
        ],
      ),
      floatingActionButton: _isSpeaking
          ? FloatingActionButton(
              onPressed: _stopSpeaking,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              child: const Icon(Icons.stop),
              tooltip: 'Stop Speaking',
            )
          : null,
          backgroundColor: AppColors.background(context),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 10,
                    backgroundColor: AppColors.iconPrimary
                  ),
                   SizedBox(height: SizeConfig().scaleHeight(16, context)),
                  const Text('Analyzing grammar...', style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputSection(),
                   SizedBox(height: SizeConfig().scaleHeight(15, context)),
                  _buildControlButtons(),
                   SizedBox(height: SizeConfig().scaleHeight(15, context)),
                  if (_correctedText != null) _buildResultsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      elevation: 2,
      color: AppColors.cardBackground(context),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                 SizedBox(width: SizeConfig().scaleWidth(8, context)),
                const Text('Enter your text:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const Spacer(),
                if (_textHistory.isNotEmpty) ...[
                  IconButton(
                    onPressed: _historyIndex > 0 ? _undo : null,
                    icon: const Icon(Icons.undo),
                    tooltip: 'Undo',
                    iconSize: 20,
                  ),
                  IconButton(
                    onPressed: _historyIndex < _textHistory.length - 1 ? _redo : null,
                    icon: const Icon(Icons.redo),
                    tooltip: 'Redo',
                    iconSize: 20,
                  ),
                ],
              ],
            ),
             SizedBox(height: SizeConfig().scaleHeight(12, context)),
           TextField(
  controller: _textController,
  focusNode: _textFocusNode,
  decoration: InputDecoration(
    hintText: 'Type or speak your sentence here...',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.border(context),
        width: 1.5,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.border(context),
        width: 1.5,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.border(context),
        width: 2.0, 
      ),
    ),
    filled: true,
    fillColor: AppColors.cardBackground(context),
    suffixIcon: _textController.text.isNotEmpty
        ? IconButton(
            onPressed: () => _copyToClipboard(_textController.text),
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Copy Text',
          )
        : null,
  ),
  maxLines: 4,
  textCapitalization: TextCapitalization.sentences,
),

            if (_textController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${_textController.text.length} characters',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _pulseAnimation.value : 1.0,
              child: ElevatedButton.icon(
                onPressed: _speechInitialized
                    ? (_isListening ? _stopListening : _startListening)
                    : null,
                icon: Icon(_isListening ? Icons.stop : Icons.mic),
                label: Text(_isListening ? 'Stop' : 'Speak'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isListening ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            );
          },
        ),
        ElevatedButton.icon(
          onPressed: _textController.text.isNotEmpty ? _checkGrammar : null,
          icon: const Icon(Icons.spellcheck),
          label: const Text('Check Grammar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _correctedText!.contains('No errors found') ? Icons.check_circle : Icons.edit_note,
                    color: _correctedText!.contains('No errors found') ? Colors.green : Colors.orange,
                  ),
                   SizedBox(width: SizeConfig().scaleWidth(8, context)),
                  const Text('Results:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_isSpeaking) ...[
                     SizedBox(width: SizeConfig().scaleWidth(8, context)),
                    SizedBox(
                      width: SizeConfig().scaleWidth(16, context),
                      height: SizeConfig().scaleHeight(16, context),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade600),
                      ),
                    ),
                     SizedBox(width: SizeConfig().scaleWidth(4, context)),
                    Text(
                      'Speaking...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: () => _copyToClipboard(_correctedText!),
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy Results',
                  ),
                ],
              ),
              const Divider(),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground(context),
                  border: Border.all(color: AppColors.border(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _richTextController,
                  readOnly: true,
                  decoration: const InputDecoration.collapsed(hintText: ''),
                  style: const TextStyle(fontSize: 16),
                  maxLines: null,
                ),
              ),
              
               SizedBox(height: SizeConfig().scaleHeight(16, context)),
              
              if (_grammarErrors.isNotEmpty) ...[
                Text(
                  'Errors Found (${_grammarErrors.length}):',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(8, context)),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _grammarErrors.map((error) => Chip(
                    label: Text(error, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.red.shade100,
                    labelStyle: TextStyle(color: Colors.red.shade700),
                  )).toList(),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(16, context)),
              ],
              
              if (_explanation?.isNotEmpty ?? false) ...[
                const Text('Explanation:', style: TextStyle(fontWeight: FontWeight.w600)),
                 SizedBox(height: SizeConfig().scaleHeight(8, context)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Text(_explanation!, style: const TextStyle(fontSize: 14)),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(10, context)),
              ],
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isSpeaking ? null : _speakCorrectedText,
                    icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_up_outlined),
                    label: Text(_isSpeaking ? 'Speaking...' : 'Hear Full Explanation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
               
                ],
              ),
               SizedBox(height: SizeConfig().scaleHeight(8, context)),
              Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    OutlinedButton.icon(
      onPressed: () {
        String correctedVersion = _correctedText!
            .replaceAll(RegExp(r'\w+ → '), '')
            .replaceAll(' Correct:', '')
            .replaceAll(' No errors found - Great job!', _textController.text)
            .trim();
        
        if (correctedVersion.isEmpty) {
          correctedVersion = _textController.text;
        }
        
        _textController.text = correctedVersion;
        _addToHistory(_textController.text);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showSuccessSnackBar('Applied corrections to input field');
          }
        });
      },
      icon: const Icon(Icons.check),
      label: const Text('Apply Corrections'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  ],
),
            ],
          ),
        ),
      ),
    );
  }
}