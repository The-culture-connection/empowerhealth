import 'package:flutter/material.dart';

class ProviderSearchScreen extends StatefulWidget {
  const ProviderSearchScreen({super.key});

  @override
  State<ProviderSearchScreen> createState() => _ProviderSearchScreenState();
}

class _ProviderSearchScreenState extends State<ProviderSearchScreen> {
  String _activeTab = 'all';
  final Map<String, dynamic> _filters = {
    'location': '',
    'insurance': '',
    'raceConcordance': false,
  };

  final List<Map<String, dynamic>> _providers = [
    {
      'name': 'Dr. Aisha Williams',
      'specialty': 'OB-GYN',
      'practice': 'Equity Maternal Health',
      'location': 'Berkeley, CA',
      'distance': '4.1 miles',
      'rating': 4.9,
      'reviews': 189,
      'acceptingNew': true,
      'languages': ['English'],
      'specialties': ['Cultural sensitivity', 'Birth trauma', 'VBAC support'],
      'hasBlackMamaTag': true,
      'raceMatch': true,
      'phone': '(510) 555-0142',
      'hours': 'Mon-Fri 8am-6pm',
      'priceRange': '\$\$',
      'recentReviews': [
        {
          'author': 'Jasmine M.',
          'rating': 5,
          'date': '2 weeks ago',
          'text': 'Dr. Williams took the time to listen to all my concerns and made me feel truly heard. She respected my birth plan and was so supportive throughout my pregnancy.',
          'helpful': 45,
        },
        {
          'author': 'Keisha R.',
          'rating': 5,
          'date': '1 month ago',
          'text': 'Finally found a provider who understands the unique challenges Black mothers face. She\'s knowledgeable, compassionate, and advocates fiercely for her patients.',
          'helpful': 38,
        },
      ],
    },
    {
      'name': 'Oakland Midwifery Collective',
      'specialty': 'Certified Nurse Midwife',
      'practice': 'Oakland Birth Center',
      'location': 'Oakland, CA',
      'distance': '2.8 miles',
      'rating': 5.0,
      'reviews': 156,
      'acceptingNew': true,
      'languages': ['English', 'Spanish', 'Mandarin'],
      'specialties': ['Home birth', 'Water birth', 'Gentle cesarean'],
      'hasBlackMamaTag': true,
      'raceMatch': false,
      'phone': '(510) 555-0198',
      'hours': '24/7 On-call',
      'priceRange': '\$\$\$',
      'recentReviews': [
        {
          'author': 'Maria S.',
          'rating': 5,
          'date': '3 days ago',
          'text': 'The entire team made my home birth experience magical. They were calm, encouraging, and respected every one of my wishes. I felt so empowered.',
          'helpful': 52,
        },
        {
          'author': 'Destiny L.',
          'rating': 5,
          'date': '1 week ago',
          'text': 'These midwives are phenomenal. They treated me like family and gave me the most beautiful, peaceful birth experience I could have hoped for.',
          'helpful': 41,
        },
      ],
    },
    {
      'name': 'Dr. Maria Johnson',
      'specialty': 'OB-GYN',
      'practice': 'Valley Health Center',
      'location': 'Oakland, CA',
      'distance': '2.3 miles',
      'rating': 4.8,
      'reviews': 234,
      'acceptingNew': true,
      'languages': ['English', 'Spanish'],
      'specialties': ['High-risk pregnancy', 'VBAC', 'Diabetes management'],
      'hasBlackMamaTag': false,
      'raceMatch': false,
      'phone': '(510) 555-0176',
      'hours': 'Mon-Fri 9am-5pm',
      'priceRange': '\$\$',
      'recentReviews': [
        {
          'author': 'Sarah P.',
          'rating': 5,
          'date': '4 days ago',
          'text': 'Dr. Johnson is incredibly thorough and patient. She explains everything in a way that\'s easy to understand and never makes you feel rushed.',
          'helpful': 29,
        },
        {
          'author': 'Anonymous',
          'rating': 4,
          'date': '2 weeks ago',
          'text': 'Great doctor, very knowledgeable about high-risk pregnancies. The office staff could be more organized, but Dr. Johnson herself is wonderful.',
          'helpful': 18,
        },
      ],
    },
    {
      'name': 'Destiny Williams, CD(DONA)',
      'specialty': 'Birth Doula',
      'practice': 'Sacred Journey Doula Services',
      'location': 'Oakland, CA',
      'distance': '3.2 miles',
      'rating': 5.0,
      'reviews': 127,
      'acceptingNew': true,
      'languages': ['English'],
      'specialties': ['VBAC support', 'Cultural sensitivity', 'Postpartum care'],
      'hasBlackMamaTag': true,
      'raceMatch': true,
      'phone': '(510) 555-0203',
      'hours': 'By appointment',
      'priceRange': '\$\$',
      'recentReviews': [
        {
          'author': 'Amara T.',
          'rating': 5,
          'date': '5 days ago',
          'text': 'Destiny was my rock during labor. She knew exactly what I needed before I even asked. Her presence was calming and empowering. Couldn\'t have done it without her!',
          'helpful': 67,
        },
        {
          'author': 'Nicole B.',
          'rating': 5,
          'date': '3 weeks ago',
          'text': 'She advocates for you when you need it most. Destiny helped me have the birth I wanted and supported me postpartum too. Worth every penny!',
          'helpful': 54,
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'All Providers', 'count': 4},
    {'id': 'obgyn', 'label': 'OB-GYNs', 'count': 2},
    {'id': 'midwife', 'label': 'Midwives', 'count': 1},
    {'id': 'doula', 'label': 'Doulas', 'count': 1},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF8F6F8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Hero Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF663399), Color(0xFF8855BB)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Find Your Care Team',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trusted providers reviewed by mothers like you',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search providers, specialties, or location',
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Pills
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = _activeTab == category['id'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => setState(() => _activeTab = category['id']),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF663399)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF663399)
                                          : Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${category['label']} (${category['count']})',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[700],
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Filters
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.filter_list,
                                    size: 16, color: const Color(0xFF663399)),
                                const SizedBox(width: 8),
                                const Text(
                                  'Filters',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FilterChip(
                                  icon: Icons.location_on,
                                  label: 'Near me',
                                  color: Colors.purple,
                                ),
                                _FilterChip(
                                  icon: Icons.check_circle,
                                  label: 'Accepting patients',
                                  color: Colors.green,
                                ),
                                _FilterChip(
                                  icon: Icons.favorite,
                                  label: 'Background match',
                                  isSelected: _filters['raceConcordance'],
                                  onTap: () => setState(() {
                                    _filters['raceConcordance'] =
                                        !_filters['raceConcordance'];
                                  }),
                                  color: Colors.blue,
                                ),
                                _FilterChip(
                                  icon: Icons.workspace_premium,
                                  label: 'Black Mama Approved',
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Provider Cards
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_providers.length} providers near you',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButton<String>(
                              value: 'Highest rated',
                              underline: const SizedBox(),
                              isDense: true,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Highest rated',
                                  child: Text('Highest rated'),
                                ),
                                DropdownMenuItem(
                                  value: 'Most reviewed',
                                  child: Text('Most reviewed'),
                                ),
                                DropdownMenuItem(
                                  value: 'Nearest',
                                  child: Text('Nearest'),
                                ),
                              ],
                              onChanged: (value) {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Provider List
                      ..._providers.map((provider) => _ProviderCard(
                            provider: provider,
                            raceConcordanceFilter: _filters['raceConcordance'],
                          )).toList(),
                      const SizedBox(height: 20),

                      // Community Trust Badge
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade50,
                              Colors.purple.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.blue.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.shield,
                                  color: Colors.blue.shade600, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Verified Reviews',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'All reviews come from verified patients. Share your experience anonymously to help other mothers make informed choices.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Write a review →',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF663399),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.shade50
              : (color == Colors.purple
                  ? Colors.purple.shade50
                  : color == Colors.green
                      ? Colors.green.shade50
                      : color == Colors.blue
                          ? Colors.blue.shade50
                          : Colors.red.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.shade200
                : (color == Colors.purple
                    ? Colors.purple.shade200
                    : color == Colors.green
                        ? Colors.green.shade200
                        : color == Colors.blue
                            ? Colors.blue.shade200
                            : Colors.red.shade200),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final Map<String, dynamic> provider;
  final bool raceConcordanceFilter;

  const _ProviderCard({
    required this.provider,
    required this.raceConcordanceFilter,
  });

  @override
  Widget build(BuildContext context) {
    final recentReview = provider['recentReviews'] != null &&
            (provider['recentReviews'] as List).isNotEmpty
        ? (provider['recentReviews'] as List)[0]
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Provider Image/Header
          Container(
            height: 128,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF663399).withOpacity(0.1),
                  const Color(0xFFCBBEC9).withOpacity(0.1),
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF663399), Color(0xFFCBBEC9)],
                      ),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        provider['name'][0],
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                if (provider['raceMatch'] == true && raceConcordanceFilter)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade500,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          const Text(
                            'Match',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Provider Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Tags
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${provider['specialty']} • ${provider['practice']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (provider['acceptingNew'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Text(
                          '✓ Accepting',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Black Mama Tag
                if (provider['hasBlackMamaTag'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade50,
                          Colors.pink.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium,
                            size: 16, color: Colors.red.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Black Mama Approved',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Rating
                Row(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star,
                            size: 20, color: Colors.amber.shade400),
                        const SizedBox(width: 4),
                        Text(
                          provider['rating'].toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${provider['reviews']} reviews)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    Text(' • ', style: TextStyle(color: Colors.grey[300])),
                    Text(
                      provider['priceRange'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: const Color(0xFF663399)),
                                const SizedBox(width: 8),
                                Text(
                                  provider['distance'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.phone,
                                    size: 16, color: const Color(0xFF663399)),
                                const SizedBox(width: 8),
                                Text(
                                  provider['phone']
                                      .toString()
                                      .substring(provider['phone']
                                              .toString()
                                              .length -
                                          8),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: const Color(0xFF663399)),
                          const SizedBox(width: 8),
                          Text(
                            provider['hours'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Specialties
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (provider['specialties'] as List)
                      .map<Widget>((specialty) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.purple.shade100),
                            ),
                            child: Text(
                              specialty,
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF663399),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Featured Review
                if (recentReview != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade50,
                          Colors.pink.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.pink.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.format_quote,
                                size: 16, color: Colors.red.shade400),
                            const SizedBox(width: 8),
                            Text(
                              'Recent review',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              Icons.star,
                              size: 14,
                              color: index < recentReview['rating']
                                  ? Colors.amber.shade400
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"${recentReview['text']}"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '— ${recentReview['author']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.thumb_up,
                                    size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  recentReview['helpful'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF663399),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('View Full Profile'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Icon(Icons.phone, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
