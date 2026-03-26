import React from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';
import { AnimatePresence } from 'framer-motion';
import { ThemeProvider } from './context/ThemeContext';

// Screens
import Home from './screens/Home';
import Settings from './screens/Settings';
import Shop from './screens/Shop';
import Play from './screens/Play';

function AnimatedRoutes() {
  const location = useLocation();
  return (
    <AnimatePresence mode="wait">
      <Routes location={location} key={location.pathname}>
        <Route path="/" element={<Home />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/shop" element={<Shop />} />
        <Route path="/play" element={<Play />} />
      </Routes>
    </AnimatePresence>
  );
}

function App() {
  return (
    <ThemeProvider>
      <div className="relative w-full h-full min-h-screen bg-theme-main theme-font text-theme-primary flex justify-center selection:bg-theme-accent/30 overflow-hidden">
        {/* Background Decorative Pattern */}
        <div className="bg-theme-pattern" />

        {/* Mobile Container wrapper (target 375px width max) */}
        <div className="relative w-full max-w-[400px] shadow-2xl bg-black/5" style={{ backdropFilter: 'blur(20px)' }}>
          <Router>
            <AnimatedRoutes />
          </Router>
        </div>
      </div>
    </ThemeProvider>
  );
}

export default App;
