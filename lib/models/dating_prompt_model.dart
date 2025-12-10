class DatingPrompt {
  final String promptId;
  final String question;
  final String answer;

  DatingPrompt({
    required this.promptId,
    required this.question,
    required this.answer,
  });

  factory DatingPrompt.fromMap(Map<String, dynamic> map) {
    return DatingPrompt(
      promptId: map['promptId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'promptId': promptId,
      'question': question,
      'answer': answer,
    };
  }
}

class DatingPrompts {
  static const List<String> availablePrompts = [
    'My ideal first date would be...',
    'I\'m really good at...',
    'The way to win me over is...',
    'I\'m looking for someone who...',
    'My perfect Sunday includes...',
    'I value...',
    'I\'m overly competitive about...',
    'The best way to ask me out is...',
    'My love language is...',
    'I geek out on...',
    'The dorkiest thing about me is...',
    'We\'ll get along if...',
    'My hidden talent is...',
    'I want someone who...',
    'A life goal of mine is...',
    'I\'m weirdly attracted to...',
    'The key to my heart is...',
    'My go-to karaoke song is...',
    'I recently discovered that...',
    'My most controversial opinion is...',
  ];

  static List<String> getRandomPrompts(int count) {
    final shuffled = List<String>.from(availablePrompts)..shuffle();
    return shuffled.take(count).toList();
  }
}
