import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:weather_app/additional_info_item.dart';
import 'package:weather_app/hourly_forecast_item.dart';
import 'package:weather_app/secrets.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> weather;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _cityName = 'London';

  @override
  void initState() {
    super.initState();
    weather = getCurrentWeather();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$_cityName,uk&APPID=$openWeatherApiKey',
        ),
      );

      final data = jsonDecode(res.body);

      if (data['cod'] != '200') {
        throw data['message'];
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  Color _getWeatherColor(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return const Color(0xFF1E88E5);
      case 'clouds':
        return const Color(0xFF546E7A);
      case 'rain':
        return const Color(0xFF37474F);
      default:
        return const Color(0xFF1E88E5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: weather,
        builder: (context, snapShot) {
          if (snapShot.connectionState == ConnectionState.waiting) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade300, Colors.blue.shade600],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          if (snapShot.hasError) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade300, Colors.blue.shade600],
                ),
              ),
              child: Center(
                child: Text(
                  snapShot.error.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          final data = snapShot.data;
          final currentWeatherData = data?['list']?[0];
          final currentTemp = currentWeatherData['main']?['temp'] ?? 0.0;
          final currentSky = currentWeatherData['weather']?[0]?['main'] ?? '';
          final currentPressure =
              currentWeatherData['main']?['pressure'] ?? 0.0;
          final currentWindSpeed = currentWeatherData['wind']?['speed'] ?? 0.0;
          final currentHumidity =
              currentWeatherData['main']?['humidity'] ?? 0.0;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getWeatherColor(currentSky),
                  _getWeatherColor(currentSky).withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          _cityName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              weather = getCurrentWeather();
                            });
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Bar
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search city...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      _cityName = value;
                                      weather = getCurrentWeather();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Main Weather Card
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${(currentTemp - 273.15).toStringAsFixed(1)}°C',
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Icon(
                                          currentSky == 'Clouds' ||
                                                  currentSky == 'Rain'
                                              ? Icons.cloud
                                              : Icons.wb_sunny,
                                          size: 80,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          currentSky,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            // Hourly Forecast
                            const Text(
                              'Hourly Forecast',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                itemCount: 5,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  final hourlyForecast =
                                      data?['list']?[index + 1];
                                  final hourlySky =
                                      data?['list']?[index +
                                          1]?['weather']?[0]?['main'];
                                  final hourlyTemp =
                                      hourlyForecast['main']['temp'].toString();
                                  final time = DateTime.parse(
                                    hourlyForecast['dt_txt'],
                                  );
                                  return HourlyForecastItem(
                                    time: DateFormat.j().format(time),
                                    temperature:
                                        '${(double.parse(hourlyTemp) - 273.15).toStringAsFixed(1)}°C',
                                    icon:
                                        hourlySky == 'Clouds' ||
                                                hourlySky == 'Rain'
                                            ? Icons.cloud
                                            : Icons.wb_sunny,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 30),
                            // Additional Info
                            const Text(
                              'Additional Info',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                AdditionalInfoCard(
                                  icon: Icons.water_drop,
                                  label: 'Humidity',
                                  value: '$currentHumidity%',
                                ),
                                AdditionalInfoCard(
                                  icon: Icons.air,
                                  label: 'Wind',
                                  value: '${currentWindSpeed}m/s',
                                ),
                                AdditionalInfoCard(
                                  icon: Icons.beach_access,
                                  label: 'Pressure',
                                  value: '${currentPressure}hPa',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
