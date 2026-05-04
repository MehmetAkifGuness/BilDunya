import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { AuthProvider } from './src/context/AuthContext';
import { MapScreen } from './src/screens/MapScreen';
import { ProfileScreen } from './src/screens/ProfileScreen';

const Tab = createBottomTabNavigator();

export default function App() {
  return (
    <SafeAreaProvider>
      <AuthProvider>
        <NavigationContainer>
          <StatusBar style="dark" />
          <Tab.Navigator
            screenOptions={{
              headerShown: false,
              tabBarActiveTintColor: '#0d9488',
              tabBarInactiveTintColor: '#64748b',
              tabBarStyle: { paddingTop: 4 },
            }}
          >
            <Tab.Screen
              name="Harita"
              component={MapScreen}
              options={{ tabBarLabel: 'Harita' }}
            />
            <Tab.Screen
              name="Profil"
              component={ProfileScreen}
              options={{ tabBarLabel: 'Profil' }}
            />
          </Tab.Navigator>
        </NavigationContainer>
      </AuthProvider>
    </SafeAreaProvider>
  );
}
