import 'package:flutter/material.dart';

class UiImageContainer extends StatelessWidget {
  const UiImageContainer({
    super.key,
    required this.image,
    this.isImageNetwork = true,
  });

  final String? image;
  final bool isImageNetwork;

  @override
  Widget build(BuildContext context) {
    final DecorationImage? decorationImage = image != null && image!.isNotEmpty
        ? DecorationImage(
            image: isImageNetwork
                ? NetworkImage(image!) as ImageProvider<Object>
                : AssetImage(image!) as ImageProvider<Object>,
            fit: BoxFit.cover,
          )
        : null;

    return Container(
      alignment: Alignment.topRight,
      width: MediaQuery.sizeOf(context).width / 1.5,
      height: MediaQuery.sizeOf(context).height / 2,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xffF7C6D7),
          style: BorderStyle.solid,
          width: 3,
        ),
        image: decorationImage,
      ),
      child: null,
    );
  }
}
