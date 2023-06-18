import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/pedometer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Step Counter 10000',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Step Counter 10000'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _steps = '?';
  int _distance = 0;
  int _calories = 0;
  late SharedPreferences _prefs;
  late Timer _timer;
  int _secondsElapsed = 0;
  bool _isTimerRunning = false;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initSharedPreferences();
  }

  void initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    int savedSteps = _prefs.getInt('stepCount') ?? 0;
    setState(() {
      _steps = savedSteps.toString();
    });
  }

  void saveStepCount(int count) async {
    await _prefs.setInt('stepCount', count);
  }

  void resetStepCount() async {
    await _prefs.remove('stepCount');
    setState(() {
      _steps = '0';
      _distance = 0;
      _calories = 0;
    });
  }

  void calculateDistanceAndCalories(int stepCount) {
    // Calculate distance (assuming average stride length)
    double strideLength =
        0.7; // Adjust this value based on individual stride length
    double distance = strideLength * stepCount.toDouble();

    // Calculate calories burned (assuming average calorie burn rate per step)
    double caloriesPerStep =
        0.04; // Adjust this value based on individual factors
    double calories = stepCount.toDouble() * caloriesPerStep;

    setState(() {
      _distance = distance.toInt();
      _calories = calories.toInt();
    });
  }

  void onStepCount(StepCount event) {
    print(event);
    int count = event.steps;
    setState(() {
      _steps = count.toString();
    });
    saveStepCount(count);
    calculateDistanceAndCalories(count);
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _steps = 'Step Count not available';
    });
  }

  void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

    if (!mounted) return;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (!_isTimerRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        setState(() {
          _secondsElapsed++;
        });
      });
      _isTimerRunning = true;
    }
  }

  void _stopTimer() {
    if (_isTimerRunning) {
      _timer.cancel();
      setState(() {
        _isTimerRunning = false;
      });
    }
  }

  void _resetTimer() {
    _timer.cancel();
    setState(() {
      _secondsElapsed = 0;
      _isTimerRunning = false;
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Steps',
              style: TextStyle(fontSize: 24),
            ),
            Text(
              _steps.toString(),
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Text(
                      'Distance',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '$_distance m',
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    Text(
                      'Calories',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '$_calories cal',
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: resetStepCount,
              child: Text('Reset Step Count'),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Timer:',
                  style: TextStyle(fontSize: 24),
                ),
                Text(
                  _formatTime(_secondsElapsed),
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _isTimerRunning ? _stopTimer : _startTimer,
                      child: Text(_isTimerRunning ? 'Stop' : 'Start'),
                    ),
                    ElevatedButton(
                      onPressed: _resetTimer,
                      child: Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
