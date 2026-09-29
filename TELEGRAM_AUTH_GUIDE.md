# Telegram Akkauntni MTProto / Telethon Orqali Ulash va Boshqarish Qo'llanmasi

Ushbu hujjatda Telegram shaxsiy akkauntini Python (`Telethon`) orqali ulash jarayoni, yuzaga kelgan muammolar, ularning texnik sabablari va to'liq yechimlari batafsil bayon etilgan.

---

## 1. Asosiy Maqsad

Telegram shaxsiy akkauntini (`+998940350990`) dasturiy ravishda Telegram MTProto API ga ulab, uni Python orqali to'liq boshqarish:
- Akkaunt profil ma'lumotlarini olish;
- Chatlar, guruhlar va kanallarni o'qish;
- Akkaunt nomidan xabarlar yuborish va avtomatlashtirish;
- Kelgusida Telegram Web App (TWA / Mini App) va botlar bilan integratsiya qilish.

---

## 2. Dastlabki Bosqichda Yuzaga Kelgan Muammolar va Ularning Texnik Sabablari

Ulanish paytida tasdiqlash kodi uzoq vaqt kelmadi. Bunga bir nechta muhim texnik omillar sabab bo'lgan:

### A. Telegram Web (`web.telegram.org`) ga Kod Kelmasligi (Asosiy Sabab)
* **Muammo:** Foydalanuvchi tasdiqlash kodini brauzerdagi Telegram Web orqali kutgan, biroq xabar kelmagan.
* **Texnik Sabab:** Telegram xavfsizlik siyosatiga ko'ra (akkauntlarni o'g'irlash va fishingdan himoyalanish maqsadida), tashqi dasturiy klientlar (`Telethon`, `Pyrogram` va h.k.) orqali so'ralgan login kodlari **brauzerlarga (Telegram Web ga) mutlaqo yuborilmaydi**.
* **Yechim:** Bunday kodlar faqatgina **mobil qurilmadagi (Android yoki iOS) rasmiy Telegram ilovasiga** (ko'k tasdiq belgili «Telegram» xizmat chatiga) keladi.

### B. Yangi Ochilgan `api_id` / `api_hash` va Bo'sh Maydonlar
* **Muammo:** Dastlab `my.telegram.org` dan olingan yangi `api_id: 32670321` ishlatildi, unda `App title` va `Short name` bo'sh qolgan edi.
* **Texnik Sabab:** Telegram yangi yaratilgan va to'liq ma'lumot kiritilmagan API arizalarini shubhali deb baholab, ularga kod jo'natishni vaqtinchalik muzlatib (silent drop) qo'yishi mumkin.
* **Yechim:** Serverdagi ishlab turgan taxi loyihasida mavjud bo'lgan, Telegram tizimida uzoq vaqtdan beri tasdiqlangan va ishonchli `API_ID: 32094368` dan foydalanildi.

### C. Soket Aloqasining Uzilishi (Socket Disconnect)
* **Muammo:** Birinchi skript kod so'rab bo'lgach, jarayonni to'xtatgan (`client.disconnect()`).
* **Texnik Sabab:** Telegram MTProto protokoli kod so'ralganidan so'ng mijoz soketi ochiq turishini (keep-alive) kutadi. Agar mijoz darhol uzilsa, Telegram xavfsizlik nuqtai nazaridan kod yetkazishni to'xtatadi.
* **Yechim:** `auth_flow.py` skripti ishlab chiqildi. U soketni doimiy ochiq ushlab turadi, kod va parolni kiritishni kutadi va bitta jonli sessiyada autentifikatsiyani yakunlaydi.

### D. 2FA (Ikki Bosqichli Xavfsizlik Paroli)
* **Muammo:** Kod kiritilgach, tizim qo'shimcha parol so'radi.
* **Texnik Sabab:** Akkauntda bulutli parol (Two-Step Verification) faollashtirilganligi sababli, Telethon `SessionPasswordNeededError` holatiga tushdi.
* **Yechim:** Skript 2FA parolini ham avtomatik qabul qiladigan qilib sozlandi.

---

## 3. Qanday Ulandik? (Bosqichma-bosqich)

### 1-qadam: Jonli Autentifikatsiya Skripti (`auth_flow.py`)
Skript `StringSession` yordamida ulanishni hosil qildi:
```python
client = TelegramClient(StringSession(), API_ID, API_HASH)
await client.connect()
sent = await client.send_code_request(PHONE)
# Soket ochiq holda terminaldan kod kiritilishini kutadi
code = sys.stdin.readline().strip()
try:
    await client.sign_in(PHONE, code=code, phone_code_hash=sent.phone_code_hash)
except SessionPasswordNeededError:
    password = sys.stdin.readline().strip()
    await client.sign_in(password=password)
```

### 2-qadam: Kod va Parolni Kiritish
- Mobil ilovaga kelgan 5 xonali login kodi: `49069`
- Akkauntning 2FA bulutli paroli kiritildi.

### 3-qadam: Natija va `STRING_SESSION`
Muvaffaqiyatli kirilgach, Telethon tomonidan bitta matnli xavfsiz sessiya (`STRING_SESSION`) generatsiya qilindi va `.env.tg` fayliga yozildi:
- **Foydalanuvchi:** NORVEN (`@norven_admin`)
- **Telegram ID:** `8999024607`
- **Telefon:** `+998940350990`

---

## 4. Akkauntni Boshqarish (`account_controller.py`)

Akkauntni qulay boshqarish uchun maxsus boshqaruv konsoli yaratildi:

### Buyruqlar:
1. **Profilni ko'rish:**
   ```bash
   python account_controller.py me
   ```
2. **So'nggi chatlarni ko'rish:**
   ```bash
   python account_controller.py chats 10
   ```
3. **Akkaunt nomidan xabar yuborish:**
   ```bash
   python account_controller.py send @username "Salom!"
   # yoki ID raqami orqali:
   python account_controller.py send 777000 "Test xabari"
   ```

### Loyihalarga Integratsiya Qilish:
Istalgan Python faylda quyidagicha ulab foydalanish mumkin:
```python
from account_controller import get_client

async def main():
    async with get_client() as client:
        # Masalan, xabar yuborish
        await client.send_message('@username', 'Salom!')
```

---

## 5. Xavfsizlik Qoidalari

> [!CAUTION]
> `.env.tg` faylidagi `STRING_SESSION` bu sizning Telegram akkauntingizning to'liq kalitidir.
> Uni hech qachon ommaviy GitHub repozitoriyalariga joylamang! `.gitignore` fayliga `.env*` va `*.session` qo'shilgan holda saqlanadi.
