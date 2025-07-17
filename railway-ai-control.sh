#!/usr/bin/env bash
#
# Railway Traffic Control AI System v2.0
# 
# Written by Andrea Giani

set -e

APP_NAME="railway-ai-control"

# Trova l'ultima versione di PHP disponibile
LATEST_PHP=$(curl -s "https://windows.php.net/download/" | grep -oE "php-[0-9]+\.[0-9]+\.[0-9]+-nts-Win32-vs17-x64.zip" | sort -V | tail -n 1)

PHP_VER=$(echo "$LATEST_PHP" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+")
PHP_DIR="php-${PHP_VER}"
PHP_ZIP="$LATEST_PHP"
PHP_URL="https://windows.php.net/downloads/releases/${PHP_ZIP}"

echo "==> Creating Enhanced Railway AI Control System: $APP_NAME"
rm -rf "$APP_NAME" "$PHP_DIR"
mkdir -p "$APP_NAME"
cd "$APP_NAME"

command -v unzip >/dev/null 2>&1 || { echo >&2 "ERROR: unzip is required but not installed."; exit 1; }

echo "==> Downloading PHP version $PHP_VER..."
curl -LO "$PHP_URL"
unzip "$PHP_ZIP" -d "$PHP_DIR"

echo "==> Configuring PHP and SQLite3..."
cp "$PHP_DIR/php.ini-development" "$PHP_DIR/php.ini"

sed -i "s|;extension_dir = \"ext\"|extension_dir = \"ext\"|" "$PHP_DIR/php.ini"
sed -i "s|;extension=sqlite3|extension=sqlite3|" "$PHP_DIR/php.ini"

if [ ! -f "$PHP_DIR/ext/php_sqlite3.dll" ]; then
    echo "ERROR: php_sqlite3.dll not found in $PHP_DIR/ext/"
    exit 1
fi

echo "==> Generating Enhanced Railway AI Control System..."
cat > index.php <<'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Railway AI Traffic Control System</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/tensorflow/4.10.0/tf.min.js"></script>
  <style>
    body { margin:0; font-family: 'Courier New', monospace; background: #0a0a0a; color: #00ff00; overflow: hidden; }
    .hud { position: fixed; top: 10px; left: 10px; background: rgba(0,0,0,0.8); 
           padding: 15px; border: 2px solid #00ff00; border-radius: 8px; 
           font-size: 12px; min-width: 300px; z-index: 1000; }
    .metric { display: flex; justify-content: space-between; margin: 5px 0; }
    .status-good { color: #00ff00; }
    .status-warning { color: #ffaa00; }
    .status-critical { color: #ff0000; }
    .ai-decision { background: rgba(0,255,0,0.1); padding: 5px; margin: 5px 0; 
                   border-left: 3px solid #00ff00; font-size: 11px; }
    .controls { position: fixed; bottom: 10px; left: 10px; background: rgba(0,0,0,0.8);
                padding: 10px; border: 2px solid #00ff00; border-radius: 8px; }
    canvas { display: block; }
    
    /* Stili aggiuntivi per le nuove funzionalità */
    .notifications {
      position: fixed;
      top: 10px;
      right: 10px;
      width: 300px;
      z-index: 1000;
    }
    .notification {
      padding: 12px;
      margin-bottom: 10px;
      border-radius: 6px;
      background: rgba(0,0,0,0.85);
      border-left: 4px solid;
      animation: fadeIn 0.3s;
    }
    @keyframes fadeIn { from { opacity:0; } to { opacity:1; } }
    .notification-info { border-color: #3498db; }
    .notification-warning { border-color: #f39c12; }
    .notification-critical { border-color: #e74c3c; }
    .weather-indicator {
      position: fixed;
      top: 10px;
      right: 320px;
      background: rgba(0,0,0,0.8);
      padding: 8px 15px;
      border-radius: 8px;
      z-index: 1000;
    }
    .sensor-panel {
      position: fixed;
      bottom: 60px;
      left: 10px;
      background: rgba(0,0,0,0.8);
      padding: 10px;
      border: 2px solid #00ff00;
      border-radius: 8px;
      min-width: 300px;
    }
	.surveillance-panel {
	  position: fixed;
	  bottom: 60px;
	  left: 350px;
	  background: rgba(0,0,0,0.8);
	  padding: 10px;
	  border: 2px solid #00ff00;
	  border-radius: 8px;
	  min-width: 300px;
	  z-index: 1000;
	}	
    .report-btn {
      position: fixed;
      top: 10px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(0,100,200,0.8);
      padding: 10px 20px;
      border-radius: 8px;
      cursor: pointer;
      z-index: 1000;
    }
  </style>
</head>
<body>
  <canvas id="canvas"></canvas>
  
  <div class="hud">
    <h3>RAILWAY AI CONTROL TOWER</h3>
    <div class="metric">System Status: <span id="systemStatus" class="status-good">OPERATIONAL</span></div>
    <div class="metric">Active Trains: <span id="activeTrains">0</span></div>
    <div class="metric">Total Throughput: <span id="throughput">0</span>/h</div>
    <div class="metric">Efficiency: <span id="efficiency">0</span>%</div>
    <div class="metric">Avg Delay: <span id="avgDelay">0</span>s</div>
    <div class="metric">Safety Score: <span id="safetyScore" class="status-good">100</span>%</div>
    
    <h4>AI Decision Engine</h4>
    <div id="aiDecisions" style="max-height: 150px; overflow-y: auto;"></div>
  </div>

  <!-- Nuovi elementi UI -->
  <div class="weather-indicator">
    Weather conditions: <span id="weatherStatus">Sunny</span> | 
    Visibility: <span id="visibility">100%</span>
  </div>
  
  <div class="notifications" id="notificationArea"></div>
  
  <div class="report-btn" onclick="generateReport()">
    GENERATE SYSTEM REPORTS
  </div>
  
  <div class="sensor-panel">
    <h4>EXTERNAL SENSORS</h4>
    <div class="metric">Track temperature: <span id="railTemp">32°C</span></div>
    <div class="metric">Vibrations: <span id="vibration">Low</span></div>
    <div class="metric">Cameras: <span id="cameraStatus">Operative</span></div>
  </div>

  <div class="surveillance-panel">
    <h4>VIDEO SURVEILLANCE SYSTEM</h4>
    <div class="metric">Status: <span id="surveillanceStatus" class="status-good">ACTIVE</span></div>
    <div class="metric">Intrusions detected: <span id="intrusionCount">0</span></div>
    <div class="metric">Sensitive areas: <span id="sensitiveZones">Stations, Tracks</span></div>
  </div>

  <div class="controls">
    <button onclick="spawnTrain()">Spawn Train</button>
    <button onclick="toggleEmergency()">Emergency</button>
    <button onclick="resetSystem()">Reset</button>
    <button onclick="toggleAI()">AI: <span id="aiStatus">ON</span></button>
    <button onclick="toggleSound()">Sound: <span id="soundStatus">ON</span></button>
  </div>

  <script>
    // ===========================================
    // RAILWAY AI CONTROL SYSTEM - CORE ENGINE
    // ===========================================
    
	let userInteracted = false;
	
    // ===========================================
    // ADVANCED SOUND ENGINE
    // ===========================================

	function activateAudio() {
		if (!audioContext) return;
		
		// Crea un nodo guadagno silenzioso
		const gainNode = audioContext.createGain();
		gainNode.gain.value = 0.001;
		gainNode.connect(audioContext.destination);
		
		// Crea un oscillatore a frequenza zero
		const oscillator = audioContext.createOscillator();
		oscillator.frequency.value = 0;
		oscillator.connect(gainNode);
		
		// Avvia e ferma immediatamente
		oscillator.start();
		oscillator.stop(audioContext.currentTime + 0.001);
		
		userInteracted = true;
		console.log("Contesto audio attivato automaticamente");
	}

//	const audioContext = new (window.AudioContext || window.webkitAudioContext)();

	let audioContext;
	try {
		audioContext = new (window.AudioContext || window.webkitAudioContext)();
	} catch (e) {
		console.error("Web Audio API non supportata", e);
	}
    
    const soundSystem = {
      enabled: true,
      
      // Train horn sound
      trainHorn(frequency = 150, duration = 800) {
        if (!this.enabled) return;
        
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);
        
        oscillator.frequency.setValueAtTime(frequency, audioContext.currentTime);
        oscillator.frequency.exponentialRampToValueAtTime(frequency * 0.7, audioContext.currentTime + duration/1000);
        
        gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + duration/1000);
        
        oscillator.type = 'sawtooth';
        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + duration/1000);
      },
      
      // Train wheels on tracks
      trainMovement(speed = 0.5) {
        if (!this.enabled) return;
        
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();
        const filter = audioContext.createBiquadFilter();
        
        oscillator.connect(filter);
        filter.connect(gainNode);
        gainNode.connect(audioContext.destination);
        
        oscillator.frequency.setValueAtTime(80 + speed * 40, audioContext.currentTime);
        oscillator.type = 'square';
        
        filter.type = 'lowpass';
        filter.frequency.setValueAtTime(200 + speed * 100, audioContext.currentTime);
        
        gainNode.gain.setValueAtTime(0.1, audioContext.currentTime);
        gainNode.gain.setValueAtTime(0, audioContext.currentTime + 0.1);
        
        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + 0.1);
      },
      
      // Emergency alarm
      emergencyAlarm() {
        if (!this.enabled) return;
        
        for (let i = 0; i < 3; i++) {
          setTimeout(() => {
            const oscillator = audioContext.createOscillator();
            const gainNode = audioContext.createGain();
            
            oscillator.connect(gainNode);
            gainNode.connect(audioContext.destination);
            
            oscillator.frequency.setValueAtTime(800, audioContext.currentTime);
            oscillator.frequency.setValueAtTime(1200, audioContext.currentTime + 0.2);
            oscillator.frequency.setValueAtTime(800, audioContext.currentTime + 0.4);
            
            gainNode.gain.setValueAtTime(0.4, audioContext.currentTime);
            gainNode.gain.setValueAtTime(0, audioContext.currentTime + 0.5);
            
            oscillator.type = 'sine';
            oscillator.start(audioContext.currentTime);
            oscillator.stop(audioContext.currentTime + 0.5);
          }, i * 600);
        }
      },
      
      // AI decision notification
      aiDecision() {
        if (!this.enabled) return;
        
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);
        
        oscillator.frequency.setValueAtTime(600, audioContext.currentTime);
        oscillator.frequency.setValueAtTime(800, audioContext.currentTime + 0.1);
        
        gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.2);
        
        oscillator.type = 'sine';
        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + 0.2);
      },
      
      // Station bell
      stationBell() {
        if (!this.enabled) return;
        
        [440, 523, 659].forEach((freq, i) => {
          setTimeout(() => {
            const oscillator = audioContext.createOscillator();
            const gainNode = audioContext.createGain();
            
            oscillator.connect(gainNode);
            gainNode.connect(audioContext.destination);
            
            oscillator.frequency.setValueAtTime(freq, audioContext.currentTime);
            gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
            gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 1);
            
            oscillator.type = 'sine';
            oscillator.start(audioContext.currentTime);
            oscillator.stop(audioContext.currentTime + 1);
          }, i * 200);
        });
      },
      
      // Collision warning
      collisionWarning() {
        if (!this.enabled) return;
        
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);
        
        // Rapid beeps
        for (let i = 0; i < 5; i++) {
          oscillator.frequency.setValueAtTime(1000, audioContext.currentTime + i * 0.1);
          gainNode.gain.setValueAtTime(0.5, audioContext.currentTime + i * 0.1);
          gainNode.gain.setValueAtTime(0, audioContext.currentTime + i * 0.1 + 0.05);
        }
        
        oscillator.type = 'square';
        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + 0.5);
      },
      
      // Ambient railway station
      playAmbient() {
        if (!this.enabled) return;
        
        // Subtle background hum
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();
        const filter = audioContext.createBiquadFilter();
        
        oscillator.connect(filter);
        filter.connect(gainNode);
        gainNode.connect(audioContext.destination);
        
        oscillator.frequency.setValueAtTime(60, audioContext.currentTime);
        oscillator.type = 'sawtooth';
        
        filter.type = 'lowpass';
        filter.frequency.setValueAtTime(120, audioContext.currentTime);
        
        gainNode.gain.setValueAtTime(0.02, audioContext.currentTime);
        
        oscillator.start(audioContext.currentTime);
        
        // Stop after 30 seconds
        setTimeout(() => {
          gainNode.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + 2);
          setTimeout(() => oscillator.stop(), 2000);
        }, 30000);
      },

		// Intrusion alert
	  intrusionAlert() {
		  if (!this.enabled) return;
		  
		  const oscillator = audioContext.createOscillator();
		  const gainNode = audioContext.createGain();
		  
		  oscillator.connect(gainNode);
		  gainNode.connect(audioContext.destination);
		  
		  // Sirena pulsante
		  for (let i = 0; i < 5; i++) {
			oscillator.frequency.setValueAtTime(800, audioContext.currentTime + i * 0.5);
			oscillator.frequency.setValueAtTime(1200, audioContext.currentTime + i * 0.5 + 0.25);
			gainNode.gain.setValueAtTime(0.8, audioContext.currentTime + i * 0.5);
			gainNode.gain.setValueAtTime(0, audioContext.currentTime + i * 0.5 + 0.25);
		  }
		  
		  oscillator.type = 'sawtooth';
		  oscillator.start(audioContext.currentTime);
		  oscillator.stop(audioContext.currentTime + 2.5);
	  }
    };

    // ===========================================
    // VOICE SYNTHESIZER (Web Speech API)
    // ===========================================

	class VoiceSynthesizer {
		constructor() {
			this.synth = window.speechSynthesis;
			this.voices = [];
			this.selectedVoice = null;
			this.speechQueue = []; // New: Queue for utterances
			this.isSpeaking = false; // New: Flag to track if currently speaking
			this.initVoices();
		}

		initVoices() {
			if (this.synth.onvoiceschanged !== undefined) {
				this.synth.onvoiceschanged = () => this.populateVoiceList();
			}
			this.populateVoiceList();
		}

		populateVoiceList() {
			this.voices = this.synth.getVoices();
			this.selectedVoice = this.voices.find(voice => voice.lang === 'it-IT') ||
								this.voices.find(voice => voice.lang.startsWith('en-')) ||
								this.voices[0];
			// If there are items in the queue, try to process them now that voices are loaded
			if (this.speechQueue.length > 0 && !this.isSpeaking) {
				this.processQueue();
			}
		}

		speak(text, type = 'info') {
			if (!this.synth || !userInteracted) {
				console.log(`Speech Skipped (no synth or no user interaction): "${text}"`);
				return;
			}

			const utterance = new SpeechSynthesisUtterance(text);
			utterance.voice = this.selectedVoice;
			utterance.pitch = 1;
			utterance.rate = 1;

			if (type === 'critical') {
				utterance.pitch = 1.2;
				utterance.rate = 0.9;
			} else if (type === 'warning') {
				utterance.pitch = 1.1;
				utterance.rate = 1.0;
			}

			utterance.onerror = (event) => {
				console.error('SpeechSynthesisUtterance.onerror', event.error);
				this.isSpeaking = false; // Reset flag on error
				this.processQueue(); // Try next in queue
			};

			utterance.onend = () => {
				this.isSpeaking = false; // Speech ended
				this.processQueue(); // Process next in queue
			};

			this.speechQueue.push(utterance); // Add to queue
			if (!this.isSpeaking) {
				this.processQueue(); // If not speaking, start processing
			}
		}

		processQueue() {
			if (this.speechQueue.length > 0 && !this.isSpeaking) {
				const nextUtterance = this.speechQueue.shift(); // Get next utterance
				this.isSpeaking = true; // Set speaking flag
				this.synth.speak(nextUtterance);
			}
		}
	}

    const voiceSynthesizer = new VoiceSynthesizer();

	// --- Speak Notification System ---
