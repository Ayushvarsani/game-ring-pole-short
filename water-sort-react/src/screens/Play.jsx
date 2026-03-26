import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { Home, Undo2, RotateCcw, Lightbulb, Star } from 'lucide-react';
import { useTheme } from '../context/ThemeContext';
import { CoinCounter } from '../components/CoinCounter';
import Bottle from '../components/Bottle';

const INITIAL_LEVEL = [
  ['#0d9488', '#9333ea', '#eab308', '#0d9488'], // Top is index 0 or last depending on how we render. Let's say index 0 is bottom.
  ['#9333ea', '#eab308', '#9333ea', '#eab308'],
  []
];

// Let's use this setup: Last element in array is the TOP of the bottle.
const LEVEL_2 = [
  ['#9333ea', '#9333ea', '#0d9488', '#0d9488'], // Bottom to Top
  ['#eab308', '#eab308', '#9333ea', '#eab308'],
  ['#0d9488', '#0d9488', '#eab308', '#9333ea'],
  [] // Empty
];

const Play = () => {
  const navigate = useNavigate();
  const { addCoins, activeTheme } = useTheme();
  
  // State
  const [bottles, setBottles] = useState([
    ['#9333ea', '#9333ea', '#0d9488', '#0d9488'], // Purple (bottom), Teal (top)
    ['#eab308', '#eab308', '#9333ea', '#9333ea'], // Yellow (bottom), Purple (top)
    [] // Empty
  ]);
  const [selectedBottle, setSelectedBottle] = useState(null);
  const [moves, setMoves] = useState(0);
  const [history, setHistory] = useState([]);
  const [hints, setHints] = useState(5);
  const [isWon, setIsWon] = useState(false);

  // Check Win Condition
  useEffect(() => {
    const checkWin = () => {
      for (let b of bottles) {
        if (b.length > 0) {
          if (b.length !== 4) return false;
          const firstColor = b[0];
          if (!b.every(c => c === firstColor)) return false;
        }
      }
      return true;
    };

    if (checkWin() && !isWon && moves > 0) {
      setIsWon(true);
      addCoins(50); // Reward
    }
  }, [bottles, isWon, moves]);

  const handleBottleClick = (idx) => {
    if (isWon) return;

    if (selectedBottle === null) {
      // Select if not empty
      if (bottles[idx].length > 0) {
        setSelectedBottle(idx);
      }
    } else {
      if (selectedBottle === idx) {
        // Deselect
        setSelectedBottle(null);
      } else {
        // Try to pour from selectedBottle to idx
        pour(selectedBottle, idx);
      }
    }
  };

  const pour = (fromIdx, toIdx) => {
    const fromBottle = [...bottles[fromIdx]];
    const toBottle = [...bottles[toIdx]];

    if (fromBottle.length === 0) {
      setSelectedBottle(null);
      return;
    }

    if (toBottle.length === 4) {
      setSelectedBottle(null);
      return; // dest full
    }

    const colorToMove = fromBottle[fromBottle.length - 1];

    if (toBottle.length > 0 && toBottle[toBottle.length - 1] !== colorToMove) {
      setSelectedBottle(null);
      return; // colors don't match
    }

    // Determine how many blocks of the same color we can move
    let blocksToMove = 0;
    for (let i = fromBottle.length - 1; i >= 0; i--) {
      if (fromBottle[i] === colorToMove) blocksToMove++;
      else break;
    }

    const availableSpace = 4 - toBottle.length;
    const actualMoves = Math.min(blocksToMove, availableSpace);

    if (actualMoves > 0) {
      // Save history
      setHistory([...history, bottles.map(b => [...b])]);
      
      const newFrom = [...fromBottle];
      const newTo = [...toBottle];

      for (let i = 0; i < actualMoves; i++) {
        newTo.push(newFrom.pop());
      }

      const newBottles = [...bottles];
      newBottles[fromIdx] = newFrom;
      newBottles[toIdx] = newTo;

      setBottles(newBottles);
      setMoves(moves + 1);
    }
    
    setSelectedBottle(null);
  };

  const handleUndo = () => {
    if (history.length > 0 && !isWon) {
      const prev = history[history.length - 1];
      setBottles(prev);
      setHistory(history.slice(0, -1));
      // Moves count doesn't decrement intentionally, or you can if preferred
    }
  };

  const handleRestart = () => {
    setBottles([
      ['#9333ea', '#9333ea', '#0d9488', '#0d9488'], // Purple (bottom), Teal (top)
      ['#eab308', '#eab308', '#9333ea', '#9333ea'], // Yellow (bottom), Purple (top)
      [] // Empty
    ]);
    setSelectedBottle(null);
    setMoves(0);
    setHistory([]);
    setIsWon(false);
  };

  const pageVariants = {
    initial: { scale: 0.9, opacity: 0 },
    in: { scale: 1, opacity: 1 },
    out: { scale: 1.1, opacity: 0 }
  };

  return (
    <motion.div initial="initial" animate="in" exit="out" variants={pageVariants} className="flex flex-col h-screen bg-theme-main p-6 relative">
      
      {/* Header Info */}
      <div className="flex justify-between items-center mb-6 z-10 relative">
        <button onClick={() => navigate('/')} className="p-3 bg-theme-card rounded-2xl shadow-sm text-theme-primary">
          <Home size={24} />
        </button>
        <div className="text-center font-bold">
          <div className="text-xl text-theme-primary drop-shadow-sm">LEVEL 2</div>
          <div className="text-xs text-theme-secondary opacity-80 uppercase tracking-widest">Moves: {moves}</div>
        </div>
        <CoinCounter />
      </div>

      {/* Game Board */}
      <div className="flex-1 flex flex-col items-center justify-center relative z-10 w-full">
        {/* Subtle Background Circle Ring */}
        <div className={`absolute w-[120%] aspect-square rounded-full border border-theme-primary/10 shadow-inner z-0 pointer-events-none opacity-20`} />
        
        <div className="flex flex-wrap justify-center gap-4 sm:gap-6 z-10 relative px-4 w-full">
          {bottles.map((b, i) => (
            <Bottle
              key={i}
              id={i}
              colors={b}
              isSelected={selectedBottle === i}
              onClick={handleBottleClick}
              maxCapacity={4}
            />
          ))}
        </div>
      </div>

      {/* Bottom Controls */}
      <div className="flex justify-center gap-6 mb-8 mt-auto z-10">
        <button onClick={handleUndo} disabled={history.length === 0 || isWon} className="p-4 bg-theme-card rounded-2xl shadow-sm text-theme-primary disabled:opacity-50 hover:bg-theme-accent hover:text-white transition-colors active:scale-95">
          <Undo2 size={28} />
        </button>
        <button onClick={handleRestart} className="p-4 bg-theme-card rounded-2xl shadow-sm text-theme-primary hover:bg-theme-accent hover:text-white transition-colors active:scale-95">
          <RotateCcw size={28} />
        </button>
        <button onClick={() => hints > 0 && !isWon && setHints(h => h - 1)} disabled={hints === 0 || isWon} className="p-4 bg-theme-card rounded-2xl shadow-sm text-theme-primary disabled:opacity-50 flex flex-col items-center gap-1 hover:bg-theme-accent hover:text-white transition-colors active:scale-95 relative overflow-hidden group">
          <Lightbulb size={28} />
          <span className="absolute bottom-1 right-1 text-[10px] font-black opacity-80 bg-theme-primary text-theme-main rounded-full w-4 h-4 flex items-center justify-center">{hints}</span>
        </button>
      </div>

      {/* Win Modal Overlay */}
      <AnimatePresence>
        {isWon && (
          <motion.div 
            initial={{ opacity: 0 }} 
            animate={{ opacity: 1 }} 
            exit={{ opacity: 0 }} 
            className="absolute inset-0 z-50 bg-black/60 backdrop-blur-md flex flex-col items-center justify-center p-8"
          >
            <motion.div 
              initial={{ scale: 0.5, y: 50, rotate: -5 }} animate={{ scale: 1, y: 0, rotate: 0 }} 
              className="bg-theme-card p-8 rounded-[2.5rem] shadow-2xl border-4 border-theme-accent text-center w-full max-w-sm"
            >
              <h2 className="text-4xl font-extrabold text-theme-primary mb-2 drop-shadow-md">LEVEL CLEARED!</h2>
              <div className="flex justify-center gap-2 mb-6 drop-shadow-lg text-yellow-400">
                <Star size={40} className="fill-current animate-bounce" style={{ animationDelay: '0s' }} />
                <Star size={48} className="fill-current animate-bounce" style={{ animationDelay: '0.1s' }} />
                <Star size={40} className="fill-current animate-bounce" style={{ animationDelay: '0.2s', opacity: moves > 15 ? 0.3 : 1 }} />
              </div>
              <p className="text-theme-secondary font-bold text-lg mb-6">You earned <span className="text-theme-accent font-black">+50 Coins</span></p>
              
              <div className="flex gap-4">
                <button onClick={() => navigate('/')} className="flex-1 py-4 bg-gray-200 text-gray-800 font-bold rounded-2xl shadow-inner active:scale-95 transition-transform">HOME</button>
                <button onClick={handleRestart} className="flex-1 py-4 bg-theme-accent text-white font-bold rounded-2xl shadow-theme-glow active:scale-95 transition-transform">NEXT</button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

    </motion.div>
  );
};

export default Play;
