import asyncio
import os
import sys
from telethon import TelegramClient
from telethon.sessions import StringSession

# .env.tg dan sozlamalarni o'qiymiz
def load_env(env_path=".env.tg"):
    env_vars = {}
    if os.path.exists(env_path):
        with open(env_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    env_vars[k.strip()] = v.strip()
    return env_vars

ENV = load_env()
API_ID = int(ENV["API_ID"])
API_HASH = ENV["API_HASH"]
STRING_SESSION = ENV.get("STRING_SESSION", "")

def get_client():
    if not STRING_SESSION:
        raise ValueError(".env.tg faylida STRING_SESSION topilmadi!")
    return TelegramClient(StringSession(STRING_SESSION), API_ID, API_HASH)

async def cmd_me():
    async with get_client() as client:
        me = await client.get_me()
        print("================ AKKAUNT MA'LUMOTLARI ================")
        print(f"Ism: {me.first_name} {me.last_name or ''}".strip())
        print(f"Username: @{me.username or 'yoq'}")
        print(f"Telegram ID: {me.id}")
        print(f"Telefon raqam: +{me.phone}")
        print(f"Premium: {'Ha' if me.premium else 'Yoq'}")
        print("======================================================")

async def cmd_chats(limit=15):
    async with get_client() as client:
        print(f"=== SO'NGGI CHATLAR (Jami: {limit}) ===")
        async for dialog in client.iter_dialogs(limit=limit):
            chat_type = "Foydalanuvchi" if dialog.is_user else ("Kanal" if dialog.is_channel else "Guruh")
            unread = f"({dialog.unread_count} ta o'qilmagan)" if dialog.unread_count else ""
            print(f"• [{chat_type}] {dialog.name} | ID: {dialog.id} {unread}")

async def cmd_send(target: str, message: str):
    async with get_client() as client:
        # ID raqam bo'lsa int ga o'giramiz
        peer = int(target) if (target.isdigit() or (target.startswith("-") and target[1:].isdigit())) else target
        sent = await client.send_message(peer, message)
        print(f"[+] Xabar yuborildi! Xabar ID: {sent.id} -> {target}")

async def main():
    if len(sys.argv) < 2:
        print("Boshqaruv buyruqlari:")
        print("  python account_controller.py me                  # Akkaunt ma'lumotlari")
        print("  python account_controller.py chats [limit]       # Oxirgi chatlar ro'yxati")
        print("  python account_controller.py send <ID/@user> <matn>  # Xabar yuborish")
        return

    cmd = sys.argv[1]
    if cmd == "me":
        await cmd_me()
    elif cmd == "chats":
        limit = int(sys.argv[2]) if len(sys.argv) > 2 else 15
        await cmd_chats(limit)
    elif cmd == "send":
        if len(sys.argv) < 4:
            print("Xato: python account_controller.py send <target> <matn>")
            return
        target = sys.argv[2]
        text = " ".join(sys.argv[3:])
        await cmd_send(target, text)
    else:
        print(f"Noma'lum buyruq: {cmd}")

if __name__ == "__main__":
    asyncio.run(main())
