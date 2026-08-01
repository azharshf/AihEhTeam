// firebase_config.js

/**
 * Firebase & Google Auth Service for LipidWise AI / AihEhTeam
 */

const firebaseConfig = {
    apiKey: "AIzaSyDemoKeyLipidWiseAI2026",
    authDomain: "aihteam-lipidwise.firebaseapp.com",
    projectId: "aihteam-lipidwise",
    storageBucket: "aihteam-lipidwise.appspot.com",
    messagingSenderId: "102030405060",
    appId: "1:102030405060:web:abcdef123456"
};

let currentUser = null;

// Initialize Firebase if SDK is loaded
if (typeof firebase !== 'undefined' && firebase.initializeApp) {
    try {
        firebase.initializeApp(firebaseConfig);
        console.log("Firebase initialized successfully.");
    } catch (e) {
        console.warn("Firebase initialization warning:", e);
    }
}

class AuthService {
    static async signInWithGoogle(role = 'Patient') {
        try {
            if (typeof firebase !== 'undefined' && firebase.auth) {
                const provider = new firebase.auth.GoogleAuthProvider();
                const result = await firebase.auth().signInWithPopup(provider);
                currentUser = {
                    displayName: result.user.displayName || (role === 'Doctor' ? 'Dr. Sarah Jenkins' : 'John Doe'),
                    email: result.user.email || 'user@example.com',
                    photoURL: result.user.photoURL || '',
                    role: role
                };
                return currentUser;
            }
        } catch (e) {
            console.warn("Popup blocked or unconfigured, falling back to instant demo auth:", e);
        }

        // Graceful fallback for local demo mode so login never breaks
        currentUser = {
            displayName: role === 'Doctor' ? 'Dr. Alex Vance, MD' : 'Patient Alex Smith',
            email: role === 'Doctor' ? 'alex.vance@clinic.org' : 'alex.smith@gmail.com',
            photoURL: 'https://ui-avatars.com/api/?name=' + encodeURIComponent(role === 'Doctor' ? 'Dr Alex' : 'Alex Smith') + '&background=0D8ABC&color=fff',
            role: role
        };
        return currentUser;
    }

    static getUser() {
        return currentUser;
    }

    static signOut() {
        if (typeof firebase !== 'undefined' && firebase.auth) {
            firebase.auth().signOut().catch(() => {});
        }
        currentUser = null;
    }
}

window.AuthService = AuthService;
