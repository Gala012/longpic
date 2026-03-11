import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../utils/index.dart';
class LongPicSelectPhotoLogic extends GetxController {
  late final String mode;
  String? templateId;
  String? templateName;
  int? maxCount;
  final albums = <AssetPathEntity>[].obs;
  AssetPathEntity? currentAlbum;
  final photos = <AssetEntity>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  static const int pageSize = 60;
  int currentPage = 0;
  bool hasMorePhotos = true;
  int totalCount = 0;
  final ScrollController scrollController = ScrollController();
  final selectedPhotos = <AssetEntity>[].obs;
  @override
  void onInit() {
    super.onInit();
    mode = Get.parameters['mode'] ?? 'vertical';
    if (mode == 'poster') {
      templateId = Get.parameters['templateId'];
      templateName = Get.parameters['templateName'];
      final maxCountStr = Get.parameters['maxCount'];
      if (maxCountStr != null) {
        maxCount = int.tryParse(maxCountStr);
      }
    }
    _requestPermissionAndLoad();
    _initScrollListener();
  }
  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
  void _initScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore.value &&
          hasMorePhotos) {
        _loadMorePhotos();
      }
    });
  }
  Future<void> _requestPermissionAndLoad() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth || ps.hasAccess) {
        await _loadAlbums();
      } else {
        _showPermissionDialog();
      }
    } catch (e) {
      errorToast('Failed to access photos: ${e.toString()}');
    }
  }
  void _showPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Photo Access Required'),
        content: const Text(
          'Please allow access to your photos in Settings to select images.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              PhotoManager.openSetting();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  Future<void> _loadAlbums() async {
    try {
      isLoading.value = true;
      final list = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );
      albums.value = list;
      if (list.isNotEmpty) {
        await _loadPhotos(list.first);
      }
    } catch (e) {
      errorToast('Failed to load albums');
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> _loadPhotos(AssetPathEntity album) async {
    try {
      isLoading.value = true;
      currentAlbum = album;
      currentPage = 0;
      hasMorePhotos = true;
      photos.clear();
      totalCount = await album.assetCountAsync;
      final end = pageSize < totalCount ? pageSize : totalCount;
      final assets = await album.getAssetListRange(start: 0, end: end);
      photos.value = assets;
      currentPage = 1;
      hasMorePhotos = photos.length < totalCount;
    } catch (e) {
      errorToast('Failed to load photos');
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> _loadMorePhotos() async {
    if (currentAlbum == null || isLoadingMore.value || !hasMorePhotos) return;
    try {
      isLoadingMore.value = true;
      final start = currentPage * pageSize;
      final end = start + pageSize;
      final actualEnd = end < totalCount ? end : totalCount;
      if (start >= totalCount) {
        hasMorePhotos = false;
        return;
      }
      final assets =
          await currentAlbum!.getAssetListRange(start: start, end: actualEnd);
      photos.addAll(assets);
      currentPage++;
      hasMorePhotos = photos.length < totalCount;
    } catch (e) {
      errorToast('Failed to load more photos');
    } finally {
      isLoadingMore.value = false;
    }
  }
  void onPhotoTap(AssetEntity photo) {
    if (selectedPhotos.contains(photo)) {
      selectedPhotos.remove(photo);
    } else {
      if (mode == 'poster' &&
          maxCount != null &&
          selectedPhotos.length >= maxCount!) {
        errorToast('Maximum $maxCount photos allowed');
        return;
      }
      selectedPhotos.add(photo);
    }
  }
  bool isSelected(AssetEntity photo) => selectedPhotos.contains(photo);
  int selectionOrder(AssetEntity photo) => selectedPhotos.indexOf(photo) + 1;
  Future<List<String>> _compressPhotos(List<AssetEntity> photos) async {
    final compressedPaths = <String>[];
    final tempDir = await getTemporaryDirectory();
    for (int i = 0; i < photos.length; i++) {
      try {
        final originBytes = await photos[i].originBytes;
        if (originBytes == null) continue;
        final image = img.decodeImage(originBytes);
        if (image == null) continue;
        final maxDimension = 2048;
        img.Image processedImage = image;
        if (image.width > maxDimension || image.height > maxDimension) {
          if (image.width > image.height) {
            processedImage = img.copyResize(
              image,
              width: maxDimension,
            );
          } else {
            processedImage = img.copyResize(
              image,
              height: maxDimension,
            );
          }
        }
        final compressedBytes = img.encodeJpg(processedImage, quality: 85);
        final fileName =
            'compressed_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final filePath = '${tempDir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(compressedBytes);
        compressedPaths.add(filePath);
      } catch (e) {
        debugPrint('Error compressing photo $i: $e');
      }
    }
    return compressedPaths;
  }
  Future<void> onDoneTap() async {
    if (selectedPhotos.isEmpty) return;
    if (mode == 'poster' &&
        maxCount != null &&
        selectedPhotos.length != maxCount) {
      errorToast('Please select exactly $maxCount photos');
      return;
    }
    Get.dialog(
      const Center(
        child: Card(
          color: Colors.black87,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Compressing images...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
    try {
      final compressedPaths = await _compressPhotos(selectedPhotos);
      Get.back();
      if (compressedPaths.isEmpty) {
        errorToast('Failed to compress images');
        return;
      }
      final targetRoute = _getTargetRoute(mode);
      final arguments = {
        'photos': compressedPaths,
        'mode': mode,
      };
      if (mode == 'poster') {
        if (templateId != null) arguments['templateId'] = templateId!;
        if (templateName != null) arguments['templateName'] = templateName!;
      }
      Get.toNamed(targetRoute, arguments: arguments);
    } catch (e) {
      Get.back();
      errorToast('Failed to process images: ${e.toString()}');
    }
  }
  String _getTargetRoute(String mode) {
    switch (mode) {
      case 'horizontal':
        return '/long_edit_horizontal';
      case 'grid':
        return '/long_edit_grid';
      case 'poster':
        return '/long_edit_poster';
      case 'vertical':
      case 'smart':
      default:
        return '/long_edit_vertical';
    }
  }
}
class _AlbumPickerSheet extends StatelessWidget {
  final List<AssetPathEntity> albums;
  final AssetPathEntity? current;
  const _AlbumPickerSheet({required this.albums, required this.current});
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: albums.length,
              itemBuilder: (_, i) {
                final album = albums[i];
                final isSelected = album.id == current?.id;
                return ListTile(
                  title: Text(
                    album.name,
                    style: TextStyle(
                      color: isSelected ? Colors.green : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => Get.back(result: album),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
