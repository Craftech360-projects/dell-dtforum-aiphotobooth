// MediaPipe Hand Detection for Web
let hands = null;
let camera = null;

window.handDetector = {
    init: async function() {
        try {
            // Initialize MediaPipe Hands
            hands = new Hands({
                locateFile: (file) => {
                    return `https://cdn.jsdelivr.net/npm/@mediapipe/hands/${file}`;
                }
            });

            hands.setOptions({
                maxNumHands: 1,
                modelComplexity: 1,
                minDetectionConfidence: 0.5,
                minTrackingConfidence: 0.5
            });

            hands.onResults(onResults);
            console.log('MediaPipe Hands initialized');
            return true;
        } catch (error) {
            console.error('Error initializing MediaPipe:', error);
            return false;
        }
    },

    processVideoFrame: async function(videoElement) {
        if (!hands || !videoElement) return null;
        
        try {
            await hands.send({image: videoElement});
        } catch (error) {
            console.error('Error processing frame:', error);
        }
    },

    detectFromCanvas: async function(canvas) {
        if (!hands || !canvas) return null;
        
        return new Promise((resolve) => {
            hands.onResults((results) => {
                if (results.multiHandLandmarks && results.multiHandLandmarks.length > 0) {
                    const landmarks = results.multiHandLandmarks[0];
                    const isPalm = checkIfPalmOpen(landmarks);
                    resolve({
                        detected: true,
                        isPalm: isPalm,
                        confidence: isPalm ? 0.8 : 0.3
                    });
                } else {
                    resolve({
                        detected: false,
                        isPalm: false,
                        confidence: 0
                    });
                }
            });
            
            hands.send({image: canvas});
        });
    }
};

function onResults(results) {
    if (results.multiHandLandmarks && results.multiHandLandmarks.length > 0) {
        const landmarks = results.multiHandLandmarks[0];
        const isPalm = checkIfPalmOpen(landmarks);
        
        if (isPalm) {
            // Dispatch custom event when palm is detected
            window.dispatchEvent(new CustomEvent('palmDetected', {
                detail: { confidence: 0.8 }
            }));
        }
    }
}

function checkIfPalmOpen(landmarks) {
    // Check if fingers are extended (simplified check)
    let extendedFingers = 0;
    
    // Thumb (check if tip is to the right of MCP for right hand)
    if (Math.abs(landmarks[4].x - landmarks[2].x) > 0.1) {
        extendedFingers++;
    }
    
    // Index finger
    if (landmarks[8].y < landmarks[6].y) {
        extendedFingers++;
    }
    
    // Middle finger
    if (landmarks[12].y < landmarks[10].y) {
        extendedFingers++;
    }
    
    // Ring finger
    if (landmarks[16].y < landmarks[14].y) {
        extendedFingers++;
    }
    
    // Pinky
    if (landmarks[20].y < landmarks[18].y) {
        extendedFingers++;
    }
    
    // Consider it a palm if 4 or 5 fingers are extended
    return extendedFingers >= 4;
}