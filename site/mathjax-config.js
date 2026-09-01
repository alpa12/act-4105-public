window.MathJax = {
  options: {
    // The expression explorer is unnecessary for the course slides. Keep the
    // contextual menu, but do not activate keyboard/VoiceOver exploration.
    enableExplorer: false,
    menuOptions: {
      settings: {
        enrich: false,
        collapsible: false,
        speech: false,
        braille: false
      }
    }
  },
  tex: {
    inlineMath: [['\\(', '\\)']],
    displayMath: [['\\[', '\\]']],
    processEscapes: true,
    processRefs: true,
    processEnvironments: true
  },
  chtml: {
    font: 'mathjax-newcm',
    fontURL: '/assets/vendor/mathjax/chtml/woff2',
    dynamicPrefix: '/assets/vendor/mathjax/chtml/dynamic'
  },
  startup: {
    ready: () => {
      console.log('MathJax is loaded and ready with font: mathjax-newcm (New Computer Modern)');
      MathJax.startup.defaultReady();
    }
  }
};
