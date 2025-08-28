import React from 'react';
import ReactDOM from 'react-dom/client';
import './app.css';
import GigiTimeUIMock from './GigiTimeUI';

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

root.render(
  <React.StrictMode>
    <GigiTimeUIMock />
  </React.StrictMode>
);
