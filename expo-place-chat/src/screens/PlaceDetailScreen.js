import React, { useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { auth } from '../firebase/firebase-config';
import { ensurePrivateChat } from '../services/chat';

/**
 * Örnek mekan — gerçek uygulamada route.params veya API’den gelir.
 * ownerId: gönderi sahibinin Firebase Auth uid’si (string).
 */
const DEMO_PLACE = {
  placeId: 'place_demo_1',
  placeName: 'Kapadokya Gün Doğumu Terası',
  ownerId: 'DIGER_KULLANICI_FIREBASE_UID',
  ownerName: 'Ayşe Yılmaz',
};

export function PlaceDetailScreen({ navigation, route }) {
  const place = route.params?.place ?? DEMO_PLACE;
  const [busy, setBusy] = useState(false);

  const currentUid = auth.currentUser?.uid;
  const currentLabel = auth.currentUser?.displayName || auth.currentUser?.email || currentUid || 'Giriş yok';

  const openChat = async () => {
    if (!currentUid) {
      Alert.alert(
        'Oturum gerekli',
        'Mesaj göndermek için Firebase Auth ile giriş yapın.',
      );
      return;
    }

    setBusy(true);
    try {
      const chatId = await ensurePrivateChat({
        peerId: place.ownerId,
        placeId: place.placeId,
        placeName: place.placeName,
      });

      navigation.navigate('Chat', {
        chatId,
        peerId: place.ownerId,
        peerName: place.ownerName,
        placeName: place.placeName,
      });
    } catch (e) {
      Alert.alert('Sunucu hatası', e.message || 'Sohbet açılamadı.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <SafeAreaView style={styles.safe} edges={['top', 'bottom']}>
      <StatusBar style="light" />
      <View style={styles.hero}>
        <Text style={styles.title}>{place.placeName}</Text>
        <Text style={styles.sub}>Sahip: {place.ownerName}</Text>
        {__DEV__ ? (
          <Text style={styles.uidHint} numberOfLines={2}>
            (Dev) Sahip uid: {place.ownerId}
          </Text>
        ) : null}
      </View>

      <View style={styles.card}>
        <Text style={styles.label}>Oturum</Text>
        <Text style={styles.value}>{currentLabel}</Text>
      </View>

      <TouchableOpacity
        style={[styles.msgBtn, busy && styles.msgBtnDisabled]}
        onPress={openChat}
        disabled={busy}
        activeOpacity={0.85}
      >
        {busy ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.msgBtnText}>Mesaj</Text>
        )}
      </TouchableOpacity>

      <Text style={styles.footer}>
        Sohbet kimliği: iki kullanıcı uid’sinin sıralı birleşimi (küçük_büyük). Firestore:{' '}
        chats/{'{chatId}'}/…
      </Text>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#0f172a' },
  hero: { padding: 20, paddingTop: 8 },
  title: { color: '#fff', fontSize: 22, fontWeight: '800' },
  sub: { color: '#94a3b8', fontSize: 16, marginTop: 8 },
  uidHint: { color: '#64748b', fontSize: 11, marginTop: 10 },
  card: {
    marginHorizontal: 16,
    backgroundColor: '#1e293b',
    borderRadius: 12,
    padding: 16,
  },
  label: { color: '#94a3b8', fontSize: 12, marginBottom: 4 },
  value: { color: '#e2e8f0', fontSize: 15 },
  msgBtn: {
    marginHorizontal: 16,
    marginTop: 24,
    backgroundColor: '#22c55e',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  msgBtnDisabled: { opacity: 0.6 },
  msgBtnText: { color: '#fff', fontSize: 17, fontWeight: '800' },
  footer: {
    margin: 16,
    marginTop: 32,
    color: '#64748b',
    fontSize: 11,
    lineHeight: 16,
  },
});
