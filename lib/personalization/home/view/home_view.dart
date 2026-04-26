import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surya_ecommerce/personalization/about_us/view/about_us_view.dart';
import 'package:surya_ecommerce/personalization/category/view/home_category.dart';
import 'package:surya_ecommerce/personalization/contact_us/view/contact_us_view.dart';
import 'package:surya_ecommerce/personalization/home/widgets/home_footer_section.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/constants/app_constants.dart';
import '../../reviews/widgets/review_prompt_widget.dart';
import '../widgets/hero_section.dart';
import '../widgets/Featured_screen.dart';
import '../widgets/home_testimonials_section.dart';
import '../../../core/utils/user_utils.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animationController.forward();
    UserUtils.checkAndPromptUser(context);
  }

  @override
  void dispose() {
    _animationController.dispose();
    UserUtils.stopLiveHeartbeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: AppConstants.companyName),
      body: SingleChildScrollView(
        physics: kIsWeb
            ? const ClampingScrollPhysics()
            : const BouncingScrollPhysics(),
        child: Column(
          children: [
            const HomeHeroSection(),
            const ReviewPromptWidget(),
            const ShopByCategoryWidget(),
            HomeAboutSection(),
            const FeaturedSection(),
            const ContactUsView(isInline: true),
            const HomeTestimonialsSection(),
            const SunAssociatesFooter(),
          ],
        ),
      ),
    );
  }
}
