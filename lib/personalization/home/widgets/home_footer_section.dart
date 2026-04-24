import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:surya_ecommerce/core/theme/app_colors.dart';

class SunAssociatesFooter extends StatelessWidget {
  const SunAssociatesFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: AppColors.borderSoft),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Builder(
              builder: (context) {
                final width = MediaQuery.of(context).size.width;
                if (width >= 900) {
                  return _DesktopFooterContent();
                } else if (width >= 600) {
                  return _TabletFooterContent();
                } else {
                  return _MobileFooterContent();
                }
              },
            ),
          ),
          Container(height: 1, color: AppColors.borderSoft),
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
            child: Column(
              children: [
                Text(
                  '© 2026 SUN ASSOCIATES. ALL RIGHTS RESERVED.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'DESIGNED FOR ARCHITECTURAL EXCELLENCE',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppColors.accentGold.withOpacity(0.6),
                    fontSize: 9,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopFooterContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _BrandColumn()),
        const SizedBox(width: 40),
        Expanded(flex: 2, child: _NavigationColumn()),
        const SizedBox(width: 40),
        Expanded(flex: 3, child: _ContactColumn()),
        const SizedBox(width: 40),
        Expanded(flex: 3, child: _MissionColumn()),
      ],
    );
  }
}

class _TabletFooterContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _BrandColumn()),
            const SizedBox(width: 32),
            Expanded(flex: 1, child: _NavigationColumn()),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ContactColumn()),
            const SizedBox(width: 32),
            Expanded(child: _MissionColumn()),
          ],
        ),
      ],
    );
  }
}

class _MobileFooterContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandColumn(),
        const SizedBox(height: 40),
        _NavigationColumn(),
        const SizedBox(height: 40),
        _ContactColumn(),
        const SizedBox(height: 40),
        _MissionColumn(),
      ],
    );
  }
}

class _BrandColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUN Associates',
          style: GoogleFonts.outfit(
            color: AppColors.accentGold,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ATHOLI, ATHANI, PIN 673315,\nKOZHIKODE, KERALA',
          style: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.7,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SocialIconButton(
              icon: FontAwesomeIcons.instagram,
              onTap: () => launchUrl(
                Uri.parse(
                  'https://www.instagram.com/surya_associates__?igsh=dHA1c2E2ZXJtMDl2',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Navigation Column ───────────────────────────────────────────────────────

class _NavigationColumn extends StatelessWidget {
  final List<String> _links = const [
    'Home',
    'About Us',
    'Products',
    'Services',
    'Contact Us',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading('NAVIGATION'),
        const SizedBox(height: 20),
        ..._links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FooterNavLink(label: link),
          ),
        ),
      ],
    );
  }
}

class _ContactColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading('GET IN TOUCH'),
        const SizedBox(height: 20),
        _ContactRow(icon: FontAwesomeIcons.phone, text: '+91 98462 03815'),
        const SizedBox(height: 16),
        _ContactRow(
          icon: FontAwesomeIcons.envelope,
          text: 'sunassociatesatholi@gmail.com',
        ),
      ],
    );
  }
}

class _MissionColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading('OUR MISSION'),
        const SizedBox(height: 20),
        Text(
          '"Powering the future of Kerala through architectural excellence and uncompromised electrical integrity."',
          style: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}

// ─── Shared Sub-Widgets ──────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: AppColors.accentGold,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
      ),
    );
  }
}

class _FooterNavLink extends StatefulWidget {
  final String label;
  const _FooterNavLink({required this.label});

  @override
  State<_FooterNavLink> createState() => _FooterNavLinkState();
}

class _FooterNavLinkState extends State<_FooterNavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: GoogleFonts.outfit(
          color: _hovered ? AppColors.accentGold : AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        child: Text(widget.label),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final dynamic icon;
  final String text;
  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildUniversalIcon(icon, color: AppColors.accentGold, size: 14),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildUniversalIcon(dynamic icon, {Color? color, double? size}) {
  if (icon is IconData) {
    return Icon(icon, color: color, size: size);
  }
  return FaIcon(icon, color: color, size: size);
}

class _SocialIconButton extends StatefulWidget {
  final dynamic icon;
  final VoidCallback onTap;
  const _SocialIconButton({required this.icon, required this.onTap});

  @override
  State<_SocialIconButton> createState() => _SocialIconButtonState();
}

class _SocialIconButtonState extends State<_SocialIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accentGold.withOpacity(0.15)
                : AppColors.cardDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? AppColors.accentGold : AppColors.borderSoft,
              width: 1,
            ),
          ),
          child: Center(
            child: _buildUniversalIcon(
              widget.icon,
              color: _hovered ? AppColors.accentGold : AppColors.textSecondary,
              size: 15,
            ),
          ),
        ),
      ),
    );
  }
}
