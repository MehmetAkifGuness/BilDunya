import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useAuth } from '../context/AuthContext';

export function ProfileScreen() {
  const insets = useSafeAreaInsets();
  const { userId, isSignedIn, signInDemo, signOut } = useAuth();

  return (
    <View style={[styles.wrap, { paddingTop: insets.top + 16 }]}>
      <Text style={styles.title}>Profil</Text>
      <Text style={styles.sub}>
        {isSignedIn ? `Oturum: ${userId}` : 'Giriş yapılmadı — Pin eklemek için giriş gerekir.'}
      </Text>

      {!isSignedIn ? (
        <Pressable style={styles.btn} onPress={() => signInDemo('demo-user-1')}>
          <Text style={styles.btnText}>Demo giriş</Text>
        </Pressable>
      ) : (
        <Pressable style={[styles.btn, styles.btnOut]} onPress={signOut}>
          <Text style={styles.btnTextOut}>Çıkış</Text>
        </Pressable>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { flex: 1, paddingHorizontal: 20, backgroundColor: '#f8fafc' },
  title: { fontSize: 24, fontWeight: '800', color: '#0f172a' },
  sub: { marginTop: 12, fontSize: 15, color: '#475569' },
  btn: {
    marginTop: 24,
    backgroundColor: '#0d9488',
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
  },
  btnText: { color: '#fff', fontWeight: '800', fontSize: 16 },
  btnOut: { backgroundColor: '#e2e8f0' },
  btnTextOut: { color: '#0f172a', fontWeight: '800', fontSize: 16 },
});
