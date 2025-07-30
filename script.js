// Agents Showcase Functionality
class AgentsShowcase {
    constructor() {
        this.currentIndex = 0;
        this.agents = document.querySelectorAll('.agent-showcase');
        this.navButtons = document.querySelectorAll('.agent-nav-btn');
        this.playPauseBtn = document.getElementById('playPauseBtn');
        this.progressFill = document.querySelector('.progress-fill');
        this.isPlaying = true;
        this.autoPlayInterval = null;
        this.progressInterval = null;
        this.autoPlayDuration = 5000; // 5 seconds per agent
        
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.startAutoPlay();
        this.showAgent(0);
    }
    
    setupEventListeners() {
        // Navigation buttons
        this.navButtons.forEach((btn, index) => {
            btn.addEventListener('click', () => {
                this.showAgent(index);
                this.resetAutoPlay();
            });
        });
        
        // Play/Pause button
        this.playPauseBtn.addEventListener('click', () => {
            this.toggleAutoPlay();
        });
        
        // Keyboard navigation
        document.addEventListener('keydown', (e) => {
            if (e.key === 'ArrowLeft') {
                this.previousAgent();
            } else if (e.key === 'ArrowRight') {
                this.nextAgent();
            } else if (e.key === ' ') {
                e.preventDefault();
                this.toggleAutoPlay();
            }
        });
        
        // Touch/swipe support
        let startX = 0;
        let endX = 0;
        
        const carousel = document.querySelector('.agents-carousel');
        carousel.addEventListener('touchstart', (e) => {
            startX = e.touches[0].clientX;
        });
        
        carousel.addEventListener('touchend', (e) => {
            endX = e.changedTouches[0].clientX;
            const diff = startX - endX;
            
            if (Math.abs(diff) > 50) { // Minimum swipe distance
                if (diff > 0) {
                    this.nextAgent();
                } else {
                    this.previousAgent();
                }
                this.resetAutoPlay();
            }
        });
    }
    
    showAgent(index) {
        // Remove all classes
        this.agents.forEach(agent => {
            agent.classList.remove('active', 'prev', 'next');
        });
        
        this.navButtons.forEach(btn => {
            btn.classList.remove('active');
        });
        
        // Set current agent
        this.currentIndex = index;
        this.agents[index].classList.add('active');
        this.navButtons[index].classList.add('active');
        
        // Set prev/next classes for 3D effect
        const prevIndex = (index - 1 + this.agents.length) % this.agents.length;
        const nextIndex = (index + 1) % this.agents.length;
        
        this.agents[prevIndex].classList.add('prev');
        this.agents[nextIndex].classList.add('next');
        
        // Trigger particle animation
        this.animateParticles(this.agents[index]);
        
        // Reset progress
        this.resetProgress();
    }
    
    nextAgent() {
        const nextIndex = (this.currentIndex + 1) % this.agents.length;
        this.showAgent(nextIndex);
    }
    
    previousAgent() {
        const prevIndex = (this.currentIndex - 1 + this.agents.length) % this.agents.length;
        this.showAgent(prevIndex);
    }
    
    startAutoPlay() {
        if (this.autoPlayInterval) return;
        
        this.autoPlayInterval = setInterval(() => {
            this.nextAgent();
        }, this.autoPlayDuration);
        
        this.startProgress();
    }
    
    stopAutoPlay() {
        if (this.autoPlayInterval) {
            clearInterval(this.autoPlayInterval);
            this.autoPlayInterval = null;
        }
        
        this.stopProgress();
    }
    
    toggleAutoPlay() {
        this.isPlaying = !this.isPlaying;
        
        if (this.isPlaying) {
            this.startAutoPlay();
            this.playPauseBtn.innerHTML = '<i class="fas fa-pause"></i>';
        } else {
            this.stopAutoPlay();
            this.playPauseBtn.innerHTML = '<i class="fas fa-play"></i>';
        }
    }
    
