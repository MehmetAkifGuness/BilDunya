import React, { createContext, useCallback, useContext, useMemo, useState } from 'react';

const AuthContext = createContext(null);

/** Demo: gerçek uygulamada Firebase / kendi auth’unuzla doldurun. */
export function AuthProvider({ children }) {
  const [userId, setUserId] = useState(null);

  const signInDemo = useCallback((id) => {
    setUserId((id && String(id).trim()) || 'demo-user-1');
  }, []);

  const signOut = useCallback(() => setUserId(null), []);

  const value = useMemo(
    () => ({ userId, signInDemo, signOut, isSignedIn: !!userId }),
    [userId, signInDemo, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth: AuthProvider eksik');
  }
  return ctx;
}
