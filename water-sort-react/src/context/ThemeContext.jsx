import React, { createContext, useContext, useState, useEffect } from 'react';

const ThemeContext = createContext();

export const useTheme = () => useContext(ThemeContext);

export const ThemeProvider = ({ children }) => {
  // Load initial states from localStorage or use defaults
  const [activeTheme, setActiveTheme] = useState(() => {
    return localStorage.getItem('water-sort-theme') || 'classic';
  });

  const [coins, setCoins] = useState(() => {
    return parseInt(localStorage.getItem('water-sort-coins') || '1000', 10);
  });

  const [unlockedThemes, setUnlockedThemes] = useState(() => {
    const saved = localStorage.getItem('water-sort-unlocked-themes');
    return saved ? JSON.parse(saved) : ['classic'];
  });

  const [settings, setSettings] = useState(() => {
    const saved = localStorage.getItem('water-sort-settings');
    return saved ? JSON.parse(saved) : { music: true, sound: false, vibration: false };
  });

  // Theme definitions for logic access
  const themes = {
    classic: { id: 'classic', name: 'Alchemist', price: 0, gradient: 'bg-[#F5F0E8]', icon: '✨' },
    space: { id: 'space', name: 'Space Theme', price: 500, gradient: 'bg-gradient-to-br from-[#0D0D2B] to-[#1A0533]', icon: '🌌' },
    jungle: { id: 'jungle', name: 'Jungle Theme', price: 300, gradient: 'bg-[#E8F0DC]', icon: '🌿' },
  };

  // Sync to localStorage and Document Body whenever activeTheme changes
  useEffect(() => {
    localStorage.setItem('water-sort-theme', activeTheme);
    document.documentElement.setAttribute('data-theme', activeTheme);
  }, [activeTheme]);

  useEffect(() => {
    localStorage.setItem('water-sort-coins', coins.toString());
  }, [coins]);

  useEffect(() => {
    localStorage.setItem('water-sort-unlocked-themes', JSON.stringify(unlockedThemes));
  }, [unlockedThemes]);

  useEffect(() => {
    localStorage.setItem('water-sort-settings', JSON.stringify(settings));
  }, [settings]);

  const unlockTheme = (themeId, price) => {
    if (coins >= price && !unlockedThemes.includes(themeId)) {
      setCoins(prev => prev - price);
      setUnlockedThemes(prev => [...prev, themeId]);
      setActiveTheme(themeId);
      return true;
    }
    return false;
  };

  const equipTheme = (themeId) => {
    if (unlockedThemes.includes(themeId)) {
      setActiveTheme(themeId);
    }
  };

  const addCoins = (amount) => setCoins(prev => prev + amount);

  const toggleSetting = (key) => setSettings(prev => ({ ...prev, [key]: !prev[key] }));

  return (
    <ThemeContext.Provider value={{
      activeTheme, themes, unlockedThemes, coins, settings,
      unlockTheme, equipTheme, addCoins, toggleSetting
    }}>
      {children}
    </ThemeContext.Provider>
  );
};
