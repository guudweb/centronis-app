class Assignment {
  final int id;
  final String title;
  final String? description;
  final String assignmentType;
  final String? dueDate;
  final String? dueTime;
  final double pointsPossible;
  final bool isPublished;
  final bool allowLateSubmission;
  final double? latePenaltyPercentage;
  final int? courseId;
  final int? subjectId;
  final int? teacherId;
  final AssignmentCourse? course;
  final AssignmentSubject? subject;
  final AssignmentTeacher? teacher;
  final Submission? mySubmission;
  final SubmissionStats? submissionStats;
  final List<AssignmentQuestion>? questions;

  const Assignment({
    required this.id,
    required this.title,
    this.description,
    required this.assignmentType,
    this.dueDate,
    this.dueTime,
    required this.pointsPossible,
    this.isPublished = true,
    this.allowLateSubmission = false,
    this.latePenaltyPercentage,
    this.courseId,
    this.subjectId,
    this.teacherId,
    this.course,
    this.subject,
    this.teacher,
    this.mySubmission,
    this.submissionStats,
    this.questions,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      assignmentType: json['assignment_type'] as String? ?? 'homework',
      dueDate: json['due_date'] as String?,
      dueTime: json['due_time'] as String?,
      pointsPossible: (json['points_possible'] as num?)?.toDouble() ?? 100,
      isPublished: json['is_published'] as bool? ?? true,
      allowLateSubmission: json['allow_late_submission'] as bool? ?? false,
      latePenaltyPercentage:
          (json['late_penalty_percentage'] as num?)?.toDouble(),
      courseId: json['course_id'] as int?,
      subjectId: json['subject_id'] as int?,
      teacherId: json['teacher_id'] as int?,
      course: json['course'] != null
          ? AssignmentCourse.fromJson(json['course'] as Map<String, dynamic>)
          : null,
      subject: json['subject'] != null
          ? AssignmentSubject.fromJson(json['subject'] as Map<String, dynamic>)
          : null,
      teacher: json['teacher'] != null
          ? AssignmentTeacher.fromJson(json['teacher'] as Map<String, dynamic>)
          : null,
      mySubmission: json['my_submission'] != null
          ? Submission.fromJson(json['my_submission'] as Map<String, dynamic>)
          : null,
      submissionStats: json['submission_stats'] != null
          ? SubmissionStats.fromJson(
              json['submission_stats'] as Map<String, dynamic>)
          : null,
      questions: (json['questions'] as List<dynamic>?)
          ?.map(
              (e) => AssignmentQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AssignmentCourse {
  final int id;
  final String name;
  final String code;

  const AssignmentCourse(
      {required this.id, required this.name, required this.code});

  factory AssignmentCourse.fromJson(Map<String, dynamic> json) {
    return AssignmentCourse(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}

class AssignmentSubject {
  final int id;
  final String name;
  final String code;

  const AssignmentSubject(
      {required this.id, required this.name, required this.code});

  factory AssignmentSubject.fromJson(Map<String, dynamic> json) {
    return AssignmentSubject(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}

class AssignmentTeacher {
  final int id;
  final String name;
  final String? email;

  const AssignmentTeacher(
      {required this.id, required this.name, this.email});

  factory AssignmentTeacher.fromJson(Map<String, dynamic> json) {
    return AssignmentTeacher(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
    );
  }
}

class Submission {
  final int id;
  final int assignmentId;
  final int studentId;
  final String? submissionDate;
  final String? submissionText;
  final String? fileUrl;
  final String? fileName;
  final String status;
  final double? grade;
  final String? feedback;
  final bool? isLate;
  final int? lateDays;
  final String? gradedAt;
  final String? studentName;
  final String? studentCode;
  final String? studentEmail;
  final List<StudentAnswer>? studentAnswers;

  const Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.submissionDate,
    this.submissionText,
    this.fileUrl,
    this.fileName,
    this.status = 'submitted',
    this.grade,
    this.feedback,
    this.isLate,
    this.lateDays,
    this.gradedAt,
    this.studentName,
    this.studentCode,
    this.studentEmail,
    this.studentAnswers,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    return Submission(
      id: json['id'] as int,
      assignmentId: json['assignment_id'] as int? ?? 0,
      studentId: json['student_id'] as int? ?? 0,
      submissionDate: json['submission_date'] as String?,
      submissionText: json['submission_text'] as String?,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      status: json['status'] as String? ?? 'submitted',
      grade: (json['grade'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      isLate: json['is_late'] as bool?,
      lateDays: json['late_days'] as int?,
      gradedAt: json['graded_at'] as String?,
      studentName: student?['name'] as String?,
      studentCode: student?['student_code'] as String?,
      studentEmail: student?['email'] as String?,
      studentAnswers: (json['student_answers'] as List<dynamic>?)
          ?.map((e) => StudentAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentAnswer {
  final int id;
  final int? questionId;
  final int? selectedOptionId;
  final String? answerText;
  final bool? isCorrect;
  final double? pointsEarned;

  const StudentAnswer({
    required this.id,
    this.questionId,
    this.selectedOptionId,
    this.answerText,
    this.isCorrect,
    this.pointsEarned,
  });

  factory StudentAnswer.fromJson(Map<String, dynamic> json) {
    return StudentAnswer(
      id: json['id'] as int,
      questionId: json['question_id'] as int?,
      selectedOptionId: json['selected_option_id'] as int?,
      answerText: json['answer_text'] as String?,
      isCorrect: json['is_correct'] as bool?,
      pointsEarned: (json['points_earned'] as num?)?.toDouble(),
    );
  }
}

class AssignmentQuestion {
  final int id;
  final String questionText;
  final String questionType;
  final double points;
  final int? orderNumber;
  final List<QuestionOption>? options;

  const AssignmentQuestion({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.points,
    this.orderNumber,
    this.options,
  });

  factory AssignmentQuestion.fromJson(Map<String, dynamic> json) {
    return AssignmentQuestion(
      id: json['id'] as int,
      questionText: json['question_text'] as String? ?? '',
      questionType: json['question_type'] as String? ?? 'open_ended',
      points: (json['points'] as num?)?.toDouble() ?? 0,
      orderNumber: json['order_number'] as int?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuestionOption {
  final int id;
  final String optionText;
  final bool isCorrect;

  const QuestionOption({
    required this.id,
    required this.optionText,
    this.isCorrect = false,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] as int,
      optionText: json['option_text'] as String? ?? '',
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }
}

class SubmissionStats {
  final int total;
  final int submitted;
  final int graded;
  final int pending;

  const SubmissionStats({
    required this.total,
    required this.submitted,
    required this.graded,
    required this.pending,
  });

  factory SubmissionStats.fromJson(Map<String, dynamic> json) {
    return SubmissionStats(
      total: json['total'] as int? ?? 0,
      submitted: json['submitted'] as int? ?? 0,
      graded: json['graded'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
    );
  }
}
