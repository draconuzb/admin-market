import asyncio
import sys
from telethon import TelegramClient
from telethon.sessions import StringSession
from telethon.errors import SessionPasswordNeededError, PhoneCodeInvalidError

API_ID = 32094368
API_HASH = "62ca43aa1e9b9525f12bcb3924012c9a"
PHONE = "+998940350990"

async def main():
    print(f"[*] Telegram serveriga ulanmoqda (API_ID: {API_ID})...", flush=True)
    client = TelegramClient(StringSession(), API_ID, API_HASH)
    await client.connect()

    print(f"[*] Kod yuborilmoqda: {PHONE} ...", flush=True)
    sent = await client.send_code_request(PHONE)
    print(f"[+] Kod muvaffaqiyatli yuborildi! (Turi: {type(sent.type).__name__})", flush=True)
    print(f"[WAIT_FOR_CODE] Iltimos, Telegram ilovangizga yoki SMS orqali kelgan 5 xonali kodni kiriting.", flush=True)
    
    loop = asyncio.get_running_loop()
    code = await loop.run_in_executor(None, sys.stdin.readline)
    code = code.strip()
    print(f"[*] Kiritilgan kod tekshirilmoqda...", flush=True)

    try:
        await client.sign_in(PHONE, code=code, phone_code_hash=sent.phone_code_hash)
    except SessionPasswordNeededError:
        print("[WAIT_FOR_PASSWORD] Akkauntda 2FA (ikki bosqichli parol) bor. Parolni kiriting:", flush=True)
        password = await loop.run_in_executor(None, sys.stdin.readline)
        password = password.strip()
        print(f"[*] 2FA parol tekshirilmoqda...", flush=True)
        await client.sign_in(password=password)

    me = await client.get_me()
    session_str = client.session.save()
    
    print("==================================================", flush=True)
    print(f"[MUVAFFAQIYAT] Akkaunt muvaffaqiyatli ulandi!", flush=True)
    print(f"Ism: {me.first_name} {me.last_name or ''}".strip(), flush=True)
    print(f"Username: @{me.username or 'yoq'}", flush=True)
    print(f"ID: {me.id}", flush=True)
    print(f"Telefon: +{me.phone}", flush=True)
    print(f"STRING_SESSION={session_str}", flush=True)
    print("==================================================", flush=True)

    with open(".env.tg", "w", encoding="utf-8") as f:
        f.write(f"API_ID={API_ID}\nAPI_HASH={API_HASH}\nSTRING_SESSION={session_str}\n")
    print("[+] .env.tg fayliga saqlandi!", flush=True)
    await client.disconnect()

if __name__ == "__main__":
    asyncio.run(main())
