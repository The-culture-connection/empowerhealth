import 'package:flutter/material.dart';
import '../app_router.dart';
import '../cors/ui_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<_TodoItem> _todos = [
    _TodoItem('First Trimester Module'),
    _TodoItem('First Trimester Module'),
    _TodoItem('First Trimester Module'),
    _TodoItem('First Trimester Module'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/homescreen.jpeg', fit: BoxFit.cover),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Welcome',
                        style: const TextStyle(
                          fontFamily: 'Primary',
                          fontSize: 70,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.brandGold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        iconSize: 36,
                        icon: const Icon(
                          Icons.mic_none_rounded,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _GlassCard(
                          onTap: () => Navigator.pushNamed(context, Routes.appointments),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              _CardTitle('Appointments:'),
                              SizedBox(height: 8),
                              Text('Nov, 29\n6:00pm\n\nFirst Trimester\nCheck-up',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _GlassCard(
                          onTap: () => Navigator.pushNamed(context, Routes.messages),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              _CardTitle('Messages:'),
                              SizedBox(height: 8),
                              Text('PHP: Hey How\nis it going', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _GlassCard(
                      onTap: () => Navigator.pushNamed(context, Routes.learning),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CardTitle('To do:'),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.separated(
                              itemBuilder: (context, index) {
                                final item = _todos[index];
                                return GestureDetector(
                                  onTap: () => setState(() => item.done = !item.done),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.done ? Icons.check_circle : Icons.circle_outlined,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemCount: _todos.length,
                            ),
                          )
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
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;
  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Primary',
        color: AppTheme.brandGold,
        fontSize: 30,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _GlassCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.brandPurple.withOpacity(0.65),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: card,
    );
  }
}

class _TodoItem {
  final String title;
  bool done;
  _TodoItem(this.title, {this.done = false});
}
