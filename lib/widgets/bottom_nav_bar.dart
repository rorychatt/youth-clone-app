import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Background with blur and top border
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  border: const Border(top: BorderSide(color: AppColors.lightGray)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    )
                  ],
                ),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
            ),
            
            // Icons Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(CupertinoIcons.house_fill, 'Home', true),
                  _buildNavItem(CupertinoIcons.chart_bar_alt_fill, 'Data', false),
                  const SizedBox(width: 48), // Space for FAB
                  _buildNavItem(CupertinoIcons.square_grid_2x2_fill, 'Services', false),
                  _buildNavItem(CupertinoIcons.checkmark_rectangle_fill, 'Plan', false),
                ],
              ),
            ),

            // Floating Action Button
            Positioned(
              top: -24,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFC16246), Color(0xFFE59367)],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x4DC16246),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    )
                  ],
                ),
                child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool active) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: active ? AppColors.dark : AppColors.darkGray, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? AppColors.dark : AppColors.darkGray,
          ),
        ),
      ],
    );
  }
}
