import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import "ol/ol.css";
import App from './App.tsx'
import "./styles/global.css";

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
