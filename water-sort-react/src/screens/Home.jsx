import React from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Settings, ShoppingBasket, Droplet } from 'lucide-react';
import { useTheme } from '../context/ThemeContext';
import { CoinCounter } from '../components/CoinCounter';
import Bottle from '../components/Bottle';

const Home = () => {
  const navigate = useNavigate();
  const { activeTheme } = useTheme();

  // Basic page transition variants
  const pageVariants = {
    initial: { opacity: 0, scale: 0.95 },
    in: { opacity: 1, scale: 1 },
    out: { opacity: 0, scale: 1.05 }
  };

  // The 3 bottles for the animated preview
  const demoBottles = [
    { id: 1, colors: ['#0d9488', '#9333ea', '#eab308'] },
    { id: 2, colors: ['#eab308', '#0d9488'] },
    { id: 3, colors: ['#9333ea', '#9333ea'] }
  ];

  return (
    <motion.div
      initial="initial" animate="in" exit="out" variants={pageVariants}
      className="flex flex-col h-screen p-6 z-10 relative"
    >
      {/* Top Bar */}
      <div className="flex justify-between items-center mb-8">
        <button
          onClick={() => navigate('/settings')}
          className="p-3 bg-theme-card rounded-2xl shadow-theme-glow text-theme-secondary hover:text-theme-accent transition-colors"
        >
          <Settings size={24} />
        </button>

        <CoinCounter />

        <button
          onClick={() => navigate('/shop')}
          className="p-3 bg-theme-card rounded-2xl shadow-theme-glow text-theme-secondary hover:text-theme-accent transition-colors"
        >
          <ShoppingBasket size={24} />
        </button>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col items-center justify-center space-y-8">
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="text-center"
        >
          <div className="text-theme-accent font-black tracking-widest text-sm mb-2 uppercase opacity-80">
            Level 2
          </div>
          <h1 className="text-4xl sm:text-5xl font-extrabold text-theme-primary drop-shadow-sm mb-4">
            Water Sort
          </h1>
        </motion.div>

        {/* Animated Preview Frame */}
        <motion.div
          animate={{ rotate: 360 }}
          transition={{ duration: 60, repeat: Infinity, ease: "linear" }}
          className="relative w-64 h-64 rounded-full border border-theme-accent/20 flex items-center justify-center p-8 bg-black/5 backdrop-blur-sm shadow-theme-glow"
        >
          {/* Inner static container to prevent bottles from rotating weirdly */}
          <div className="absolute inset-0 flex items-center justify-center gap-4" style={{ transform: 'rotate(0deg)' }}>
            {demoBottles.map((bottle, idx) => (
              <motion.div 
                key={bottle.id}
                animate={{ y: [0, -10, 0] }}
                transition={{ duration: 3, delay: idx * 0.4, repeat: Infinity, ease: 'easeInOut' }}
                className="scale-75"
              >
                <Bottle id={bottle.id} colors={bottle.colors} isSelected={false} onClick={() => {}} maxCapacity={4} />
              </motion.div>
            ))}
          </div>
        </motion.div>

        <Droplet className="text-theme-accent" size={32} />

      </div>

      {/* Play Button */}
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={() => navigate('/play')}
        className={`w-full py-5 rounded-[2rem] bg-theme-accent text-lg font-bold shadow-theme-active flex items-center justify-center gap-3 relative overflow-hidden group`}
      >
        <span className="relative z-10 flex items-center gap-2">
          <Droplet size={20} className="fill-current" /> PLAY
        </span>
        <div className="absolute inset-0 bg-white/20 transform -translate-x-full group-hover:translate-x-full transition-transform duration-500 ease-out" />
      </motion.button>
    </motion.div>
  );
};

export default Home;