//	function showNotification(message, type = 'info', duration = 3000) {
//		notificationsElement.textContent = message;
//		notificationsElement.className = ''; // Reset classes
//		notificationsElement.classList.add(type); // Add type class for styling (e.g., 'critical', 'warning')
//		notificationsElement.style.display = 'block';
//		voiceSynthesizer.speak(message, type); // Speak the notification message
//		setTimeout(() => {
//			notificationsElement.style.display = 'none';
//		}, duration);
//	}

	setTimeout(activateAudio, 1000);  // Attiva dopo 1 secondo

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, window.innerWidth/window.innerHeight, 0.1, 1000);
    const renderer = new THREE.WebGLRenderer({canvas: document.getElementById('canvas'), antialias: true});
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setClearColor(0x001122);
    scene.fog = new THREE.Fog(0x001122, 50, 200);

    // Lighting
    const ambientLight = new THREE.AmbientLight(0x404040, 0.4);
    scene.add(ambientLight);
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(50, 50, 50);
    scene.add(directionalLight);

    // Camera setup
    camera.position.set(0, 25, 30);
    camera.lookAt(0, 0, 0);

    // ===========================================
    // RAILWAY INFRASTRUCTURE
    // ===========================================
    
    const tracks = [];
    const stations = [];
    const signals = [];
    
    // Create railway tracks (4 parallel tracks)
    function createTracks() {
      for (let i = 0; i < 4; i++) {
        const trackGeometry = new THREE.BoxGeometry(100, 0.2, 0.5);
        const trackMaterial = new THREE.MeshLambertMaterial({color: 0x666666});
        const track = new THREE.Mesh(trackGeometry, trackMaterial);
        track.position.set(0, 0, (i - 1.5) * 4);
        scene.add(track);
        
        // Rails
        for (let side of [-0.3, 0.3]) {
          const railGeometry = new THREE.BoxGeometry(100, 0.1, 0.1);
          const railMaterial = new THREE.MeshLambertMaterial({color: 0x999999});
          const rail = new THREE.Mesh(railGeometry, railMaterial);
          rail.position.set(0, 0.15, (i - 1.5) * 4 + side);
          scene.add(rail);
        }
        
        tracks.push({
          id: i,
          z: (i - 1.5) * 4,
          occupied: false,
          direction: i % 2 === 0 ? 1 : -1, // Alternate directions
          trains: []
        });
      }
    }
    
    // Create stations
    function createStations() {
      for (let i = 0; i < 3; i++) {
        const stationGeometry = new THREE.BoxGeometry(8, 3, 18);
        const stationMaterial = new THREE.MeshLambertMaterial({color: 0x4444aa});
        const station = new THREE.Mesh(stationGeometry, stationMaterial);
        station.position.set((i - 1) * 30, 1.5, 0);
        scene.add(station);
        
        // Station name
        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        canvas.width = 256;
        canvas.height = 64;
        context.fillStyle = '#ffffff';
        context.font = 'bold 20px Arial';
        context.textAlign = 'center';
        context.fillText(`STATION ${String.fromCharCode(65 + i)}`, 128, 40);
        
        const texture = new THREE.CanvasTexture(canvas);
        const textMaterial = new THREE.MeshBasicMaterial({map: texture});
        const textGeometry = new THREE.PlaneGeometry(4, 1);
        const textMesh = new THREE.Mesh(textGeometry, textMaterial);
        textMesh.position.set((i - 1) * 30, 4, 0);
        scene.add(textMesh);
        
        stations.push({
          id: i,
          name: String.fromCharCode(65 + i),
          x: (i - 1) * 30,
          capacity: 2,
          occupancy: 0
        });
      }
    }
    
    // Create traffic signals
    function createSignals() {
      for (let i = 0; i < 8; i++) {
        const signalGeometry = new THREE.CylinderGeometry(0.2, 0.2, 3);
        const signalMaterial = new THREE.MeshLambertMaterial({color: 0x00ff00});
        const signal = new THREE.Mesh(signalGeometry, signalMaterial);
        signal.position.set((i - 3.5) * 12, 2, -8);
        scene.add(signal);
        
        signals.push({
          id: i,
          x: (i - 3.5) * 12,
          state: 'green', // green, yellow, red
          mesh: signal
        });
      }
    }

    // ===========================================
    // TRAIN SYSTEM WITH ADVANCED FEATURES
    // ===========================================
    
    const trains = [];
    let trainIdCounter = 0;
    
    class Train {
      constructor(trackId, startX = -50) {
        this.id = trainIdCounter++;
        this.trackId = trackId;
        this.x = startX;
        this.z = tracks[trackId].z;
        this.direction = tracks[trackId].direction;
        this.destination = Math.floor(Math.random() * stations.length);
        this.state = 'moving'; // moving, stopping, stopped, waiting
        this.waitTime = 0;
        this.totalDelay = 0;
		this.speedingNotified = false;
		this.blinkCounter = 0;
		this.isOverspeeding = false;
		this.locomotive = null;

        // Tipi di treno: 1=Passeggeri, 2=Alta velocità, 3=Merci
        this.trainType = Math.floor(Math.random() * 3) + 1;
        
        // Assegnazione priorità in base al tipo
        switch(this.trainType) {
          case 1: // Passeggeri
            this.priority = 4 + Math.floor(Math.random() * 2);
            this.baseSpeed = 0.4 + Math.random() * 0.3;
            this.color = new THREE.Color().setHSL(0.6, 0.8, 0.5); // Blu
            break;
          case 2: // Alta velocità
            this.priority = 5;
            this.baseSpeed = 0.7 + Math.random() * 0.2;
            this.color = new THREE.Color().setHSL(0.9, 0.8, 0.6); // Rosso
            break;
          default: // Merci
            this.priority = 2 + Math.floor(Math.random() * 2);
            this.baseSpeed = 0.2 + Math.random() * 0.2;
            this.color = new THREE.Color().setHSL(0.3, 0.8, 0.5); // Verde
        }
        
        this.maxSpeed = this.baseSpeed * weatherSystem.speedMultiplier;
        this.speed = this.maxSpeed;
        
        this.createMesh();
        trains.push(this);
        tracks[trackId].trains.push(this);
      }
      
      createMesh() {
        const trainGroup = new THREE.Group();
        
        // Locomotive
        const locoGeometry = new THREE.BoxGeometry(4, 2, 1.5);
        const locoMaterial = new THREE.MeshLambertMaterial({
          color: this.color
        });
        const locomotive = new THREE.Mesh(locoGeometry, locoMaterial);
        locomotive.position.y = 1;
        trainGroup.add(locomotive);
        
        // Cars
        for (let i = 1; i <= 2; i++) {
          const carGeometry = new THREE.BoxGeometry(3, 1.5, 1.5);
          const carMaterial = new THREE.MeshLambertMaterial({color: 0x666666});
          const car = new THREE.Mesh(carGeometry, carMaterial);
          car.position.set(-i * 4, 0.75, 0);
          trainGroup.add(car);
        }
        
        trainGroup.position.set(this.x, 0, this.z);
        scene.add(trainGroup);
        this.mesh = trainGroup;
        
        // Train ID label
        this.createLabel();
        this.locomotive = locomotive;  // Memorizza riferimento diretto
		
        // Train spawn sound
        soundSystem.trainHorn(120 + Math.random() * 100, 600);
      }
      
      createLabel() {
        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        canvas.width = 128;
        canvas.height = 64;
        context.fillStyle = '#ffffff';
        context.font = 'bold 16px Arial';
        context.textAlign = 'center';
        
        const typeNames = ['', 'PASSENGERS', 'HIGH SPEED', 'CARGO TRAIN'];
        context.fillText(`T${this.id}`, 64, 20);
        context.fillText(`${typeNames[this.trainType]}`, 64, 40);
        
        const texture = new THREE.CanvasTexture(canvas);
        const labelMaterial = new THREE.MeshBasicMaterial({map: texture});
        const labelGeometry = new THREE.PlaneGeometry(2, 1);
        const label = new THREE.Mesh(labelGeometry, labelMaterial);
        label.position.set(0, 3, 0);
        this.mesh.add(label);
      }
      
      update() {
        if (this.state === 'moving') {

			// Rilevamento eccesso velocità
			const speedLimit = this.maxSpeed * 0.9;

			if (this.speed > speedLimit) {
			  if (!this.hasNotifiedOverspeed) {
				notificationSystem.addNotification(
				  ` T${this.id} exceeds speed limit: ${(this.speed*100).toFixed(0)} km/h`,
				  'warning'
				);
				this.hasNotifiedOverspeed = true;
				
				//  Cambia colore a rosso
			//	this.mesh.material.color.set(0xff0000);
				if (this.locomotive && this.locomotive.material) { // Add checks
					this.locomotive.material.color.set(0xff0000);
				}

				//  Lampeggio ogni 15 frame
			//	this.blinkCounter = (this.blinkCounter + 1) % 30;
			//	if (this.blinkCounter < 15) {
			//		this.mesh.material.color.set(0xff0000); // rosso
			//		this.blinkCounter = 0;
			//	} else {
			//		this.mesh.material.color.set(0x888888); // grigio normale
			//		this.blinkCounter = 0;
			//	}
  
			  }
			  
			} else {

			  this.hasNotifiedOverspeed = false;
			  
			  //  Ripristina colore normale
		//	  this.mesh.material.color.set(0x888888);
			  if (this.locomotive && this.locomotive.material) { // Add checks
				  this.locomotive.material.color.set(this.color); // Use the original color
			  }
			  
			  this.blinkCounter = 0;
			}
          
			// AI collision avoidance
			if (this.checkCollisionRisk()) {
				this.state = 'waiting';
				this.waitTime = 60; // Wait frames
				aiSystem.addDecision(`Train T${this.id}: Collision avoidance - STOP`);
				//  Collision warning sound
				soundSystem.collisionWarning();
				return;
			}
          
			this.x += this.speed * this.direction;
			this.mesh.position.x = this.x;
          
			//  Occasional train movement sounds
			if (Math.random() < 0.02) { // 2% chance per frame
				soundSystem.trainMovement(this.speed);
			}
          
			// Check if reaching station
			const nearestStation = this.getNearestStation();
			if (nearestStation && Math.abs(this.x - nearestStation.x) < 3) {
				if (Math.random() < 0.3) { // 30% chance to stop
					this.state = 'stopping';
					this.waitTime = 120 + Math.random() * 180; // 2-5 seconds
					aiSystem.addDecision(`Train T${this.id}: Arriving at Station ${nearestStation.name}`);
					//  Station bell
					soundSystem.stationBell();
				}
			}
          
			// Remove train if off-screen
			if (Math.abs(this.x) > 60) {
				this.destroy();
			}

		} else if (this.state === 'waiting') {
		
			this.waitTime--;
			this.totalDelay++;
			
			// Verifica se la collisione è ancora possibile prima di ripartire
			if (this.waitTime <= 0) {
				if (this.checkCollisionRisk()) {
					// Se il pericolo persiste, aspetta ancora
					this.waitTime = 30;
				} else {
					this.state = 'moving';
					aiSystem.addDecision(`Train T${this.id}: Resuming movement`);
					soundSystem.trainHorn(100, 400);
				}
			}
			
		} else if (this.state === 'stopping') {
          
			this.waitTime--;
			this.totalDelay++;
			if (this.waitTime <= 0) {
				this.state = 'moving';
				aiSystem.addDecision(`Train T${this.id}: Resuming movement`);
				//  Resume horn
				soundSystem.trainHorn(100, 400);
			}
        }
      }
      
	  checkCollisionRisk() {
			const sameTrackTrains = tracks[this.trackId].trains.filter(t => t.id !== this.id);
			
			for (let other of sameTrackTrains) {
				const distance = Math.abs(this.x - other.x);
				const relativeSpeed = Math.abs(this.speed - other.speed);
				const safeDistance = 8 + relativeSpeed * 10;  // Distanza di sicurezza dinamica
				
				if (distance < safeDistance && 
					((this.direction > 0 && this.x < other.x) || 
					 (this.direction < 0 && this.x > other.x))) {
					return true;
				}
			}
			return false;
	  }

      getNearestStation() {
        let nearest = null;
        let minDistance = Infinity;
        for (let station of stations) {
          const distance = Math.abs(this.x - station.x);
          if (distance < minDistance) {
            minDistance = distance;
            nearest = station;
          }
        }
        return nearest;
      }
      
      destroy() {
        scene.remove(this.mesh);
        const index = trains.indexOf(this);
        if (index > -1) trains.splice(index, 1);
        
        const trackIndex = tracks[this.trackId].trains.indexOf(this);
        if (trackIndex > -1) tracks[this.trackId].trains.splice(trackIndex, 1);
      }

    }

    // ===========================================
    // AI DECISION SYSTEM WITH ENHANCED FEATURES
    // ===========================================
    
    const aiSystem = {
      enabled: true,
      decisions: [],
      lastOptimization: 0,
      
      addDecision(decision) {
        const timestamp = new Date().toLocaleTimeString();
        this.decisions.unshift(`[${timestamp}] ${decision}`);
        if (this.decisions.length > 10) this.decisions.pop();
        this.updateUI();
        
        // 🔊 AI decision notification sound
        soundSystem.aiDecision();
      },

	  resolveDeadlocks() {
		const deadlockedTrains = trains.filter(t => 
			t.state === 'waiting' && t.waitTime > 120
		);
		
		deadlockedTrains.forEach(train => {
			// Trova un binario alternativo libero
			const freeTrack = tracks.find(t => 
				!t.occupied && t.id !== train.trackId
			);
			
			if (freeTrack) {
				aiSystem.addDecision(`Train T${train.id}: Deadlock detected - Rerouting to track ${freeTrack.id}`);
				train.trackId = freeTrack.id;
				train.z = freeTrack.z;
				train.mesh.position.z = freeTrack.z;
				train.state = 'moving';
			}
		});
	  },

      updateUI() {
        const decisionsDiv = document.getElementById('aiDecisions');
        decisionsDiv.innerHTML = this.decisions.map(d => 
          `<div class="ai-decision">${d}</div>`
        ).join('');
      },
      
      optimize() {
        if (!this.enabled || Date.now() - this.lastOptimization < 2000) return;
        
        this.lastOptimization = Date.now();
        
        // Traffic light optimization
        this.optimizeTrafficLights();
        
        // Route optimization
        this.optimizeRoutes();
        
        // Priority scheduling
        this.schedulePriority();
      },
      
      optimizeTrafficLights() {
        signals.forEach((signal, index) => {
          const nearbyTrains = trains.filter(t => Math.abs(t.x - signal.x) < 10);
          
          if (nearbyTrains.length > 0) {
            const highPriorityTrain = nearbyTrains.find(t => t.priority >= 4);
            if (highPriorityTrain) {
              signal.state = 'green';
              signal.mesh.material.color.setHex(0x00ff00);
              this.addDecision(`Signal ${index}: GREEN for high-priority train T${highPriorityTrain.id}`);
            } else if (nearbyTrains.length > 2) {
              signal.state = 'yellow';
              signal.mesh.material.color.setHex(0xffaa00);
            }
          } else {
            signal.state = 'green';
            signal.mesh.material.color.setHex(0x00ff00);
          }
        });
      },
      
      optimizeRoutes() {
        // Find congested tracks
        const congestion = tracks.map(track => ({
          id: track.id,
          density: track.trains.length,
          avgSpeed: track.trains.reduce((sum, t) => sum + t.speed, 0) / (track.trains.length || 1)
        }));
        
        const mostCongested = congestion.reduce((max, track) => 
          track.density > max.density ? track : max, {density: 0});
        
        if (mostCongested.density > 2) {
          this.addDecision(`Track ${mostCongested.id}: HIGH CONGESTION detected - Rerouting recommended`);
        }
      },
      
      schedulePriority() {
        // Sort trains by priority and delay
        const sortedTrains = [...trains].sort((a, b) => {
          const scoreA = a.priority * 10 + a.totalDelay / 10;
          const scoreB = b.priority * 10 + b.totalDelay / 10;
          return scoreB - scoreA;
        });
        
        if (sortedTrains.length > 0 && sortedTrains[0].totalDelay > 300) {
          this.addDecision(`Train T${sortedTrains[0].id}: HIGH PRIORITY - Expediting route`);
          sortedTrains[0].speed = Math.min(sortedTrains[0].speed * 1.2, 0.8);
        }
      }
    };

    // ===========================================
    // SYSTEM METRICS & MONITORING
    // ===========================================
    
    const metrics = {
      totalThroughput: 0,
      totalTrains: 0,
      avgDelay: 0,
      efficiency: 100,
      safetyScore: 100,
      emergencyMode: false,
      
      update() {
        // Update real-time metrics
        document.getElementById('activeTrains').textContent = trains.length;
        document.getElementById('throughput').textContent = Math.floor(this.totalThroughput);
        
        // Calculate average delay
        if (trains.length > 0) {
          this.avgDelay = trains.reduce((sum, t) => sum + t.totalDelay, 0) / trains.length / 60;
          document.getElementById('avgDelay').textContent = Math.floor(this.avgDelay);
        }
        
        // Calculate efficiency
        const idealSpeed = 0.5;
        const actualSpeed = trains.length > 0 ? 
          trains.reduce((sum, t) => sum + t.speed, 0) / trains.length : idealSpeed;
        this.efficiency = Math.floor((actualSpeed / idealSpeed) * 100);
        document.getElementById('efficiency').textContent = this.efficiency;
        
        // Safety score (based on near-misses)
        let dangerousProximities = 0;
        for (let i = 0; i < trains.length; i++) {
          for (let j = i + 1; j < trains.length; j++) {
            if (trains[i].trackId === trains[j].trackId) {
              const distance = Math.abs(trains[i].x - trains[j].x);
              if (distance < 6) dangerousProximities++;
            }
          }
        }
        this.safetyScore = Math.max(0, 100 - dangerousProximities * 10);
        
        const safetyElement = document.getElementById('safetyScore');
        safetyElement.textContent = this.safetyScore;
        safetyElement.className = this.safetyScore > 80 ? 'status-good' : 
                                 this.safetyScore > 50 ? 'status-warning' : 'status-critical';
        
        // System status
        const statusElement = document.getElementById('systemStatus');
        if (this.emergencyMode) {
          statusElement.textContent = 'EMERGENCY';
          statusElement.className = 'status-critical';
        } else if (this.safetyScore < 50) {
          statusElement.textContent = 'WARNING';
          statusElement.className = 'status-warning';
        } else {
          statusElement.textContent = 'OPERATIONAL';
          statusElement.className = 'status-good';
        }
      }
    };

    // ===========================================
    // NEW SYSTEMS: NOTIFICATIONS, WEATHER, 
	// SENSORS, SPEAK
    // ===========================================
    
    const notificationSystem = {
      notifications: [],
      
      addNotification(message, severity = 'info') {
        const notification = {
          id: Date.now(),
          message,
          severity,
          timestamp: new Date().toLocaleTimeString()
        };
        
        this.notifications.unshift(notification);
        if (this.notifications.length > 8) this.notifications.pop();
        this.updateUI();
        
        // Notifiche sonore per eventi critici
        if (severity === 'critical') {
          soundSystem.emergencyAlarm();
        } else if (severity === 'warning') {
          soundSystem.collisionWarning();
        }

		// Aggiungi sintesi vocale
		if (voiceSynthesizer.synth && userInteracted) { // Assicurati che userInteracted sia true
		  console.log(`addNotification::SPEAK ATTEMPT::"${message}"`);
		  voiceSynthesizer.speak(message, severity);
		}		
      },
      
      updateUI() {
        const container = document.getElementById('notificationArea');
        container.innerHTML = this.notifications.map(notif => `
          <div class="notification notification-${notif.severity}">
            <strong>[${notif.timestamp}]</strong> ${notif.message}
          </div>
        `).join('');
      }
    };

    const weatherSystem = {
      conditions: ['sunny', 'rain', 'fog', 'snow'],
      currentCondition: 'sunny',
      visibility: 100,
      speedMultiplier: 1.0,
      
      init() {
        // Cambia condizioni meteo ogni 2-5 minuti
        setInterval(() => this.changeWeather(), 120000 + Math.random() * 180000);
      },
      
      changeWeather() {
        const newCondition = this.conditions[Math.floor(Math.random() * this.conditions.length)];
        this.currentCondition = newCondition;
        
        // Aggiorna parametri in base al meteo
        switch(newCondition) {
          case 'rain':
            this.visibility = 70;
            this.speedMultiplier = 0.8;
            scene.fog = new THREE.Fog(0x334455, 40, 150);
            break;
          case 'fog':
            this.visibility = 40;
            this.speedMultiplier = 0.7;
            scene.fog = new THREE.Fog(0x888888, 20, 100);
            break;
          case 'snow':
            this.visibility = 60;
            this.speedMultiplier = 0.6;
            scene.fog = new THREE.Fog(0xffffff, 30, 120);
            break;
          default: // sunny
            this.visibility = 100;
            this.speedMultiplier = 1.0;
            scene.fog = new THREE.Fog(0x001122, 50, 200);
        }
        
        // Aggiorna UI e invia notifica
        document.getElementById('weatherStatus').textContent = newCondition;
        document.getElementById('visibility').textContent = `${this.visibility}%`;
        notificationSystem.addNotification(
          `Changing weather conditions: ${newCondition.toUpperCase()}`,
          newCondition !== 'sunny' ? 'warning' : 'info'
        );
        
        // Aggiorna velocità treni
        trains.forEach(train => {
          train.maxSpeed = train.baseSpeed * this.speedMultiplier;
          if (train.speed > train.maxSpeed) train.speed = train.maxSpeed;
        });
      }
    };

    const sensorSystem = {
      init() {
        setInterval(() => this.updateSensors(), 10000);
      },
      
      updateSensors() {
        // Simula dati da sensori esterni
        const railTemp = 25 + Math.floor(Math.random() * 20);
        const vibrations = ['low', 'medium', 'high'][Math.floor(Math.random() * 3)];
        const cameraStatus = Math.random() > 0.1 ? 'Operative' : 'Problems';
    
        document.getElementById('railTemp').textContent = `${railTemp}°C`;
        document.getElementById('vibration').textContent = vibrations;
        document.getElementById('cameraStatus').textContent = cameraStatus;
        
        // Notifica problemi critici
        if (railTemp > 40) {
		  console.log("updateSensors::Rail Temperature High");
//		  showNotification(`WARNING: Rail Temperature High (${railTemp}) degrees Celsius)!`, 'warning');
          notificationSystem.addNotification(
            `Warning: High track temperature (${railTemp}°C)`,
            'critical'
          );
        }
        
        if (cameraStatus === 'Problems') {
		  console.log("updateSensors::cameraStatus as Problems");
//		  showNotification("WARNING: Security Cameras Offline!", 'warning');
          notificationSystem.addNotification(
            `Camera system problems`,
            'warning'
          );
        }
		
		if (vibrations === 'high') { // High vibration alert
		  console.log("updateSensors::tracks as high vibrations");
//		  showNotification(`CRITICAL: High Vibration Detected ! Potential track issue.`, 'critical');
		}
      }
    };

	const intrusionSystem = {
	  intrusionCount: 0,
	  zones: [
		{ name: "Station A", risk: 0.3 },
		{ name: "Station B", risk: 0.2 },
		{ name: "Tracks 1", risk: 0.4 },
		{ name: "Control Center", risk: 0.1 }
	  ],

	  init() {
		setInterval(() => this.checkIntrusions(), 15000);
	  },

	  checkIntrusions() {
		// Simula rilevamento intrusioni basato su rischio zona
		this.zones.forEach(zone => {
		  if (Math.random() < zone.risk) {
			this.handleIntrusion(zone.name);
		  }
		});
	  },

	  handleIntrusion(zone) {
		this.intrusionCount++;
		const timestamp = new Date().toLocaleTimeString();
		
		// Notifica visiva e sonora
		notificationSystem.addNotification(` Intrusion in ${zone}`, 'critical');
		soundSystem.intrusionAlert();
		
		// Registra nel log
		aiSystem.addDecision(`Intrusion detected in ${zone} - Alarm activated`);

		fetch('api.php?action=log_event', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/x-www-form-urlencoded',
			},
			body: new URLSearchParams({
				event_type: 'INTRUSION',
				description: `Intrusion detected in ${zone}`,
				severity: 'critical'
			})
		}).catch(error => console.error('API Error:', error));
	
		// Aggiorna UI
		document.getElementById('intrusionCount').textContent = this.intrusionCount;
		document.getElementById('surveillanceStatus').className = 'status-critical';
		document.getElementById('surveillanceStatus').textContent = 'ALLARM!';
		
		// Ripristina stato dopo 10 secondi
		setTimeout(() => {
		  document.getElementById('surveillanceStatus').className = 'status-good';
		  document.getElementById('surveillanceStatus').textContent = 'ACTIVE';
		}, 10000);
	  }
	};

    // ===========================================
    // REPORTING SYSTEM
    // ===========================================
    function generateReport() {
      const now = new Date();
      const reportData = {
        date: now.toLocaleDateString(),
        time: now.toLocaleTimeString(),
        totalTrains: metrics.totalTrains,
        activeTrains: trains.length,
        efficiency: metrics.efficiency,
        avgDelay: metrics.avgDelay,
        safetyScore: metrics.safetyScore,
        weather: weatherSystem.currentCondition,
        events: notificationSystem.notifications.slice(0, 10)
      };
      
      // Effetto visivo generazione report
      document.querySelector('.report-btn').textContent = ' REPORT GENERATION...';
      setTimeout(() => {
        document.querySelector('.report-btn').textContent = ' REPORT GENERATED!';
        
        // Notifica con dati del report
        const reportWindow = window.open('', '_blank');
        reportWindow.document.write(`
          <html><head><title>Report Sistema Ferroviario</title></head>
          <body style="font-family: Arial; background: #f0f0f0; padding: 20px;">
            <h1>Report Prestazioni Sistema</h1>
            <h2>${reportData.date} ${reportData.time}</h2>
            
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-top: 30px;">
              <div style="background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
                <h3>Key Metrics</h3>
                <p>Total trains: ${reportData.totalTrains}</p>
                <p>Active trains: ${reportData.activeTrains}</p>
                <p>Efficiency: ${reportData.efficiency}%</p>
                <p>Average delay: ${reportData.avgDelay}s</p>
                <p>Safety Index: ${reportData.safetyScore}%</p>
                <p>Weather conditions: ${reportData.weather}</p>
              </div>
              
              <div style="background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
                <h3>Eventi Recenti</h3>
                <ul>
                  ${reportData.events.map(e => `<li>[${e.timestamp}] ${e.message}</li>`).join('')}
                </ul>
              </div>
            </div>
            
            <div style="margin-top: 30px; text-align: center;">
              <h3>Distribuzione Tipi Treno</h3>
              <div style="display: flex; justify-content: center; gap: 20px; margin-top: 15px;">
                ${[1,2,3].map(type => {
                  const count = trains.filter(t => t.trainType === type).length;
                  return `<div style="text-align: center;">
                    <div style="font-size: 24px; font-weight: bold;">${count}</div>
                    <div>${['Passengers','High Speed','Cargo'][type-1]}</div>
                  </div>`;
                }).join('')}
              </div>
            </div>
          </body></html>
        `);
        
        setTimeout(() => {
          document.querySelector('.report-btn').textContent = ' GENERATE SYSTEM REPORTS';
        }, 3000);
      }, 1500);
    }

    // ===========================================
    // CONTROL FUNCTIONS
    // ===========================================
    
    function spawnTrain() {
      if (trains.length < 12) { // Max 12 trains
        const trackId = Math.floor(Math.random() * tracks.length);
        new Train(trackId);
        metrics.totalTrains++;
        aiSystem.addDecision(`New train T${trainIdCounter-1} spawned on Track ${trackId}`);
      }
    }
    
    function toggleEmergency() {
      metrics.emergencyMode = !metrics.emergencyMode;
      if (metrics.emergencyMode) {
        // Emergency: Stop all trains
        trains.forEach(train => {
          train.state = 'waiting';
          train.waitTime = 300;
        });
        signals.forEach(signal => {
          signal.state = 'red';
          signal.mesh.material.color.setHex(0xff0000);
        });
        aiSystem.addDecision(' EMERGENCY PROTOCOL ACTIVATED - All trains STOP');
        //  Emergency alarm
        soundSystem.emergencyAlarm();
      } else {
        trains.forEach(train => {
          if (train.state === 'waiting') train.state = 'moving';
        });
        aiSystem.addDecision(' Emergency cleared - Normal operations resumed');
      }
    }
    
    function resetSystem() {
      trains.forEach(train => train.destroy());
      metrics.totalThroughput = 0;
      metrics.totalTrains = 0;
      metrics.emergencyMode = false;
      aiSystem.decisions = [];
      aiSystem.updateUI();
      aiSystem.addDecision('System reset - All parameters cleared');
    }
    
    function toggleAI() {
      aiSystem.enabled = !aiSystem.enabled;
      document.getElementById('aiStatus').textContent = aiSystem.enabled ? 'ON' : 'OFF';
      aiSystem.addDecision(`AI Decision Engine: ${aiSystem.enabled ? 'ENABLED' : 'DISABLED'}`);
    }
    
    function toggleSound() {
      soundSystem.enabled = !soundSystem.enabled;
      document.getElementById('soundStatus').textContent = soundSystem.enabled ? 'ON' : 'OFF';
      if (soundSystem.enabled) {
        soundSystem.aiDecision(); // Test sound
      }
    }

    // ===========================================
    // INITIALIZATION & MAIN LOOP
    // ===========================================
    
    createTracks();
    createStations();
    createSignals();
    
    // Avvio nuovi sistemi
    weatherSystem.init();
    sensorSystem.init();
	intrusionSystem.init();
    
    // Initial trains
    for (let i = 0; i < 3; i++) {
      setTimeout(() => spawnTrain(), i * 2000);
    }
    
    // Auto-spawn trains
    setInterval(() => {
      if (trains.length < 8 && Math.random() < 0.3) {
        spawnTrain();
      }
    }, 5000);
    
    // Main animation loop
    function animate() {
      requestAnimationFrame(animate);

      // Usa un ciclo al contrario per evitare problemi di indici
      for (let i = trains.length - 1; i >= 0; i--) {
          trains[i].update();
      }	
      
//    trains.forEach(train => train.update());
      aiSystem.optimize();
	  aiSystem.resolveDeadlocks();
      metrics.update();
      
      // Camera movement
      const time = Date.now() * 0.001;
      camera.position.x = Math.sin(time * 0.1) * 10;
      camera.position.y = 25 + Math.sin(time * 0.05) * 5;
      camera.lookAt(0, 0, 0);

      renderer.render(scene, camera);
    }
    
    animate();
    
    // Initialize AI system
    aiSystem.addDecision(' Railway AI Control System ONLINE');
    aiSystem.addDecision('Monitoring 4 tracks, 3 stations, 8 signals');
    
    // Aggiunta notifica iniziale
    notificationSystem.addNotification('Sistema Railway AI Control avviato', 'info');
    notificationSystem.addNotification('Sensori esterni collegati', 'info');
    
    // Start ambient railway sounds
    setTimeout(() => soundSystem.playAmbient(), 2000);
    
    // Window resize handler
    window.addEventListener('resize', () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    });

    // Initialize audio context on first user interaction
    document.addEventListener('click', () => {
      if (audioContext.state === 'suspended') {
        audioContext.resume();
      }
	  userInteracted = true;
    }, { once: true });

  </script>
