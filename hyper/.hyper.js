module.exports = {
  config: {
    updateChannel: 'stable',

    fontSize: 20,

    fontFamily: '"UbuntuMono Nerd Font"',

    fontWeight: 'bold',

    fontWeightBold: 'bold',

    lineHeight: 1.3,

    letterSpacing: 0,

    // terminal cursor background color and opacity (hex, rgb, hsl, hsv, hwb or cmyk)
    cursorColor: 'rgba(248,28,229,0.8)',

    // terminal text color under BLOCK cursor
    cursorAccentColor: '#000',

    cursorShape: 'UNDERLINE',

    cursorBlink: true,

    foregroundColor: '#fff',

    backgroundColor: '#000000',

    selectionColor: 'rgba(248,28,229,0.3)',

    borderColor: '#333',

    css: '',

    termCSS: '',

    showHamburgerMenu: '',

    showWindowControls: '',

    padding: '12px 14px',

    MaterialTheme: {
      theme: 'Palenight',

      // [Optional] Set the rgba() app background opacity, useful when enableVibrance is true
      // OPTIONS: From 0.1 to 1
      backgroundOpacity: '0.1',

      // [Optional] Set the accent color for the current active tab
      accentColor: '#64FFDA',

      // [Optional] Mac Only. Need restart. Enable the vibrance and blurred background
      // OPTIONS: 'dark', 'ultra-dark', 'bright'
      // NOTE: The backgroundOpacity should be between 0.1 and 0.9 to see the effect.
      vibrancy: 'dark',
    },

    colors: {
      black: '#222222',
      red: '#fc5758',
      green: '#b3e347',
      yellow: '#fff727',
      blue: '#20b0fc',
      magenta: '#8d36fe',
      cyan: '#49e0fb',
      white: '#C7C7C7',
      lightBlack: '#686868',
      lightRed: '#fc5758',
      lightGreen: '#b3e347',
      lightYellow: '#fff727',
      lightBlue: '#20b0fc',
      lightMagenta: '#8d36fe',
      lightCyan: '#49e0fb',
      lightWhite: '#FFFFFF',
    },

    shell: '',

    shellArgs: ['--login'],

    env: {},

    bell: 'false',

    copyOnSelect: true,

    defaultSSHApp: true,

    webGLRenderer: true,
  },

  plugins: [
    'hyper-material-theme',
    'hyper-pane',
    'hypercwd',
    'hyper-spotify',
    'hyper-tabs-enhanced',
    'hyper-dark-scrollbar',
    'hyper-statusline',
    // 'hyper-transparent-dynamic',
  ],

  keymaps: {},
}
