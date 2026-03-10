class TopicEntity {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String systemPrompt;

  const TopicEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.systemPrompt,
  });
}

class TopicData {
  static const List<TopicEntity> topics = [
    TopicEntity(
      id: 'vacation',
      title: 'Vacation',
      description: 'Travel, booking, and holiday conversations',
      emoji: '🏖️',
      systemPrompt:
          'You are an English teacher playing the role of a travel companion. The user is practicing English for vacation scenarios. Help them with vocabulary for travel, hotel booking, sightseeing, and holiday phrases. Correct their mistakes gently and encourage them.',
    ),
    TopicEntity(
      id: 'travel_docs',
      title: 'Travel Documents',
      description: 'Airport, border, and customs dialogue',
      emoji: '🛂',
      systemPrompt:
          'You are an English teacher helping the user practice travel documentation scenarios. Simulate airport check-in, immigration, customs, and passport control dialogues. Correct grammar errors and teach relevant vocabulary.',
    ),
    TopicEntity(
      id: 'office',
      title: 'Office',
      description: 'Daily workplace language and conversations',
      emoji: '🏢',
      systemPrompt:
          'You are an English teacher and workplace communication coach. Help the student practice office English: emails, talking to colleagues, asking for help, water cooler conversations, and business etiquette. Correct errors and explain corporate vocabulary.',
    ),
    TopicEntity(
      id: 'tech_meeting',
      title: 'Tech Meeting',
      description: 'Technology and software team meetings',
      emoji: '💻',
      systemPrompt:
          'You are an English teacher specializing in technology and software development language. Simulate a tech meeting environment: sprint planning, code reviews, project updates, and tech jargon. Help the user practice speaking in a tech team setting. Correct their English and teach relevant tech vocabulary.',
    ),
    TopicEntity(
      id: 'gossip',
      title: 'Small Talk & Gossip',
      description: 'Casual conversation and social talk',
      emoji: '💬',
      systemPrompt:
          'You are an English teacher helping the user practice casual social English — small talk, gossip, opinions, and everyday conversation. Keep it fun and light. Gently correct grammar mistakes and introduce idiomatic expressions.',
    ),
    TopicEntity(
      id: 'housekeeper',
      title: 'Housekeeper',
      description: 'Home service and domestic help dialogues',
      emoji: '🏠',
      systemPrompt:
          'You are an English teacher simulating household service conversations. Help the user practice English for domestic service scenarios: instructions to a housekeeper, cleaning services, discussing tasks, and home management vocabulary. Correct errors and expand vocabulary.',
    ),
    TopicEntity(
      id: 'waiter',
      title: 'Restaurant & Waiter',
      description: 'Dining out and restaurant phrases',
      emoji: '🍽️',
      systemPrompt:
          'You are an English teacher and you will simulate a restaurant scenario. Switch between being the waiter and coach: take the user\'s order, handle complaints, special requests, and bills. Teach restaurant and food vocabulary. Correct the student\'s English naturally.',
    ),
  ];
}
