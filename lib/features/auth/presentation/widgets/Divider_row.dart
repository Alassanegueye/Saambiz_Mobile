import 'package:saambiz/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:saambiz/core/theme/police.dart';

class DividerRow extends StatelessWidget {
  final String title;
  const DividerRow({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColor.kLine)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: kPolice,
              color: AppColor.kGrayscale40,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColor.kLine)),
      ],
    );
  }
}
