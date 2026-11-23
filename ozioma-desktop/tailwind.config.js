/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          900: '#0F172A',
          800: '#1E293B',
          700: '#334155',
          600: '#475569',
        },
        theocratic: {
          blue: '#1E40AF',
          gold: '#CA8A04',
          emerald: '#059669',
          crimson: '#DC2626',
        }
      }
    },
  },
  plugins: [],
}
