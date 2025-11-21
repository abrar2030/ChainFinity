// Mock IntersectionObserver
global.IntersectionObserver = class IntersectionObserver {
  constructor(callback, options) {
    // console.log('IntersectionObserver constructor called'); // Debug
  }
  observe(target) {
    /* console.log('IntersectionObserver observe'); */ return null;
  }
  unobserve(target) {
    /* console.log('IntersectionObserver unobserve'); */ return null;
  }
  disconnect() {
    /* console.log('IntersectionObserver disconnect'); */ return null;
  }
};

// Forceful and simple matchMedia mock
window.matchMedia = jest.fn().mockImplementation((query) => {
  console.log("[MOCK] window.matchMedia called with query:", query); // Crucial log
  return {
    matches: false, // Consistently return a boolean. Default to false (mobile-first approach often assumes wider screens match 'true').
    media: query,
    onchange: null,
    addListener: jest.fn(), // deprecated
    removeListener: jest.fn(), // deprecated
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  };
});
