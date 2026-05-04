import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  FlatList,
  KeyboardAvoidingView,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { auth } from '../firebase/firebase-config';
import { sendChatMessage, subscribeToMessages } from '../services/chat';

function formatTime(ts) {
  if (!ts) return '';
  try {
    const d = ts.toDate ? ts.toDate() : new Date(ts);
    return d.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
  } catch {
    return '';
  }
}

export function ChatScreen({ navigation, route }) {
  const { chatId, peerName, placeName, peerId } = route.params || {};
  const myUid = auth.currentUser?.uid;

  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(true);
  const [sendBusy, setSendBusy] = useState(false);
  const listRef = useRef(null);

  useEffect(() => {
    if (!chatId) {
      Alert.alert('Hata', 'Sohbet bilgisi eksik.');
      navigation.goBack();
      return;
    }

    const unsub = subscribeToMessages(
      chatId,
      (list) => {
        setMessages(list);
        setLoading(false);
      },
      (err) => {
        setLoading(false);
        Alert.alert('Sunucu hatası', err.message || 'Mesajlar yüklenemedi.');
      },
    );

    return () => unsub();
  }, [chatId, navigation]);

  const onSend = useCallback(async () => {
    const text = input.trim();
    if (!text) return;
    if (!peerId) {
      Alert.alert('Hata', 'Alıcı bilgisi eksik.');
      return;
    }
    setSendBusy(true);
    try {
      await sendChatMessage({ chatId, text, receiverId: peerId });
      setInput('');
    } catch (e) {
      Alert.alert('Sunucu hatası', e.message || 'Mesaj gönderilemedi.');
    } finally {
      setSendBusy(false);
    }
  }, [chatId, input, peerId]);

  const renderItem = useCallback(
    ({ item }) => {
      const mine = item.senderId === myUid;
      return (
        <View
          style={[styles.row, mine ? styles.rowMine : styles.rowTheirs]}
        >
          <View style={[styles.bubble, mine ? styles.bubbleMine : styles.bubbleTheirs]}>
            <Text style={[styles.bubbleText, mine && styles.bubbleTextMine]}>
              {item.text}
            </Text>
            <Text style={[styles.time, mine && styles.timeMine]}>
              {formatTime(item.createdAt)}
            </Text>
          </View>
        </View>
      );
    },
    [myUid],
  );

  return (
    <SafeAreaView style={styles.safe} edges={['top', 'bottom']}>
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={Platform.OS === 'ios' ? 8 : 0}
      >
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()} hitSlop={12}>
            <Text style={styles.back}>‹ Geri</Text>
          </TouchableOpacity>
          <View style={styles.headerText}>
            <Text style={styles.peerName} numberOfLines={1}>
              {peerName || 'Sohbet'}
            </Text>
            <Text style={styles.placeName} numberOfLines={1}>
              {placeName ? `Mekan: ${placeName}` : ''}
            </Text>
          </View>
          <View style={styles.headerSpacer} />
        </View>

        {loading ? (
          <View style={styles.centered}>
            <ActivityIndicator size="large" />
          </View>
        ) : (
          <FlatList
            ref={listRef}
            data={messages}
            keyExtractor={(item) => item.id}
            renderItem={renderItem}
            contentContainerStyle={styles.listContent}
            onContentSizeChange={() =>
              listRef.current?.scrollToEnd({ animated: true })
            }
          />
        )}

        <View style={styles.inputBar}>
          <TextInput
            style={styles.input}
            value={input}
            onChangeText={setInput}
            placeholder="Mesaj yazın…"
            placeholderTextColor="#889"
            multiline
            maxLength={2000}
            editable={!sendBusy}
          />
          <TouchableOpacity
            style={[styles.sendBtn, (!input.trim() || sendBusy) && styles.sendDisabled]}
            onPress={onSend}
            disabled={!input.trim() || sendBusy}
          >
            {sendBusy ? (
              <ActivityIndicator color="#fff" size="small" />
            ) : (
              <Text style={styles.sendLabel}>Gönder</Text>
            )}
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#e8e4dc' },
  flex: { flex: 1 },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 10,
    backgroundColor: '#1e3a2f',
  },
  back: { color: '#a8e6cf', fontSize: 16, paddingHorizontal: 6 },
  headerText: { flex: 1, marginHorizontal: 8 },
  headerSpacer: { width: 56 },
  peerName: { color: '#fff', fontSize: 17, fontWeight: '700' },
  placeName: { color: '#a8e6cf', fontSize: 13, marginTop: 2 },
  listContent: { padding: 12, paddingBottom: 8 },
  row: { marginVertical: 3, flexDirection: 'row' },
  rowMine: { justifyContent: 'flex-end' },
  rowTheirs: { justifyContent: 'flex-start' },
  bubble: {
    maxWidth: '78%',
    borderRadius: 14,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  bubbleMine: { backgroundColor: '#dcf8c6' },
  bubbleTheirs: { backgroundColor: '#fff' },
  bubbleText: { color: '#111', fontSize: 15, lineHeight: 20 },
  bubbleTextMine: { color: '#111' },
  time: { fontSize: 11, color: '#667', marginTop: 4, alignSelf: 'flex-end' },
  timeMine: { color: '#486' },
  inputBar: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    padding: 8,
    backgroundColor: '#f0f0f0',
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: '#ccc',
  },
  input: {
    flex: 1,
    maxHeight: 100,
    backgroundColor: '#fff',
    borderRadius: 20,
    paddingHorizontal: 14,
    paddingVertical: 10,
    fontSize: 16,
    marginRight: 8,
  },
  sendBtn: {
    backgroundColor: '#128c7e',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 20,
    minWidth: 88,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sendDisabled: { opacity: 0.45 },
  sendLabel: { color: '#fff', fontWeight: '700', fontSize: 15 },
  centered: { flex: 1, justifyContent: 'center', alignItems: 'center' },
});