</body>
</html>
EOF

echo "==> Generating API endpoints..."
cat > api.php <<'EOF'
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$db = new SQLite3('railway_control.db');
$db->exec('CREATE TABLE IF NOT EXISTS trains (
    id INTEGER PRIMARY KEY,
    train_id TEXT,
    track_id INTEGER,
    position_x REAL,
    speed REAL,
    state TEXT,
    priority INTEGER,
    type TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
)');

$db->exec('CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY,
    event_type TEXT,
    description TEXT,
    severity TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
)');

$action = $_GET['action'] ?? '';

switch($action) {
    case 'log_train':
        $stmt = $db->prepare('INSERT INTO trains (train_id, track_id, position_x, speed, state, priority, type) VALUES (?, ?, ?, ?, ?, ?, ?)');
        $stmt->bindValue(1, $_POST['train_id'] ?? '');
        $stmt->bindValue(2, $_POST['track_id'] ?? 0);
        $stmt->bindValue(3, $_POST['position_x'] ?? 0.0);
        $stmt->bindValue(4, $_POST['speed'] ?? 0.0);
        $stmt->bindValue(5, $_POST['state'] ?? 'unknown');
        $stmt->bindValue(6, $_POST['priority'] ?? 1);
        $stmt->bindValue(7, $_POST['type'] ?? 'passenger');
        $result = $stmt->execute();
        echo json_encode(['success' => (bool)$result]);
        break;
        
    case 'log_event':
        $stmt = $db->prepare('INSERT INTO events (event_type, description, severity) VALUES (?, ?, ?)');
        $stmt->bindValue(1, $_POST['event_type'] ?? '');
        $stmt->bindValue(2, $_POST['description'] ?? '');
        $stmt->bindValue(3, $_POST['severity'] ?? 'info');

		if($_POST['event_type'] === 'INTRUSION') {
			$stmt->bindValue(1, 'INTRUSION');
			$stmt->bindValue(2, $_POST['description'] ?? '');
			$stmt->bindValue(3, 'critical');
		}

        $result = $stmt->execute();
        echo json_encode(['success' => (bool)$result]);
        break;
        
    case 'get_stats':
        $train_count = $db->querySingle('SELECT COUNT(*) FROM trains WHERE datetime(timestamp) > datetime("now", "-1 hour")');
        $events = $db->query('SELECT * FROM events ORDER BY timestamp DESC LIMIT 10');
        $event_list = [];
        while ($row = $events->fetchArray(SQLITE3_ASSOC)) {
            $event_list[] = $row;
        }
        echo json_encode([
            'train_count' => $train_count,
            'recent_events' => $event_list
        ]);
        break;
        
    case 'generate_report':
        $trains = $db->query('SELECT * FROM trains ORDER BY timestamp DESC LIMIT 50');
        $events = $db->query('SELECT * FROM events ORDER BY timestamp DESC LIMIT 20');
        
        $reportData = [
            'timestamp' => date('Y-m-d H:i:s'),
            'train_count' => $db->querySingle('SELECT COUNT(*) FROM trains'),
            'active_trains' => $db->querySingle('SELECT COUNT(*) FROM trains WHERE state != "stopped"'),
            'recent_events' => [],
            'train_types' => ['passenger' => 0, 'high_speed' => 0, 'freight' => 0]
        ];
        
        while ($event = $events->fetchArray(SQLITE3_ASSOC)) {
            $reportData['recent_events'][] = $event;
        }
        
        while ($train = $trains->fetchArray(SQLITE3_ASSOC)) {
            if ($train['type'] === 'passenger') $reportData['train_types']['passenger']++;
            if ($train['type'] === 'high_speed') $reportData['train_types']['high_speed']++;
            if ($train['type'] === 'freight') $reportData['train_types']['freight']++;
        }
        
        echo json_encode($reportData);
        break;
        
    case 'sensor_data':
        // Simula dati sensori
        $sensorData = [
            'timestamp' => date('Y-m-d H:i:s'),
            'rail_temperature' => rand(20, 45),
            'vibration_level' => ['low', 'medium', 'high'][rand(0,2)],
            'camera_status' => (rand(0,10) > 1 ? 'operational' : 'faulty'),
            'weather' => ['clear', 'rain', 'fog', 'snow'][rand(0,3)]
        ];
        echo json_encode($sensorData);
        break;

	case 'get_intrusions':
		$count = $db->querySingle('SELECT COUNT(*) FROM events WHERE event_type = "INTRUSION" AND datetime(timestamp) > datetime("now", "-24 hours")');
		echo json_encode(['intrusion_count' => $count]);
		break;
	
    default:
        echo json_encode(['error' => 'Invalid action']);
}
?>
EOF

