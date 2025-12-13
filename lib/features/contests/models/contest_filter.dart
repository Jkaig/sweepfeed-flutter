enum ContestFilter {
  highValue,
  endingSoon,
  dailyEntry,
  easyEntry,
  trending,
  newToday,
}

extension ContestFilterExtension on ContestFilter {
  String get label {
    switch (this) {
      case ContestFilter.highValue:
        return 'High Value';
      case ContestFilter.endingSoon:
        return 'Ending Soon';
      case ContestFilter.dailyEntry:
        return 'Daily Entry';
      case ContestFilter.easyEntry:
        return 'Easy Entry';
      case ContestFilter.trending:
        return 'Trending';
      case ContestFilter.newToday:
        return 'New Today';
    }
  }

  String get description {
    switch (this) {
      case ContestFilter.highValue:
        return 'Contests worth \$1,000+';
      case ContestFilter.endingSoon:
        return 'Ending within 7 days';
      case ContestFilter.dailyEntry:
        return 'Enter every day';
      case ContestFilter.easyEntry:
        return 'Quick & simple to enter';
      case ContestFilter.trending:
        return 'Popular right now';
      case ContestFilter.newToday:
        return 'Added today';
    }
  }
}
