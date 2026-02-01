import { useState } from 'react';
import Navbar from './components/Navbar';
import SecondaryNav from './components/SecondaryNav';
// Sections import will go here
import Dashboard from './components/sections/Dashboard';
import ProtocolGovernance from './components/sections/ProtocolGovernance';
import LiveMarket from './components/sections/LiveMarket';

function App() {
  const [activeSection, setActiveSection] = useState('dashboard');

  return (
    <>
      <div className="antigravity-border"></div>

      {/* Video Background */}
      <video autoPlay muted loop playsInline id="bg-video">
        <source src="/video2.mp4" type="video/mp4" />
      </video>

      <Navbar />
      <SecondaryNav activeSection={activeSection} setActiveSection={setActiveSection} />

      <div className="container">
        {activeSection === 'dashboard' && <Dashboard />}
        {activeSection === 'governance' && <ProtocolGovernance />}
        {activeSection === 'market' && <LiveMarket />}
      </div>
    </>
  );
}

export default App;
