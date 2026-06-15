import 'package:commons/shared/extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fndtv/src/index.dart';
import 'package:ui_kit/ui_kit.dart';

final List<Map<String, dynamic>> _terms = [
  {
    'description':
        'Secrets Unsealed is a legally incorporated non-profit organization 501(c)3 which is committed to upholding, proclaiming and multiplying the unique end-time Present Truth message which God has entrusted to the Seventh-day Adventist Church to proclaim to the world. Ever conscious of the sacredness of God’s holy truth, we hold high and without apology or compromise all the fundamental teachings of the Bible as well as the distinctive beliefs of our beloved Seventh-day Adventist Church.',
  },
  {
    'description':
        'Among the distinctive beliefs we cherish and uphold are: A literal seven-day creation, heterosexual marriage between one man and one woman, the sanctity of the seventh-day Sabbath, the full inspiration of the writings of Ellen G. White, the sanctuary doctrine including the investigative pre-advent judgment, the hope of immortality only through Jesus Christ, historicism as the indispensable method of prophetic interpretation and the burning desire to see Jesus return soon, visibly, literally, personally and pre-millennially. We also believe in, teach and practice a reverent, traditional worship style and we seek to uphold the unique Seventh-day Adventist lifestyle.',
  },
  {
    'description':
        'Secrets Unsealed is an active member of Adventist-laymen\'s Services & Industries (ASI). Our eight board members are faithful members of the Fresno Central Seventh-day Adventist Church.',
  },
  {
    'description':
        'Although we realize that we are ultimately accountable to God in all things, in order to assure financial transparency we are audited every year by our request.',
  },
  {
    'description':
        'Although Secrets Unsealed has its own non-profit status, it works in full harmony with the Central California Conference of Seventh-day Adventists as a supporting ministry. Individuals who accept the message of the Seventh-day Adventist Church through our various media are encouraged to become faithful members of the organized Seventh-day Adventist Church. The ministry volunteers are mostly members of the Fresno Central Seventh-day Adventist Church and all the employees are members in good and regular standing of various churches of the Central California Conference.',
  },
  {
    'description':
        'Secrets Unsealed has produced over 100 different series on prophecy and various Biblical topics. One of the most ambitious projects so far has been “Cracking the Genesis Code”, a series of 52 one-hour lectures presenting the full message of the Bible from the perspective of the book of Genesis, and we continue to produce new materials every year. Though our products are useful for evangelism, they also provide in-depth Bible study and fresh insights on Bible truth for church members and any avid Bible student.',
  },
  {
    'description':
        'Secrets Unsealed presently has 14 full-time, one part-time employee, and one intern. In addition, we have many Fresno Central Church members who volunteer their time and talents to help keep the ministry functioning. Financially our ministry is sustained by tax-deductible contributions from those who believe in our mission, and from the sales of the Biblical materials we produce. We crave the prayers of God’s people for our ministry for we are keenly aware that success is not by might nor by power but by the Holy Spirit.',
  },
  {
    'description':
        'In 2017 Secrets Unsealed launched two broadcasting networks; SUMTV and SUMTV Latino. Both channels provide Christ centered programs with clarity and power on topics such as Bible prophecy, end-time events, Bible interpretation, tips for healthful living, cooking demonstrations and so more. Our programs provide practical counsel for daily life, and assurance for these uncertain times. Download the free SUMTV app or watch online at SUMTV.org. You will be blessed!',
  },
];

class TermsOfUsePage extends StatefulWidget {
  const TermsOfUsePage({super.key});

  static const path = 'terms-of-use';
  static const name = 'terms-of-use';

  @override
  State<TermsOfUsePage> createState() => _TermsOfUsePageState();
}

class _TermsOfUsePageState extends State<TermsOfUsePage> {
  late final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _controller,
      slivers: [
        const SliverPadding(padding: Paddings.vertical10),
        PageHeader(
          isTv: context.isTv,
          onPressed: () {
            context.pop();
          },
          isMainPage: true,
          page: 'About Us',
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverList.builder(
            itemCount: _terms.length + 1,
            itemBuilder: (context, index) {
              if (index == _terms.length) {
                return const SizedBox(height: 100);
              }

              final Map<String, dynamic> policy = _terms[index];

              return KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (e) {
                  if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (_controller.offset ==
                        _controller.position.maxScrollExtent) {
                      return;
                    }
                    _controller.animateTo(
                      _controller.offset + 200,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeIn,
                    );
                  }

                  if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (_controller.offset == 0.00) {
                      return;
                    }
                    _controller.animateTo(
                      _controller.offset - 200,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeIn,
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      policy['description'],
                      style: TextStyles.bodyLarge.surface(context),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
