📱 ServicePro - Local Job Hub

แอปพลิเคชันสำหรับหางานและจ้างงานในพื้นที่ใกล้เคียง
พัฒนาด้วย Flutter (Frontend) และ Node.js + MySQL (Backend)

🚀 Features
👤 ผู้ใช้งาน (User)
สมัครสมาชิก / เข้าสู่ระบบ
ดูงานใกล้ตัว
รับงาน / ส่งงาน
แชทกับผู้ว่าจ้าง
โทรหาผู้ใช้งาน (Voice Call)
ดูรายได้
ถอนเงิน
อัปโหลดผลงาน (Portfolio)
🧑‍💼 ผู้ดูแลระบบ (Admin)
จัดการผู้ใช้งาน
ระงับบัญชี
จัดการประกาศ (Announcement)
ดูรายงาน (Report)
ดู Dashboard รายได้
🛠 Tech Stack
Frontend
Flutter
Dart
Backend
Node.js
Express.js
MySQL
JWT Authentication
⚙️ การติดตั้งและรันระบบ
🔹 1. Clone Project
git clone <your-repo-url>
cd flutter_app_fixed
🔹 2. ติดตั้ง Backend
cd backend
npm install

ถ้ามี error เช่น multer not found ให้รัน:

npm install multer
🔹 3. ตั้งค่า .env

สร้างไฟล์ .env ในโฟลเดอร์ backend

DB_HOST=localhost
DB_USER=root
DB_PASSWORD=yourpassword
DB_NAME=servicepro_db

JWT_SECRET=your_secret_key
PORT=3000
🔹 4. รัน Backend
node server.js

หรือ

npx nodemon server.js

ถ้าสำเร็จจะขึ้น:

Server running on port 3000
🔹 5. รัน Flutter
cd ..
flutter pub get
flutter run
📡 การเชื่อมต่อมือถือ

⚠️ สำคัญมาก

ถ้ารันบนมือถือ ห้ามใช้ localhost

ให้ใช้ IP ของเครื่องแทน เช่น:

http://192.168.1.162:3000

มือถือกับคอมต้องอยู่ WiFi เดียวกัน

🖼 การแสดงรูปภาพ

รูปถูกเก็บใน:

/backend/uploads/

Backend เปิดใช้งานด้วย:

app.use('/uploads', express.static('uploads'));

ตัวอย่าง URL รูป:

http://192.168.1.162:3000/uploads/jobs/image.jpg
💰 ระบบรายได้และถอนเงิน
คำนวณจากตาราง earnings
ถอนเงินผ่าน API:
POST /api/users/:id/withdraw

ตัวอย่าง response:

{
  "message": "ถอนเงินสำเร็จ",
  "withdrawal": {
    "amount": 1500,
    "status": "success"
  }
}
💬 ระบบแชท
ใช้ API:
POST /api/chat-v2/conversations/start-user-chat
รองรับ User ↔ User
📞 ระบบโทร (Voice Call)
ใช้ Agora SDK
ใช้ channel name:
call_job_{jobId}_{userId}
⚠️ ปัญหาที่พบบ่อย
❌ รูปไม่ขึ้น
ใช้ localhost แทน IP
URL เป็น https แต่ server เป็น http
❌ Login ไม่ได้ (Handshake error)

แก้จาก:

https://192.168.x.x

เป็น:

http://192.168.x.x
❌ Server รันไม่ได้

ติดตั้ง dependency:

npm install
❌ Flutter ไม่เจอมือถือ
flutter devices
adb devices
📂 โครงสร้างโปรเจกต์
flutter_app_fixed/
│
├── lib/
│   ├── pages/
│   ├── services/
│   └── main.dart
│
├── backend/
│   ├── routes/
│   ├── uploads/
│   ├── db.js
│   └── server.js
👨‍💻 ผู้พัฒนา
Pakin Narkjaroen
Natsaran Pommachot

📌 หมายเหตุ

โปรเจกต์นี้ใช้เพื่อการศึกษา
สามารถพัฒนาเพิ่มเติมได้ เช่น:

ระบบแจ้งเตือน
ระบบจ่ายเงินจริง
ระบบรีวิวขั้นสูง
