import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App 全域主題設定
/// 所有頁面的視覺風格都從這裡統一控制
/// 要改顏色、字型、元件樣式，只需要改這個檔案
class AppTheme {
  /// 深色主題（目前唯一主題）
  /// 之後如果要加淺色主題，在這裡新增 static ThemeData get light
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // App 背景色，所有頁面的底色
      scaffoldBackgroundColor: AppColors.background,

      // 色彩系統，Flutter 會根據這裡自動套用到各種元件
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,         // 主要互動色（按鈕、選中狀態）
        secondary: AppColors.primaryLight,  // 次要互動色
        surface: AppColors.surface,         // 卡片、底部導覽等表面色
        error: AppColors.error,             // 錯誤狀態色
      ),

      // AppBar（頂部標題列）樣式
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background, // 跟背景同色，視覺上無邊界
        foregroundColor: AppColors.textPrimary,
        elevation: 0,          // 無陰影
        centerTitle: true,     // 標題置中
      ),

      // 底部導覽列樣式
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,        // 選中的 tab 顏色
        unselectedItemColor: AppColors.textSecondary, // 未選中的 tab 顏色
        type: BottomNavigationBarType.fixed,          // 固定寬度，不會因選中而移動
        elevation: 0,
      ),

     // 卡片樣式（錄音列表、分析結果卡片等都會用到）
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,        // 無陰影，扁平化設計
        margin: EdgeInsets.zero,
      ),  

      // 文字樣式系統
      // 使用時：Theme.of(context).textTheme.headlineLarge
      textTheme: const TextTheme(
        // 大標題，用於頁面主標題
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        // 中標題，用於區塊標題
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        // 一般正文
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        // 次要說明文字
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }
}
