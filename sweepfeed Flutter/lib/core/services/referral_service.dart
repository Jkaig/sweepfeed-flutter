class ReferralService {
  // In a real app, you would use a service like Firebase Dynamic Links.
  // For now, we'll create a simple placeholder link.
  Future<String> generateReferralLink(String userId) async {
    // This is a placeholder. A real implementation would be more robust.
    const baseUrl = 'https://sweepfeed.page.link';
    return '$baseUrl/refer?userId=$userId';
  }
}
