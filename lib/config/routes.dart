import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/tenant_provider.dart';
import '../layouts/admin_layout.dart';
import '../layouts/teacher_layout.dart';
import '../layouts/student_layout.dart';
import '../layouts/parent_layout.dart';
import '../layouts/secretary_layout.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/tenant_screen.dart';
import '../screens/common/profile_screen.dart';
// Admin
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/users_screen.dart';
import '../screens/admin/students_management_screen.dart';
import '../screens/admin/courses_management_screen.dart';
import '../screens/admin/settings_screen.dart';
import '../screens/admin/student_detail_screen.dart';
import '../screens/admin/course_detail_screen.dart';
// Teacher
import '../screens/teacher/teacher_dashboard_screen.dart';
import '../screens/teacher/teacher_courses_screen.dart';
import '../screens/teacher/teacher_attendance_screen.dart';
import '../screens/teacher/teacher_grades_screen.dart';
import '../screens/teacher/teacher_assignments_screen.dart';
import '../screens/teacher/teacher_assignment_detail_screen.dart';
import '../screens/teacher/teacher_course_detail_screen.dart';
// Student
import '../screens/student/student_dashboard_screen.dart';
import '../screens/student/student_grades_screen.dart';
import '../screens/student/student_schedule_screen.dart';
import '../screens/student/student_attendance_screen.dart';
import '../screens/student/student_courses_screen.dart';
import '../screens/student/student_assignments_screen.dart';
import '../screens/student/student_report_card_screen.dart';
import '../screens/student/student_announcements_screen.dart';
import '../screens/student/student_events_screen.dart';
// Parent
import '../screens/parent/parent_dashboard_screen.dart';
import '../screens/parent/parent_children_screen.dart';
import '../screens/parent/parent_child_detail_screen.dart';
import '../screens/parent/parent_child_grades_screen.dart';
import '../screens/parent/parent_child_attendance_screen.dart';
import '../screens/parent/parent_child_assignments_screen.dart';
import '../screens/parent/parent_child_report_card_screen.dart';
import '../screens/parent/parent_child_charges_screen.dart';
import '../screens/parent/parent_events_screen.dart';
// Secretary
import '../screens/secretary/secretary_dashboard_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _adminShellKey = GlobalKey<NavigatorState>();
final _teacherShellKey = GlobalKey<NavigatorState>();
final _studentShellKey = GlobalKey<NavigatorState>();
final _parentShellKey = GlobalKey<NavigatorState>();
final _secretaryShellKey = GlobalKey<NavigatorState>();
final _directorShellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final tenantState = ref.watch(tenantProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/auth/tenant',
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = authState.isAuthenticated;
      final inAuthRoute = state.matchedLocation.startsWith('/auth');

      // Si tenant no resuelto y no está en /auth/tenant, ir a /auth/tenant
      if (!tenantState.isResolved && state.matchedLocation != '/auth/tenant') {
        return '/auth/tenant';
      }

      // Si tenant resuelto y sigue en /auth/tenant, ir a login
      if (tenantState.isResolved && !loggedIn && state.matchedLocation == '/auth/tenant') {
        return '/auth/login';
      }

      // Si tenant resuelto pero no logueado y no en ruta auth, ir a login
      if (tenantState.isResolved && !loggedIn && !inAuthRoute) {
        return '/auth/login';
      }

      // Si logueado y en ruta auth, ir al dashboard por rol
      if (loggedIn && inAuthRoute) {
        final notifier = ref.read(authProvider.notifier);
        return notifier.getDashboardRoute();
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/tenant',
        name: 'tenant',
        builder: (context, state) => const TenantScreen(),
      ),

      // Admin shell
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/admin/students',
            builder: (context, state) => const StudentsManagementScreen(),
          ),
          GoRoute(
            path: '/admin/students/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return StudentDetailScreen(studentId: id);
            },
          ),
          GoRoute(
            path: '/admin/courses',
            builder: (context, state) => const CoursesManagementScreen(),
          ),
          GoRoute(
            path: '/admin/courses/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CourseDetailScreen(courseId: id);
            },
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Director shell (same screens as admin)
      ShellRoute(
        navigatorKey: _directorShellKey,
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/director/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/director/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/director/students',
            builder: (context, state) => const StudentsManagementScreen(),
          ),
          GoRoute(
            path: '/director/students/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return StudentDetailScreen(studentId: id);
            },
          ),
          GoRoute(
            path: '/director/courses',
            builder: (context, state) => const CoursesManagementScreen(),
          ),
          GoRoute(
            path: '/director/courses/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CourseDetailScreen(courseId: id);
            },
          ),
          GoRoute(
            path: '/director/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Secretary shell
      ShellRoute(
        navigatorKey: _secretaryShellKey,
        builder: (context, state, child) => SecretaryLayout(child: child),
        routes: [
          GoRoute(
            path: '/secretary/dashboard',
            builder: (context, state) => const SecretaryDashboardScreen(),
          ),
          GoRoute(
            path: '/secretary/students',
            builder: (context, state) => const StudentsManagementScreen(),
          ),
          GoRoute(
            path: '/secretary/students/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return StudentDetailScreen(studentId: id);
            },
          ),
          GoRoute(
            path: '/secretary/courses',
            builder: (context, state) => const CoursesManagementScreen(),
          ),
          GoRoute(
            path: '/secretary/courses/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CourseDetailScreen(courseId: id);
            },
          ),
          GoRoute(
            path: '/secretary/schedule',
            builder: (context, state) => const StudentScheduleScreen(),
          ),
          GoRoute(
            path: '/secretary/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Teacher shell
      ShellRoute(
        navigatorKey: _teacherShellKey,
        builder: (context, state, child) => TeacherLayout(child: child),
        routes: [
          GoRoute(
            path: '/teacher/dashboard',
            builder: (context, state) => const TeacherDashboardScreen(),
          ),
          GoRoute(
            path: '/teacher/courses',
            builder: (context, state) => const TeacherCoursesScreen(),
          ),
          GoRoute(
            path: '/teacher/courses/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              final name =
                  state.uri.queryParameters['name'] ?? 'Curso';
              return TeacherCourseDetailScreen(
                  courseId: id, courseName: name);
            },
          ),
          GoRoute(
            path: '/teacher/attendance',
            builder: (context, state) => const TeacherAttendanceScreen(),
          ),
          GoRoute(
            path: '/teacher/grades',
            builder: (context, state) => const TeacherGradesScreen(),
          ),
          GoRoute(
            path: '/teacher/assignments',
            builder: (context, state) => const TeacherAssignmentsScreen(),
          ),
          GoRoute(
            path: '/teacher/assignments/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return TeacherAssignmentDetailScreen(assignmentId: id);
            },
          ),
        ],
      ),

      // Student shell
      ShellRoute(
        navigatorKey: _studentShellKey,
        builder: (context, state, child) => StudentLayout(child: child),
        routes: [
          GoRoute(
            path: '/student/dashboard',
            builder: (context, state) => const StudentDashboardScreen(),
          ),
          GoRoute(
            path: '/student/courses',
            builder: (context, state) => const StudentCoursesScreen(),
          ),
          GoRoute(
            path: '/student/grades',
            builder: (context, state) => const StudentGradesScreen(),
          ),
          GoRoute(
            path: '/student/grades/report-card',
            builder: (context, state) => const StudentReportCardScreen(),
          ),
          GoRoute(
            path: '/student/assignments',
            builder: (context, state) => const StudentAssignmentsScreen(),
          ),
          GoRoute(
            path: '/student/schedule',
            builder: (context, state) => const StudentScheduleScreen(),
          ),
          GoRoute(
            path: '/student/attendance',
            builder: (context, state) => const StudentAttendanceScreen(),
          ),
          GoRoute(
            path: '/student/announcements',
            builder: (context, state) => const StudentAnnouncementsScreen(),
          ),
          GoRoute(
            path: '/student/events',
            builder: (context, state) => const StudentEventsScreen(),
          ),
          GoRoute(
            path: '/student/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Parent shell
      ShellRoute(
        navigatorKey: _parentShellKey,
        builder: (context, state, child) => ParentLayout(child: child),
        routes: [
          GoRoute(
            path: '/parent/dashboard',
            builder: (context, state) => const ParentDashboardScreen(),
          ),
          GoRoute(
            path: '/parent/children',
            builder: (context, state) => const ParentChildrenScreen(),
          ),
          GoRoute(
            path: '/parent/children/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return ParentChildDetailScreen(studentId: id);
            },
          ),
          GoRoute(
            path: '/parent/children/:id/grades',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return ParentChildGradesScreen(studentId: id);
            },
          ),
          GoRoute(
            path: '/parent/children/:id/attendance',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return ParentChildAttendanceScreen(studentId: id);
            },
          ),
          GoRoute(
            path: '/parent/children/:id/assignments',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return ParentChildAssignmentsScreen(studentId: id);
            },
          ),
          GoRoute(
            path: '/parent/children/:id/report-card',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return ParentChildReportCardScreen(studentId: id);
            },
          ),
          GoRoute(
            path: '/parent/children/:id/charges',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return ParentChildChargesScreen(studentId: id);
            },
          ),
          GoRoute(
            path: '/parent/events',
            builder: (context, state) => const ParentEventsScreen(),
          ),
          GoRoute(
            path: '/parent/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
