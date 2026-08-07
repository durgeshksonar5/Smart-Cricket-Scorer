/**
 * CRICKET SCORE COUNTER - LANDING PAGE INTERACTIVE SCRIPT
 */

document.addEventListener('DOMContentLoaded', () => {
  // 1. Download Toast Notification
  const downloadBtns = document.querySelectorAll('.btn-download-apk');
  const toast = document.getElementById('downloadToast');

  downloadBtns.forEach(btn => {
    btn.addEventListener('click', (e) => {
      // Allow relative APK download to trigger naturally, but show toast
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

  // 2. Interactive Coin Flip Section
  const flipBtn = document.getElementById('flipCoinBtn');
  const coin = document.getElementById('interactiveCoin');
  const tossResultText = document.getElementById('tossResultText');

  if (flipBtn && coin && tossResultText) {
    let isFlipping = false;

    flipBtn.addEventListener('click', () => {
      if (isFlipping) return;
      isFlipping = true;

      tossResultText.textContent = "Flipping coin...";
      tossResultText.style.color = "#FFD700";

      // Random outcome
      const isHeads = Math.random() < 0.5;
      const rotationDegrees = isHeads ? 1800 : 1980; // 5 full turns vs 5.5 turns

      coin.style.transform = `rotateY(${rotationDegrees}deg)`;

      setTimeout(() => {
        const winnerTeam = Math.random() < 0.5 ? "India" : "Australia";
        const decision = Math.random() < 0.5 ? "BAT" : "BOWL";
        const side = isHeads ? "HEADS" : "TAILS";

        tossResultText.innerHTML = `🪙 Result: <strong>${side}</strong>! <br> ${winnerTeam} won the toss & elected to <strong>${decision}</strong>.`;
        tossResultText.style.color = "#00E676";
        isFlipping = false;
      }, 1500);
    });
  }

  // 3. Mobile Navigation Toggle
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

  // 4. Smooth scrolling for internal anchor links
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
