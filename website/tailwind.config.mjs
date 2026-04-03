/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}',
    './node_modules/flowbite/**/*.js',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        terminal: {
          bg: '#1e1e2e',
          border: '#313244',
          text: '#cdd6f4',
        },
      },
      fontFamily: {
        mono: ['SF Mono', 'Fira Code', 'monospace'],
      },
    },
  },
  plugins: [
    require('flowbite/plugin'),
  ],
};
