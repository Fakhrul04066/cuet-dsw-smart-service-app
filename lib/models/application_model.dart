class ApplicationModel {
  final String trackingNumber;
  final String serviceType;
  final String date;
  final String status;
  final Map<String, String> submittedInformation;
  final List<String> documentNames;
  final List<String> statusHistory;
  final String? officialNotes;
  final String? finalDecision;

  const ApplicationModel({
    required this.trackingNumber,
    required this.serviceType,
    required this.date,
    required this.status,
    required this.submittedInformation,
    required this.documentNames,
    required this.statusHistory,
    this.officialNotes,
    this.finalDecision,
  });
}
