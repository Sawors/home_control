import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:home_control/common/ui_utils.dart';
import 'package:home_control/devices/lights/light_bulb.dart';

import '../../common/color.dart';

class LightControlWidget extends StatefulWidget {
  const LightControlWidget({super.key, required this.light});
  final LightBulb light;

  @override
  createState() => _LightControlWidgetState();
}

class _LightControlWidgetState extends State<LightControlWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Future<LightState> lightState;
  double? brightness;
  RGBColor? color;
  int? colorTemp;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    lightState = widget.light.state();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: lightState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final isOn = state?.isOn ?? false;
        if (state != null) {
          brightness ??= state.brightnessPercent;
          color ??= state.color;
          colorTemp ??= state.colorTemperature;
        }
        final colorTempRgb = RGBColor.fromTemperature(
          (colorTemp ?? 2500) * 1.5,
        ).toDartColor();
        final trueColorTempRgb = RGBColor.fromTemperature(
          (colorTemp ?? 2500) * 1.5,
        ).toDartColor();
        final double brightnessInfluence = (((brightness ?? 0)) * 0.66) + 0.33;
        final double trueBrightnessInfluence =
            (((state?.brightnessPercent ?? 0)) * 0.5) + 0.5;
        final brightnessRgb = Color.from(
          alpha: 1,
          red: brightnessInfluence,
          green: brightnessInfluence,
          blue: brightnessInfluence,
        );

        final trueInfluencedColor = Color.from(
          alpha: 1,
          red: trueColorTempRgb.r * trueBrightnessInfluence,
          green: trueColorTempRgb.g * trueBrightnessInfluence,
          blue: trueColorTempRgb.b * trueBrightnessInfluence,
        );
        final influencedColor = Color.from(
          alpha: 1,
          red: colorTempRgb.r * brightnessInfluence,
          green: colorTempRgb.g * brightnessInfluence,
          blue: colorTempRgb.b * brightnessInfluence,
        );

        return Stack(
          children: [
            isOn
                ? ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(color: influencedColor),
                    ),
                  )
                : Container(),
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: isOn
                        ? influencedColor.withValues(
                            red: influencedColor.r * 0.75,
                            green: influencedColor.g * 0.75,
                            blue: influencedColor.b * 0.75,
                          )
                        : theme.colorScheme.surfaceContainerHigh,
                    width: isOn ? 4 : 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                color: theme.canvasColor,

                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Text(
                        widget.light.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          onPressed: () {
                            if (state != null) {
                              setState(() {
                                lightState = Future.value(
                                  LightState(
                                    isOn: !isOn,
                                    brightnessPercent: state.brightnessPercent,
                                    color: state.color,
                                    isError: state.isError,
                                    colorTemperature: state.colorTemperature,
                                  ),
                                );
                              });
                            }
                            // toggle light
                            widget.light.toggle().then((v) {
                              setState(() {
                                lightState = widget.light.state();
                              });
                            });
                          },
                          icon: state?.isOn ?? false
                              ? Icon(
                                  Icons.lightbulb,
                                  size: 80,
                                  color: trueInfluencedColor,
                                )
                              : Icon(Icons.lightbulb_outline, size: 80),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.light_mode,
                                  color: theme.colorScheme.primary,
                                ),
                                Text(
                                  ((brightness ?? 0) * 100).toInt().toString(),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: theme.sliderTheme.copyWith(
                                thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                                thumbSize: WidgetStatePropertyAll(
                                  Size.fromRadius(12),
                                ),
                                thumbColor: brightnessRgb,
                              ),
                              child: Slider(
                                padding: EdgeInsets.symmetric(
                                  vertical: 2,
                                  horizontal: 10,
                                ),
                                value: (brightness ?? 1).toDouble() * 100,
                                onChanged: isOn
                                    ? (v) {
                                        setState(() {
                                          brightness = v / 100;
                                        });
                                      }
                                    : null,
                                onChangeEnd: (v) {
                                  if (brightness != null) {
                                    widget.light
                                        .setBrightness(brightness!.toDouble())
                                        .then((_) {
                                          setState(() {
                                            lightState = widget.light.state();
                                          });
                                        });
                                  }
                                },
                                min: 0,
                                max: 100,
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.thermostat,
                                  color: theme.colorScheme.primary,
                                ),
                                Text((colorTemp ?? 2500).toString()),
                              ],
                            ),
                            SliderTheme(
                              data: theme.sliderTheme.copyWith(
                                thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                                thumbSize: WidgetStatePropertyAll(
                                  Size.fromRadius(12),
                                ),
                                thumbColor: colorTempRgb,
                                activeTrackColor: colorTempRgb,
                              ),
                              child: Slider(
                                padding: EdgeInsets.symmetric(
                                  vertical: 2,
                                  horizontal: 10,
                                ),
                                value: (colorTemp ?? 2500).toDouble(),
                                onChanged: isOn
                                    ? (v) {
                                        setState(() {
                                          colorTemp = v.toInt();
                                        });
                                      }
                                    : null,
                                onChangeEnd: (v) {
                                  if (colorTemp != null) {
                                    widget.light
                                        .setColorTemperature(colorTemp ?? 2500)
                                        .then((_) {
                                          setState(() {
                                            lightState = widget.light.state();
                                          });
                                        });
                                  }
                                },
                                min: 1700,
                                max: 6500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      MaterialButton(
                        onPressed: () {
                          if (state != null) {
                            setState(() {
                              lightState = Future.value(
                                LightState(
                                  isOn: !isOn,
                                  brightnessPercent: state.brightnessPercent,
                                  color: state.color,
                                  isError: state.isError,
                                  colorTemperature: state.colorTemperature,
                                ),
                              );
                            });
                          }
                          widget.light.toggle().then((v) {
                            setState(() {
                              lightState = widget.light.state();
                            });
                          });
                        },

                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isOn
                                ? influencedColor
                                : theme.colorScheme.primaryContainer,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 15,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 24,
                            child: Center(
                              child: Text(
                                isOn ? "Allumée" : "Éteinte",
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double tempToPercent(num temp, {int maxTemp = 6500, int minTemp = 1700}) {
    return ((temp - minTemp) / (maxTemp - minTemp)).toDouble();
  }

  int percentToTemp(double percent, {int maxTemp = 6500, int minTemp = 1700}) {
    return (((maxTemp - minTemp) * percent) + minTemp).toInt();
  }
}
