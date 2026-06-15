import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class ChoiceChips extends StatefulWidget {
  const ChoiceChips({super.key});

  @override
  State<ChoiceChips> createState() => ChoiceChipsState();
}

class ChoiceChipsState extends State<ChoiceChips> {
  final List<Map<String, dynamic>> _days = [
    {'weekday': 'Mon', 'date': '01'},
    {'weekday': 'Tue', 'date': '02'},
    {'weekday': 'Wed', 'date': '03'},
    {'weekday': 'Thu', 'date': '04'},
    {'weekday': 'Fri', 'date': '05'},
    {'weekday': 'Sat', 'date': '06'},
    {'weekday': 'Sun', 'date': '07'},
  ];
  int selectedDayIndex = 0;
  int selectedShowIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 65,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _days.length,
          reverse: true,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final bool isSelected = selectedDayIndex == index;
            final Color borderColor =
                isSelected ? context.uiColors.primary : Colors.grey.shade500;
            final Color textColor =
                isSelected ? Colors.white : Colors.grey.shade500;

            return Padding(
              padding: EdgeInsets.only(
                right: index == 0 ? 24 : 0,
                left: index == (_days.length - 1) ? 24 : 8,
              ),
              child: ChoiceChip(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(22))),
                label: SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Text(
                        _days[index]['weekday'],
                        textAlign: TextAlign.center,
                        style: TextStyles.bodySmall
                            .copyWith(fontSize: 14, color: textColor),
                      ),
                      Text(
                        _days[index]['date'],
                        textAlign: TextAlign.center,
                        style: TextStyles.bodySmall.copyWith(
                            fontSize: 18,
                            color: textColor,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                selected: isSelected,
                onSelected: (bool value) {
                  if (!value) return;

                  setState(() {
                    selectedDayIndex = index;
                  });
                },
                showCheckmark: false,
                backgroundColor: context.uiColors.surface,
                side: BorderSide(color: borderColor),
                selectedColor: borderColor,
                labelStyle: TextStyles.bodyMediumRegular.copyWith(
                  color: textColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
