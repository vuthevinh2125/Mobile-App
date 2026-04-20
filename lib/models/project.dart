class Project {
  final int id;
  final String name;
  final String date;
  final String type;
  final double amount;

  Project({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.amount,
  });

  factory Project.fromJson(Map<dynamic, dynamic> json) {
    return Project(
      id: json['id'] ?? 0,
      name: json['claimant'] ?? 'Unknown',
      date: json['date'] ?? '',
      type: json['type'] ?? 'General',
      amount: (json['amount'] != null) ? double.parse(json['amount'].toString()) : 0.0,
    );
  }
}