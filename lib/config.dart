class Config {
  // 🔴 เปลี่ยนตรงนี้ที่เดียวพอ
  static const String baseUrl = 'http://192.168.1.162:3000';

  // ตัวช่วยต่อ path รูป
  static String getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }
    return '$baseUrl/$path';
  }
}