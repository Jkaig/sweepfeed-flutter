import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweep_feed/core/models/category_model.dart';
import 'package:sweep_feed/core/models/contest_model.dart';
import 'package:sweep_feed/core/theme/app_colors.dart';
import 'package:sweep_feed/core/theme/app_text_styles.dart';
import 'package:sweep_feed/core/widgets/loading_indicator.dart';
import 'package:sweep_feed/features/contests/services/contest_service.dart';
import 'package:sweep_feed/features/contests/widgets/category_card.dart';
import 'package:sweep_feed/features/contests/widgets/contest_card.dart';
import 'package:sweep_feed/features/contests/widgets/home_search_bar.dart';
import 'package:sweep_feed/features/dashboard/widgets/daily_stats_card.dart';
import 'package:sweep_feed/features/auth/services/user_service.dart';
import 'package:sweep_feed/core/services/firebase_service.dart';
import 'package:sweep_feed/features/checklist/services/checklist_service.dart';
import 'package:sweep_feed/features/contests/widgets/interactive_daily_checklist_item.dart';
import 'package:sweep_feed/features/contests/screens/contest_detail_screen.dart';
import 'package:sweep_feed/features/contests/screens/submit_contest_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Contest> _featuredContests = [];
  List<Contest> _latestContests = [];
  String? _userName;
  int _entriesUsed = 2;
  int _entriesLimit = 10;
  int _userLevel = 5;
  double _todaysBestPrize = 1500;

  List<Contest> _dailyChecklistContests = [];
  Map<String, bool> _checklistCompletionStatus = {};
  Set<String> _hiddenChecklistItems = {};
  bool _isChecklistLoading = true;
  final ChecklistService _checklistService = ChecklistService();
  String? _currentUserId;

  final List<Category> _categories = const [
    Category(id: '1', name: 'Gift Cards', icon: Icons.card_giftcard),
    Category(id: '2', name: 'Electronics', icon: Icons.phone_iphone),
    Category(id: '3', name: 'Cash', icon: Icons.attach_money),
    Category(id: '4', name: 'Vacations', icon: Icons.beach_access),
    Category(id: '5', name: 'Gaming', icon: Icons.sports_esports),
  ];

  @override
  void initState() {
    super.initState();
    _currentUserId = Provider.of<FirebaseService>(context, listen: false).currentUser?.uid;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isChecklistLoading = true;
    });
    try {
      final contestService = Provider.of<ContestService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);
      
      final featured = await contestService.getFeaturedContests(limit: 5).first;
      
      Stream<List<Contest>> latestStream;
      if (_currentUserId != null) {
        latestStream = contestService.getContests(userId: _currentUserId!, limit: 10, orderBy: 'createdAt', descending: true);
      } else {
        latestStream = contestService.getContests(limit: 10, orderBy: 'createdAt', descending: true);
      }
      final latest = await latestStream.first;
      
      final userData = await userService.getCurrentUserData();
      _userName = userData?['displayName'] as String? ?? 'SweepFeeder';
      
      if (_currentUserId != null) {
        final checklistContestsFuture = contestService.getDailyChecklistContests(limit: 5);
        final completionStatusFuture = _checklistService.getCompletionStatus(_currentUserId!, DateTime.now());
        final hiddenItemsFuture = _checklistService.getHiddenItems(_currentUserId!, DateTime.now());
        
        final results = await Future.wait([checklistContestsFuture.first, completionStatusFuture, hiddenItemsFuture]);
        _dailyChecklistContests = results[0] as List<Contest>;
        _checklistCompletionStatus = results[1] as Map<String, bool>;
        _hiddenChecklistItems = results[2] as Set<String>;
      }
      
      setState(() {
        _featuredContests = featured;
        _latestContests = latest;
        _isLoading = false;
        _isChecklistLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading home screen data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isChecklistLoading = false;
        });
      }
    }
  }

  Future<void> _toggleChecklistItemComplete(String contestId) async {
    if (_currentUserId == null) return;
    final currentStatus = _checklistCompletionStatus[contestId] ?? false;
    setState(() {
      _checklistCompletionStatus[contestId] = !currentStatus;
    });
    await _checklistService.updateCompletionStatus(_currentUserId!, contestId, !currentStatus, DateTime.now());
  }

  Future<void> _hideChecklistItem(String contestId) async {
    if (_currentUserId == null) return;
    setState(() {
      _hiddenChecklistItems.add(contestId);
    });
    await _checklistService.hideItem(_currentUserId!, contestId, DateTime.now());
  }

  Future<void> _refreshChecklist() async { 
    if (_currentUserId == null) return;
    setState(() => _isChecklistLoading = true);
    _hiddenChecklistItems.clear(); 
    final contests = await Provider.of<ContestService>(context, listen: false).getDailyChecklistContests(limit: 5).first;
    final completionStatus = await _checklistService.getCompletionStatus(_currentUserId!, DateTime.now());
    final hiddenItems = await _checklistService.getHiddenItems(_currentUserId!, DateTime.now());

    setState(() {
      _dailyChecklistContests = contests;
      _checklistCompletionStatus = completionStatus;
      _hiddenChecklistItems = hiddenItems; 
      _isChecklistLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.headlineSmall),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text('View All', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accent,
        backgroundColor: AppColors.primaryMedium,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.primaryDark,
              expandedHeight: 130.0, 
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primaryMedium.withOpacity(0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 12), 
                title: SafeArea( 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        'Good morning, ${_userName ?? "User"}!', 
                        style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      HomeSearchBar(
                        controller: _searchController,
                        onSubmitted: (query) {
                          debugPrint("Search submitted: $query");
                        },
                        onFilterPressed: () {
                           debugPrint("Filter pressed");
                        },
                      ),
                    ],
                  ),
                ),
                centerTitle: false, 
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(child: Center(child: LoadingIndicator())),

            if (!_isLoading) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DailyStatsCard(
                    entriesUsed: _entriesUsed,
                    entriesLimit: _entriesLimit,
                    userLevel: _userLevel,
                    todaysBestPrize: _todaysBestPrize,
                  ),
                ),
              ),

              _buildSectionHeader("Today's Checklist", onViewAll: _refreshChecklist),
              SliverToBoxAdapter(
                child: _isChecklistLoading
                    ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: LoadingIndicator()))
                    : _dailyChecklistContests.where((c) => !_hiddenChecklistItems.contains(c.id)).isEmpty
                        ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("No checklist items for today.", style: AppTextStyles.bodyMedium)))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _dailyChecklistContests.where((c) => !_hiddenChecklistItems.contains(c.id)).length,
                            itemBuilder: (context, index) {
                              final contest = _dailyChecklistContests.where((c) => !_hiddenChecklistItems.contains(c.id)).toList()[index];
                              return InteractiveDailyChecklistItem(
                                contest: contest,
                                isCompleted: _checklistCompletionStatus[contest.id] ?? false,
                                onToggleComplete: _toggleChecklistItemComplete,
                                onHide: _hideChecklistItem,
                                onViewDetails: (selectedContest) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ContestDetailScreen(contestId: selectedContest.id)));
                                },
                              );
                            },
                          ),
              ),
              
              _buildSectionHeader('Featured Today', onViewAll: () {}),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 310, 
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _featuredContests.length,
                    itemBuilder: (context, index) {
                      return SizedBox( 
                        width: MediaQuery.of(context).size.width * 0.85, 
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0), 
                          child: ContestCard(contest: _featuredContests[index]),
                        ),
                      );
                    },
                  ),
                ),
              ),

              _buildSectionHeader('Browse Categories'),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140, 
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0), 
                        child: CategoryCard(
                          category: _categories[index],
                          onTap: () {
                            debugPrint("Category tapped: ${_categories[index].name}");
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)), 

              _buildSectionHeader('Latest Contests', onViewAll: () {}),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ContestCard(contest: _latestContests[index]),
                    );
                  },
                  childCount: _latestContests.length,
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 20)), 
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitContestScreen()));
        },
        backgroundColor: AppColors.accent,
        child: Icon(Icons.add, color: AppColors.primaryDark),
        tooltip: 'Submit a Sweepstake',
      ),
    );
  }
}
