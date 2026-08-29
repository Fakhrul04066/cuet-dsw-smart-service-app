import '../models/application_model.dart';
import '../models/notification_model.dart';
import '../models/student_model.dart';

class MockData {
  static const StudentProfile studentProfile = StudentProfile(
    name: 'Ayesha Rahman',
    studentId: '1902010',
    department: 'Computer Science & Engineering',
    levelTerm: 'Level 4 / Term I',
    email: 'ayesha.rahman@cuet.ac.bd',
    phone: '+8801712345678',
  );

  static const List<ApplicationModel> applications = [
    ApplicationModel(
      trackingNumber: 'CC-2026-0012',
      serviceType: 'Character Certificate',
      date: '2026-08-21',
      status: 'Under Review',
      submittedInformation: {
        'Student Name': 'Arafat Rahman',
        'Student ID': '1904010',
        'Department': 'Computer Science & Engineering',
        'Level': 'Level 4',
        'Term': 'Term I',
        'Email': 'u1904010@student.cuet.ac.bd',
        'Phone Number': '+8801712345678',
        'Purpose of Certificate':
            'Higher studies application and visa processing',
      },
      documentNames: [
        'Student ID Card',
        'Transcript Copy',
        'Passport size photo',
      ],
      statusHistory: ['Submitted', 'Under Review', 'Approved'],
      officialNotes: 'Application is valid and is under academic verification.',
      finalDecision: 'Approved for issue',
    ),
    ApplicationModel(
      trackingNumber: 'HT-2026-0015',
      serviceType: 'Hall Transfer',
      date: '2026-08-15',
      status: 'Correction Required',
      submittedInformation: {
        'Student Name': 'Arafat Rahman',
        'Student ID': '1904010',
        'Current Hall': 'Dr. Qudrat-i-Khuda Hall',
        'Preferred Hall': 'Shahid Mohammad Shah Hall',
        'Reason for Transfer':
            'Requesting closer access to the department building and better study environment.',
      },
      documentNames: ['Transfer request letter', 'Hall allotment slip'],
      statusHistory: [
        'Submitted',
        'Under Review',
        'Correction Required',
        'Resubmitted',
      ],
      officialNotes:
          'Please provide updated supporting evidence for room availability and hall preference.',
      finalDecision: null,
    ),
    ApplicationModel(
      trackingNumber: 'CMP-2026-0021',
      serviceType: 'Student Complaint',
      date: '2026-08-10',
      status: 'In Progress',
      submittedInformation: {
        'Complaint Category': 'Hall Facilities',
        'Complaint Title': 'Water supply interruption in dormitory block',
        'Detailed Description':
            'The water supply in Block B remains unavailable for the past three days affecting student welfare.',
        'Confidentiality': 'No',
      },
      documentNames: ['Photo evidence', 'Complaint statement'],
      statusHistory: ['Submitted', 'Assigned', 'In Progress'],
      officialNotes:
          'Complaint has been assigned to the Hall Administration for inspection.',
      finalDecision: null,
    ),
  ];

  static const List<NotificationModel> notifications = [
    NotificationModel(
      title: 'Character Certificate application received',
      message:
          'Your certificate application has been received and is now under review.',
      time: '2 hours ago',
      isRead: false,
    ),
    NotificationModel(
      title: 'Hall Transfer correction requested',
      message:
          'Please update your supporting evidence for hall transfer review.',
      time: 'Yesterday',
      isRead: false,
    ),
    NotificationModel(
      title: 'Complaint assigned to Hall Administration',
      message:
          'Your complaint has been assigned for inspection by the hall office.',
      time: '2 days ago',
      isRead: true,
    ),
    NotificationModel(
      title: 'Character Certificate approved',
      message: 'The approved certificate is ready to be downloaded.',
      time: '3 days ago',
      isRead: true,
    ),
    NotificationModel(
      title: 'Complaint resolved',
      message:
          'The issue has been reviewed and a resolution has been recorded.',
      time: '5 days ago',
      isRead: true,
    ),
  ];
}
