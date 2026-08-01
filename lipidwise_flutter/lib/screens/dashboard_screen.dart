import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final String role;
  
  const DashboardScreen({super.key, required this.result, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getRiskColor(String category) {
    if (category.contains('Emergency') || category.contains('Very High') || category.contains('High')) return const Color(0xFFE11D48); // Rose-600
    if (category.contains('Moderate')) return const Color(0xFFF59E0B); // Amber-500
    return const Color(0xFF10B981); // Emerald-500
  }

  LinearGradient _getRiskGradient(String category) {
    if (category.contains('Emergency') || category.contains('Very High') || category.contains('High')) {
      return const LinearGradient(colors: [Color(0xFFFEF2F2), Color(0xFFFFE4E6)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
    if (category.contains('Moderate')) {
      return const LinearGradient(colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
    return const LinearGradient(colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  }

  Widget _buildHoverCard({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(24)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF94A3B8).withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLipidWidget(String title, double? value, double target, bool isHdl) {
    bool isBad = false;
    if (value != null) {
      if (isHdl) {
         isBad = value < target;
      } else {
         isBad = value > target;
      }
    }
    Color statColor = isBad ? const Color(0xFFE11D48) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: statColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(isBad ? Icons.priority_high_rounded : Icons.check_rounded, color: statColor, size: 16),
              )
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value?.toStringAsFixed(0) ?? '--', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -1)),
              const SizedBox(width: 4),
              const Text('mg/dL', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value == null ? 0 : (value / (target * 2)).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              color: statColor,
              minHeight: 6,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGuidelineCard(String title, IconData icon, String subtitle, String corBadge, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: themeColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: themeColor, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: Text(corBadge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String badge, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(12)),
            child: Text(badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color riskColor = _getRiskColor(widget.result['category'] ?? 'Low');
    bool isRuleBased = widget.result['typeBadge']?.toString().contains('Clinical') ?? false;
    List<dynamic> breakdown = widget.result['breakdown'] ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mark_chat_unread_rounded),
        label: const Text('Ask AI Coach', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(children: [Icon(Icons.smart_toy_rounded, color: Color(0xFF2563EB)), SizedBox(width: 12), Text('LipidWise AI Coach')]),
              content: const Text('Hello! Ask me any questions about 2026 ACC/AHA guidelines, PREVENT risk, or healthy food swaps.\n\n(This chatbot feature is simulated for the hackathon prototype)'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
              ],
            ),
          );
        },
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 14, color: Color(0xFF2563EB)),
                              SizedBox(width: 6),
                              Text('AI-Powered Analysis', style: TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Patient Dashboard', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -1)),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                        label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 32),
                
                // Gradient Alert Banner
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: _getRiskGradient(widget.result['category'] ?? 'Low'),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                    boxShadow: [
                      BoxShadow(color: riskColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                          BoxShadow(color: riskColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))
                        ]),
                        child: Icon(Icons.health_and_safety_rounded, color: riskColor, size: 32),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.result['category']} Risk Level Detected',
                              style: TextStyle(color: riskColor.withOpacity(0.9), fontWeight: FontWeight.w800, fontSize: 20),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.result['message'] ?? '', 
                              style: TextStyle(color: const Color(0xFF1E293B).withOpacity(0.8), fontSize: 15, height: 1.5),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 800;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gauge Card
                        Expanded(
                          flex: isWide ? 4 : 0,
                          child: _buildHoverCard(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('RISK SCORE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                                      child: Text(widget.result['typeBadge'] ?? '', style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  height: 220,
                                  width: 220,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: SizedBox(
                                          width: 220, height: 220,
                                          child: CircularProgressIndicator(value: 1, color: const Color(0xFFF8FAFC), strokeWidth: 16),
                                        ),
                                      ),
                                      Center(
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween<double>(begin: 0, end: widget.result['gaugeValue'] ?? 0.0),
                                          duration: const Duration(milliseconds: 1500),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, value, _) => SizedBox(
                                            width: 220, height: 220,
                                            child: CircularProgressIndicator(
                                              value: value, 
                                              color: riskColor, 
                                              strokeWidth: 16, 
                                              strokeCap: StrokeCap.round,
                                              backgroundColor: Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.monitor_heart_outlined, color: riskColor, size: 32),
                                            const SizedBox(height: 8),
                                            Text(
                                              widget.result['category']?.split(' ').join('\n') ?? '', 
                                              textAlign: TextAlign.center, 
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF0F172A), height: 1.1)
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        if (isWide) const SizedBox(width: 32),
                        if (!isWide) const SizedBox(height: 32),
                        
                        // Specific Lipid Breakdown OR ML Factors
                        Expanded(
                          flex: isWide ? 6 : 0,
                          child: isRuleBased
                            ? GridView.count(
                                crossAxisCount: isWide ? 2 : 2,
                                shrinkWrap: true,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 1.4,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                   _buildLipidWidget('LDL-C (Bad)', breakdown.isNotEmpty ? double.tryParse(breakdown.firstWhere((b) => b['marker'] == 'LDL-C')['value'].toString()) : null, 130, false),
                                   _buildLipidWidget('HDL-C (Good)', breakdown.isNotEmpty ? double.tryParse(breakdown.firstWhere((b) => b['marker'] == 'HDL-C')['value'].toString()) : null, 40, true),
                                   _buildLipidWidget('Triglycerides', breakdown.isNotEmpty ? double.tryParse(breakdown.firstWhere((b) => b['marker'] == 'Triglycerides')['value'].toString()) : null, 150, false),
                                   _buildLipidWidget('Total Chol', breakdown.isNotEmpty ? double.tryParse(breakdown.firstWhere((b) => b['marker'] == 'Total Cholesterol')['value'].toString()) : null, 200, false),
                                ],
                              )
                            : _buildHoverCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                          child: const Icon(Icons.analytics_rounded, color: Color(0xFFF59E0B)),
                                        ),
                                        const SizedBox(width: 16),
                                        const Text('Top ML Risk Factors', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('The AI model pinpointed these leading factors driving the risk score based on lifestyle history.', style: TextStyle(color: Color(0xFF64748B), fontSize: 15, height: 1.5)),
                                    const SizedBox(height: 24),
                                    if (widget.result['topFactors'] != null)
                                      ...((widget.result['topFactors'] as List).map((f) => Padding(
                                        padding: const EdgeInsets.only(bottom: 16.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.track_changes_rounded, color: Color(0xFF3B82F6), size: 20),
                                              const SizedBox(width: 16),
                                              Text(f['name'], style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 16)),
                                            ],
                                          ),
                                        ),
                                      ))),
                                  ],
                                ),
                              ),
                        ),
                      ],
                    );
                  }
                ),

                const SizedBox(height: 32),
                // AI Coach Plan
                _buildHoverCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 20),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AI Prevention Coach', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                              SizedBox(height: 4),
                              Text('Actionable steps to lower lipid risk', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isWide = constraints.maxWidth > 700;
                          return Flex(
                            direction: isWide ? Axis.horizontal : Axis.vertical,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.restaurant_menu_rounded, size: 18, color: Color(0xFF94A3B8)),
                                        SizedBox(width: 8),
                                        Text('NUTRITION SWAPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (widget.result['swaps'] != null)
                                      ...((widget.result['swaps'] as List).map((s) => Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), shape: BoxShape.circle),
                                              child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 14),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(child: Text(s['from'], style: const TextStyle(color: Color(0xFF64748B), decoration: TextDecoration.lineThrough, fontSize: 14))),
                                            const Icon(Icons.arrow_forward_rounded, color: Color(0xFFCBD5E1), size: 16),
                                            const SizedBox(width: 12),
                                            Expanded(child: Text(s['to'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 14))),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                                              child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 14),
                                            ),
                                          ],
                                        ),
                                      ))),
                                  ],
                                ),
                              ),
                              if (isWide) const SizedBox(width: 40),
                              if (!isWide) const SizedBox(height: 40),
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.task_alt_rounded, size: 18, color: Color(0xFF94A3B8)),
                                        SizedBox(width: 8),
                                        Text('WEEKLY LIFESTYLE PLAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (widget.result['plan'] != null)
                                      ...((widget.result['plan'] as List).map((p) => Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFFCBD5E1), size: 20),
                                            const SizedBox(width: 16),
                                            Expanded(child: Text(p['desc'], style: const TextStyle(color: Color(0xFF334155), fontSize: 15, height: 1.4))),
                                          ],
                                        ),
                                      ))),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                // 2026 ACC/AHA Guidelines
                _buildHoverCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.monitor_heart_rounded, color: Color(0xFFDC2626), size: 28),
                          SizedBox(width: 16),
                          Text('2026 ACC/AHA Recommendation Highlights', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(builder: (context, constraints) {
                        bool isWide = constraints.maxWidth > 600;
                        return GridView.count(
                          crossAxisCount: isWide ? 2 : 1,
                          shrinkWrap: true,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: isWide ? 1.8 : 2.5,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildGuidelineCard('PREVENT™ Risk Calculator', Icons.calculate_rounded, 'Requires age 30-79 without known ASCVD.', 'COR 1 | LOE B-NR', const Color(0xFF3B82F6)),
                            _buildGuidelineCard('Lipoprotein(a) [Lp(a)]', Icons.vaccines_rounded, 'Measure at least once in all adults for ASCVD risk assessment (Cutoff: ≥125 nmol/L).', 'COR 1 | LOE B-NR', const Color(0xFF8B5CF6)),
                            _buildGuidelineCard('Coronary Artery Calcium (CAC)', Icons.document_scanner_rounded, 'Recommended for adults with 10-yr risk ≥3% with uncertainty about LLT.', 'COR 1 | LOE B-R', const Color(0xFFF59E0B)),
                            _buildGuidelineCard('LLT Escalation Targets', Icons.medication_rounded, 'In clinical ASCVD not at target: Add Ezetimibe, PCSK9 inhibitors, or Bempedoic Acid.', 'COR 1-2', const Color(0xFF10B981)),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Screening Schedule
                _buildHoverCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB), size: 28),
                          SizedBox(width: 16),
                          Text('Recommended Screening & Retesting Schedule', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(builder: (context, constraints) {
                        bool isWide = constraints.maxWidth > 800;
                        return Flex(
                          direction: isWide ? Axis.horizontal : Axis.vertical,
                          children: [
                            Expanded(flex: isWide ? 1 : 0, child: _buildScheduleItem('Retesting', '4–12 Weeks', 'Repeat lipid profile after LLT initiation or dose adjustment.')),
                            if (isWide) const SizedBox(width: 24),
                            if (!isWide) const SizedBox(height: 16),
                            Expanded(flex: isWide ? 1 : 0, child: _buildScheduleItem('Maintenance', '6–12 Months', 'Routine lipid testing to assess ongoing therapeutic response.')),
                            if (isWide) const SizedBox(width: 24),
                            if (!isWide) const SizedBox(height: 16),
                            Expanded(flex: isWide ? 1 : 0, child: _buildScheduleItem('Screening', 'Age 9–11 & q5yr', 'Universal screening at age 9–11, then every 5 years from age 19.')),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