echo "==> Creating enhanced documentation..."
cat > README.md <<'EOF'
# Railway AI Traffic Control System v2.0

## 🚄 Enhanced Demo for AITEK Interview

## New Features:
1. **Real-time Notification System**
   - Collision warnings, speed alerts, technical issues
   - Color-coded severity (info, warning, critical)

2. **Dynamic Weather Simulation**
   - 4 conditions: Clear, Rain, Fog, Snow
   - Visibility and performance effects
   - Adaptive AI behavior

3. **Advanced Train Typology**
   - Passenger trains (high priority)
   - High-speed trains (maximum priority)
   - Freight trains (medium priority)

4. **External Sensor Integration**
   - Rail temperature monitoring
   - Vibration detection
   - Security camera status
   - Intrusion Alert (Video Surveillance System)

5. **Advanced Reporting System**
   - One-click report generation
   - Performance metrics dashboard
   - Train type distribution

## Technical Stack:
- Frontend: Three.js, TensorFlow.js
- Backend: PHP 8.4, SQLite3
- AI: Real-time decision algorithms
- Architecture: Event-driven, real-time processing

## Emergency Protocols:
1. **Imminent Collision**
   - AI detects collision courses
   - Activates emergency protocols
   - Alerts operators with sound alarms

2. **Technical Failures**
   - Camera system malfunctions
   - Dangerous rail temperatures
   - Abnormal vibrations

3. **Critical Weather Conditions**
   - Reduced visibility (fog/snow)
   - Reduced train performance
   - Automatic speed adaptation

EOF

start http://localhost:8080/index.php

echo "==> Starting Railway AI Control System..."
echo "     System ready at: http://localhost:8080"
echo "     Show All Intrusions: http://localhost:8080/api.php?action=get_intrusions"
echo "     AI Engine: ACTIVE"
echo "     Real-time monitoring: ENABLED"
echo "     Demo optimized for AITEK interview"

"$(pwd)/$PHP_DIR/php.exe" -c "$(pwd)/$PHP_DIR/php.ini" -S localhost:8080
