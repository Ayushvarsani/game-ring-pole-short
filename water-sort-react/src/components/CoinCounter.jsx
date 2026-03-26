import React from 'react';
import { motion } from 'framer-motion';
import { ArrowLeft, Settings, ShoppingBasket, Play, RotateCcw, Undo2, Lightbulb, Home } from 'lucide-react';
import { useTheme } from '../context/ThemeContext';

export const CoinCounter = () => {
  const { coins, activeTheme } = useTheme();
  
  // Icon based on theme
  const getIcon = () => {
    switch(activeTheme) {
      case 'space': return <span className="text-xl">💎</span>;
      case 'jungle': return <span className="text-xl">🥥</span>;
      default: return <span className="text-xl text-yellow-500">🪙</span>;
    }
  };

  return (
    <div className="flex items-center gap-1.5 bg-theme-card px-3 py-1.5 rounded-full shadow-theme-glow border border-white/20">
      {getIcon()}
      <span className="font-bold text-theme-primary">{coins}</span>
    </div>
  );
};
