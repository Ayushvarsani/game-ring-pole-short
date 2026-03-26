import React from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { ArrowLeft, Music, Volume2, Vibrate } from 'lucide-react';
import { useTheme } from '../context/ThemeContext';

const Settings = () => {
  const navigate = useNavigate();
  const { settings, toggleSetting } = useTheme();

  const pageVariants = {
    initial: { x: -50, opacity: 0 },
    in: { x: 0, opacity: 1 },
    out: { x: 50, opacity: 0 }
  };

  const SettingRow = ({ icon: Icon, label, settingKey, isActive }) => (
    <div className="flex items-center justify-between p-4 bg-theme-card rounded-2xl mb-4 shadow-sm border border-white/10 backdrop-blur-md">
      <div className="flex items-center gap-4">
        <div className={`p-2 rounded-xl ${isActive ? 'bg-theme-accent/20 text-theme-accent' : 'bg-gray-100 dark:bg-gray-800 text-gray-500'}`}>
          <Icon size={24} />
        </div>
        <span className="font-semibold text-theme-primary text-lg">{label}</span>
      </div>
      <label className="flex items-center cursor-pointer">
        <div className="relative">
          <input
            type="checkbox"
            className="sr-only"
            checked={isActive}
            onChange={() => toggleSetting(settingKey)}
          />
          <div className="block toggle-switch" checked={isActive}></div>
        </div>
      </label>
    </div>
  );

  return (
    <motion.div
      initial="initial" animate="in" exit="out" variants={pageVariants}
      className="flex flex-col h-screen bg-theme-main z-10 p-6 relative"
    >
      {/* Header */}
      <div className="flex items-center gap-6 mb-8 mt-2">
        <button onClick={() => navigate(-1)} className="p-3 bg-theme-card rounded-2xl shadow-sm text-theme-primary">
          <ArrowLeft size={24} />
        </button>
        <h1 className="text-3xl font-extrabold text-theme-primary">Settings</h1>
      </div>

      <div className="flex-1 space-y-2 mt-4">
        <SettingRow icon={Music} label="Music" settingKey="music" isActive={settings.music} />
        <SettingRow icon={Volume2} label="Sound Effects" settingKey="sound" isActive={settings.sound} />
        <SettingRow icon={Vibrate} label="Vibration" settingKey="vibration" isActive={settings.vibration} />
      </div>

      <div className="text-center text-sm text-theme-secondary opacity-60 pb-8">
        Water Sort v1.0.0
      </div>
    </motion.div>
  );
};

export default Settings;
