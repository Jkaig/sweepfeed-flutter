// SweepFeed Flutter App - Contest Display Widget
// This shows how to use the prepared contest data in your Flutter app

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Contest Model Class
class Contest {
  Contest({
    required this.id,
    required this.title,
    required this.description,
    required this.prize,
    required this.value,
    required this.valueDisplay,
    required this.sponsor,
    required this.sponsorVerified,
    required this.category,
    required this.categoryIcon,
    required this.categoryColor,
    required this.images,
    required this.entryUrl,
    required this.endDate,
    required this.endDateDisplay,
    required this.daysLeft,
    required this.entryFrequency,
    required this.entryMethods,
    required this.restrictions,
    required this.confidence,
    required this.featured,
    required this.isNew,
    required this.trending,
    required this.keywords,
    required this.searchText,
    this.thumbnailUrl,
    this.sponsorLogoUrl,
  });

  factory Contest.fromJson(Map<String, dynamic> json) => Contest(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        prize: json['prize'],
        value: json['value'],
        valueDisplay: json['valueDisplay'],
        sponsor: json['sponsor'],
        sponsorVerified: json['sponsorVerified'],
        category: json['category'],
        categoryIcon: json['categoryIcon'],
        categoryColor: json['categoryColor'],
        images: List<String>.from(json['images']),
        thumbnailUrl: json['thumbnailUrl'],
        sponsorLogoUrl: json['sponsorLogoUrl'],
        entryUrl: json['entryUrl'],
        endDate: json['endDate'],
        endDateDisplay: json['endDateDisplay'],
        daysLeft: json['daysLeft'],
        entryFrequency: json['entryFrequency'],
        entryMethods: List<String>.from(json['entryMethods']),
        restrictions: List<String>.from(json['restrictions']),
        confidence: json['confidence'],
        featured: json['featured'],
        isNew: json['new'],
        trending: json['trending'],
        keywords: List<String>.from(json['keywords']),
        searchText: json['searchText'],
      );
  final String id;
  final String title;
  final String description;
  final String prize;
  final int value;
  final String valueDisplay;
  final String sponsor;
  final bool sponsorVerified;
  final String category;
  final String categoryIcon;
  final String categoryColor;
  final List<String> images;
  final String? thumbnailUrl;
  final String? sponsorLogoUrl;
  final String entryUrl;
  final String endDate;
  final String endDateDisplay;
  final int daysLeft;
  final String entryFrequency;
  final List<String> entryMethods;
  final List<String> restrictions;
  final int confidence;
  final bool featured;
  final bool isNew;
  final bool trending;
  final List<String> keywords;
  final String searchText;
}

// Main Contest List Widget
class SweepFeedContestList extends StatefulWidget {
  const SweepFeedContestList({super.key});

  @override
  _SweepFeedContestListState createState() => _SweepFeedContestListState();
}

class _SweepFeedContestListState extends State<SweepFeedContestList> {
  List<Contest> contests = [];
  List<Contest> filteredContests = [];
  String selectedCategory = 'all';
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadContests();
  }

  Future<void> loadContests() async {
    // Load from local JSON file or Firebase
    final jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/FLUTTER_SWEEPFEED_DATA.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    setState(() {
      contests = (jsonData['contests'] as List)
          .map((contest) => Contest.fromJson(contest))
          .toList();
      filteredContests = contests;
      isLoading = false;
    });
  }

  void filterContests() {
    setState(() {
      filteredContests = contests.where((contest) {
        final matchesCategory =
            selectedCategory == 'all' || contest.category == selectedCategory;
        final matchesSearch = searchQuery.isEmpty ||
            contest.searchText.contains(searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('SweepFeed - Win Prizes!'),
          backgroundColor: Colors.deepPurple,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search contests...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    filterContests();
                  });
                },
              ),
            ),

            // Category Chips
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('all', 'All', Colors.blue),
                  _buildCategoryChip('cash', 'Cash', Colors.green),
                  _buildCategoryChip(
                      'electronics', 'Electronics', Colors.orange),
                  _buildCategoryChip('travel', 'Travel', Colors.purple),
                  _buildCategoryChip('vehicle', 'Vehicles', Colors.red),
                  _buildCategoryChip('gift_card', 'Gift Cards', Colors.pink),
                ],
              ),
            ),

            // Contest List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredContests.length,
                      itemBuilder: (context, index) =>
                          ContestCard(contest: filteredContests[index]),
                    ),
            ),
          ],
        ),
      );

  Widget _buildCategoryChip(String category, String label, Color color) {
    final isSelected = selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedCategory = category;
            filterContests();
          });
        },
        backgroundColor: isSelected ? color : Colors.grey[300],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Filter Contests'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Ending Soon'),
              leading: Radio(value: 'ending'),
            ),
            ListTile(
              title: Text('High Value (\\>\$1000)'),
              leading: Radio(value: 'high'),
            ),
            ListTile(
              title: Text('Featured Only'),
              leading: Radio(value: 'featured'),
            ),
          ],
        ),
      ),
    );
  }
}

// Individual Contest Card Widget
class ContestCard extends StatelessWidget {
  const ContestCard({required this.contest, super.key});
  final Contest contest;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _launchUrl(contest.entryUrl),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contest Image
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: contest.thumbnailUrl ?? contest.images.first,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges Row
                    Row(
                      children: [
                        if (contest.featured)
                          _buildBadge('FEATURED', Colors.amber),
                        if (contest.isNew) _buildBadge('NEW', Colors.green),
                        if (contest.trending)
                          _buildBadge('TRENDING', Colors.red),
                        const Spacer(),
                        _buildCategoryBadge(contest),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Title
                    Text(
                      contest.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Description
                    Text(
                      contest.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Prize Value and Days Left
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prize Value',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            Text(
                              contest.valueDisplay,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Ends in',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            Text(
                              '${contest.daysLeft} days',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: contest.daysLeft <= 7
                                    ? Colors.red
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Sponsor Info
                    Row(
                      children: [
                        Icon(Icons.business, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          contest.sponsor,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (contest.sponsorVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 16, color: Colors.blue),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Enter Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _launchUrl(contest.entryUrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Enter Contest',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

  Widget _buildCategoryBadge(Contest contest) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Color(int.parse(contest.categoryColor.replaceAll('#', '0x'))),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              contest.categoryIcon,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              contest.category.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
