import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TechNova Calculator',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: CalculatorScreen(onToggleTheme: _toggleTheme),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const CalculatorScreen({super.key, required this.onToggleTheme});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = '';
  String _result = '';
  bool _justEvaluated = false;

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _input = '';
        _result = '';
        _justEvaluated = false;
      } else if (value == '⌫') {
        if (_justEvaluated) {
          // After '=', backspace clears everything
          _input = '';
          _result = '';
          _justEvaluated = false;
        } else if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (value == '=') {
        _evaluate();
      } else {
        // If we just evaluated, start a new expression unless operator pressed
        if (_justEvaluated) {
          final isOperator = ['+', '−', '×', '÷', '%'].contains(value);
          if (isOperator) {
            // Continue with previous result
            _input = _result + value;
          } else {
            _input = value;
          }
          _result = '';
          _justEvaluated = false;
        } else {
          _input += value;
        }
      }
    });
  }

  void _evaluate() {
    if (_input.isEmpty) return;
    try {
      String expression = _input
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-');

      Parser p = Parser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      String formatted;
      if (eval == eval.roundToDouble() && eval.abs() < 1e15) {
        formatted = eval.toInt().toString();
      } else {
        formatted = eval.toString();
      }

      setState(() {
        _result = formatted;
        _justEvaluated = true;
      });
    } catch (e) {
      setState(() {
        _result = 'Error';
        _justEvaluated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // What to show in the big top display
    final String mainDisplay =
        _input.isEmpty ? (_result.isEmpty ? '0' : _result) : _input;

    // What to show in the small bottom line
    final String subDisplay = _result.isNotEmpty && _input.isNotEmpty
        ? '= $_result'
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('TechNova Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display area
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Small: shows "= <result>" after evaluate
                    if (subDisplay.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          subDisplay,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    // Big: main display
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        mainDisplay,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Button grid
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildRow(['C', '⌫', '%', '÷']),
                    _buildRow(['7', '8', '9', '×']),
                    _buildRow(['4', '5', '6', '−']),
                    _buildRow(['1', '2', '3', '+']),
                    _buildRow(['0', '.', '='], isLastRow: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> labels, {bool isLastRow = false}) {
    return Expanded(
      child: Row(
        children: labels.map((label) {
          final isWide = isLastRow && (label == '=' || label == '0');
          return Expanded(
            flex: isWide && label == '0' ? 2 : 1,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: CalcButton(
                label: label,
                onPressed: () => _onButtonPressed(label),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const CalcButton({super.key, required this.label, required this.onPressed});

  bool get _isOperator => ['÷', '×', '−', '+', '=', '%'].contains(label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOperator = _isOperator;
    final isEquals = label == '=';

    Color bg;
    Color fg;

    if (isEquals) {
      bg = theme.colorScheme.primary;
      fg = theme.colorScheme.onPrimary;
    } else if (isOperator) {
      bg = theme.colorScheme.primaryContainer;
      fg = theme.colorScheme.onPrimaryContainer;
    } else {
      bg = theme.colorScheme.surfaceContainerHighest;
      fg = theme.colorScheme.onSurface;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}