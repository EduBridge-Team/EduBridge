// lib/app_icons.dart
// ═══════════════════════════════════════════════════════════
//  🎯 أيقونات موحّدة — بديل الإيموجي في كل التطبيق
//  الاستخدام: Icon(AppIcons.users, color: c.heading)
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';

class AppIcons {
  AppIcons._();

  // ─── الأدوار ───
  static const teacher      = Icons.school_outlined;
  static const specialist   = Icons.psychology_outlined;
  static const parent       = Icons.family_restroom;
  static const child        = Icons.child_care_outlined;
  static const admin        = Icons.admin_panel_settings_outlined;
  static const ministry     = Icons.account_balance_outlined;
  static const institution  = Icons.apartment_outlined;
  static const users        = Icons.groups_outlined;

  // ─── لوحة التحكم ───
  static const dashboard        = Icons.dashboard_outlined;
  static const settings         = Icons.settings_outlined;
  static const shield           = Icons.verified_user_outlined;
  static const support          = Icons.headset_mic_outlined;
  static const search           = Icons.search;
  static const notifications    = Icons.notifications_none_outlined;
  static const notificationsOn  = Icons.notifications_active_outlined;

  // ─── المحتوى التعليمي ───
  static const lesson    = Icons.menu_book_outlined;
  static const homework  = Icons.assignment_outlined;
  static const game      = Icons.videogame_asset_outlined;
  static const progress  = Icons.insights_outlined;
  static const star      = Icons.star_outline;
  static const starFilled= Icons.star;
  static const trophy    = Icons.emoji_events_outlined;
  static const plan      = Icons.event_note_outlined;
  static const report    = Icons.bar_chart_outlined;
  static const evaluate  = Icons.rate_review_outlined;

  // ─── التواصل ───
  static const chat  = Icons.chat_bubble_outline;
  static const send  = Icons.send_outlined;
  static const call  = Icons.call_outlined;
  static const forum = Icons.forum_outlined;

  // ─── العمليات ───
  static const add      = Icons.add_circle_outline;
  static const addPlain = Icons.add;
  static const edit     = Icons.edit_outlined;
  static const delete   = Icons.delete_outline;
  static const refresh  = Icons.refresh_outlined;
  static const close    = Icons.close;
  static const back     = Icons.arrow_forward_outlined; // RTL
  static const next     = Icons.arrow_back_outlined;    // RTL
  static const check    = Icons.check_circle_outline;
  static const error    = Icons.error_outline;
  static const warning  = Icons.warning_amber_rounded;
  static const info     = Icons.info_outline;
  static const view     = Icons.visibility_outlined;
  static const upload   = Icons.upload_outlined;
  static const download = Icons.download_outlined;
  static const attach   = Icons.attach_file_outlined;
  static const filter   = Icons.filter_list_outlined;
  static const more     = Icons.more_vert;
  static const menu     = Icons.menu;
  static const save     = Icons.save_outlined;
  static const grade    = Icons.grade_outlined;

  // ─── الإعاقات ───
  static const blind        = Icons.visibility_off_outlined;
  static const deaf         = Icons.hearing_disabled_outlined;
  static const speech       = Icons.record_voice_over_outlined;
  static const motor        = Icons.accessible_outlined;
  static const cognitive    = Icons.psychology_alt_outlined;
  static const signLanguage = Icons.sign_language_outlined;
  static const autism       = Icons.auto_awesome_outlined;
  static const aac          = Icons.grid_view_outlined;

  // ─── الوسائط ───
  static const image    = Icons.image_outlined;
  static const video    = Icons.videocam_outlined;
  static const audio    = Icons.audiotrack_outlined;
  static const volumeUp = Icons.volume_up_outlined;
  static const camera   = Icons.camera_alt_outlined;
  static const mic      = Icons.mic_none_outlined;
  static const play     = Icons.play_circle_outline;
  static const pause    = Icons.pause_circle_outline;
  static const captions = Icons.closed_caption_outlined;

  // ─── الزمن ───
  static const calendar = Icons.calendar_today_outlined;
  static const clock    = Icons.schedule_outlined;
  static const event    = Icons.event_outlined;

  // ─── الطوارئ والأمان ───
  static const emergency = Icons.emergency_outlined;
  static const lock      = Icons.lock_outline;
  static const verified  = Icons.verified_outlined;
  static const logout    = Icons.logout;

  // ─── عام ───
  static const home        = Icons.home_outlined;
  static const profile     = Icons.person_outline;
  static const language    = Icons.language_outlined;
  static const theme       = Icons.contrast;
  static const privacy     = Icons.privacy_tip_outlined;
  static const certificate = Icons.workspace_premium_outlined;

  // ═══════════════════════════════════════════════════════════
  // ─── الويب والمنصات ───
  // ═══════════════════════════════════════════════════════════
  static const web           = Icons.web_outlined;             // 🌐 الأنسب عمومًا
  static const webBrowser    = Icons.open_in_browser_outlined; // زر "افتح في المتصفح"
  static const webAsset      = Icons.web_asset_outlined;       // صفحة ويب
  static const webAssetOff   = Icons.web_asset_off_outlined;   // ويب معطّل
  static const webhook       = Icons.webhook_outlined;         // Webhooks
  static const link          = Icons.link_outlined;            // رابط مشاركة
  static const http          = Icons.http_outlined;            // بروتوكول HTTP
  static const publicGlobe   = Icons.public_outlined;          // كرة أرضية بديل

  // ─── أجهزة / منصات ───
  static const android   = Icons.android_outlined;
  static const ios       = Icons.phone_iphone_outlined;
  static const windows   = Icons.window_outlined;
  static const macos     = Icons.laptop_mac_outlined;
  static const linux     = Icons.computer_outlined;
  static const desktop   = Icons.desktop_windows_outlined;
  static const mobile    = Icons.smartphone_outlined;
  static const tablet    = Icons.tablet_mac_outlined;

  // ─── مساعد: أيقونة حسب اسم المنصة ───
  /// يرجع أيقونة مناسبة بناءً على اسم المنصة القادم من السيرفر.
  /// مثال: منصة == 'web' أو 'android' أو 'ios' ...
  static IconData platform(String? platform) {
    switch ((platform ?? '').toLowerCase()) {
      case 'web':
      case 'browser':
        return web;
      case 'android':
        return android;
      case 'ios':
      case 'iphone':
        return ios;
      case 'windows':
        return windows;
      case 'macos':
      case 'mac':
        return macos;
      case 'linux':
        return linux;
      case 'desktop':
        return desktop;
      case 'tablet':
        return tablet;
      case 'mobile':
      case 'phone':
        return mobile;
      default:
        return publicGlobe;
    }
  }
}