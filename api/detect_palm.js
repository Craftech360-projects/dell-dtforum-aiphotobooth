export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    // For now, return a mock response
    // In production, you'd integrate with a proper hand detection service
    const { image } = req.body;
    
    // Simulate palm detection (random for demo)
    const isPalm = Math.random() > 0.7;
    
    res.status(200).json({
      detected: true,
      is_palm: isPalm,
      confidence: isPalm ? 0.8 : 0.3,
      extended_fingers: isPalm ? 5 : 2,
      message: isPalm ? 'Palm detected' : 'Hand detected but not open palm'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}