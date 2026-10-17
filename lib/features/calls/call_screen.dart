import 'package:flutter/material.dart';

class CallScreen extends StatelessWidget {
  final String callType;

  const CallScreen({super.key, required this.callType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 60),
                  ),
                  const SizedBox(height: 16),
                  const Text('Calling...', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('${callType.toUpperCase()} CALL', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: IconButton(
                      icon: const Icon(Icons.mic_off, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.red,
                    child: IconButton(
                      icon: const Icon(Icons.call_end, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: IconButton(
                      icon: const Icon(Icons.videocam_off, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
