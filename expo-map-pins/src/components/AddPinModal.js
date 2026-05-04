import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Modal,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import * as FileSystem from 'expo-file-system';

/**
 * @param {object} props
 * @param {boolean} props.visible
 * @param {() => void} props.onClose
 * @param {(payload: { title: string, description: string, image: string | null }) => Promise<void>} props.onSave
 * @param {() => { lat: number, lng: number } | null} props.getCoordinates
 * @param {boolean} props.isSignedIn
 */
export function AddPinModal({
  visible,
  onClose,
  onSave,
  getCoordinates,
  isSignedIn,
}) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [imageUri, setImageUri] = useState(null);
  const [imageBase64, setImageBase64] = useState(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!visible) {
      setTitle('');
      setDescription('');
      setImageUri(null);
      setImageBase64(null);
      setSaving(false);
    }
  }, [visible]);

  const pickImage = useCallback(async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) {
      Alert.alert('İzin gerekli', 'Fotoğraf seçmek için galeri izni verin.');
      return;
    }
    const res = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      quality: 0.85,
      allowsEditing: true,
    });
    if (res.canceled || !res.assets?.[0]) return;
    const uri = res.assets[0].uri;
    setImageUri(uri);
    try {
      const base64 = await FileSystem.readAsStringAsync(uri, {
        encoding: FileSystem.EncodingType.Base64,
      });
      const mime = uri.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
      setImageBase64(`data:${mime};base64,${base64}`);
    } catch (e) {
      console.log('IMAGE READ ERROR', e);
      setImageBase64(null);
      Alert.alert('Hata', 'Fotoğraf okunamadı.');
    }
  }, []);

  const clearImage = useCallback(() => {
    setImageUri(null);
    setImageBase64(null);
  }, []);

  const handleSave = useCallback(async () => {
    if (!isSignedIn) {
      Alert.alert('Giriş gerekli', 'Pin eklemek için oturum açın.');
      return;
    }

    const t = title.trim();
    const d = description.trim();
    if (!t) {
      Alert.alert('Eksik bilgi', 'Başlık boş olamaz.');
      return;
    }
    if (!d) {
      Alert.alert('Eksik bilgi', 'Açıklama boş olamaz.');
      return;
    }

    const coords = getCoordinates();
    if (
      !coords ||
      typeof coords.lat !== 'number' ||
      typeof coords.lng !== 'number' ||
      Number.isNaN(coords.lat) ||
      Number.isNaN(coords.lng)
    ) {
      Alert.alert('Konum yok', 'Harita konumu alınamadı. Haritayı hareket ettirip tekrar deneyin.');
      return;
    }

    setSaving(true);
    try {
      await onSave({
        title: t,
        description: d,
        image: imageBase64,
      });
      onClose();
    } catch (e) {
      Alert.alert('Pin eklenemedi', e.message || 'Beklenmeyen bir hata oluştu.');
    } finally {
      setSaving(false);
    }
  }, [
    description,
    getCoordinates,
    imageBase64,
    isSignedIn,
    onClose,
    onSave,
    title,
  ]);

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent
      onRequestClose={onClose}
    >
      <Pressable style={styles.backdrop} onPress={onClose}>
        <Pressable style={styles.sheet} onPress={(e) => e.stopPropagation()}>
          <Text style={styles.sheetTitle}>Yeni pin</Text>

          <Text style={styles.label}>Başlık</Text>
          <TextInput
            style={styles.input}
            value={title}
            onChangeText={setTitle}
            placeholder="Başlık"
            maxLength={200}
          />

          <Text style={styles.label}>Açıklama</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            value={description}
            onChangeText={setDescription}
            placeholder="Açıklama"
            multiline
            maxLength={2000}
          />

          <Text style={styles.label}>Fotoğraf (opsiyonel)</Text>
          <View style={styles.photoRow}>
            <Pressable style={styles.secondaryBtn} onPress={pickImage}>
              <Text style={styles.secondaryBtnText}>Seç</Text>
            </Pressable>
            {imageUri ? (
              <Pressable style={styles.secondaryBtn} onPress={clearImage}>
                <Text style={styles.secondaryBtnText}>Kaldır</Text>
              </Pressable>
            ) : null}
          </View>

          <View style={styles.actions}>
            <Pressable style={styles.secondaryBtn} onPress={onClose} disabled={saving}>
              <Text style={styles.secondaryBtnText}>İptal</Text>
            </Pressable>
            <Pressable
              style={[styles.primaryBtn, saving && styles.btnDisabled]}
              onPress={handleSave}
              disabled={saving}
            >
              {saving ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <Text style={styles.primaryBtnText}>Kaydet</Text>
              )}
            </Pressable>
          </View>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.45)',
    justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: '#fff',
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    paddingHorizontal: 20,
    paddingTop: 18,
    paddingBottom: 28,
  },
  sheetTitle: { fontSize: 18, fontWeight: '800', marginBottom: 14, color: '#111' },
  label: { fontSize: 12, fontWeight: '700', color: '#555', marginBottom: 6, marginTop: 10 },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 16,
    color: '#111',
  },
  textArea: { minHeight: 88, textAlignVertical: 'top' },
  photoRow: { flexDirection: 'row', gap: 10, marginTop: 8 },
  actions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 12,
    marginTop: 22,
  },
  primaryBtn: {
    backgroundColor: '#0d9488',
    paddingHorizontal: 22,
    paddingVertical: 12,
    borderRadius: 10,
    minWidth: 110,
    alignItems: 'center',
  },
  primaryBtnText: { color: '#fff', fontWeight: '800', fontSize: 16 },
  secondaryBtn: {
    backgroundColor: '#e5e7eb',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 10,
  },
  secondaryBtnText: { color: '#111', fontWeight: '700', fontSize: 15 },
  btnDisabled: { opacity: 0.6 },
});
