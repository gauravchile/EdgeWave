// src/App.jsx
function App() {
  const color = import.meta.env.VITE_DEPLOY_COLOR || 'unknown';

  return (
    <div style={{ textAlign: 'center', paddingTop: '50px' }}>
      <h2>{color === 'blue' ? '🔵 BLUE DEPLOYMENT ACTIVE' : '🟢 GREEN DEPLOYMENT ACTIVE'}</h2>
      <p>Welcome to EdgeWave Frontend</p>
      <p>Version: {color}</p>
    </div>
  );
}

export default App;
// test trigger Sun Nov 30 22:00:24 IST 2025
// poll test Sun Nov 30 22:05:23 IST 2025
// test commit
