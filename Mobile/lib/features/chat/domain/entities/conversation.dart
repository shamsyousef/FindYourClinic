import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime lastMessageAt;
  final String? lastMessage;
  final String? counterpartyName;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.lastMessageAt,
    this.lastMessage,
    this.counterpartyName,
    required this.unreadCount,
  });

  Conversation copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    DateTime? lastMessageAt,
    String? lastMessage,
    String? counterpartyName,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        doctorId,
        lastMessageAt,
        lastMessage,
        counterpartyName,
        unreadCount,
      ];
}