    resetAutoPlay() {
        if (this.isPlaying) {
            this.stopAutoPlay();
            this.startAutoPlay();
        }
    }
    
    startProgress() {
        this.resetProgress();
        let progress = 0;
        
        this.progressInterval = setInterval(() => {
            progress += 100 / (this.autoPlayDuration / 100);
            this.progressFill.style.width = `${Math.min(progress, 100)}%`;
            
            if (progress >= 100) {
                this.resetProgress();
                progress = 0;
            }
        }, 100);
    }
    
    stopProgress() {
        if (this.progressInterval) {
            clearInterval(this.progressInterval);
            this.progressInterval = null;
        }
    }
    
    resetProgress() {
        this.progressFill.style.width = '0%';
    }
    
    animateParticles(agentElement) {
        const particles = agentElement.querySelector('.agent-particles');
        
        // Create additional floating particles
        for (let i = 0; i < 5; i++) {
            const particle = document.createElement('div');
            particle.style.cssText = `
                position: absolute;
                width: 3px;
                height: 3px;
                background: rgba(255, 255, 255, 0.8);
                border-radius: 50%;
                pointer-events: none;
                top: ${Math.random() * 100}%;
                left: ${Math.random() * 100}%;
                animation: particle-burst 2s ease-out forwards;
            `;
            
            particles.appendChild(particle);
            
            // Remove particle after animation
            setTimeout(() => {
                if (particle.parentNode) {
                    particle.parentNode.removeChild(particle);
                }
            }, 2000);
        }
    }
}

// Add particle burst animation
const particleStyle = document.createElement('style');
particleStyle.textContent = `
    @keyframes particle-burst {
        0% {
            transform: scale(0) translateY(0);
            opacity: 1;
        }
        50% {
            transform: scale(1.5) translateY(-20px);
            opacity: 0.8;
        }
        100% {
            transform: scale(0) translateY(-40px);
            opacity: 0;
        }
    }
`;
document.head.appendChild(particleStyle);

