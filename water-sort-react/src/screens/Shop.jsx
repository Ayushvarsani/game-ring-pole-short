import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { ArrowLeft, Lock } from 'lucide-react';
import { useTheme } from '../context/ThemeContext';
import { CoinCounter } from '../components/CoinCounter';

const Shop = () => {
  const navigate = useNavigate();
  const { themes, activeTheme, unlockedThemes, unlockTheme, equipTheme } = useTheme();
  const [activeTab, setActiveTab] = useState('Themes');

  const tabs = ['Bottles', 'Liquids', 'Themes'];

  const pageVariants = {
    initial: { y: 50, opacity: 0 },
    in: { y: 0, opacity: 1 },
    out: { y: -50, opacity: 0 }
  };

  const handleAction = (themeId, price) => {
    if (unlockedThemes.includes(themeId)) {
      equipTheme(themeId);
    } else {
      unlockTheme(themeId, price);
    }
  };

  return (
    <motion.div initial="initial" animate="in" exit="out" variants={pageVariants} className="flex flex-col h-screen bg-theme-main p-6 relative overflow-hidden">
      {/* Header */}
      <div className="flex justify-between items-center mb-6 mt-2 relative z-10">
        <div className="flex items-center gap-4">
          <button onClick={() => navigate(-1)} className="p-3 bg-theme-card rounded-2xl shadow-sm text-theme-primary">
            <ArrowLeft size={24} />
          </button>
          <h1 className="text-2xl font-extrabold text-theme-primary">Shop</h1>
        </div>
        <CoinCounter />
      </div>

      {/* Tabs */}
      <div className="flex justify-between bg-theme-card/60 backdrop-blur-md rounded-2xl p-1 mb-6 relative z-10 shadow-sm border border-black/5">
        {tabs.map(tab => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`flex-1 py-2.5 rounded-xl font-bold text-sm transition-all ${
              activeTab === tab ? 'bg-theme-accent text-white shadow-md' : 'text-theme-secondary hover:text-theme-primary'
            }`}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Store Content */}
      <div className="flex-1 overflow-y-auto pb-10 space-y-4 pr-1 relative z-10 custom-scroll">
        {activeTab === 'Themes' && Object.values(themes).map(theme => {
          const isOwned = unlockedThemes.includes(theme.id);
          const isEquipped = activeTheme === theme.id;

          return (
            <div key={theme.id} className={`p-4 rounded-3xl bg-theme-card border-2 transition-all ${isEquipped ? 'border-theme-accent shadow-theme-active' : 'border-black/5 shadow-sm'} flex flex-col gap-4 relative overflow-hidden`}>
              
              {/* Card Background Preview */}
              <div className={`absolute -right-10 -top-10 w-40 h-40 rounded-full opacity-10 blur-xl ${theme.gradient}`} />
              
              <div className="flex items-center gap-4 relative z-10">
                <div className={`w-16 h-16 rounded-2xl flex items-center justify-center text-3xl shadow-inner ${theme.gradient}`}>
                  {theme.icon}
                </div>
                <div className="flex-1">
                  <h3 className="font-bold text-lg text-theme-primary">{theme.name}</h3>
                  <p className="text-sm font-semibold text-theme-secondary">
                    {isOwned ? 'Purchased' : `${theme.price} Coins`}
                  </p>
                </div>
              </div>

              {/* Mini Preview Box */}
              <div className={`w-full h-16 rounded-xl flex items-center justify-center gap-2 ${theme.gradient} border border-black/10 shadow-inner relative overflow-hidden`}>
                 <span className="text-xs font-bold text-white uppercase opacity-70 z-10 mix-blend-overlay">Preview Scene</span>
              </div>

              <button
                onClick={() => handleAction(theme.id, theme.price)}
                className={`w-full py-3 rounded-xl font-bold text-sm flex items-center justify-center gap-2 transition-transform ${
                  isEquipped 
                    ? 'bg-black/5 text-theme-primary opacity-50 cursor-default' 
                    : isOwned 
                      ? 'bg-black/10 text-theme-primary hover:bg-black/20' 
                      : 'bg-theme-accent text-white shadow-theme-glow hover:scale-[1.02]'
                }`}
                disabled={isEquipped}
              >
                {isEquipped ? 'EQUIPPED' : isOwned ? 'EQUIP' : (
                  <>BUY NOW <span className="font-black text-xs opacity-70">(-{theme.price})</span></>
                )}
              </button>
            </div>
          );
        })}

        {activeTab === 'Bottles' && (
          <div className="text-center py-10 text-theme-secondary font-semibold opacity-70 flex flex-col items-center gap-3">
            <Lock size={40} className="mb-2 opacity-50" />
            <p>Bottles unlock periodically.</p>
            <p className="text-sm">Classic Glass: OWNED</p>
            <p className="text-sm">Aura Flask: 50 | Star Gem: 100</p>
            <p className="text-xs text-theme-accent mt-4 bg-theme-accent/10 px-4 py-2 rounded-full">(Visual only - logic tied to themes for this demo)</p>
          </div>
        )}
        
        {activeTab === 'Liquids' && (
          <div className="text-center py-10 text-theme-secondary font-semibold opacity-70 flex flex-col items-center gap-3">
             <Lock size={40} className="mb-2 opacity-50" />
             <p>Coming in next update!</p>
          </div>
        )}
      </div>
    </motion.div>
  );
};

export default Shop;
