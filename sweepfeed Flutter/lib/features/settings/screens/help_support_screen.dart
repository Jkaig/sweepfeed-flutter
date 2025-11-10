import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final Map<int, bool> _expandedFAQs = {};
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I enter a sweepstakes?',
      'answer':
          'Simply browse available sweepstakes on the home screen and tap "Enter" on any that interest you. Make sure to read the entry requirements and terms before entering.',
    },
    {
      'question': 'Are there any entry limits?',
      'answer':
          'Each sweepstakes has its own entry rules. Some allow one entry per person, while others may allow daily entries. Check the specific sweepstakes details for entry limits.',
    },
    {
      'question': 'How are winners selected?',
      'answer':
          'Winners are selected randomly from all eligible entries. The selection process is fair and transparent, and all entries have an equal chance of winning.',
    },
    {
      'question': 'When will I know if I won?',
      'answer':
          'Winners are notified via email and in-app notification. Check the specific sweepstakes for the winner announcement date. Make sure your notifications are enabled.',
    },
    {
      'question': 'Is SweepFeed free to use?',
      'answer':
          'Yes, SweepFeed is completely free to download and use. There are no hidden fees or charges for entering sweepstakes.',
    },
    {
      'question': 'How do I claim my prize if I win?',
      'answer':
          "If you win, you'll receive detailed instructions via email. Prizes are typically shipped directly to your verified address or provided as digital codes.",
    },
    {
      'question': 'Can I increase my chances of winning?',
      'answer':
          'While each entry has equal chances, you can enter more sweepstakes to increase your overall opportunities. Refer friends to earn bonus entries in some sweepstakes.',
    },
    {
      'question': 'What countries are supported?',
      'answer':
          "Currently, SweepFeed is available in the United States and Canada. We're working on expanding to more countries soon.",
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchEmail() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'support@sweepfeed.com',
      query: 'subject=SweepFeed Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch email client'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _submitSupportRequest() async {
    if (_formKey.currentState!.validate()) {
      // Simulate sending support request
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Support request sent successfully!'),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: const CustomAppBar(
          title: 'Help & Support',
          leading: CustomBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FAQ Section
              Card(
                color: AppColors.primaryMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.brandCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            color: AppColors.brandCyan,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Frequently Asked Questions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(_faqs.length, _buildFAQItem),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Contact Support Section
              Card(
                color: AppColors.primaryMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.brandCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.contact_support_outlined,
                            color: AppColors.brandCyan,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Contact Support',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Need personalized help? Get in touch with our support team.',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Contact Options
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.brandCyan,
                                    AppColors.brandCyanDark,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _launchEmail,
                                icon:
                                    const Icon(Icons.email_outlined, size: 18),
                                label: const Text('Email Support'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: AppColors.primaryDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Contact Form
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.brandCyan.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Send us a message',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Name Field
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Your Name',
                                  labelStyle: const TextStyle(
                                      color: AppColors.textLight),
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: AppColors.brandCyan,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: AppColors.primaryLight),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: AppColors.primaryLight),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.brandCyan,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.primaryMedium,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Your Email',
                                  labelStyle: const TextStyle(
                                      color: AppColors.textLight),
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: AppColors.brandCyan,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: AppColors.primaryLight),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: AppColors.primaryLight),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.brandCyan,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.primaryMedium,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Message Field
                              TextFormField(
                                controller: _messageController,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: 'Your Message',
                                  labelStyle: const TextStyle(
                                      color: AppColors.textLight),
                                  prefixIcon: const Icon(
                                    Icons.message_outlined,
                                    color: AppColors.brandCyan,
                                  ),
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: AppColors.primaryLight),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: AppColors.primaryLight),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.brandCyan,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.primaryMedium,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your message';
                                  }
                                  if (value.length < 10) {
                                    return 'Message must be at least 10 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.brandCyan,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _submitSupportRequest,
                                    icon: const Icon(Icons.send, size: 18),
                                    label: const Text('Send Message'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: AppColors.brandCyan,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildFAQItem(int index) {
    final faq = _faqs[index];
    final isExpanded = _expandedFAQs[index] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? AppColors.brandCyan.withValues(alpha: 0.5)
              : AppColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isExpanded
                    ? AppColors.brandCyan.withValues(alpha: 0.2)
                    : AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isExpanded ? Icons.help : Icons.help_outline,
                color: isExpanded ? AppColors.brandCyan : AppColors.textLight,
                size: 16,
              ),
            ),
            title: Text(
              faq['question']!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            trailing: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: isExpanded ? AppColors.brandCyan : AppColors.textLight,
              ),
            ),
            onTap: () {
              setState(() {
                _expandedFAQs[index] = !isExpanded;
              });
            },
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isExpanded ? null : 0,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      faq['answer']!,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