// Smooth scrolling for navigation links
document.addEventListener('DOMContentLoaded', function() {
    // Initialize Agents Showcase
    const agentsShowcase = new AgentsShowcase();
    // Handle navigation link clicks
    const navLinks = document.querySelectorAll('.nav-links a');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            const targetSection = document.querySelector(targetId);
            if (targetSection) {
                targetSection.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Handle CTA button clicks
    const ctaButtons = document.querySelectorAll('.cta-button-primary, .cta-button-nav');
    ctaButtons.forEach(button => {
        button.addEventListener('click', function() {
            // Simulate booking action - in real implementation, this would open a booking form or redirect
            showBookingModal();
        });
    });

    // Intersection Observer for fade-in animations
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
            }
        });
    }, observerOptions);

    // Add fade-in class to sections and observe them
    const sections = document.querySelectorAll('section');
    sections.forEach(section => {
        section.classList.add('fade-in');
        observer.observe(section);
    });

    // Add fade-in to cards
    const cards = document.querySelectorAll('.agent-card, .story-card, .testimonial, .feature');
    cards.forEach(card => {
        card.classList.add('fade-in');
        observer.observe(card);
    });

    // Header background change on scroll
    const header = document.querySelector('.header');
    window.addEventListener('scroll', function() {
        if (window.scrollY > 100) {
            header.style.background = 'rgba(255, 255, 255, 0.98)';
            header.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.1)';
        } else {
            header.style.background = 'rgba(255, 255, 255, 0.95)';
            header.style.boxShadow = 'none';
        }
    });

    // Mobile menu toggle (for future enhancement)
    const mobileMenuToggle = document.createElement('button');
    mobileMenuToggle.innerHTML = '<i class="fas fa-bars"></i>';
    mobileMenuToggle.className = 'mobile-menu-toggle';
    mobileMenuToggle.style.display = 'none';
    
    // Add mobile menu styles
    const style = document.createElement('style');
    style.textContent = `
        .mobile-menu-toggle {
            background: none;
            border: none;
            font-size: 1.5rem;
            color: #333;
            cursor: pointer;
            padding: 0.5rem;
        }
        
        @media (max-width: 768px) {
            .mobile-menu-toggle {
                display: block !important;
            }
            
            .nav-links {
                display: none;
                position: absolute;
                top: 100%;
                left: 0;
                right: 0;
                background: white;
                flex-direction: column;
                padding: 1rem;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
            }
            
            .nav-links.active {
                display: flex !important;
            }
        }
    `;
    document.head.appendChild(style);

    // Add mobile menu toggle to nav
    const nav = document.querySelector('.nav');
    nav.insertBefore(mobileMenuToggle, nav.querySelector('.cta-button-nav'));

    // Mobile menu toggle functionality
    mobileMenuToggle.addEventListener('click', function() {
        const navLinks = document.querySelector('.nav-links');
        navLinks.classList.toggle('active');
    });

    // Close mobile menu when clicking on a link
    navLinks.forEach(link => {
        link.addEventListener('click', function() {
            document.querySelector('.nav-links').classList.remove('active');
        });
    });

    // Contact info click handlers
    const contactItems = document.querySelectorAll('.contact-item');
    contactItems.forEach(item => {
        item.addEventListener('click', function() {
            const text = this.querySelector('span').textContent;
            if (text.includes('@')) {
                // Email
                window.location.href = `mailto:${text}`;
            } else if (text.includes('+')) {
                // Phone
                window.location.href = `tel:${text}`;
            }
        });
        
        // Add cursor pointer style
        item.style.cursor = 'pointer';
        item.style.transition = 'color 0.3s ease';
        
        item.addEventListener('mouseenter', function() {
            this.style.color = '#007bff';
        });
        
        item.addEventListener('mouseleave', function() {
            this.style.color = '#2c3e50';
        });
    });

    // Parallax effect for hero section
    window.addEventListener('scroll', function() {
        const scrolled = window.pageYOffset;
        const hero = document.querySelector('.hero');
        const rate = scrolled * -0.5;
        
        if (hero) {
            hero.style.transform = `translateY(${rate}px)`;
        }
    });

    // Counter animation for metrics
    function animateCounter(element, target, duration = 2000) {
        let start = 0;
        const increment = target / (duration / 16);
        
        function updateCounter() {
            start += increment;
            if (start < target) {
                element.textContent = Math.floor(start) + '%';
                requestAnimationFrame(updateCounter);
            } else {
                element.textContent = target + '%';
            }
        }
        
        updateCounter();
    }

    // Animate metrics when they come into view
    const metricsObserver = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting && !entry.target.classList.contains('animated')) {
                const text = entry.target.textContent;
                const number = parseInt(text.match(/\d+/));
                if (number) {
                    entry.target.classList.add('animated');
                    animateCounter(entry.target, number);
                }
            }
        });
    }, { threshold: 0.5 });

    const metrics = document.querySelectorAll('.metric');
    metrics.forEach(metric => {
        metricsObserver.observe(metric);
    });
});

