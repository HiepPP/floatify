/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}',
  ],
  theme: {
    extend: {
      colors: {
        game: {
          'sky-dark': '#1a1a2e',
          'sky-mid': '#16213e',
          'mario-red': '#E52521',
          'coin-gold': '#F5C518',
          'pipe-green': '#049C2F',
          'sky-blue': '#6185F8',
          'cloud-white': '#F0F0F0',
          'brick-brown': '#C84C09',
          'ground-brown': '#8B5E34',
          'block-tan': '#D4A55A',
          'console-dark': '#0f0f1a',
        },
      },
      fontFamily: {
        pixel: ['"Press Start 2P"', 'monospace'],
        body: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['SF Mono', 'Fira Code', 'monospace'],
      },
    },
  },
  plugins: [],
};
