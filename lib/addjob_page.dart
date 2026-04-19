import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'myjobs_page.dart';
import 'services/auth_service.dart';
import 'services/job_api_service.dart';

class AddJobPage extends StatefulWidget {
  const AddJobPage({super.key});

  @override
  State<AddJobPage> createState() => _AddJobPageState();
}

class _AddJobPageState extends State<AddJobPage> {
  static const Color _green = Color(0xFF00E676);

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _imageName;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedCategory;
  bool _isSaving = false;

  GoogleMapController? _mapController;
  LatLng _pickedLatLng = const LatLng(13.7563, 100.5018);
  final Set<Marker> _markers = {};
  bool _isSearching = false;

  final List<String> _categories = [
    'บริการช่าง',
    'งานปรับปรุง',
    'งานซ่อมบำรุง',
    'ยานยนต์',
    'งานบ้านและสวน',
  ];

  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _updateMarker(_pickedLatLng);
    _reverseGeocode(_pickedLatLng);
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (!mounted) return;
      setState(() => currentUserId = userId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarker(LatLng pos) {
    setState(() {
      _pickedLatLng = pos;
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('job_location'),
            position: pos,
            draggable: true,
            onDragEnd: (newPos) => _onMarkerDragged(newPos),
          ),
        );
    });
  }

  void _onMarkerDragged(LatLng newPos) {
    _updateMarker(newPos);
    _reverseGeocode(newPos);
  }

  void _onMapTap(LatLng pos) {
    _updateMarker(pos);
    _reverseGeocode(pos);
  }

  Future<String> _getGoogleFormattedAddress(LatLng pos) async {
    final url = Uri.parse(
      'http://192.168.1.162:3000/api/maps/reverse-geocode?lat=${pos.latitude}&lng=${pos.longitude}',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    debugPrint('Backend reverse-geocode response: $data');

    if (response.statusCode == 200 && data['success'] == true) {
      return data['address'] as String;
    }

    return 'ไม่พบชื่อสถานที่ (${data['status'] ?? data['message'] ?? 'UNKNOWN'})';
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final address = await _getGoogleFormattedAddress(pos);
      if (!mounted) return;

      setState(() {
        _locationController.text = address;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationController.text = 'ไม่พบชื่อสถานที่ ($e)';
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'http://192.168.1.162:3000/api/maps/search-geocode?q=${Uri.encodeComponent(query)}',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      debugPrint('Backend search-geocode response: $data');

      if (response.statusCode == 200 && data['success'] == true && mounted) {
        final latLng = LatLng(
          (data['lat'] as num).toDouble(),
          (data['lng'] as num).toDouble(),
        );

        _updateMarker(latLng);

        setState(() {
          _locationController.text = data['address'] as String;
        });

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ไม่พบสถานที่ที่ค้นหา (${data['status'] ?? data['message'] ?? 'UNKNOWN'})',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ไม่พบสถานที่ที่ค้นหา ($e)')));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _expandMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullMapPage(
          initialLatLng: _pickedLatLng,
          onLocationPicked: (latLng, address) {
            _updateMarker(latLng);
            setState(() => _locationController.text = address);
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(latLng, 15),
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _green)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _green)),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _timeController.text = picked.format(context));
    }
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    }
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (currentUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบผู้ใช้ที่ล็อกอิน')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await JobApiService.createJob(
        userId: currentUserId!,
        title: _titleController.text.trim(),
        category: _selectedCategory ?? 'ทั่วไป',
        description: _descController.text.trim(),
        budget: _priceController.text.trim(),
        location: _locationController.text.trim(),
        workDate: _dateController.text.trim(),
        workTime: _timeController.text.trim(),
        imageBytes: _imageBytes,
        imageFileName: _imageName,
        latitude: _pickedLatLng.latitude,
        longitude: _pickedLatLng.longitude,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyJobsPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลงประกาศงานไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ลงประกาศงาน',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('ชื่อหัวข้องาน'),
              _textField(_titleController, 'ระบุชื่อหัวข้องานที่ต้องการจ้าง'),

              const SizedBox(height: 20),

              _label('เลือกหมวดหมู่'),
              _buildDropdown(),

              const SizedBox(height: 20),

              _label('รูปภาพประกอบงาน'),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 38,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'คลิกเพื่อเลือกรูปภาพ',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              _label('รายละเอียดงาน'),
              _textField(
                _descController,
                'อธิบายรายละเอียดของงานที่คุณต้องการเพื่อให้ผู้รับงานเข้าใจ...',
                maxLines: 4,
              ),

              const SizedBox(height: 20),

              _label('งบประมาณ (บาท)'),
              _textField(
                _priceController,
                '0.00',
                suffix: '฿',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              _buildLocationSection(),

              const SizedBox(height: 20),

              _label('วันและเวลาที่ต้องการ'),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: _textField(
                          _dateController,
                          'mm/dd/yyyy',
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectTime,
                      child: AbsorbPointer(
                        child: _textField(
                          _timeController,
                          '--:-- --',
                          prefixIcon: Icons.access_time_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text(
                          'ลงประกาศงาน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('พิกัดสถานที่'),
        TextFormField(
          controller: _locationController,
          onFieldSubmitted: _searchLocation,
          decoration: InputDecoration(
            hintText: 'ใส่ที่อยู่หรือปักหมุดสถานที่',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: _green,
              size: 22,
            ),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _green,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search, color: Colors.grey),
                    onPressed: () => _searchLocation(_locationController.text),
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'กรุณาระบุสถานที่' : null,
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 180,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _pickedLatLng,
                    zoom: 14,
                  ),
                  markers: _markers,
                  onMapCreated: (c) => _mapController = c,
                  onTap: _onMapTap,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _expandMap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.map_outlined,
                              size: 16,
                              color: Color(0xFF444444),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'ขยายแผนที่',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF444444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    ),
  );

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    String? suffix,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'กรุณากรอกข้อมูล' : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.grey, size: 20)
              : null,
          suffixText: suffix,
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 13,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          ),
          hint: const Text(
            'เลือกประเภทงาน',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'กรุณาเลือกหมวดหมู่' : null,
          items: _categories
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v),
        ),
      ),
    );
  }
}

