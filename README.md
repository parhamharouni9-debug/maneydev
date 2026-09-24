# پول من

اپ مدیریت مالی شخصی با Flutter برای Android، iOS و وب. رابط کاربری فارسی است و از تاریخ شمسی استفاده می‌کند.

## بررسی محلی

```sh
flutter pub get
flutter analyze --no-pub
flutter test
```

بخش `backend/` شامل Worker و تست‌های API است. برای بررسی آن، در همان پوشه `npm test` و `npm run check` را اجرا کنید.

## ساخت وب

نسخهٔ وب باید از **همان دامنهٔ API** سرو شود. نشست کاربر در کوکی `HttpOnly; Secure; SameSite=Strict` قرار دارد؛ میزبانی مستقل در GitHub Pages نمی‌تواند از نشست دامنهٔ Worker استفاده کند. مرورگر کوکی را مدیریت می‌کند و اپ آن را در localStorage کپی نمی‌کند.

```sh
flutter build web --release --dart-define=API_BASE_URL=https://money-tracker.parhamharouni9.workers.dev
```

خروجی در `build/web/` است. فایل `backend/wrangler.production.jsonc` این پوشه را به عنوان assets همان Worker معرفی می‌کند. قبل از انتشار، آدرس API و تنظیمات Worker را با محیط مقصد بررسی کنید. GitHub Pages این مخزن صرفاً به سایت اصلی هدایت می‌شود.

برای اجرای محلی با Worker:

```sh
flutter build web --debug --dart-define=API_BASE_URL=http://127.0.0.1:8787
cd backend
npx wrangler dev --config wrangler.jsonc --port 8787 --local
```

سپس `http://127.0.0.1:8787/` را باز کنید. دادهٔ D1 در این حالت محلی است.
