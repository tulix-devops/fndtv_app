import 'package:flutter/material.dart';


class VideoProgramList extends StatefulWidget {
  const VideoProgramList({super.key, required this.isExpanded});

  final bool isExpanded;

  @override
  State<VideoProgramList> createState() => _VideoProgramListState();
}

class _VideoProgramListState extends State<VideoProgramList> {
  final List<Map<String, dynamic>> shows = List.generate(
    10,
    (index) => {
      "title": "Program",
      "startTime": "${index + 12}:00 PM",
      "endTime": "${index + 1 + 12}:00 PM",
      "thumbnailUrl": "https://via.placeholder.com/150",
    },
  );
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _EPG(
          isExpanded: widget.isExpanded,
        ),
        const SizedBox(
          height: 24,
        )
      ],
    );
  }
}

class _EPG extends StatefulWidget {
  const _EPG({required this.isExpanded});

  final bool isExpanded;
  @override
  State<_EPG> createState() => _EPGState();
}

class _EPGState extends State<_EPG> {
  int selectedDayIndex = 0;
  int selectedShowIndex = 0;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
    // return Padding(
    //   padding: const EdgeInsets.only(left: 10, right: 10),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.stretch,
    //     children: [
    //       const ChoiceChips(),
    //       Margins.vertical20,
    //       Container(
    //         decoration: BoxDecoration(
    //           borderRadius: BorderRadius.circular(12),
    //           border: Border.all(
    //             width: 2,
    //             color: context.uiColors.primary,
    //           ),
    //         ),
    //         height: widget.isExpanded
    //             ? MediaQuery.sizeOf(context).height / 2
    //             : 180,
    //         child: ListView.separated(
    //           padding: EdgeInsets.zero,
    //           scrollDirection: Axis.vertical,
    //           separatorBuilder: (context, index) => const SizedBox(height: 10),
    //           itemCount: mockShows.length,
    //           itemBuilder: (context, index) {
    //             final bool isSelectedShow = selectedShowIndex == index;
    //             final Color textColor =
    //                 isSelectedShow ? Colors.white : Colors.grey.shade500;

    //             return Padding(
    //               padding:
    //                   const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    //               child: Material(
    //                 color: Colors.transparent,
    //                 child: ListTile(
    //                   title: Text(
    //                     mockShows[index]['title'],
    //                     style: TextStyles.h5.copyWith(color: textColor),
    //                   ),
    //                   selected: isSelectedShow,
    //                   shape: const RoundedRectangleBorder(
    //                       borderRadius: BorderRadius.all(Radius.circular(12))),
    //                   tileColor: context.uiColors.surface,
    //                   selectedTileColor: context.uiColors.primary,
    //                   leading: AspectRatio(
    //                     aspectRatio: 5 / 7,
    //                     child: Image.asset(
    //                       mockShows[index]['image'],
    //                       fit: BoxFit.cover,
    //                       height: 50,
    //                       width: 90,
    //                     ),
    //                   ),
    //                   subtitle: Text(
    //                     mockShows[index]['time'],
    //                     style: TextStyles.h6.copyWith(color: textColor),
    //                   ),
    //                   onTap: () {
    //                     setState(() {
    //                       selectedShowIndex = index;
    //                     });
    //                   },
    //                 ),
    //               ),
    //             );
    //           },
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }
}