// Booking modal functionality
function showBookingModal() {
    // Create modal overlay
    const modalOverlay = document.createElement('div');
    modalOverlay.className = 'modal-overlay';
    modalOverlay.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.8);
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 10000;
        opacity: 0;
        transition: opacity 0.3s ease;
    `;

    // Create modal content
    const modalContent = document.createElement('div');
    modalContent.className = 'modal-content';
    modalContent.style.cssText = `
        background: white;
        padding: 3rem;
        border-radius: 16px;
        max-width: 500px;
        width: 90%;
        text-align: center;
        transform: scale(0.8);
        transition: transform 0.3s ease;
    `;

    modalContent.innerHTML = `
        <h2 style="color: #2c3e50; margin-bottom: 1rem;">Book Your Free UAE AI Strategy Session</h2>
        <p style="color: #666; margin-bottom: 2rem;">Ready to transform your business with AI? Let's discuss your specific needs and goals.</p>
        
        <div style="margin-bottom: 2rem;">
            <div style="display: flex; justify-content: center; gap: 2rem; margin-bottom: 1rem; flex-wrap: wrap;">
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                    <i class="fas fa-envelope" style="color: #007bff;"></i>
                    <span>hello@myaibo.in</span>
                </div>
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                    <i class="fas fa-phone" style="color: #007bff;"></i>
                    <span>+971-4-000-1234</span>
                </div>
            </div>
        </div>
        
        <div style="display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap;">
            <button class="modal-cta-email" style="
                background: linear-gradient(135deg, #007bff, #0056b3);
                color: white;
                border: none;
                padding: 0.75rem 1.5rem;
                border-radius: 8px;
                font-weight: 600;
                cursor: pointer;
                transition: transform 0.2s ease;
            ">Email Us</button>
            
            <button class="modal-cta-call" style="
                background: linear-gradient(135deg, #28a745, #1e7e34);
                color: white;
                border: none;
                padding: 0.75rem 1.5rem;
                border-radius: 8px;
                font-weight: 600;
                cursor: pointer;
                transition: transform 0.2s ease;
            ">Call Now</button>
            
            <button class="modal-close" style="
                background: #6c757d;
                color: white;
                border: none;
                padding: 0.75rem 1.5rem;
                border-radius: 8px;
                font-weight: 600;
                cursor: pointer;
                transition: transform 0.2s ease;
            ">Close</button>
        </div>
    `;

    modalOverlay.appendChild(modalContent);
    document.body.appendChild(modalOverlay);

    // Animate modal in
    setTimeout(() => {
        modalOverlay.style.opacity = '1';
        modalContent.style.transform = 'scale(1)';
    }, 10);

    // Add event listeners
    modalContent.querySelector('.modal-cta-email').addEventListener('click', function() {
        window.location.href = 'mailto:hello@myaibo.in?subject=Free UAE AI Strategy Session Request';
    });

    modalContent.querySelector('.modal-cta-call').addEventListener('click', function() {
        window.location.href = 'tel:+971-4-000-1234';
    });

    modalContent.querySelector('.modal-close').addEventListener('click', closeModal);
    modalOverlay.addEventListener('click', function(e) {
        if (e.target === modalOverlay) {
            closeModal();
        }
    });

    function closeModal() {
        modalOverlay.style.opacity = '0';
        modalContent.style.transform = 'scale(0.8)';
        setTimeout(() => {
            document.body.removeChild(modalOverlay);
        }, 300);
    }

    // Close modal with Escape key
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeModal();
        }
    });
}

// Add hover effects to buttons
document.addEventListener('DOMContentLoaded', function() {
    const buttons = document.querySelectorAll('button');
    buttons.forEach(button => {
        button.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-2px)';
        });
        
        button.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
        });
    });
});

// Performance optimization: Lazy load images
document.addEventListener('DOMContentLoaded', function() {
    const images = document.querySelectorAll('img');
    
    const imageObserver = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                if (img.dataset.src) {
                    img.src = img.dataset.src;
                    img.removeAttribute('data-src');
                    imageObserver.unobserve(img);
                }
            }
        });
    });

    images.forEach(img => {
        if (img.src && img.src !== window.location.href) {
            // Image already has src, no need to lazy load
            return;
        }
        imageObserver.observe(img);
    });
});

// Add loading animation
window.addEventListener('load', function() {
    document.body.classList.add('loaded');
    
    // Add CSS for loading animation
    const loadingStyle = document.createElement('style');
    loadingStyle.textContent = `
        body {
            opacity: 0;
            transition: opacity 0.5s ease;
        }
        
        body.loaded {
            opacity: 1;
        }
    `;
    document.head.appendChild(loadingStyle);
});
