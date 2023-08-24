import 'package:flutter/material.dart';
import 'package:kasie_transie_demoapp/auth/auth_service.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lm;
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/language_and_color_chooser.dart';
import 'package:kasie_transie_library/widgets/timer_widget.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'demo_landing.dart';

class AssociationList extends StatefulWidget {
  const AssociationList({Key? key}) : super(key: key);

  @override
  AssociationListState createState() => AssociationListState();
}

class AssociationListState extends State<AssociationList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final mm = '🍐🍐🍐🍐AssociationList 🍐🍐';
  var assocList = <lm.Association>[];
  bool busy = false;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _checkStatus();
  }

  lib.Association? association;

  Future<void> _checkStatus() async {
    association = await prefs.getAssociation();
    await _getData(true);

    if (association != null) {
      if (mounted) {
        _navigateToLanding(association!);
        return;
      }
    }
  }

  Future _getData(bool refresh) async {
    pp('$mm  ... getting associations ... ....... ');
    setState(() {
      busy = true;
    });
    try {
      await authService.registerDemoDriver();
      assocList = await listApiDog.getAssociations(refresh);
      pp('$mm ...... associations ... found: ${assocList.length}');
    } catch (e) {
      pp(e);
    }

    setState(() {
      busy = false;
    });
  }

  void _navigateToLanding(lib.Association ass) async {
    await prefs.saveAssociation(ass);
    await prefs.saveDemoFlag(true);
    fcmBloc.subscribeForDemoDriver('DemoDriver');
    final type = getThisDeviceType();
    if (type == 'phone') {
      if (mounted) {
        await navigateWithScale(DemoLanding(association: ass), context);
        setState(() {});
      }
    } else {
      setState(() {
        association = ass;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Associations for Demo',
          ),
          actions: [
            IconButton(
                onPressed: () {
                  navigateWithScale(
                      LanguageAndColorChooser(onLanguageChosen: () {}),
                      context);
                },
                icon: Icon(
                  Icons.color_lens,
                  color: Theme.of(context).primaryColor,
                )),
            IconButton(
                onPressed: () {
                  _getData(true);
                },
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).primaryColor,
                ))
          ],
        ),
        body: busy
            ? const Center(
                child: TimerWidget(
                  title: 'Loading data',
                  subTitle: 'Please wait a couple of minutes',
                  isSmallSize: false,
                ),
              )
            : ScreenTypeLayout.builder(mobile: (ctx) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    shape: getRoundedBorder(radius: 16),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 48,
                        ),
                        const Text('Select the Association for the Demo'),
                        const SizedBox(
                          height: 48,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ListView.builder(
                                itemCount: assocList.length,
                                itemBuilder: (ctx, index) {
                                  final ass = assocList.elementAt(index);
                                  return GestureDetector(
                                    onTap: () {
                                      _navigateToLanding(ass);
                                    },
                                    child: Card(
                                      shape: getRoundedBorder(radius: 16),
                                      elevation: 4,
                                      child: ListTile(
                                        title: Text(
                                          '${ass.associationName}',
                                          style:
                                              myTextStyleMediumLargeWithColor(
                                                  context,
                                                  Theme.of(context)
                                                      .primaryColor,
                                                  14),
                                        ),
                                        subtitle: ass.cityName == null
                                            ? const SizedBox()
                                            : Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0),
                                                child: Text(
                                                  ass.cityName!,
                                                  style:
                                                      myTextStyleTiny(context),
                                                ),
                                              ),
                                        leading: Icon(
                                          Icons.back_hand,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }, tablet: (ctx) {
                return OrientationLayoutBuilder(
                  portrait: (ctx) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: (width / 2) - 40,
                          child: Card(
                            shape: getRoundedBorder(radius: 16),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 48,
                                ),
                                const Text(
                                    'Select the Association for the Demo'),
                                const SizedBox(
                                  height: 48,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: ListView.builder(
                                        itemCount: assocList.length,
                                        itemBuilder: (ctx, index) {
                                          final ass =
                                              assocList.elementAt(index);
                                          return GestureDetector(
                                            onTap: () {
                                              _navigateToLanding(ass);
                                            },
                                            child: Card(
                                              shape:
                                                  getRoundedBorder(radius: 16),
                                              elevation: 4,
                                              child: ListTile(
                                                title: Text(
                                                  '${ass.associationName}',
                                                  style: myTextStyleSmall(
                                                    context,
                                                  ),
                                                ),
                                                subtitle: ass.cityName == null
                                                    ? const SizedBox()
                                                    : Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 8.0),
                                                        child: Text(
                                                          ass.cityName!,
                                                          style:
                                                              myTextStyleTiny(
                                                                  context),
                                                        ),
                                                      ),
                                                leading: Icon(
                                                  Icons.back_hand,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                            width: (width / 2) + 40,
                            child: association == null
                                ? Center(
                                    child: Card(
                                      shape: getRoundedBorder(radius: 16),
                                      elevation: 12,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          'Waiting for Godot ...',
                                          style:
                                              myTextStyleMediumLargeWithColor(
                                                  context,
                                                  Theme.of(context)
                                                      .primaryColor,
                                                  32),
                                        ),
                                      ),
                                    ),
                                  )
                                : DemoLanding(association: association!))
                      ],
                    );
                  },
                  landscape: (ctx) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: (width / 2),
                          child: Card(
                            shape: getRoundedBorder(radius: 16),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 48,
                                ),
                                const Text(
                                    'Select the Association for the Demo'),
                                const SizedBox(
                                  height: 48,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: ListView.builder(
                                        itemCount: assocList.length,
                                        itemBuilder: (ctx, index) {
                                          final ass =
                                              assocList.elementAt(index);
                                          return GestureDetector(
                                            onTap: () {
                                              _navigateToLanding(ass);
                                            },
                                            child: Card(
                                              shape:
                                                  getRoundedBorder(radius: 16),
                                              elevation: 4,
                                              child: ListTile(
                                                title: Text(
                                                  '${ass.associationName}',
                                                  style:
                                                      myTextStyleMediumLargeWithColor(
                                                          context,
                                                          Theme.of(context)
                                                              .primaryColor,
                                                          14),
                                                ),
                                                subtitle: ass.cityName == null
                                                    ? const SizedBox()
                                                    : Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 8.0),
                                                        child: Text(
                                                          ass.cityName!,
                                                          style:
                                                              myTextStyleTiny(
                                                                  context),
                                                        ),
                                                      ),
                                                leading: Icon(
                                                  Icons.back_hand,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                            width: (width / 2),
                            child: association == null
                                ? const SizedBox()
                                : DemoLanding(association: association!))
                      ],
                    );
                  },
                );
              }),
      ),
    );
  }
}
