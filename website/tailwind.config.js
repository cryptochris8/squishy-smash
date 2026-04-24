/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        // Squishy Smash brand palette — pulled from the Flutter app's
        // Palette constants + the collection-screen rarity tints.
        pink: {
          50: '#FFF2F7',
          100: '#FFE1EC',
          200: '#FFC7DC',
          300: '#FF8FB8',  // warm pink (primary)
          400: '#FF6FA5',
          500: '#FF4D90',
        },
        cream: {
          100: '#FFF7DF',
          200: '#FFE9B0',
          300: '#FFD36E',  // cream (secondary)
          400: '#FFBE3B',
        },
        jelly: {
          100: '#E7FAFF',
          200: '#BCEFFF',
          300: '#7FE7FF',  // jelly blue (accent)
          400: '#39D5FF',
        },
        lime: {
          300: '#B6FF5C',  // toxic lime
          400: '#94E83F',
        },
        lavender: {
          200: '#E4D2FF',
          300: '#C98BFF',  // lavender (epic rarity)
          400: '#A763F0',
          500: '#8040D8',
        },
        rarity: {
          common: '#B0B6C3',
          rare: '#7FE7FF',
          epic: '#C98BFF',
          legendary: '#FFD36E',
        },
        bg: {
          deep: '#1E0E2A',   // deeper purple for dark sections
          surface: '#2A1838',
        },
      },
      fontFamily: {
        display: ['Fredoka', 'system-ui', 'sans-serif'],
        body: ['Nunito', 'system-ui', 'sans-serif'],
      },
      animation: {
        float: 'float 3s ease-in-out infinite',
        'float-delayed': 'float 3s ease-in-out 1s infinite',
        'float-slow': 'float 4s ease-in-out 0.5s infinite',
        'float-slower': 'float 6s ease-in-out 2s infinite',
        'bubble-rise': 'bubbleRise 8s ease-in infinite',
        'bubble-rise-slow': 'bubbleRise 12s ease-in 2s infinite',
        'bubble-rise-fast': 'bubbleRise 6s ease-in 1s infinite',
        shimmer: 'shimmer 3s ease-in-out infinite',
        'pulse-glow': 'pulseGlow 2s ease-in-out infinite',
        'gradient-shift': 'gradientShift 12s ease infinite',
        wiggle: 'wiggle 2s ease-in-out infinite',
        pop: 'pop 0.4s ease-out',
        'fade-in-up': 'fadeInUp 0.6s ease-out forwards',
        'fade-in-up-delayed': 'fadeInUp 0.6s ease-out 0.2s forwards',
        'squish-press': 'squishPress 0.3s ease-out',
        'spin-slow': 'spin 8s linear infinite',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-15px)' },
        },
        bubbleRise: {
          '0%': { transform: 'translateY(100vh) scale(0.5)', opacity: '0' },
          '10%': { opacity: '0.6' },
          '90%': { opacity: '0.3' },
          '100%': { transform: 'translateY(-20vh) scale(1.2)', opacity: '0' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-200% center' },
          '100%': { backgroundPosition: '200% center' },
        },
        pulseGlow: {
          '0%, 100%': { boxShadow: '0 0 20px rgba(255, 143, 184, 0.35)' },
          '50%': { boxShadow: '0 0 48px rgba(255, 143, 184, 0.75)' },
        },
        gradientShift: {
          '0%': { backgroundPosition: '0% 50%' },
          '50%': { backgroundPosition: '100% 50%' },
          '100%': { backgroundPosition: '0% 50%' },
        },
        wiggle: {
          '0%, 100%': { transform: 'rotate(-3deg)' },
          '50%': { transform: 'rotate(3deg)' },
        },
        pop: {
          '0%': { transform: 'scale(0.8)', opacity: '0' },
          '80%': { transform: 'scale(1.05)' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
        fadeInUp: {
          '0%': { opacity: '0', transform: 'translateY(24px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        squishPress: {
          '0%': { transform: 'scale(1, 1)' },
          '40%': { transform: 'scale(1.18, 0.82)' },
          '70%': { transform: 'scale(0.94, 1.06)' },
          '100%': { transform: 'scale(1, 1)' },
        },
      },
      backgroundImage: {
        'squishy-gradient':
          'linear-gradient(135deg, #FF8FB8 0%, #C98BFF 35%, #8040D8 65%, #7FE7FF 100%)',
        'rainbow-text':
          'linear-gradient(90deg, #FFD36E, #FF8FB8, #C98BFF, #7FE7FF, #B6FF5C, #FFD36E)',
      },
    },
  },
  plugins: [],
}
