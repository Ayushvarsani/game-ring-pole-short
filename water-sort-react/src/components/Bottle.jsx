import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useTheme } from '../context/ThemeContext';

const Bottle = ({ id, colors, isSelected, onClick, maxCapacity = 4 }) => {
  const { activeTheme } = useTheme();

  // Draw empty slots if partially full
  const emptySlots = maxCapacity - colors.length;
  
  // Base on activeTheme, bottle look changes based on CSS vars, but we can also apply specific styles
  const isJungle = activeTheme === 'jungle';
  const isSpace = activeTheme === 'space';

  return (
    <motion.div
      onClick={() => onClick(id)}
      animate={{ y: isSelected ? -15 : 0 }}
      className={`relative w-[var(--bottle-width)] h-[var(--bottle-height)] flex flex-col justify-end overflow-hidden cursor-pointer transition-all duration-300 ${isSelected ? 'shadow-theme-active border-theme-accent' : ''}`}
      style={{
        backgroundColor: 'var(--bottle-bg)',
        border: '3px solid var(--bottle-border)',
        borderRadius: 'var(--bottle-radius)',
        borderTopLeftRadius: 'var(--bottle-top-radius)',
        borderTopRightRadius: 'var(--bottle-top-radius)',
        borderTopWidth: isJungle ? '3px' : isSpace ? '6px' : '3px',
      }}
    >
      {/* Decorative cap for space/jungle */}
      {isSpace && (
        <div className="absolute top-0 left-0 right-0 h-3 bg-[var(--bottle-border)] opacity-80 z-20" />
      )}
      {isJungle && (
        <>
           <div className="absolute top-[30%] w-full h-1 bg-[var(--bottle-border)] opacity-50 z-20" />
           <div className="absolute top-[60%] w-full h-1 bg-[var(--bottle-border)] opacity-50 z-20" />
        </>
      )}

      {/* Shine effect */}
      <div className="absolute top-0 left-2 w-2 h-full bg-white opacity-20 rounded-full mix-blend-overlay z-10 pointer-events-none" />

      {/* Liquids */}
      <div className="flex flex-col-reverse w-full h-full justify-start rounded-b-[calc(var(--bottle-radius)-3px)] overflow-hidden relative z-0">
        <AnimatePresence>
          {colors.map((color, index) => (
            <motion.div
              key={`${id}-${index}-${color}`}
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: `${100 / maxCapacity}%`, opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              transition={{ duration: 0.3, type: 'spring', stiffness: 200, damping: 20 }}
              className="w-full relative shadow-inner"
              style={{ backgroundColor: color }}
            >
              {/* Liquid surface highlight */}
              <div className="absolute top-0 w-full h-1 bg-white opacity-30" />
              <div className="absolute bottom-0 w-full h-1 bg-black opacity-10" />
              {/* Particle glow for space theme */}
              {isSpace && (
                <div className="absolute inset-0 opacity-50 mix-blend-screen bg-theme-pattern" />
              )}
            </motion.div>
          ))}
        </AnimatePresence>
      </div>
    </motion.div>
  );
};

export default Bottle;
