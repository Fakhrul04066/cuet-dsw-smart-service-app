import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

class AiHelpdeskScreen extends StatefulWidget {
  const AiHelpdeskScreen({super.key});

  @override
  State<AiHelpdeskScreen> createState() => _AiHelpdeskScreenState();
}

class _AiHelpdeskScreenState extends State<AiHelpdeskScreen> {
  final _controller = TextEditingController();
  final List<({bool user, String text, bool fallback})> _messages = [
    (
      user: false,
      text:
          'Hello. I can explain DSW services, required information, request categories, and the tracking process. I do not make official decisions.',
      fallback: false,
    ),
  ];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _loading) return;

    setState(() {
      _messages.add((user: true, text: question, fallback: false));
      _controller.clear();
      _loading = true;
    });

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
      );
      final response = await model.generateContent([
        Content.text(
          '''You are the CUET Directorate of Students' Welfare (DSW) helpdesk assistant inside a student service app.
You may explain these service categories: hall-related request, financial assistance, student welfare complaint, event permission, certificate/recommendation request, and general grievance.
Official workflow: Submitted → Under Review → Assigned → Resolved.
Students can upload PDF/JPG/PNG evidence up to 5 MB per file and track application history and notifications.
Do not claim a request is approved, rejected, guaranteed, or officially resolved. Do not invent university rules, fees, deadlines, contact numbers, or eligibility requirements. When policy-specific information is unavailable, tell the student to confirm with the DSW office.
Give a concise, helpful answer to: $question''',
        ),
      ]);
      final answer = response.text?.trim();
      if (!mounted) return;
      setState(() {
        _messages.add((
          user: false,
          text: answer == null || answer.isEmpty
              ? _fallbackAnswer(question)
              : answer,
          fallback: answer == null || answer.isEmpty,
        ));
      });
    } catch (error, stackTrace) {
      debugPrint('AI HELPDESK ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _messages.add((
          user: false,
          text: _fallbackAnswer(question),
          fallback: true,
        ));
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fallbackAnswer(String question) {
    final q = question.toLowerCase();

    if (q == 'hi' || q == 'hello' || q == 'hey' || q.contains('help')) {
      return 'I can help with hall requests, financial assistance, student welfare complaints, event permission, certificate/recommendation requests, general grievances, document uploads, and request tracking. What would you like to know?';
    }
    if (q.contains('hall')) {
      return 'For a hall-related issue, open DSW Service Center, choose “Hall-related request”, enter a clear title and detailed description, attach supporting evidence if available, and submit. You can then follow the status from Track Service Requests.';
    }
    if (q.contains('financial') || q.contains('assistance') || q.contains('money')) {
      return 'Choose “Financial assistance request” in DSW Service Center. Explain the situation clearly and attach any supporting documents you are comfortable providing. Eligibility and final decisions must be confirmed by the DSW office.';
    }
    if (q.contains('complaint') || q.contains('welfare') || q.contains('grievance')) {
      return 'For a student welfare complaint or general grievance, submit a DSW Service Request with a factual description of what happened, where relevant, and any supporting evidence. The official workflow is Submitted → Under Review → Assigned → Resolved.';
    }
    if (q.contains('event') || q.contains('permission')) {
      return 'Choose “Event permission” in DSW Service Center. Include the event purpose, date/time if known, venue, organizer details, and any supporting document. The DSW office will review the request according to official policy.';
    }
    if (q.contains('certificate') || q.contains('recommendation')) {
      return 'Choose “Certificate / recommendation request” in DSW Service Center, or use the specialized Character Certificate workflow when that is the service you need. Provide the purpose and supporting information requested by the form.';
    }
    if (q.contains('track') || q.contains('status') || q.contains('history')) {
      return 'Open Track Service Requests to see your request status, assigned officer, documents, resolution note, and application history. Status moves through Submitted → Under Review → Assigned → Resolved.';
    }
    if (q.contains('upload') || q.contains('document') || q.contains('pdf') || q.contains('image')) {
      return 'The service request form accepts PDF, JPG, and PNG files up to 5 MB per file. Images may also be used for advisory evidence analysis when the AI service is available.';
    }
    if (q.contains('workflow') || q.contains('process')) {
      return 'The standard DSW service workflow is Submitted → Under Review → Assigned → Resolved. Students can track changes and application history from the app.';
    }

    return 'I could not reach the online AI service, but the app can still guide you. DSW Service Center supports hall-related requests, financial assistance, student welfare complaints, event permission, certificate/recommendation requests, and general grievances. For policy-specific rules, fees, deadlines, or eligibility, confirm with the DSW office.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('AI DSW Helpdesk')),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.user
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.user
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message.text),
                          if (!message.user && message.fallback) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Offline guidance · online AI is currently unavailable',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask about a DSW service...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _loading ? null : _send,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
