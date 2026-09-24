# پول من

اپ مدیریت مالی شخصی با Flutter برای Android، iOS و وب. رابط کاربری فارسی است و از تاریخ شمسی استفاده می‌کند.

## بررسی محلی

```sh
flutter pub get
flutter analyze --no-pub
flutter test
```

کد Worker و تست‌های API در پروژهٔ محلی اصلی نگهداری می‌شوند و در این مخزن عمومی قرار ندارند.

## ساخت وب

نسخهٔ وب باید از **همان دامنهٔ API** سرو شود. نشست کاربر در کوکی `HttpOnly; Secure; SameSite=Strict` قرار دارد؛ میزبانی مستقل در GitHub Pages نمی‌تواند از نشست دامنهٔ Worker استفاده کند. مرورگر کوکی را مدیریت می‌کند و اپ آن را در localStorage کپی نمی‌کند.

```sh
flutter build web --release --dart-define=API_BASE_URL=https://money-tracker.parhamharouni9.workers.dev
```

خروجی در `build/web/` است. تنظیمات Worker در پروژهٔ اصلی این خروجی را به‌عنوان فایل‌های وب همان دامنه منتشر می‌کند. GitHub Pages این مخزن به سایت اصلی هدایت می‌شود.

برای اجرای محلی همراه Worker، API و وب باید روی یک دامنه اجرا شوند تا نشست مرورگر کار کند.
