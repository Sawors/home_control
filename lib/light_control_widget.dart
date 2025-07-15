import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:home_control/light_bulb.dart';
import 'package:home_control/utils.dart';

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
  int? brightness;
  int? color;

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
          brightness ??= state.brightness;
          color ??= state.color;
        }
        final colorTempRgb = colorTempToRGB((color ?? 2500) * 1.5);
        final trueColorTempRgb = colorTempToRGB((state?.color ?? 2500) * 1.5);
        final double brightnessInfluence =
            (((brightness ?? 0) / 100) * 0.5) + 0.5;
        final double trueBrightnessInfluence =
            (((state?.brightness ?? 0) / 100) * 0.5) + 0.5;
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
                    imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                      IconButton(
                        onPressed: () {
                          if (state != null) {
                            setState(() {
                              lightState = Future.value(
                                LightState(
                                  isOn: !isOn,
                                  brightness: state.brightness,
                                  color: state.color,
                                  isError: state.isError,
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
                        icon: state?.isOn ?? false
                            ? Icon(
                                Icons.lightbulb,
                                size: 100,
                                color: trueInfluencedColor,
                              )
                            : Icon(Icons.lightbulb_outline, size: 100),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.light_mode,
                            color: theme.colorScheme.primary,
                          ),
                          Text((brightness ?? 0).toString()),
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
                          value: (brightness ?? 1).toDouble(),
                          onChanged: isOn
                              ? (v) {
                                  setState(() {
                                    brightness = v.toInt();
                                  });
                                }
                              : null,
                          onChangeEnd: (v) {
                            if (brightness != null) {
                              widget.light.setBrightness(brightness!).then((_) {
                                setState(() {
                                  lightState = widget.light.state();
                                });
                              });
                            }
                          },
                          min: 1,
                          max: 100,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.color_lens,
                            color: theme.colorScheme.primary,
                          ),
                          Text((color ?? 2500).toString()),
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
                          value: (color ?? 2500).toDouble(),
                          onChanged: isOn
                              ? (v) {
                                  setState(() {
                                    color = v.toInt();
                                  });
                                }
                              : null,
                          onChangeEnd: (v) {
                            if (color != null) {
                              widget.light.setColorTemperature(color!).then((
                                _,
                              ) {
                                setState(() {
                                  lightState = widget.light.state();
                                });
                              });
                            }
                          },
                          min: 2500,
                          max: 6500,
                        ),
                      ),
                      Spacer(),
                      MaterialButton(
                        onPressed: () {
                          if (state != null) {
                            setState(() {
                              lightState = Future.value(
                                LightState(
                                  isOn: !isOn,
                                  brightness: state.brightness,
                                  color: state.color,
                                  isError: state.isError,
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
}
