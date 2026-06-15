import 'package:commons/shared/extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ui_kit/ui_kit.dart';
import 'package:fndtv/src/index.dart';

final List<Map<String, dynamic>> _policies = [
  {
    'title':
        'Our privacy policy covers POCKO Channel and its web site (pockochannel.com).',
    'description':
        'Your personal information may be stored by us. We don"t distribute it to third parties. Browsing and ordering via pockochannel.com will not result in your computer getting infected by spyware, hardware or viruses. We do not phish, harm or participate in any illicit or identity theft activities.',
  },
  {
    'title': 'Security',
    'description':
        'We always use industry-standard encryption technologies when transferring and receiving consumer data exchanged with our site. We have appropriate security measures in place in our physical facilities to protect against the loss, misuse or alteration of information that we have collected from you at our site.',
  },
  {
    'title': 'What We Track and Don"t Track',
    'description':
        'We collect aggregate information on what pages are accessed and visited by consumers.',
  },
  {
    'title': 'How We Use Contact Information',
    'description':
        'You can access our web site home page and browse our site without disclosing your personal data. The information we collect is used to notify consumers about issues with his or her order or if they have opted in to our newsletter, updates to our Web site. When we offer contests, promotions or feedback surveys, you may be required to provide certain personal information to participate. In these cases, we will give you the choice not to receive email messages or other communications from us regarding our products, services, contests, and promotions. We may use your contact information to reach you about the sweepstakes or contest. If you do not want to receive e-mail from us in the future, please let us know by sending us an e-mail at the above address. We use cookies to record session information, such as items that consumers add to their shopping cart. Persons who supply us with their telephone numbers on-line will only receive telephone calls from us with information regarding orders or questions they have submitted on-line.',
  },
  {
    'title': 'Updates to Privacy Policy',
    'description':
        'From time to time, we may use the customer information for new, unanticipated uses not previously disclosed in our privacy notice. If our information practices change at some time in the future, we will post the policy changes to our Web site to notify you of these changes and provide you with the ability to opt out of these new uses. If you are concerned about how your information is used, you should check back at our Web site periodically (we will maintain a last-updated date at the bottom of this web page). You can request by contacting us whether we are keeping personal data about you. We do, however, allow you to challenge our decision to refuse to provide you with a copy of your personal data.',
  },
];

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  static const path = 'privacy-policy';
  static const name = 'privacy-policy';

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  late final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasNavbar: false,
      body: CustomScrollView(
        controller: _controller,
        slivers: [
          PageHeader(
            isTv: context.isTv,
            onPressed: () {
              context.pop();
            },
            isMainPage: false,
            page: 'Privacy Policy',
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverList.builder(
              itemCount: _policies.length + 1,
              itemBuilder: (context, index) {
                if (index == _policies.length) {
                  return const SizedBox(height: 50);
                }

                final Map<String, dynamic> policy = _policies[index];

                return KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (e) {
                    if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
                      _controller.animateTo(
                        _controller.offset + 200,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeIn,
                      );
                    }

                    if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
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
                      Text(
                        policy['title'],
                        style: TextStyles.h5.surface(context),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        policy['description'],
                        style: TextStyles.bodyMedium.surface(context),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
