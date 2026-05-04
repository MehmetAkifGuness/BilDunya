import React, { useCallback, useMemo, useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, View } from 'react-native';
import MapView, { Marker } from 'react-native-maps';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useBottomTabBarHeight } from '@react-navigation/elements';
import { AddPinModal } from '../components/AddPinModal';
import { useAuth } from '../context/AuthContext';
import { createPinRequest } from '../services/pinApi';

const INITIAL_REGION = {
  latitude: 38.6431,
  longitude: 34.8282,
  latitudeDelta: 0.35,
  longitudeDelta: 0.35,
};

export function MapScreen() {
  const insets = useSafeAreaInsets();
  const tabBarHeight = useBottomTabBarHeight();
  const { userId, isSignedIn } = useAuth();

  const [region, setRegion] = useState(INITIAL_REGION);
  /** Haritada uzun basınca seçilen nokta; yoksa merkez kullanılır. */
  const [selectedCoordinate, setSelectedCoordinate] = useState(null);
  const [modalOpen, setModalOpen] = useState(false);

  const fabBottom = tabBarHeight + insets.bottom + 20;
  const approxFabHeight = 52;
  /** Sol FAB ile çakışmayı azaltmak için harita iç boşluğu */
  const mapPadLeft = 132;

  const getPinCoordinates = useCallback(() => {
    if (
      selectedCoordinate &&
      typeof selectedCoordinate.latitude === 'number' &&
      typeof selectedCoordinate.longitude === 'number'
    ) {
      return {
        lat: selectedCoordinate.latitude,
        lng: selectedCoordinate.longitude,
      };
    }
    if (region && typeof region.latitude === 'number' && typeof region.longitude === 'number') {
      return { lat: region.latitude, lng: region.longitude };
    }
    return null;
  }, [region, selectedCoordinate]);

  const onSavePin = useCallback(
    async ({ title, description, image }) => {
      const coords = getPinCoordinates();
      if (!coords || !userId) {
        throw new Error('Konum veya kullanıcı bilgisi eksik.');
      }
      await createPinRequest({
        title,
        description,
        image: image ?? null,
        lat: coords.lat,
        lng: coords.lng,
        userId,
      });
      Alert.alert('Tamam', 'Pin sunucuya gönderildi.');
    },
    [getPinCoordinates, userId],
  );

  const openFab = useCallback(() => {
    if (!isSignedIn) {
      Alert.alert('Giriş gerekli', 'Pin eklemek için Profil sekmesinden giriş yapın.');
      return;
    }
    setModalOpen(true);
  }, [isSignedIn]);

  const hintText = useMemo(
    () =>
      selectedCoordinate
        ? 'Seçili nokta: uzun basış. Kayıtta bu koordinat kullanılır.'
        : 'Pin konumu: harita merkezi. Nokta seçmek için haritaya uzun basın.',
    [selectedCoordinate],
  );

  return (
    <View style={styles.container}>
      <MapView
        style={StyleSheet.absoluteFill}
        initialRegion={INITIAL_REGION}
        onRegionChangeComplete={setRegion}
        onLongPress={(e) => {
          const c = e.nativeEvent.coordinate;
          setSelectedCoordinate({
            latitude: c.latitude,
            longitude: c.longitude,
          });
        }}
        showsUserLocation={false}
        mapPadding={{
          top: insets.top + 8,
          right: 16,
          bottom: fabBottom + approxFabHeight + 16,
          left: mapPadLeft,
        }}
      >
        {selectedCoordinate ? (
          <Marker coordinate={selectedCoordinate} title="Pin konumu" pinColor="#0d9488" />
        ) : null}
      </MapView>

      <View pointerEvents="box-none" style={StyleSheet.absoluteFill}>
        <View style={[styles.hintWrap, { top: insets.top + 8 }]}>
          <Text style={styles.hint}>{hintText}</Text>
        </View>

        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Pin ekle"
          onPress={openFab}
          style={({ pressed }) => [
            styles.fab,
            {
              left: 20,
              bottom: fabBottom,
              opacity: pressed ? 0.9 : 1,
            },
          ]}
        >
          <Text style={styles.fabIcon}>＋</Text>
          <Text style={styles.fabLabel}>Pin ekle</Text>
        </Pressable>
      </View>

      <AddPinModal
        visible={modalOpen}
        onClose={() => setModalOpen(false)}
        onSave={onSavePin}
        getCoordinates={getPinCoordinates}
        isSignedIn={isSignedIn}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000' },
  hintWrap: {
    position: 'absolute',
    left: 12,
    right: 12,
    zIndex: 2,
  },
  hint: {
    backgroundColor: 'rgba(255,255,255,0.92)',
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 10,
    fontSize: 12,
    color: '#333',
    overflow: 'hidden',
  },
  fab: {
    position: 'absolute',
    zIndex: 10,
    elevation: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: '#0d9488',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 28,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
  },
  fabIcon: { color: '#fff', fontSize: 20, fontWeight: '800' },
  fabLabel: { color: '#fff', fontSize: 15, fontWeight: '800' },
});