class _FullMapPage extends StatefulWidget {
  final LatLng initialLatLng;
  final void Function(LatLng latLng, String address) onLocationPicked;

  const _FullMapPage({
    required this.initialLatLng,
    required this.onLocationPicked,
  });

  @override
  State<_FullMapPage> createState() => _FullMapPageState();
}

class _FullMapPageState extends State<_FullMapPage> {
  static const Color _green = Color(0xFF00E676);

  GoogleMapController? _ctrl;
  late LatLng _current;
  final Set<Marker> _markers = {};
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;
  String _address = '';

  @override
  void initState() {
    super.initState();
    _current = widget.initialLatLng;
    _updateMarker(_current);
    _reverseGeocode(_current);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  void _updateMarker(LatLng pos) {
    setState(() {
      _current = pos;
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('loc'),
            position: pos,
            draggable: true,
            onDragEnd: (p) {
              _updateMarker(p);
              _reverseGeocode(p);
            },
          ),
        );
    });
  }

  Future<String> _getGoogleFormattedAddress(LatLng pos) async {
    final url = Uri.parse(
      'http://192.168.1.162:3000/api/maps/reverse-geocode?lat=${pos.latitude}&lng=${pos.longitude}',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    debugPrint('Backend reverse-geocode response: $data');

    if (response.statusCode == 200 && data['success'] == true) {
      return data['address'] as String;
    }

    return 'ไม่พบชื่อสถานที่ (${data['status'] ?? data['message'] ?? 'UNKNOWN'})';
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final address = await _getGoogleFormattedAddress(pos);
      if (!mounted) return;

      setState(() {
        _address = address;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _address = 'ไม่พบชื่อสถานที่ ($e)';
      });
    }
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'http://192.168.1.162:3000/api/maps/search-geocode?q=${Uri.encodeComponent(q)}',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      debugPrint('Backend search-geocode response: $data');

      if (response.statusCode == 200 && data['success'] == true && mounted) {
        final ll = LatLng(
          (data['lat'] as num).toDouble(),
          (data['lng'] as num).toDouble(),
        );

        _updateMarker(ll);

        setState(() {
          _address = data['address'] as String;
        });

        _ctrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 15));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ไม่พบสถานที่ (${data['status'] ?? data['message'] ?? 'UNKNOWN'})',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ไม่พบสถานที่ ($e)')));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _current, zoom: 14),
            markers: _markers,
            onMapCreated: (c) => _ctrl = c,
            onTap: (pos) {
              _updateMarker(pos);
              _reverseGeocode(pos);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onSubmitted: _search,
                        decoration: InputDecoration(
                          hintText: 'ค้นหาสถานที่...',
                          hintStyle: const TextStyle(fontSize: 14),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: 20,
                          ),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _green,
                                    ),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: _green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _address.isNotEmpty
                              ? _address
                              : 'แตะบนแผนที่เพื่อเลือกสถานที่',
                          style: TextStyle(
                            fontSize: 14,
                            color: _address.isNotEmpty
                                ? const Color(0xFF1A1A2E)
                                : Colors.grey,
                            fontWeight: _address.isNotEmpty
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onLocationPicked(
                          _current,
                          _address.isNotEmpty ? _address : 'ไม่พบชื่อสถานที่',
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'ยืนยันสถานที่นี้',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
