/// Type alias for backward compatibility
///
/// In this codebase, "Sweepstakes" and "Contest" refer to the same entity.
/// This file provides the Sweepstakes type as an alias to the Contest class
/// to maintain compatibility with code that uses the Sweepstakes naming.
///
/// Usage:
/// ```dart
/// import 'package:sweepfeed/core/models/sweepstake.dart';
///
/// Sweepstakes contest = Sweepstakes(...); // Same as Contest
/// ```
library;

import 'contest.dart';

/// Sweepstakes is an alias for Contest
/// All Contest properties and methods are available on Sweepstakes
typedef Sweepstakes = Contest;
