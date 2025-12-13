class AdminPermissions {

  const AdminPermissions({
    this.canManageUsers = false,
    this.canManageSupportTickets = false,
    this.canManageWinnerClaims = false,
    this.canManageContests = false,
    this.canViewAnalytics = false,
    this.canManageSettings = false,
  });

  factory AdminPermissions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AdminPermissions();
    return AdminPermissions(
      canManageUsers: map['canManageUsers'] ?? false,
      canManageSupportTickets: map['canManageSupportTickets'] ?? false,
      canManageWinnerClaims: map['canManageWinnerClaims'] ?? false,
      canManageContests: map['canManageContests'] ?? false,
      canViewAnalytics: map['canViewAnalytics'] ?? false,
      canManageSettings: map['canManageSettings'] ?? false,
    );
  }
  final bool canManageUsers;
  final bool canManageSupportTickets;
  final bool canManageWinnerClaims;
  final bool canManageContests;
  final bool canViewAnalytics;
  final bool canManageSettings;

  // Full admin permissions (superadmin only)
  static const AdminPermissions full = AdminPermissions(
    canManageUsers: true,
    canManageSupportTickets: true,
    canManageWinnerClaims: true,
    canManageContests: true,
    canViewAnalytics: true,
    canManageSettings: true,
  );

  // Support admin - can only manage support tickets
  static const AdminPermissions supportOnly = AdminPermissions(
    canManageSupportTickets: true,
  );

  // Winner claims moderator - can only manage winner claims
  static const AdminPermissions winnerClaimsOnly = AdminPermissions(
    canManageWinnerClaims: true,
  );

  // User moderator - can manage users but not other admins
  static const AdminPermissions userModerator = AdminPermissions(
    canManageUsers: true,
  );

  Map<String, dynamic> toMap() => {
        'canManageUsers': canManageUsers,
        'canManageSupportTickets': canManageSupportTickets,
        'canManageWinnerClaims': canManageWinnerClaims,
        'canManageContests': canManageContests,
        'canViewAnalytics': canViewAnalytics,
        'canManageSettings': canManageSettings,
      };

  AdminPermissions copyWith({
    bool? canManageUsers,
    bool? canManageSupportTickets,
    bool? canManageWinnerClaims,
    bool? canManageContests,
    bool? canViewAnalytics,
    bool? canManageSettings,
  }) =>
      AdminPermissions(
        canManageUsers: canManageUsers ?? this.canManageUsers,
        canManageSupportTickets: canManageSupportTickets ?? this.canManageSupportTickets,
        canManageWinnerClaims: canManageWinnerClaims ?? this.canManageWinnerClaims,
        canManageContests: canManageContests ?? this.canManageContests,
        canViewAnalytics: canViewAnalytics ?? this.canViewAnalytics,
        canManageSettings: canManageSettings ?? this.canManageSettings,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminPermissions &&
          runtimeType == other.runtimeType &&
          canManageUsers == other.canManageUsers &&
          canManageSupportTickets == other.canManageSupportTickets &&
          canManageWinnerClaims == other.canManageWinnerClaims &&
          canManageContests == other.canManageContests &&
          canViewAnalytics == other.canViewAnalytics &&
          canManageSettings == other.canManageSettings;

  @override
  int get hashCode =>
      canManageUsers.hashCode ^
      canManageSupportTickets.hashCode ^
      canManageWinnerClaims.hashCode ^
      canManageContests.hashCode ^
      canViewAnalytics.hashCode ^
      canManageSettings.hashCode;
}
