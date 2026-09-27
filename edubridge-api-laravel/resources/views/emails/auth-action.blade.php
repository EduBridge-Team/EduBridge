<!doctype html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $subjectLine }}</title>
</head>
<body style="margin:0;padding:0;background:#f4f7fb;font-family:Arial,'Segoe UI',Tahoma,sans-serif;color:#1f2937;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f4f7fb;padding:24px 12px;">
    <tr>
        <td align="center">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:620px;background:#ffffff;border-radius:18px;overflow:hidden;border:1px solid #e5e7eb;">
                <tr>
                    <td style="padding:28px 32px;background:linear-gradient(135deg,#0f766e,#2563eb);color:#ffffff;text-align:center;">
                        <div style="font-size:30px;font-weight:800;letter-spacing:.2px;">EduBridge</div>
                        <div style="font-size:14px;opacity:.92;margin-top:6px;">جسر تعليمي • فرص تعلم متساوية للجميع</div>
                    </td>
                </tr>
                <tr>
                    <td style="padding:32px;">
                        <h1 style="font-size:24px;line-height:1.5;margin:0 0 16px;color:#111827;">{{ $heading }}</h1>

                        <p style="font-size:16px;line-height:1.9;margin:0 0 18px;">
                            مرحباً {{ $userName }}،
                        </p>

                        <p style="font-size:16px;line-height:1.9;margin:0 0 24px;color:#374151;">
                            {{ $intro }}
                        </p>

                        <div style="text-align:center;margin:28px 0;">
                            <a href="{{ $actionUrl }}"
                               style="display:inline-block;background:#0f766e;color:#ffffff;text-decoration:none;font-size:16px;font-weight:700;padding:14px 28px;border-radius:10px;">
                                {{ $actionText }}
                            </a>
                        </div>

                        <p style="font-size:14px;line-height:1.8;color:#6b7280;margin:0 0 8px;">
                            إذا لم يعمل الزر، انسخ الرابط التالي وافتحه في المتصفح:
                        </p>

                        <p style="font-size:13px;line-height:1.7;word-break:break-all;background:#f9fafb;border:1px solid #e5e7eb;border-radius:8px;padding:12px;margin:0 0 22px;">
                            <a href="{{ $actionUrl }}" style="color:#2563eb;text-decoration:none;">{{ $actionUrl }}</a>
                        </p>

                        <p style="font-size:14px;line-height:1.8;color:#6b7280;margin:0;">
                            {{ $expiryText }}
                        </p>

                        @if(!empty($ignoreText))
                            <p style="font-size:14px;line-height:1.8;color:#6b7280;margin:12px 0 0;">
                                {{ $ignoreText }}
                            </p>
                        @endif
                    </td>
                </tr>
                <tr>
                    <td style="padding:22px 32px;background:#f9fafb;border-top:1px solid #e5e7eb;text-align:center;color:#6b7280;font-size:13px;line-height:1.8;">
                        تحتاج مساعدة؟ تواصل معنا على
                        <a href="mailto:support@edubridge.win" style="color:#0f766e;text-decoration:none;font-weight:700;">support@edubridge.win</a>
                        <br>
                        <a href="https://edubridge.win" style="color:#2563eb;text-decoration:none;">edubridge.win</a>
                        <br>
                        © {{ date('Y') }} EduBridge
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
