/**
 * SMART CRICKET SCORER - LANDING PAGE INTERACTIVE SCRIPT
 * Version: 1.2.0
 */

document.addEventListener('DOMContentLoaded', () => {
  // 1. Download Toast Notification
  const downloadBtns = document.querySelectorAll('.btn-download-apk');
  const toast = document.getElementById('downloadToast');

  downloadBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      showDownloadToast();
    });
  });

  function showDownloadToast() {
    if (!toast) return;
    toast.classList.add('show');
    setTimeout(() => {
      toast.classList.remove('show');
    }, 4500);
  }

  // 2. Interactive Mockup Tab Switcher (Live Score, History, Team Reuse)
  const mockupTabBtns = document.querySelectorAll('.preview-tab-btn');
  const mockupViews = {
    scorecard: document.getElementById('mockup-scorecard'),
    history: document.getElementById('mockup-history'),
    reuse: document.getElementById('mockup-reuse')
  };

  mockupTabBtns.forEach(tab => {
    tab.addEventListener('click', () => {
      const targetView = tab.getAttribute('data-mockup');
      
      // Update active button
      mockupTabBtns.forEach(btn => btn.classList.remove('active'));
      tab.classList.add('active');

      // Toggle views
      Object.keys(mockupViews).forEach(key => {
        if (mockupViews[key]) {
          mockupViews[key].style.display = (key === targetView) ? 'block' : 'none';
        }
      });
    });
  });

  // 3. Interactive 3D Coin Flip Section
  const flipBtn = document.getElementById('flipCoinBtn');
  const coin = document.getElementById('interactiveCoin');
  const tossResultText = document.getElementById('tossResultText');

  if (flipBtn && coin && tossResultText) {
    let isFlipping = false;

    flipBtn.addEventListener('click', () => {
      if (isFlipping) return;
      isFlipping = true;

      tossResultText.textContent = "Flipping coin in the air...";
      tossResultText.style.color = "#FFD700";

      // Random outcome
      const isHeads = Math.random() < 0.5;
      const rotationDegrees = isHeads ? 1800 : 1980; // 5 turns vs 5.5 turns

      coin.style.transform = `rotateY(${rotationDegrees}deg)`;

      setTimeout(() => {
        const teams = ["India", "Australia", "England", "South Africa"];
        const winnerTeam = teams[Math.floor(Math.random() * teams.length)];
        const decision = Math.random() < 0.5 ? "BAT FIRST" : "BOWL FIRST";
        const side = isHeads ? "HEADS" : "TAILS";

        tossResultText.innerHTML = `🪙 Coin Result: <strong>${side}</strong>! <br> 🏆 <strong>${winnerTeam}</strong> won the toss and elected to <strong>${decision}</strong>.`;
        tossResultText.style.color = "#00E676";
        isFlipping = false;
      }, 1500);
    });
  }

  // 4. Mobile Navigation Toggle
  const navToggle = document.getElementById('mobileNavToggle');
  const navLinks = document.querySelector('.nav-links');

  if (navToggle && navLinks) {
    navToggle.addEventListener('click', () => {
      if (navLinks.style.display === 'flex') {
        navLinks.style.display = 'none';
      } else {
        navLinks.style.display = 'flex';
        navLinks.style.flexDirection = 'column';
        navLinks.style.position = 'absolute';
        navLinks.style.top = '70px';
        navLinks.style.left = '0';
        navLinks.style.width = '100%';
        navLinks.style.background = '#0A1612';
        navLinks.style.padding = '20px';
        navLinks.style.borderBottom = '1px solid #24473C';
      }
    });
  }

  // 5. Smooth scrolling for internal navigation
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      e.preventDefault();
      const targetId = this.getAttribute('href');
      if (targetId === '#') return;
      const target = document.querySelector(targetId);
      if (target) {
        target.scrollIntoView({ behavior: 'smooth' });
        if (window.innerWidth <= 768 && navLinks) {
          navLinks.style.display = 'none';
        }
      }
    });
  });
});
