import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final String role;
  
  const DashboardScreen({super.key, required this.result, required this.role});

  Color _getRiskColor(String category) {
    if (category == 'Emergency' || category == 'Very High' || category == 'High') return Colors.redAccent;
    if (category == 'Moderate') return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    Color riskColor = _getRiskColor(result['category'] ?? 'Low');

    return Scaffold(
      appBar: AppBar(
        title: Text('Results Dashboard - $role View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
               // Print action logic here
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting report...')));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Alert Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: riskColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: riskColor, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result['category']} Concern',
                          style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(result['message'] ?? '', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Risk Gauge Area (Simplified with LinearProgressIndicator for Flutter prototype)
            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('Risk Level Indicator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: result['gaugeValue'] ?? 0.0,
                      minHeight: 12,
                      backgroundColor: Colors.white12,
                      color: riskColor,
                    ),
                    const SizedBox(height: 10),
                    Text(result['typeBadge'] ?? '', style: const TextStyle(color: Colors.blueAccent)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Render Clinical Table if available
            if (result['breakdown'] != null) ...[
              const Text('Clinical Lipid Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                color: const Color(0xFF1E293B),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: result['breakdown'].length,
                  itemBuilder: (context, i) {
                    var b = result['breakdown'][i];
                    return ListTile(
                      title: Text(b['marker'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Target: ${b['target']}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(b['value'].toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(b['status'], style: TextStyle(color: _getRiskColor(b['status']))),
                        ],
                      ),
                    );
                  }
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Render ML Factors if available
            if (result['topFactors'] != null) ...[
              const Text('AI Risk Factor Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                color: const Color(0xFF1E293B),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: result['topFactors'].length,
                  itemBuilder: (context, i) {
                    var f = result['topFactors'][i];
                    return ListTile(
                      leading: const Icon(Icons.analytics, color: Colors.blueAccent),
                      title: Text(f['name']),
                      subtitle: LinearProgressIndicator(
                        value: (f['weight'] as double) / 0.20, // normalize roughly
                        color: Colors.blueAccent,
                        backgroundColor: Colors.white12,
                      ),
                    );
                  }
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Asian Food Swaps
            const Text('AI Lifestyle Coach: Food Swaps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (result['swaps'] != null) 
              ...((result['swaps'] as List).map((s) => Card(
                color: const Color(0xFF1E293B),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.fastfood, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Text(s['from'], style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.white54)),
                          const Icon(Icons.arrow_forward, color: Colors.white30, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s['to'], style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(s['desc'], style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ))),
              
            const SizedBox(height: 24),
            
            // 7-Day Plan
            const Text('7-Day Prevention Plan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (result['plan'] != null)
              Card(
                color: const Color(0xFF1E293B),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: result['plan'].length,
                  itemBuilder: (context, i) {
                    var d = result['plan'][i];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.blueAccent, child: Text('${i+1}')),
                      title: Text(d['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(d['desc']),
                    );
                  }
                ),
              ),
              
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Start New Assessment'),
            )
          ],
        ),
      ),
    );
  }
}
